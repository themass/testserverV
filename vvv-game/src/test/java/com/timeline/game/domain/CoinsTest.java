package com.timeline.game.domain;

import org.junit.jupiter.api.Test;

import java.time.ZoneId;
import java.util.List;

import static com.timeline.game.domain.Coins.*;
import static org.junit.jupiter.api.Assertions.*;

/** 金币账本纯函数单测（镜像 TS packages/shared/test/coins.test.ts 的全部预期）。 */
class CoinsTest {

    static final ZoneId ZONE = ZoneId.of("Asia/Shanghai");
    static final long T0 = 1_795_176_000_000L; // Date.UTC(2026, 10, 20, 12, 0, 0) 同一天内固定时刻

    static CoinsState empty() { return CoinsState.empty(); }
    static DailyState daily() { return initialDaily(T0, ZONE); }

    @Test
    void 收入加余额并写明细() {
        CoinResult r = applyCoin(empty(), daily(), new CoinOp(CoinReason.LOGIN, "login:d1", "d1", T0, LOGIN_GRANT), ZONE);
        assertEquals(50, r.applied());
        assertEquals(50, r.coins().balance());
        CoinEntry e = r.coins().ledger().get(0);
        assertEquals("login:d1", e.id());
        assertEquals(50, e.delta());
        assertEquals(CoinReason.LOGIN, e.reason());
    }

    @Test
    void 同id重放是noOp幂等() {
        CoinResult a = applyCoin(empty(), daily(), new CoinOp(CoinReason.GAME, "game:t:1", null, T0, 5), ZONE);
        CoinResult b = applyCoin(a.coins(), a.daily(), new CoinOp(CoinReason.GAME, "game:t:1", null, T0, 5), ZONE);
        assertEquals(0, b.applied());
        assertEquals(5, b.coins().balance());
        assertEquals(1, b.coins().ledger().size());
    }

    @Test
    void 余额不足以支出整体拒绝() {
        CoinResult r = applyCoin(new CoinsState(30, List.of()), daily(),
            new CoinOp(CoinReason.TICKET_FEE, "fee:1", null, T0, -50), ZONE);
        assertTrue(r.insufficient());
        assertEquals(30, r.coins().balance());
        assertTrue(r.coins().ledger().isEmpty());
    }

    @Test
    void 明细新在前超过上限折掉最旧余额保留() {
        CoinsState c = empty();
        DailyState d = daily();
        for (int i = 0; i < LEDGER_MAX + 5; i++) {
            // 两种 NET_EXEMPT reason：既不受净增封顶，也不受分 reason 日限
            CoinResult r = applyCoin(c, d, new CoinOp(CoinReason.SEASON_GRANT, "grant:" + i, null, T0, 1), ZONE);
            c = r.coins(); d = r.daily();
            CoinResult r2 = applyCoin(c, d, new CoinOp(CoinReason.TICKET_REFUND, "refund:" + i, null, T0, 1), ZONE);
            c = r2.coins(); d = r2.daily();
        }
        assertEquals(LEDGER_MAX, c.ledger().size());
        assertEquals("refund:104", c.ledger().get(0).id()); // 最新在前
        assertEquals(2 * (LEDGER_MAX + 5), c.balance());    // 折叠不丢余额
    }

    @Test
    void 净增封顶超出部分不发() {
        CoinResult r = applyCoin(empty(), daily(), new CoinOp(CoinReason.LOGIN, "a", null, T0, 480), ZONE);
        CoinResult r2 = applyCoin(r.coins(), r.daily(), new CoinOp(CoinReason.GAME, "b", null, T0, 50), ZONE);
        assertEquals(20, r2.applied()); // 只剩 500−480 的空间
        assertTrue(r2.capped());
        assertEquals(500, r2.coins().balance());
        CoinResult r3 = applyCoin(r2.coins(), r2.daily(), new CoinOp(CoinReason.GAME, "c", null, T0, 5), ZONE);
        assertEquals(0, r3.applied());
        assertTrue(r3.capped());
    }

