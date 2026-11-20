package com.timeline.game.protocol;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.timeline.game.domain.GameTypes;
import com.timeline.game.domain.Rules;
import com.timeline.game.engine.EngineEvent;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** 引擎事件 → wire 编码单测：与 docs/game/protocol.md 的事件清单逐字段对拍。 */
class EngineEventCodecTest {

    private final ObjectMapper mapper = new ObjectMapper();

    private JsonNode dataOf(EngineEvent ev) {
        EngineEventCodec.Encoded enc = EngineEventCodec.encode(mapper, ev);
        return parse(enc.data().toString());
    }

    private String evtOf(EngineEvent ev) {
        return EngineEventCodec.encode(mapper, ev).evt().wire;
    }

    // ---------------------------------------------------------------- 基础事件

    @Test
    void encodesError() {
        assertEquals("error", evtOf(new EngineEvent.Error(GameErrorCode.NOT_YOUR_TURN, "还没轮到你")));
        JsonNode data = dataOf(new EngineEvent.Error(GameErrorCode.NOT_YOUR_TURN, "还没轮到你"));
        assertEquals("NOT_YOUR_TURN", data.get("code").asText());
        assertEquals("还没轮到你", data.get("message").asText());
    }

    @Test
    void encodesPlaneAcceptedWithCells() {
        var ev = new EngineEvent.PlaneAccepted(List.of(new Rules.Cell(2, 3), new Rules.Cell(5, 6)));
        assertEquals("game.planeAccepted", evtOf(ev));
        JsonNode data = dataOf(ev);
        assertEquals(2, data.get("planes").size());
        assertEquals(2, data.get("planes").get(0).get("row").asInt());
        assertEquals(3, data.get("planes").get(0).get("col").asInt());
        assertEquals(5, data.get("planes").get(1).get("row").asInt());
    }

    @Test
    void encodesPhaseChangedWithAllFields() {
        var ev = new EngineEvent.PhaseChanged(GameTypes.GamePhase.PLAYING, 1234567890L, "p1", null);
        assertEquals("phase.changed", evtOf(ev));
        JsonNode data = dataOf(ev);
        assertEquals("playing", data.get("phase").asText());   // 小写
        assertEquals(1234567890L, data.get("deadlineAt").asLong());
        assertEquals("p1", data.get("turn").asText());
        assertTrue(data.get("round").isNull());                 // melee 侧显式 null
    }

    @Test
    void encodesPhaseChangedWithNullTurnAndNullRound() {
        // 摆放相位：turn/round 都没有，必须显式写出 null 而不是缺字段
        var ev = new EngineEvent.PhaseChanged(GameTypes.GamePhase.PLACING, null, null, null);
        JsonNode data = dataOf(ev);
        assertEquals("placing", data.get("phase").asText());
        assertTrue(data.has("deadlineAt"));
        assertTrue(data.get("deadlineAt").isNull());
        assertTrue(data.get("turn").isNull());
        assertTrue(data.get("round").isNull());
    }

    @Test
    void encodesGameShotWithLowercaseResult() {
        var ev = new EngineEvent.GameShot("p1", 3, 4, Rules.ShotResult.HEAD, "plane-2", "p2");
        assertEquals("game.shot", evtOf(ev));
        JsonNode data = dataOf(ev);
        assertEquals("p1", data.get("by").asText());
        assertEquals(3, data.get("row").asInt());
        assertEquals(4, data.get("col").asInt());
        assertEquals("head", data.get("result").asText());      // 小写
        assertEquals("plane-2", data.get("planeId").asText());
        assertEquals("p2", data.get("nextTurn").asText());
    }

    @Test
    void encodesGameShotWithNullPlaneIdOnMiss() {
        var ev = new EngineEvent.GameShot("p1", 0, 0, Rules.ShotResult.MISS, null, "p1");
        JsonNode data = dataOf(ev);
        assertEquals("miss", data.get("result").asText());
        assertTrue(data.get("planeId").isNull());
    }

    @Test
    void encodesPlaneDestroyed() {
        var ev = new EngineEvent.PlaneDestroyed("p2", "plane-1");
        assertEquals("game.destroyed", evtOf(ev));
        JsonNode data = dataOf(ev);
        assertEquals("p2", data.get("ownerId").asText());
        assertEquals("plane-1", data.get("planeId").asText());
    }

