package com.timeline.game.service;

/**
 * 桌子出站的一条定向消息（TS table.ts 的 Outbound 直译）：发给谁 + 桌子层事件。
 *
 * 所有桌子方法都返回 List&lt;TableOutbound&gt;；引擎事件一律包成 {@link TableEvent.FromEngine}。
 * 桌边界会丢弃 to 以 "bot:" 开头的条目（spec §2 invariant，table.ts:439）——电脑没有 socket，也永不收信。
 */
public record TableOutbound(String to, TableEvent event) {}
