# `vvv-poetry` 代码分层与遗漏清单

## 1. 现状分层（实测，非设计意图）

| 层 | 位置 | 内容 | 依赖方向 |
|---|---|---|---|
| 接口 | `api/PoetryController.java` | 16 个 GET，统一 `/api/poetry/v1`（新增 `/coverage`、`/themes/{id}/items`）；异常→400/404 | → service |
| 契约 | `api/PoetryModels.java` | 15 个 record（+Coverage、+ThemeItem；Background 改 bodyText/audience），含独立 `Response{errno,data,error}` | 无依赖 |
| 服务 | `service/PoetryCatalog.java` | 参数校验、类型白名单、分页、存在性检查 | → persistence, domain |
| 持久 | `persistence/PoetryMapper.java` | 注解 SQL，读侧发布闸门 | → PoetrySql |
| 规则常量 | `persistence/PoetrySql.java` | `PUBLIC_CONTENT / PUBLIC_CLAIM / PUBLIC_VERSION / VERIFIED_SOURCE` | 无依赖 |
| 领域 | `domain/TimeSpan.java`、`domain/PublicationGate.java` | 时间合法性、发布前置条件 | 无依赖 |
| 装配 | `config/PoetryAutoConfiguration.java` | `poetry.enabled=true` 才装配；复用宿主 SqlSessionFactory；不跑迁移 | → 以上全部 |
| 词表 | `domain/Vocabulary.java` | Java 侧枚举唯一定义；启动自检与 classpath 上的核查 SQL 比对 | → 无 |
| 自检 | `service/PoetrySelfCheck.java` | 表可达性、schema 版本、词表漂移；只报告不抛异常 | → persistence |
| 写侧 | `service/PoetryReviewService.java`、`service/AuditRunner.java`、`persistence/PoetryWriter.java`、`api/PoetryReviewController.java` | 发布/撤回/留痕；发布前后各跑一次核查，脏则回滚；无 token 一律 503 | → persistence, domain |
| 运维 | `api/PoetryAccessGuard.java` | 每请求一行日志 + 每客户端每分钟计数（默认 300，超出 429） | → servlet |
| 资源 | `db/poetry/`：`V001` / `V003` / `V002` / `V004` / `audit_integrity_checks.sql`（106 项）/ `demo_publish_chunwang.sql` / `drop_poetry_objects.sql` | 建表 → 加固 → 草稿种子 → 春望草稿闭环 / 核查 / 闸门演练 / 回退 | 手工执行 |

宿主接线：根 `pom.xml` 与 `vvv-link/pom.xml` 已加依赖；旧拦截器只匹配 `/**/*.json`，`@MapperScan` 只扫 `com.timeline.vpn.dao.db` → 新模块与旧业务互不干扰。

## 2. 遗漏清单（按严重度，含"现在做/推迟"判断）

