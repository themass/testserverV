package com.timeline.game.engine;

import com.timeline.game.domain.Rules;
import com.timeline.game.domain.Ruleset;
import com.timeline.game.protocol.GameErrorCode;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.function.DoubleSupplier;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.*;

/** 摆放阶段与引擎工厂单测（镜像 TS apps/server/test/engine-placing.test.ts 全部预期）。 */
class EnginePlacingTest {

    /** TS: const rules = { boardSize: 12, planeCount: 2, turnSeconds: 20, hintAllowed: false } */
    private static final Ruleset.RuleSet RULES = new Ruleset.RuleSet(12, 2, 20, false);
    /** TS: () => 0 */
    private static final DoubleSupplier ZERO = () -> 0;

    private static Rules.Cell cell(int row, int col) { return new Rules.Cell(row, col); }

    /** TS packages/shared/test/helpers.ts 的 mulberry32：直接复用测试公共实现（domain.Mulberry32）。 */
    private static DoubleSupplier mulberry32(int seed) {
        return com.timeline.game.domain.Mulberry32.of(seed);
    }

    @Test
    void deadline等于当前时刻加placeSeconds毫秒() {
        // TS it('deadline = now + placeSeconds')
        assertEquals(1000 + 60_000, new Engine.PlacingPhase(RULES, List.of("a", "b", "c"), 1000, ZERO).deadlineAt());
    }

    @Test
    void 合法摆放只回给本人() {
        // TS it('合法摆放只回给本人')
        Engine.PlacingPhase p = new Engine.PlacingPhase(RULES, List.of("a", "b", "c"), 0, ZERO);
        List<Outbound> out = p.place("a", List.of(cell(2, 2), cell(6, 6)));
        assertEquals(List.of(new Outbound("a",
            new EngineEvent.PlaneAccepted(List.of(cell(2, 2), cell(6, 6))))), out);
    }

    @Test
    void 飞机数不对或重叠报INVALID_PLACEMENT() {
        // TS it('飞机数不对 / 重叠 → INVALID_PLACEMENT')
        Engine.PlacingPhase p = new Engine.PlacingPhase(RULES, List.of("a", "b"), 0, ZERO);
        EngineEvent.Error e1 = assertInstanceOf(EngineEvent.Error.class, p.place("a", List.of(cell(2, 2))).get(0).event());
        assertEquals(GameErrorCode.INVALID_PLACEMENT, e1.code());
        EngineEvent.Error e2 = assertInstanceOf(EngineEvent.Error.class,
            p.place("a", List.of(cell(2, 2), cell(2, 3))).get(0).event());
        assertEquals(GameErrorCode.INVALID_PLACEMENT, e2.code());
    }

    @Test
    void autoPlaceMissing只补未摆放者且结果合法() {
        // TS it('autoPlaceMissing 只补未摆放者，且结果合法')
        Engine.PlacingPhase p = new Engine.PlacingPhase(RULES, List.of("a", "b", "c"), 0, mulberry32(1));
        p.place("a", List.of(cell(2, 2), cell(6, 6)));
        List<Outbound> out = p.autoPlaceMissing();
        assertEquals(List.of("b", "c"),
            out.stream().map(Outbound::to).sorted().collect(Collectors.toList()));
        assertTrue(p.allPlaced());
        for (String id : List.of("b", "c")) {
            assertTrue(Rules.checkPlacement(p.planesOf(id), 12, 2).ok());
        }
    }

    @Test
    void 自动摆放的结果只发给其本人() {
        // TS it('自动摆放的结果只发给其本人')
        Engine.PlacingPhase p = new Engine.PlacingPhase(RULES, List.of("a", "b", "c"), 0, mulberry32(2));
        List<Outbound> out = p.autoPlaceMissing();
        assertEquals(3, out.size());
        for (Outbound o : out) {
            EngineEvent.PlaneAccepted accepted = assertInstanceOf(EngineEvent.PlaneAccepted.class, o.event());
            assertEquals(p.planesOf(o.to()), accepted.planes());
        }
        assertEquals(3, out.stream().map(Outbound::to).distinct().count());
    }

