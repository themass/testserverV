package com.timeline.game.service;

import com.timeline.game.domain.GameTypes;
import com.timeline.game.engine.EngineEvent;

/**
 * 桌子层对外事件（TS table.ts 返回消息里桌子级的那部分；引擎级事件原样转发）。
 * 编码成 wire（evt 名见 docs/game/protocol.md）在 Hub/网关层做，这里只是内部契约。
 *
 * 全量快照策略：桌子任何状态变化都推 table.state，客户端无脑覆盖——
 * 这是相对 TS 版（碎片事件十余种）刻意收敛的一处，行为不变式见 protocol.md 尾表。
 */
public sealed interface TableEvent {

    /** wire: table.state —— 全量桌子快照。 */
    record TableState(GameTypes.TableView table) implements TableEvent {}

    /** wire: table.closed（Hub 侧编码；桌子内部一律静默 close，只有 Hub 决定是否发这条）。 */
    record Closed() implements TableEvent {}

    /** wire: kicked —— 被踢者专属；必须先于给其余人的 table.state 送达。 */
    record Kicked(String roomCode) implements TableEvent {}

    /** wire: game.planeAccepted 等——引擎事件经桌子转发。 */
    record FromEngine(EngineEvent event) implements TableEvent {}
}
