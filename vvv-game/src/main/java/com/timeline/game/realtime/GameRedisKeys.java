package com.timeline.game.realtime;

/**
 * Redis 键表（docs/game/design.md 状态放置表的唯一落点）。
 *
 * 前缀纪律：所有键都以 {@code game:} 开头——真库/真 Redis 与平台其它业务共用，
 * 前缀是唯一的隔离手段（同库表 game_* 前缀一个道理）。
 *
 * v1 的取舍（诚实记录，见 docs/game/README.md 待办）：
 * 桌子/对局引擎状态留在持连进程内存（同 TS 版），Redis 只放跨进程可见的
 * presence / 席位映射 / 桌子索引 / 锁——支撑崩溃巡检与重连路由；
 * 引擎态进 Redis 的多实例共享是后续扩展，不在 v1。
 */
public final class GameRedisKeys {

    private GameRedisKeys() {}

    /** 在线连接：`game:presence:{userId}` = clientId，TTL 续期（默认 90s），到期即视为离线。 */
    public static String presence(long userId) {
        return "game:presence:" + userId;
    }

    /** 玩家 → 所在桌子（重连路由与"一人一桌"约束的跨进程视图）。 */
    public static String seat(long userId) {
        return "game:seat:" + userId;
    }

    /** 桌子索引（Set，成员 tableId）：kill -9 后启动巡检按它扫存量桌走散桌退款。 */
    public static String tableIndex() {
        return "game:table:index";
    }

    /** 桌子登记表条目：`game:table:{tableId}` = 桌子公开信息 JSON（房号/容量/创建时刻），供巡检与列表。 */
    public static String table(String tableId) {
        return "game:table:" + tableId;
    }

    /** 房号 → tableId（好友房按房号寻址；随桌删除）。 */
    public static String room(String roomCode) {
        return "game:room:" + roomCode;
    }

    /** 匹配队列（v1 内存实现时先占键位；多实例扩展用）。 */
    public static String queue(int capacity, String preset, String ticket) {
        return "game:queue:" + capacity + ":" + preset + ":" + ticket;
    }

    /** 用户级写锁（RedisLockServiceImpl，TTL 5s）。 */
    public static String userLock(long userId) {
        return "game:lock:user:" + userId;
    }

    /** 桌子级锁（双实例并发处理同一桌时后到者放弃）。 */
    public static String tableLock(String tableId) {
        return "game:lock:table:" + tableId;
    }

    /** 赛季任务锁（发奖/重置只允许一个实例跑）。 */
    public static String seasonLock(int seasonNo) {
        return "game:lock:season:" + seasonNo;
    }
}
