package com.timeline.game.engine;

import com.timeline.game.domain.GameTypes;
import com.timeline.game.domain.Placement;
import com.timeline.game.domain.Rules;
import com.timeline.game.domain.Ruleset;
import com.timeline.game.protocol.GameErrorCode;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.function.DoubleSupplier;

/**
 * 对局引擎接口与两种引擎共用的摆放阶段（TS apps/server/src/engine.ts 直译）。
 * 工厂：2 人 → DuelEngine，3–4 人 → MeleeEngine。
 */
public interface Engine {

    long DISCONNECT_GRACE_MS = 30_000;

    GameTypes.Mode mode();

    GameTypes.GamePhase phase();

    /** phase == FINISHED 时非空。 */
    GameTypes.GameResult result();

    /** 只处理 place / fire / leave。 */
    List<Outbound> handle(String playerId, GameCommand cmd, long now);

    List<Outbound> tick(long now);

    List<Outbound> setConnected(String playerId, boolean connected, long now);

    GameTypes.GameView view(String playerId);

    /** 玩家对引擎可发的命令（客户端消息的子集；leave = 认输/离开）。 */
    sealed interface GameCommand {
        record Place(List<Rules.Cell> planes) implements GameCommand {}
        record Fire(int row, int col) implements GameCommand {}
        record Leave() implements GameCommand {}
    }

    record EngineOptions(Ruleset.RuleSet rules, List<String> playerIds, long now, DoubleSupplier rng) {
        public EngineOptions(Ruleset.RuleSet rules, List<String> playerIds, long now) {
            this(rules, playerIds, now, Math::random);
        }
    }

    /** 2 人 → DuelEngine，3–4 人 → MeleeEngine。 */
    static Engine create(EngineOptions opts) {
        int n = opts.playerIds().size();
        if (n < 2 || n > 4) throw new IllegalArgumentException("createEngine: playerIds must have 2-4 players, got " + n);
        return n == 2 ? new DuelEngine(opts) : new MeleeEngine(opts);
    }

    /** 两种引擎共用的摆放阶段：同时摆放、可重摆、到时自动摆放。 */
    final class PlacingPhase {
        private final Ruleset.RuleSet rules;
        private final List<String> playerIds;
        private final DoubleSupplier rng;
        private long deadlineAt;
        private final Map<String, List<Rules.Cell>> planes = new HashMap<>();

        public PlacingPhase(Ruleset.RuleSet rules, List<String> playerIds, long now, DoubleSupplier rng) {
            this.rules = rules;
            this.playerIds = playerIds;
            this.rng = rng;
            this.deadlineAt = now + Ruleset.placeSeconds(rules) * 1000L;
        }

        public long deadlineAt() { return deadlineAt; }

        /** 合法 → planeAccepted 给本人（可重摆，替换旧摆放）；非法 → INVALID_PLACEMENT。非成员 → 空。 */
        public List<Outbound> place(String playerId, List<Rules.Cell> heads) {
            if (!playerIds.contains(playerId)) return List.of();
            Rules.PlacementCheck check = Rules.checkPlacement(heads, rules.boardSize(), rules.planeCount());
            if (!check.ok()) {
                return List.of(new Outbound(playerId,
                    new EngineEvent.Error(GameErrorCode.INVALID_PLACEMENT, check.reason().name())));
            }
            planes.put(playerId, List.copyOf(heads));
            return List.of(new Outbound(playerId, new EngineEvent.PlaneAccepted(List.copyOf(heads))));
        }

        /** 给未摆放者 autoPlace，各发 planeAccepted。 */
        public List<Outbound> autoPlaceMissing() {
            List<Outbound> out = new ArrayList<>();
            for (String id : playerIds) {
                if (planes.containsKey(id)) continue;
                var placed = com.timeline.game.domain.Placement.autoPlace(rules.boardSize(), rules.planeCount(), rng);
                planes.put(id, placed);
                out.add(new Outbound(id, new EngineEvent.PlaneAccepted(placed)));
            }
            return out;
        }

        public boolean allPlaced() {
            return playerIds.stream().allMatch(planes::containsKey);
        }

        public List<Rules.Cell> planesOf(String playerId) {
            return planes.get(playerId);
        }

        /** duel 暂停顺延用。 */
        public void extend(long ms) {
            deadlineAt += ms;
        }
    }
}
