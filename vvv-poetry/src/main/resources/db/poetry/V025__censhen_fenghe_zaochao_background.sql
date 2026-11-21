-- V025：岑参《奉和中書舍人賈至早朝大明宮》(work-t300-299) 四层背景（阶段 D 第 7 首）。MySQL 5.6.40 兼容。
-- 只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V015、V017、V018 已执行（work-t300-299 与其 text-work-t300-299-ws 都是 V018 的行；
--       source-zizhi-tongjian-events 是 V015 的行（V017 已增引卷218，本迁移增引卷220）；
--       event-anshi-rebellion 是 V004/V015 的行）。
--
-- 数据源（可复现）：emit_v025.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/奉和中書舍人賈至早朝大明宮.txt（页内 {{另|}} 异文标记照登）、
--   杜詩詳註(四庫全書本)卷05（注本正文——本诗以「附岑參詩」收在杜甫条内）、
--   資治通鑑卷220、全唐詩卷201（锚点+转引用桩+卷首作者注）。
--
-- 做：2 个新 source 登记（杜詩詳註卷五／全唐詩卷201，一律 PENDING——登记不等于核验）+
--   4 BACKGROUND content/claim/background + 9 组逐字引用 + 系年 claim（time.span LIKELY）+
--   written_during 安史挂接 + 8 行 background_line（scene→1,2｜city→3,4｜world→5,6｜person→7,8，
--   绑 text-work-t300-299-ws）。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log。
--
-- 诚实边界：
--   * 系年为注本单源：仇注系年句附在**杜甫**奉和条（「此{{YL|乾元元年}}春在諫省作」），
--     岑参诗条本身无系年——唱和同一集会为内证，合推 LIKELY（V019 鹤注先例）；
--   * 岑参本传本地核不到：两唐书文苑/文艺实测无传；PERSON 层只写署名三证与唱和集团，
--     KNOWN 不覆盖生平；
--   * 全唐詩卷201 对本诗只有锚点+转引用桩（无正文）——署名第二证走卷首作者注；
--   * 页内异文 色/欲、闕/鎖、迎/明 只登记（tang300-variants.md）；草堂本「春色夜闌」
--     为注本别出异读，照登不裁决；
--   * 仇注「合觀四作」高下之判是注家读法，照登不裁决。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 24，不含 25
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-hz-%';              -- 空
--   SELECT id FROM poetry_text_version WHERE id='text-work-t300-299-ws';  -- 恰 1 行（V018 已执行）
--   SELECT id FROM poetry_source WHERE id IN ('source-dushi-xiangzhu-05','source-quantangshi-201');  -- 空
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-hz-%';        -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-299';                                  -- 8
--   SELECT certainty FROM poetry_claim WHERE id='claim-bg-hz-person';   -- KNOWN
--   SELECT certainty FROM poetry_claim WHERE id='claim-hz-time-758';    -- LIKELY
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-299'
--     AND predicate='written_during';                                   -- 1
-- 回滚: recovery/V025_rollback.sql（按 id 全枚举删除；不动 V018 的任何行，不动共用通鉴来源行）
START TRANSACTION;

