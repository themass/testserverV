-- V026：王維《和賈舍人早朝大明宮之作》(work-t300-140) 四层背景（阶段 D 第 8 首）。MySQL 5.6.40 兼容。
-- 只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V015、V016、V017、V018、V025 已执行（work-t300-140 与其 text-work-t300-140-ws 是 V018 行；
--       source-ws-t300-140 亦是 V018 行；source-dushi-xiangzhu-05 是 V025 行；
--       source-jiutangshu-wenyuan / source-xintangshu-wenyi 是 V016 行；
--       source-zizhi-tongjian-events 是 V015 行；event-anshi-rebellion 是 V004/V015 行）。
--
-- 数据源（可复现）：emit_v026.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/和賈舍人早朝大明宮之作.txt（页内 {{另|}} 异文标记照登）、
--   杜詩詳註(四庫全書本)卷05（「附王維詩」段——注本正文取「報」，与诗页首读「送」相反）、
--   資治通鑑卷220（年标题/改元与 V025 共用切片）、全唐詩卷128、舊唐書卷190下、新唐書卷202。
--
-- 做：1 个新 source 登记（全唐詩卷128，PENDING——登记不等于核验）+
--   4 BACKGROUND content/claim/background + 11 组逐字引用 + 系年 claim（time.span LIKELY）+
--   written_during 安史挂接 + 8 行 background_line（scene→1,2｜city→3,4｜world→5,6｜person→7,8，
--   绑 text-work-t300-140-ws）。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log。
--
-- 诚实边界：
--   * 系年为注本单源：仇注系年句附在**杜甫**奉和条（唱和同一集会为内证），LIKELY（V019/V025 先例）；
--   * 首行异文「送/報」两处来源首读相反（诗页取送，仇注正文取報且别出「一作送」）——只登记不裁决；
--   * 「乾元中迁中書舍人」与「此诗（乾元元年春）」的先后核不到，正文不排；
--   * 汉官仪句是仇注注内转引（非汉官仪原本单证）——LIKELY 不升 KNOWN；
--   * 仇注「合觀四作」高下之判是注家读法，照登不裁决；
--   * KNOWN 覆盖本传事实（两唐书各记一段互不矛盾逐字可指）与唱和集团，不覆盖系月。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 25，不含 26
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-wd-%';              -- 空
--   SELECT id FROM poetry_text_version WHERE id='text-work-t300-140-ws';  -- 恰 1 行（V018 已执行）
--   SELECT id FROM poetry_source WHERE id='source-quantangshi-128';     -- 空
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-wd-%';        -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-140';                                  -- 8
--   SELECT certainty FROM poetry_claim WHERE id='claim-bg-wd-person';   -- KNOWN
--   SELECT certainty FROM poetry_claim WHERE id='claim-wd-time-758';    -- LIKELY
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-140'
--     AND predicate='written_during';                                   -- 1
-- 回滚: recovery/V026_rollback.sql（按 id 全枚举删除；不动 V018/V025 的任何行，不动共用通鉴来源行）
START TRANSACTION;

