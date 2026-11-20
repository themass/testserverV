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

## 已实测 / 未实测（诚实清单，随实现更新，2026-11-21）

| 事实 | 状态 |
|---|---|
| 设计方案 | 本文档 + `ts-server-spec.md`（移植契约），未外部评审 |
| `game_*` DDL 在真 5.6.40 执行 | **未做**——真库即线上库，脚本备好在 `vvv-game/src/main/resources/db/game/`，执行需用户点头 |
| Java 引擎与 TS 引擎逐行为对齐（同 seed 同结果） | **已对拍**：引擎 7 套件 75 测试与 vitest 36 用例逐 seed 对齐；机器人决策序列同 seed 校验通过 |
| 持久层 SQL 正确性 | H2（MODE=MySQL）8 测试绿；**真 5.6.40 语法未过**（注解 SQL 刻意只用 5.6 子集，见 data-model.md） |
| 钱包/结算幂等路径 | 13 测试绿（H2 + 确定性 fake mapper）；**真并发下 CAS 让渡路径未在真 MySQL 复测** |
| WebSocket 在宿主进程内跑通（repo 内首次引入 spring-websocket） | **未实测**——单测只覆盖编解码/限流/鉴权逻辑，容器内握手与端到端对局需起 vvv-link 人工验 |
| 多实例水平扩展 | **未做**——桌子/引擎状态在进程内存（v1 与 TS 版一致），Redis 只放在线态/座位/索引/锁；扩容前必读 design.md 的边界说明 |
| 客户端改接新协议 | **未做**——Vue 客户端仍是 TS 旧协议线；切换客户端是上线前置工作 |
