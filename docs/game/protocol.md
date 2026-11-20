# Java 化协议（WebSocket）

> 决策：不与 Vue/TS 旧协议线级兼容。旧协议的痛点（type 字段混命令与事件、错误散在各处、
> 无版本、无回执关联）在这里一次改掉。**客户端改接前，本模块不承接线上流量。**

## 连接

- `GET /api/game/ws`，握手 HTTP 头带 `Vpn-Token`（与 HTTP 接口同一个 token，同一 Redis 校验链路）。
- 握手失败（无 token / token 失效）直接 401，不建 WS。
- 断线语义照旧：掉线不踢座位，桌子进 `paused`，重连恢复；超过宽限期由服务端判负/散桌退款。

## 信封（两个方向同一骨架）

```jsonc
// 客户端 → 服务端（命令）
{ "v": 1, "cmd": "room.create", "seq": 17, "data": { ... } }

// 服务端 → 客户端（事件 / 回执）
{ "v": 1, "evt": "table.state", "seq": 17, "ref": null, "data": { ... } }
```

- `cmd`：命令名，**动词域.**分词（`room.create` / `game.fire` / `coin.adReward`）。
- `seq`：客户端自增；服务端回执原样带 `ref=seq`，客户端据此做请求-响应关联与乐观 UI 回滚。
- 服务端主动推送 `ref=null`。
- 所有命令都有确定回执：成功 `ack`（`cmd` 同名的 `.ok`），失败统一 `error` 事件。

## 错误

`evt: "error"`，`data: { code, message }`。code 是 SCREAMING_SNAKE 稳定词表（对齐 TS ErrorCodes，语义不变）：

```
BAD_JSON BAD_SHAPE UNKNOWN_CMD NOT_AUTHED NOT_IN_ROOM ALREADY_IN_ROOM
ROOM_NOT_FOUND ROOM_FULL NOT_HOST NOT_READY PHASE_LOCKED NOT_YOUR_TURN
BAD_MOVE TICKET_DENIED BALANCE_LOW QUOTA_EXCEEDED SESSION_CLOSED
RATE_LIMITED INTERNAL
```

## 命令清单（19 条，逐条对应 TS 版）

| cmd | data 要点 | 回执 evt |
|---|---|---|
| `profile.get` | — | `profile.now` |
| `nickname.set` | nickname | `profile.now` |
| `room.create` | capacity, preset, ticket, listed | `table.state` |
| `room.join` | roomCode | `table.state` |
| `room.list` | subscribe: true/false（订阅式列表，取代 subscribe/unsubscribe 两条） | `room.list` |
| `room.rules` | rules（RuleSet 校验同 TS） | `table.state` |
| `room.ready` | ready | `table.state` |
| `room.leave` | — | `table.state` |
| `room.kick` | seat | `table.state` |
| `room.listed` | listed | `table.state` |
| `queue.join` | capacity, preset, ticket | `queue.status` |
| `queue.leave` | — | `queue.status` |
| `practice.create` | preset | `table.state` |
| `game.place` | planes（布阵，Placement 校验同 TS） | `game.planeAccepted` |
| `game.fire` | row, col | `game.shot` |
| `game.item` | itemId, row, col | `game.shot` |
| `rank.list` | — | `rank.list` |
| `coins.ledger` | — | `coins.ledger` |
| `coin.adReward` | adRef | `coins.now` |

（心跳走 WS 协议层 ping/pong，不设应用命令。）

## 服务端事件清单

`table.state`（全量桌子快照，任何桌子状态变化都推这个，客户端无脑覆盖——去掉 TS 里十余种碎片事件的合并压力）
`table.kicked` `table.closed` `queue.status` `queue.timeout` `room.list`
`phase.changed`（placing→playing→finished，带 deadlineAt）
`game.planeAccepted` `game.shot`（含双方视角：自己 shots 增量 + 对手 incoming 增量）
`game.destroyed`（某家一架飞机被击落）`game.over`（TableResult）
`player.presence`（座位在线态变化）`profile.now` `rank.changed` `rank.list` `coins.now` `coins.ledger`

## 与 TS 协议的行为不变式（移植时逐条对拍）

1. 所有权威判定在服务端；客户端只渲染事件。
2. `game.fire` 非回合/相位锁定/非法坐标 → `error: NOT_YOUR_TURN / PHASE_LOCKED / BAD_MOVE`，不断线。
3. 成局前散桌 → 门票全额 `ticket-refund`；成局后判负 → 门票不退。
4. 人机参与局：`scoring=0`，星/MMR/计分统计全不动，金币照发。
5. 匹配桶规则照搬 TS：同桶立配，跨桶每等 15s 放宽一桶（`matchRelaxGate` 直译）。