| # | 遗漏 | 事实依据 | 影响 | 决定 |
|---|---|---|---|---|
| 1 | ~~`PublicationGate` 无调用点~~ **已闭合**：`PoetryReviewService.publish()` 调它，且发布前后各跑一次 106 项核查，不干净就回滚 | | grep 全模块：只有它自己的测试引用 | 发布规则存在**两处独立表达**：Java 的 `problems()` 与 SQL 的 `PUBLIC_CLAIM`。两者会漂移，而 Java 那份实际不生效 | **现在做**：要么删掉并承认"闸门只在读侧"，要么引入写入/审核服务统一调用 |
| 2 | **`TimeSpan` 只用于校验查询参数**，不校验库里的年代 | `PoetryCatalog` 第 40 行是唯一生产调用 | 库里可存 `EXACT 757→758` 这类非法年代 | **现在做**：核查 SQL 已能抓（C6 已实测抓到），把它列为发布前必查即可，不必加触发器 |
| 3 | ~~无启动自检~~ **已做**：`PoetrySelfCheck`（表可达 / schema 版本 / 词表漂移，fail-soft） | 没有 schema/表存在性检查 | 未迁移就开 `poetry.enabled=true` → 接口 500，排查成本高 | **现在做**：加 `PoetrySchemaGuard`（查 `poetry_schema_version` 是否匹配），不匹配则拒绝启用模块并打明确日志 |
| 4 | **日志已做（`PoetryAccessGuard` 每请求一行），指标仍无** | 模块内无 logger；management 只暴露 prometheus | 已发布内容因来源核查回退而**静默消失**，无人知晓 | **现在做**（最小）：访问日志 + "关键接口返回 0 条"计数 |
| 5 | **无鉴权（有意）+ 已加进程内最小限流**；多实例时网关层再设 | 拦截器只匹配 `*.json`，新路径不在其中 | 读的是已发布内容，风险可接受；但无任何限流与来源审计 | **推迟到有真实流量**；本轮只需加最小限流并记录 |
| 6 | **Mapper 直接返回 API record**（持久层与对外契约耦合） | `PoetryMapper` 返回 `PoetryModels.*` | 将来加缓存/拆库要改一遍映射 | **接受**：现阶段少一层样板，属有意取舍；写进文档防止后人再加一层 |
| 7 | ~~无写入/审核服务入口~~ **已做最小闭环**：状态转移 + 核查 + 留痕；仍**不创建内容**（录入还是受控 SQL） | 只有读接口 | 录数据靠手工 SQL，符合当前阶段（内容少、必须人审） | **推迟**：但文档必须写死"录入=受控 SQL"，否则将来做 CMS 会绕过所有约定 |
| 8 | ~~无回滚脚本~~ **已做**：`drop_poetry_objects.sql`（26 张表，含顺序说明） | 脚本靠手工执行；无 drop 清单 | 误执行或需要回退时没有标准动作 | **现在做**：补 `drop_poetry_objects.sql` + 执行前检查清单（MySQL 版本、InnoDB、字符集、备份） |
| 9 | ~~配置项只有 `poetry.enabled`~~ **已加** `poetry.reviewToken`（不配=写侧 503）、`poetry.rateLimitPerMinute` | 无法控制分页上限、schema 版本要求 | **推迟** |
| 10 | **测试缺口**：核查 SQL 仍未纳入回归（但已在**真 MySQL 5.6.40** 手工执行通过：106 项全 0） | 现有 4 个测试类不含 audit 文件；`TRIM`、`LIMIT/OFFSET`、`utf8mb4_bin` 排序未在真实 MySQL 验证 | 核查文件写错不会被发现（本轮已手工用 H2 跑通一次） | **现在做**：加一个测试读取 `audit_integrity_checks.sql` 并断言全部返回 0 |
| 11 | ~~覆盖声明硬编码~~ **已做**：读 `poetry_coverage`；Java 只保留一句产品声明 | `PoetryCatalog.timeline()` | 覆盖范围无法随数据变化 | **现在做**：改为读覆盖元数据（见 `data-model.md` 缺口） |

## 3. 本轮（V003 + 词表 + 自检 + 限流）之后仍然欠的

| 优先级 | 欠什么 | 什么时候必须补 |
|---|---|---|
| P0 | 写侧/审核服务（`PublicationGate` 目前只是预flight，不生效） | 开始批量录数据之前 |
| P1 | 指标：已发布内容数量、每接口返回 0 条的计数 | 第一次有真实流量之前 |
| P1 | 注释/意象读接口（`annotation` 已有数据但无出口） | 做"读懂一首诗"体验层之前 |
| P1 | 写侧只改状态，不创建内容；草稿录入仍是手工 SQL | 内容量超过几十条之前 |
| P1 | 写侧无并发保护（两人同时发布同一行） | 多人同时审核之前 |
| P2 | 多实例限流（网关层）、缓存、按学段过滤查询参数 | 上线多实例之前 |
| P2 | **PageHelper 与 poetry 查询的拦截链实测**（只读探针绕过了宿主 MyBatis 配置，未覆盖） | 启动宿主进程之前 |
| P2 | HTTP 层（Controller + `PoetryAccessGuard`）尚未跑通：未启动宿主进程 | 启动宿主进程之前 |
| P1 | `authorship` 缺 `poetry_claim_selection`，接口里 `selected=false`（V002 种子遗漏） | 数据 A2 处理 |

## 4. 一句话结论

读侧（查询与闸门）已经成型且经过实测；**写侧与运维侧（审核入口、自检、日志、回滚）几乎空白**。底座要"牢"，下一轮补的重点不在接口，而在：让规则的唯一定义处生效、让内容消失可见、让脚本可回退。


## 2026-11-06 写侧补齐记录

- `PoetryDraftService`（slice1）+ `PoetryTextService`（slice2）+ `PoetryDraftWriter2`：基础信息表增删改查全部落在写侧，仍然 0 外键、0 DELETE。
- `PoetryGuards` 统一 token 语义；`PoetryAuthoringAdvice` 把 Invalid/Dirty 变成 400/409。
- `PoetryAutoConfiguration` 不再同时用 `@Import` 和 `@Bean` 注册 `PoetryDraftController`（会造成 Ambiguous mapping）。
- 实测证据：`/tmp/poetry_crud/out2.txt`（PASS=32/FAIL=0）、`/tmp/poetry_crud/out4.txt`（PASS=40/FAIL=0），
  两者都在同一连接内跑 106 项核查、最后回滚，回滚后逐表确认 `zzs%`/`zzp%` 0 残留。
- 仍未做：并发保护（`revision` 未参与 WHERE）、注释读接口之外的一致性接口、HTTP 层冒烟（用户暂缓）。
