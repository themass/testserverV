# Studio 治理 API(V009)

适用模块:`vvv-poetry`。对应契约:`poetry-agent-platform/docs/handoff/A-contract.md` §3。迁移 `V009__studio_governance.sql` 只写了文件,**需要用户在已备份的库上手工执行**(回滚见 `db/poetry/recovery/V009_rollback.sql`)。

## 部署顺序

1. 执行 V009(逐条执行,遇错即停;`CREATE INDEX` 在 MySQL 5.6 不能 `IF NOT EXISTS`,重复执行会报重名,属预期)。
2. 配置 `poetry.studioReviewerToken`(必须与 `poetry.agentInternalToken` 不同)。
3. 再部署带逐项评审改动的 `vvv-poetry`。`PoetryAgentService.apply` 会读 `poetry_agent_proposal_item`,表不存在时 apply 会失败,不会静默回退成"全部执行"。

## 令牌

| 路由 | 头 | 配置项 | 未配置 | 错误 |
|---|---|---|---|---|
| 读 `/api/poetry/v1/agent-orchestration/*`(新增 GET) | `X-Poetry-Agent-Internal-Token` | `poetry.agentInternalToken` | 403 | 403 |
| 写 `/api/poetry/v1/studio/*` | `X-Poetry-Studio-Reviewer-Token` | `poetry.studioReviewerToken` | 503 | 401 |

- agent 令牌调用 studio 写路由一律 401;studio 令牌调用读路由 403。
- 若 `studioReviewerToken` 与 `agentInternalToken` 配成同一个值,写路由按未配置处理(503)。
- 令牌校验先于请求体解析:没有令牌的请求拿不到字段级提示。

## 信封与错误

响应:`{status, data, audit_refs, next_action}`。错误时 `data = {code, reason, details?}`。

| HTTP | status | 常见 code |
|---|---|---|
| 400 | REJECTED | `INVALID_ID` `INVALID_FILTER` `INVALID_PAGINATION` `INVALID_REVIEWER` `INVALID_ROLE` `INVALID_LOCATOR` `INVALID_DECISION` `INVALID_ITEM_INDEX` `DUPLICATE_ITEM_INDEX` `DECISIONS_REQUIRED` `TOO_MANY_DECISIONS` `FIELD_TOO_LONG` `BODY_REQUIRED` `BODY_INVALID` `BODY_TOO_LARGE` |
| 401 / 503 | UNAUTHORIZED / UNAVAILABLE | `INVALID_TOKEN` / `STUDIO_WRITE_DISABLED` |
| 403 | FORBIDDEN | `ROLE_NOT_ALLOWED`(读路由令牌错时为 `INVALID_TOKEN`) |
| 404 | NOT_FOUND | `WORK_NOT_FOUND` `TASK_NOT_FOUND` `PROPOSAL_NOT_FOUND` `SOURCE_NOT_FOUND` `CITATION_NOT_FOUND` |
| 409 | CONFLICT | `LOCATOR_MISSING`(`details.missing=[{claim_id,locator_state}]`) `PUBLISH_BLOCKED`(`details.blocking`) `AUDIT_ROLLBACK` `PROPOSAL_NOT_PENDING` |

请求体字段全部 snake_case,**未知字段会被拒绝**(400 `BODY_INVALID`),包括写成 camelCase 的键。

## 读(经 MCP 控制桥)

`GET` 前缀 `/api/poetry/v1/agent-orchestration`,分页统一 `{items,limit,offset,has_more}`,`limit` 默认 50、范围 1–200,越界返回 400(不静默截断)。

`/tasks` `/tasks/{id}/runs` `/proposals` `/proposals/{id}/items` `/works` `/works/{id}/coverage` `/works/{id}/studio-view` `/sources`

- 过滤值大小写敏感(`status=RUNNING`),不合法返回 400。
- `/proposals` 的 `proposal_json` 是库里存的原始字符串;没有 run 行的旧提案仍会出现(`task_id=null`)。
- `studio-view` 的 `claims/citations/sources` 是 snapshot 的**超集**:另外包含以背景 id 为 subject 的 claim。
- `claims_checkable.checkable` = 至少有一条 locator 为真实值(SET)的 claim 数,与来源是否已核验无关。
- 键名一律 snake_case;值为 NULL 的列仍保留键(值为 null)。

## 写