    @Test
    void 退款豁免净增上限() {
        CoinResult a = applyCoin(empty(), daily(), new CoinOp(CoinReason.LOGIN, "a", null, T0, 500), ZONE);
        CoinResult r = applyCoin(a.coins(), a.daily(), new CoinOp(CoinReason.TICKET_REFUND, "refund:x", null, T0, 100), ZONE);
        assertEquals(100, r.applied());
        assertEquals(600, r.coins().balance());
        assertEquals(500, r.daily().netGain()); // 净值不涨
    }

    @Test
    void 支出把净值拉回之后又能赚() {
        CoinResult a = applyCoin(new CoinsState(500, List.of()), daily(), new CoinOp(CoinReason.LOGIN, "a", null, T0, 500), ZONE);
        CoinResult r = applyCoin(a.coins(), a.daily(), new CoinOp(CoinReason.TICKET_FEE, "fee:1", null, T0, -100), ZONE);
        assertEquals(400, r.daily().netGain());
        CoinResult r2 = applyCoin(r.coins(), r.daily(), new CoinOp(CoinReason.GAME, "g1", null, T0, 50), ZONE);
        assertEquals(50, r2.applied());
    }

    @Test
    void 日计数login置位gameAd计数() {
        CoinResult a = applyCoin(empty(), daily(), new CoinOp(CoinReason.LOGIN, "l", null, T0, 50), ZONE);
        assertTrue(a.daily().loginDone());
        CoinResult b = applyCoin(a.coins(), a.daily(), new CoinOp(CoinReason.AD, "ad:1", null, T0, 30), ZONE);
        assertEquals(1, b.daily().adGrants());
        CoinResult c = applyCoin(b.coins(), b.daily(), new CoinOp(CoinReason.GAME, "g:1", null, T0, 5), ZONE);
        assertEquals(1, c.daily().gameGrants());
    }

    @Test
    void 跨零点日翻转() {
        long noon = 1_795_176_000_000L;                    // 2026-11-20 12:00 UTC = 沪 20:00
        long next = 1_795_219_201_000L;                    // 2026-11-21 00:00:01 UTC = 沪 08:00:01
        assertNotEquals(dayKey(noon, ZONE), dayKey(next, ZONE));
        DailyState used = applyCoin(empty(), initialDaily(noon, ZONE), new CoinOp(CoinReason.LOGIN, "l", null, noon, 50), ZONE).daily();
        assertTrue(used.loginDone());
        DailyState rolled = rollDaily(used, next, ZONE);
        assertEquals(dayKey(next, ZONE), rolled.day());
        assertFalse(rolled.loginDone());
        assertEquals(0, rolled.netGain());
    }

    @Test
    void 门票配额二十场封顶() {
        DailyState d = daily();
        for (int i = 0; i < DAILY_TICKET_MAX; i++) d = bumpTicketPlays(d, T0, ZONE);
        assertFalse(canPlayTicket(d));
    }

    @Test
    void 门票定价与奖励() {
        assertEquals(new Ticket(0, 0), TICKETS.get(TicketId.FREE));
        assertTrue(TICKETS.get(TicketId.STANDARD).reward() > TICKETS.get(TicketId.STANDARD).fee());
        assertEquals(100, TICKETS.get(TicketId.ADVANCED).fee());
    }

    @Test
    void 赛季发币() {
        assertEquals(50, seasonGrant(0));
        assertEquals(400, seasonGrant(7));
    }

    @Test
    void 完成对局二十局每日封顶其它reason不受影响() {
        CoinsState coins = empty();
        DailyState d = daily();
        for (int i = 0; i < DAILY_GAME_MAX; i++) {
            CoinResult r = applyCoin(coins, d, new CoinOp(CoinReason.GAME, "game:" + i, null, T0, GAME_GRANT), ZONE);
            assertEquals(GAME_GRANT, r.applied());
            coins = r.coins(); d = r.daily();
        }
        assertEquals(DAILY_GAME_MAX, d.gameGrants());
        CoinResult over = applyCoin(coins, d, new CoinOp(CoinReason.GAME, "game:21", null, T0, GAME_GRANT), ZONE);
        assertEquals(0, over.applied());
        assertTrue(over.capped());
        assertEquals(coins.balance(), over.coins().balance());
        CoinResult ad = applyCoin(coins, d, new CoinOp(CoinReason.AD, "ad:1", null, T0, AD_GRANT), ZONE);
        assertEquals(AD_GRANT, ad.applied());
    }
}
