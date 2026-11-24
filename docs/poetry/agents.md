# Agent 家族与入口（2026-11-24 实测盘点）

> 起因：域名规划只考虑了「页面 + Java API」，agent 那一层没有入口方案。
> 结论：**agent 不是一个域，也不是一条通路**——学生端那条要跟页面同源，内容生产那条
> 永远不该有公网入口。下面每一行都是探测或读代码得来的，不是设计愿望。

## 五个家族

| 家族 | 进程与端口 | 今天在线上吗 | 公网入口 | 该不该有公网入口 |
|---|---|---|---|---|
| **唐诗内容生产 agent**（`poetry-agent/content-agent`） | `agent-bff :8100`、`agent-worker :8102`、`poetry-domain-mcp :8101`、`deerflow-gateway :8001`、`redis`（compose，两张网络 internal/egress） | **没有**（8100/8101/8102/8001 在 `64.32.22.150`、`104.160.191.87` 上全部连不上，本机也没有） | 无 | **不要**。BFF 只服务 Poetry Studio（人用的写入口），compose 里 8100 只发布到 `127.0.0.1`；8101 故意不发布端口。要远端用就 SSH 隧道，不给域名 |
| **学生端讲诗 agent**（`poetry-agent/student-app/agent`，包 `student_agent`） | FastAPI，默认 `127.0.0.1:8765`，路由只有 `/agent/v1/health`、`/agent/v1/turn` | **没有**（:8765 连不上） | 计划用 `poetry.sspacee.com/agent/v1/**`（同源） | 要，但**只作为 PWA 同源的一条路径**，不单独开域。前端 `agentBase` 默认就是 `/agent/v1`，同源即零改动 |
| **companion-agent**（陪伴 / Her，独立产品） | `:8081`，跑在 `104.160.191.87` | **是**（`/health` 200） | 已生效：`api.ok123find.top/v1/**`、`/companion-health` → 实测 401（鉴权在 agent 自己，读 Java 登录态）/ 200 | 已有。`/metrics` 实测 **403**（只对内网放开，正确） |
| **job-come 的 agent**（JC，简历产品） | 内嵌在 API Python 进程里（无独立 agent 端口） | 站点在（`jc.sspacee.com` 200，应用机） | `jc.sspacee.com`（它自己的站） | 与唐诗无关，别混用 |
| **naviforge** | Chrome 扩展 + 本机 Host 进程 | 本地工具，无服务端 | 无 | 不上公网 |

`plane-duel` / `deepspace-field` / `sayagain` 没有 agent。

## 由此定的两条通路

**学生端**：`poetry.sspacee.com`（PWA）+ 同源 `/agent/v1/**`。所以讲诗 agent 上线要做的
是「进程起在应用机 + 网关那条 location 放开」，不是「申请 agent 域名」。配置已按这个写法
预留：`deploy/nginx/snippets-poetry-routes.conf` 里那段 `location ^~ /agent/v1/` 是注释状态，
放开时要同时在 nginx.conf 的 `http {}` 加 `student_agent_server` 上游。两个坑写在同一段注释里：
`:8765` 默认绑 loopback，且 `STUDENT_AGENT_AUTH` 不是 `java` 时它自己拒绝启动（跨机反代必须先配这两项）。
Java 那边 `student.agentEnabled` 只是**告诉 App 要不要试**这条通路（实测它只进 `Config` 的一个布尔字段），
不代表 Java 会代理 agent。

**内容生产**：零公网。理由就是 `docs/poetry/architecture.md` 里那条写边界——agent 只能产 DRAFT，
人审是唯一通道；给它一个公网域名只会多一个能被人从外面打的写入口。`agent-poetry.sspacee.com`
这个名已从证书脚本里删掉，不要再加回来（2026-11-24 决定）。

## companion 那条通路上的一个命名冲突（要挑一个）

仓库里有两套给 companion 写过的 nginx 段，**都只有一份能生效**：

| 来源 | 上游名 | location | 状态 |
|---|---|---|---|
| `myproject/companion-agent/scripts/nginx/ca-location.conf` | `ca_api` | `/v1/**`、`/companion-health`、`/metrics` | **实测已生效**（401 / 200 / 403） |
| 本仓库 `deploy/nginx/snippets-vpn-routes.conf` | `companion_server` | `/api/agent/v1/**`、`/companion/**` | **没放上网关**（实测这两个前缀返回 nginx 自己的 HTML 404，不是 agent 的 JSON 404） |

`/api/agent/v1` 是 companion **新聊天栈**的前缀（`serve.py`：配了 Postgres 与 Redis 才启用），
`/v1` 是旧栈——所以这不是「哪套写错了」，是**旧栈在跑、新栈还没上线**。
上线新栈时把本仓库那两段的 `proxy_pass` 改成 `ca_api`（别再造第三个上游），并确认旧栈是否还要并存。
