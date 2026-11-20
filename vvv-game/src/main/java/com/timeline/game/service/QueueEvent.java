package com.timeline.game.service;

import com.timeline.game.domain.Coins;
import com.timeline.game.domain.Ruleset;

/**
 * 匹配队列对外事件（TS ServerMessage 里的 queueStatus / queueTimeout 两条，spec §3）。
 *
 * 编码成 wire 在 Hub/网关层做（evt 名见 protocol/GameEvt）：
 * queueStatus → {@code queue.status}，queueTimeout → {@code queue.timeout}。
 * 这里只是 service 层与 Hub 之间的内部契约。
 */
public sealed interface QueueEvent {

    /**
     * wire: queue.status —— 队列人数与补位倒计时（全队列共享同一个 botFillAt）。
     *
     * @param waiting 当前队列真人数量
     * @param botFillAt 补位倒计时到点的绝对时刻；null = 不补位（补位关闭或真人不足 MIN_HUMANS）
     * @param humansNeeded 还差几个真人才开始补位（= max(0, MIN_HUMANS − waiting)）
     * @param ticket 门票档；null = 客户端没传门票字段（v4 调用方兼容，Hub 编码时整条省略）
     */
    record Status(int capacity, Ruleset.PresetId preset, int waiting, Long botFillAt,
                  int humansNeeded, Coins.TicketId ticket) implements QueueEvent {}

    /** wire: queue.timeout —— 仅补位关闭时的一次性"暂时没有对手"提示，不出队。 */
    record Timeout() implements QueueEvent {}
}
