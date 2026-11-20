package com.timeline.game.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.timeline.game.domain.Coins;
import com.timeline.game.domain.GameTypes;
import com.timeline.game.domain.Ruleset;

import java.util.List;

/**
 * Hub 出站侧的共享数据结构与 wire data 构造器（TS hub.ts 内联的 JSON 组装直译）。
 *
 * <p>为什么单独一个类：Hub 本体只讲业务语义（路由/归因/门票/tick），wire 的
 * "字段名与可缺字段写法"是协议表达，集中在这一处便于和 docs/game/protocol.md 对表；
 * 引擎事件的 data 形状不归这里管（已在 {@code protocol/EngineEventCodec}）。
 *
 * <p>枚举一律序列化成小写（kind/phase/mode/result/reason/preset/ticket），与
 * EngineEventCodec 的口径一致；可缺字段显式 putNull，客户端无脑读。
 * 大厅列表条目刻意逐字段拼——RoomListEntry 里本来就没有 roomCode/playerId/ready，
 * 编码层再手拼一遍，杜绝将来 POJO 加字段时把隐私字段顺手带出去（spec §6.8）。
 */
public final class HubOutbound {

    private HubOutbound() {}

    /**
     * 门票桌记账（TS ticketByTable 的 value）：门票档 + 入座真人名单。
     * 名单必须连着票一起记：首局没打完桌就关了，要按入座名单全额退款（评审 #2）。
     */
    public record Booked(Coins.TicketId ticket, List<String> ids) {}

    /** 专区上次推送的内容与时刻（合并推送的依据，spec §20.6）。 */
    public record RoomLast(String json, long at) {}

    // ---------------------------------------------------------------- 桌子视图

    public static ObjectNode tableNode(ObjectMapper mapper, GameTypes.TableView t) {
        ObjectNode node = mapper.createObjectNode();
        node.put("roomCode", t.roomCode());
        node.put("kind", t.kind().name().toLowerCase());
        node.put("capacity", t.capacity());
        node.set("rules", ruleSetNode(mapper, t.rules()));
        node.put("rulesVersion", t.rulesVersion());
        node.put("listed", t.listed());
        node.putNull("hostId");
        if (t.hostId() != null) node.put("hostId", t.hostId());
        node.put("phase", t.phase().name().toLowerCase());
        ArrayNode seats = node.putArray("seats");
        for (GameTypes.SeatView s : t.seats()) {
            if (s == null) { seats.addNull(); continue; }
            ObjectNode sn = seats.addObject();
            sn.put("seat", s.seat());
            sn.put("playerId", s.playerId());
            sn.put("nickname", s.nickname());
            sn.put("ready", s.ready());
            sn.put("connected", s.connected());
            sn.put("bot", s.bot());
        }
        node.set("lastResult", t.lastResult() == null
            ? node.nullNode() : tableResultNode(mapper, t.lastResult()));
        return node;
    }

    public static ObjectNode tableResultNode(ObjectMapper mapper, GameTypes.TableResult r) {
        ObjectNode node = mapper.createObjectNode();
        node.put("reason", r.reason().name().toLowerCase());
        node.set("ranking", rankingNode(mapper, r.ranking()));
        ArrayNode bots = node.putArray("botIds");
        for (String id : r.botIds()) bots.add(id);
        return node;
    }

    public static ObjectNode snapshotNode(ObjectMapper mapper, TableSnapshot snapshot) {
        // 有意差异（Table 类注释）：sealed TableEvent 没有 state 变体，
        // 私有 {table, game} 快照借 table.state 下发，data 里多出 game 节点。
        ObjectNode node = mapper.createObjectNode();
        node.set("table", tableNode(mapper, snapshot.table()));
        node.set("game", snapshot.game() == null
            ? node.nullNode() : gameNode(mapper, snapshot.game()));
        return node;
    }

    // ---------------------------------------------------------------- 引擎视图（仅供快照的 game 节点用）

    public static ObjectNode gameNode(ObjectMapper mapper, GameTypes.GameView g) {
        ObjectNode node = mapper.createObjectNode();
        node.put("mode", g.mode().name().toLowerCase());
        node.put("phase", g.phase().name().toLowerCase());
        putNullableLong(node, "deadlineAt", g.deadlineAt());
        putNullableText(node, "turn", g.turn());
        putNullableInt(node, "round", g.round());
        node.set("you", youNode(mapper, g.you()));
        ArrayNode others = node.putArray("others");
        for (GameTypes.OtherPlayerView o : g.others()) {
            ObjectNode on = others.addObject();
            on.put("playerId", o.playerId());
            on.put("connected", o.connected());
            on.put("alive", o.alive());
            on.put("planesDestroyed", o.planesDestroyed());
            on.put("submitted", o.submitted());
        }
        return node;
    }

