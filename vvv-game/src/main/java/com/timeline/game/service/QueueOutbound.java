package com.timeline.game.service;

/**
 * 队列层的一条定向消息（TS {@code Outbound = {to, msg}} 直译）：发给谁 + 什么队列事件。
 * 队列不存在 bot 收件人，故无需桌边界那套 {@code bot:} 前缀过滤。
 */
public record QueueOutbound(String to, QueueEvent event) {}
