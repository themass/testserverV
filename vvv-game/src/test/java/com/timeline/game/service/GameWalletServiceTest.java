package com.timeline.game.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.timeline.game.domain.Coins;
import com.timeline.game.persistence.GameCoinLedgerMapper;
import com.timeline.game.persistence.GameMatchMapper;
import com.timeline.game.persistence.GameMatchPlayerMapper;
import com.timeline.game.persistence.GameProfileMapper;
import com.timeline.game.persistence.GameProgressMapper;
import com.timeline.game.persistence.GameSeasonMapper;
import com.timeline.game.persistence.GameWalletMapper;

import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.time.ZoneId;
import java.util.List;

import org.apache.ibatis.jdbc.ScriptRunner;
import org.apache.ibatis.mapping.Environment;
import org.apache.ibatis.session.Configuration;
import org.apache.ibatis.session.SqlSession;
import org.apache.ibatis.session.SqlSessionFactory;
import org.apache.ibatis.session.SqlSessionFactoryBuilder;
import org.apache.ibatis.transaction.jdbc.JdbcTransactionFactory;
import org.h2.jdbcx.JdbcDataSource;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * GameWalletService 在 H2（MODE=MySQL）上的行为测试（建库方式与 GamePersistenceH2Test 同款）：
 * 幂等（uk entry_key）、日切覆盖、透支拒绝、门票配额；跨日 CAS 让渡分支用假 mapper 确定性地打。
 */
class GameWalletServiceTest {

    private static final ZoneId ZONE = ZoneId.of("Asia/Shanghai");
    private static final long AT = 1_795_000_000_000L; // 2026-11-19（上海时区）

    private SqlSession session;
    private GameWalletMapper walletMapper;
    private GameCoinLedgerMapper ledgerMapper;
    private GameWalletService svc;

    @BeforeEach
    void setUp() throws Exception {
        // 内存库每测试重建（h2-schema.sql 自带 DROP IF EXISTS），:name 唯一化 + DB_CLOSE_DELAY=-1
        // 的原因见 GamePersistenceH2Test 的同名注释。
        JdbcDataSource ds = new JdbcDataSource();
        ds.setURL("jdbc:h2:mem:walletsvc_" + System.nanoTime()
            + ";MODE=MySQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1");
        ds.setUser("sa");
        try (Connection c = ds.getConnection(); Reader r = openH2Schema()) {
            ScriptRunner runner = new ScriptRunner(c);
            runner.setSendFullScript(false);
            runner.setStopOnError(true);
            runner.setLogWriter(new java.io.PrintWriter(new java.io.Writer() {
                @Override public void write(char[] cbuf, int off, int len) {}
                @Override public void flush() {}
                @Override public void close() {}
            }));
            runner.setErrorLogWriter(null);
            runner.runScript(r);
        }
        Configuration cfg = new Configuration(
            new Environment("h2", new JdbcTransactionFactory(), ds));
        cfg.addMapper(GameProfileMapper.class);
        cfg.addMapper(GameProgressMapper.class);
        cfg.addMapper(GameWalletMapper.class);
        cfg.addMapper(GameCoinLedgerMapper.class);
        cfg.addMapper(GameMatchMapper.class);
        cfg.addMapper(GameMatchPlayerMapper.class);
        cfg.addMapper(GameSeasonMapper.class);
        SqlSessionFactory factory = new SqlSessionFactoryBuilder().build(cfg);
        session = factory.openSession(true); // autocommit：CAS 返回值测试不掺事务语义
        walletMapper = session.getMapper(GameWalletMapper.class);
        ledgerMapper = session.getMapper(GameCoinLedgerMapper.class);
        svc = new GameWalletService(walletMapper, ledgerMapper);
    }

    @AfterEach
    void tearDown() {
        if (session != null) session.close();
    }

    private static Reader openH2Schema() {
        InputStream in = GameWalletServiceTest.class.getClassLoader()
            .getResourceAsStream("db/game/h2-schema.sql");
        assertNotNull(in, "h2-schema.sql 不在测试 classpath 上");
        return new InputStreamReader(in, StandardCharsets.UTF_8);
    }

    private static Coins.CoinOp op(Coins.CoinReason reason, String id, String ref, int delta) {
        return new Coins.CoinOp(reason, id, ref, AT, delta);
    }

