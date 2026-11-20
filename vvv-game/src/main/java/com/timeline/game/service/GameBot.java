package com.timeline.game.service;

import com.timeline.game.domain.GameTypes;
import com.timeline.game.domain.Ruleset;
import com.timeline.game.engine.Engine;

import java.util.Optional;

/**
 * 电脑玩家的对外契约（TS bot/brain.ts 的 BotBrainLike + bot/driver.ts 的 poll 合并直译）。
 *
 * 桌子只通过这一个接口碰 bot：tick 里对每个 bot 座位调 poll，拿到命令回喂引擎。
 * bot 永不收网消息（桌子边界按 bot: 前缀丢弃），因此这里没有发送通道。
 * 实现（思考时长抖动、难度误着率）见 GameBotBrain；测试可注入桩实现。
 */
public interface GameBot {

    /** 座位 id，恒以 "bot:" 开头（桌子/Hub 依此过滤收件人与归因）。 */
    String playerId();

    /**
     * 看快照决定是否行动（TS BotDriver.poll）：
     * 摆放未完成 → 摆放；duel 轮到自己 → 开炮；melee 本轮未提交 → 提交。
     * 每个决策点只动作一次（driver 的 doneKey 语义），思考时长在实现内随机并钳到 deadlineAt−1000ms。
     */
    Optional<Engine.GameCommand> poll(GameTypes.GameView view, Ruleset.RuleSet rules, long now);
}
