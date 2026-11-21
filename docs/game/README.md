# 飞机对决游戏服务端（vvv-game）文档

| 文件 | 用途 | 什么情况下必须读 |
|---|---|---|
| `design.md` | 总体设计：模块结构、协议、Redis 实时态、可靠性 | 动 `vvv-game` 代码之前 |
| `data-model.md` | `game_*` 表设计、字段语义、幂等约定 | 改表、写 Mapper、加接口之前 |
| `protocol.md` | Java 化协议（信封 + 命令/事件清单），与 Vue 旧协议的差异 | 改 WebSocket 消息、改客户端之前 |
| `api.md` | HTTP 接口清单（`/api/game/v1/**`） | 动 Controller 之前 |
| `migration.md` | 迁移脚本清单与执行顺序（真库是线上库！） | 执行任何 DDL 之前 |

## 一句话边界

`vvv-game` 是**库模块**，不是进程：由 vvv-link（8888）通过 AutoConfiguration 装载，
`game.enabled=true` 才注册任何 Bean。业务数据全部落在 `game_*` 前缀表 + Redis `game:` 前缀键，
用户身份完全复用平台 `vpn.user`（Vpn-Token → Redis token → userId），游戏账号从 userId 派生。

## 已定决策（2026-11-21，用户拍板）

| 决策 | 结论 |
|---|---|
| 协议 | **重新设计 Java 化协议**（信封 + 命令/事件，snake_case JSON），不与 Vue/TS 旧协议线级兼容；客户端后续改接 |
| 账号 | **必须用平台 userId**，游戏档案从 `vpn.user.id` 派生；登录/鉴权复用现有链路，游戏侧不做自己的账号密码 |
| 存储 | MySQL 5.6.40 做持久层（账本/档案/对局记录），Redis 做实时层（房间/匹配/在线态/游戏进程快照） |

## 端口与路由

- 不新起进程：WS 路径 `/api/game/ws`、HTTP 路径 `/api/game/v1/**`，都走 vvv-link 8888。
- nginx：`location ^~ /api/game/ws` 必须带 `proxy_http_version 1.1` + `Upgrade/Connection` 头；
  `/api/game/v1` 普通转发即可。见 `deploy/nginx/snippets-vpn-routes.conf`。
- 路径特意绕开旧的 `/**/*.json` 拦截器链，游戏侧用自己的一层 `Vpn-Token` 校验。

## 已实测 / 未实测（诚实清单，随实现更新，2026-11-22）

| 事实 | 状态 |
|---|---|
| 设计方案 | 本文档 + `ts-server-spec.md`（移植契约），未外部评审 |
| `game_*` DDL 执行 | **已执行**（2026-11-22，线上库 `vpn`）：V001+V002 共 9 张表落地，`game_schema_version` 记到 2，`game_season` 已种首季行（season_no=1, ACTIVE）。真库 `SELECT VERSION()` 实测 **MySQL 8.0.46**——此前文档按 TS 旧情报写的"5.6.40"已过时；SQL 刻意只用 5.6 子集写法，在 8.0.46 上全部一次通过（前向兼容） |
| Java 引擎与 TS 引擎逐行为对齐（同 seed 同结果） | **已对拍**：引擎 7 套件 75 测试与 vitest 36 用例逐 seed 对齐；机器人决策序列同 seed 校验通过 |
| 桌子/Hub 与 TS 行为对齐 | **已对拍**：Table 64 测试 1:1 移植 table.ts 测试、GameHub 42 测试覆盖 hub.ts 口径（门票状态机/归因门/派发序/tick 序） |
| 全模块单测 | **367/367 绿**（H2 模拟库） |
| 持久层 SQL 正确性 | H2（MODE=MySQL）绿 + **真 8.0.46 建表过**；DML（注解 SQL）真库实跑待首局对局覆盖 |
| 宿主装载 | **真机启动实测**（2026-11-22，本机 jar + local profile 连线上库）：`Started VVVLinkApplication`、`vvv-game module armed`、`/api/game/v1/health` → `{"mysql":true,"redis":true,"module":true}`。健康检查 redisAlive 的探测 bug（hasKey 查永不存在的键）就是这次实测抓出并已修的 |
| WebSocket 端到端（真握手 + 双端对局） | **握手鉴权实测**（无 token 被拒、协议未升级）；**双端对局未实测**。粗糙点：握手 401 被宿主全局异常包装成 `errno:10000` 系统错误而非 401，客户端按"连不上"处理即可，想细分要动宿主错误链 |
| 多实例水平扩展 | **未做**——桌子/引擎状态在进程内存（v1 与 TS 版一致），Redis 只放在线态/座位/索引/锁；扩容前必读 design.md 的边界说明 |
| 客户端改接新协议 | **未做**——Vue 客户端仍是 TS 旧协议线；切换客户端是上线前置工作 |

## 上线开关（本工程无 Nacos，配置全在 `vvv-link/src/main/resources/bootstrap.yml` 的 `game:` 块）

1. ~~执行 DDL~~ **已完成（2026-11-22 线上库）**；回退脚本仍在 `db/game/recovery/drop_game_objects.sql`。
2. `bootstrap.yml` 的 `game.enabled: true` **已就位**（game.* 全部可配项连同默认值与注释写在该文件里）；改值 = 改文件 + 重新打包 + 重启。
3. 自检：`curl 'https://api.ok123find.top/api/game/v1/health'` → `{"module":true,"mysql":true,"redis":true}`（本机 8888 已验过同样返回；生产要等 jar 部署 + nginx 路由同步）。
4. nginx 路由片段已备好在 `deploy/nginx/snippets-vpn-routes.conf`（/api/game/ws 带 Upgrade 头），
   按 deploy/README.md 的步骤同步到服务器。
5. 回归审计：跑 `db/game/audit_integrity_checks.sql`，六项全 0 才算稳定（2026-11-22 建表当晚已跑一遍，全绿）。
