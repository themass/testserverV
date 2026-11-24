# 底座 · 应用 · Agent 架构

正式图：`architecture.html`（浏览器直接打开，含读路径 / 写路径 / 自检与守护 三个视角）。
可编辑源：`architecture.json`。

## 图的文字版

```
读路径（学生能看到的一切）
  学生 → 应用层 → 只读 API(/api/poetry/v1) → 内容底座
                                              ↑
                                        发布闸门（人审 + 来源已核查 + 演绎已标识）
                                              ↑
                                        录入与复核 ← 草稿区 ← Agent（未来）
                                              
运维旁路：核查 SQL（106 项）→ 底座：改数据后必须全 0
Agent 另有一条只读边：可读底座作上下文，不可写库

自检与守护（第三个视角）
  只读 API  ← 访问日志 + 每客户端限流（PoetryAccessGuard，进程内）
  自检（PoetrySelfCheck） -.探活.-> 底座        （表不存在 / schema 版本过旧 → 告警，不改数据）
  自检 -.词表比对.-> 核查 SQL                  （Vocabulary.java 与 C7 词表漂移 → 告警）
```

## 三条边界（与图对应）

| 边界 | 含义 | 现在靠什么保证 |
|---|---|---|
| 读边界 | 只有满足发布闸门的内容能被读到；草稿、未核查来源、未标识演绎一律不可见 | `PoetrySql` 每条 SELECT 复查（fail closed，已实测） |
| 写边界 | 人工与 Agent 一律先产 DRAFT，发布必须过人审 + 106 项核查 | 约定 + `audit_integrity_checks.sql`（**尚无代码强制**，见 `code-layers.md` 第 1、7 项） |
| Agent 边界 | Agent 可读不可写；产出必须标注 `DRAMATIZATION` 或 `INTERPRETATION`，不得伪装史实 | 目前只是设计约定，未实现 |

## 为什么 Agent 不能直接写库

产品的核心资产是"有依据的内容"。Agent 一旦直接写入已发布内容，就会出现：无出处的史实、把演绎当事实、把一般时代背景当作确定创作动机。这三条正是项目明确的反目标。因此 Agent 的正确位置是**草稿生产者**，人审是它进入底座的唯一通道。

## 这张图对应到代码（2026-11-06 现状）

| 图中节点 | 现在是什么 | 状态 |
|---|---|---|
| 内容底座 | `db/poetry/V001` + `V003`（26 张表，无外键） | 已在 H2 跑通，未在真 MySQL 执行 |
| 草稿区 | `V002` + `V004`（《春望》最小闭环，全 DRAFT） | 已在库，接口读不到（已实测 SQL 层） |
| 发布闸门 | `PoetrySql` 读侧复查 + `review-checklist.md` 人工步骤 | 读侧强制；写侧仍是人 + SQL |
| 核查 SQL | `audit_integrity_checks.sql` 106 项 | 已实测（草稿全 0；演练库 5 项非 0） |
| 自检与词表 | `PoetrySelfCheck` + `Vocabulary` | 已实现（fail-soft，只告警） |
| 限流与日志 | `PoetryAccessGuard` | 已实现（单实例，非分布式） |
| Agent | 无代码 | 明确未实现；底座已为它留出草稿区与 claim 词表。**2026-11-24 补**：仓库里已有五个 agent 家族（内容生产、学生端讲诗、companion、job-come、naviforge），端口/在线状态/入口定案见 `agents.md`；这张图说的「Agent」= 内容生产那一支，它对 Java 只有一条边：**读已发布 + 写 DRAFT**，没有公网入口 |

## 进程与装配（2026-11-24 补：这一层此前没写进架构文档）

唐诗的 Java 侧只有**一个进程**：`vvv-link` jar（`bootstrap.yml: port 8888`）。
poetry 与 student 不是独立服务、没有独立端口，而是同一个 jar 里靠
`@ConditionalOnProperty` 装载的两个模块——**开关不在 yml 里，模块就整个不存在**，
请求落到宿主兜底（实测 `errno:10000`），不是 404、更不是崩。

| 模块 | 开关 | 对外路由 | 关键件 |
|---|---|---|---|
| `vvv-poetry` | `poetry.enabled` | `/api/poetry/v1/**`（读 + review/publish） | `PoetrySql`（读侧复查 fail closed）、`AuditRunner`（106 项）、`PoetrySelfCheck`、`PoetryAccessGuard` |
| `vvv-student` | `student.enabled` | `/api/student/v1/**` + `/app/` + `/assets/` | `StudentContentController`（config/timeline/overview/works/{id}/lesson/pack/bundles/claims·citations/assets·chain）、`StudentDeviceController`、`StudentSqlGuard`、`StudentCorsFilter`（白名单 origin，Bearer 非 cookie 故不放 credentials）、`StudentAccessGuard`、`BundleStore`、`StudentStaticResources` |
| `vvv-game` / `vvv-roles` / 旧 vpn 业务 | 各自开关 | `/vvv/api/**` | 同 jar，与唐诗互不干扰（旧拦截器只匹配 `/**/*.json`，`@MapperScan` 只扫 `com.timeline.vpn.dao.db`） |

student 层的读边界：**它不另开一条写口**——`ContentService` 的构造参数里就有
`PoetryCatalog`，读的还是同一个内容底座，因此发布闸门对两个模块同时生效；
student 自己只加设备登记、bundle 缓存与限流。

装配开关必须在**服务器上**加（`bootstrap-*.yml` 被 `.gitignore` 排除，含库口令，
不随 jar 走）——这是「代码没错但线上没装配」这类现象的唯一根因，见 `deploy/README.md`。

## 一个已知缺口：宿主的通配 CORS（2026-11-24 实测）

`vvv-link` 里有个 `MyCorsFilter`：`addAllowedOriginPattern("*")` +
`allowCredentials(true)`，注册在 `/**`。实测带任意 `Origin` 请求现网
`/vvv/api/poetry/v1/**` 会拿到 `Access-Control-Allow-Origin: <该 Origin>`
+ `Access-Control-Allow-Credentials: true`。两个后果：

1. `StudentCorsFilter` 的白名单在跨域上实际**不起决定作用**（宿主过滤器在前、且已应答预检）；
   唐诗读接口本无 cookie 会话，所以现在没有数据泄漏，但**写侧（review/publish）也在 `/**` 范围内**，
   靠的只是 token 头，不是 CORS。
2. ~~「poetry.sspacee.com 静态 + api 单独一个域」这个拓扑要成立，前端跨域就必须真受白名单管~~
   —— 2026-11-24 拓扑改定为 **PWA 与 API 同源**（都在网关 `poetry.sspacee.com`），
   唐诗这条不再触发跨域，此缺口**不是上线阻塞项**；但它对旧业务（vpn/chat/game 的写侧）依然成立，
   仍要修。

修法（未做，等排期）：把 `MyCorsFilter` 的注册范围收到旧业务前缀（如 `/vvv/api/**` 里
除 poetry/student 之外的部分），或按前缀分别注册；改完必须重新实测两个 origin 的预检行为。
