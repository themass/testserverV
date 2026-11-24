-- V077：劉方平《春怨》(work-t300-360) 四层背景（阶段 D 第 58 首·同题两诗与让渡形态）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V014、V015、V016、V018、V026、V033、V035、V039、V048、V049、V053、
--       V055、V056、V057、V058、V059、V060、V061、V062、V063、V064、V065、V066、V067、
--       V068、V069、V070、V071、V072、V073、V074、V075、V076 已执行
--       （work-t300-360 与其 text-work-t300-360-ws（version_code=ws-raw——V018 立此诗正文
--       用的就是《唐詩三百首》选本页，四行净文全无尾随空格——是本页 poem 块的**折叠面**：
--       {{另|欲|又}} 取头部主读「欲」、两物理行行尾随行空格全裁——**存储面即定読面第二枚**
--       （V076 首枚）：页面存异读、库存储定读）与其源 source-ws-t300-360（V018 已立的
--       选本页源，本迁移第二次复用零新建）；
--       **同题另一首** work-t300-043（金昌緒《春怨》五绝）及其 text-work-t300-043-ws /
--       source-ws-t300-043（V018 同场所立——同题两诗在册首枚：两首各全套在册机器断言；
--       本页诗面随 CITY 入引——768 与选本两面互异 {{另|啼時|幾時}}/{{另|啼時|幾迴}}、却/卻
--       只登记不裁决）；source-zizhi-tongjian-events（V014/V015 已立的通鉴事件源）是既有行；
--       **本迁移恰新建一枚 source：source-quantangshi-768**——卷768 卷页源（V076 首立
--       卷页源之第二枚），承载金昌緒编者附记小传「餘杭人，詩一首。」+题级{{另}}锚+inline
--       全文（V076 卷253 空壳/本篇 768 inline 成**底本两态**：壳在册/inline 在录）；
--       audit 断言本文件恰一枚 poetry_source INSERT、回滚恰删此一枚；
--       判例在册句（V018 句读式「紗窗日落漸黃昏，……梨花滿地不開門。」「打起黃鶯兒，……
--       不得到遼西。」+两页 'header author=' 署名直证、V056 通鉴泪痕句「以其有淚痕故也」
--       ——**泪痕账 V056 已用讫：零重开硬断言，此句不入任何引文**；V075 fetch.log 卷256
--       在册句只对照不重开）。
--
-- 数据源（可复现）：emit_v077.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/春怨__劉方平_.txt（poem 块两物理行存原样+行尾随行空格照登+{{另|欲|又}}；notes
--   整值 75%+↑回指卷251 同行+**行尾双随行空格全库恰一页**机器断言；{{唐詩三百首}}「}}」同行
--   随尾挂法 145 页闭域；类目四元组全库恰一页）、
--   ws-poems/春怨__金昌緒_.txt（同题另一首：题面 {{*|一作伊州歌}}（20 页闭域）+notes 回指
--   卷768 在册+poem 双 {{另}} 存原样）、
--   V018 存储面重建比对（t300-360 四行 vs ws 折叠面双向断言；t300-043 四行 vs 金页双折叠
--   面双向断言——同题两页各自折叠）、
--   全唐詩快照卷768（锚{{另|春怨|伊州歌}}+inline 全诗+编者附记「餘杭人，詩一首。」——
--   新源逐字承载）+卷143（王昌齡锚+空壳——只计数不入引——**同题三诗三命运**）+卷017/018
--   （劉方平恰两处全在锚/署名行——「巫山高 劉方平著」恰一、「著」式锚全书 55 处唯卷017
--   机器断言——只计数不入引）+卷128（伊州歌只计数）、
--   fetch.log（「卷251: FAILED both name forms」恰二取第一轮窗口入引——**在册外零第二枚**：
--   底本不在快照非书零；第二轮窗口后继是卷256 FAILED——负证断言）、
--   通鑑卷205（梨花段逐字入引+延載元年窗口）、卷256（淚痕窗口——只断言耗尽不入引）+
--   通鑑 75 卷负证计数扫描（梨花恰一在205+淚痕恰一在256（V056 用讫）+春怨/紗窗/金屋/空庭/
--   不開門/黃鶯/遼西/妾夢/黃昏全零）+全唐詩快照负证（六句净文全零/莫教枝上啼+不得到遼西+
--   遼西恰一在768/春怨恰两卷143,768/伊州歌恰两卷128,768/餘杭人恰一/金昌緒唯768恰四/
--   劉方平恰两卷各一）+七史快照（jts 2+xts 8+qss 3+通鉴 75）劉方平/金昌緒全零机器断言+
--   ws 全库 295 页闭域档扫（notes双空格恰1含本页/类目四元组两页各唯一/题面{{*}}20含金页/
--   随尾挂145含本页，快照变动即中止）+既有迁移引文域逐句查重——在册零重开、让渡耗尽/
--   首引零域前提全部生成时断言。
--
-- 做：4 BACKGROUND content/claim/background + 6 组逐字引用（(claim,source) 主键每对恰一行）+
--   4 background_line（四句七绝 **1/1/1/1 第九次**：scene→1 city→2 world→3 person→4，
--   绑 text-work-t300-360-ws 的 4 行）+ 恰新建 source 一枚（source-quantangshi-768）+
--   不碰 poetry_text_line。
-- 不做：**不新建除 768 外的任何 source**（audit 断言恰一枚、回滚恰删此一枚）；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「泪的账前人先记走了」）：
--   * 「梨花灾异」「泪账耗尽让渡」系通鉴梨花段逐字入引+V056 在册域机器断言支撑的对照判决，
--     非史实因果——通鉴不记这首诗；亦不考本诗系年（编年诸说一律不采信不铸造）；
--   * 「以其有淚痕故也」**不入本迁移任何引文**（V056 已逐字用讫——audit 硬断言）：
--     通鉴泪痕恰一即恰一处已讫，无第二笔可引，只登记耗尽事实；
--   * 一作《伊州歌》：**两处见证（768 题级锚 {{另|春怨|伊州歌}} + 金选本页题面 {{*}}）
--     并列只登记不裁决**（异文只登记不裁决总判例）；欲/又、打/卻、啼時/幾迴取 {{另}}
--     头部主读系 V018 存储事实的登记非本迁移裁决；768 面却/幾時 与选本面卻/幾迴 互异
--     只登跨面见证对不裁决；
--   * 卷143 王昌齡《春怨》锚壳只计数不入引（同题三诗三命运之登记）；「巫山高 劉方平著」
--     与 55 处「著」式锚只计数不入引（署名行≠传记）；
--   * 页尾类目系整理者动作：非史料声明、不升格，V048 判例；
--   * 「七史无传」严格限于本地史部快照——不排除纸面史部另有传（无快照即不能说）；
--   * KNOWN 零如实记录（第卅三例——两首 V018 text claim 的 KNOWN 在册零重开不碰，audit
--     反向断言本迁移 SQL 无 KNOWN 字面量）；
--   * V011/V014/V015/V016/V018/V020/V026/V033/V035/V039/V048/V049/V053/V055/V056/V057/V058/
--     V059–V076 已引诸句只对照不重开。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 76，不含 77
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-360-%';             -- 空
--   SELECT id FROM poetry_source WHERE id IN ('source-ws-t300-360',
--     'source-ws-t300-043','source-quantangshi-768');                   -- 恰两行（768 本迁移新建前不存在）
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-360-ws';  -- 恰 4
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-043-ws';  -- 恰 4
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-360-%';       -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-360';                                  -- 4（1/1/1/1）
--   SELECT certainty FROM poetry_claim WHERE id LIKE 'claim-bg-360-%';  -- 四行全 LIKELY
--   SELECT COUNT(*) FROM poetry_source WHERE id='source-quantangshi-768';  -- 恰 1（本迁移所立）
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-360'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-360';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-360-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
-- 回滚: recovery/V077_rollback.sql（按 id 全枚举删除；**source 只删一行**——
--   source-quantangshi-768 是本迁移新建的卷页源（恰一枚，审计断言）按 id 删除；
--   source-ws-t300-360 与 source-ws-t300-043 都是 V018 所立的选本页源（本迁移复用），绝不删；
--   work-t300-360/work-t300-043 本体与其 text_line 各 4 行都是 V018 的行，绝不删）
START TRANSACTION;

