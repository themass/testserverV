# 唐诗产品自己的网络架构（2026-11-24 实测）

> 只写唐诗这条线的进程、端口、域名、边界。别人的产品（陪伴 / 简历 / 浏览器 agent 等）
> 不在本架构内——它们跑在同一批机器上，但**不是唐诗的服务**，写架构时不要把它们算进来。
> agent 那一层的定案单独在 [`agents.md`](agents.md)。

## 三台机器（此前文档只写了两台，这是错的）

| 角色 | 地址 | 与唐诗有关的东西 | 证据（2026-11-24 只读探测） |
|---|---|---|---|
| **应用机** | `64.32.22.150` == `104.160.191.87`（**一台机两个公网 IP**） | **`vvv-link` jar :8888** —— 唐诗唯一的 Java 进程（内含 `vvv-poetry` / `vvv-student` 两个模块）；jar 的静态资源目录 | 两个 IP 的 `:8888/api/poetry/v1/coverage` 响应**逐字节一致**；443 上 `jc` 与 `sspacee.com` 两张证书序列号相同。该机 80 端口的默认 vhost 是**别人的简历站**（`<title>免费 AI 简历优化…`），不是唐诗 |
| **网关** | `8.217.122.83` | nginx 1.24.0；唐诗今天的**唯一公网入口**（`/vvv/api/poetry/v1/**`）；唐诗 PWA 定案落在这里 | `:80` → `404`（无默认页）、`:443` 默认证书 `CN=api.ok123find.top`，SAN = `api.ok123find / api.ok124find / book.ok123find / file.ok123find`。**共享机**：同一 vhost 还挂着 `/BookManager`（实测 502）、`/file/`（200）等别人的路由 |
| **库机** | `47.82.163.162` ← `mysql.sspacee.com` | **唐诗的内容底座**：`mysql.sspacee.com:6666/vpn`，`poetry_*` 表 | `dig @8.8.8.8 mysql.sspacee.com` → `47.82.163.162`，**与上面两台都不是同一台**；`:6666` 可连，MySQL 握手横幅 `protocol_version=10 server_version=8.0.46-0ubuntu0.24.04.5`。该机另有 openresty（`:80`→403、`:443` 自签 `CN=47.82.163.162`）——所以它也是共享机，不要按「唐诗的 DB 专用机」规划 |

> 我此前所有唐诗文档只描述「网关 + 应用机」两台，**库机这一跳从来没写进去**。
> 后果不是排版问题：跨机防火墙、备份、迁移执行位置、连接串该放哪台，全都挂在这跳上。

## 进程清单：唐诗只有 1 个进程在线上

| 进程 | 端口 | 在哪 | 状态 |
|---|---|---|---|
| `vvv-link` jar | `:8888` | 应用机 | **在**（systemd 托管，见 `docs/game/deploy.md` 同一约定） |
| └ `vvv-poetry` 模块 | 同上 | 同上 | **已装配**（`coverage` 200） |
| └ `vvv-student` 模块 | 同上 | 同上 | **未装配**（`student.enabled` 不在服务器 yml）→ 该路径落宿主兜底 |
| 讲诗 agent（`student_agent`） | `:8765` | 未在服务器 | **没有进程**（实测连不上）；上线后只作为 PWA 同源 `/agent/v1/**` |
| 内容生产 agent（bff/worker/domain-mcp/deerflow-gateway/redis） | `:8100/:8102/:8101/:8001` | 只在开发机 compose | **没有在服务器部署**（四个端口在两个公网 IP 上全部连不上）；**永久不给公网入口** |
| PWA 静态产物 | — | 未上传 | 网关的 `/home/file/poetry/current/dist` 还没东西（vhost 也还没放） |
| 场景 bundle / 素材 | — | 应用机磁盘（`student.bundle.root` / `student.asset.root`） | bundle 未配置 → `BundleStore` 明确 503（代码里 `Unavailable`） |

没有别的进程。唐诗不需要 Redis、不需要独立 API 进程、不需要第二台应用机——
这两件事在架构上是**有意**的（模块不是服务，见 `architecture.md`「进程与装配」）。

## 通路：今天实际能走的，和目标态

