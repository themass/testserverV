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

## 已实测 / 未实测（诚实清单，随实现更新）

| 事实 | 状态 |
|---|---|
| 设计方案 | 本文档，未评审 |
| `game_*` DDL 在真 5.6.40 执行 | **未做**——真库即线上库，脚本备好在 `vvv-game/src/main/resources/db/game/`，执行需用户点头 |
| Java 引擎与 TS 引擎逐行为对齐（同 seed 同结果） | 计划以单测对拍实现，**未实现** |
| WebSocket 在宿主进程内跑通（repo 内首次引入 spring-boot-starter-websocket） | **未实测** |
