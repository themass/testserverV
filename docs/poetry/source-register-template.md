# 来源登记模板

底座的可信度全部来自 `poetry_source` + `poetry_citation`。登记错一次，后面所有发布都建立在沙上。

## 1. 一条来源一行（绝不重复登记）

| 字段 | 填法 | 反面例子 |
|---|---|---|
| `id` | `source-<书或史源短名>`，一次定名长期使用 | `source-tang-1`、`source-tang-2` 是同一本书 |
| `title` | 书名全称，含卷次范围 | 《全唐诗》（不写版本＝无法复查） |
| `author` | 撰者/编者，未知留空 | 猜测 |
| `edition` | **必须具体**：通行本/影印本/点校本 + 出版信息 | 空、"网络版" |
| `url` | 有则填，且记录访问日期在 `rights_note` | 把 wikisource 当定本 |
| `source_kind` | OFFICIAL_HISTORY / YEAR_BOOK / ANTHOLOGY / TEXTBOOK / MODERN_STUDY / DIGITIZED_TEXT / ONLINE_ENTRY / OTHER | 留空又想升 VERIFIED（`C5_verified_source_without_grading` 会拦） |
| `reliability` | HIGH / MEDIUM / LOW / UNKNOWN（**分级=编者判断**，不等于已核查） | 把"有名"当 HIGH |
| `rights_note` | 使用条件、访问日期、能否摘录原文 | 空 |
| `verification_status` | 默认 PENDING；只有逐条核对过原文与定位才 VERIFIED | 批量升 VERIFIED |
| `verified_by` / `verified_at` | 具体人 + 时间；`DEMO*` 前缀会被核查当作演练库标记报警 | 系统账号 |

## 2. `poetry_citation.locator` 的合格写法

- 合格：`点校本《全唐诗》卷225，第2318页，第3行`（前提：你真的翻到了那一页）
- 不合格：`待人工核对`、`见相关章节`、`网上查到`、`卷225`（你没核对是哪一页就写哪一卷，等同猜）
- 机器兜底：`C5_citation_locator_placeholder_on_published_claim`（拦截 待% / 待核查 / 待人工 / 未核对 / DEMO / 演练）

## 3. 什么时候可以升 VERIFIED

四个条件同时成立，缺一就停在 PENDING：

1. 手里有该 `edition`（或可复查的影印/点校来源），不是二手转述；
2. 抄录原文并与 `evidence_excerpt` 逐字一致；
3. `locator` 能让另一个人翻到同一处；
4. 已在 `poetry_review_log` 追加一行（`subject_table='poetry_source'`，decision=`APPROVED`，note 写明核对了什么、还欠什么）。

## 4. 明确不可当已核查来源的东西

- chinese-poetry 等批量数据集：可作为**线索**，其文本与课本版本可能不同（《静夜思》即是例子），必须回到纸本或权威点校；
- 百科词条、自媒体、AI 回答：只能作为线索，登记时 `source_kind='ONLINE_ENTRY'` + `reliability='LOW'`，且永远 PENDING；
- 旧教材的标签/单元名：不作为史实依据，只作为"某版教材曾收录"的记录（走 `poetry_textbook`）。
