-- V027：杜甫《登岳陽樓》(work-t300-231) 四层背景（阶段 D 第 9 首）。MySQL 5.6.40 兼容。
-- 只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V015、V018 已执行（work-t300-231 与其 text-work-t300-231-ws、source-ws-t300-231
--       都是 V018 的行；source-jiutangshu-dufu 是 V010/V011 的行；source-xintangshu-wenyi 是 V016 的行；
--       source-zizhi-tongjian-events 是 V015 的行——本迁移在同一通鉴来源上增引卷224，不另开行）。
--
-- 数据源（可复现）：emit_v027.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/登岳陽樓__杜甫_.txt（页内实测无 {{另|}} 异文——如实写明）、資治通鑑卷224、
--   全唐詩卷233（锚点+转引用桩+卷首作者注）、舊唐書卷190下、新唐書卷201。
--
-- 做：1 个新 source 登记（全唐詩卷233，PENDING——登记不等于核验）+
--   4 BACKGROUND content/claim/background + 10 组逐字引用 +
--   8 行 background_line（scene→1,2｜city→3,4｜world→5,6｜person→7,8，绑 text-work-t300-231-ws）。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不铸 time.span、不挂 written_during**——见下。
--
-- 诚实边界（这首的边界就是形状本身，同 V023/V024）：
--   * 系年两窗口互斥：旧唐书笔序指向永泰二年（766），新唐书系「大曆中」（766–779），
--     通行年谱（768）本地核不到不采信——time.span 与 written_during 一个都不造；
--     且两窗口都在安史乱事收场（763）之后，挂 written_during 是**肯定错的**，不是弃权；
--   * 注本不覆盖：《杜詩詳註》卷三–五快照实测连「岳陽」二字都没有（qss-卷03/04/05 grep 复核）；
--   * 楼名建制、洞庭建制零注家引用，正文不补；
--   * 页内异文实测无（ws 快照八句与 V018 入库正文全同）——没有异文也登记为「核过」；
--   * person 层 KNOWN 只覆盖两传事同年异的不矛盾部分（行舟/客耒阳/卒耒阳/年五十九，
--     V016 已按同一标准立过 person-du-fu 的并列卒年断言），不覆盖此诗属哪一窗口。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 26，不含 27
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-yy-%';              -- 空
--   SELECT id FROM poetry_text_version WHERE id='text-work-t300-231-ws';  -- 恰 1 行（V018 已执行）
--   SELECT id FROM poetry_source WHERE id='source-quantangshi-233';     -- 空
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-yy-%';        -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-231';                                  -- 8
--   SELECT certainty FROM poetry_claim WHERE id='claim-bg-yy-person';   -- KNOWN
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-231'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
-- 回滚: recovery/V027_rollback.sql（按 id 全枚举删除；不动 V018 的任何行，不动共用通鉴来源行）
START TRANSACTION;

