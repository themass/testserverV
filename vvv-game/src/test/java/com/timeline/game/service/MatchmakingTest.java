package com.timeline.game.service;

import com.timeline.game.domain.Ruleset.PresetId;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;

import static com.timeline.game.domain.Rank.INITIAL_MMR;
import static org.junit.jupiter.api.Assertions.*;

/** 多队列匹配单测（镜像 TS apps/server/test/matchmaking.test.ts 的全部用例与时间戳）。 */
class MatchmakingTest {

    private static final Matchmaking.QueueKey K2 = new Matchmaking.QueueKey(2, PresetId.STANDARD);
    private static final Matchmaking.QueueKey K3 = new Matchmaking.QueueKey(3, PresetId.STANDARD);
    private static final Matchmaking.QueueKey K4 = new Matchmaking.QueueKey(4, PresetId.STANDARD);
    private static final Matchmaking.QueueKey K2B = new Matchmaking.QueueKey(2, PresetId.BEGINNER);

    /** 补位参数（spec §20.5）：2/3 人桌 30 秒，4 人桌 45 秒。 */
    private static Matchmaking fill() {
        return Matchmaking.perCapacity(null, Matchmaking.BOT_FILL_AFTER_MS);
    }

    private static List<QueueEvent.Status> statusTo(List<QueueOutbound> out, String to) {
        List<QueueEvent.Status> got = new ArrayList<>();
        for (QueueOutbound o : out) {
            if (o.to().equals(to) && o.event() instanceof QueueEvent.Status s) got.add(s);
        }
        return got;
    }

    private static List<QueueEvent.Status> statusTo(List<QueueOutbound> a, List<QueueOutbound> b, String to) {
        List<QueueOutbound> all = new ArrayList<>(a);
        all.addAll(b);
        return statusTo(all, to);
    }

    /** TS 的 statusTo(...).filter(msg.type === 'queueTimeout')：Java 里等价于筛 Timeout 事件。 */
    private static List<QueueOutbound> timeouts(List<QueueOutbound> out) {
        return out.stream().filter(o -> o.event() instanceof QueueEvent.Timeout).toList();
    }

    // ---------------- 多队列匹配 ----------------

    @Test
    void 不同人数档位的队列互不干扰() {
        Matchmaking m = new Matchmaking();
        assertNull(m.join("a", K2, 0).group());
        assertNull(m.join("b", K2B, 0).group());
        assertNull(m.join("c", K4, 0).group());
        assertEquals(1, m.size(K2));
        assertEquals(1, m.size(K2B));
        assertEquals(1, m.size(K4));
        Matchmaking.JoinResult r = m.join("d", K2, 10);
        assertEquals(new Matchmaking.Grouped(K2, List.of("a", "d"), 0), r.group());
        assertEquals(1, m.size(K2B));
        assertEquals(1, m.size(K4));
        assertEquals(K2B, m.queueOf("b"));
    }

    @Test
    void 四人队列凑满四人才成组按入队顺序() {
        Matchmaking m = new Matchmaking();
        assertNull(m.join("p1", K4, 0).group());
        assertNull(m.join("p2", K4, 1).group());
        assertNull(m.join("p3", K4, 2).group());
        Matchmaking.JoinResult r = m.join("p4", K4, 3);
        assertEquals(new Matchmaking.Grouped(K4, List.of("p1", "p2", "p3", "p4"), 0), r.group());
    }

    @Test
    void 入队离队时向该队列全体推送queueStatus() {
        Matchmaking m = new Matchmaking();
        m.join("x", K2B, 0);
        // TS 的 s(waiting) 工厂：capacity 4 / standard / 不补位 / humansNeeded = max(0, 2 − waiting)
        java.util.function.IntFunction<QueueEvent.Status> s = waiting ->
            new QueueEvent.Status(4, PresetId.STANDARD, waiting, null, Math.max(0, Matchmaking.MIN_HUMANS - waiting), null);

        Matchmaking.JoinResult r1 = m.join("a", K4, 0);
        assertEquals(List.of(s.apply(1)), statusTo(r1.out(), "a"));
        Matchmaking.JoinResult r2 = m.join("b", K4, 1);
        assertEquals(List.of(s.apply(2)), statusTo(r2.out(), "a"));
        assertEquals(List.of(s.apply(2)), statusTo(r2.out(), "b"));
        assertTrue(r2.out().stream().noneMatch(o -> o.to().equals("x")));
        List<QueueOutbound> out = m.leave("a", 2);
        assertEquals(List.of(new QueueOutbound("b", s.apply(1))), out);
        assertNull(m.queueOf("a"));
        assertEquals(List.of(), m.leave("a", 3));
    }

