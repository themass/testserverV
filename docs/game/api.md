# HTTP 接口（/api/game/v1/**）

沿用新模块约定：`record GameResponse<T>(int errno, T data, String error)`，HTTP 状态码表达传输层结果，
`errno` 表达业务结果（0 = 成功），不碰 legacy `JsonResult` / AES。
鉴权：请求头 `Vpn-Token`，解出 `vpn.user.id`；解不出 → 401。

| 方法 路径 | 用途 | 备注 |
|---|---|---|
| `GET /api/game/v1/profile` | 档案页首屏（profile + progress + wallet 三行单键读） | 首见用户在此建 `game_profile` 行并派生默认昵称 |
| `PUT /api/game/v1/nickname` | 改游戏昵称 | 过 nickname-blocklist（直译 TS `nickname.ts`）；不落敏感词 |
| `GET /api/game/v1/coins/ledger` | 金币明细（最近 100 条 + 余额） | 读 `game_coin_ledger` 倒序 |
| `POST /api/game/v1/coins/ad-reward` | 看广告领奖 | body `{adRef}`；幂等键 `ad:<day_key>:<序号>`，日上限 5 |
| `GET /api/game/v1/rank/list` | 段位排行榜（前 100） | `game_progress` 按 (tier, stars, wins) 反扫 |
| `GET /api/game/v1/matches/recent` | 最近对局（ProfileView.recent 的来源） | `game_match_player` ⋈ `game_match` |
| `GET /api/game/v1/health` | 自检（Redis/MySQL 连通、game.enabled） | 无鉴权，只回布尔 |

WS 命令能做的事（建房、开炮）**不**提供 HTTP 版：实时交互只有一条路，避免两份实现漂移。
HTTP 只承载"打开 App 先拉一次"的读接口与离线写（昵称、广告）。
