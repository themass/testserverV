package com.timeline.game.domain;

import org.junit.jupiter.api.Test;

import static com.timeline.game.domain.Rank.*;
import static org.junit.jupiter.api.Assertions.*;

/** 段位纯函数单测（镜像 TS packages/shared/test/rank.test.ts 的全部预期）。 */
class RankTest {

    static RankState r(int tier, int stars, int lossStreak) { return new RankState(tier, stars, INITIAL_MMR, lossStreak); }
    static RankState r(int tier, int stars) { return r(tier, stars, 0); }

    @Test
    void 段位表() {
        assertArrayEquals(new int[]{3, 3, 5, 5, 5, 5, 5},
            new int[]{starCap(0), starCap(1), starCap(2), starCap(3), starCap(4), starCap(5), starCap(6)});
        assertEquals(Integer.MAX_VALUE, starCap(TIER_MARSHAL));
        assertEquals("列兵", tierLabel(0));
        assertEquals("元帅", tierLabel(TIER_MARSHAL));
    }

    @Test
    void 胜加一星星满晋级新段零星() {
        RankApply a = applyOutcome(r(0, 0), Outcome.WIN, 1200);
        assertEquals(0, a.state().tier()); assertEquals(1, a.state().stars()); assertEquals(0, a.state().lossStreak());
        RankApply b = applyOutcome(r(0, 2), Outcome.WIN, 1200);
        assertEquals(1, b.state().tier()); assertEquals(0, b.state().stars());
        RankApply c = applyOutcome(r(5, 4), Outcome.WIN, 1200);
        assertEquals(6, c.state().tier()); assertEquals(0, c.state().stars());
    }

    @Test
    void 元帅胜只加星不晋级() {
        RankApply a = applyOutcome(r(TIER_MARSHAL, 9), Outcome.WIN, 1200);
        assertEquals(TIER_MARSHAL, a.state().tier());
        assertEquals(10, a.state().stars());
    }

    @Test
    void 负减一星零星降到上一级满星() {
        RankApply a = applyOutcome(r(3, 2), Outcome.LOSS, 1200);
        assertEquals(3, a.state().tier()); assertEquals(1, a.state().stars()); assertEquals(1, a.state().lossStreak());
        RankApply b = applyOutcome(r(3, 0), Outcome.LOSS, 1200);
        assertEquals(2, b.state().tier()); assertEquals(starCap(2) - 1, b.state().stars());
    }

    @Test
    void 列兵零星不跌垫底保护() {
        RankApply a = applyOutcome(r(0, 0), Outcome.LOSS, 1200);
        assertEquals(0, a.state().tier()); assertEquals(0, a.state().stars());
    }

    @Test
    void 星满状态输棋星减一段位不动() {
        RankApply a = applyOutcome(r(2, 4), Outcome.LOSS, 1200);
        assertEquals(2, a.state().tier()); assertEquals(3, a.state().stars());
    }

    @Test
    void 保星局连败第三场不扣星计数器清零() {
        RankState s = r(2, 1);
        s = applyOutcome(s, Outcome.LOSS, 1200).state(); // 1→0, streak 1
        assertEquals(0, s.stars()); assertEquals(1, s.lossStreak());
        s = applyOutcome(s, Outcome.LOSS, 1200).state(); // 0 星跌段
        assertEquals(1, s.tier());
        assertEquals(2, s.lossStreak());
        RankState before = s;
        RankState after = applyOutcome(s, Outcome.LOSS, 1200).state(); // 第 3 败：保星
        assertEquals(before.tier(), after.tier());
        assertEquals(before.stars(), after.stars());
        assertEquals(0, after.lossStreak());
    }

    @Test
    void 胜场清零连败计数() {
        assertEquals(0, applyOutcome(r(2, 2, 2), Outcome.WIN, 1200).state().lossStreak());
    }

    @Test
    void delta与实际星序变化一致() {
        for (RankState s : new RankState[]{r(0, 0), r(0, 2), r(3, 0), r(TIER_MARSHAL, 5)}) {
            assertEquals(1, applyOutcome(s, Outcome.WIN, 1200).delta());
            int dl = applyOutcome(s, Outcome.LOSS, 1200).delta();
            assertTrue(dl == -1 || dl == 0);
        }
    }

    @Test
    void elo同分期望半高打低赢分少输分多() {
        assertEquals(0.5, eloExpected(1200, 1200), 1e-9);
        assertTrue(eloDelta(1400, 1200, 1) < 16);
        assertTrue(eloDelta(1400, 1200, 0) < -16);
        assertTrue(eloDelta(1200, 1400, 1) > 16);
    }

    @Test
    void applyOutcome同步更新mmr() {
        RankApply a = applyOutcome(initialRank(), Outcome.WIN, 1400);
        assertTrue(a.state().mmr() > INITIAL_MMR);
        assertEquals(eloDelta(INITIAL_MMR, 1400, 1), a.state().mmr() - INITIAL_MMR);
    }

    @Test
    void 晋级局elo之外同向微调加四十() {
        RankApply a = applyOutcome(new RankState(0, 2, INITIAL_MMR, 0), Outcome.WIN, INITIAL_MMR);
        assertEquals(1, a.state().tier());
        assertEquals(0, a.state().stars());
        assertEquals(INITIAL_MMR + eloDelta(INITIAL_MMR, INITIAL_MMR, 1) + 40, a.state().mmr());
        // 非晋级胜不加 40
        RankApply p = applyOutcome(new RankState(0, 0, INITIAL_MMR, 0), Outcome.WIN, INITIAL_MMR);
        assertEquals(INITIAL_MMR + eloDelta(INITIAL_MMR, INITIAL_MMR, 1), p.state().mmr());
    }

    @Test
    void 赛季epoch当刻第1季满四周进第2季() {
        assertEquals(1, seasonNumber(SEASON_EPOCH_MS));
        assertEquals(1, seasonNumber(SEASON_EPOCH_MS + SEASON_MS - 1));
        assertEquals(2, seasonNumber(SEASON_EPOCH_MS + SEASON_MS));
    }

    @Test
    void 赛季重置降一级满星元帅降到准将满星() {
        RankState a = resetSeason(new RankState(3, 2, 1337, 2));
        assertEquals(new RankState(2, starCap(2) - 1, 1337, 0), a);
        RankState b = resetSeason(new RankState(TIER_MARSHAL, 42, 2000, 1));
        assertEquals(new RankState(TIER_MARSHAL - 1, starCap(TIER_MARSHAL - 1) - 1, 2000, 0), b);
        assertEquals(initialRank(), resetSeason(initialRank()));
    }

    @Test
    void 分桶同桶不限时跨桶按桶距逐级放宽() {
        assertEquals(mmrBucket(1200), mmrBucket(1240));
        assertNotEquals(mmrBucket(1200), mmrBucket(1500));
        assertTrue(matchRelaxGate(1200, 1250, 14_000)); // 同桶不限时
        // 1200→桶10，1260→桶11（10.5 向上取整，与 JS Math.round 一致）：隔一桶等 15s 放行
        assertNotEquals(mmrBucket(1200), mmrBucket(1260));
        assertFalse(matchRelaxGate(1200, 1260, 14_999));
        assertTrue(matchRelaxGate(1200, 1260, 15_000));
        // 1380→桶12：隔两桶等 30s
        assertFalse(matchRelaxGate(1200, 1380, 29_999));
        assertTrue(matchRelaxGate(1200, 1380, 30_000));
    }
}