    @Test
    void 加入另一个队列会自动离开原队列() {
        Matchmaking m = new Matchmaking();
        m.join("a", K4, 0);
        m.join("b", K4, 0);
        Matchmaking.JoinResult r = m.join("a", K2, 5);
        assertEquals(K2, m.queueOf("a"));
        assertEquals(1, m.size(K4));
        assertEquals(List.of(new QueueEvent.Status(4, PresetId.STANDARD, 1, null, 1, null)),
            statusTo(r.out(), "b"));
        // 重复加入同一队列不产生第二个自己
        m.join("a", K2, 6);
        assertEquals(1, m.size(K2));
    }

    @Test
    void 成组后这些人从队列移除其余人收到新的queueStatus() {
        Matchmaking m = new Matchmaking();
        m.join("a", K3, 0);
        m.join("b", K3, 1);
        Matchmaking.JoinResult r = m.join("c", K3, 2);
        assertEquals(List.of("a", "b", "c"), r.group().playerIds());
        assertEquals(0, m.size(K3));
        for (String p : new String[]{"a", "b", "c"}) assertNull(m.queueOf(p));
        // 成组的人不再收到 queueStatus
        assertTrue(statusTo(r.out(), "a").isEmpty());
        assertTrue(statusTo(r.out(), "b").isEmpty());
        assertTrue(statusTo(r.out(), "c").isEmpty());
        Matchmaking.JoinResult r2 = m.join("d", K3, 3);
        assertEquals(List.of(new QueueOutbound("d",
            new QueueEvent.Status(3, PresetId.STANDARD, 1, null, 1, null))), r2.out());
    }

    @Test
    void 成组不影响其它队列的人() {
        Matchmaking m = new Matchmaking();
        m.join("x", K4, 0);
        m.join("a", K2, 0);
        Matchmaking.JoinResult r = m.join("b", K2, 1);
        assertEquals(List.of("a", "b"), r.group().playerIds());
        assertTrue(r.out().stream().noneMatch(o -> o.to().equals("x")));
        assertEquals(1, m.size(K4));
    }

    @Test
    void 六十秒提示一次queueTimeout不出队补位关闭默认() {
        Matchmaking m = new Matchmaking(60_000L, (java.lang.Long) null);
        m.join("a", K4, 0);
        assertEquals(List.of(), m.tick(59_999).out());
        assertEquals(List.of(new QueueOutbound("a", new QueueEvent.Timeout())), m.tick(60_000).out());
        assertEquals(List.of(), m.tick(61_000).out());
        assertEquals(K4, m.queueOf("a"));
        assertEquals(1, m.size(K4));
    }

    // ---------------- P2 补位（spec §20.5） ----------------

    @Test
    void 补位关闭默认行为与P1相同botFillAt恒为null() {
        Matchmaking m = new Matchmaking();
        Matchmaking.JoinResult r1 = m.join("a", K4, 0);
        Matchmaking.JoinResult r2 = m.join("b", K4, 100);
        assertNull(statusTo(r1.out(), r2.out(), "b").get(0).botFillAt());
        assertEquals(List.of(), m.tick(10_000).groups());
        assertEquals(2, m.size(K4));
    }

    @Test
    void 只有一人botFillAt为nullhumansNeeded为1等多久都不补位() {
        Matchmaking m = fill();
        Matchmaking.JoinResult r = m.join("a", K4, 0);
        assertEquals(List.of(new QueueEvent.Status(4, PresetId.STANDARD, 1, null, 1, null)), statusTo(r.out(), "a"));
        assertEquals(List.of(), m.tick(10_000_000).groups());
        assertEquals(List.of(), m.tick(10_000_000).out());
        assertEquals(1, m.size(K4));
    }