署名 `reviewer`:去零宽字符与首尾空白后 2–100 字。`reviewer_role` 取 `HISTORICAL_REVIEWER|PLATFORM_ADMIN|CONTENT_EDITOR`;填 locator 与核验来源只允许前两者(其余 403)。每次成功写入追加一行 `poetry_studio_check_log`,`audit_refs[0]` 为 `studio-check-log:<id>`。

### 署名规则的取舍

- 拒绝:含 `agent` / `deerflow` / `system` 子串(忽略大小写);中文 `智能体 机器人 人工智能 大模型 系统 助手`;作为**完整词**出现的 `mcp` `llm` `bot` `chatbot`;`PublicationGate` 已有的 DEMO 前缀与 system/root/null/live-probe。
- `ai` 不做子串匹配(否则 Lai、Bai、Kai、Cai 等拼音人名全部被拒)。只在三种情形拒绝:整个署名就是 `ai`;大写 `AI` 独立成词且署名里还有小写字母(`Claude AI`);小写 `ai` 与别的词用 `-_./:@` 连写,或与 `reviewer/assistant/gpt` 等角色词同时出现(`ai-reviewer`、`AI Assistant`)。
- 通过:`Wang Ai`、`Lai`、`Bai Juyi`、`Ai Weiwei`、`Talbot`、`McPherson`。
- 已知误伤:含 `agent` 子串的姓(`Reagent`);小写连字符的 `li-ai`。
- 已知漏判:`Ai Claude` 这类不大写、不连写、不带角色词的署名。
- 这只是减速带。Studio 没有登录(契约 D8),真正的控制是独立令牌 + 角色白名单 + 审计表。

### `PUT /studio/citations/{claimId}/{sourceId}/locator`

```json
{"locator":"《资治通鉴》卷二百一十八","evidence_excerpt":"摘录","reviewer":"Zhang Wei","reviewer_role":"HISTORICAL_REVIEWER","note":"对照影印本"}
```

- locator 拒绝:空/纯空白、`待…` 开头或含 `待核查/待人工/未核对`、`TBD`、`DEMO`、`演练`、`n/a/无/暂无/略`、无任何字母数字汉字、含控制字符、超 300 字。口径与 `audit_integrity_checks.sql` 的 C5 占位判断一致,保证这里接受的 locator 不会被发布前核查拦下。
- citation 必须已存在(404),不会新建;**不改来源的 `verification_status`**。
- `evidence_excerpt` 不传则保留原值。被替换的旧 locator 写进审计表 `note`。

### `POST /studio/sources/{id}/verification`

```json
{"decision":"VERIFY","reviewer":"Zhang Wei","reviewer_role":"HISTORICAL_REVIEWER","note":"…"}
```

- `VERIFY`:先要求该来源下**每条** citation 的 locator 均为 SET,否则 409 `LOCATOR_MISSING` 并列出缺失的 claim;再调用 `PoetryReviewService.publish("source", …)`(发布闸门 + 106 项审计,发布后再审一次,不干净则回滚)。
- `REJECT`:调用 `retract("source", …)`。
- 已是目标状态时返回 200 且 `changed=false`,不重复写日志。
- 不检查 `poetry_text_version.source_locator`(那是版本级 locator,不属于 citation)。

### `PUT /studio/proposals/{id}/items`

```json
{"decisions":[{"item_index":0,"decision":"APPROVE"},{"item_index":1,"decision":"REJECT","comment":"措辞不当"}],"reviewer":"Li Na","reviewer_role":"CONTENT_EDITOR"}
```

- 仅提案 `review_status=PENDING` 时允许(否则 409);逐条覆盖写入,单次最多 50 条,`item_index` 为 `changes` 数组的 **0 起始**下标。
- 非可执行项(无 `draft_payload`)也可记录,不影响应用。
- **apply 语义**:提案下完全没有逐项记录 → 旧行为(全部可执行项都执行);有任意记录 → 只执行被明确 `APPROVE` 的可执行项,未记录或 `REJECT` 的跳过。响应新增 `item_review`、`skipped_executable_changes`(如 `["1:REJECT","0:UNDECIDED"]`)。全部被跳过时 apply 仍成功,`applied_operations` 为空。

## 已知缺口

- 没有身份认证:`reviewer` 与 `reviewer_role` 由调用方自报(契约 D8)。
- `poetry_agent_proposal_item` 与 `poetry_studio_check_log` 未纳入 `audit_integrity_checks.sql`(那是已执行的核查文件,本次未改;要加需另行决定)。
- 逐项评审的单项历史会被覆盖,只在 `poetry_studio_check_log.note` 里留每次调用的 `index:decision` 摘要。
