package com.timeline.game.service;

import com.timeline.game.domain.Coins;
import com.timeline.game.domain.Rank;
import com.timeline.game.domain.Ruleset;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.function.IntUnaryOperator;

/**
 * 多队列随机匹配（TS matchmaking.ts 直译，spec §3、§20.5、§21.2）。
 *
 * 队列按 (人数, 档位, 门票) 分开；凑满人数即成组，按入队顺序。
 * 队列为空是新游戏常态：
 * - 真人不足 MIN_HUMANS 时可以无限等（只发"等待真人"语义的 queue.status，不补位、不 timeout）。
 * - 真人达到 MIN_HUMANS 后，以"第 2 人的入队时刻"起算补位倒计时；到点整队成组，
 *   缺的座位由 Hub 补电脑（botSeats）。倒计时对全队可见（queue.status.botFillAt）。
 * - 补位关闭时退回 P1 行为：等待超 enqueueWaitMs 发一次 queue.timeout，不强制出队。
 *
 * 本类不持有牌桌、不生成房间号：成组结果交给 Hub 建 match 桌并统一生成房间号。
 * 时钟从参数注入（spec §1），类内不读墙钟。
 */
public final class Matchmaking {

    /** 补位倒计时（spec §20.5 用户裁定）：2/3 人桌 30 秒，4 人桌 45 秒。Hub 侧同值使用。 */
    public static final Map<Integer, Long> BOT_FILL_AFTER_MS = Map.of(2, 30_000L, 3, 30_000L, 4, 45_000L);
    /** 少于这个真人数量就永远不补位——不能让一个真人面对三个电脑还以为匹配到了真人。 */
    public static final int MIN_HUMANS = 2;
    /** 等待多久后提示一次"暂时没有对手"（仅补位关闭时生效）的默认值。 */
    public static final long DEFAULT_ENQUEUE_WAIT_MS = 60_000L;

    /**
     * 队列键：容量 × 档位 × 门票互相隔离（spec §3；门票见 spec §廿二.3）。
     * ticket 为 null = 客户端没传门票字段（v4 调用方兼容），等价 TS 的 undefined。
     * record 的 equals/hashCode 按三个字段逐一比较（含 null 安全），与 TS 的 keyOf 字符串判等一致。
     */
    public record QueueKey(int capacity, Ruleset.PresetId preset, Coins.TicketId ticket) {

        /** 无门票（v4 兼容）快捷构造。 */
        public QueueKey(int capacity, Ruleset.PresetId preset) {
            this(capacity, preset, null);
        }
    }

    /** 凑满真人时 botSeats = 0；补位成组时 = capacity − 真人数。 */
    public record Grouped(QueueKey key, List<String> playerIds, int botSeats) {}

    /** join 的出参：定向消息 + 本次立即成组（无则 null）。 */
    public record JoinResult(List<QueueOutbound> out, Grouped group) {}

    /** tick 的出参：定向消息（queue.timeout）+ 本轮成组（含补位组）。 */
    public record TickResult(List<QueueOutbound> out, List<Grouped> groups) {}

    private static final class Entry {
        final String playerId;
        final long since;
        boolean notified;
        final int mmr;

        Entry(String playerId, long since, boolean notified, int mmr) {
            this.playerId = playerId;
            this.since = since;
            this.notified = notified;
            this.mmr = mmr;
        }
    }

    private static final class Queue {
        final QueueKey key;
        List<Entry> entries = new ArrayList<>();

        Queue(QueueKey key) { this.key = key; }
    }

    /** 队列按插入序遍历（与 TS Map 迭代序一致，tick 的成组次序依赖它）。 */
    private final Map<String, Queue> queues = new LinkedHashMap<>();
    private final Map<String, QueueKey> byPlayer = new HashMap<>();
    private final long enqueueWaitMs;
    /** null = 补位关闭；否则入参是 capacity，返回该桌型的补位倒计时。 */
    private final IntUnaryOperator botFillMs;

    /** TS {@code new Matchmaking({})}：enqueueWaitMs 默认 60000，补位关闭。 */
    public Matchmaking() {
        this(null, (IntUnaryOperator) null);
    }

    /**
     * TS {@code {enqueueWaitMs, botFillMs: <数字>}}：全桌型同一倒计时。
     *
     * @param enqueueWaitMs 仅补位关闭时生效；null = 默认 60000
     * @param flatBotFillMs 补位倒计时（全桌型同值）；null = 关闭补位
     */
    public Matchmaking(Long enqueueWaitMs, Long flatBotFillMs) {
        this(enqueueWaitMs, flatBotFillMs == null ? null
            : (IntUnaryOperator) capacity -> Math.toIntExact(flatBotFillMs));
    }