    // ---------------------------------------------------------------- 幂等

    @Test
    void grantIsIdempotentByEntryKey() {
        String day = Coins.dayKey(AT, ZONE);
        svc.ensureWallet(1L, day);
        svc.ensureWallet(1L, day); // 二次建档 no-op：没建第二行

        Coins.CoinOp op = op(Coins.CoinReason.GAME, "game:m1:1", "m1", Coins.GAME_GRANT);
        GameWalletService.GrantResult r1 = svc.grant(1L, op, ZONE);
        assertEquals(5, r1.applied());
        assertFalse(r1.capped());
        assertFalse(r1.insufficient());
        assertEquals(5, r1.balance());
        assertEquals(1, r1.daily().gameGrants());

        // 重放同 entry_key：uk_game_coin_ledger_entry 挡住 → applied=0、余额不动、流水不翻倍。
        GameWalletService.GrantResult r2 = svc.grant(1L, op, ZONE);
        assertEquals(0, r2.applied());
        assertFalse(r2.insufficient());
        assertEquals(5, r2.balance());
        assertEquals(5, svc.balance(1L));
        assertEquals(1, ledgerMapper.ledger(1L, 100).size());
        assertEquals(5, ledgerMapper.sumDelta(1L));
        assertEquals(1, walletMapper.wallet(1L).gameGrants());
    }

    // ---------------------------------------------------------------- 日切

    @Test
    void grantRollsDayAndOverwritesCountersViaCas() {
        // 存档是"昨天"的：满额旧计数应被新日整行覆盖（原地换新，旧值作废）。
        walletMapper.insertInitial(2L, "2026-1-1");
        walletMapper.casUpdateDay(2L, "2026-1-1", 1, 20, 20, 5, 500, "2026-1-1");

        GameWalletService.GrantResult r = svc.grant(2L,
            op(Coins.CoinReason.GAME, "game:m2:2", "m2", Coins.GAME_GRANT), ZONE);
        assertEquals(5, r.applied());
        assertEquals(Coins.dayKey(AT, ZONE), r.daily().day());
        assertEquals(1, r.daily().gameGrants());
        assertEquals(5, r.daily().netGain());

        GameWalletMapper.WalletRow w = walletMapper.wallet(2L);
        assertEquals(Coins.dayKey(AT, ZONE), w.dayKey());
        assertEquals(1, w.gameGrants());
        assertEquals(0, w.loginDone()); // 新日计数从 0 起，不带旧值
        assertEquals(5, w.netGain());
        assertEquals(5, w.coinBalance());
    }

    @Test
    void crossDayCasFailureGivesUpAndReturnsFreshDailyState() {
        // 真库没法把"读后写之间日切"插进单线程测试，用假 mapper 确定性打这条让渡分支：
        // 读回旧日行 → CAS 恒 0（赛跑输了）→ 读回新日行，本笔让渡（applied=0），
        // daily 如实反映新日重算结果；绝不拿旧算结果覆盖新日计数。
        String freshDay = Coins.dayKey(AT, ZONE);
        GameWalletService fakeSvc = new GameWalletService(
            new StaleCasWallet(freshDay), new NoopLedger());

        GameWalletService.GrantResult r = fakeSvc.grant(3L,
            op(Coins.CoinReason.GAME, "game:m3:3", "m3", Coins.GAME_GRANT), ZONE);
        assertEquals(0, r.applied());
        assertFalse(r.capped());
        assertFalse(r.insufficient());
        assertEquals(100, r.balance());          // 余额以让渡后的读回值报
        assertEquals(freshDay, r.daily().day());
        assertEquals(5, r.daily().netGain());    // 新日重算：这笔会进新日，但本请求不落账
    }

    /** CAS 恒失败的钱包假件：第一次读到旧日行，重算路径读回新日行。 */
    private static final class StaleCasWallet implements GameWalletMapper {
        private final String freshDay;
        private int walletCalls;

        StaleCasWallet(String freshDay) { this.freshDay = freshDay; }

