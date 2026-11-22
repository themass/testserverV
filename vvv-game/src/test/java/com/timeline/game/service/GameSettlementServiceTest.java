package com.timeline.game.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.timeline.game.domain.Coins;
import com.timeline.game.domain.GameTypes;
import com.timeline.game.persistence.GameCoinLedgerMapper;
import com.timeline.game.persistence.GameMatchMapper;
import com.timeline.game.persistence.GameMatchPlayerMapper;
import com.timeline.game.persistence.GameProfileMapper;
import com.timeline.game.persistence.GameProgressMapper;
import com.timeline.game.persistence.GameSeasonMapper;
import com.timeline.game.persistence.GameShotMapper;
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
 * GameSettlementService 在 H2（MODE=MySQL）上的契约测试（建库方式与 GamePersistenceH2Test 同款）：
 * 结算抢占幂等、friend 桌不记账、人机局冻结段位（战绩口径按 TS profile.ts）、
 * 计分段升星与 best_*、门票胜奖只发一次、退款豁免净增上限。
 */
class GameSettlementServiceTest {

    private static final ZoneId ZONE = ZoneId.of("Asia/Shanghai");
    private static final long AT = 1_795_000_000_000L;
    private static final long START = AT - 120_000L; // 开早两分钟，duration 恒正

    private SqlSession session;
    private GameMatchMapper matchMapper;
    private GameMatchPlayerMapper matchPlayerMapper;
    private GameProgressMapper progressMapper;
    private GameWalletMapper walletMapper;
    private GameCoinLedgerMapper ledgerMapper;
    private GameShotMapper shotMapper;
    private GameSettlementService svc;