    /**
     * TS {@code {enqueueWaitMs, botFillMs: <Record<Capacity, number>>}}：按桌型给倒计时。
     * 典型入参就是 {@link #BOT_FILL_AFTER_MS}。
     */
    public static Matchmaking perCapacity(Long enqueueWaitMs, Map<Integer, Long> botFillAfterMs) {
        return new Matchmaking(enqueueWaitMs, botFillAfterMs == null ? null
            : (IntUnaryOperator) capacity -> Math.toIntExact(botFillAfterMs.get(capacity)));
    }

    /**
     * 全参构造：补位倒计时按桌型由调用方给定（TS 的 {@code (capacity) => number} 形态）。
     *
     * @param enqueueWaitMs null = 默认 60000
     * @param botFillMsForCapacity null = 补位关闭（等价 TS 的 botFillMs: null）
     */
    public Matchmaking(Long enqueueWaitMs, IntUnaryOperator botFillMsForCapacity) {
        this.enqueueWaitMs = enqueueWaitMs == null ? DEFAULT_ENQUEUE_WAIT_MS : enqueueWaitMs;
        this.botFillMs = botFillMsForCapacity;
    }

    /** 该玩家当前所在的队列键；不在任何队列 = null。 */
    public QueueKey queueOf(String playerId) {
        return byPlayer.get(playerId);
    }

    /** 该队列当前真人数量。 */
    public int size(QueueKey key) {
        Queue q = queues.get(keyOf(key));
        return q == null ? 0 : q.entries.size();
    }

    /**
     * 入队（TS join）。mmr 用于分桶匹配（spec §21.2）；缺省按新号初始分见
     * {@link #join(String, QueueKey, long)}。
     *
     * 不变式：同键重复入队 = 静默 no-op（门票不重扣，Hub 层保证）；异键先自动离开旧队
     * （旧队剩余成员会收到重发 status）；成组者不再收 status，新的 tableState 由 Hub 下发。
     */
    public JoinResult join(String playerId, QueueKey key, long now, int mmr) {
        QueueKey current = byPlayer.get(playerId);
        if (current != null && keyOf(current).equals(keyOf(key))) {
            return new JoinResult(List.of(), null);
        }

        List<QueueOutbound> out = new ArrayList<>(leave(playerId, now));
        String k = keyOf(key);
        Queue q = queues.get(k);
        if (q == null) {
            q = new Queue(key);
            queues.put(k, q);
        }
        q.entries.add(new Entry(playerId, now, false, mmr));
        byPlayer.put(playerId, q.key);

        Grouped group = null;
        if (q.entries.size() >= q.key.capacity()) {
            List<Entry> taken = formGroup(q, now, q.key.capacity());
            if (taken != null) {
                take(q, taken);
                group = new Grouped(q.key, ids(taken), 0);
                // 成组者不再收队列状态；新的 tableState 由 Hub 下发
                if (!q.entries.isEmpty()) out.addAll(status(q.key, q.entries));
            } else {
                // 满员但分桶不兼容（隔 ≥2 桶永不放行）：继续等更合适的对手，宁等不错配
                out.addAll(status(q.key, q.entries));
            }
        } else {
            out.addAll(status(q.key, q.entries));
        }
        if (q.entries.isEmpty()) queues.remove(k);
        return new JoinResult(List.copyOf(out), group);
    }

    /** 入队，mmr 取新号初始分（TS 的 {@code mmr = INITIAL_MMR} 默认参数）。 */
    public JoinResult join(String playerId, QueueKey key, long now) {
        return join(playerId, key, now, Rank.INITIAL_MMR);
    }

    /** 离队：给该队剩余成员重发 status；不在队或队空 = 空出参。now 仅为签名对称（TS 也未用）。 */
    public List<QueueOutbound> leave(String playerId, long now) {
        QueueKey key = byPlayer.get(playerId);
        if (key == null) return List.of();
        byPlayer.remove(playerId);
        Queue q = queues.get(keyOf(key));
        if (q == null) return List.of();
        q.entries.removeIf(e -> e.playerId.equals(playerId));
        if (q.entries.isEmpty()) {
            queues.remove(keyOf(key));
            return List.of();
        }
        return status(q.key, q.entries);
    }