| 通路 | 实测 | 说明 |
|---|---|---|
| `https://api.ok123find.top/vvv/api/poetry/v1/coverage` | `200`，与 `:8888` 直连**逐字节一致** | 网关 → `vpn_server` 上游 → 应用机 jar。**今天唯一的公网 API**。`/vvv` 前缀是网关 location 的形状（rewrite 剥掉），jar 自己没有 context-path |
| `http://64.32.22.150:8888/api/poetry/v1/**`（及 `104.160.191.87`） | `200` | **明文、公网、无白名单**——见下面「我的两个暴露问题」 |
| `https://poetry.sspacee.com/**` | 80 `404`、443 握手失败 | DNS 已到网关（三家公共 resolver 一致），vhost 与 SAN 都还没做 |
| `https://api.sspacee.com/**` | 同上 | DNS 已到网关，`vpn.conf` 的 `server_name` 已加该名但**还没放上网关** |

## 读边界与写边界的实测形状（无 token）

| 请求 | 实测响应 | 含义 |
|---|---|---|
| `GET /api/poetry/v1/coverage` | `200 errno:0`，有 cov-* 行 | 读侧装配、数据在库 |
| `GET /api/poetry/v1/content` | `200 errno:0`，`items:[]` | **发布闸门**（127 首全 DRAFT），不是故障 |
| `GET /api/poetry/v1/review/audit` | `503` `review side disabled: configure a token (poetry.authorToken / poetry.reviewToken)` | 写侧没配令牌 → 明确关闭（fail closed，符合设计） |
| `GET /api/poetry/v1/works/{id}/snapshot` | `403 {"status":"REJECTED", … "agent domain API disabled: configure poetry.agentInternalToken"}` | agent 域 API 没配令牌 → 关闭 |
| `POST /api/poetry/v1/review/content/{id}/publish` | `200 errno:10000`（通用错误） | 请求**到达了 Spring**（不是 404），被拒；失败原因被宿主 advice 掩盖成通用错误。带假 token 也是同一个响应，所以**端到端鉴权必须用真 token 才能验**——别把这个 10000 读成「接口不存在」 |

令牌开关共 5 个，全在服务器上配（`bootstrap-*.yml` 被 gitignore，不随 jar 走）：
`poetry.reviewToken`、`poetry.authorToken`（默认继承 reviewToken）、`poetry.studioReviewerToken`、
`poetry.agentInternalToken`、以及 student 侧的 `student.internalToken`。
对应头名实测在代码里：`X-Poetry-Review-Token`、`X-Poetry-Draft-Token`、
`X-Poetry-Studio-Reviewer-Token`、`X-Poetry-Agent-Internal-Token`（+ `…-Run-Id` / `…-Role` / `…-Mandate-Id`）。

## 我自己的两个暴露问题（不是别人的，是我这条线的）

1. **`:8888` 明文直挂公网**。两个公网 IP 上 `:8888` 都可直接访问，没有 TLS、没有来源限制。
   所有读接口今天就这么暴露；将来 `poetry.reviewToken` 配上之后，**写侧也会从这里绕开网关暴露**
   ——网关上的 location、限流、CORS 白名单全部旁路。
   修法（你执行）：安全组/iptables 把 `:8888` 收成只允许 `8.217.122.83` 与本机回环。
   这是这条线**最该先补**的一项，因为它比 CORS 通配那条更直接。
2. **网关是共享机，唐诗的路由与别人的路由在同一个 vhost 同一个 snippet 里**。
   一次 `nginx -t && reload` 影响 vpn/chat/book/file 全部产品；改唐诗时不能只想着唐诗。
   （这也是为什么 `deploy/README.md` 里每步都要求先备份、先 `-t`。）

顺带一个不是我的、但会影响我读别人响应的判断：网关上 `/BookManager` 实测 **502**——
那是别人家的上游挂了/没起，**别把它当成唐诗通路有问题**的证据。

## 数据库事实纠正（我自己的文档写错过）

- 连接点：`mysql.sspacee.com:6666`，库 `vpn`（与宿主应用**同库**，靠 `poetry_` 前缀隔离），
  `local` 与 `prod` 两个 profile **完全相同** → 跑迁移就是跑在线上库。
- **版本**：今天握手横幅是 **`8.0.46-0ubuntu0.24.04.5`**。我文档里长期写的「MySQL 5.6.40」
  是 **2026-11-06 迁移当时**的事实（V007 把 `idempotency_key` 限到 128 字符，正是因为 5.6 的
  767 字节索引上限——那条限制当时真实存在），`docs/game/` 已在 2026-11-22 实测出 8.0.46。
- 对 emit 流水线的影响：**没有**。SQL 仍按 5.6 子集写（无 CTE、无 JSON、字面量禁反斜杠）是
  **前向兼容**的选择，在 8.0.46 上一次通过。但文档里「因为服务器是 5.6」这个理由已经不成立，
  写清楚是「刻意只用 5.6 子集，为了两版都能跑」。