    private static ObjectNode youNode(ObjectMapper mapper, GameTypes.YouView you) {
        ObjectNode node = mapper.createObjectNode();
        node.set("planes", cellsNode(mapper, you.planes()));
        node.put("planesDestroyed", you.planesDestroyed());
        node.put("alive", you.alive());
        node.set("shots", shotsNode(mapper, you.shots(), "targetId"));
        node.set("incoming", shotsNode(mapper, you.incoming(), "by"));
        node.put("submitted", you.submitted());
        node.set("pendingShot", you.pendingShot() == null
            ? node.nullNode() : cellNode(mapper, you.pendingShot()));
        return node;
    }

    /** TargetShot 与 IncomingShot 字段同名不同首列（targetId / by），共用一个循环。 */
    private static ArrayNode shotsNode(ObjectMapper mapper, List<?> shots, String whoField) {
        ArrayNode arr = mapper.createArrayNode();
        for (Object s : shots) {
            ObjectNode n = arr.addObject();
            if (s instanceof GameTypes.TargetShot t) {
                n.put(whoField, t.targetId());
                n.put("row", t.row());
                n.put("col", t.col());
                n.put("result", t.result().name().toLowerCase());
                putNullableText(n, "planeId", t.planeId());
            } else if (s instanceof GameTypes.IncomingShot i) {
                n.put(whoField, i.by());
                n.put("row", i.row());
                n.put("col", i.col());
                n.put("result", i.result().name().toLowerCase());
                putNullableText(n, "planeId", i.planeId());
            }
        }
        return arr;
    }

    // ---------------------------------------------------------------- 大厅列表

    /** 大厅列表条目数组；排序/截断在 Hub 做完后才进来，这里只管如实编码。 */
    public static ArrayNode roomListEntries(ObjectMapper mapper, List<GameTypes.RoomListEntry> entries) {
        ArrayNode arr = mapper.createArrayNode();
        for (GameTypes.RoomListEntry e : entries) {
            ObjectNode n = arr.addObject();
            n.put("tableId", e.tableId());
            n.put("capacity", e.capacity());
            n.set("rules", ruleSetNode(mapper, e.rules()));
            n.put("hostNickname", e.hostNickname());
            n.put("seated", e.seated());
            ArrayNode seats = n.putArray("seats");
            for (GameTypes.RoomListEntry.PublicSeat ps : e.seats()) {
                if (ps == null) { seats.addNull(); continue; }
                ObjectNode sn = seats.addObject();
                sn.put("seat", ps.seat());
                sn.put("nickname", ps.nickname());
            }
            n.put("createdAt", e.createdAt());
        }
        return arr;
    }

    // ---------------------------------------------------------------- 队列 / 档案 / 金币

    public static ObjectNode queueStatusNode(ObjectMapper mapper, QueueEvent.Status s) {
        ObjectNode node = mapper.createObjectNode();
        node.put("capacity", s.capacity());
        node.put("preset", s.preset().name().toLowerCase());
        node.put("waiting", s.waiting());
        putNullableLong(node, "botFillAt", s.botFillAt());
        node.put("humansNeeded", s.humansNeeded());
        // v4 兼容：客户端没传门票字段的队列，整条事件也不带 ticket
        if (s.ticket() != null) node.put("ticket", s.ticket().name().toLowerCase());
        return node;
    }

    public static ObjectNode profileNode(ObjectMapper mapper, GameProfileService.ProfileView p) {
        ObjectNode node = mapper.createObjectNode();
        node.put("userId", p.userId());
        node.put("nickname", p.nickname());
        node.set("rank", p.rank() == null ? node.nullNode() : rankViewNode(mapper, p.rank()));
        node.set("coins", p.coins() == null ? node.nullNode() : coinsNode(mapper, p.coins()));
        node.put("season", p.season());
        return node;
    }

    private static ObjectNode rankViewNode(ObjectMapper mapper, GameProfileService.RankView r) {
        ObjectNode node = mapper.createObjectNode();
        node.put("tier", r.tier());
        node.put("stars", r.stars());
        node.put("lossStreak", r.lossStreak());
        node.put("wins", r.wins());
        node.put("losses", r.losses());
        node.put("totalHits", r.totalHits());
        node.put("bestTier", r.bestTier());
        node.put("bestStars", r.bestStars());
        node.put("streak", r.streak());
        node.put("scoringGames", r.scoringGames());
        return node;
    }

