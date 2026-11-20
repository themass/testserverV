package com.timeline.game.domain;

import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * 金币账本（TS packages/shared/src/coins.ts 直译）：纯函数与常量，无 Spring、无 IO、时钟从参数进。
 *
 * 三条铁律（spec §18.4 法规红线）：
 * 1. 金币只在 玩家 ↔ 系统 之间流动，永不在玩家之间转移；
 * 2. 门票归系统回收，奖励是固定额，与对手付了多少无关；
 * 3. 每日净增封顶——金币产出受控，不能无限刷。
 */
public final class Coins {

    private Coins() {}

    // ---------------------------------------------------------------- 门票档

    public enum TicketId { FREE, STANDARD, ADVANCED }

    /** 门票与奖励都是固定额（系统定价，不是奖池）。 */
    public record Ticket(int fee, int reward) {}

    public static final Map<TicketId, Ticket> TICKETS = Map.of(
        TicketId.FREE, new Ticket(0, 0),
        TicketId.STANDARD, new Ticket(50, 80),
        TicketId.ADVANCED, new Ticket(100, 160));

    // ---------------------------------------------------------------- 账本类型

    /** 入账原因；label 与 TS COIN_REASON_LABELS 对齐，展示用。 */
    public enum CoinReason {
        LOGIN("每日登录"), GAME("完成对局"), TICKET_FEE("门票"), TICKET_WIN("门票胜利"),
        TICKET_REFUND("门票退款"), AD("广告奖励"), SEASON_GRANT("赛季奖励");

        public final String label;

        CoinReason(String label) { this.label = label; }
    }

    public record CoinEntry(String id, long at, int delta, CoinReason reason, String ref) {}

    /** 明细新在前。 */
    public record CoinsState(int balance, List<CoinEntry> ledger) {
        public static CoinsState empty() { return new CoinsState(0, List.of()); }
    }

    /** 当日计数器；day 翻转时整体换新（旧值作废）。 */
    public record DailyState(String day, boolean loginDone, int gameGrants,
                             int ticketPlays, int adGrants, int netGain) {}

    // ---------------------------------------------------------------- 常量（§廿二.2）

    public static final int LOGIN_GRANT = 50;
    public static final int GAME_GRANT = 5;
    public static final int DAILY_GAME_MAX = 20;
    public static final int DAILY_TICKET_MAX = 20;
    /** 每日净增封顶（支出为负数，会把净值拉回来）。 */
    public static final int NET_GAIN_MAX = 500;
    public static final int AD_GRANT = 30;
    public static final int AD_DAILY_MAX = 5;
    /** 明细保留条数；更早的折进余额（DB 侧全量留痕，这里只管内存视图）。 */
    public static final int LEDGER_MAX = 100;

    /** 不受净增上限约束的 reason：退款是还回自己的钱；赛季发币 4 周一次，不是可刷产出。 */
    private static boolean netExempt(CoinReason reason) {
        return reason == CoinReason.TICKET_REFUND || reason == CoinReason.SEASON_GRANT;
    }

    // ---------------------------------------------------------------- 纯函数

    private static final DateTimeFormatter DAY_FMT =
        DateTimeFormatter.ofPattern("yyyy-M-d", Locale.ROOT);

    /** 服务端本地日（00:00 翻转）的日期键；TS 用 Date 本地方法，Java 用系统默认时区对齐。 */
    public static String dayKey(long nowMs, ZoneId zone) {
        return DAY_FMT.format(Instant.ofEpochMilli(nowMs).atZone(zone));
    }

    public static DailyState initialDaily(long nowMs, ZoneId zone) {
        return new DailyState(dayKey(nowMs, zone), false, 0, 0, 0, 0);
    }

    /** 跨日自动翻转（纯函数，返回新对象或原对象）。 */
    public static DailyState rollDaily(DailyState daily, long nowMs, ZoneId zone) {
        return daily.day().equals(dayKey(nowMs, zone)) ? daily : initialDaily(nowMs, zone);
    }