        @Override
        public WalletRow wallet(long userId) {
            walletCalls++;
            return walletCalls == 1
                ? new WalletRow(userId, 100, "2026-11-18", 0, 0, 0, 0, 40)  // 读档：旧日
                : new WalletRow(userId, 100, freshDay, 0, 0, 0, 0, 0);      // 赛跑输了后的新日行
        }
        @Override public int insertInitial(long userId, String dayKey) { return 1; }
        @Override public int casUpdateDay(long userId, String dayKey, int loginDone,
                                          int gameGrants, int ticketPlays, int adGrants,
                                          int netGain, String oldDayKey) { return 0; }
        @Override public int addBalance(long userId, int delta) { return 1; }
    }

    /** 恒成功的一次性流水假件（让渡分支只关心钱包侧）。 */
    private static final class NoopLedger implements GameCoinLedgerMapper {
        @Override public int insertIgnore(long userId, String entryKey, String reason,
                                          int delta, String ref, long atMs, int capped) { return 1; }
        @Override public List<LedgerRow> ledger(long userId, int limit) { return List.of(); }
        @Override public Integer sumDelta(long userId) { return 0; }
    }

    // ---------------------------------------------------------------- 余额

    @Test
    void ticketFeeOverdraftIsRejectedWithoutLedger() {
        svc.ensureWallet(4L, Coins.dayKey(AT, ZONE));
        // 先垫 30 币（走退款通道入账，免净增上限，纯粹当本金用）。
        svc.grant(4L, op(Coins.CoinReason.TICKET_REFUND, "ticket-refund:seed", "seed", 30), ZONE);

        GameWalletService.GrantResult r = svc.grant(4L,
            op(Coins.CoinReason.TICKET_FEE, "ticket-fee:t1", "t1",
                -Coins.TICKETS.get(Coins.TicketId.STANDARD).fee()), ZONE);
        assertTrue(r.insufficient());
        assertEquals(0, r.applied());
        assertEquals(30, r.balance());
        assertEquals(30, svc.balance(4L));
        assertEquals(1, ledgerMapper.ledger(4L, 100).size()); // 只有垫本金那笔
        // 没建过档也判得动：余额 0 直接不足
        assertTrue(svc.grant(404L,
            op(Coins.CoinReason.TICKET_FEE, "ticket-fee:t2", "t2", -100), ZONE).insufficient());
    }

    // ---------------------------------------------------------------- 配额

    @Test
    void ticketQuotaCountsUpToDailyMax() {
        svc.ensureWallet(5L, Coins.dayKey(AT, ZONE));
        assertTrue(svc.canPlayTicket(5L, AT, ZONE));
        for (int i = 0; i < Coins.DAILY_TICKET_MAX; i++) {
            assertTrue(svc.bumpTicketPlays(5L, AT, ZONE), "第 " + (i + 1) + " 次 bump 应成功");
        }
        assertFalse(svc.canPlayTicket(5L, AT, ZONE)); // 满 20/日 → 拒
        assertEquals(Coins.DAILY_TICKET_MAX, walletMapper.wallet(5L).ticketPlays());
        assertFalse(svc.canPlayTicket(404L, AT, ZONE)); // 没建过档 = 拒
        // bump 让渡语义由 StaleCasWallet 路径覆盖；这里验证 H2 上 CAS 成功路径不翻倍。
        svc.ensureWallet(6L, "2026-1-1");
        assertTrue(svc.bumpTicketPlays(6L, AT, ZONE));
        assertEquals(1, walletMapper.wallet(6L).ticketPlays());
        assertEquals(Coins.dayKey(AT, ZONE), walletMapper.wallet(6L).dayKey());
    }

    @Test
    void snapshotReportsBalanceAndDailyShell() {
        svc.ensureWallet(7L, Coins.dayKey(AT, ZONE));
        svc.grant(7L, op(Coins.CoinReason.AD, "ad:" + Coins.dayKey(AT, ZONE) + ":1", "slot", Coins.AD_GRANT), ZONE);
        GameWalletService.WalletSnapshot s = svc.snapshot(7L, ZONE);
        assertEquals(30, s.balance());
        assertEquals(1, s.daily().adGrants());
        assertEquals(30, s.daily().netGain());
        // 没建过档：0 币 + 全零日计数（兜底键取此刻，不建档）。
        GameWalletService.WalletSnapshot empty = svc.snapshot(404L, ZONE);
        assertEquals(0, empty.balance());
        assertEquals(0, empty.daily().netGain());
    }
}
