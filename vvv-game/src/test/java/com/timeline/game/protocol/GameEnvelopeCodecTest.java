package com.timeline.game.protocol;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** 信封编解码单测：与 docs/game/protocol.md 的 wire 格式逐字段对拍。 */
class GameEnvelopeCodecTest {

    private final ObjectMapper mapper = new ObjectMapper();

    // ---------------------------------------------------------------- decode

    @Test
    void decodesWellFormedCommand() {
        var r = GameEnvelopeCodec.decode(mapper,
            "{\"v\":1,\"cmd\":\"room.create\",\"seq\":17,\"data\":{\"capacity\":2}}");
        assertTrue(r.ok());
        assertEquals(GameCmd.ROOM_CREATE, r.inbound().cmd());
        assertEquals(17, r.inbound().seq());
        assertEquals(2, r.inbound().data().get("capacity").asInt());
    }

    @Test
    void missingDataDecodesToNull() {
        // data 允许缺失：形状校验归各命令 handler
        var r = GameEnvelopeCodec.decode(mapper, "{\"v\":1,\"cmd\":\"room.leave\",\"seq\":1}");
        assertTrue(r.ok());
        assertNull(r.inbound().data());
    }

    @Test
    void badJsonFailsWithBadJson() {
        assertEquals(GameErrorCode.BAD_JSON, GameEnvelopeCodec.decode(mapper, "{oops").error());
        assertEquals(GameErrorCode.BAD_JSON, GameEnvelopeCodec.decode(mapper, "").error());
    }

    @Test
    void nonObjectFailsWithBadShape() {
        assertEquals(GameErrorCode.BAD_SHAPE, GameEnvelopeCodec.decode(mapper, "[1,2]").error());
        assertEquals(GameErrorCode.BAD_SHAPE, GameEnvelopeCodec.decode(mapper, "null").error());
    }

    @Test
    void wrongVersionFailsWithBadShape() {
        assertEquals(GameErrorCode.BAD_SHAPE,
            GameEnvelopeCodec.decode(mapper, "{\"v\":2,\"cmd\":\"room.leave\",\"seq\":1}").error());
        assertEquals(GameErrorCode.BAD_SHAPE,
            GameEnvelopeCodec.decode(mapper, "{\"cmd\":\"room.leave\",\"seq\":1}").error());
    }

    @Test
    void unknownCmdFailsWithUnknownCmd() {
        assertEquals(GameErrorCode.UNKNOWN_CMD,
            GameEnvelopeCodec.decode(mapper, "{\"v\":1,\"cmd\":\"room.teleport\",\"seq\":1}").error());
    }

    @Test
    void missingOrNonIntegralSeqFailsWithBadShape() {
        assertEquals(GameErrorCode.BAD_SHAPE,
            GameEnvelopeCodec.decode(mapper, "{\"v\":1,\"cmd\":\"room.leave\"}").error());
        assertEquals(GameErrorCode.BAD_SHAPE,
            GameEnvelopeCodec.decode(mapper, "{\"v\":1,\"cmd\":\"room.leave\",\"seq\":\"x\"}").error());
    }

    // ---------------------------------------------------------------- encode

    @Test
    void encodesPushWithoutRef() {
        String json = GameEnvelopeCodec.encode(mapper, GameEvt.TABLE_STATE, 41, null, null);
        JsonNode node = parse(json);
        assertEquals(1, node.get("v").asInt());
        assertEquals("table.state", node.get("evt").asText());
        assertEquals(41, node.get("seq").asLong());
        assertTrue(node.get("ref").isNull());        // 显式 null，客户端无脑读
        assertTrue(node.get("data").isObject());     // data 缺省为空对象
    }

    @Test
    void encodesAckWithRef() {
        String json = GameEnvelopeCodec.encode(mapper, GameEvt.GAME_PLANE_ACCEPTED, 42, 17L, null);
        JsonNode node = parse(json);
        assertEquals(42, node.get("seq").asLong());
        assertEquals(17, node.get("ref").asLong());
    }

    @Test
    void encodesErrorWithCodeAndMessage() {
        String json = GameEnvelopeCodec.encodeError(mapper, GameErrorCode.NOT_YOUR_TURN, "还没轮到你", 43, 9L);
        JsonNode node = parse(json);
        assertEquals("error", node.get("evt").asText());
        assertEquals(9, node.get("ref").asLong());
        assertEquals("NOT_YOUR_TURN", node.get("data").get("code").asText());
        assertEquals("还没轮到你", node.get("data").get("message").asText());
    }

    @Test
    void errorWithoutMessageFallsBackToCode() {
        JsonNode node = parse(GameEnvelopeCodec.encodeError(mapper, GameErrorCode.INTERNAL, null, 1, null));
        assertEquals("INTERNAL", node.get("data").get("message").asText());
    }

    // ---------------------------------------------------------------- 枚举词表

    @Test
    void everyCmdWireRoundTrips() {
        for (GameCmd c : GameCmd.values()) assertEquals(c, GameCmd.fromWire(c.wire));
        assertNull(GameCmd.fromWire("nope"));
        assertNull(GameCmd.fromWire(null));
    }

    @Test
    void everyEvtWireRoundTrips() {
        for (GameEvt e : GameEvt.values()) assertEquals(e, GameEvt.fromWire(e.wire));
        assertNull(GameEvt.fromWire("nope"));
    }

    @Test
    void cmdWireVocabularyMatchesProtocolDoc() {
        // protocol.md 的 19 条命令，一字不差
        String[] expected = {
            "profile.get", "nickname.set", "room.create", "room.join", "room.list", "room.rules",
            "room.ready", "room.leave", "room.kick", "room.listed", "queue.join", "queue.leave",
            "practice.create", "game.place", "game.fire", "game.item", "rank.list", "coins.ledger",
            "coin.adReward"};
        assertEquals(expected.length, GameCmd.values().length);
        for (String wire : expected) {
            assertFalse(GameCmd.fromWire(wire) == null, "命令缺失: " + wire);
        }
    }

    private JsonNode parse(String json) {
        try {
            return mapper.readTree(json);
        } catch (Exception e) {
            throw new AssertionError("编码结果不是合法 JSON: " + json, e);
        }
    }
}