-- ---------- 0. 新建卷页源一枚（source-quantangshi-768——V076 卷页源第二枚） ----------
INSERT INTO poetry_source (id, title, author, edition, url, rights_note, verification_status, source_kind, reliability)
SELECT * FROM (
SELECT 'source-quantangshi-768' AS id, '御定全唐詩 (四庫全書本) 卷七百六十八（錢起 盧綸 … 金昌緒 曾麻幾 等合卷）' AS title, NULL AS author, '御定全唐詩 (四庫全書本)' AS edition, 'https://zh.wikisource.org/wiki/全唐詩/卷768' AS url, '维基文库录入本，公有领域古籍。本行由 emit_v077.py 对 /tmp/src-dl 快照逐字定位。本诗（t300-360 劉方平）V018 立正文用的是《唐詩三百首》选本页（source-ws-t300-360，version_code ws-raw），此《御定全唐詩》卷768 是**同题另一首**（t300-043 金昌緒）的底本页：金页 notes ↑回指即指本页，且本页在册形态是 inline 全文转录（「打{{另|起|却}}黃鶯兒……不得到遼西。」）+题级锚 {{另|春怨|伊州歌}}+编者附记小传「金昌緒，餘杭人，詩一首。」——与 V076 卷253 空壳成底本两态（壳在册/inline 在录）。选本页与卷页是两个独立见证面（选本侧 {{*|一作伊州歌}} vs 卷页侧锚级 {{另|春怨|伊州歌}}——两处只登记不裁决），本迁移引卷页非新源不能承载（audit 断言恰一枚 source INSERT、回滚恰删此一枚）。核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status, 'POETRY_COLLECTION' AS source_kind, 'HIGH' AS reliability FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_source x WHERE x.id = t.id);

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-360-scene' AS id, 'BACKGROUND' AS entity_type, '360-scene' AS slug, '眼前：日落黄屋与满院空庭' AS title, '四层处境背景（阶段 D 第 58 首·四句七绝 1/1/1/1 第九次）；史实句均有逐字引证；系年第五十二次判决（同题两诗与底本两态——三首《春怨》三种在册命运）；同字两界第二十二形态·让渡形态首见：「诗的梨花，通鉴恰一处，那一处是灾异；泪的账已被 V056 记走」——梨花入引（延載元年宰相声瑞）、淚痕零重开硬断言（耗尽登记不重引）；同题两诗在册首枚（t300-360/t300-043 各全套在册——类目四元组两页各全库唯一）；存储面即定読面第二枚（V018 ws-raw 净文=两页折叠面，生成时拼合断言）；在册外零第二枚（卷251 FAILED 恰二机器登记——与 V075 卷256 成对）；一作伊州歌两处见证+768/选本诗面互异只登记不裁决；恰新建卷页源一枚 source-quantangshi-768（卷页源第二枚）+ws-360/043/通鉴在册复用；正文第二引第二十五例零重开；零传记之人第三、四枚合页首枚（七史全零+金附记「詩一首」+刘只留名）；KNOWN 零如实记录第卅三例（audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-360-city' AS id, 'BACKGROUND' AS entity_type, '360-city' AS slug, '这座城：同题两诗与底本两态' AS title, '四层处境背景（阶段 D 第 58 首·四句七绝 1/1/1/1 第九次）；史实句均有逐字引证；系年第五十二次判决（同题两诗与底本两态——三首《春怨》三种在册命运）；同字两界第二十二形态·让渡形态首见：「诗的梨花，通鉴恰一处，那一处是灾异；泪的账已被 V056 记走」——梨花入引（延載元年宰相声瑞）、淚痕零重开硬断言（耗尽登记不重引）；同题两诗在册首枚（t300-360/t300-043 各全套在册——类目四元组两页各全库唯一）；存储面即定読面第二枚（V018 ws-raw 净文=两页折叠面，生成时拼合断言）；在册外零第二枚（卷251 FAILED 恰二机器登记——与 V075 卷256 成对）；一作伊州歌两处见证+768/选本诗面互异只登记不裁决；恰新建卷页源一枚 source-quantangshi-768（卷页源第二枚）+ws-360/043/通鉴在册复用；正文第二引第二十五例零重开；零传记之人第三、四枚合页首枚（七史全零+金附记「詩一首」+刘只留名）；KNOWN 零如实记录第卅三例（audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-360-world' AS id, 'BACKGROUND' AS entity_type, '360-world' AS slug, '这个天下：梨花是灾异，泪账已记讫' AS title, '四层处境背景（阶段 D 第 58 首·四句七绝 1/1/1/1 第九次）；史实句均有逐字引证；系年第五十二次判决（同题两诗与底本两态——三首《春怨》三种在册命运）；同字两界第二十二形态·让渡形态首见：「诗的梨花，通鉴恰一处，那一处是灾异；泪的账已被 V056 记走」——梨花入引（延載元年宰相声瑞）、淚痕零重开硬断言（耗尽登记不重引）；同题两诗在册首枚（t300-360/t300-043 各全套在册——类目四元组两页各全库唯一）；存储面即定読面第二枚（V018 ws-raw 净文=两页折叠面，生成时拼合断言）；在册外零第二枚（卷251 FAILED 恰二机器登记——与 V075 卷256 成对）；一作伊州歌两处见证+768/选本诗面互异只登记不裁决；恰新建卷页源一枚 source-quantangshi-768（卷页源第二枚）+ws-360/043/通鉴在册复用；正文第二引第二十五例零重开；零传记之人第三、四枚合页首枚（七史全零+金附记「詩一首」+刘只留名）；KNOWN 零如实记录第卅三例（audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-360-person' AS id, 'BACKGROUND' AS entity_type, '360-person' AS slug, '这个人：七史无名，总集留一首' AS title, '四层处境背景（阶段 D 第 58 首·四句七绝 1/1/1/1 第九次）；史实句均有逐字引证；系年第五十二次判决（同题两诗与底本两态——三首《春怨》三种在册命运）；同字两界第二十二形态·让渡形态首见：「诗的梨花，通鉴恰一处，那一处是灾异；泪的账已被 V056 记走」——梨花入引（延載元年宰相声瑞）、淚痕零重开硬断言（耗尽登记不重引）；同题两诗在册首枚（t300-360/t300-043 各全套在册——类目四元组两页各全库唯一）；存储面即定読面第二枚（V018 ws-raw 净文=两页折叠面，生成时拼合断言）；在册外零第二枚（卷251 FAILED 恰二机器登记——与 V075 卷256 成对）；一作伊州歌两处见证+768/选本诗面互异只登记不裁决；恰新建卷页源一枚 source-quantangshi-768（卷页源第二枚）+ws-360/043/通鉴在册复用；正文第二引第二十五例零重开；零传记之人第三、四枚合页首枚（七史全零+金附记「詩一首」+刘只留名）；KNOWN 零如实记录第卅三例（audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-360-scene' AS id, 'bg-360-scene' AS subject_id, 'context' AS property_key, '四句取 ws 选本页 poem 块存原样面入引（两物理行各带行尾随行空格照登+第二行内嵌{{另|欲|又}} 异读；header author 署名直证同入引——七史无传之人只在页 header 留名）；**存储面即定読面第二枚**（V018 ws-raw 四行净文=本页 poem 块折叠面：欲取头部主读、两随行空格全裁——生成时拼合断言双向）；正文第二引第二十五例（V018 句读式「紗窗日落漸黃昏，……梨花滿地不開門。」一引在先零重开硬断言）' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-360-city' AS id, 'bg-360-city' AS subject_id, 'context' AS property_key, '**同题两诗在册首枚**：t300-360/t300-043 各有全套在册（机器断言）；本页类目四元组与金页五言四元组各全库恰一页（同题两页各占唯一类目面，V048 不升格）；notes 整值入引（75%+↑回指卷251 同行+**行尾双随行空格全库恰一页**）——卷251 不在快照（fetch.log「卷251: FAILED」恰二机器登记——**在册外零第二枚**）；对照金页回指卷768 在册+inline 全文入引；「春怨」快照恰两卷 143（锚壳只计数）/768（inline入引）——同题三诗三命运+底本两态（与 V076 空壳对照）；一作伊州歌两处见证（768 锚{{另}}+金页题面{{*}}——题面{{*}}20页闭域）只登记不裁决；768/选本诗面互异（幾時/幾迴、却/卻）异文跨面见证对第二枚；{{唐詩三百首}} 随尾挂法 145 页闭域与 V075 独立行 59 页闭域成挂法两式总账；**恰新建卷页源一枚 source-quantangshi-768**（卷页源第二枚，audit 正反断言）' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-360-world' AS id, 'bg-360-world' AS subject_id, 'context' AS property_key, '通鉴梨花恰一（延載元年甲午六九四武后出梨花一枝示宰相、宰相皆以為瑞、杜景儉「陰陽不時，咎在臣等」拜谢）闭域+年标题窗口机器断言入引——史的梨花是灾异、诗的梨花是无人看（对照判决非史实因果）；**同字两界第二十二形态·让渡形态首见**：淚痕通鉴恰一（光啟二年御袍）已被 V056 逐字引走用讫（域断言）——本迁移零重开硬断言（audit 硬卡「以其有淚痕故也」不入任何引文）；春怨/紗窗/金屋/空庭/不開門/黃鶯/遼西/妾夢/黃昏通鉴全零' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-360-person' AS id, 'bg-360-person' AS subject_id, 'context' AS property_key, '劉方平/金昌緒七史快照全零（jts 2+xts 8+qss 3+通鉴 75——零传记之人第三、四枚合页首枚，机器断言）；金附记「餘杭人，詩一首」逐字入引（新源承载——與 V076 王附记同款、餘杭人全快照恰一）；「劉方平」快照恰两处全在锚/署名行（017 巫山高劉方平著——著式锚全书55处唯卷017机器断言只计数不入引/018 署名行）——刘只留名金留一首；V018 作者判定在册零重开；KNOWN 零如实记录第卅三例' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-360-scene' AS subject_id, 'context' AS property_key, 'claim-bg-360-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-360-city' AS subject_id, 'context' AS property_key, 'claim-bg-360-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-360-world' AS subject_id, 'context' AS property_key, 'claim-bg-360-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-360-person' AS subject_id, 'context' AS property_key, 'claim-bg-360-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-360-scene' AS id, 'work-t300-360' AS work_id, 'SCENE' AS layer, '**诗的第一笔是一间正在暗下去的屋子**：「紗窗日落漸黃昏，金屋無人見淚痕」——日落、黄昏、无人、泪痕，四个状态叠成一个看不见的脸。**ws 页的 poem 块存原样**：两个物理行、每行两个七言句，行尾各带一个随行空格照登；第二行内嵌 {{另|欲|又}} 异读（「寂寞空庭春{{另|欲|又}}晚」）。**存储面即定読面第二枚**（V076 首枚）：V018 以 ws-raw 存的四行净文正是本页折叠面——「欲」取 {{另}} 头部主读、两个行尾随行空格全裁（生成时拼合断言：页物理行 = 存储行拼合+标记件）：页面存异读、库存储定读。署名 header 「author = 劉方平」逐字入引——七史无传之人只在页 header 留名。**正文第二引上限用满第二十五例**（V018 句读式「紗窗日落漸黃昏，……梨花滿地不開門。」一引在先，零重开硬断言），此后此诗正文关闭。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-360-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-360-city' AS id, 'work-t300-360' AS work_id, 'CITY' AS layer, '**选本同时收了两首《春怨》**：t300-360 劉方平（七绝）与 t300-043 金昌緒（五绝「打起黃鶯兒」）——同题两诗各有 work/text/claim/source 全套在册（机器断言），本页类目四元组（唐詩/七言絕句/閨怨詩/詠春詩）**全库恰一页**、金页五言四元组亦全库恰一页——**同题两页各占一个唯一类目面**（整理者动作：非史料声明、不升格，V048 判例）。notes 整值入引：75% 评级+↑底本回指「全唐詩·卷251」同行——**行尾双随行空格全库恰一页**（照登）；而回指目标卷251 不在快照：抓取日志「卷251: FAILED both name forms」恰二条（两轮各一，机器登记入引）——**在册外零第二枚**（四句净文118 卷全零系底本缺席非书零）。对照金页：notes 回指卷768、768 在快照在册——「春怨」在快照恰两卷：143（王昌齡锚+空壳——只计数）/768（金昌緒 inline 全文逐字入引）——**同题三诗三命运**：刘底本不在、金 inline 在录、王锚壳在册；与 V076 卷253空壳成**底本两态**（壳在册/inline 在录）。题面「一作伊州歌」两处独立见证（768 锚内 {{另|春怨|伊州歌}}+金选本页题面 {{*}}——题面{{*}}20 页闭域）**只登记不裁决**；768 与金选本页诗面互异（{{另|啼時|幾時}} vs {{另|啼時|幾迴}}、却/卻）——**异文跨面见证对第二枚**。{{唐詩三百首}} 走「}}」同行随尾挂法（145 页闭域——与 V075 body独立行挂法 59 页闭域对成挂法两式）。**恰新建卷页源一枚 source-quantangshi-768**。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-360-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-360-world' AS id, 'work-t300-360' AS work_id, 'WORLD' AS layer, '**诗的梨花，通鉴恰一处，那一处是灾异**（同字两界第二十二形态·让渡形态首见）：「梨花滿地不開門」——通鉴「梨花」恰一：延載元年（甲午，六九四）武后「**出梨花一枝以示宰相，宰相皆以為瑞**」，杜景儉獨曰「**今草木黃落，而此更發榮，陰陽不時，咎在臣等**」因拜谢，太后曰「卿真宰相也！」——史的梨花是反常到教宰相拜谢认罪的灾异，诗的梨花是无人开门来看的满地落白（对照判决，非史实因果）。**泪的账已被前人记走**：本诗第二句有淚痕，通鉴「淚痕」也恰一（光啟二年僖宗解御袍賜王建「以其有淚痕故也」）——但这一处 V056《怨情》已逐字引走用讫（域 [''V056''] 机器断言）：通鉴的泪痕账没有第二笔，本迁移只登记耗尽事实、**在册句零重开硬断言**（audit 硬卡此句不入本迁移任何引文）——同字两界二十二形态第一次以「这一账前人先记走了」的形态出现；春怨/紗窗/金屋/空庭/不開門/黃鶯/遼西/妾夢/黃昏 通鉴全零（闭域档扫，机器断言）。' AS body_text, 'SENIOR' AS audience, 'claim-bg-360-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-360-person' AS id, 'work-t300-360' AS work_id, 'PERSON' AS layer, '**七史里没有这两个人——总集只留下他们的一首诗和一行附记**：劉方平/金昌緒在 jts 2 卷+xts 8 卷+qss 3 卷+通鉴 75 卷史部快照**全零**（机器断言）——零传记之人系列第三、四枚**合页首枚**（同一迁移两个人都无传）。金昌緒有总集编者附记一行：「金昌緒，餘杭人，詩一首。」（逐字入引，新源承载——与 V076 王之渙附记同款装置：王得「詩六首」、金得「詩一首」——**餘杭人三字全快照恰一**）。刘方平无附记：「劉方平」在快照恰两处全在锚/署名行（017「====巫山高 劉方平著====」——「著」式锚全书 55 处唯卷017，机器断言，只计数不入引；018 署名行）——**刘只留名、金留一首**。V018 作者判定（署名两页转录一致）在册零重开；两首 V018 text claim 已持 KNOWN（在册零重开不碰），本迁移自铸 claims 零 KNOWN（如实记录第卅三例，audit 反向断言）。无传的人在总集里一个有一首、一个只剩名字——系读法声明。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-360-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文 ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-360-scene' AS claim_id, 'source-ws-t300-360' AS source_id, '页面 春怨 (劉方平)（《唐詩三百首》第 360 首選本页；header author+poem 块两物理行存原样以「……」相连——行尾随行空格照登、行2内嵌 {{另|欲|又}}；**存储面即定読面第二枚**：V018 ws-raw 四行净文=本页折叠面（欲取头部主读+随行空格全裁，生成时拼合双向断言）；正文第二引第二十五例零重开' AS locator, '| author   = 劉方平……紗窗日落漸黃昏，金屋無人見淚痕。 ……寂寞空庭春{{另|欲|又}}晚，梨花滿地不開門。 ' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-360-city' AS claim_id, 'source-ws-t300-360' AS source_id, '页面 春怨 (劉方平)（notes 整值（75% 评级+↑底本回指卷251 同行+**行尾双随行空格全库恰一页**机器断言）+{{唐詩三百首}}「}}」同行随尾挂法（145 页闭域——与 V075 body独立行 59 页闭域成挂法两式）+页尾类目四元组（唐詩/七言絕句/閨怨詩/詠春詩全库恰一页——整理者动作：非史料声明、不升格，V048）+抓取日志窗口「卷251: FAILED both name forms」恰二取第一轮（**在册外零第二枚**：底本不在快照非书零）' AS locator, '| notes    ={{Textquality|75%}}↑ [[全唐詩/卷251#春怨|全唐詩·卷251]]  ……}}{{唐詩三百首}}……[[Category:唐詩]]
[[Category:七言絕句]]
[[Category:閨怨詩]]
[[Category:詠春詩]]……全唐詩/卷251: 全唐詩/卷251
全唐詩/卷251: 全唐詩/卷251
卷251: FAILED both name forms
全唐詩/卷253 -> vol253.txt 2088 chars' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-360-city' AS claim_id, 'source-ws-t300-043' AS source_id, '页面 春怨 (金昌緒)（同题另一首选本页——header title 内嵌 {{*|一作伊州歌}}（题面{{*}}20 页闭域）+notes 整值（75%+↑回指卷768 在册——与刘页卷251 抓取失败成对照）+poem 块两物理行存原样（{{另|打|卻}}/{{另|啼時|幾迴}}+随行空格照登——与卷768 面互成跨面异文见证对，只登记不裁决）；V018 折叠断言同页双向' AS locator, '| title    = 春怨{{*|一作伊州歌}}……| notes    ={{Textquality|75%}} ↑ [[全唐詩/卷768#|全唐詩·卷768]]……{{另|打|卻}}起黃鶯兒，莫教枝上啼。 ……{{另|啼時|幾迴}}驚妾夢，不得到遼西。 ' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-360-city' AS claim_id, 'source-quantangshi-768' AS source_id, '卷七百六十八·金昌緒「==={{另|春怨|伊州歌}}===」锚+inline 全诗逐字入引（**底本两态**之 inline 在录态——与 V076 卷253 空壳成谱；锚级一作伊州歌见证+「打{{另|起|却}}/{{另|啼時|幾時}}」存面与选本页互异；「春怨」快照恰两卷 143（王锚壳只计数不入引）/768——**本迁移恰新建此卷页源一枚**）' AS locator, '==={{另|春怨|伊州歌}}===
<poem>
打{{另|起|却}}黃鶯兒，莫教枝上啼。
{{另|啼時|幾時}}驚妾夢，不得到遼西。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-360-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '卷二百零五·延載元年（甲午，六九四）武后出梨花一枝以示宰相、宰相皆以為瑞、杜景儉「今草木黃落，而此更發榮，陰陽不時，咎在臣等」因拜谢、「卿真宰相也！」（**史的梨花是反常到教宰相认罪的灾异**）——通鉴 75 卷「梨花」唯一一处（文件闭域+年标题窗口机器断言）；淚痕恰一处（光啟二年御袍）V056 已用讫**零重开**（audit 硬卡不入引）；春怨/紗窗/金屋/空庭/不開門/黃鶯/遼西/妾夢/黃昏全零——梨花一段逐字入引为让渡形态判决证据' AS locator, '太后出梨花一枝以示宰相，宰相皆以為瑞。杜景儉獨曰：「今草木黃落，而此更發榮，陰陽不時，咎在臣等。」因拜謝。太后曰：「卿真宰相也！」' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-360-person' AS claim_id, 'source-quantangshi-768' AS source_id, '卷七百六十八·金昌緒编者附记整行「[[Author:金昌緒|金昌緒]]，餘杭人，詩一首。」逐字入引（**七史无传、总集编者一行小传**：與 V076 王之渙附记同款装置——王得「詩六首」金得「詩一首」；「餘杭人」全快照恰一机器断言；「金昌緒」快照唯 768 卷恰四处；劉方平快照恰两处全在锚/署名行只计数不入引——新源承载）' AS locator, '[[Author:金昌緒|金昌緒]]，餘杭人，詩一首。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（四句七绝 1/1/1/1 第九次） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-360-scene' AS background_id, 'text-work-t300-360-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-360-city' AS background_id, 'text-work-t300-360-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-360-world' AS background_id, 'text-work-t300-360-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-360-person' AS background_id, 'text-work-t300-360-ws' AS version_id, 4 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 77, 'Liu Fang-ping''s Spring Sorrow (work-t300-360) background layers (stage-D poem 58, one of two poems sharing the title in the anthology; four-line seven-character quatrain 1/1/1/1, ninth time): dating verdict fifty-two, thirty-eighth shape of the title-evidence series -- two Spring Sorrows in one anthology, three fates on the record. THE SAME-TITLE PAIR ON RECORD, first seen: the anthology carries two poems titled 春怨 -- t300-360 Liu Fang-ping (seven-character) and t300-043 Jin Changxu (five-character, "Hit the oriole off the branch") -- each with its own full work/text/claim/source stack (machine-asserted); their anthology pages each own a unique category quadruple in the whole 295-page corpus (seven-character and five-character runs, one page each -- curator action, not upgraded, V048). THREE FATES OF THE TITLE in the 118-volume Quan-Tangshi snapshot: the literal appears in exactly two volumes -- 143 (Wang Changling, anchor plus empty shell: counted only, never quoted) and 768 (Jin Changxu, inline full text quoted verbatim) -- while Liu''s base volume 251 is absent from the snapshot: the fetch log says "卷251: FAILED both name forms" exactly twice (both rounds; first-round window quoted) -- OUT-OF-CATALOG ZERO, second instance (paired with V075''s volume 256): the six clean lines scoring zero across 118 volumes is a snapshot zero, not a book zero. BASE-BOOK TWO STATES: volume 768 holds Jin''s poem INLINE (unlike V076''s volume-253 empty shell): anchor, poem body and an editors'' appendix mini-bio on one page. ALTERNATIVE TITLE, two witnesses, registered not adjudicated: 一作伊州歌 appears independently inside the volume-768 anchor ({{另|春怨|伊州歌}}) and in the anthology page''s title field ({{*}}, a closed set of exactly 20 pages); the 768 face and the anthology face differ line by line ({{另|啼時|幾時}} vs {{另|啼時|幾迴}}, 却 vs 卻) -- cross-face variant witnesses, second pair. THE STORED FACE IS THE READING FACE, second of its series: both poems were stored by V018 as the folded face of their anthology pages (欲 from the head of {{另|欲|又}}, both physical lines'' trailing spaces trimmed; Jin''s page folds twice: 打 from {{另|打|卻}}, 啼時 from {{另|啼時|幾迴}}) -- generator asserts the pair-join both directions for each page. Page form registered: the notes field of this page ends in a DOUBLE trailing space -- exactly one page in the whole corpus (machine-asserted); the {{唐詩三百首}} marker here hangs in the same line right after the header close (}}{{ form, a closed set of 145 pages), paired with V075''s standalone-body hang (59 pages): two hang styles, one ledger. WORLD: same-character-two-realms, twenty-second shape -- the conceded shape, first seen. The poem''s pear blossom: the Tongjian has exactly one (Yanzai 1, jiawu, 694: the empress dowager "sent a branch of pear blossom out to show the chancellors, and all the chancellors took it for an omen of fortune" while Du Jingjian alone said "now grass and trees are yellow and falling, yet this one blooms out of season -- the fault in the balance of yin and yang lies with us ministers", bowed and thanked; the history''s pear blossom is an anomaly so out of season it made a chancellor confess, the poem''s pear blossom is white all over the ground with nobody opening the door to see it). But the tears: the poem''s second line carries tear traces, and the Tongjian''s ledger of 淚痕 has exactly one entry (Guangqi 2, bingwu, 886: Xizong, sleeping under a plank, unfastened his imperial robe for Wang Jian "because it has tear traces on it") -- and that one entry was already quoted verbatim and used up by V056 (domain [''V056''] machine-asserted): for the first time in twenty-two shapes, this ledger was booked by a predecessor -- the migration registers the exhaustion and hard-asserts the closed sentence never re-enters any citation of this migration (audit). 春怨/紗窗/金屋/空庭/不開門/黃鶯/遼西/妾夢/黃昏 all zero in the Tongjian (machine-asserted). PERSON: ZERO-BIOGRAPHY PAIR, third and fourth of the series, first on one page: Liu Fang-ping and Jin Changxu score zero across the local history snapshots (2 JTS + 8 XTS + 3 QSS + 75 Tongjian, machine-asserted). Jin has one editors'' appendix line, quoted verbatim as this migration''s PERSON evidence (the same apparatus as V076''s Wang Zhihuan note: Wang got "six poems", Jin gets "one poem"; 餘杭人 appears exactly once in the whole snapshot). Liu has no note at all: 劉方平 appears in exactly two snapshot places, both anchor/byline lines (017 "====巫山高 劉方平著====" -- the "著"-style heading occurs 55 times corpus-wide, all in volume 017, machine-asserted, counted only, never quoted; 018 a byline): Liu keeps a name, Jin keeps one poem. NEW SOURCES: exactly one -- source-quantangshi-768, the volume page (second volume-page source ever, following V076; the audit asserts exactly one source insert and exactly one source delete in the rollback), while ws-t300-360 (second reuse), ws-t300-043 (second reuse) and the Tongjian events source are existing rows. Body use-ceiling, twenty-fifth instance: V018''s punctuated excerpt on this poem stands first and is never re-opened (hard assertion); likewise V018''s header-author excerpts for both pages and its punctuated excerpt for the sister poem stay closed. KNOWN zero honestly recorded (thirty-third instance -- both V018 text claims keep their KNOWN and stay untouched; audit reverse-asserts no KNOWN literal in this migration); closed precedent keywords (both punctuated full quotes, both header-author lines, V056''s tear-trace sentence, V075''s fetch-log line) stay out of all citations of this migration.'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 77);
COMMIT;
