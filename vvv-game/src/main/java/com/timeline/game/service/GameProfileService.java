package com.timeline.game.service;

import com.timeline.game.domain.Coins;
import com.timeline.game.domain.Nickname;
import com.timeline.game.domain.Rank;
import com.timeline.game.persistence.GameCoinLedgerMapper;
import com.timeline.game.persistence.GameMatchMapper;
import com.timeline.game.persistence.GameProfileMapper;
import com.timeline.game.persistence.GameProgressMapper;
import com.timeline.game.persistence.GameWalletMapper;
import com.timeline.game.protocol.GameErrorCode;

import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * HTTP 读接口 + 离线写的业务装配（api.md 的 profile/nickname/ledger/ad-reward/rank/matches）。
 *
 * 只读装配 + 幂等写：不做对局相关任何事（那些只走 WS，见 api.md 尾注）。
 * 首见用户在 profile.get 建档（upsert + 默认昵称派生自平台 name）。
 */
public final class GameProfileService {

    private final GameProfileMapper profiles;
    private final GameProgressMapper progress;
    private final GameWalletMapper wallet;
    private final GameCoinLedgerMapper ledger;
    private final GameMatchMapper matches;
    private final GameSeasonService seasons;   // 可空：没装赛季服务就退化为"不懒翻页"（测试常用）
    private final ZoneId zone;

    public GameProfileService(GameProfileMapper profiles, GameProgressMapper progress,
                              GameWalletMapper wallet, GameCoinLedgerMapper ledger,
                              GameMatchMapper matches, GameSeasonService seasons, ZoneId zone) {
        this.profiles = profiles;
        this.progress = progress;
        this.wallet = wallet;
        this.ledger = ledger;
        this.matches = matches;
        this.seasons = seasons;
        this.zone = zone;
    }

    // ---------------------------------------------------------------- 档案

    /** 三行单键读 + 首见建档。昵称缺省时派生平台 name，再兜底"玩家{尾号}"。 */
    public ProfileView profile(long userId, String platformName, long nowMs) {
        var row = profiles.profile(userId);
        if (row == null) {
            String nick = Nickname.sanitizeNickname(platformName, "玩家" + (userId % 10000));
            if (!Nickname.isNicknameAllowed(nick)) nick = "玩家" + (userId % 10000);
            profiles.upsertProfile(userId, nick);
            progress.insertInitial(userId, Rank.seasonNumber(nowMs));
            wallet.insertInitial(userId, Coins.dayKey(nowMs, zone));
            row = profiles.profile(userId);
        } else {
            profiles.touchSeen(userId);   // 尽力而为；失败不影响读
        }
        var p = progress.progress(userId);
        // 跨季懒翻页（TS profile.ts get() 的懒路径，评审 #4）：先被读接口摸到的在线玩家
        // 不能等 tick 批量——奖励 (tier+1)×50 现在就发，与 sweep 共用 entry_key 幂等键，两路只发一次。
        if (seasons != null && p != null && p.seasonNo() != GameSeasonService.seasonOf(nowMs)) {
            seasons.crossUser(userId, GameSeasonService.seasonOf(nowMs), nowMs);
            p = progress.progress(userId);
        }
        var w = wallet.wallet(userId);
        return new ProfileView(row.userId(), row.nickname(),
            p == null ? null : new RankView(p.tier(), p.stars(), p.lossStreak(), p.wins(), p.losses(),
                p.totalHits(), p.bestTier(), p.bestStars(), p.streak(), p.scoringGames()),
            w == null ? null : new WalletView(w.coinBalance()),
            Rank.seasonNumber(nowMs));
    }

    public record ProfileView(long userId, String nickname, RankView rank, WalletView coins, int season) {}
    public record RankView(int tier, int stars, int lossStreak, int wins, int losses,
                           int totalHits, int bestTier, int bestStars, int streak, int scoringGames) {}
    public record WalletView(int balance) {}

    /** 改昵称：清洗 → 屏蔽词 → 落库。非法回 BAD_SHAPE / BAD_MOVE（被词表挡）。 */
    public GameErrorCode setNickname(long userId, Object rawNickname) {
        String cleaned = Nickname.sanitizeNickname(rawNickname, null);
        if (cleaned == null) return GameErrorCode.BAD_SHAPE;
        if (Nickname.isNicknameBlocked(cleaned)) return GameErrorCode.BAD_MOVE;
        profiles.renameProfile(userId, cleaned);
        return null;
    }

    // ---------------------------------------------------------------- 金币

    public record LedgerView(int balance, List<LedgerEntry> entries) {}
    public record LedgerEntry(String entryKey, String reason, int delta, long atMs) {}