    private static ObjectNode coinsNode(ObjectMapper mapper, GameProfileService.WalletView w) {
        ObjectNode node = mapper.createObjectNode();
        node.put("balance", w.balance());
        return node;
    }

    public static ObjectNode rankChangedNode(ObjectMapper mapper, int delta,
                                             int tier, int stars, int lossStreak, String reason) {
        ObjectNode node = mapper.createObjectNode();
        node.put("delta", delta);
        ObjectNode rank = node.putObject("rank");
        rank.put("tier", tier);
        rank.put("stars", stars);
        rank.put("lossStreak", lossStreak);
        node.put("reason", reason);
        return node;
    }

    /** coinsChanged → wire coins.now（spec §0：展示账变统一走 coins.now 推送、coins.ledger 拉取）。 */
    public static ObjectNode coinsNowNode(ObjectMapper mapper, int delta, String reason,
                                          int balance, boolean capped) {
        ObjectNode node = mapper.createObjectNode();
        node.put("delta", delta);
        node.put("reason", reason);
        node.put("balance", balance);
        if (capped) node.put("capped", true);
        return node;
    }

    public static ObjectNode rankListNode(ObjectMapper mapper, int season,
                                          List<GameProfileService.RankRowEntry> rows) {
        ObjectNode node = mapper.createObjectNode();
        node.put("season", season);
        ArrayNode entries = node.putArray("entries");
        for (GameProfileService.RankRowEntry r : rows) {
            ObjectNode n = entries.addObject();
            n.put("pos", r.pos());
            n.put("nickname", r.nickname());
            n.put("tier", r.tier());
            n.put("stars", r.stars());
            n.put("wins", r.wins());
            // 隐私红线（spec §4）：榜单条目不含 playerId
        }
        return node;
    }

    public static ObjectNode ledgerNode(ObjectMapper mapper, GameProfileService.LedgerView v) {
        ObjectNode node = mapper.createObjectNode();
        node.put("balance", v.balance());
        ArrayNode ledger = node.putArray("ledger");
        for (GameProfileService.LedgerEntry e : v.entries()) {
            ObjectNode n = ledger.addObject();
            n.put("entryKey", e.entryKey());
            n.put("reason", e.reason());
            n.put("delta", e.delta());
            n.put("atMs", e.atMs());
        }
        return node;
    }

    public static ObjectNode kickedNode(ObjectMapper mapper, String roomCode) {
        ObjectNode node = mapper.createObjectNode();
        node.put("roomCode", roomCode);
        return node;
    }

    public static ObjectNode roomListNode(ObjectMapper mapper, int capacity, ArrayNode entries) {
        ObjectNode node = mapper.createObjectNode();
        node.put("capacity", capacity);
        node.set("entries", entries);
        return node;
    }

    // ---------------------------------------------------------------- 小工具

    private static ObjectNode ruleSetNode(ObjectMapper mapper, Ruleset.RuleSet r) {
        ObjectNode node = mapper.createObjectNode();
        node.put("boardSize", r.boardSize());
        node.put("planeCount", r.planeCount());
        node.put("turnSeconds", r.turnSeconds());
        node.put("hintAllowed", r.hintAllowed());
        return node;
    }

    private static ArrayNode cellsNode(ObjectMapper mapper, List<com.timeline.game.domain.Rules.Cell> cells) {
        ArrayNode arr = mapper.createArrayNode();
        for (com.timeline.game.domain.Rules.Cell c : cells) arr.add(cellNode(mapper, c));
        return arr;
    }

    private static ObjectNode cellNode(ObjectMapper mapper, com.timeline.game.domain.Rules.Cell c) {
        ObjectNode n = mapper.createObjectNode();
        n.put("row", c.row());
        n.put("col", c.col());
        return n;
    }

    public static ArrayNode rankingNode(ObjectMapper mapper, List<GameTypes.RankEntry> ranking) {
        ArrayNode arr = mapper.createArrayNode();
        for (GameTypes.RankEntry r : ranking) {
            ObjectNode n = arr.addObject();
            n.put("playerId", r.playerId());
            n.put("rank", r.rank());
            putNullableInt(n, "eliminatedRound", r.eliminatedRound());
            n.put("hits", r.hits());
        }
        return arr;
    }

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
