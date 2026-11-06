# 发布前审核清单（人做的判断 + 机器能查的项）

顺序不能颠倒：**先跑核查，再做判断**。核查非 0 时不必往下看，先修数据。

## 第 0 步：机器核查

```bash
mysql <dev_db> < vvv-poetry/src/main/resources/db/poetry/audit_integrity_checks.sql | awk -F'\t' '$2!=0'
```
106 项必须全 0（表头会显示当前项数）。非 0 = **禁止发布**，不是警告。

## 第 1 步：内容能不能发布（逐条打勾）

| 检查 | 判断标准 | 对应核查项 |
|---|---|---|
| 依据能复查 | locator 能让人翻到同一处 | `C5_citation_locator_placeholder_on_published_claim` |
| 来源真核过 | VERIFIED 的具体人+时间+版本；`DEMO*` 一律拒绝 | `C5_demo_verified_source_would_publish`、`C5_verified_source_without_reviewer`、`C5_verified_source_without_grading` |
| 事实/解释/演绎没混 | 演绎有 `dramatization_labeled=1`；解释不写成史实 | `C5_published_dramatization_not_labeled` |
| 年代有出处 | 展示年代 = `time.span` FACT claim + 采用说 | `C6_published_timed_content_without_adopted_time_claim` |
| 分歧是显式的 | 他说并存 + selection 表态；不用摘要掩盖 | `C4_selection_claim_missing_or_mismatched` |
| 作者归属成立 | claim 主体=作品、`property_key='authorship'`、ACCEPTED/DISPUTED | `C4_claim_subject_mismatch_on_work_author`、`C5_published_work_without_accepted_author` |
| 背景不吞文本 | 每条背景关联到具体句，正文非空，学段已定 | `C5_published_background_without_body`、`..._without_audience`、`C4_line_missing_on_background_line`、`C4_background_line_cross_work` |
| 主题线成其为线 | 至少 2 个已发布成员 | `C5_published_theme_with_fewer_than_two_published_items` |
| 审核可追溯 | 该 content 有 review_log 记录 | `C5_published_content_without_review_log` |
| 覆盖声明属实 | `poetry_coverage` 与实际录入范围一致（空白=未覆盖，不是"没有"） | `C6_coverage_*`、`C7_invalid_coverage_*` |

## 第 2 步：内容该不该发布（机器管不了的部分）

1. 这段文字是否**只说这首诗这一版**能说的事？（跨作品泄漏：`C4_background_line_cross_work` 只查结构，不查表述）
2. 有没有把"可能"写成"确定"？（尤其：为什么写这首诗）
3. 学段标注是否与实际措辞相符？
4. 学生读完后，是更接近诗句本身，还是更远离？——后者不发。

## 第 3 步：发布动作（两条通道，二选一）

**A. 走审核接口（推荐，机器强制）**：`POST /api/poetry/v1/review/{type}/{id}/publish`
带 `X-Poetry-Review-Token`，body `{"reviewer":"<真人>","note":"依据哪一版"}`。
机器会：查审核人身份（`DEMO*`/`LIVE-PROBE`/`system` 一律拒）→ 查本体闸门（来源已核查、演绎已打标、
`source_kind/reliability` 已填、版本有句）→ 跑 106 项核查 → 改状态 + 追加 `poetry_review_log` →
**再跑一遍核查**，结果不干净就整笔回滚。

**B. 走受控 SQL**（没有 token 或需要批量整理时）：见下方第 3 步，但必须自己保证 A 的全部条件。


1. `poetry_content / poetry_claim / poetry_text_version`：`status='PUBLISHED'`，`reviewed_by=<真人>`，`reviewed_at=NOW()`；
2. `revision` +1，并在 `poetry_review_log` 追加一行（`decision='PUBLISHED'`，note 写"依据哪一版、核查输出全 0"）；
3. 再跑一次核查：必须仍然全 0；
4. 冒烟：`curl` 该作品的 lines / claims / citations，确认返回；再确认草稿内容仍 404。

## 反向清单（发布后禁止）

- 不许把 `reviewed_by` 写成系统账号或他人姓名；
- 不许为了让接口有数据而 `UPDATE ... SET status='PUBLISHED'`（先补依据）；
- 不许用 `DEMO` 演练库充当内容质量证据：演练后核查必然非 0（见 `demo_publish_chunwang.sql` 顶部说明）。
