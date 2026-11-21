-- V028：陳子昂《登幽州臺歌》(work-t300-002) 四层背景 + 乱前事件线首点（阶段 D 第 10 首）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V015、V018 已执行（work-t300-002 与其 text-work-t300-002-ws、source-ws-t300-002
--       都是 V018 的行；source-jiutangshu-wenyuan / source-xintangshu-wenyi 是 V016 的行；
--       source-zizhi-tongjian-events 是 V015 的行——本迁移在同一通鉴来源上增引卷205/206，不另开行）。
--
-- 数据源（可复现）：emit_v028.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/登幽州臺歌.txt（页内实测无 {{另|}} 异文——如实写明）、資治通鑑卷205/206、
--   全唐詩卷083（卷首叙+锚点+转引用桩）、舊唐書卷190中、新唐書卷202（仅作无本传的旁证）。
--
-- 做：1 个新 source 登记（全唐詩卷083，PENDING——登记不等于核验）+
--   1 个新 EVENT 实体（营州契丹之乱，V015 同构）+ 其 time.span claim（KNOWN，通鉴年标题直证）
--   及其 1 组逐字引用（主键唯一）+
--   4 BACKGROUND content/claim/background + 8 组逐字引用（(claim,source) 主键每对恰一行）+
--   8 行 background_line（scene→1,2｜city→3,4｜world→5,6｜person→7,8，绑 text-work-t300-002-ws）。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「本传没提这首诗」）：
--   * 两唐书与通鉴**无一字**提及《登幽州臺歌》——北征幕中作诗是后世年谱说，本地核不到：
--     time.span/event.name/written_during 一个都不造（V023/V024/V027 形状断言 + 本文件
--     零 relation 断言守死）；事件实体挂战事本体（696–697 通鉴年标题直证 KNOWN），不向诗外溢；
--   * 新唐书文艺传无陈子昂本传（xts-卷201/202/203 全检索，仅卷202 萧颖士传一句提及）——
--     阶段 D 首个单传诗人：凡只见于全唐詩卷首叙者（碎琴）不升，KNOWN 只给两源同记处；
--   * ws 诗页快照实测无页内异文（无 {{另|}}，四句与 V018 入库正文全同）——没有异文也登记为「核过」，
--     tang300-variants.md 不开「无」行；
--   * 台的建制（黄金台/蓟北楼后世说）零引用不写。
--
-- 干支对账：696=丙申、697=丁酉（audit-migrations.py 检查4 同源复核）。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 27，不含 28
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-yz-%' OR id='event-tang-khitans-invasion';  -- 空
--   SELECT id FROM poetry_text_version WHERE id='text-work-t300-002-ws';  -- 恰 1 行（V018 已执行）
--   SELECT id FROM poetry_source WHERE id='source-quantangshi-083';     -- 空
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-yz-%';        -- 4
--   SELECT COUNT(*) FROM poetry_content WHERE id='event-tang-khitans-invasion';  -- 1
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-002';                                  -- 8
--   SELECT certainty FROM poetry_claim WHERE id='claim-bg-yz-person';   -- KNOWN
--   SELECT certainty FROM poetry_claim WHERE id='claim-event-tang-khitans-invasion-time';  -- KNOWN
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-002'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-002';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id IN ('claim-bg-yz-scene','claim-bg-yz-city','claim-bg-yz-world',
--                        'claim-bg-yz-person','claim-event-tang-khitans-invasion-time')
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
-- 回滚: recovery/V028_rollback.sql（按 id 全枚举删除；不动 V018 的任何行，不动共用通鉴/两唐书来源行）
START TRANSACTION;