    @Test
    void encodesPresence() {
        var ev = new EngineEvent.Presence("p1", false);
        assertEquals("player.presence", evtOf(ev));
        JsonNode data = dataOf(ev);
        assertEquals("p1", data.get("playerId").asText());
        assertTrue(data.get("connected").isBoolean());
        assertEquals(false, data.get("connected").asBoolean());
    }

    // ---------------------------------------------------------------- 终局

    @Test
    void encodesGameOverWithNullEliminatedRoundInRanking() {
        // melee 终局：冠军没有出局轮次 → eliminatedRound 显式 null
        var result = new GameTypes.GameResult(GameTypes.GameOverReason.LAST_STANDING, List.of(
            new GameTypes.RankEntry("p1", 1, null, 7),
            new GameTypes.RankEntry("p2", 2, 5, 4)));
        assertEquals("game.over", evtOf(new EngineEvent.GameOver(result)));
        JsonNode data = dataOf(new EngineEvent.GameOver(result));
        assertEquals("last_standing", data.get("reason").asText());   // 小写
        JsonNode ranking = data.get("ranking");
        assertEquals(2, ranking.size());
        assertEquals("p1", ranking.get(0).get("playerId").asText());
        assertEquals(1, ranking.get(0).get("rank").asInt());
        assertTrue(ranking.get(0).has("eliminatedRound"));
        assertTrue(ranking.get(0).get("eliminatedRound").isNull());
        assertEquals(7, ranking.get(0).get("hits").asInt());
        assertEquals(5, ranking.get(1).get("eliminatedRound").asInt());
    }

    // ---------------------------------------------------------------- melee

    @Test
    void encodesSubmitted() {
        var ev = new EngineEvent.Submitted("p3", 4);
        assertEquals("game.submitted", evtOf(ev));
        JsonNode data = dataOf(ev);
        assertEquals("p3", data.get("playerId").asText());
        assertEquals(4, data.get("round").asInt());
    }

    @Test
    void encodesRoundResultWithAllLists() {
        var ev = new EngineEvent.RoundResult(3,
            List.of(new GameTypes.TargetShot("p2", 1, 2, Rules.ShotResult.BODY, "plane-1")),
            List.of(new GameTypes.IncomingShot("p2", 4, 5, Rules.ShotResult.MISS, null)),
            List.of(new EngineEvent.DestroyedCount("p2", 1)),
            List.of("p4"));
        assertEquals("game.roundResult", evtOf(ev));
        JsonNode data = dataOf(ev);
        assertEquals(3, data.get("round").asInt());
        assertEquals("p2", data.get("shots").get(0).get("targetId").asText());
        assertEquals("body", data.get("shots").get(0).get("result").asText());
        assertEquals("plane-1", data.get("shots").get(0).get("planeId").asText());
        assertEquals("p2", data.get("incoming").get(0).get("by").asText());
        assertTrue(data.get("incoming").get(0).get("planeId").isNull());
        assertEquals("miss", data.get("incoming").get(0).get("result").asText());
        assertEquals("p2", data.get("destroyed").get(0).get("playerId").asText());
        assertEquals(1, data.get("destroyed").get(0).get("planesDestroyed").asInt());
        assertEquals("p4", data.get("eliminated").get(0).asText());
    }

    @Test
    void encodesRoundResultWithEmptyLists() {
        // 本轮零交火：四个数组都必须存在且为空，客户端无脑读
        var ev = new EngineEvent.RoundResult(2, List.of(), List.of(), List.of(), List.of());
        JsonNode data = dataOf(ev);
        assertEquals(2, data.get("round").asInt());
        assertTrue(data.get("shots").isArray());
        assertEquals(0, data.get("shots").size());
        assertEquals(0, data.get("incoming").size());
        assertEquals(0, data.get("destroyed").size());
        assertEquals(0, data.get("eliminated").size());
    }

    @Test
    void encodesPlayerOut() {
        var ev = new EngineEvent.PlayerOut("p4", 6);
        assertEquals("game.playerOut", evtOf(ev));
        JsonNode data = dataOf(ev);
        assertEquals("p4", data.get("playerId").asText());
        assertEquals(6, data.get("round").asInt());
    }

    // ---------------------------------------------------------------- 辅助

    private JsonNode parse(String json) {
        try {
            return mapper.readTree(json);
        } catch (Exception e) {
            throw new AssertionError("编码结果不是合法 JSON: " + json, e);
        }
    }
}
