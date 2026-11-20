package com.timeline.game.protocol;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.timeline.game.domain.GameTypes;
import com.timeline.game.domain.Rules;
import com.timeline.game.engine.EngineEvent;

/**
 * 引擎事件 → wire JSON（协议层）：{@link EngineEvent} 各分支到 evt 名 + data 形状的映射。
 *
 * 为什么单独一层：引擎只产类型化事件、不碰 JSON，信封（seq/ref）由 GameEnvelopeCodec 负责；
 * 这里只回答"这条事件在协议里叫什么、data 长什么样"。evt 名与 docs/game/protocol.md 的事件清单一一对应。
 * 枚举一律序列化成小写（phase/result/reason），坐标一律 {"row":r,"col":c}；
 * 可缺字段（deadlineAt/turn/round/planeId/eliminatedRound）显式 putNull，客户端无脑读、不必判存在性。
 */
public final class EngineEventCodec {

    private EngineEventCodec() {}

    /** 编码结果：事件名 + data 节点（尚未套信封）。 */
    public record Encoded(GameEvt evt, ObjectNode data) {}

    /** 单条引擎事件 → evt + data。sealed switch 穷尽分支：引擎加事件时这里编译期就会提醒。 */
    public static Encoded encode(ObjectMapper mapper, EngineEvent ev) {
        return switch (ev) {
            case EngineEvent.Error e -> {
                ObjectNode data = mapper.createObjectNode();
                data.put("code", e.code().name());
                data.put("message", e.message());
                yield new Encoded(GameEvt.ERROR, data);
            }
            case EngineEvent.PlaneAccepted e -> {
                ObjectNode data = mapper.createObjectNode();
                ArrayNode planes = data.putArray("planes");
                for (Rules.Cell cell : e.planes()) planes.add(cellNode(mapper, cell));
                yield new Encoded(GameEvt.GAME_PLANE_ACCEPTED, data);
            }
            case EngineEvent.PhaseChanged e -> {
                ObjectNode data = mapper.createObjectNode();
                data.put("phase", e.phase().name().toLowerCase());
                putNullableLong(data, "deadlineAt", e.deadlineAt());
                putNullableText(data, "turn", e.turn());
                putNullableInt(data, "round", e.round());
                yield new Encoded(GameEvt.PHASE_CHANGED, data);
            }
            case EngineEvent.GameShot e -> {
                ObjectNode data = mapper.createObjectNode();
                data.put("by", e.by());
                data.put("row", e.row());
                data.put("col", e.col());
                data.put("result", e.result().name().toLowerCase());
                putNullableText(data, "planeId", e.planeId());
                data.put("nextTurn", e.nextTurn());
                yield new Encoded(GameEvt.GAME_SHOT, data);
            }
            case EngineEvent.PlaneDestroyed e -> {
                ObjectNode data = mapper.createObjectNode();
                data.put("ownerId", e.ownerId());
                data.put("planeId", e.planeId());
                yield new Encoded(GameEvt.GAME_DESTROYED, data);
            }
            case EngineEvent.GameOver e -> {
                ObjectNode data = mapper.createObjectNode();
                data.put("reason", e.result().reason().name().toLowerCase());
                ArrayNode ranking = data.putArray("ranking");
                for (GameTypes.RankEntry r : e.result().ranking()) {
                    ObjectNode entry = ranking.addObject();
                    entry.put("playerId", r.playerId());
                    entry.put("rank", r.rank());
                    putNullableInt(entry, "eliminatedRound", r.eliminatedRound());
                    entry.put("hits", r.hits());
                }
                yield new Encoded(GameEvt.GAME_OVER, data);
            }
            case EngineEvent.Presence e -> {
                ObjectNode data = mapper.createObjectNode();
                data.put("playerId", e.playerId());
                data.put("connected", e.connected());
                yield new Encoded(GameEvt.PLAYER_PRESENCE, data);
            }
            case EngineEvent.Submitted e -> {
                ObjectNode data = mapper.createObjectNode();
                data.put("playerId", e.playerId());
                data.put("round", e.round());
                yield new Encoded(GameEvt.GAME_SUBMITTED, data);
            }
            case EngineEvent.RoundResult e -> {
                ObjectNode data = mapper.createObjectNode();
                data.put("round", e.round());
                ArrayNode shots = data.putArray("shots");
                for (GameTypes.TargetShot s : e.shots()) {
                    ObjectNode n = shots.addObject();
                    n.put("targetId", s.targetId());
                    n.put("row", s.row());
                    n.put("col", s.col());
                    n.put("result", s.result().name().toLowerCase());
                    putNullableText(n, "planeId", s.planeId());
                }
                ArrayNode incoming = data.putArray("incoming");
                for (GameTypes.IncomingShot s : e.incoming()) {
                    ObjectNode n = incoming.addObject();
                    n.put("by", s.by());
                    n.put("row", s.row());
                    n.put("col", s.col());
                    n.put("result", s.result().name().toLowerCase());
                    putNullableText(n, "planeId", s.planeId());
                }
                ArrayNode destroyed = data.putArray("destroyed");
                for (EngineEvent.DestroyedCount d : e.destroyed()) {
                    ObjectNode n = destroyed.addObject();
                    n.put("playerId", d.playerId());
                    n.put("planesDestroyed", d.planesDestroyed());
                }
                ArrayNode eliminated = data.putArray("eliminated");
                for (String id : e.eliminated()) eliminated.add(id);
                yield new Encoded(GameEvt.GAME_ROUND_RESULT, data);
            }
            case EngineEvent.PlayerOut e -> {
                ObjectNode data = mapper.createObjectNode();
                data.put("playerId", e.playerId());
                data.put("round", e.round());
                yield new Encoded(GameEvt.GAME_PLAYER_OUT, data);
            }
        };
    }

    // ---------------------------------------------------------------- 小工具

    private static ObjectNode cellNode(ObjectMapper mapper, Rules.Cell cell) {
        ObjectNode node = mapper.createObjectNode();
        node.put("row", cell.row());
        node.put("col", cell.col());
        return node;
    }

    /** 可缺字段显式 putNull：客户端读法统一，不需要 has() 判断。 */
    private static void putNullableLong(ObjectNode node, String field, Long value) {
        if (value == null) node.putNull(field);
        else node.put(field, value);
    }

    private static void putNullableInt(ObjectNode node, String field, Integer value) {
        if (value == null) node.putNull(field);
        else node.put(field, value);
    }

    private static void putNullableText(ObjectNode node, String field, String value) {
        if (value == null) node.putNull(field);
        else node.put(field, value);
    }
}
