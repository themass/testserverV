package com.timeline.game.engine;

/** 引擎输出的一条定向消息（TS Outbound 直译）：发给谁 + 什么事件。 */
public record Outbound(String to, EngineEvent event) {}