    public LedgerView coinsLedger(long userId) {
        var w = wallet.wallet(userId);
        List<LedgerEntry> entries = new ArrayList<>();
        for (var e : ledger.ledger(userId, Coins.LEDGER_MAX)) {
            entries.add(new LedgerEntry(e.entryKey(), e.reason(), e.delta(), e.atMs()));
        }
        return new LedgerView(w == null ? 0 : w.coinBalance(), List.copyOf(entries));
    }

    /**
     * 看广告领奖（离线写；WS 侧 coin.adReward 走同一方法保证行为一致）。
     * 幂等键 ad:&lt;day_key&gt;:&lt;序号&gt;：序号 = 当日 ad_grants + 1，与 CAS 更新配对——
     * 并发双请求只有一个能把 ad_grants 从 n 推到 n+1，另一个 CAS 失败重算后撞上限或新序号，
     * ledger 唯一键再兜一层。日上限 Coins.AD_DAILY_MAX。
     */
    public AdRewardResult adReward(long userId, long nowMs) {
        var w = wallet.wallet(userId);
        if (w == null) {
            wallet.insertInitial(userId, Coins.dayKey(nowMs, zone));
            w = wallet.wallet(userId);
            if (w == null) return new AdRewardResult(GameErrorCode.INTERNAL, 0, 0);
        }
        var daily = new Coins.DailyState(w.dayKey(), w.loginDone() != 0, w.gameGrants(),
            w.ticketPlays(), w.adGrants(), w.netGain());
        Coins.DailyState rolled = Coins.rollDaily(daily, nowMs, zone);
        if (rolled.adGrants() >= Coins.AD_DAILY_MAX) {
            return new AdRewardResult(GameErrorCode.QUOTA_EXCEEDED, 0, w.coinBalance());
        }
        String day = rolled.day();
        int seq = rolled.adGrants() + 1;
        String entryKey = "ad:" + day + ":" + seq;

        // 净增上限走 Coins.applyCoin 的同款逻辑：广告非豁免项，余额+30 前先查封顶。
        int delta = Coins.AD_GRANT;
        boolean capped = false;
        int room = Coins.NET_GAIN_MAX - rolled.netGain();
        if (room <= 0) return new AdRewardResult(GameErrorCode.QUOTA_EXCEEDED, 0, w.coinBalance());
        if (delta > room) { delta = room; capped = true; }

        if (ledger.insertIgnore(userId, entryKey, "ad", delta, null, nowMs, capped ? 1 : 0) == 0) {
            // 唯一键挡住 = 这一笔已经发过（重试/并发），按幂等成功回
            var again = wallet.wallet(userId);
            return new AdRewardResult(null, 0, again == null ? 0 : again.coinBalance());
        }
        wallet.addBalance(userId, delta);
        wallet.casUpdateDay(userId, day, w.loginDone(), w.gameGrants(), w.ticketPlays(),
            rolled.adGrants() + 1, rolled.netGain() + delta, w.dayKey());
        var after = wallet.wallet(userId);
        return new AdRewardResult(null, delta, after == null ? 0 : after.coinBalance());
    }

    public record AdRewardResult(GameErrorCode error, int granted, int balance) {}

    // ---------------------------------------------------------------- 排行 / 战绩

    public record RankRowEntry(int pos, String nickname, int tier, int stars, int wins) {}

    /** 段位榜（api.md：前 100；tier↓ stars↓ wins↓，并列 user_id 定序）。 */
    public List<RankRowEntry> rankList(int limit, long nowMs) {
        var season = Rank.seasonNumber(nowMs);
        List<RankRowEntry> out = new ArrayList<>();
        int pos = 1;
        for (var b : progress.board(season, Math.min(limit, 100))) {
            var prof = profiles.profile(b.userId());      // 单键主键查；上量后可换 IN 批量
            out.add(new RankRowEntry(pos++, prof == null ? "玩家" + (b.userId() % 10000) : prof.nickname(),
                b.tier(), b.stars(), b.wins()));
        }
        return List.copyOf(out);
    }

    public record MatchBrief(String matchId, String mode, String preset, long startedAtMs, long endedAtMs,
                             int finalRank, int hits, int deltaStar, int win, int scoring) {}

    public List<MatchBrief> recentMatches(long userId, int limit) {
        List<MatchBrief> out = new ArrayList<>();
        for (var m : matches.recentByUser(userId, Math.min(limit, 50))) {
            out.add(new MatchBrief(m.matchId(), m.mode(), m.preset(), m.startedAtMs(), m.endedAtMs(),
                m.finalRank(), m.hits(), m.deltaStar(), m.win(), m.scoring()));
        }
        return List.copyOf(out);
    }

    // ---------------------------------------------------------------- 装配小工具

    /** HTTP 头鉴权后的公共入口：解析失败时控制器直接回 401，这里不再重复判空。 */
    public Optional<GameErrorCode> guard(long userId) { return userId <= 0 ? Optional.of(GameErrorCode.NOT_AUTHED) : Optional.empty(); }
}
