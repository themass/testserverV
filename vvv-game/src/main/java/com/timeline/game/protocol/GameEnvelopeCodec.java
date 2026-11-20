package com.timeline.game.protocol;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;

/**
 * 信封编解码（协议层）：{"v":1,"cmd":"room.create","seq":17,"data":{...}} 的双向转换。
 *
 * 解码只负责信封骨架（v/cmd/seq/data 是否成形、命令名是否认识）；
 * data 的业务形状校验在各命令的 handler 里做（不同命令形状不同，这里不掺和）。
 * 编解码不抛异常：一切失败收口成 {@link DecodeResult} 的 bad 形态 + 错误码，由调用方回 error 事件。
 */
public final class GameEnvelopeCodec {

    /** 协议版本。收到不认识的 v → BAD_SHAPE（将来若做双版本再扩）。 */
    public static final int PROTOCOL_VERSION = 1;

    private GameEnvelopeCodec() {}

    /** 客户端命令信封（解码后）。data 保持原始 JsonNode，由各 handler 自行按形状取用。 */
    public record Inbound(GameCmd cmd, long seq, JsonNode data) {}

    /** 解码结果：成功带 inbound；失败带错误码（BAD_JSON / BAD_SHAPE / UNKNOWN_CMD）。 */
    public record DecodeResult(Inbound inbound, GameErrorCode error) {
        public boolean ok() { return error == null; }
        static DecodeResult ok(Inbound in) { return new DecodeResult(in, null); }
        static DecodeResult fail(GameErrorCode error) { return new DecodeResult(null, error); }
    }

    /**
     * 解码一条客户端消息。
     * 非 JSON → BAD_JSON；缺 cmd 或 seq 或 v 不等于协议版本 → BAD_SHAPE；
     * cmd 不在词表 → UNKNOWN_CMD。
     */
    public static DecodeResult decode(ObjectMapper mapper, String raw) {
        // 空帧对齐 TS JSON.parse('') 抛异常 → BAD_JSON；Jackson 对 "" 会安静返回 NullNode，须先挡
        if (raw == null || raw.isBlank()) return DecodeResult.fail(GameErrorCode.BAD_JSON);
        JsonNode root;
        try {
            root = mapper.readTree(raw);
        } catch (Exception e) {
            return DecodeResult.fail(GameErrorCode.BAD_JSON);
        }
        if (root == null || !root.isObject()) return DecodeResult.fail(GameErrorCode.BAD_SHAPE);
        JsonNode v = root.get("v");
        if (v == null || !v.isNumber() || v.asInt() != PROTOCOL_VERSION) return DecodeResult.fail(GameErrorCode.BAD_SHAPE);
        JsonNode cmdNode = root.get("cmd");
        if (cmdNode == null || !cmdNode.isTextual()) return DecodeResult.fail(GameErrorCode.BAD_SHAPE);
        GameCmd cmd = GameCmd.fromWire(cmdNode.asText());
        if (cmd == null) return DecodeResult.fail(GameErrorCode.UNKNOWN_CMD);
        JsonNode seqNode = root.get("seq");
        if (seqNode == null || !seqNode.isIntegralNumber() || !seqNode.canConvertToLong()) {
            return DecodeResult.fail(GameErrorCode.BAD_SHAPE);
        }
        JsonNode data = root.get("data");
        return DecodeResult.ok(new Inbound(cmd, seqNode.asLong(), data));
    }

    /** 编码一条服务端事件。data 为 null 时省略 data 字段。 */
    public static String encode(ObjectMapper mapper, GameEvt evt, long seq, Long ref, JsonNode data) {
        ObjectNode node = mapper.createObjectNode();
        node.put("v", PROTOCOL_VERSION);
        node.put("evt", evt.wire);
        node.put("seq", seq);
        // ref：命令回执带原 seq；主动推送为 null（显式写出，客户端无脑读）
        if (ref != null) node.put("ref", ref);
        else node.putNull("ref");
        node.set("data", data == null ? mapper.createObjectNode() : data);
        return node.toString();
    }

    /** 统一错误回执。 */
    public static String encodeError(ObjectMapper mapper, GameErrorCode code, String message, long seq, Long ref) {
        ObjectNode data = mapper.createObjectNode();
        data.put("code", code.name());
        data.put("message", message == null ? code.name() : message);
        return encode(mapper, GameEvt.ERROR, seq, ref, data);
    }
}