    @Test
    void 补位开启第2人入队后botFillAt为第2人入队时刻加三万秒三桌() {
        Matchmaking m = fill();
        m.join("a", K3, 1000);
        Matchmaking.JoinResult r = m.join("b", K3, 5000);
        QueueEvent.Status expected = new QueueEvent.Status(3, PresetId.STANDARD, 2, 5000 + 30_000L, 0, null);
        assertEquals(List.of(expected), statusTo(r.out(), "a"));
        assertEquals(List.of(expected), statusTo(r.out(), "b"));
    }

    @Test
    void 第2人离队后botFillAt回到null只剩一人不补位() {
        Matchmaking m = fill();
        m.join("a", K3, 0);
        m.join("b", K3, 100);
        List<QueueOutbound> out = m.leave("b", 200);
        assertEquals(List.of(new QueueEvent.Status(3, PresetId.STANDARD, 1, null, 1, null)), statusTo(out, "a"));
        assertEquals(List.of(), m.tick(100_000).groups());
    }

    @Test
    void 二十九秒九百九十九毫秒不成组三十秒时三名真人成组botSeats为一() {
        Matchmaking m = new Matchmaking(null, 30_000L); // 全桌型自定义 30 秒
        m.join("a", K4, 0);
        m.join("b", K4, 10);
        m.join("c", K4, 20);
        assertEquals(List.of(), m.tick(10 + 29_999).groups());
        Matchmaking.TickResult r = m.tick(10 + 30_000);
        assertEquals(List.of(new Matchmaking.Grouped(K4, List.of("a", "b", "c"), 1)), r.groups());
        assertEquals(0, m.size(K4));
    }

    @Test
    void 四人队列倒计时为四十五秒() {
        Matchmaking m = fill();
        m.join("a", K4, 0);
        Matchmaking.JoinResult r = m.join("b", K4, 100);
        assertEquals(Long.valueOf(100 + 45_000L), statusTo(r.out(), "a").get(0).botFillAt());
        assertEquals(List.of(), m.tick(100 + 44_999).groups());
        assertEquals(List.of(new Matchmaking.Grouped(K4, List.of("a", "b"), 2)), m.tick(100 + 45_000).groups());
    }

    @Test
    void 第三四人入队不重置倒计时以第二人的入队时刻为准() {
        Matchmaking m = fill();
        m.join("a", K4, 0);
        m.join("b", K4, 100);
        Matchmaking.JoinResult r = m.join("c", K4, 20_000);
        assertEquals(Long.valueOf(100 + 45_000L), statusTo(r.out(), "c").get(0).botFillAt());
        // 4 名真人在倒计时到点前入队 → 立即凑满，走正常成组（botSeats 0）
        assertEquals(new Matchmaking.Grouped(K4, List.of("a", "b", "c", "d"), 0), m.join("d", K4, 30_000).group());
    }

    @Test
    void 人够四名真人时立即成组botSeats为零不等补位() {
        Matchmaking m = fill();
        m.join("a", K4, 0);
        m.join("b", K4, 0);
        m.join("c", K4, 0);
        assertEquals(new Matchmaking.Grouped(K4, List.of("a", "b", "c", "d"), 0), m.join("d", K4, 1).group());
    }

    @Test
    void ReviewFocus四同一tick之前已离队的人不在成组里队列空则不成组() {
        // 4 座队列只来了 3 人（不足容量才不会立即成组）；b 在倒计时到点前离队
        Matchmaking m = new Matchmaking(null, 30_000L);
        m.join("a", K4, 0);
        m.join("b", K4, 10);
        m.join("c", K4, 20);
        m.leave("b", 30);
        // 锚点变成第 2 人 c（入队于 20）
        Matchmaking.TickResult r = m.tick(20 + 30_000);
        assertEquals(List.of(new Matchmaking.Grouped(K4, List.of("a", "c"), 2)), r.groups());
        // 队列已空：再 tick 不产出任何东西
        assertEquals(new Matchmaking.TickResult(List.of(), List.of()), m.tick(100_000));
    }

    @Test
    void 补位成组者从queueOf中移除且不再收到queueStatus或queueTimeout() {
        Matchmaking m = new Matchmaking(1L, 30_000L);
        m.join("a", K3, 0);
        m.join("b", K3, 0);
        Matchmaking.TickResult r = m.tick(30_000);
        assertEquals(1, r.groups().size());
        for (String p : new String[]{"a", "b"}) {
            assertNull(m.queueOf(p));
            assertTrue(r.out().stream().noneMatch(o -> o.to().equals(p)));
        }
        // 之后他们也不在任何队列里：leave 不再广播
        assertEquals(List.of(), m.leave("a", 30_100));
    }

