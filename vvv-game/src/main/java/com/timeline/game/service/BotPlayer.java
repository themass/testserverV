package com.timeline.game.service;

import com.timeline.game.domain.GameTypes;
import com.timeline.game.domain.Placement;
import com.timeline.game.domain.Rules;
import com.timeline.game.domain.Ruleset;
import com.timeline.game.engine.Engine;

import java.util.Objects;
import java.util.Optional;
import java.util.function.DoubleSupplier;

/**
 * 电脑玩家的完整实现：决策（{@link BotBrain}）+ 出手时机（TS apps/server/src/bot/driver.ts 直译，spec §5）。
 *
 * <p>纯函数式：时间由调用方通过 {@code now} 传入，不读墙钟；随机性只来自注入的 rng。
 * 思考时长 {@value #THINK_LO_MS}–{@value #THINK_HI_MS} ms 随机，并钳到 {@code deadlineAt − }
 * {@value #DEADLINE_MARGIN_MS} ms（不足则立即出手，且不早于 now）。
 *
 * <p><b>rng 调用次序（对齐 driver.ts）</b>：新决策点建计划时抽一次思考时长；真正出手时
 * 摆放走 autoPlace 的一串随机，开炮走 {@link BotBrain#chooseShot}（误着骰 → 可选均匀挑 → 并列挑）。
 * 计划未重建时不再抽时长——因此同 seed 的 poll 序列与 TS 逐步一致。
 */
public final class BotPlayer implements GameBot {

    /** 每个新决策点的思考时间范围下界（毫秒，TS BOT_THINK_MS[0]）。 */
    public static final long THINK_LO_MS = 1200;
    /** 每个新决策点的思考时间范围上界（毫秒，TS BOT_THINK_MS[1]）。 */
    public static final long THINK_HI_MS = 3500;
    /** 最晚在截止前这么久出手（毫秒，TS BOT_DEADLINE_MARGIN_MS）。 */
    public static final long DEADLINE_MARGIN_MS = 1000;

    /** 摆放决策键。 */
    static final String KEY_PLACE = "place";

    private final String playerId;
    private final Ruleset.PresetId difficulty;
    private final DoubleSupplier rng;

    /** 当前计划：决策点键、计划出手时间、制定计划时的 deadlineAt。 */
    private String planKey;
    /** 计划出手时刻保留小数（对齐 TS：actAt 是实数，判定是 now < actAt）——取整会让出手时刻差 1ms。 */
    private double planActAt;
    private Long planDeadlineAt;
    private boolean hasPlan;
    /** 已出过手的键。键消失（无决策点）时清除。 */
    private String doneKey;

    public BotPlayer(String playerId, Ruleset.PresetId difficulty, DoubleSupplier rng) {
        this.playerId = playerId;
        this.difficulty = difficulty;
        this.rng = rng;
    }

    @Override
    public String playerId() {
        return playerId;
    }

    /** 难度预设（TS difficulty 字段）；同时决定 {@link BotBrain#BOT_MISTAKE_RATE}。 */
    public Ruleset.PresetId difficulty() {
        return difficulty;
    }

    @Override
    public Optional<Engine.GameCommand> poll(GameTypes.GameView view, Ruleset.RuleSet rules, long now) {
        String key = decisionKey(view);
        if (key == null) {
            hasPlan = false;
            planDeadlineAt = null;
            doneKey = null;
            return Optional.empty();
        }
        if (key.equals(doneKey)) return Optional.empty();

        if (!hasPlan || !key.equals(planKey) || !Objects.equals(planDeadlineAt, view.deadlineAt())) {
            planKey = key;
            planActAt = scheduleAt(now, view.deadlineAt());
            planDeadlineAt = view.deadlineAt();
            hasPlan = true;
        }
        if ((double) now < planActAt) return Optional.empty();

        doneKey = key;
        hasPlan = false;
        planDeadlineAt = null;
        return act(key, view, rules);
    }

    /** 当前是否存在待执行的思考计划（仅供测试与诊断）。 */
    public boolean hasPendingPlan() {
        return hasPlan;
    }

    /** 摆放阶段未摆放 → 'place'；duel 轮到自己 → {@code turn:{shotsSoFar}}；melee 本轮未提交 → {@code round:{round}}。 */
    private String decisionKey(GameTypes.GameView view) {
        if (view.phase() == GameTypes.GamePhase.PLACING) {
            return view.you().planes().isEmpty() ? KEY_PLACE : null;
        }
        if (view.phase() != GameTypes.GamePhase.PLAYING) return null; // paused / finished
        if (view.mode() == GameTypes.Mode.DUEL) {
            return playerId.equals(view.turn()) ? "turn:" + view.you().shots().size() : null;
        }
        if (!view.you().alive() || view.you().submitted() || view.round() == null) return null;
        return "round:" + view.round();
    }

    private double scheduleAt(long now, Long deadlineAt) {
        double actAt = now + THINK_LO_MS + rng.getAsDouble() * (THINK_HI_MS - THINK_LO_MS);
        if (deadlineAt != null) actAt = Math.min(actAt, deadlineAt - DEADLINE_MARGIN_MS);
        return Math.max(actAt, now);
    }

    private Optional<Engine.GameCommand> act(String key, GameTypes.GameView view, Ruleset.RuleSet rules) {
        if (KEY_PLACE.equals(key)) {
            return Optional.of(new Engine.GameCommand.Place(
                Placement.autoPlace(rules.boardSize(), rules.planeCount(), rng)));
        }
        Rules.Cell cell = BotBrain.chooseShot(view, rules, difficulty, rng);
        return cell == null ? Optional.empty()
            : Optional.of(new Engine.GameCommand.Fire(cell.row(), cell.col()));
    }
}