    @Test
    void 非房间成员place返回空且不影响摆放记录() {
        // TS it('非房间成员 place → []，且不影响 allPlaced')（planesOf('x') → null）
        Engine.PlacingPhase p = new Engine.PlacingPhase(RULES, List.of("a", "b"), 0, ZERO);
        assertEquals(List.of(), p.place("x", List.of(cell(2, 2), cell(6, 6))));
        assertNull(p.planesOf("x"));
    }

    @Test
    void 截止前可重摆替换旧摆放() {
        // TS it('截止前可重摆，替换旧摆放')
        Engine.PlacingPhase p = new Engine.PlacingPhase(RULES, List.of("a", "b"), 0, ZERO);
        p.place("a", List.of(cell(2, 2), cell(6, 6)));
        p.place("a", List.of(cell(3, 3), cell(7, 7)));
        assertEquals(List.of(cell(3, 3), cell(7, 7)), p.planesOf("a"));
    }

    @Test
    void 非法重摆不覆盖原有合法摆放() {
        // TS it('非法重摆不覆盖原有合法摆放')
        Engine.PlacingPhase p = new Engine.PlacingPhase(RULES, List.of("a", "b"), 0, ZERO);
        p.place("a", List.of(cell(2, 2), cell(6, 6)));
        p.place("a", List.of(cell(2, 2)));
        assertEquals(List.of(cell(2, 2), cell(6, 6)), p.planesOf("a"));
    }

    @Test
    void allPlaced需要全员摆放且extend顺延deadline() {
        // TS it('allPlaced 需要全员摆放；extend 顺延 deadline')
        Engine.PlacingPhase p = new Engine.PlacingPhase(RULES, List.of("a", "b"), 0, ZERO);
        p.place("a", List.of(cell(2, 2), cell(6, 6)));
        assertFalse(p.allPlaced());
        p.extend(5000);
        assertEquals(65_000, p.deadlineAt());
    }

    @Test
    void createEngine两人得到DuelEngine从placing开始() {
        // TS it('2 人 → DuelEngine（mode duel，从 placing 开始）')
        Engine e = Engine.create(new Engine.EngineOptions(RULES, List.of("a", "b"), 0));
        assertInstanceOf(DuelEngine.class, e);
        assertEquals(com.timeline.game.domain.GameTypes.Mode.DUEL, e.mode());
        assertEquals(com.timeline.game.domain.GameTypes.GamePhase.PLACING, e.phase());
    }

    @Test
    void createEngine三四人得到MeleeEngine从placing开始() {
        // TS it('3–4 人 → MeleeEngine（mode melee，从 placing 开始）')
        for (List<String> ids : List.of(List.of("a", "b", "c"), List.of("a", "b", "c", "d"))) {
            Engine e = Engine.create(new Engine.EngineOptions(RULES, ids, 0));
            assertInstanceOf(MeleeEngine.class, e);
            assertEquals(com.timeline.game.domain.GameTypes.Mode.MELEE, e.mode());
            assertEquals(com.timeline.game.domain.GameTypes.GamePhase.PLACING, e.phase());
        }
    }

    @Test
    void 人数不在2到4区间时工厂抛错() {
        // TS it('人数不在 2–4 → 抛错')，正则 /2.4/ 匹配消息中的 "2-4"
        IllegalArgumentException e1 = assertThrows(IllegalArgumentException.class,
            () -> Engine.create(new Engine.EngineOptions(RULES, List.of("a"), 0)));
        assertTrue(e1.getMessage().matches("(?s).*2.4.*"), e1.getMessage());
        IllegalArgumentException e2 = assertThrows(IllegalArgumentException.class,
            () -> Engine.create(new Engine.EngineOptions(RULES, List.of("a", "b", "c", "d", "e"), 0)));
        assertTrue(e2.getMessage().matches("(?s).*2.4.*"), e2.getMessage());
    }
}
