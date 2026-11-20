package com.timeline.game.service;

import com.timeline.game.domain.GameTypes;

/**
 * 单人全量快照（TS state{table, game} 直译）：重连/进桌/开局时发给个人的私有视图。
 * game 为 null 表示桌上没有在进行的对局（等待期）。
 */
public record TableSnapshot(GameTypes.TableView table, GameTypes.GameView game) {}