    @Test
    void 补位开启时不发queueTimeout() {
        Matchmaking m = Matchmaking.perCapacity(1L, Matchmaking.BOT_FILL_AFTER_MS);
        m.join("a", K4, 0);
        assertEquals(List.of(), m.tick(10_000).out());
        m.join("b", K4, 10);
        assertEquals(List.of(), timeouts(m.tick(20_000).out()));
    }

    // ---------------- P3：MMR 分桶匹配（spec §21.2） ----------------

    // 桶边界：mmrBucket = round(mmr/120)。1200→10，1330→11（相邻），1450→12（隔两桶）
    private static final int NEAR = INITIAL_MMR + 130; // 相邻桶（bucket 11）
    private static final int FAR = INITIAL_MMR + 250;  // 隔 ≥2 桶（bucket 12）

    @Test
    void 同桶立即成组默认mmr即同桶() {
        Matchmaking m = new Matchmaking();
        assertNull(m.join("a", K2, 0).group());
        assertNotNull(m.join("b", K2, 1, INITIAL_MMR + 10).group());
    }

    @Test
    void 相邻桶等待小于十五秒不成组满十五秒后tick成组() {
        Matchmaking m = new Matchmaking();
        m.join("a", K2, 0, INITIAL_MMR);
        assertNull(m.join("b", K2, 0, NEAR).group());
        assertEquals(List.of(), m.tick(14_999).groups());
        assertEquals(List.of(new Matchmaking.Grouped(K2, List.of("a", "b"), 0)), m.tick(15_000).groups());
    }

    @Test
    void 隔两桶以上等待按桶距升级后放行不兼容队列不会永久饿死() {
        Matchmaking m = new Matchmaking();
        m.join("a", K2, 0, INITIAL_MMR);
        assertNull(m.join("b", K2, 0, FAR).group());
        assertEquals(List.of(), m.tick(29_999).groups());
        assertEquals(List.of(new Matchmaking.Grouped(K2, List.of("a", "b"), 0)), m.tick(30_000).groups());
    }

    @Test
    void 满员但分桶未放行时不硬凑零电脑真人群放行时限到了照常成组() {
        Matchmaking m = fill();
        m.join("a", K2, 0, INITIAL_MMR);
        m.join("b", K2, 0, FAR);
        // 2 人满 capacity=2：闸门未放行 → 不建组，也不许补位成 botSeats=0 的组
        assertEquals(List.of(), m.tick(14_999).groups());
        assertEquals(2, m.size(K2));
        // 等待到 gap×15s：正常成组（不是补位局）
        assertEquals(List.of(new Matchmaking.Grouped(K2, List.of("a", "b"), 0)), m.tick(30_000).groups());
    }

    @Test
    void 补位倒计时照常两人不同桶但相邻未满员等到点带电脑成组() {
        Matchmaking m = fill();
        m.join("a", K3, 0, INITIAL_MMR);
        m.join("b", K3, 0, NEAR);
        // 补位局不参与分桶闸门（不计段位，spec §21.2）：到点即组
        assertEquals(List.of(), m.tick(29_999).groups());
        assertEquals(List.of(new Matchmaking.Grouped(K3, List.of("a", "b"), 1)), m.tick(30_000).groups());
    }

    @Test
    void 四人满员时贪心挑互相放行的三人先走同桶优先剩下的继续等() {
        Matchmaking m = new Matchmaking();
        m.join("a", K4, 0, INITIAL_MMR);          // 桶 10
        m.join("b", K4, 1, INITIAL_MMR + 5);      // 桶 10
        m.join("c", K4, 2, INITIAL_MMR + 9);      // 桶 10
        m.join("d", K4, 3, FAR);                  // 桶 12：谁都带不动它
        Matchmaking.JoinResult r = m.join("e", K4, 4, INITIAL_MMR + 8); // 桶 10 → 满 4 个同桶者
        assertEquals(new Matchmaking.Grouped(K4, List.of("a", "b", "c", "e"), 0), r.group());
        assertEquals(1, m.size(K4)); // 只剩 d
    }
}