    @BeforeEach
    void setUp() throws Exception {
        // 内存库每测试重建；:name 唯一化 + DB_CLOSE_DELAY=-1 的原因见 GamePersistenceH2Test 注释。
        JdbcDataSource ds = new JdbcDataSource();
        ds.setURL("jdbc:h2:mem:settle_" + System.nanoTime()
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
        cfg.addMapper(GameShotMapper.class);
        SqlSessionFactory factory = new SqlSessionFactoryBuilder().build(cfg);
        session = factory.openSession(true);
        matchMapper = session.getMapper(GameMatchMapper.class);
        matchPlayerMapper = session.getMapper(GameMatchPlayerMapper.class);
        progressMapper = session.getMapper(GameProgressMapper.class);
        walletMapper = session.getMapper(GameWalletMapper.class);
        ledgerMapper = session.getMapper(GameCoinLedgerMapper.class);
        shotMapper = session.getMapper(GameShotMapper.class);
        svc = new GameSettlementService(matchMapper, matchPlayerMapper, progressMapper,
            session.getMapper(GameProfileMapper.class),
            new GameWalletService(walletMapper, ledgerMapper), shotMapper, ZONE);
    }

    @AfterEach
    void tearDown() {
        if (session != null) session.close();
    }

    private static Reader openH2Schema() {
        InputStream in = GameSettlementServiceTest.class.getClassLoader()
            .getResourceAsStream("db/game/h2-schema.sql");
        assertNotNull(in, "h2-schema.sql 不在测试 classpath 上");
        return new InputStreamReader(in, StandardCharsets.UTF_8);
    }

    // ---------------------------------------------------------------- 夹具

    /** 两人局：seat0=10（第 1 名 7 中），seat1=20（第 2 名第 3 轮出局 4 中）。 */
    private static GameTypes.GameResult duel10Beats20() {
        return new GameTypes.GameResult(GameTypes.GameOverReason.LAST_STANDING, List.of(
            new GameTypes.RankEntry("10", 1, null, 7),
            new GameTypes.RankEntry("20", 2, 3, 4)));
    }

    private static GameSettlementService.GameContext ctx(String gameId, GameTypes.TableKind kind,
                                                         Coins.TicketId ticket, boolean withBots,
                                                         List<Long> humans, GameTypes.GameResult result) {
        return new GameSettlementService.GameContext(gameId, kind, "duel", "standard", 2,
            ticket, humans, result, withBots, AT);
    }

    private void recordTwoHumans(String gameId) {
        svc.recordStart(gameId, 1, "duel", "standard", 2, "free", 10, 1, START, List.of(10L, 20L));
    }

    private long ledgerCount(long userId, String prefix) {
        return ledgerMapper.ledger(userId, 100).stream()
            .filter(r -> r.entryKey().startsWith(prefix)).count();
    }

    // ---------------------------------------------------------------- 抢占与幂等

    @Test
    void settleClaimsOnceAndReplayIsNoOp() {
        recordTwoHumans("t1:1");
        // 骨架行：crash-sweep 审计认出"开了没结"；final_rank 此时必须还是 NULL。
        GameMatchPlayerMapper.SeatRow skeleton = matchPlayerMapper.seatsOfMatch("t1:1").get(0);
        assertNull(skeleton.finalRank());

        GameSettlementService.SettleOutcome first =
            svc.settle(ctx("t1:1", GameTypes.TableKind.MATCH, null, false, List.of(10L, 20L), duel10Beats20()));
        assertTrue(first.claimed());
        assertEquals(2, first.deltas().size());
        assertEquals(5, first.deltas().get(0).coinApplied());
        assertEquals(10L, first.deltas().get(0).userId());
        assertEquals(5, walletMapper.wallet(10L).coinBalance());
        assertEquals(5, walletMapper.wallet(20L).coinBalance());

        GameMatchMapper.MatchRow row = matchMapper.match("t1:1");
        assertEquals(1, row.finished());
        assertEquals("finished", row.closeReason());

        // 重放：finished CAS 抢不到 → claimed=false，币/星/座位行都一个字不再动。
        GameSettlementService.SettleOutcome second =
            svc.settle(ctx("t1:1", GameTypes.TableKind.MATCH, null, false, List.of(10L, 20L), duel10Beats20()));
        assertFalse(second.claimed());
        assertTrue(second.deltas().isEmpty());
        assertEquals(5, walletMapper.wallet(10L).coinBalance());
        assertEquals(1, ledgerCount(10L, "game:"));
    }

    @Test
    void friendTableIsNeverRecorded() {
        // friend 桌：调用方没记 match 行，这里也必须立即 claimed=false 且不留任何痕迹。
        GameSettlementService.SettleOutcome out =
            svc.settle(ctx("fr:1", GameTypes.TableKind.FRIEND, null, false, List.of(10L, 20L), duel10Beats20()));
        assertFalse(out.claimed());
        assertTrue(out.deltas().isEmpty());
        assertNull(walletMapper.wallet(10L));
        assertNull(progressMapper.progress(10L));
    }

    // ---------------------------------------------------------------- 人机局

    @Test
    void withBotsFreezesRankAndOnlyMovesTotalHits() {
        // TS profile.ts record() 185-200 行（有意差异以 TS 为准）：电脑局只涨 totalHits，
        // wins/losses/streak/scoringGames 与段位/MMR 全冻结（apply===null 分支外不发战绩）。
        svc.recordStart("t2:1", 1, "practice", "standard", 2, "free", 10, 1, START, java.util.Arrays.asList(10L, null));
        GameSettlementService.GameContext c =
            ctx("t2:1", GameTypes.TableKind.PRACTICE, null, true, List.of(10L), duel10Beats20());

        GameSettlementService.SettleOutcome out = svc.settle(c);
        assertTrue(out.claimed());
        GameProgressMapper.ProgressRow p = progressMapper.progress(10L);
        assertEquals(0, p.tier());
        assertEquals(0, p.stars());
        assertEquals(1200, p.mmr());
        assertEquals(0, p.wins());          // 人机局不涨胜负（TS 口径）
        assertEquals(0, p.losses());
        assertEquals(0, p.streak());
        assertEquals(0, p.scoringGames());
        assertEquals(7, p.totalHits());     // 唯独总命中每局都进
        assertEquals(0, out.deltas().get(0).deltaStar());  // 计分段外的星数变化恒 0
        assertEquals(5, out.deltas().get(0).coinApplied()); // 完成币人机局照发
    }

    @Test
    void withBotsSeatRowRecordsResultWithoutScoring() {
        svc.recordStart("t2:2", 1, "practice", "standard", 2, "free", 10, 1, START, java.util.Arrays.asList(10L, null));
        svc.settle(ctx("t2:2", GameTypes.TableKind.PRACTICE, null, true, List.of(10L), duel10Beats20()));

        List<GameMatchPlayerMapper.SeatRow> seats = matchPlayerMapper.seatsOfMatch("t2:2");
        GameMatchPlayerMapper.SeatRow human = seats.get(0);
        assertEquals(1, human.finalRank());
        assertEquals(7, human.hits());
        assertEquals(1, human.win());
        assertEquals(0, human.deltaStar()); // 计分冻结：deltaStar 恒 0
        assertEquals(0, human.scoring());
        // bot 骨架行原样保留：user_id NULL 不会被 updateResult 误中。
        GameMatchPlayerMapper.SeatRow bot = seats.get(1);
        assertNull(bot.userId());
        assertEquals(1, bot.bot());
        // +5 完成币人机局照发（spec §6.1"bot 局发 +5 完成币"）。
        assertEquals(5, walletMapper.wallet(10L).coinBalance());
    }

    // ---------------------------------------------------------------- 计分局

    @Test
    void scoringWinGainsStarMmrAndBestAndUpdatesSeatRow() {
        recordTwoHumans("t3:1");
        GameSettlementService.SettleOutcome out =
            svc.settle(ctx("t3:1", GameTypes.TableKind.MATCH, null, false, List.of(10L, 20L), duel10Beats20()));
        assertTrue(out.claimed());

        // 对手分 = 其他真人均值 = 1200 → Elo 增量 round(32·(1−0.5))=+16；升 1 星。
        GameProgressMapper.ProgressRow w = progressMapper.progress(10L);
        assertEquals(0, w.tier());
        assertEquals(1, w.stars());
        assertEquals(1216, w.mmr());
        assertEquals(1, w.wins());
        assertEquals(0, w.losses());
        assertEquals(1, w.streak());
        assertEquals(0, w.lossStreak());
        assertEquals(1, w.scoringGames());
        assertEquals(0, w.bestTier());      // 先段后星：同段星数更高 → best_stars 跟进
        assertEquals(1, w.bestStars());

        GameProgressMapper.ProgressRow l = progressMapper.progress(20L);
        assertEquals(0, l.stars());         // 列兵 0 星不跌（垫底保护）
        assertEquals(1184, l.mmr());        // 同分输 → −16
        assertEquals(1, l.losses());
        assertEquals(1, l.scoringGames());

        // 座位行回写（updateResult 按 (match_id, user_id) 定位骨架行）。
        GameMatchPlayerMapper.SeatRow seat = matchPlayerMapper.seatsOfMatch("t3:1").get(0);
        assertEquals(1, seat.finalRank());
        assertEquals(1, seat.win());
        assertEquals(1, seat.deltaStar());
        assertEquals(1, seat.scoring());
        assertEquals(1, out.deltas().get(0).deltaStar());
        assertNull(seat.eliminatedRound());
    }

    // ---------------------------------------------------------------- 门票

    @Test
    void ticketWinRewardPaidOnceToWinnerOnly() {
        recordTwoHumans("t4:1");
        GameSettlementService.SettleOutcome out = svc.settle(
            ctx("t4:1", GameTypes.TableKind.MATCH, Coins.TicketId.STANDARD, false,
                List.of(10L, 20L), duel10Beats20()));
        assertTrue(out.claimed());
        // 胜者：+5 完成币 + 80 门票胜奖；败者只损失门票费（这里没收，不在这结）。
        assertEquals(85, walletMapper.wallet(10L).coinBalance());
        assertEquals(5, walletMapper.wallet(20L).coinBalance());
        assertEquals(1, ledgerCount(10L, "ticket-win:"));
        assertEquals(0, ledgerCount(20L, "ticket-win:"));

        // 重放不双发：claim 挡住后连 entry_key 都不会再碰。
        assertFalse(svc.settle(ctx("t4:1", GameTypes.TableKind.MATCH, Coins.TicketId.STANDARD, false,
            List.of(10L, 20L), duel10Beats20())).claimed());
        assertEquals(85, walletMapper.wallet(10L).coinBalance());
        assertEquals(1, ledgerCount(10L, "ticket-win:"));
    }

    @Test
    void ticketRefundIsExemptFromDailyNetCap() {
        // 净增已到 499/500：普通 +50 会被截成 1，退款（还回自己的钱）必须整额 50 进、
        // net_gain 纹丝不动（Coins.netExempt 的落库验证，spec §6.1）。
        String day = Coins.dayKey(AT, ZONE);
        svc.recordStart("t5:0", 1, "duel", "standard", 2, "standard", 10, 1, START, List.of(30L));
        walletMapper.insertInitial(30L, day);
        walletMapper.addBalance(30L, 10); // 先垫 10 币当"被扣过门票"的余额基线
        walletMapper.casUpdateDay(30L, day, 0, 0, 0, 0, 499, day);

        GameWalletService.GrantResult r =
            svc.refundTicket(30L, Coins.TicketId.STANDARD, "t5:0", AT);
        assertEquals(50, r.applied());
        assertFalse(r.capped());
        assertEquals(60, r.balance());
        assertEquals(499, r.daily().netGain());
        assertEquals(60, walletMapper.wallet(30L).coinBalance());
        assertEquals(499, walletMapper.wallet(30L).netGain());

        // 对照：同额普通收入（广告 +30）会被截到只剩 1，并打上 capped。
        GameWalletService.GrantResult capped = new GameWalletService(walletMapper, ledgerMapper)
            .grant(30L, new Coins.CoinOp(Coins.CoinReason.AD, "ad:" + day + ":1", "slot",
                AT, Coins.AD_GRANT), ZONE);
        assertEquals(1, capped.applied());
        assertTrue(capped.capped());
        assertEquals(500, walletMapper.wallet(30L).netGain());
    }

    @Test
    void settleWritesShotsOnceInSeqOrder() {
        recordTwoHumans("t6:0");
        // 电脑发炮 byUser=null；seq 由 settle 按列表序 0..n-1 赋，重放（抢占失败）不重插。
        var shots = List.of(
            new GameSettlementService.ShotRecord(10L, 20L, 7, 7, "head", "p1", START + 1000),
            new GameSettlementService.ShotRecord(null, 10L, 2, 2, "miss", "p0", START + 2000));
        var out = svc.settle(ctx("t6:0", GameTypes.TableKind.MATCH, null, false,
            List.of(10L, 20L), duel10Beats20()), shots);
        assertTrue(out.claimed());

        var rows = shotMapper.shotsOfMatch("t6:0");
        assertEquals(2, rows.size());
        assertEquals(10L, rows.get(0).byUser());
        assertEquals(20L, rows.get(0).targetUser());
        assertEquals("head", rows.get(0).result());
        assertEquals(7, rows.get(0).rowNo());
        assertNull(rows.get(1).byUser());          // 电脑发炮
        assertEquals("miss", rows.get(1).result());

        // 重放：claimed=false 且明细一条不加（uk(match_id,seq) 之前，抢占闸门先挡住）。
        var again = svc.settle(ctx("t6:0", GameTypes.TableKind.MATCH, null, false,
            List.of(10L, 20L), duel10Beats20()), shots);
        assertFalse(again.claimed());
        assertEquals(2, shotMapper.countByMatch("t6:0"));

        // 空明细照常结算（melee 之外/装配缺 shotMapper 的等价路径）。
        recordTwoHumans("t6:1");
        assertTrue(svc.settle(ctx("t6:1", GameTypes.TableKind.MATCH, null, false,
            List.of(10L, 20L), duel10Beats20())).claimed());
        assertEquals(0, shotMapper.countByMatch("t6:1"));
    }
}
