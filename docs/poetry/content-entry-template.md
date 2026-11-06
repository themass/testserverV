# 内容录入模板（受控 SQL，不是 CMS）

现阶段录入=人写 SQL。原因：内容少、每条都必须人审、且约定（无外键）只有在录入时才能遵守。
将来做录入界面时必须实现本页的顺序，否则所有约定都会失效。

## 0. 动手前

- 确认库：`SELECT @@hostname, DATABASE(), @@version;` 写进工单。**不要**在生产库演练。
- 备份。DDL 不可回滚；回退只能靠 `db/poetry/drop_poetry_objects.sql`（会清空全部 poetry 表）。
- 一条内容一个文件/一个工单，事务包住：`START TRANSACTION; … COMMIT;`

## 1. 顺序（无外键世界的唯一"约束"）

```
1) poetry_content           身份：entity_type / slug / title / 时间三件套
2) 实体子表                  poetry_dynasty|period|place|person|event|experience|work|theme
3) poetry_claim             说法（FACT / INTERPRETATION / DRAMATIZATION）
4) poetry_source            来源（若已登记则复用 id，绝不重复登记同一本书）
5) poetry_citation          说法↔来源，locator 必须是**可复查的定位**（卷/页/条目）
6) poetry_claim_selection   采用哪一说（同主体同属性只允许一条）
7) 明细与关联               text_version / text_line / background / background_line /
                           annotation / relation / work_author / theme_item
8) poetry_review_log        追加一行：谁、第几版、什么决定、为什么
```

**BACKGROUND 例外顺序**：`poetry_content(bg) → poetry_claim(bg) → poetry_background → poetry_citation → poetry_background_line`。
因为 `poetry_background.claim_id` 与 `poetry_claim.subject_id` 互相指向，先建 claim 才不会插入悬空 id。

## 2. 抄这段骨架（替换 <> 部分）

```sql
START TRANSACTION;

INSERT INTO poetry_content (id, entity_type, slug, title, summary, start_year, end_year, time_precision)
VALUES (<id>, 'WORK', <slug>, <标题>, <一句话摘要，不要写结论性史实>, <起年>, <止年>, 'EXACT');

-- 年代必须是"说法"，展示值只是它的投影
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
VALUES ('claim-<id>-time', <id>, 'time.span', '<起>..<止> (EXACT)', 'FACT', 'KNOWN');
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
VALUES (<id>, 'time.span', 'claim-<id>-time');

INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
VALUES ('claim-<id>-authorship', <id>, 'authorship', '<作者>', 'FACT', 'KNOWN');
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
VALUES ('claim-<id>-authorship', <source_id>, '<可复查的卷/页/条目>', '<原文摘录>');
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
VALUES (<id>, 'authorship', 'claim-<id>-authorship');

INSERT INTO poetry_work_author (work_id, person_id, attribution, claim_id)
VALUES (<id>, <person_id>, 'ACCEPTED', 'claim-<id>-authorship');

INSERT INTO poetry_review_log (subject_table, subject_id, subject_revision, decision, reviewer, note)
VALUES ('poetry_content', <id>, 1, 'SUBMITTED', <你的名字>, '<这次改了什么、还欠什么>');
COMMIT;
```

## 3. 硬性要求（不满足就是不许发布，不是"建议"）

| 要求 | 为什么 | 被抓的核查项 |
|---|---|---|
| 每个引用 id 先存在再引用 | 无外键 | `C1_*` / `C4_*` |
| 时间有值就必须有 `time.span` FACT claim + 采用说 | 年代不能只活在展示字段里 | `C6_published_timed_content_without_adopted_time_claim` |
| locator 必须能复查 | "待核对"不是定位 | `C5_citation_locator_placeholder_on_published_claim` |
| 不确定就 `certainty='DISPUTED'` + 并存两说 + selection 表态 | 把分歧藏起来等于造假 | `C4_selection_claim_missing_or_mismatched` |
| 演绎必须 `claim_kind='DRAMATIZATION'` 且 `dramatization_labeled=1` | 学生不能把演绎当史实 | `C5_published_dramatization_not_labeled` |
| 撤回用 `status='RETRACTED'`，永不 DELETE | 删父行会制造孤儿 | `C1_*` |
| 一条背景 = 一个 layer + 一段正文 | 四层处境要能分别呈现 | `C5_published_background_without_body` |

## 4. 交回来必须带的三样东西

1. 执行的 SQL（含 `poetry_schema_version` 之外的所有语句）；
2. `audit_integrity_checks.sql` 的输出（草稿阶段应全 0）；
3. 一句话：这条内容**还缺什么依据**（写进 `poetry_review_log.note`，别只写在聊天里）。
