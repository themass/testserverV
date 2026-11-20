package com.timeline.game.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.timeline.game.domain.Coins;
import com.timeline.game.domain.Rank;
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
 * GameSeasonService 在 H2（MODE=MySQL）上的契约测试（建库方式与 GamePersistenceH2Test 同款）：
 * 跨季降级逐字段对齐 TS rank.ts resetSeason（降级满星、连胜保留、mmr 保留）、
 * (tier+1)×50 奖励发一次不双发、懒路径与 sweep 共用幂等键、审计锚点（game_season 行）两条路一致。
 */
class GameSeasonServiceTest {

    private static final ZoneId ZONE = ZoneId.of("Asia/Shanghai");
    /** 第 1 赛季内任意时刻。 */
    private static final long S1 = Rank.SEASON_EPOCH_MS + 60_000L;
    /** 第 2 赛季内任意时刻。 */
    private static final long S2 = Rank.SEASON_EPOCH_MS + Rank.SEASON_MS + 60_000L;

    private SqlSession session;
    private GameProgressMapper progress;
    private GameSeasonMapper seasons;
    private GameWalletMapper wallet;
    private GameCoinLedgerMapper ledger;
    private GameSeasonService svc;

    @BeforeEach
    void setUp() {
        JdbcDataSource ds = new JdbcDataSource();
        ds.setURL("jdbc:h2:mem:season_" + System.nanoTime()
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
        } catch (Exception e) {
            throw new RuntimeException(e);
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
        session = factory.openSession(true);
        progress = session.getMapper(GameProgressMapper.class);
        seasons = session.getMapper(GameSeasonMapper.class);
        wallet = session.getMapper(GameWalletMapper.class);
        ledger = session.getMapper(GameCoinLedgerMapper.class);
        svc = new GameSeasonService(progress, seasons,
            new GameWalletService(wallet, ledger), ZONE);
    }

    @AfterEach
    void tearDown() {
        if (session != null) session.close();
    }

    private static Reader openH2Schema() {
        InputStream in = GameSeasonServiceTest.class.getClassLoader()
            .getResourceAsStream("db/game/h2-schema.sql");
        assertNotNull(in, "h2-schema.sql 不在测试 classpath 上");
        return new InputStreamReader(in, StandardCharsets.UTF_8);
    }

    private void seed(long userId, int seasonNo, int tier, int stars, int mmr) {
        progress.insertInitial(userId, seasonNo);
        progress.updateProgress(userId, tier, stars, mmr, 2, 5, 3, 42, tier, stars, 4, 9);
        wallet.insertInitial(userId, Coins.dayKey(S2, ZONE));
    }

    // ---------------------------------------------------------------- crossUser

    @Test
    void crossUserDemotesWithFullStarsKeepsStreakAndPaysGrant() {
        seed(10L, 1, 4, 1, 1450);
        // 上一季行存在时（比如 DBA 手建或更早一次翻页建的）跨季要把它收掉；
        // 不存在时 closeSeason 是无害空操作——审计只认 ACTIVE 的 MAX(season_no)。
        seasons.ensureRow(1, Rank.SEASON_EPOCH_MS, Rank.SEASON_EPOCH_MS + Rank.SEASON_MS);
        int paid = svc.crossUser(10L, 2, S2);
        // 段位奖励 (4+1)×50=250；TS crossSeason 先按旧段位发再降级。
        assertEquals(250, paid);
        var p = progress.progress(10L);
        assertEquals(2, p.seasonNo());
        // resetSeason(4,1) = (3, starCap(3)-1=4)；mmr/连胜/统计保留，连败清零。
        assertEquals(3, p.tier());
        assertEquals(4, p.stars());
        assertEquals(1450, p.mmr());
        assertEquals(0, p.lossStreak());
        assertEquals(4, p.streak());
        assertEquals(5, p.wins());
        assertEquals(4, p.bestTier());   // 历史最高不回退
        assertEquals(250, wallet.wallet(10L).coinBalance());
        // 审计锚点：新季行建出、旧季收掉。
        assertNotNull(seasons.season(2));
        assertEquals("CLOSED", seasons.season(1).status());
    }

    @Test
    void crossUserOnLowestTierOnlyFlipsSeason() {
        seed(11L, 1, 0, 2, 1200);
        int paid = svc.crossUser(11L, 2, S2);
        assertEquals(Coins.seasonGrant(0), paid);   // (0+1)×50 = 50 照发
        var p = progress.progress(11L);
        assertEquals(0, p.tier());                  // 列兵没有"降 1 级"，原样保留
        assertEquals(2, p.stars());
        assertEquals(2, p.seasonNo());
    }

    @Test
    void crossUserTwiceGrantsOnce() {
        seed(12L, 1, 3, 0, 1300);
        assertEquals(200, svc.crossUser(12L, 2, S2));
        // 第二次：season_no 已是 2，直接 no-op；就算绕过前置判断，entry_key 也挡双发。
        assertEquals(0, svc.crossUser(12L, 2, S2));
        assertEquals(200, wallet.wallet(12L).coinBalance());
    }

    @Test
    void seasonGrantIsNetCapExempt() {
        // 净增已顶满 500：普通 +30 广告会被截成 0 空间（QUOTA 由调用方判），
        // 但 season-grant 豁免净增——500 余额上照发全额。
        seed(13L, 1, 2, 0, 1200);
        wallet.addBalance(13L, 500);
        wallet.casUpdateDay(13L, Coins.dayKey(S2, ZONE), 0, 0, 0, 0, 500,
            Coins.dayKey(S2, ZONE));
        assertEquals(150, svc.crossUser(13L, 2, S2));
        assertEquals(650, wallet.wallet(13L).coinBalance());
    }

    // ---------------------------------------------------------------- sweep

    @Test
    void sweepConvergesAndMarksSeasonDone() {
        seed(20L, 1, 1, 0, 1200);
        seed(21L, 1, 2, 0, 1200);
        seed(22L, 1, 3, 0, 1200);
        assertEquals(2, svc.sweep(S2, 2));
        assertEquals(1, svc.sweep(S2, 2));
        assertEquals(0, svc.sweep(S2, 2));          // 收敛：常态每 tick 就这一次空扫描
        var row = seasons.season(2);
        assertNotNull(row.grantedAt());              // 收敛批才打全局标记
        assertNotNull(row.resetAt());
        assertEquals(2, progress.progress(22L).seasonNo());
        // 奖励按各自旧段位：(1+1)×50 + (2+1)×50 + (3+1)×50 = 300
        assertEquals(100, wallet.wallet(20L).coinBalance());
        assertEquals(150, wallet.wallet(21L).coinBalance());
        assertEquals(200, wallet.wallet(22L).coinBalance());
    }

    @Test
    void sweepDoesNotMarkWhileStaleRemain() {
        seed(23L, 1, 1, 0, 1200);
        seed(24L, 1, 1, 0, 1200);
        assertEquals(1, svc.sweep(S2, 1));
        assertTrue(seasons.season(2) != null && seasons.season(2).grantedAt() == null);
    }

    // ---------------------------------------------------------------- 懒路径接入

    @Test
    void profileLazyPathPaysOnceSharedWithSweep() {
        seed(30L, 1, 5, 0, 1200);
        var profiles = session.getMapper(GameProfileMapper.class);
        var matches = session.getMapper(GameMatchMapper.class);
        var ps = new GameProfileService(profiles, progress, wallet, ledger, matches, svc, ZONE);
        profiles.upsertProfile(30L, "老李");
        // 首读即懒翻页：发 (5+1)×50=300、降级 (4,4)。
        var view = ps.profile(30L, "老李", S2);
        assertEquals(4, view.rank().tier());
        assertEquals(4, view.rank().stars());
        assertEquals(300, view.coins().balance());
        // tick 的 sweep 再扫：season_no 已对齐，一分钱都不再发。
        assertEquals(0, svc.sweep(S2, 10));
        assertEquals(300, wallet.wallet(30L).coinBalance());
    }

    @Test
    void nullSeasonServiceDisablesLazyFlipWithoutCrash() {
        seed(31L, 1, 2, 0, 1200);
        var profiles = session.getMapper(GameProfileMapper.class);
        var ps = new GameProfileService(profiles, progress, wallet, ledger,
            session.getMapper(GameMatchMapper.class), null, ZONE);
        profiles.upsertProfile(31L, "老张");
        var view = ps.profile(31L, "老张", S2);
        // 没接赛季服务：如实回旧季段位，不翻页不发币（测试/降级形态）。
        // ProfileView.season 永远是此刻的赛季号（来自时钟）；"没翻页"的证据是 progress 行。
        assertEquals(2, view.season());
        assertEquals(1, progress.progress(31L).seasonNo());
        assertEquals(2, view.rank().tier());
        assertEquals(0, wallet.wallet(31L).coinBalance());
    }
}