    /**
     * 一笔账。
     * @param id 幂等键 reason:ref；同 id 重复调用是 no-op（DB 侧由唯一键兜底）
     * @param delta 期望变动：收入正、支出负
     */
    public record CoinOp(CoinReason reason, String id, String ref, long at, int delta) {}

    /**
     * @param applied 实际入账（0 = 被幂等吞掉或被上限截成 0）
     * @param capped 有金额被净增上限截掉（或触发分 reason 日限）
     * @param insufficient 余额不足以支出（调用方应拒绝本次操作，coins 原样返回）
     */
    public record CoinResult(CoinsState coins, DailyState daily,
                             int applied, boolean capped, boolean insufficient) {}

    /** 一笔账（§廿二.1/§廿二.2）：幂等 → 日计数 → 净增封顶 → 余额/明细更新。 */
    public static CoinResult applyCoin(CoinsState coins, DailyState daily, CoinOp op, ZoneId zone) {
        DailyState d0 = rollDaily(daily, op.at(), zone);
        // 幂等：账本里已有同 id → 原样返回（applied 0）。
        for (CoinEntry e : coins.ledger()) {
            if (e.id().equals(op.id())) return new CoinResult(coins, d0, 0, false, false);
        }

        if (op.delta() < 0 && coins.balance() + op.delta() < 0) {
            return new CoinResult(coins, d0, 0, false, true);
        }

        int delta = op.delta();
        boolean capped = false;
        if (delta > 0 && !netExempt(op.reason())) {
            // 分 reason 日限（评审 #3）：完成对局 20 局/日——只进 daily 计数不检查等于没限
            if (op.reason() == CoinReason.GAME && d0.gameGrants() >= DAILY_GAME_MAX) {
                return new CoinResult(coins, d0, 0, true, false);
            }
            int room = NET_GAIN_MAX - d0.netGain();
            if (room <= 0) return new CoinResult(coins, d0, 0, true, false);
            if (delta > room) {
                delta = room;
                capped = true;
            }
        }

        List<CoinEntry> ledger = new ArrayList<>(coins.ledger().size() + 1);
        ledger.add(new CoinEntry(op.id(), op.at(), delta, op.reason(), op.ref()));
        ledger.addAll(coins.ledger());
        if (ledger.size() > LEDGER_MAX) ledger = List.copyOf(ledger.subList(0, LEDGER_MAX));
        else ledger = List.copyOf(ledger);

        DailyState next = new DailyState(
            d0.day(),
            op.reason() == CoinReason.LOGIN || d0.loginDone(),
            op.reason() == CoinReason.GAME ? d0.gameGrants() + 1 : d0.gameGrants(),
            d0.ticketPlays(),
            op.reason() == CoinReason.AD ? d0.adGrants() + 1 : d0.adGrants(),
            netExempt(op.reason()) ? d0.netGain() : d0.netGain() + delta);

        return new CoinResult(new CoinsState(coins.balance() + delta, ledger), next, delta, capped, false);
    }

    /** 门票消耗配额检查（不是账目，是配额；账目走 applyCoin 的 ticket-fee）。 */
    public static boolean canPlayTicket(DailyState daily) {
        return daily.ticketPlays() < DAILY_TICKET_MAX;
    }

    public static DailyState bumpTicketPlays(DailyState daily, long nowMs, ZoneId zone) {
        DailyState d0 = rollDaily(daily, nowMs, zone);
        return new DailyState(d0.day(), d0.loginDone(), d0.gameGrants(), d0.ticketPlays() + 1, d0.adGrants(), d0.netGain());
    }

    /** 赛季段位奖励：(tier+1)×50，元帅 400（§廿二.5）。 */
    public static int seasonGrant(int tier) {
        return (tier + 1) * 50;
    }
}