-- ---------- 0. 来源登记（一律 PENDING：登记不等于核验） ----------
INSERT INTO poetry_source (id, title, author, edition, url, rights_note, verification_status, source_kind, reliability)
SELECT * FROM (
SELECT 'source-quantangshi-128' AS id, '《全唐詩》全唐詩/卷128（维基文库录入本）' AS title, NULL AS author, '全唐詩/卷128（维基文库《全唐詩》录入本）' AS edition, 'https://zh.wikisource.org/wiki/全唐詩/卷128' AS url, '维基文库录入本，公有领域古籍。本卷为王維诗卷，卷首 notes 标作者；本诗条目只有锚点+转引用桩，正文在诗页。本行由 emit_v026.py 对快照逐字定位。核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status, 'POETRY_COLLECTION' AS source_kind, 'HIGH' AS reliability FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_source x WHERE x.id = t.id);

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-wd-scene' AS id, 'BACKGROUND' AS entity_type, 'wd-scene' AS slug, '眼前：红头巾唱筹的那个拂晓' AS title, '四层处境背景（阶段 D 第 8 首·早朝大明宮组诗另一半）；史实句均有逐字引证；王维本传两唐书逐字升 KNOWN；系年仍注本单源 LIKELY。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-wd-city' AS id, 'BACKGROUND' AS entity_type, 'wd-city' AS slug, '这名物：宫里没有鸡，有唱晓的卫士' AS title, '四层处境背景（阶段 D 第 8 首·早朝大明宮组诗另一半）；史实句均有逐字引证；王维本传两唐书逐字升 KNOWN；系年仍注本单源 LIKELY。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-wd-world' AS id, 'BACKGROUND' AS entity_type, 'wd-world' AS slug, '这个春天：刚改元，九路兵马正围庆绪' AS title, '四层处境背景（阶段 D 第 8 首·早朝大明宮组诗另一半）；史实句均有逐字引证；王维本传两唐书逐字升 KNOWN；系年仍注本单源 LIKELY。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-wd-person' AS id, 'BACKGROUND' AS entity_type, 'wd-person' AS slug, '这个人：陷贼、凝碧诗，和赎他罪的弟弟' AS title, '四层处境背景（阶段 D 第 8 首·早朝大明宮组诗另一半）；史实句均有逐字引证；王维本传两唐书逐字升 KNOWN；系年仍注本单源 LIKELY。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-wd-scene' AS id, 'bg-wd-scene' AS subject_id, 'context' AS property_key, '早朝场景为诗本文内证（题「和賈舍人…」+通篇候朝名物）；首行页内异文（送/報）有 ws 快照逐字，仇注正文取「報」别出「一作送」——两处首读相反，均逐字登记不裁决。' AS value_text, 'INTERPRETATION' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-wd-city' AS id, 'bg-wd-city' AS subject_id, 'context' AS property_key, '絳幘鸡唱名物为仇注注内引《漢官儀》（四库本录入快照逐字，录入标记照登）；属注本转引类书/汉官仪——单链但逐字可指，故 LIKELY 不升 KNOWN。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-wd-world' AS id, 'bg-wd-world' AS subject_id, 'context' AS property_key, '乾元元年年标题、改元句、九节度使讨庆绪+不置元帅均以通鉴卷220 逐字（与 V025 共用年标题/改元切片）；朝堂与战场并置已标明是读法。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-wd-person' AS id, 'bg-wd-person' AS subject_id, 'context' AS property_key, '陷贼-伪瘖-凝碧诗-特宥-乾元迁转整段，旧唐书卷190下/新唐书卷202 各记一段互不矛盾逐字可指，升 KNOWN（同 V017/V021/V022 两史标准）；certainty 只覆盖本传事实与唱和集团，不覆盖本诗系月与「乾元中」迁转的先后（核不到，正文不排）。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-wd-scene' AS subject_id, 'context' AS property_key, 'claim-bg-wd-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-wd-city' AS subject_id, 'context' AS property_key, 'claim-bg-wd-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-wd-world' AS subject_id, 'context' AS property_key, 'claim-bg-wd-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-wd-person' AS subject_id, 'context' AS property_key, 'claim-bg-wd-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-wd-scene' AS id, 'work-t300-140' AS work_id, 'SCENE' AS layer, '还是那场天没亮的朝会，换一个角度再写一遍：宫里的报晓人戴着红头巾唱筹，尚衣局刚把翠云裘呈上去——诗从宫墙内最先醒的那个人写起。第一句维基文库诗页里就并列两读：「絳幘雞人{{另|送|報}}曉籌」（{{另|}} 是页面异文标记，原样引）。
这一首的题目「和賈舍人早朝大明宮之作」把自己的位置说清了：它是和作，唱的那首出自中書舍人賈至。谁先写的、和得如何，仇注有总评——那是读法，照登在第 7、8 句那层。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-wd-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-wd-city' AS id, 'work-t300-140' AS work_id, 'CITY' AS layer, '「絳幘雞人」不是比喻。仇注注这一句时引《漢官儀》：「宮中輿臺竝不得畜雞，夜漏未明三刻雞鳴，衛士候於朱雀門外，著絳幘雞唱」——红头巾报晓是宫中执事的制度名物，写在注家引的汉官仪里（录入标记照登）。
「九天閶闔開宮殿」的閶闔是天门，也是宫门的借称；诗页此句同样并列两读「九{{另|天|重}}閶闔開宮殿」。名物的账，注本替我们记着。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-wd-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-wd-world' AS id, 'work-t300-140' AS work_id, 'WORLD' AS layer, '这场早朝的年份在通鑑里有名有姓：乾元元年（戊戌，公元七五八年）「丁未，上御明鳳門，赦天下，改元」——朝廷刚改元乾元。同一个春天里，仗还没打完：通鑑同年记「庚寅，命朔方郭子儀……七節度使及平盧兵馬使董秦將步騎二十萬討慶緒；又命河東李光弼、關內、澤潞王思禮二節度使將所部兵助之」——九个节度使围安庆绪，朝廷却不设元帅，只派宦官鱼朝恩做观军容使。
朝堂上鸡唱裘进、五色诏裁；朝堂外二十万人讨庆绪。诗里看不到仗——这正是乱中早朝诗的张力，两页并置是读法，通鑑的记事摆在那里。' AS body_text, 'SENIOR' AS audience, 'claim-bg-wd-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-wd-person' AS id, 'work-t300-140' AS work_id, 'PERSON' AS layer, '写这首和作的人，两唐书都有传，而且传里最重的一段就压在乱事里：《舊唐書》「禄山陷两都……维扈从不及，为贼所得。维服药取痢，伪称瘖病……迫以伪署……凝碧宫……维闻之悲恻，潜为诗曰：万户伤心生野烟……」；贼平论罪，「维以凝碧诗闻于行在，肃宗嘉之，会缙请削己刑部侍郎以赎兄罪，特宥之」——弟弟王缙拿自己的官赎他的罪。《新唐书》同记此事，字有详略，事不相背。
「佩聲歸向鳳池頭」的凤池即中书省：仇注引《晋书》荀勖传「夺我凤凰池，诸君贺我耶」。巧的是两传同记他「乾元中，迁太子中庶子、中書舍人」——他后来也成了「舍人」；但「乾元中」无月，和本诗的先后核不到，不排。
这组诗四首：賈至原唱「早朝大明宮呈兩省僚友」，王維、岑参、杜甫三和——王維这首在《唐詩三百首》里（第 140 首），岑、杜两首也在，原唱在仇注附段里逐字保存。仇注总评「合觀四作……三和俱有奪席之意……王岑秀色可攬……故當推為擅塲」——注家之判，照登不裁决。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-wd-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文 ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-wd-scene' AS claim_id, 'source-ws-t300-140' AS source_id, '页面 和賈舍人早朝大明宮之作（起行含页内异文标记 {{另|送|報}} 原样引，登记 corpus/tang300-variants.md 不裁决；八句全文见 V018 claim-t300-140-text 引文）' AS locator, '絳幘雞人{{另|送|報}}曉籌，' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-wd-scene' AS claim_id, 'source-dushi-xiangzhu-05' AS source_id, '杜詩詳註卷五·「附王維詩」正文段（仇注正文作「報」别出「一作送」——与诗页首读相反；另有第三行异读「一作九天宮殿開閶闔」，均在段内照登）' AS locator, '{{SK anchor|絳幘雞人報}}{{SK notes|一作送}}曉籌尚衣方進翠雲裘九天閶闔開宮殿{{SK notes|一作九天宮殿開閶闔}}萬國衣冠拜冕旒日色纔臨仙掌動香煙欲傍{{SK notes|去聲}}衮龍浮朝{{SK notes|音潮}}罷須裁五色詔佩聲歸向鳯池頭……九{{另|天|重}}閶闔開宮殿，……佩聲歸{{另|向|到}}鳳池頭。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-wd-city' AS claim_id, 'source-dushi-xiangzhu-05' AS source_id, '杜詩詳註卷五·附王維詩注条（注内引《漢官儀》絳幘鸡唱；录自注本，非汉官仪原本）' AS locator, '漢官儀宮中輿臺竝不得畜雞夜漏未明三刻雞鳴衛士侯於朱雀門外著絳幘雞唱' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-wd-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '通鑑卷二百二十·乾元元年（戊戌，公元七五八年）年標題＋二月改元句＋九節度使討慶緒条（与 V025 共用年标题/改元切片；三段以「……」相連）' AS locator, '肅宗文明武德大聖大宣孝皇帝中之下乾元元年（戊戌，公元七五八年）……丁未，上御明鳳門，赦天下，改元。盡免百姓今載租、庸。復以載為年。……庚寅，命朔方郭子儀、淮西魯炅、興平李奐、滑濮許叔冀、鎮西、北庭李嗣業、鄭蔡季廣琛、河南崔光遠七節度使及平盧兵馬使董秦將步騎二十萬討慶緒；又命河東李光弼、關內、澤潞王思禮二節度使將所部兵助之。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-wd-person' AS claim_id, 'source-ws-t300-140' AS source_id, '页面 和賈舍人早朝大明宮之作（header title+author 字段逐字）' AS locator, '| title    = 和賈舍人早朝大明宮之作
| section  =
| author   = 王維' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-wd-person' AS claim_id, 'source-quantangshi-128' AS source_id, '页面 全唐詩/卷128（卷首 notes 作者注＋本诗锚点与转引用桩 {{:…}}；卷页无正文，正文证据在诗页——同 V022/V025 桩教训，定位已分记）' AS locator, '''''''王維''''''……==[[和賈舍人早朝大明宮之作]]==
{{:和賈舍人早朝大明宮之作}}' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-wd-person' AS claim_id, 'source-dushi-xiangzhu-05' AS source_id, '杜詩詳註卷五·賈至原唱条标＋晋书凤池典＋組詩总评「合觀四作」段（三段与 V025 共用切片，逐字相同，以「……」相連）' AS locator, '{{SK anchor|早朝}}{{SK notes|音潮}}大明宮呈兩省僚友{{SK notes|附賈至詩}}……晉書荀朂傳朂乆在中書專管機事及失之甚罔罔悵悵或有賀之者朂曰奪我鳯凰池諸君賀我耶……合觀四作賈首倡殊平平三和俱有奪席之意就三詩論之杜老氣無前王岑秀色可攬一則三春穠李一則千尺喬松結語用事天然凑泊故當推為擅塲' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-wd-person' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百四十下·文苑下·王維传（陷贼-伪瘖-凝碧诗-特宥-乾元迁转整段连续原文；{{YL|}} 标记照登）' AS locator, '禄山䧟兩都，玄宗出幸，維扈從不及，為賊所得。維服藥取痢，偽稱瘖病。禄山素憐之，遣人迎置洛陽，拘於普施寺，迫以偽署。禄山宴其徒於凝碧宫，其樂工皆梨園弟子、教坊工人。維聞之悲惻，潛為詩曰：「萬户傷心生野煙，百官何日再朝天？秋槐花落空宫裏，凝碧池頭奏筦絃。」賊平，陷賊官三等定罪。維以凝碧詩聞于行在，肅宗嘉之，會縉請削己刑部侍郎以贖兄罪，特宥之，責授太子中允，乾元中，遷太子中庶子、中書舍人，復拜給事中，轉尚書右丞。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-wd-person' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百二·文藝中·王維传（陷贼-凝碧-下獄-特宥整段连续原文，与旧传字有详略事不相背）' AS locator, '安祿山反，玄宗西狩，維為賊得，以藥下利，陽喑。祿山素知其才，迎置洛陽，迫為給事中。祿山大宴凝碧池，悉召梨園諸工合樂，諸工皆泣，維聞悲甚，賦詩悼痛。賊平，皆下獄。或以詩聞行在，時縉位已顯，請削官贖維罪，肅宗亦自憐之，下遷太子中允。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-wd-time-758' AS claim_id, 'source-dushi-xiangzhu-05' AS source_id, '杜詩詳註卷五·杜甫奉和条注系年句（「此乾元元年春在諫省作」附在杜甫奉和条上——王维和作同场为内证，唱和同一集会；注本单源）' AS locator, '{{SK notes|此{{YL|乾元元年}}春在諫省作' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-wd-in-anshi' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '通鑑卷二百二十·乾元元年（戊戌，公元七五八年）年標題（758 在 755–763 乱期内的纪年锚）' AS locator, '肅宗文明武德大聖大宣孝皇帝中之下乾元元年（戊戌，公元七五八年）' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-wd-scene' AS background_id, 'text-work-t300-140-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-wd-scene' AS background_id, 'text-work-t300-140-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-wd-city' AS background_id, 'text-work-t300-140-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-wd-city' AS background_id, 'text-work-t300-140-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-wd-world' AS background_id, 'text-work-t300-140-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-wd-world' AS background_id, 'text-work-t300-140-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-wd-person' AS background_id, 'text-work-t300-140-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-wd-person' AS background_id, 'text-work-t300-140-ws' AS version_id, 8 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 系年 claim（work 主语，V022/V025 同款：合推 → LIKELY）+ 选定 ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-wd-time-758' AS id, 'work-t300-140' AS subject_id, 'time.span' AS property_key,
       '758..758 (EXACT) 乾元元年春说：仇注系年句「此乾元元年春在諫省作」附于杜甫同组和作（唱和同一集会为内证——原唱与三和同一场早朝）+通鉴卷220 年标题为纪年锚；注本单源合推，非年谱原文——同 V019/V025 先例给 LIKELY' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'work-t300-140' AS subject_id, 'time.span' AS property_key, 'claim-wd-time-758' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x
                  WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 7. 乱期挂接（event.name 断言 + written_during 关系，V022/V025 同款形状） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-wd-in-anshi' AS id, 'work-t300-140' AS subject_id, 'event.name' AS property_key,
       '安史之亂（755–763）。係年758在亂期內（通鑑卷220 乾元元年標題）；诗人本人即乱事亲历者（陷贼-伪瘖-凝碧诗-特宥，两唐书逐字），此诗是乱中朝廷的早朝声景，诗本文不写战事' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'work-t300-140' AS subject_id, 'event.name' AS property_key, 'claim-wd-in-anshi' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x
                  WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);
INSERT INTO poetry_relation (id, subject_id, predicate, object_id, claim_id)
SELECT * FROM (
SELECT 'rel-work-t300-140-written-during-anshi' AS id, 'work-t300-140' AS subject_id,
       'written_during' AS predicate, 'event-anshi-rebellion' AS object_id,
       'claim-wd-in-anshi' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_relation x
                  WHERE x.id = t.id OR (x.subject_id = t.subject_id AND x.predicate = t.predicate
                                        AND x.object_id = t.object_id));

-- ---------- 8. 版本账本 ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 26, 'wang wei he jiasheren zaochao-daminggong background layers (inserts-only): the other half of the morning-audience poem set completed in V025; Wang Wei is the first stage-D poet with real biographies in both Tang histories (captured by rebels, feigned muteness with purgative medicine, the Ningbi pool poem, brother Juan begging to trade his own office to redeem him) -- biography facts KNOWN per two-histories standard; attribution triple (ws page header, quan tangshi vol128 volume note with transclusion-stub entry, dushi xiangzhu appendix); first line carries a mirror-image variant: ws page prints song as first reading while the commentary text prints bao with "yi zuo song" -- both registered, none adjudicated; time.span LIKELY via the same single-source commentary dating (precedents V019/V025); tongjian ju220 amnesty and the nine-governors campaign against An Qingxu as the spring of 758'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 26);
COMMIT;
