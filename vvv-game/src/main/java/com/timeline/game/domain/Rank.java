package com.timeline.game.domain;

/**
 * 段位系统（TS packages/shared/src/rank.ts 直译）：星制 + 隐藏 MMR 双轨，纯函数。
 *
 * 服务端只存 RankState 并接线；升降星、Elo、赛季重置全部在这里，可单测。
 * MMR 从不下发给客户端（星数是显示壳，匹配按 MMR）。
 */
public final class Rank {

    private Rank() {}

    public static final String[] TIERS = {"列兵", "新兵", "少尉", "上尉", "少校", "上校", "准将", "元帅"};
    public static final int TIER_MARSHAL = 7; // 元帅无星数上限，按星数排名
    private static final int[] STAR_CAPS = {3, 3, 5, 5, 5, 5, 5, 5}; // 下标 = tier；元帅的值不用

    /** 该段位的星数上限（stars ∈ [0, cap)；元帅用 MAX_VALUE 表示无限）。 */
    public static int starCap(int tier) {
        return tier >= TIER_MARSHAL ? Integer.MAX_VALUE : STAR_CAPS[Math.max(0, Math.min(TIER_MARSHAL, tier))];
    }

    public static String tierLabel(int tier) {
        return TIERS[Math.max(0, Math.min(TIER_MARSHAL, tier))];
    }

    public record RankState(int tier, int stars, int mmr, int lossStreak) {}

    public static final int INITIAL_MMR = 1200;

    public static RankState initialRank() {
        return new RankState(0, 0, INITIAL_MMR, 0);
    }

    // ---------------------------------------------------------------- Elo

    public static final int ELO_K = 32;

    /** 期望胜率（标准 Elo 公式）。 */
    public static double eloExpected(int mmr, int opponentMmr) {
        return 1 / (1 + Math.pow(10, (opponentMmr - mmr) / 400.0));
    }

    /** K=32 的 Elo 增量，四舍五入（JS Math.round 同：half-up toward +∞）。 */
    public static int eloDelta(int mmr, int opponentMmr, int score) {
        // JS Math.round 是 half-up toward +∞；Java Math.round 同为 floor(x+0.5)，语义一致
        return (int) Math.round(ELO_K * (score - eloExpected(mmr, opponentMmr)));
    }

    // ---------------------------------------------------------------- 升降星

    public enum Outcome { WIN, LOSS }

    public record RankApply(RankState state, int delta) {}

    /**
     * 一局计分局的星数结算：
     * - 胜：+1 星；星满晋级、新段 0 星；元帅无上限
     * - 负：−1 星；0 星降一级并落到满星；列兵 0 星不跌（垫底保护）
     * - 晋级局失败不降级：降段只会发生在 0 星时，星数下跌本身永不跨段
     * - 保星局：连败满 3 场的那一败不扣星，计数器随后清零（每 3 连败保一次）
     *
     * MMR 同步按对手 MMR 走 Elo（对手 MMR 由服务端传入）。
     */
    public static RankApply applyOutcome(RankState prev, Outcome outcome, int opponentMmr) {
        if (outcome == Outcome.WIN) {
            int tier = prev.tier();
            int stars = prev.stars();
            int mmr = prev.mmr() + eloDelta(prev.mmr(), opponentMmr, 1);
            int delta = 1;
            if (prev.tier() >= TIER_MARSHAL) {
                stars = prev.stars() + 1;
            } else if (prev.stars() + 1 >= starCap(prev.tier())) {
                tier = prev.tier() + 1;
                stars = 0;
                // 升段同向微调（spec §21.2）：段位是 MMR 的显示壳，晋级说明被低估，MMR 补 40
                mmr += 40;
            } else {
                stars = prev.stars() + 1;
            }
            return new RankApply(new RankState(tier, stars, mmr, 0), delta);
        }

        int mmr = prev.mmr() + eloDelta(prev.mmr(), opponentMmr, 0);
        int lossStreak = prev.lossStreak() + 1;
        // 保星局：连败到第 3 场不扣星，计数器清零（之后每 3 连败再保一次）
        if (lossStreak >= 3) return new RankApply(new RankState(prev.tier(), prev.stars(), mmr, 0), 0);

        if (prev.stars() > 0) return new RankApply(new RankState(prev.tier(), prev.stars() - 1, mmr, lossStreak), -1);
        if (prev.tier() == 0) return new RankApply(new RankState(0, 0, mmr, lossStreak), 0);
        return new RankApply(new RankState(prev.tier() - 1, starCap(prev.tier() - 1) - 1, mmr, lossStreak), -1);
    }

    // ---------------------------------------------------------------- 赛季

    /** 第 1 赛季起点（UTC，避开本地时区歧义）：2026-11-23T00:00:00Z。 */
    public static final long SEASON_EPOCH_MS = 1_795_392_000_000L; // Date.UTC(2026, 10, 23)
    public static final long SEASON_MS = 4L * 7 * 24 * 3600 * 1000; // 4 周

    public static int seasonNumber(long nowMs) {
        return (int) Math.max(1, 1 + Math.floor((nowMs - SEASON_EPOCH_MS) / (double) SEASON_MS));
    }

    /**
     * 新赛季：降 1 级、满星起步（元帅降到准将满星）。
     * 已在最低段（列兵）：段位星数都保持原样——0 段没有"降 1 级"，也白送满星。
     * MMR 保留（匹配质量连续），连败清零。
     */
    public static RankState resetSeason(RankState prev) {
        if (prev.tier() == 0) return new RankState(prev.tier(), prev.stars(), prev.mmr(), 0);
        int tier = prev.tier() - 1;
        return new RankState(tier, starCap(tier) - 1, prev.mmr(), 0);
    }

    // ---------------------------------------------------------------- 匹配分桶

    /** MMR 分桶（spec §21.2 ±120）：同桶优先相遇。 */
    public static final int MMR_BUCKET = 120;
    /** 等待超过这个时长后放开相邻桶。 */
    public static final long MATCH_RELAX_MS = 15_000;

    public static int mmrBucket(int mmr) {
        // JS Math.round 对 .5 half-up toward +∞；Math.round(int/120.0) 的 double 语义一致
        return (int) Math.floor(mmr / (double) MMR_BUCKET + 0.5);
    }

    /**
     * 匹配放行判定：同桶立即放行；跨桶按桶距逐级放宽——每多隔一桶多等一份
     * MATCH_RELAX_MS（相邻 15s、隔两桶 30s、隔三桶 45s…）。封顶按等待时长线性升级，
     * 保证满员且不兼容的队列也能配上，不会有人饿死在队里。
     */
    public static boolean matchRelaxGate(int mmrA, int mmrB, long waitedMs) {
        int gap = Math.abs(mmrBucket(mmrA) - mmrBucket(mmrB));
        if (gap == 0) return true;
        return waitedMs >= MATCH_RELAX_MS * gap;
    }
}
