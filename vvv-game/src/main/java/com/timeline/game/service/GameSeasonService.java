package com.timeline.game.service;

import com.timeline.game.domain.Coins;
import com.timeline.game.domain.Rank;
import com.timeline.game.persistence.GameProgressMapper;
import com.timeline.game.persistence.GameSeasonMapper;

import java.time.ZoneId;
import java.util.List;

/**
 * 跨季翻页（TS profile.ts crossSeason/resetSeasonAll 的持久层版，spec §4 tick 序第 1 步）。
 *
 * 与 TS 的两处刻意差异（其余逐字段对齐 rank.ts resetSeason 100-104 行）：
 * 1. TS 全内存逐档案，这里批量 SQL 扫描（staleUserIds）+ 逐行降级（seasonCross）：
 *    发奖额取决于各自旧段位，批量 UPDATE 给不了，所以"扫描批量、发奖逐行"。
 * 2. 无全局事务：单行顺序固定为 先发币 → 后翻页降级。崩溃在两步之间时，
 *    重放被 entry_key {@code season-grant:<赛季>} 挡住（applied=0 幂等成功）、降级照做——
 *    玩家不会丢奖励，也不会双发。跨进程重复跑（多实例）同样被这对幂等键兜住。
 *
 * 段位奖励 seasonGrant=(tier+1)×50 在 Coins 里豁免净增上限（还的是荣誉结算，不是产出）。
 * game_season 行是审计锚点：audit 的 stale_progress_rows 检查用 status='ACTIVE' 的
 * MAX(season_no) 当"当前赛季"，所以翻页第一步先 ensureRow 新季、关上一季。
 */
public final class GameSeasonService {

    private final GameProgressMapper progress;
    private final GameSeasonMapper seasons;
    private final GameWalletService wallet;
    private final ZoneId zone;

    public GameSeasonService(GameProgressMapper progress, GameSeasonMapper seasons,
                             GameWalletService wallet, ZoneId zone) {
        this.progress = progress;
        this.seasons = seasons;
        this.wallet = wallet;
        this.zone = zone;
    }

    /** 本批翻页的人数；0 = 全服已是最新赛季（tick 里每轮都调，常态就是一次空扫描）。 */
    public int sweep(long nowMs, int batchSize) {
        int season = Rank.seasonNumber(nowMs);
        List<Long> stale = progress.staleUserIds(season, batchSize);
        if (stale.isEmpty()) return 0;
        for (long userId : stale) crossUser(userId, season, nowMs);
        // 补跑收敛后打全局标记（跑一半崩溃不打，审计里"这季没结完"看得见）。
        if (progress.staleUserIds(season, 1).isEmpty()) {
            seasons.markGranted(season);
            seasons.markReset(season);
        }
        return stale.size();
    }

    /**
     * 单用户跨季（TS crossSeason 的等价物；GameProfileService 懒路径与 sweep 共用，
     * 两条路只靠 entry_key 保证只发一次——评审 #4 的"先被 get 摸到的人奖励蒸发"就是这么堵的）。
     * 顺序锁死：先立审计锚（ensureRow 新季 + 关掉该用户所在旧季；INSERT IGNORE，逐行调无害，
     * 懒路径单用户也走它，audit 的 status='ACTIVE' MAX(season_no) 锚点两条路才一致）
     * → 按旧段位算奖 → 发币 → 降级翻页。返回实发额（0=幂等吞掉/让渡）。
     */
    public int crossUser(long userId, int newSeason, long nowMs) {
        var p = progress.progress(userId);
        if (p == null || p.seasonNo() == newSeason) return 0;
        seasons.ensureRow(newSeason, Rank.SEASON_EPOCH_MS + (long) (newSeason - 1) * Rank.SEASON_MS,
            Rank.SEASON_EPOCH_MS + (long) newSeason * Rank.SEASON_MS);
        if (p.seasonNo() >= 1) seasons.closeSeason(p.seasonNo());
        int grant = Coins.seasonGrant(p.tier());
        Rank.RankState after = Rank.resetSeason(
            new Rank.RankState(p.tier(), p.stars(), p.mmr(), p.lossStreak()));
        wallet.grant(userId, new Coins.CoinOp(Coins.CoinReason.SEASON_GRANT,
            "season-grant:" + newSeason, String.valueOf(newSeason), nowMs, grant), zone);
        progress.seasonCross(userId, newSeason, after.tier(), after.stars());
        return grant;
    }

    /** 赛季号（懒路径判断用；语义与 Rank.seasonNumber 同）。 */
    public static int seasonOf(long nowMs) {
        return Rank.seasonNumber(nowMs);
    }
}