-- ---------- 0. 来源登记（一律 PENDING：登记不等于核验） ----------
INSERT INTO poetry_source (id, title, author, edition, url, rights_note, verification_status, source_kind, reliability)
SELECT * FROM (
SELECT 'source-dushi-xiangzhu-05' AS id, '《杜詩詳註》卷五（清仇兆鰲注）' AS title, '仇兆鰲' AS author, '欽定四庫全書本（维基文库录入本，页面标注需据扫描版校对；{{YL|}}、{{SK notes|}}、{{SKchar|}} 等录入标记在引文中原样保留）' AS edition, 'https://zh.wikisource.org/wiki/杜詩詳註_(四庫全書本)/卷05' AS url, '公有领域古籍。卷五恰是「早朝大明宮」组诗所在——岑参诗无本传，却以「附岑參詩」收在杜甫条内，是这首诗最重要的本地注本证据。reliability 不代表已核验。' AS rights_note, 'PENDING' AS verification_status, 'YEAR_BOOK' AS source_kind, 'MEDIUM' AS reliability FROM DUAL
UNION ALL
SELECT 'source-quantangshi-201' AS id, '《全唐詩》全唐詩/卷201（维基文库录入本）' AS title, NULL AS author, '全唐詩/卷201（维基文库《全唐詩》录入本）' AS edition, 'https://zh.wikisource.org/wiki/全唐詩/卷201' AS url, '维基文库录入本，公有领域古籍。本卷为岑参诗卷，卷首 notes 标作者；本诗条目只有锚点+转引用桩，正文在诗页。本行由 emit_v025.py 对快照逐字定位。核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status, 'POETRY_COLLECTION' AS source_kind, 'HIGH' AS reliability FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_source x WHERE x.id = t.id);

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-hz-scene' AS id, 'BACKGROUND' AS entity_type, 'hz-scene' AS slug, '眼前：天没亮的那场朝会' AS title, '四层处境背景（阶段 D 第 7 首·第一首非杜甫）；史实句均有逐字引证；系年依仇注（附杜甫条）给 LIKELY；岑参本传两唐书实测无传，写成边界。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-hz-city' AS id, 'BACKGROUND' AS entity_type, 'hz-city' AS slug, '这座宫：改了几轮名的明宫' AS title, '四层处境背景（阶段 D 第 7 首·第一首非杜甫）；史实句均有逐字引证；系年依仇注（附杜甫条）给 LIKELY；岑参本传两唐书实测无传，写成边界。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-hz-world' AS id, 'BACKGROUND' AS entity_type, 'hz-world' AS slug, '这个年号：刚改元乾元的那年春天' AS title, '四层处境背景（阶段 D 第 7 首·第一首非杜甫）；史实句均有逐字引证；系年依仇注（附杜甫条）给 LIKELY；岑参本传两唐书实测无传，写成边界。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-hz-person' AS id, 'BACKGROUND' AS entity_type, 'hz-person' AS slug, '这组诗：一倡三和与推不出的高下' AS title, '四层处境背景（阶段 D 第 7 首·第一首非杜甫）；史实句均有逐字引证；系年依仇注（附杜甫条）给 LIKELY；岑参本传两唐书实测无传，写成边界。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-hz-scene' AS id, 'bg-hz-scene' AS subject_id, 'context' AS property_key, '早朝场景为诗本文内证（题「奉和…早朝大明宮」+通篇候朝景物）；殿名/年份另层给，正文已声明边界。' AS value_text, 'INTERPRETATION' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-hz-city' AS id, 'bg-hz-city' AS subject_id, 'context' AS property_key, '大明宫建置沿革为仇注引旧唐书原文（四库本录入快照逐字，{{YL|}} 标记照登）；属注本转引正史——单链但逐字可指，故 LIKELY 不升 KNOWN。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-hz-world' AS id, 'bg-hz-world' AS subject_id, 'context' AS property_key, '乾元元年年标题与改元句有通鉴卷220 逐字（本迁移在同一通鉴来源上增引卷220，沿用 V017「增引不另开行」规矩）；诗不写乱事与史书战事的并置已标明是读法。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-hz-person' AS id, 'bg-hz-person' AS subject_id, 'context' AS property_key, '署名三证（ws header author 字段／全唐詩卷201 作者注／杜詩詳註附岑參詩段）互不矛盾逐字可指，升 KNOWN；certainty 只覆盖署名与唱和集团（一倡三和四首俱在），不覆盖岑参生平——两唐书本传实测无岑参，正文已声明。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-hz-scene' AS subject_id, 'context' AS property_key, 'claim-bg-hz-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-hz-city' AS subject_id, 'context' AS property_key, 'claim-bg-hz-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-hz-world' AS subject_id, 'context' AS property_key, 'claim-bg-hz-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-hz-person' AS subject_id, 'context' AS property_key, 'claim-bg-hz-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-hz-scene' AS id, 'work-t300-299' AS work_id, 'SCENE' AS layer, '这首诗本身就是一场天没亮的朝会。鸡叫了，京路上曙光还寒，莺声把春色啼到将尽，金阙的晓钟开万户，玉阶前的仙仗拥着千官——全诗八句几乎全是候朝的景物；题目把来由写得明白：「奉和中書舍人賈至早朝大明宮」，是和人家的「早朝大明宮」。
哪座殿、哪一年朝会，要靠注本与史书——这一层只说诗本文写得出的东西：天未亮而百官已列，诗写的是等待。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-hz-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-hz-city' AS id, 'work-t300-299' AS work_id, 'CITY' AS layer, '诗里的大明宮、金闕、玉階、仙仗都是朝堂名物，其中那座宫有自己的来历。仇注在组诗注里引《舊唐書》：「東内大明宮在禁苑之東南，本永安宫，貞觀八年置，九年改大明宮，龍朔二年號蓬萊宮，咸亨元年改含元宮，尋復大明宮，正殿曰含元殿，天后改大明殿」（{{YL|}} 录入标记照登于引文）。改名几轮，朝会照旧——「金闕曉鐘」敲的是这座几经改名的宫。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-hz-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-hz-world' AS id, 'work-t300-299' AS work_id, 'WORLD' AS layer, '这首早朝诗的年份在通鑑里有名有姓：乾元元年（戊戌，公元七五八年）年标题之下，「丁未，上御明鳳門，赦天下，改元。盡免百姓今載租、庸」——写这首诗的这一开春，朝廷刚改元乾元。
朝会之前，战争刚收复了两京，但收而复来，乱事没完（通鑑卷220 同年连着记两京之外的仗）。诗里一个字的仗都没有：鸡鸣钟声是太平朝仪——这正是安史乱中早朝诗的张力。两页并置是读法，通鑑的记事摆在那里。' AS body_text, 'SENIOR' AS audience, 'claim-bg-hz-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-hz-person' AS id, 'work-t300-299' AS work_id, 'PERSON' AS layer, '岑参的本传本地核不到——旧唐书文苑（卷190上/中/下）、新唐书文艺（卷201–203）实测都没有他的传。所以这一层说这组诗本身：賈至任中書舍人，作「早朝大明宮呈兩省僚友」为原唱（附賈至詩），王維、岑参、杜甫各有奉和——王維和作也在《唐詩三百首》里（第 140 首），賈至原唱与杜甫和作都在《杜詩詳註》的附段里逐字保存。仇注总评四首：「合觀四作，賈首倡殊平平，三和俱有奪席之意……王岑秀色可攬……故當推為擅塲」——注家的高下之判是读法，照登不裁决。
「獨有鳳皇池上客」说的是賈至：仇注引《晉書》荀朂傳「奪我鳯凰池，諸君賀我耶」，鳳池是中書省的省称。这首诗的署名有三处互不相犯的记载：维基文库诗页 header 的 author 字段、《全唐詩》卷201 的卷首作者注、《杜詩詳註》的「附岑參詩」段——三处同指岑参。署名与唱和集团可核到；岑参这一生，本地核不到，不写。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-hz-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文 ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-hz-scene' AS claim_id, 'source-ws-t300-299' AS source_id, '页面 奉和中書舍人賈至早朝大明宮（起二句逐字；页内异文标记 {{另|色|欲}} 原样引，登记 corpus/tang300-variants.md 不裁决；八句全文见 V018 claim-t300-299-text 引文）' AS locator, '雞鳴紫陌曙光寒，鶯囀皇州春{{另|色|欲}}闌。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-hz-scene' AS claim_id, 'source-dushi-xiangzhu-05' AS source_id, '杜詩詳註卷五（页内另两对页内异文的注本对应：第三行「闕/鎖」仇注无注、第五行「迎/明」仇注无注——此条只登草堂异读所系处）' AS locator, '金{{另|闕|鎖}}曉鐘開萬戶，……花{{另|迎|明}}劒珮星初落，' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-hz-city' AS claim_id, 'source-dushi-xiangzhu-05' AS source_id, '杜詩詳註卷五·組詩注条（引「舊唐書」大明宫建置；{{YL|}} 标记照登）' AS locator, '舊唐書東内大明宮在禁苑之東南本永安宫{{YL|貞觀八年}}置九年改大明宮{{YL|龍朔二年}}號蓬萊宮{{YL|咸亨元年}}改含元宮尋復大明宮正殿曰含元殿天后改大明殿' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-hz-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '通鑑卷二百二十·乾元元年（戊戌，公元七五八年）年標題＋二月改元句（本迁移在同一通鉴来源上增引卷220，沿用 V017 增引卷218 的「不另开来源行」规矩）' AS locator, '肅宗文明武德大聖大宣孝皇帝中之下乾元元年（戊戌，公元七五八年）……丁未，上御明鳳門，赦天下，改元。盡免百姓今載租、庸。復以載為年。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-hz-person' AS claim_id, 'source-ws-t300-299' AS source_id, '页面 奉和中書舍人賈至早朝大明宮（header title+author 字段逐字）' AS locator, '| title    = 奉和中書舍人賈至早朝大明宮
| section  = 
| author   = 岑參' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-hz-person' AS claim_id, 'source-quantangshi-201' AS source_id, '页面 全唐詩/卷201（卷首 notes 作者注＋本诗锚点与转引用桩 {{:…}}；卷页无正文，正文证据在诗页——同 V022 卷227 桩教训，定位已分记）' AS locator, '''''''岑參''''''……==[[奉和中書舍人賈至早朝大明宮]]==
{{:奉和中書舍人賈至早朝大明宮}}' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-hz-person' AS claim_id, 'source-dushi-xiangzhu-05' AS source_id, '杜詩詳註卷五·杜甫奉和条「附岑參詩」正文段＋賈至原唱条标（早朝…呈兩省僚友＋附賈至詩）＋杜甫和詩注条引晉書凤池典＋組詩总评「合觀四作」段；四段以「……」相連，各段归属已在定位分記' AS locator, '雞鳴紫陌曙光寒鶯囀皇州春色{{SK notes|草堂作夜}}闌金闕曉鐘開萬户玉階仙仗擁千官花迎劍佩星初落柳拂旌旗露未乾{{SK notes|音干}}獨有鳯凰池上客陽春一曲和{{SK notes|去聲}}皆難……{{SK anchor|早朝}}{{SK notes|音潮}}大明宮呈兩省僚友{{SK notes|附賈至詩}}……晉書荀朂傳朂乆在中書專管機事及失之甚罔罔悵悵或有賀之者朂曰奪我鳯凰池諸君賀我耶……合觀四作賈首倡殊平平三和俱有奪席之意就三詩論之杜老氣無前王岑秀色可攬一則三春穠李一則千尺喬松結語用事天然凑泊故當推為擅塲' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-hz-time-758' AS claim_id, 'source-dushi-xiangzhu-05' AS source_id, '杜詩詳註卷五·杜甫奉和条注系年句（「此乾元元年春在諫省作」附在杜甫奉和条上，非岑参诗条原文——唱和同一集会为内证，注本单源）' AS locator, '{{SK notes|此{{YL|乾元元年}}春在諫省作' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-hz-in-anshi' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '通鑑卷二百二十·乾元元年（戊戌，公元七五八年）年標題（758 在 755–763 乱期内的纪年锚）' AS locator, '肅宗文明武德大聖大宣孝皇帝中之下乾元元年（戊戌，公元七五八年）' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-hz-scene' AS background_id, 'text-work-t300-299-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-hz-scene' AS background_id, 'text-work-t300-299-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-hz-city' AS background_id, 'text-work-t300-299-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-hz-city' AS background_id, 'text-work-t300-299-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-hz-world' AS background_id, 'text-work-t300-299-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-hz-world' AS background_id, 'text-work-t300-299-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-hz-person' AS background_id, 'text-work-t300-299-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-hz-person' AS background_id, 'text-work-t300-299-ws' AS version_id, 8 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 系年 claim（work 主语，V022 同款：合推 → LIKELY）+ 选定 ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-hz-time-758' AS id, 'work-t300-299' AS subject_id, 'time.span' AS property_key,
       '758..758 (EXACT) 乾元元年春说：仇注系年句「此乾元元年春在諫省作」附于杜甫同组和作（唱和同一集会为内证）+通鉴卷220 年标题为纪年锚；注本单源合推，非年谱原文——同 V019 鹤注先例给 LIKELY' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'work-t300-299' AS subject_id, 'time.span' AS property_key, 'claim-hz-time-758' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x
                  WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 7. 乱期挂接（event.name 断言 + written_during 关系，V022 同款形状） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-hz-in-anshi' AS id, 'work-t300-299' AS subject_id, 'event.name' AS property_key,
       '安史之亂（755–763）。係年758在亂期內（通鑑卷220 乾元元年標題）；此诗是乱中朝廷的早朝声景，诗本文不写战事' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'work-t300-299' AS subject_id, 'event.name' AS property_key, 'claim-hz-in-anshi' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x
                  WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);
INSERT INTO poetry_relation (id, subject_id, predicate, object_id, claim_id)
SELECT * FROM (
SELECT 'rel-work-t300-299-written-during-anshi' AS id, 'work-t300-299' AS subject_id,
       'written_during' AS predicate, 'event-anshi-rebellion' AS object_id,
       'claim-hz-in-anshi' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_relation x
                  WHERE x.id = t.id OR (x.subject_id = t.subject_id AND x.predicate = t.predicate
                                        AND x.object_id = t.object_id));

-- ---------- 8. 版本账本 ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 25, 'cen-shen fenghe zaochao-daminggong background layers (inserts-only): first non-Du poem in stage D; four-poem court-verse group (Jia Zhi original plus Wang Wei, Cen Shen, Du Fu responses) evidenced across ws page header, quan tangshi vol201 volume note with transclusion-stub entry, and dushi xiangzhu ju5 which copies the poem as an appendix under the Du Fu entry; tongjian ju220 Qianyuan-1 year title and amnesty; time.span LIKELY from commentary dating attached to the Du Fu poem of the same gathering (single-source, precedent V019); KNOWN limited to attribution and the group, Cen Shen biography verified absent in both Tang history anthologies'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 25);
COMMIT;
