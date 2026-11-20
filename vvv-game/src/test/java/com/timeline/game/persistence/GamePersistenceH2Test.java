package com.timeline.game.persistence;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.io.Reader;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.List;

import org.apache.ibatis.datasource.unpooled.UnpooledDataSource;
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
 * 七个 game mapper 的 H2 冒烟测试：证明注解 SQL 能跑、CAS/幂等语义的返回行数正确、
 * 以及 record 按 SELECT 列序位置映射的约定成立（列序错 = 字段串位 = 这里立刻红）。
 *
 * 注意：这里跑的是 db/game/h2-schema.sql（MODE=MySQL 等价表），不是真 V001；
 * 真库行为（utf8mb4_bin 大小写敏感、UPDATE...LIMIT 在 5.6 的真实表现）仍按
 * docs/game/migration.md 在预发验证。
 */
class GamePersistenceH2Test {

    private SqlSessionFactory factory;
    private SqlSession session;

    @BeforeEach
    void setUp() throws Exception {
        // 内存库每测试重建（h2-schema.sql 自带 DROP IF EXISTS），连接级隔离靠 :name 唯一化；
        // DB_CLOSE_DELAY=-1 必须带：建表用的连接关掉后 H2 默认就把 mem 库销毁，
        // MyBatis 再开连接会看到空库（"this database is empty"）。
        JdbcDataSource ds = new JdbcDataSource();
        ds.setURL("jdbc:h2:mem:game_" + System.nanoTime()
            + ";MODE=MySQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1");
        ds.setUser("sa");
        try (Connection c = ds.getConnection();
             Reader r = openH2Schema()) {
            ScriptRunner runner = new ScriptRunner(c);
            runner.setSendFullScript(false);
            runner.setStopOnError(true);
            runner.setLogWriter(new PrintWriter(new NullWriter()));
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
        factory = new SqlSessionFactoryBuilder().build(cfg);
        session = factory.openSession(true); // autocommit：CAS 返回值测试不掺事务语义
    }

    @AfterEach
    void tearDown() {
        if (session != null) session.close();
    }

    private static Reader openH2Schema() {
        InputStream in = GamePersistenceH2Test.class.getClassLoader()
            .getResourceAsStream("db/game/h2-schema.sql");
        assertNotNull(in, "h2-schema.sql 不在测试 classpath 上");
        return new InputStreamReader(in, StandardCharsets.UTF_8);
    }

    /** 空 Writer：ScriptRunner 默认把每条语句打到 stdout，测试里只要报错不要日志。 */
    private static final class NullWriter extends java.io.Writer {
        @Override public void write(char[] cbuf, int off, int len) {}
        @Override public void flush() {}
        @Override public void close() {}
    }

    private int countRows(String sql) throws Exception {
        try (Statement st = session.getConnection().createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            rs.next();
            return rs.getInt(1);
        }
    }

    // ---------------------------------------------------------------- profile

    @Test
    void profileUpsertKeepsOneRowAndSyncsNickname() throws Exception {
        GameProfileMapper m = session.getMapper(GameProfileMapper.class);
        assertEquals(1, m.upsertProfile(7L, "初见"));
        // 二次 upsert 命中 ODKU：不新增行，昵称同步为新值。
        m.upsertProfile(7L, "改名后");
        GameProfileMapper.ProfileRow row = m.profile(7L);
        // 位置映射验证：列序 (user_id, nickname)。串位的话 nickname 会是数字字符串。
        assertEquals(7L, row.userId());
        assertEquals("改名后", row.nickname());
        assertEquals(1, countRows("SELECT COUNT(*) FROM game_profile"));
        assertEquals(1, m.renameProfile(7L, "再改"));
        assertEquals("再改", m.profile(7L).nickname());
        assertEquals(1, m.touchSeen(7L));
        assertEquals(0, m.touchSeen(404L)); // 没建过档：0 行，调用方先 upsert
        assertEquals(0, m.renameProfile(404L, "无档改名"));
    }

    // ---------------------------------------------------------------- ledger

    @Test
    void ledgerInsertIgnoreIsIdempotent() {
        GameCoinLedgerMapper m = session.getMapper(GameCoinLedgerMapper.class);
        long at = 1_795_000_000_000L;
        assertEquals(1, m.insertIgnore(9L, "login:2026-11-21", "login", 50, null, at, 0));
        // uk (user_id, entry_key) 挡重复：第二次 applied=0，不是异常。
        assertEquals(0, m.insertIgnore(9L, "login:2026-11-21", "login", 50, null, at, 0));
        assertEquals(1, m.insertIgnore(9L, "game:m-1", "game", 5, "m-1", at + 1, 0));

        List<GameCoinLedgerMapper.LedgerRow> rows = m.ledger(9L, 100);
        assertEquals(2, rows.size());
        // 倒序 + 位置映射：(id, entry_key, reason, delta, ref, at_ms, capped, created_at)
        GameCoinLedgerMapper.LedgerRow newest = rows.get(0);
        assertEquals("game:m-1", newest.entryKey());
        assertEquals("game", newest.reason());
        assertEquals(5, newest.delta());
        assertEquals("m-1", newest.ref());
        assertEquals(at + 1, newest.atMs());
        assertEquals(0, newest.capped());
        assertNotNull(newest.createdAt());          // DATETIME → java.util.Date
        assertNull(rows.get(1).ref());              // NULL → null
        assertEquals(55, m.sumDelta(9L));
        assertNull(m.sumDelta(404L));               // 无流水：SUM → null，交由调用方判 0
    }

    // ---------------------------------------------------------------- wallet

    @Test
    void walletCasUpdateDayRejectsStaleDayKey() {
        GameWalletMapper m = session.getMapper(GameWalletMapper.class);
        m.insertInitial(11L, "2026-11-21");
        // 拿旧 day_key 当 CAS 条件：日切/赛跑场景 0 行 → 调用方读回重算。
        assertEquals(0, m.casUpdateDay(11L, "2026-11-22", 0, 0, 0, 0, 0, "2026-11-20"));
        assertEquals(1, m.casUpdateDay(11L, "2026-11-22", 1, 3, 2, 1, 42, "2026-11-21"));
        GameWalletMapper.WalletRow w = m.wallet(11L);
        // 位置映射：(user_id, coin_balance, day_key, login_done, game_grants, ticket_plays, ad_grants, net_gain)
        assertEquals(11L, w.userId());
        assertEquals(0, w.coinBalance());
        assertEquals("2026-11-22", w.dayKey());
        assertEquals(1, w.loginDone());
        assertEquals(3, w.gameGrants());
        assertEquals(2, w.ticketPlays());
        assertEquals(1, w.adGrants());
        assertEquals(42, w.netGain());
    }

    @Test
    void walletAddBalanceRejectsOverdraft() {
        GameWalletMapper m = session.getMapper(GameWalletMapper.class);
        m.insertInitial(12L, "2026-11-21");
        // 条件更新：coin_balance+delta>=0 挡透支，0 行 = 余额不足（不抛异常、不为负）。
        assertEquals(0, m.addBalance(12L, -1));
        assertEquals(1, m.addBalance(12L, 30));
        assertEquals(1, m.addBalance(12L, -30));
        assertEquals(0, m.addBalance(12L, -1));
        assertEquals(0, m.wallet(12L).coinBalance());
    }

    // ---------------------------------------------------------------- progress

    @Test
    void progressBoardOrdersByTierStarsWins() {
        GameProgressMapper m = session.getMapper(GameProgressMapper.class);
        // 三行种子：tier↓ stars↓ wins↓；(2,3) 一行用来验证跨段排序先于 wins。
        m.insertInitial(30L, 1);
        m.insertInitial(20L, 1);
        m.insertInitial(10L, 1);
        m.updateProgress(30L, 2, 3, 1300, 0, 5, 2, 40, 2, 3, 1, 7);
        m.updateProgress(20L, 4, 1, 1450, 0, 9, 1, 88, 4, 1, 3, 10);
        m.updateProgress(10L, 4, 1, 1200, 2, 13, 4, 60, 4, 1, 0, 13);

        List<GameProgressMapper.BoardRow> board = m.board(1, 10);
        assertEquals(3, board.size());
        // 位置映射：(user_id, tier, stars, wins)；排序 tier↓, stars↓, wins↓（SQL 里显式写死，
        // 并列时还有 user_id ASC 保证分页稳定——种子只有 3 行，这里验前三键）。
        assertEquals(new GameProgressMapper.BoardRow(10L, 4, 1, 13), board.get(0));
        assertEquals(new GameProgressMapper.BoardRow(20L, 4, 1, 9), board.get(1));
        assertEquals(new GameProgressMapper.BoardRow(30L, 2, 3, 5), board.get(2));

        // 跨季翻页（mapper 层语义，TS resetSeasonAll/crossSeason 的持久层两半）：
        // staleUserIds 按 user_id 确定性扫描且翻页后的行退出谓词，所以"打满 limit 就有下一批"
        // 必然收敛；降级结果（tier/stars）由调用方逐行用 Rank.resetSeason 算好传给 seasonCross
        // ——发奖额取决于各自旧段位，批量 SQL 给不了，mapper 只负责扫描与单行写。
        assertEquals(List.of(10L, 20L), m.staleUserIds(2, 2));
        m.seasonCross(10L, 2, 3, 4);   // resetSeason(4,1) = (3, starCap(3)-1=4)
        m.seasonCross(20L, 2, 3, 4);
        assertEquals(List.of(30L), m.staleUserIds(2, 2));
        m.seasonCross(30L, 2, 1, 2);   // resetSeason(2,3) = (1, starCap(1)-1=2)
        assertEquals(List.of(), m.staleUserIds(2, 2)); // 收敛
        GameProgressMapper.ProgressRow p = m.progress(20L);
        assertEquals(2, p.seasonNo());
        assertEquals(3, p.tier());
        assertEquals(4, p.stars());
        assertEquals(0, p.lossStreak());
        assertEquals(3, p.streak());   // 连胜保留：TS resetSeason 不碰 stats.streak（旧断言清零是错的）
        assertEquals(1450, p.mmr());        // 匹配质量保留
        assertEquals(9, p.wins());
        assertEquals(4, p.bestTier());      // 历史最高保留
        assertEquals(1, p.bestStars());
        assertEquals(10, p.scoringGames());
        // board 带赛季过滤：翻页前的 season_no=1 查不到了
        assertTrue(m.board(1, 10).isEmpty());
    }

    // ---------------------------------------------------------------- match

    @Test
    void matchClaimSettlementSecondClaimReturnsZero() throws Exception {
        GameMatchMapper m = session.getMapper(GameMatchMapper.class);
        m.insert("t1:1", 1, "duel", "standard", 2, "free", 8, 3, 1_795_000_000_000L, 2);
        // 结算抢占 CAS：第一个抢到（1 行），第二个人必须读到 0 行然后走"读回既成结果"。
        assertEquals(1, m.claimSettlement("t1:1"));
        assertEquals(0, m.claimSettlement("t1:1"));
        GameMatchMapper.MatchRow row = m.match("t1:1");
        // 位置映射：(match_id, season_no, mode, preset, capacity, ticket, started_at_ms,
        //           ended_at_ms, finished, close_reason, human_count)
        assertEquals("t1:1", row.matchId());
        assertEquals(1, row.seasonNo());
        assertEquals("duel", row.mode());
        assertEquals("standard", row.preset());
        assertEquals(2, row.capacity());
        assertEquals("free", row.ticket());
        assertEquals(1_795_000_000_000L, row.startedAtMs());
        // ended_at_ms 由 CAST(UNIX_TIMESTAMP() AS DECIMAL(20,0))*1000 写入：毫秒级、非 0、
        // 晚于开局（这同时证明 DECIMAL 乘法没被截成秒/溢出成 int）。
        assertTrue(row.endedAtMs() > row.startedAtMs());
        assertEquals(1, row.finished());
        assertEquals("", row.closeReason()); // COALESCE：NULL → ''
        assertEquals(2, row.humanCount());

        // 非正常收尾走 markClosed，不碰 finished（结算与否只归 claim CAS 管）。
        m.insert("t1:2", 1, "melee", "beginner", 4, "standard", 8, 3, 1_795_000_001_000L, 3);
        assertEquals(1, m.markClosed("t1:2", "disbanded", 1_795_000_002_000L, 1000));
        GameMatchMapper.MatchRow closed = m.match("t1:2");
        assertEquals("disbanded", closed.closeReason());
        assertEquals(0, closed.finished());          // markClosed 不碰 finished：结算仍归 CAS 管
        assertEquals(1_795_000_002_000L, closed.endedAtMs()); // markClosed 显式写入的结束时刻
    }

    @Test
    void seatsAndRecentMapNullableColumnsPositionally() {
        GameMatchMapper mm = session.getMapper(GameMatchMapper.class);
        GameMatchPlayerMapper pm = session.getMapper(GameMatchPlayerMapper.class);
        mm.insert("t2:1", 1, "duel", "standard", 2, "free", 8, 3, 1_795_000_010_000L, 1);
        pm.insert("t2:1", 0, 21L, 0, 1, null, 12, 1, 1, 1200, 1216, 1);
        // 电脑座位：user_id / final_rank / eliminated_round / mmr_* 全 NULL。
        pm.insert("t2:1", 1, null, 1, null, 3, 4, 0, 0, null, null, 0);
        mm.claimSettlement("t2:1");

        List<GameMatchPlayerMapper.SeatRow> seats = pm.seatsOfMatch("t2:1");
        assertEquals(2, seats.size());
        // 位置映射：(seat, user_id, bot, final_rank, eliminated_round, hits, win, delta_star, scoring)
        GameMatchPlayerMapper.SeatRow human = seats.get(0);
        assertEquals(0, human.seat());
        assertEquals(21L, human.userId());
        assertEquals(0, human.bot());
        assertEquals(1, human.finalRank());
        assertNull(human.eliminatedRound());
        assertEquals(12, human.hits());
        assertEquals(1, human.win());
        assertEquals(1, human.deltaStar());
        assertEquals(1, human.scoring());
        GameMatchPlayerMapper.SeatRow bot = seats.get(1);
        assertNull(bot.userId());
        assertEquals(1, bot.bot());
        assertNull(bot.finalRank());
        assertEquals(3, bot.eliminatedRound());

        // recent = match 总账 + 自己座位行联查；只回 finished=1。
        List<GameMatchMapper.RecentRow> recent = mm.recentByUser(21L, 10);
        assertEquals(1, recent.size());
        // 位置映射：(match_id, mode, preset, started_at_ms, ended_at_ms, final_rank, hits,
        //           delta_star, win, scoring)
        GameMatchMapper.RecentRow r = recent.get(0);
        assertEquals("t2:1", r.matchId());
        assertEquals("duel", r.mode());
        assertEquals("standard", r.preset());
        assertEquals(1_795_000_010_000L, r.startedAtMs());
        assertTrue(r.endedAtMs() > r.startedAtMs());
        assertEquals(1, r.finalRank());
        assertEquals(12, r.hits());
        assertEquals(1, r.deltaStar());
        assertEquals(1, r.win());
        assertEquals(1, r.scoring());
        assertTrue(mm.recentByUser(404L, 10).isEmpty());
    }

    // ---------------------------------------------------------------- season

    @Test
    void seasonEnsureIsIdempotentAndTracksGrantAndReset() {
        GameSeasonMapper m = session.getMapper(GameSeasonMapper.class);
        long start = 1_795_392_000_000L, end = start + 4L * 7 * 24 * 3600 * 1000;
        assertEquals(1, m.ensureRow(1, start, end));
        assertEquals(0, m.ensureRow(1, start, end)); // INSERT IGNORE：重复建 = 0，边界不改

        GameSeasonMapper.SeasonRow s = m.season(1);
        // 位置映射：(season_no, started_at_ms, ends_at_ms, status, granted_at, reset_at)
        assertEquals(1, s.seasonNo());
        assertEquals(start, s.startedAtMs());
        assertEquals(end, s.endsAtMs());
        assertEquals("ACTIVE", s.status());  // DDL 默认值
        assertNull(s.grantedAt());
        assertNull(s.resetAt());

        assertEquals(1, m.markGranted(1));
        assertNotNull(m.season(1).grantedAt());   // 跑批续点标记：非 null 即已发奖
        assertEquals(1, m.markReset(1));
        assertNotNull(m.season(1).resetAt());
        assertEquals(1, m.closeSeason(1));
        assertEquals("CLOSED", m.season(1).status());
        assertNull(m.season(404));               // 无此赛季：null，调用方先 ensureRow
    }
}