-- ---------- 0. 来源登记（一律 PENDING：登记不等于核验） ----------
INSERT INTO poetry_source (id, title, author, edition, url, rights_note, verification_status, source_kind, reliability)
SELECT * FROM (
SELECT 'source-quantangshi-233' AS id, '《全唐詩》全唐詩/卷233（维基文库录入本）' AS title, NULL AS author, '全唐詩/卷233（维基文库《全唐詩》录入本）' AS edition, 'https://zh.wikisource.org/wiki/全唐詩/卷233' AS url, '维基文库录入本，公有领域古籍。本卷为杜甫大曆间诗卷，卷首 notes 标作者；本诗条目只有锚点+转引用桩，正文在诗页。本行由 emit_v027.py 对快照逐字定位。核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status, 'POETRY_COLLECTION' AS source_kind, 'HIGH' AS reliability FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_source x WHERE x.id = t.id);

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-yy-scene' AS id, 'BACKGROUND' AS entity_type, 'yy-scene' AS slug, '眼前：听说了很多年才站上的楼' AS title, '四层处境背景（阶段 D 第 9 首）；史实句均有逐字引证；系年两窗口并列（旧传 766／新传大曆中），不铸 time.span 不挂乱事线。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-yy-city' AS id, 'BACKGROUND' AS entity_type, 'yy-city' AS slug, '这段水：扁舟下峡与溯沅湘之间' AS title, '四层处境背景（阶段 D 第 9 首）；史实句均有逐字引证；系年两窗口并列（旧传 766／新传大曆中），不铸 time.span 不挂乱事线。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-yy-world' AS id, 'BACKGROUND' AS entity_type, 'yy-world' AS slug, '这个天下：京师戒严那年、兵变那年' AS title, '四层处境背景（阶段 D 第 9 首）；史实句均有逐字引证；系年两窗口并列（旧传 766／新传大曆中），不铸 time.span 不挂乱事线。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-yy-person' AS id, 'BACKGROUND' AS entity_type, 'yy-person' AS slug, '这个人：两史各给一个年份，都不采信' AS title, '四层处境背景（阶段 D 第 9 首）；史实句均有逐字引证；系年两窗口并列（旧传 766／新传大曆中），不铸 time.span 不挂乱事线。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-yy-scene' AS id, 'bg-yy-scene' AS subject_id, 'context' AS property_key, '迟登之叹为诗本文内证（起联昔闻/今上对举）；年份注本实测不覆盖且两史窗口互斥，正文并列，已声明边界。' AS value_text, 'INTERPRETATION' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-yy-city' AS id, 'bg-yy-city' AS subject_id, 'context' AS property_key, '江湘舟行两传各记一段（扁舟下峽/溯沅湘），岳阳在其间水路上为字面所及；楼名建制注本核不到，正文零注家引用。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-yy-world' AS id, 'bg-yy-world' AS subject_id, 'context' AS property_key, '768 吐蕃围灵州京师戒严、770 臧玠杀崔灌均有通鉴卷224 逐字（年标题分记）；戎马/兵变与凭轩之涕的对应是读法，正文标明。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-yy-person' AS id, 'bg-yy-person' AS subject_id, 'context' AS property_key, '晚年江湘行舟、客耒陽、卒耒陽年五十九——两唐书各记一段，事同而年号互异，不矛盾部分（行舟/耒阳/五十九）升 KNOWN（V016 两史标准）；certainty 不覆盖系年——旧传笔序指向 766、新传系大曆中，两窗口并列不裁决。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-yy-scene' AS subject_id, 'context' AS property_key, 'claim-bg-yy-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-yy-city' AS subject_id, 'context' AS property_key, 'claim-bg-yy-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-yy-world' AS subject_id, 'context' AS property_key, 'claim-bg-yy-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-yy-person' AS subject_id, 'context' AS property_key, 'claim-bg-yy-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-yy-scene' AS id, 'work-t300-231' AS work_id, 'SCENE' AS layer, '这一次是登临，而且登临本身就是诗眼：「昔聞洞庭水，今上岳陽樓。」——听说洞庭很多年了，今天才站上来；一「昔」一「今」之间隔着一生。
哪年上的楼，要靠年谱——本地注本实测不覆盖此诗，两唐书给出的年份还互相打架（见第 7、8 句那层），所以这里只说诗本文写得出的东西：一个久闻而迟登的人，把湖看进了诗里。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-yy-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-yy-city' AS id, 'work-t300-231' AS work_id, 'CITY' AS layer, '水比楼大：「吳楚東南坼，乾坤日夜浮。」——吴楚之地在东南裂开，天地日月在水上浮动；这是站在岳阳城头看洞庭的字面。楼的来历、湖的建制，注本核不到（本地快照实测无此诗），不补。
可核到的是他到这条水路上的路：《舊唐書》本传「扁舟下峽……泝沿湘流」，《新唐書》「出瞿唐，下江陵，溯沅、湘以登衡山」——两传同记这一程江湘舟行；岳阳正在下峡与溯沅湘之间的水路上。洞庭是他晚年的路过的地界，这由两传各自的原文说得定。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-yy-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-yy-world' AS id, 'work-t300-231' AS work_id, 'WORLD' AS layer, '「戎馬關山北」在通鑑里有对应的年月：大曆三年（戊申，公元七六八年）「九月，吐蕃眾數萬圍靈州，游騎至潘原、宜祿……京師戒嚴」——关山以北，京师的戒严令一年里贴了又揭。
而在他自己停舟的湖南，通鑑大曆五年（庚戌，公元七七零年）记「夏，四月，庚子，湖南兵馬使臧玠殺觀察使崔灌；澧州刺史楊子琳起兵討之，取賂而還」——乱事按史书算收了场，兵变却在湖广的衙门里接着发生。北望是戎马，舟下是兵变：凭轩所涕，通鑑同卷里两页都有得对。' AS body_text, 'SENIOR' AS audience, 'claim-bg-yy-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-yy-person' AS id, 'work-t300-231' AS work_id, 'PERSON' AS layer, '这首诗系于何年，本地核不实——两个窗口各出自一史，逐字可指，却互不相容：
窗口一：《舊唐書》本传的叙事里，江湘行舟之后接「永泰二年，啗牛肉白酒，一夕而卒於耒陽，時年五十九」——照旧传的笔序，这一程与卒都在 766。
窗口二：《新唐書》本传「大曆中，出瞿唐，下江陵，溯沅、湘以登衡山，因客耒陽」——江湘之程整个放进大曆（766–779），卒亦在其后。
通行年谱系此诗于大曆三年（768），落在窗口二之内，但年谱本地核不到，不采信。
两传可核而不打架的部分：扁舟下峡、溯沅湘、客耒陽、卒于耒陽、年五十九。年号各说，正文并列——一首诗收在「憑軒涕泗流」上，它的年份本身就是晚唐漂泊的一部分。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-yy-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文 ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-yy-scene' AS claim_id, 'source-ws-t300-231' AS source_id, '页面 登岳陽樓 (杜甫)（起二句逐字；页内实测无 {{另|}} 异文标记，八句与 V018 入库正文全同；全文见 V018 claim-t300-231-text 引文）' AS locator, '昔聞洞庭水，今上岳陽樓。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-yy-city' AS claim_id, 'source-ws-t300-231' AS source_id, '页面 登岳陽樓 (杜甫)（三四句逐字——洞庭水势为诗本文）' AS locator, '吳楚東南坼，乾坤日夜浮。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-yy-city' AS claim_id, 'source-jiutangshu-dufu' AS source_id, '卷一百九十下·杜甫传（江湘行舟段：避乱荆楚—扁舟下峡—江陵乱—溯沿湘流—游衡山—寓居耒阳，连续原文；窗口一系年语境）' AS locator, '甫以其家避亂荊、楚，扁舟下峽，未維舟而江陵亂，乃泝沿湘流，遊衡山，寓居耒陽。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-yy-city' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百一·文藝上·杜甫传（窗口二「大曆中」江湘段）' AS locator, '大曆中，出瞿唐，下江陵，溯沅、湘以登衡山，因客耒陽。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-yy-world' AS claim_id, 'source-ws-t300-231' AS source_id, '页面 登岳陽樓 (杜甫)（末二句逐字——「戎馬關山北」即本层对年的诗眼，通鑑两段所对）' AS locator, '戎馬關山北，憑軒涕泗流。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-yy-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '通鑑卷二百二十四·大曆三年標題+吐蕃圍靈州京師戒嚴段＋大曆五年標題+臧玠殺崔灌条；四段以「……」相連，年標題歸屬已分記' AS locator, '代宗睿文孝武皇帝中之上大曆三年（戊申，公元七六八年）……九月，吐蕃眾數萬圍靈州，游騎至潘原、宜祿；郭子儀自河中帥甲士三萬鎮涇陽，京師戒嚴。……代宗睿文孝武皇帝中之上大曆五年（庚戌，公元七七零年）……夏，四月，庚子，湖南兵馬使臧玠殺觀察使崔灌；澧州刺史楊子琳起兵討之，取賂而還。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-yy-person' AS claim_id, 'source-ws-t300-231' AS source_id, '页面 登岳陽樓 (杜甫)（header title+author 字段逐字——署名与组诗归属同 V025/V026 路数）' AS locator, '| title    = 登岳陽樓
| section  =
| author   = 杜甫' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-yy-person' AS claim_id, 'source-quantangshi-233' AS source_id, '页面 全唐詩/卷233（卷首 notes 作者注＋本诗锚点与转引用桩 {{:登岳陽樓 (杜甫)}}；卷页无正文，正文证据在诗页——同 V022/V025/V026 桩教训，定位已分记）' AS locator, '''''''杜甫''''''……==[[登岳陽樓 (杜甫)|登岳陽樓]]==
{{:登岳陽樓 (杜甫)}}' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-yy-person' AS claim_id, 'source-jiutangshu-dufu' AS source_id, '卷一百九十下·杜甫传（行舟段＋永泰二年耒阳卒句——窗口一 766 的出处；两段以「……」相連）' AS locator, '甫以其家避亂荊、楚，扁舟下峽，未維舟而江陵亂，乃泝沿湘流，遊衡山，寓居耒陽。……永泰二年，啗牛肉白酒，一夕而卒於耒陽，時年五十九。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-yy-person' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百一·文藝上·杜甫传（大曆中江湘段＋耒阳卒句——窗口二的出处；两段以「……」相連）' AS locator, '大曆中，出瞿唐，下江陵，溯沅、湘以登衡山，因客耒陽。……令嘗饋牛炙白酒，大醉，一昔卒，年五十九。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-yy-scene' AS background_id, 'text-work-t300-231-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-yy-scene' AS background_id, 'text-work-t300-231-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-yy-city' AS background_id, 'text-work-t300-231-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-yy-city' AS background_id, 'text-work-t300-231-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-yy-world' AS background_id, 'text-work-t300-231-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-yy-world' AS background_id, 'text-work-t300-231-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-yy-person' AS background_id, 'text-work-t300-231-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-yy-person' AS background_id, 'text-work-t300-231-ws' AS version_id, 8 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不铸 time.span / 不挂 written_during，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 27, 'du fu deng-yueyang-lou background layers (inserts-only): tongjian ju224 768 Tufan siege of Lingzhou with capital on alert plus 770 rebel assassination of the Hunan observer; both Tang histories carry the late river journey (down the gorges, upstream the Yuan and Xiang, lodging at Leiyang, dead aged 59) but their dating windows are mutually exclusive -- the JTS narrative order implies Yongtai-2 (766) while the XTS dates the journey to Da-li; the received chronology-year 768 is locally unverifiable and NOT adopted: deliberately NO time.span and NO written_during (both windows fall after the 763 end of the rebellion, so hanging written_during would be affirmatively wrong); ws page verified to carry no inline variants for this poem -- recorded as checked-and-clean'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 27);
COMMIT;
