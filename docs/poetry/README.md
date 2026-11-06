# 诗词内容底座文档

| 文件 | 用途 | 什么情况下必须读 |
|---|---|---|
| `architecture.html` | 一张图说清底座 / 应用 / Agent 的边界（可直接浏览器打开） | 任何人想搞清"数据从哪来、谁能写、学生能看到什么" |
| `architecture.json` | 上述图的可编辑源（Archify 规格） | 要改图时，改这里再重新生成 |
| `data-model.md` | 实体关系、字段语义、枚举词表、约定、全面性缺口 | 录数据、改表、加接口之前 |
| `code-layers.md` | 代码分层现状与遗漏清单 | 动 `vvv-poetry` 代码之前 |
| `content-entry-template.md` | 录入模板：顺序、SQL 骨架、硬性要求 | 录任何一条数据之前 |
| `source-register-template.md` | 来源登记与"什么才算核查过" | 动 `poetry_source` / `poetry_citation` 之前 |
| `review-checklist.md` | 发布前清单（机器项 + 人的判断） | 把任何内容改成 PUBLISHED 之前 |
| `data-backlog.md` | 首批数据待办（到《春望》上线为止） | 决定"下一步录什么"时 |

## 迁移与核查：唯一正确顺序（2026-11-06 已在真库执行）

**先看清是哪台库**：宿主 `local` 与 `prod` 两个 profile 的 datasource **完全相同**（`mysql.sspacee.com:6666/vpn`，MySQL 5.6.40）。
也就是说：跑迁移就是跑在那台线上库上。它现在已经有 26 张 `poetry_` 表，**全 DRAFT、无任何内容可见**；
该账号没有建库权限，所以不可能另起 dev 库——只能前缀隔离 + 备份 + 可回退。

```bash
# 0) 只碰 poetry_* ；先做结构备份（mysqldump 的 8.x 客户端对 5.6 会报 generation_expression，用 SHOW CREATE TABLE 兜）
# 1) 结构 → 加固 → 草稿种子 → 春望草稿闭环
mysql --default-character-set=utf8mb4 < V001__foundation.sql     # 已于 11-06 00:33 执行
mysql --default-character-set=utf8mb4 < V003__integrity.sql      # 已于 11-06 14:14 执行
mysql --default-character-set=utf8mb4 < V002__draft_seed.sql     # 已于 11-06 14:14 执行
mysql --default-character-set=utf8mb4 < V004__chunwang_context_draft.sql
mysql --default-character-set=utf8mb4 < V006__media_and_script.sql   # 已于 11-06 15:44 执行（新增 3 表）
# 2) 核查：106 项，真库实测全 0
mysql --default-character-set=utf8mb4 -N -B < audit_integrity_checks.sql | awk -F'\t' '$2!=0'
# 3) 读闸门探针（就是接口真正跑的 SQL）
mysql -N -B < gate_probe.sql
# 4) 回退 / 清理
mysql --default-character-set=utf8mb4 < revert_demo_publish.sql   # 撤回演练发布
mysql --default-character-set=utf8mb4 < reset_all_to_draft.sql    # 紧急：全库回到 DRAFT
mysql --default-character-set=utf8mb4 < drop_poetry_objects.sql   # 清空所有 poetry 表
```

## 闸门演练（不是内容质量证据）

```bash
mysql dev_db < vvv-poetry/src/main/resources/db/poetry/demo_publish_chunwang.sql
```
作用：证明发布闸门真的会放行"依据齐全"的内容、挡住草稿。验收 =
`GET /api/poetry/v1/versions/text-chun-wang-draft/lines` 返回 8 句；未发布的背景仍 404。
**演练之后核查必然非 0**（DEMO 来源、占位 locator、缺年代采用说），这是设计出来的报警，
用来证明"假核查骗不过底座"。演练库的数不能当内容质量结论。

## 已实测 / 未实测（诚实清单，2026-11-06）

| 事实 | 状态 |
|---|---|
| V001/V002/V003/V004 在真 MySQL **5.6.40** 全部执行成功；29 张表、中文无损（V006 后含 poetry_asset / poetry_script / poetry_script_asset） | **已实测（真库）** |
| 106 项核查在真库：草稿态全 0 | **已实测** |
| 演练发布后 5 个核查项非 0（未核查来源被发布 2、缺已采用年代说 1、发布无审核轨迹 2、占位/演练 locator 2、DEMO 来源 1） | **已实测** |
| 撤回演练后：读闸门全部 0 条、核查回到全 0 | **已实测** |
| 真 MyBatis + 真库映射（record 位置映射、snake_case、`TRIM`、`LIKE`、UNION ALL）：八句 / 作者 / coverage / claims / citations 全部读通 | **已实测**（只读探针） |
| `mysqldump`（8.x 客户端）备份 5.6 失败 → 改用 `SHOW CREATE TABLE` 结构备份 | 已知坑，已处理 |
| 探针曾把模拟发布**提交**进真库（JDBC 自动提交，非预期）→ 已用 `reset_all_to_draft.sql` 全量撤回，复核全 0 | 事故已清理，并因此新增该脚本 |
| PageHelper 拦截链、Controller、`PoetryAccessGuard`（HTTP 层） | **未实测**：需要启动宿主进程 |
| 起宿主进程 curl 新接口 | **未做**：`poetry.enabled` 未在任何 yml；且 local=prod 同库，启动会影响线上数据 |