    /**
     * 推进计时（TS tick）。补位开启且真人 ≥ MIN_HUMANS 且倒计时到点 → 整队成组
     * （botSeats = 缺的座位数）；仍满员 = 分桶闸门不放行，继续等，不硬凑、不补位越闸。
     * 补位关闭时只做 P1 的 queue.timeout 提示。
     */
    public TickResult tick(long now) {
        List<QueueOutbound> out = new ArrayList<>();
        List<Grouped> groups = new ArrayList<>();
        for (Queue q : List.copyOf(queues.values())) {
            if (botFillMs != null) {
                // 真人满员先按分桶成组（spec §21.2）
                drainFormGroups(q, now, groups);
                if (q.entries.isEmpty()) {
                    queues.remove(keyOf(q.key));
                    continue;
                }
                // 仍满员 = 分桶闸门不放行（隔 ≥2 桶）：继续等，不硬凑成"零电脑的真人居段局"
                if (q.entries.size() >= q.key.capacity()) continue;
                if (q.entries.size() < MIN_HUMANS) continue;
                // 锚点 = 第 MIN_HUMANS 个真人的入队时刻：第 3、4 人入队不重置倒计时
                Entry anchor = q.entries.get(MIN_HUMANS - 1);
                if (now - anchor.since < botFillMs.applyAsInt(q.key.capacity())) continue;
                List<Entry> taken = new ArrayList<>(q.entries);
                q.entries.clear();
                for (Entry e : taken) byPlayer.remove(e.playerId);
                groups.add(new Grouped(q.key, ids(taken), q.key.capacity() - taken.size()));
                queues.remove(keyOf(q.key));
                continue;
            }
            // 补位关闭（P1 语义）：同样先按分桶凑满，再走 queue.timeout 提示
            drainFormGroups(q, now, groups);
            if (q.entries.isEmpty()) {
                queues.remove(keyOf(q.key));
                continue;
            }
            for (Entry e : q.entries) {
                if (!e.notified && now - e.since >= enqueueWaitMs) {
                    e.notified = true;
                    out.add(new QueueOutbound(e.playerId, new QueueEvent.Timeout()));
                }
            }
        }
        return new TickResult(List.copyOf(out), List.copyOf(groups));
    }

    /** 满员就反复贪心成组，直到分桶闸门不放行（tick 两个分支共用）。 */
    private void drainFormGroups(Queue q, long now, List<Grouped> groups) {
        while (q.entries.size() >= q.key.capacity()) {
            List<Entry> taken = formGroup(q, now, q.key.capacity());
            if (taken == null) break;
            take(q, taken);
            groups.add(new Grouped(q.key, ids(taken), 0));
        }
    }

    /**
     * 从队首凑 count 个互相放行（matchRelaxGate，等待时长按各自入队时刻）的人。
     * 贪心：按入队顺序取人，逐个与已选集合校验。凑不齐返回 null（不部分成组）。
     */
    private List<Entry> formGroup(Queue q, long now, int count) {
        List<Entry> picked = new ArrayList<>();
        for (Entry e : q.entries) {
            if (picked.size() == count) break;
            long waited = now - e.since;
            boolean okWith = true;
            for (Entry p : picked) {
                // 放行时长取两人等待更短的那个：后来者不能替先来者放宽闸门
                if (!Rank.matchRelaxGate(p.mmr, e.mmr, Math.min(waited, now - p.since))) {
                    okWith = false;
                    break;
                }
            }
            if (okWith) picked.add(e);
        }
        return picked.size() == count ? picked : null;
    }

    private void take(Queue q, List<Entry> picked) {
        Set<String> takenIds = new HashSet<>();
        for (Entry e : picked) takenIds.add(e.playerId);
        q.entries.removeIf(e -> takenIds.contains(e.playerId));
        for (Entry e : picked) byPlayer.remove(e.playerId);
    }

    /** 补位倒计时：以"第 MIN_HUMANS 个真人的入队时刻"起算，第 3、4 人入队不重置。 */
    private Long botFillAt(QueueKey key, List<Entry> entries) {
        if (botFillMs == null || entries.size() < MIN_HUMANS) return null;
        return entries.get(MIN_HUMANS - 1).since + botFillMs.applyAsInt(key.capacity());
    }

    /** 给队列全体重发 queue.status（ticket 为 null 时 Hub 编码整条省略该字段，v4 兼容）。 */
    private List<QueueOutbound> status(QueueKey key, List<Entry> entries) {
        int waiting = entries.size();
        Long botFillAt = botFillAt(key, entries);
        int humansNeeded = Math.max(0, MIN_HUMANS - waiting);
        List<QueueOutbound> out = new ArrayList<>(entries.size());
        for (Entry e : entries) {
            out.add(new QueueOutbound(e.playerId,
                new QueueEvent.Status(key.capacity(), key.preset(), waiting, botFillAt, humansNeeded, key.ticket())));
        }
        return out;
    }

    private static List<String> ids(List<Entry> entries) {
        List<String> ids = new ArrayList<>(entries.size());
        for (Entry e : entries) ids.add(e.playerId);
        return List.copyOf(ids);
    }

    /** 队列键的字符串形态（TS keyOf）：capacity:preset:ticket（缺省 free）。 */
    private static String keyOf(QueueKey k) {
        return k.capacity() + ":" + k.preset() + ":" + Objects.requireNonNullElse(k.ticket(), "free");
    }
}