-- ---------- 0. 来源登记（一律 PENDING：登记不等于核验） ----------
INSERT INTO poetry_source (id, title, author, edition, url, rights_note, verification_status, source_kind, reliability)
SELECT * FROM (
SELECT 'source-quantangshi-083' AS id, '《全唐詩》全唐詩/卷083（维基文库录入本）' AS title, NULL AS author, '全唐詩/卷083（维基文库《全唐詩》录入本）' AS edition, 'https://zh.wikisource.org/wiki/全唐詩/卷083' AS url, '维基文库录入本，公有领域古籍。本卷为陈子昂诗卷，卷首 Collection header notes 标作者 ''''''陳子昂'''''' 并有整段卷首叙（旧传之外独立的第二传状来源）。本诗条目只有锚点+转引用桩，正文在诗页。本行由 emit_v028.py 对快照逐字定位。核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status, 'POETRY_COLLECTION' AS source_kind, 'HIGH' AS reliability FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_source x WHERE x.id = t.id);

-- ---------- 1. 事件实体（阶段 D 首个安史乱前战事；V015 同构，通鉴年标题直证 KNOWN） ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, start_year, end_year, time_precision)
SELECT * FROM (
SELECT 'event-tang-khitans-invasion' AS id, 'EVENT' AS entity_type, 'khitans-invasion' AS slug, '营州契丹之乱（李尽忠、孙万荣）' AS title, '万岁通天元年（696）营州契丹松漠都督李尽忠、归诚州刺史孙万荣举兵反，攻陷营州；唐军讨之于硖石谷，全军皆没。神功元年（697）王孝傑十七万军覆于东硖石谷，武攸宜军渔阳不敢进，幽州为契丹所陷；同年孙万荣为奴所杀，制以契丹初平。' AS summary, 696 AS start_year, 697 AS end_year, 'RANGE' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-event-tang-khitans-invasion-time' AS id, 'event-tang-khitans-invasion' AS subject_id, 'time.span' AS property_key, '696..697 (RANGE) 起：通鉴卷205 万岁通天元年（丙申，公元六九六年）「李盡忠、孫萬榮舉兵反，攻陷營州」；讫：卷206 神功元年（丁酉，公元六九七年）「孫萬榮為奴所殺」「制以契丹初平」——起讫同年标题直证' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'event-tang-khitans-invasion' AS subject_id, 'time.span' AS property_key, 'claim-event-tang-khitans-invasion-time' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-event-tang-khitans-invasion-time' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '通鑑卷二百零五·万岁通天元年标题+起兵陷营州条+硖石谷全军没句＋卷二百零六·神功元年标题+东硖石谷孝傑死条+孙万荣见杀句+制以契丹初平短语；六段以「……」相連，年標題歸屬已分記' AS locator, '則天順聖皇后中之上萬歲通天元年（丙申，公元六九六年）……夏，五月，壬子，營州契丹松漠都督李盡忠、歸誠州刺史孫萬榮舉兵反，攻陷營州，殺都督趙文翽。……契丹伏兵於中道邀之，全軍皆沒。……則天順聖皇后中之下神功元年（丁酉，公元六九七年）……春，三月，戊申，清邊道總管王孝傑、蘇宏暉等將兵十七萬與孫萬榮戰於東硤石谷，唐兵大敗，孝傑死之。……甲午，孫萬榮為奴所殺。……制以契丹初平' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 2. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-yz-scene' AS id, 'BACKGROUND' AS entity_type, 'yz-scene' AS slug, '眼前：二十五个字的一哭' AS title, '四层处境背景（阶段 D 第 10 首）；史实句均有逐字引证；系年全部缺席——两唐书与通鉴无一字提及此诗；新唐书无本传为单传边界。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-yz-city' AS id, 'BACKGROUND' AS entity_type, 'yz-city' AS slug, '这座城：契丹攻陷过的幽州' AS title, '四层处境背景（阶段 D 第 10 首）；史实句均有逐字引证；系年全部缺席——两唐书与通鉴无一字提及此诗；新唐书无本传为单传边界。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-yz-world' AS id, 'BACKGROUND' AS entity_type, 'yz-world' AS slug, '这个天下：安史乱前的六十年' AS title, '四层处境背景（阶段 D 第 10 首）；史实句均有逐字引证；系年全部缺席——两唐书与通鉴无一字提及此诗；新唐书无本传为单传边界。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-yz-person' AS id, 'BACKGROUND' AS entity_type, 'yz-person' AS slug, '这个人：本传没提这首诗' AS title, '四层处境背景（阶段 D 第 10 首）；史实句均有逐字引证；系年全部缺席——两唐书与通鉴无一字提及此诗；新唐书无本传为单传边界。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 3. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-yz-scene' AS id, 'bg-yz-scene' AS subject_id, 'context' AS property_key, '四句本文的内证（古今/天地的对举）；写作缘由本传无一字，正文只给坐标不给因果，已声明边界。' AS value_text, 'INTERPRETATION' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-yz-city' AS id, 'bg-yz-city' AS subject_id, 'context' AS property_key, '696 武攸宜出师、其在军中参谋上疏、697 幽州陷落诸条通鉴逐字（年标题归属已分记）；旧传管记句逐字；台之建制核不到零引用。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-yz-world' AS id, 'bg-yz-world' AS subject_id, 'context' AS property_key, '起于 696「舉兵反攻陷營州」与全军没、697 东硖石谷王孝傑死、孙万荣见杀、契丹初平，通鉴卷205/206 逐字（年标题归属已分记）；诗与战事无逐字因果关联——正文只并置不断言，事件实体挂战事本体不挂诗。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-yz-person' AS id, 'bg-yz-person' AS subject_id, 'context' AS property_key, '籍贯（梓州射洪）、管记北讨、忧愤而卒——旧传与全唐詩卷首叙逐字一致处升 KNOWN；certainty 不覆盖只见于卷首叙的碎琴段、不覆盖任何系年；新唐书无本传（xts-卷201/202/203 实测）——两史并列标准用不上，单传边界写明。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-yz-scene' AS subject_id, 'context' AS property_key, 'claim-bg-yz-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-yz-city' AS subject_id, 'context' AS property_key, 'claim-bg-yz-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-yz-world' AS subject_id, 'context' AS property_key, 'claim-bg-yz-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-yz-person' AS subject_id, 'context' AS property_key, 'claim-bg-yz-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 4. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-yz-scene' AS id, 'work-t300-002' AS work_id, 'SCENE' AS layer, '四句、二十五个字，没有题目里的故事：「前不見古人，後不見來者。念天地之悠悠，獨愴然而涕下。」往前看不见古人，往后看不见来者，天地无穷，一个人站在高处哭了。
这首诗「为什么写」，本传里没有一句话直接回答——本传甚至通篇没提这首诗（见第 7、8 句那层）。能核到的只有一件事：他登的幽州，在通鉴里有一段对得上年月的战事。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-yz-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-yz-city' AS id, 'work-t300-002' AS work_id, 'CITY' AS layer, '幽州是战区的城。通鉴万岁通天元年（丙申，公元六九六年）记朝廷「以同州刺史建安王武攸宜為右武威衛大將軍，充清邊道行軍大總管，以討契丹」；神功元年（丁酉，公元六九七年）记「武攸宜軍漁陽，聞孝傑等敗沒，軍中震恐，不敢進。契丹乘勝寇幽州，攻陷城邑，剽掠吏民，攸宜遣將擊之，不克」——幽州被契丹攻陷过，主帅在渔阳按兵不动。
台的建制（黄金台、蓟北楼，都是后世说法）本地核不到，不写。核得到的是：陈子昂就在这支军队里——旧传「武攸宜統軍北討契丹，以子昂爲管記，軍中文翰皆委之」，通鉴「右拾遺陳子昂為攸宜府參謀，上疏曰」还留了他反对以罪人奴兵凑数的一段原话。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-yz-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-yz-world' AS id, 'work-t300-002' AS work_id, 'WORLD' AS layer, '这是安史之乱六十年前的事，本库的事件线第一次走到乱前：万岁通天元年（丙申，公元六九六年）「營州契丹松漠都督李盡忠、歸誠州刺史孫萬榮舉兵反，攻陷營州」，当年「契丹伏兵於中道邀之，全軍皆沒」；神功元年（丁酉，公元六九七年）三月「清邊道總管王孝傑、蘇宏暉等將兵十七萬與孫萬榮戰於東硤石谷，唐兵大敗，孝傑死之」，同年「甲午，孫萬榮為奴所殺」，朝廷随即「制以契丹初平」论功行赏——本迁移把这两年立成事件线锚点 event-tang-khitans-invasion。
幽州城在这两年里是前线。但要说清边界：通鉴记的是战场，本传记的是他在那支军队里，没有任何一条史料说这首诗为这场战事而作——并置是给读者的坐标，不是因果。' AS body_text, 'SENIOR' AS audience, 'claim-bg-yz-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-yz-person' AS id, 'work-t300-002' AS work_id, 'PERSON' AS layer, '陈子昂，梓州射洪人——旧传与全唐詩卷首叙同记。旧传记他早年：「初爲《感遇詩》三十首，京兆司功王適見而驚曰：『此子必爲天下文宗矣！』由是知名」；卷首叙另记一段碎琴扬名的市井传说（「有賣胡琴者…一日之內，名滿都下」），两源各记一路，不合并。
仕履核得而不矛盾的：则天召见拜麟臺正字（旧传），数上书迁右拾遗（卷首叙），武攸宜北讨表为管记（两源同记），父被县令段簡所辱、闻之还乡、被收繫狱中、「憂憤而卒，時年四十餘」（两源同记）。
边界两条硬杠：新唐书文艺传**没有**陈子昂本传（卷201/202/203 全检，仅萧颖士传一句「所許可當世者，陳子昂、富嘉謨、盧藏用之文辭」可作他身后的旁证）——所以凡只见于《全唐詩》卷首叙的说法（如碎琴）一律不升；而本传通篇不提《登幽州臺歌》，这首诗作于何年、是否作于北征幕中，**两唐书与通鉴无一字**——不铸系年。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-yz-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 5. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-yz-scene' AS claim_id, 'source-ws-t300-002' AS source_id, '页面 登幽州臺歌（起二句+末二句逐字以「……」相連；页内实测无 {{另|}} 异文标记，四句与 V018 入库正文全同；全文另见 V018 claim-t300-002-text 引文）' AS locator, '前不見古人，後不見來者。……念天地之悠悠，獨愴然而涕下。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-yz-city' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '通鑑卷二百零五·万岁通天元年标题+武攸宜出师条+陈子昂参谋上疏句＋卷二百零六·神功元年标题+渔阳不敢进/幽州陷落条；五段以「……」相連，年標題歸屬已分記' AS locator, '則天順聖皇后中之上萬歲通天元年（丙申，公元六九六年）……以同州刺史建安王武攸宜為右武威衛大將軍，充清邊道行軍大總管，以討契丹。……右拾遺陳子昂為攸宜府參謀，上疏曰：「恩制免天下罪人及募諸色奴充兵討擊契丹，此乃捷急之計，非天子之兵。……則天順聖皇后中之下神功元年（丁酉，公元六九七年）……武攸宜軍漁陽，聞孝傑等敗沒，軍中震恐，不敢進。契丹乘勝寇幽州，攻陷城邑，剽掠吏民，攸宜遣將擊之，不克。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-yz-city' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十中·文苑中·陈子昂传（管记段——军中文翰皆委之）' AS locator, '俄授麟臺正字。武攸宜統軍北討契丹，以子昂爲管記，軍中文翰皆委之。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-yz-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '通鑑卷二百零五·万岁通天元年标题+起兵陷营州条+硖石谷全军没句＋卷二百零六·神功元年标题+东硖石谷孝傑死条+孙万荣见杀句+制以契丹初平短语；七段以「……」相連，年標題歸屬已分記（事件线战事本体证据；诗不挂 written_during）' AS locator, '則天順聖皇后中之上萬歲通天元年（丙申，公元六九六年）……夏，五月，壬子，營州契丹松漠都督李盡忠、歸誠州刺史孫萬榮舉兵反，攻陷營州，殺都督趙文翽。……契丹伏兵於中道邀之，全軍皆沒。……則天順聖皇后中之下神功元年（丁酉，公元六九七年）……春，三月，戊申，清邊道總管王孝傑、蘇宏暉等將兵十七萬與孫萬榮戰於東硤石谷，唐兵大敗，孝傑死之。……甲午，孫萬榮為奴所殺。……制以契丹初平' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-yz-person' AS claim_id, 'source-ws-t300-002' AS source_id, '页面 登幽州臺歌（header title+author 字段逐字——署名第三证，V018 T1_TITLE 路数的逐字切片）' AS locator, '| title    = 登幽州臺歌
| section  =
| author   = 陳子昂' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-yz-person' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十中·文苑中·陈子昂传（籍贯段＋感遇诗/王适叹＋召见拜官句＋管记段＋忧愤卒段＋史臣语；六段以「……」相連，出处同卷同传）' AS locator, '陳子昂，梓州射洪人。家世富豪。……初爲《感遇詩》三十首，京兆司功王適見而驚曰：「此子必爲天下文宗矣！」由是知名。……則天召見，奇其對，拜麟臺正字。……俄授麟臺正字。武攸宜統軍北討契丹，以子昂爲管記，軍中文翰皆委之。……子昂父在鄉，爲縣令段簡所辱，子昂聞之，遽還鄉里。簡乃因事收繫獄中，憂憤而卒，時年四十餘。……子昂褊躁無威儀，然文詞宏麗，甚爲當時所重。有集十卷，友人黃門侍郎盧藏用爲之序，盛行於代。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-yz-person' AS claim_id, 'source-quantangshi-083' AS source_id, '页面 全唐詩/卷083（卷首作者注＋本诗锚点与转引用桩＋卷首叙前半/碎琴段/仕履段/推宗语；碎琴只见于此源不升 KNOWN，与旧传同记处作并列第二证；卷页无正文，正文证据在诗页；六段以「……」相連，出处同卷）' AS locator, '''''''陳子昂''''''……==[[登幽州臺歌]]==
{{:登幽州臺歌}}……陳子昂，字伯玉，梓州射洪人。少以富家子，尚氣決，好弋博，後遊鄉校，乃感悔修飭。初舉進士入京，不爲人知。……有賣胡琴者，價百萬，子昂顧左右，輦千緡市之。衆驚問，子昂曰：「余善此。」曰：「可得聞乎？」曰：「明日可入宣陽里。」如期偕往，則酒肴畢具。奉琴語曰：「蜀人陳子昂，有文百軸，不爲人知，此賦工之伎，豈宜留心？」舉而碎之，以其文百軸徧贈會者。一日之內，名滿都下。……擢進士第。武后朝，爲靈臺正字。數上書言事，遷右拾遺。武攸宜北討，表爲管記，軍中文翰，皆委之子昂。父爲縣令段簡所辱，子昂聞之，遽還鄉里，簡乃因事收繫獄中，憂憤而卒。……唐興，文章承徐庾餘風，駢麗穠縟，子昂橫制頹波，始歸雅正，李杜以下，咸推宗之。集十卷，今編詩二卷。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-yz-person' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百二·文藝中·萧颖士传（新唐书无陈子昂本传的唯一旁证——身后推重；本层单传边界的出处，升证反用）' AS locator, '所許可當世者，陳子昂、富嘉謨、盧藏用之文辭，董南事、孔述睿之博學而已。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 6. background_line ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-yz-scene' AS background_id, 'text-work-t300-002-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-yz-scene' AS background_id, 'text-work-t300-002-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-yz-city' AS background_id, 'text-work-t300-002-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-yz-city' AS background_id, 'text-work-t300-002-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-yz-world' AS background_id, 'text-work-t300-002-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-yz-world' AS background_id, 'text-work-t300-002-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-yz-person' AS background_id, 'text-work-t300-002-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-yz-person' AS background_id, 'text-work-t300-002-ws' AS version_id, 8 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 7. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 28, 'chen-zi-ang deng-youzhou-tai-ge background layers plus the stage-D first pre-An-Shi event anchor (inserts-only): new EVENT entity for the Yingzhou Khitan revolt 696-697 with KNOWN time.span straight from tongjian ju205/206 year titles (rising and fall of Yingzhou in 696; Wang Xiaojie buried at East Xiashi Valley, Wu Zhuyi stalled at Yuyang, Youzhou fallen, Sun Wanrong killed by his own slave and the edict declaring the Khitans pacified, all in 697); the poem itself deliberately gets NO time.span, NO event.name, NO written_during and zero relation rows -- neither Tang history nor the Zizhi Tongjian mentions this poem anywhere, the camp-composition story is a later chronology claim not locally verifiable; first single-biography poet of stage D (Xin Tang Shu has no biography of Chen Zi-ang -- verified by full scan of ju201-203, one passing mention in the Xiao Yingshi entry only): KNOWN covers only facts recorded word-for-word by both the JTS biography and the Quan Tang Shi volume-headnote (the qin-smashing story appears in the headnote alone and is NOT promoted); ws page verified to carry no inline variants -- recorded as checked-and-clean'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 28);
COMMIT;