## 写侧（审核/发布）默认关闭

```yaml
poetry:
  enabled: true
  reviewToken: "<自己生成，不要提交进仓库>"   # 不配置 = 写侧全部 503
```

| 端点 | 作用 | 拒绝条件 |
|---|---|---|
| `POST /api/poetry/v1/review/{type}/{id}/publish` | 把 content / claim / text_version / source 置为已发布（source→VERIFIED） | 审核人缺失或为 `DEMO*`/`LIVE-PROBE`/`system`；本体闸门不过；106 项核查非 0 |
| `POST /api/poetry/v1/review/{type}/{id}/retract` | 撤回（`RETRACTED` / source→REJECTED） | 同上（审核人） |
| `POST /api/poetry/v1/review/log/{type}` | 追加审核记录 | `decision` 越出词表 |
| `GET /api/poetry/v1/review/audit` | 跑核查，返回非 0 项 | 无 token → 503/401 |
| `GET /api/poetry/v1/review/status` | 已发布数、已核查来源数、核查非 0 项 | 同上 |

关键保证：`publish` 会**跑两遍核查**——写之前一遍（不过就 409），写之后一遍；
只要结果不干净就抛异常**整笔回滚**。所以通过这个接口**不可能**把库留在"核查非 0"的状态。
它只改状态，不创建内容：内容仍然只能由受控 SQL 录入（见 `content-entry-template.md`）。



1. **学生可见的一切只能走 `/api/poetry/v1` 只读接口**，且只有满足发布闸门的内容才会出现（fail closed）。
2. **人和 Agent 都只能产出 `DRAFT`**。进入已发布状态的唯一通道是：人工审核 + `audit_integrity_checks.sql` 全 0。
3. **Agent 不得写库**。它可以读底座作为上下文，产出必须落到草稿区，由人审决定采用与否。

## 重新生成架构图

```bash
cd ~/.agents/skills/archify
node bin/archify.mjs deliver architecture <spec.json> architecture.html --quality showcase --json
```


## 写侧接口（2026-11-06 实测，全部在真库事务内回滚验证）

Token：读侧 `/api/poetry/v1/**` 公开（有 `PoetryAccessGuard` 每分钟计数）；
写侧与草稿侧必须带 header：

| 前缀 | Header | 取配置 |
|---|---|---|
| `/api/poetry/v1/review/**` | `X-Poetry-Review-Token` | `poetry.reviewToken`（未配置 → 503，错 → 401） |
| `/api/poetry/v1/draft/**` | `X-Poetry-Draft-Token` | `poetry.authorToken`，缺省回落到 `poetry.reviewToken` |

**没有 DELETE**：撤回 = `POST /review/{type}/{id}/retract`（删父行会制造 106 项核查要找的孤儿）。

slice1（已验证 PASS=32/FAIL=0）：
`POST/PUT /draft/content[/{id}]`、`/draft/source[/{id}]`、`/draft/claim[/{id}]`、
`/draft/citation`、`/draft/adopt`、`/draft/coverage`，读：`GET /draft/content`、`/draft/content/{id}[/claims|/selections]`、
`/draft/claim/{id}/citations`、`/draft/source`、`/draft/coverage`。

slice2（已验证 PASS=40/FAIL=0）：
`POST/PUT /draft/version[/{id}]`、`GET /draft/versions?work=`、`POST /draft/version/{id}/lines`（**只许追加**：`line_seq` 跳号会被拒，因为 `C4_text_line_seq_gap`）、
`PUT /draft/line`、`POST/PUT /draft/background[/{id}]`（content 行 + claim + background 行**一笔事务**创建，因为 `background.claim_id NOT NULL` 且 claim 的 subject 必须是背景自己）、
`GET /draft/backgrounds?work=`、`POST /draft/background/{id}/lines`（背景↔诗句绑定，跨作品会被拒）、`GET /draft/background/{id}/lines`、
`POST /draft/annotation`、`GET /draft/annotations?version=`、`POST /draft/relation`、`GET /draft/relations?subject=`、
`POST /draft/work-author`（依据 claim 必须 `property_key='authorship'` 且 subject=作品，见 `C4_claim_subject_mismatch_on_work_author`）、
`GET /draft/work-authors?work=`、`POST /draft/textbook`、`GET /draft/textbooks`、`POST /draft/textbook-work`、`GET /draft/textbook-works?work=`。

错误语义：`400` 词表/引用/重复等业务错误；`409` 写入会让库"不可核查"（已整笔回滚）；`401/503` token 问题。
统一由 `PoetryAuthoringAdvice` 生成响应体，不再抛栈。

探针（只读或显式回滚，绝不提交）：`/tmp/poetry_crud/CrudProbe.java`、`/tmp/poetry_crud/Slice2Probe.java`。
