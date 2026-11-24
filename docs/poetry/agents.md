# 唐诗的 agent（2026-11-24）

> 唐诗这条线只有**两个** agent：一个产内容（草稿），一个在学生端讲诗。
> 别的 agent（陪伴、简历产品里的、浏览器扩展里的）跑在同一批机器上，但**不是唐诗的服务**，
> 不在本架构内——它们的路由、上游、域名不由唐诗的文档规定。此前这份文档把它们列进来过，
> 已删除。架构主体见 [`network-architecture.md`](network-architecture.md)。

## 1. 内容生产 agent（Poetry Studio 那一支）

进程与端口（`content-agent/deploy/compose.yaml`，**只在开发机跑**）：

| 服务 | 端口 | 网络 | 出网 |
|---|---|---|---|
| `agent-bff` | `:8100`（只发布到 `127.0.0.1`） | internal + egress | 是（Java Poetry API） |
| `agent-worker` | `:8102` | **仅 internal** | **否**（compose 里 `internal: true` 那张网没有默认路由） |
| `poetry-domain-mcp` | `:8101` | internal + egress | 是（Java API）；**故意不发布端口** |
| `deerflow-gateway` | `:8001` | internal + egress | 是（模型网关） |
| `redis` | — | 仅 internal | 否 |

线上状态：**没有部署**。两个公网 IP 上 `8100 / 8101 / 8102 / 8001` 实测全部连不上。

入口定案：**不给任何公网域名**（`agent-poetry.sspacee.com` 已从证书脚本删除，别加回来）。
理由不是「还没起进程」，而是写边界本身——它只能通过 Java 的 DRAFT 通道写，人审是唯一出路；
给它一个公网入口等于多一个可被打的写侧大门。远端要用 Poetry Studio 就走 SSH 隧道到 `:8100`。

它调 Java 用的路由（实测存在的形状，`PoetryAgentController` / `PoetryStudioRead/WriteController`）：

```
GET  /api/poetry/v1/works/{id}/snapshot                 只读上下文
GET  /api/poetry/v1/works/{id}/integrity-gap-report     缺口报告
POST /api/poetry/v1/draft/proposals                     产 DRAFT 候选（唯一写口）
POST /api/poetry/v1/draft/proposals/{id}/reviews        人复核
POST /api/poetry/v1/draft/proposals/{id}/apply          人批准后才落库
POST /api/poetry/v1/works/{id}/compile-requests         请求编译 bundle
```

令牌切分（compose 注释即权威）：`worker` **不持** `POETRY_DOMAIN_REVIEW_TOKEN`——
agent 不能批准自己的提案。Java 侧对应 `poetry.agentInternalToken` /
`poetry.studioReviewerToken`，头名 `X-Poetry-Agent-Internal-Token` /
`X-Poetry-Studio-Reviewer-Token`。实测未配令牌时 Java 明确关闭：`snapshot` → `403 REJECTED
agent domain API disabled`。

## 2. 学生端讲诗 agent（`student_agent`）

FastAPI，默认 `127.0.0.1:8765`，**只有两条路由**：`GET /agent/v1/health`、`POST /agent/v1/turn`。
线上状态：**没有进程**（`:8765` 实测连不上）。

入口定案：**只作为 `poetry.sspacee.com` 同源的一条路径** `/agent/v1/**`，不单独开域。
前端 `platform.js` 的 `agentBase` 默认就是 `/agent/v1`，同源即零改动。
nginx 那段 location 在 `deploy/nginx/snippets-poetry-routes.conf` 里预留成注释，放开时有两个坑：

1. `:8765` 默认绑 loopback——跨机反代要先改 `STUDENT_AGENT_HOST`；
2. 绑了非 loopback 而 `STUDENT_AGENT_AUTH` 不是 `java` 时，它**自己拒绝启动**
   （`config.py` 里的断言），不是静默裸奔。这条设计是对的，别绕过。

它与内容底座的关系是**只读已发布**：没有任何写底座能力、不读 DRAFT、只消费编译好的
Scene Bundle。Java 侧的 `student.agentEnabled` 只是**告诉 App 要不要试**这条通路
（实测它只进 `Config` 的一个布尔字段），不代表 Java 会代理 agent——别指望它做鉴权。

## 为什么两条通路不一样

内容生产 agent 的产物会进底座，所以它离公网越远越好；讲诗 agent 的产物只进一个学生的屏幕,
所以它跟页面同源、走 PWA 那一个域名就够。两者的共同点只有一条：**都不直接碰 MySQL**——
读和写都经过 Java，发布闸门因此对两个 agent 同时生效。
