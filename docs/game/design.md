# 总体设计

## 模块定位

`vvv-game` 是**库模块**（jar），不是可部署进程，完全照 vvv-student 的落地方式：

```
vvv-game/
  pom.xml                                    # 无 build 段，坐标继承父 pom
  src/main/java/com/timeline/game/
    config/GameAutoConfiguration.java        # @AutoConfiguration + @ConditionalOnProperty(game.enabled)
                                             #   + @ConditionalOnBean(SqlSessionFactory)
                                             #   + WebSocketConfigurer 注册
    api/        GameProfileController, GameCoinController, GameRankController  (@RestController)
                GameWsControllerSupport（握手拦截器：Vpn-Token → userId）
                GameErrors / GameResponse（record 契约，HTTP 语义，不碰 legacy JsonResult）
    protocol/   Cmd / Evt 枚举、Envelope record、编解码、错误码表
    domain/     Coins.java, Rank.java, Ruleset.java, Placement.java   ← 纯函数，逐条移植 shared
    engine/     DuelEngine.java, MeleeEngine.java                     ← 纯函数引擎
    service/    ProfileService, CoinService, RankService, TableService,
                MatchmakingService, WsHubService, GameRecordService
    realtime/   RedisTableStore, RedisQueueStore, RedisPresenceStore, RedisGameStore
    persistence/ GameProfileMapper, GameProgressMapper, GameWalletMapper,
                 GameCoinLedgerMapper, GameMatchMapper, GameMatchPlayerMapper, GameSeasonMapper
                 （接口 + 注解 SQL + record 行，无 XML、无 @Table，同 StudentDeviceMapper 风格）
  src/main/resources/
    db/game/V001__core.sql, V002__shots.sql, audit_integrity_checks.sql,
    db/game/recovery/drop_game_objects.sql
    META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports
  src/test/java/com/timeline/game/...        # H2 2.2.224 测持久层；domain/engine 纯单测
```

接线：父 pom `<module>vvv-game</module>`；`.github/workflows/ci.yml` 的 `-pl` 列表加 `vvv-game`；
`game.enabled=true` 写进 vvv-link 的 bootstrap（默认关，避免误上线上）。

## 分层规矩（越界就是 bug）

| 层 | 允许 | 禁止 |
|---|---|---|
| `domain` / `engine` | 纯 Java，无 Spring、无 IO、无时钟（时间从参数进） | import Redis/Mapper/WebSocket |
| `service` | 编排、锁、事务边界 | 直接读 HttpServletRequest |
| `realtime` | StringRedisTemplate，手写 JSON 字符串，显式 TTL | 落 MySQL |
| `persistence` | MyBatis 注解 SQL | 含业务判断 |
| `api` | 校验入参、装配响应 | 写业务 |

domain/engine 是 TS `packages/shared` 的直译，**对拍测试**喂同一批输入比结果，行为不一致即 bug。

## 状态放置：什么进 Redis，什么进 MySQL

原则：**Redis 丢了可以重建，MySQL 丢了才是事故。**

| 状态 | 存哪 | 键 / 表 | TTL |
|---|---|---|---|
| 桌子（座位、规则、phase、lastResult） | Redis | `game:table:{tableId}` | 无 TTL，散桌显式删；兜底 `game:table:index` 巡检 |
| roomCode → tableId | Redis | `game:room:{roomCode}` | 同上，随桌删 |
| 匹配队列 | Redis List/ZSet | `game:queue:{capacity}:{preset}:{ticket}` | 无（成员随进出） |
| 在线连接 | Redis String | `game:presence:{userId}` = clientId | 90s，心跳续期 |
| 进行中的对局引擎状态（棋盘、布阵、回合、deadline） | Redis Hash | `game:live:{tableId}` | 无 TTL，局结束删 |
| 玩家 ↔ 所在桌子 | Redis String | `game:seat:{userId}` = tableId | 随离桌删 |
| 玩家档案 / 段位 / 钱包 / 流水 / 对局记录 | **MySQL** | `game_*` 见 data-model.md | 永久（对局 365d、炮弹 90d 后清） |
| 分布式锁 | Redis | `game:lock:user:{userId}`、`game:lock:table:{tableId}` | 5s 自动过期，`RedisLockServiceImpl` |

为什么进程态进 Redis 而不是内存：将来起多个 vvv-link 实例时，WS 连接会散在不同实例上，
桌子与对局必须共享。这是"健壮"的主要成本来源，也是唯一能让多实例成立的做法。
Redis 不可用时：连接拒绝新握手，已在线的提示 `INTERNAL` 并重连，不写脏数据、不掉星。

## 可靠性场景逐条

| 场景 | 处理 |
|---|---|
| 结算写 MySQL 中途宕机 | `game_match.finished=0` 的行由启动巡检重放（幂等键保证只结一次） |
| 进程优雅停机 | 逐桌：进行中的局 `close_reason=abandoned` + 门票 `ticket-refund` + `table.closed`，与 TS 行为一致 |
| 双实例并发处理同一桌 | 桌子操作前取 `game:lock:table:{id}`；拿不到即放弃（另一实例在做） |
| 用户断线 | 座位保留，桌子 `paused`；宽限期（=2×turnSeconds 秒）后判负/散桌退款；`game:presence` TTL 到期即视为离线 |
| Redis 键泄漏（进程被 kill -9） | 启动时按 `game:table:index` 扫存量桌，无连接且超龄的桌走同一散桌退款路径 |
| 客户端连发非法包 | 每连接令牌桶（命令 ≤20/s），超了 `RATE_LIMITED`，连续超频断连 |
| 时间跳变 / 时区 | 日计数器用服务端本地日 `day_key` 字符串比较，跨日原地覆盖；业务时间戳全走 `BIGINT` 毫秒 |

## 与平台既有能力的复用清单

| 复用 | 来源 | 用法 |
|---|---|---|
| 身份 | `AuthUtil.nameToToken` + Redis `token_%s` + `CacheService.getUser(token)` → `UserPo` | WS 握手与 HTTP 请求同一校验；拿到 `vpn.user.id` 即游戏账号 |
| 昵称兜底 | `UserPo.name` | 首见用户未设游戏昵称时取平台 name |
| 锁 | `RedisLockServiceImpl`（vvv-common） | 用户级 / 桌子级写锁 |
| Redis 客户端 | `StringRedisTemplate`（**不用 jetcache**，仓库里声明了但从未使用） | 手写 JSON 串，键 `game:` 前缀，显式 TTL |
| 日志 | 既有 logback / `logs/` | 桌子与结算轨迹落 INFO，排查靠 matchId 串 |

## 待办（实现顺序即模块构建顺序）

1. 模块骨架 + AutoConfiguration + `game.enabled` 开关（不接任何业务先跑通宿主启动）
2. domain/engine 移植 + 单测对拍（Coins/Rank/Ruleset/Placement/Duel/Melee）
3. persistence + `db/game/*.sql`（脚本备好，**执行需用户点头**）
4. realtime + service（桌子/匹配/结算）
5. WS 接入 + api（HTTP 三接口）
6. nginx 片段 + docs 补齐"已实测/未实测"
