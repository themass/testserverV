-- V021：《春宿左省》(work-t300-209) 四层背景 + 系年 + 安史线挂接（阶段 D 第 3 首）。MySQL 5.6.40 兼容。
-- 只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V003、V011、V015、V017、V018 已执行（background_line 绑 text-work-t300-209-ws，V018 插的行）。
--
-- 数据源（可复现）：emit_v021.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   資治通鑑卷217/220/222（切片与 V019/V020 共用同一代码路径）、新唐書卷201、舊唐書卷190下。
--
-- 做：4 BACKGROUND content/claim/background（正文全带证或如实声明边界）+ 5 组逐字引用 +
--   8 行 background_line（scene→1,2｜city→3,4｜person→5,6｜world→7,8，绑 text-work-t300-209-ws）+
--   系年断言 claim-chun-su-time-757（两史合证 → LIKELY）+ written_during 安史之乱挂接。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log。
--
-- 诚实边界：
--   * 「掖垣/金钥」的制度解释需要注本（杜诗详注卷五本地快照正文为空、维基文库当前不可达）——
--     SCENE 层因此零注家引用，正文向读者声明这一点；
--   * 系年 757 由「新唐书至德二年拜右拾遗」+「旧唐书明年春救房琯时已为左省官」合证推出，
--     不是注本单源，也不是年谱原文，故 LIKELY；
--   * person 层升 KNOWN 的标准与 V017 陷长安 756 一致：两个独立来源各记一段、互不矛盾、逐字可指。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 20，不含 21
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-chunsu-%';          -- 空
--   SELECT id FROM poetry_text_version WHERE id='text-work-t300-209-ws';  -- 恰 1 行（V018 已执行）
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-chunsu-%';    -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-209';                                  -- 8
--   SELECT certainty FROM poetry_claim WHERE id='claim-bg-chunsu-person';  -- KNOWN
-- 回滚: recovery/V021_rollback.sql（按 id 全枚举删除；不动 V018 的任何行）
START TRANSACTION;

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-chunsu-scene' AS id, 'BACKGROUND' AS entity_type, 'chunsu-scene' AS slug, '眼前：宫墙里的值夜' AS title, '四层处境背景（阶段 D 第 3 首）；史实句均有逐字引证；制度词未核到的已写成正文边界。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-chunsu-city' AS id, 'BACKGROUND' AS entity_type, 'chunsu-city' AS slug, '这座城：刚刚收回的京城' AS title, '四层处境背景（阶段 D 第 3 首）；史实句均有逐字引证；制度词未核到的已写成正文边界。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-chunsu-world' AS id, 'BACKGROUND' AS entity_type, 'chunsu-world' AS slug, '这个天下：打到转折之年的战事' AS title, '四层处境背景（阶段 D 第 3 首）；史实句均有逐字引证；制度词未核到的已写成正文边界。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-chunsu-person' AS id, 'BACKGROUND' AS entity_type, 'chunsu-person' AS slug, '这个人：刚上任就会因奏疏获罪的谏官' AS title, '四层处境背景（阶段 D 第 3 首）；史实句均有逐字引证；制度词未核到的已写成正文边界。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-chunsu-scene' AS id, 'bg-chunsu-scene' AS subject_id, 'context' AS property_key, '值夜场景为诗本文内证（题「春宿左省」）；掖垣/金钥的制度解释需注本，未核——正文已声明边界。' AS value_text, 'INTERPRETATION' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-chunsu-city' AS id, 'bg-chunsu-city' AS subject_id, 'context' AS property_key, '至德二载九月收西京与百姓欢呼有通鉴卷220逐字记载；宫殿星月意象为诗本文内证。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-chunsu-world' AS id, 'bg-chunsu-world' AS subject_id, 'context' AS property_key, '战事起讫以通鉴年标题为锚（755反于范阳/763史朝义死）；757收京以通鉴卷220年标题+入京句为锚。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-chunsu-person' AS id, 'bg-chunsu-person' AS subject_id, 'context' AS property_key, '拜右拾遗（新唐书本传）与救房琯被出（旧唐书本传连续一段）为两史各自逐字记载，事件链完整；升 KNOWN。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-chunsu-scene' AS subject_id, 'context' AS property_key, 'claim-bg-chunsu-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-chunsu-city' AS subject_id, 'context' AS property_key, 'claim-bg-chunsu-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-chunsu-world' AS subject_id, 'context' AS property_key, 'claim-bg-chunsu-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-chunsu-person' AS subject_id, 'context' AS property_key, 'claim-bg-chunsu-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-chunsu-scene' AS id, 'work-t300-209' AS work_id, 'SCENE' AS layer, '这个夜晚在宫里。傍晚花影落在宫墙的缺口上，归鸟啾啾地掠过；入夜后锁钥的声音清晰可闻——值夜的谏官睡不着，一遍遍问夜多深了，因为明天一早要把密封的奏章递进去。
「掖垣」「金钥」具体指什么建筑、什么门禁，需要注本来解释——这层注本我们还没有核到，不敢代注家下定义。能说的是：这一切都是诗里的场景，诗题为「春宿左省」，值夜是这首诗的现场。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-chunsu-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-chunsu-city' AS id, 'work-t300-209' AS work_id, 'CITY' AS layer, '这座城刚被收复不久。至德二载（丁酉，公元七五七年）九月癸卯，广平王俶统率的「朔方等军及回纥、西域之众十五万，号二十万」进入西京，《资治通鉴》写长安百姓：「俶整众入城，百姓老幼夹道欢呼悲泣。」
「星临万户动，月傍九霄多」的万户与九霄，写的正是这座刚收回宫阙的京城——在刚刚失而复得的人眼里，星空下的宫殿才会那样亮。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-chunsu-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-chunsu-world' AS id, 'work-t300-209' AS work_id, 'WORLD' AS layer, '战事此时打到了第四年：起于天宝十四年（乙未，公元七五五年）「禄山发所部兵……反于范阳」，广德元年（癸卯，公元七六三年）史朝义「穷蹙，缢于林中」才收场——两端都在《资治通鉴》年标题里。
至德二年是转折之年：年标题下记着「癸卯，大军入西京」——长安回到了唐朝手里。但仗没打完：诗中「明朝有封事」那份连夜准备的上疏，就是乱世里谏官的日常。' AS body_text, 'SENIOR' AS audience, 'claim-bg-chunsu-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-chunsu-person' AS id, 'work-t300-209' AS work_id, 'PERSON' AS layer, '写这首诗时杜甫是右拾遗——《新唐书》本传记他「至德二年，亡走凤翔上谒，拜右拾遗」：从长安跑去凤翔投奔肃宗，被留了这个从八品的谏官。
这个位置他没坐多久，旧《唐书》本传记了完整一段：房琯布衣时与杜甫交好，为宰相后自请率军讨贼，「琯兵败于陈涛斜」，来年春被罢相，「甫上疏言琯有才，不宜罢免。肃宗怒，贬琯为刺史，出甫为华州司功参军」——救朋友，触怒皇帝，被赶出京城。「明朝有封事」不是一个履职动作的抒情化：这个人的奏疏真的会换来贬官。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-chunsu-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文 ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-chunsu-scene' AS claim_id, 'source-quantangshi-225' AS source_id, '卷225·杜甫·春宿左省（锚点 ==春宿左省==；诗本文八句为内证，见 V018 claim-t300-209-text 引文）' AS locator, '花隱掖垣暮，……數問夜如何。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-chunsu-city' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '通鑑卷二百二十·唐紀（至德二年丁酉=757，卷內年標題自带公元）；入京句與歡呼句以「……」相連' AS locator, '遲明，諜至，守忠、歸仁與張通儒、田乾真等皆已遁矣。癸卯，大軍入西京。……俶整眾入城，百姓老幼夾道歡呼悲泣。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-chunsu-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '通鑑卷二百十七（天寶十四年標題+反于范陽）與卷二百二十二（廣德元年標題+史朝義死）為起訫；卷二百二十至德二年標題+入西京句為轉折；四段以「……」相連；卷217年標題作「天寶十四年」不作「載」，照登' AS locator, '玄宗至道大聖大明孝皇帝下之下天寶十四年（乙未，公元七五五年）……十一月，甲子，祿山發所部兵及同羅、奚、契丹、室韋凡十五萬眾，號二十萬，反於范陽。……肅宗文明武德大聖大宣孝皇帝中之下至德二年（丁酉，公元七五七年）……遲明，諜至，守忠、歸仁與張通儒、田乾真等皆已遁矣。癸卯，大軍入西京。……肅宗文明武德大聖大宣孝皇帝下之下廣德元年（癸卯，公元七六三年）……朝義窮蹙，縊於林中，懷仙取其首以獻。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-chunsu-person' AS claim_id, 'source-dufu-zhuan-candidate' AS source_id, '卷二百一·文藝上·杜甫传（拜右拾遗原文）' AS locator, '至德二年，亡走鳳翔上謁，拜右拾遺。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-chunsu-person' AS claim_id, 'source-jiutangshu-dufu' AS source_id, '卷一百九十下·杜甫传（救房琯段连续原文：交好—兵败—罢相—上疏—贬琯出甫）' AS locator, '房琯布衣時與甫善，時琯為宰相，請自帥師討賊，帝許之。其年十月，琯兵敗於陳濤斜。明年春，琯罷相，甫上疏言琯有才，不宜罷免。肅宗怒，貶琯為刺史，出甫為華州司功叅軍。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-chunsu-scene' AS background_id, 'text-work-t300-209-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-chunsu-scene' AS background_id, 'text-work-t300-209-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-chunsu-city' AS background_id, 'text-work-t300-209-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-chunsu-city' AS background_id, 'text-work-t300-209-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-chunsu-person' AS background_id, 'text-work-t300-209-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-chunsu-person' AS background_id, 'text-work-t300-209-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-chunsu-world' AS background_id, 'text-work-t300-209-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-chunsu-world' AS background_id, 'text-work-t300-209-ws' AS version_id, 8 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 系年（两史合证 → LIKELY；locator 写明是合证推出，不是年谱原文） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-chun-su-time-757' AS id, 'work-t300-209' AS subject_id, 'time.span' AS property_key, '757..757 (EXACT) 至德二载春任左省时作：新唐书「至德二年…拜右拾遗」+旧唐书救房琯段（罢相在明年春=758，值左省时在757收京后）——两史合证推出，非年谱原文' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'work-t300-209' AS subject_id, 'time.span' AS property_key, 'claim-chun-su-time-757' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-chun-su-time-757' AS claim_id, 'source-dufu-zhuan-candidate' AS source_id,
       '卷二百一·文藝上·杜甫传（至德二年=757，卷标题在传内；拜右拾遗）' AS locator, '至德二年，亡走鳳翔上謁，拜右拾遺。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-chun-su-time-757' AS claim_id, 'source-jiutangshu-dufu' AS source_id,
       '卷一百九十下·杜甫传（「其年十月…明年春，琯罢相」：明年春=乾元元年758，上疏时杜甫在左省任内）' AS locator,
       '房琯布衣時與甫善，時琯為宰相，請自帥師討賊，帝許之。其年十月，琯兵敗於陳濤斜。明年春，琯罷相，甫上疏言琯有才，不宜罷免。肅宗怒，貶琯為刺史，出甫為華州司功叅軍。' AS evidence_excerpt FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 7. written_during 安史之乱（形状同 V017/V020） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-chun-su-in-anshi' AS id, 'work-t300-209' AS subject_id, 'event.name' AS property_key, '安史之亂（755–763）。係年757在亂期內；「明朝有封事」與房琯兵敗後朝局為亂中語境依據' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'work-t300-209' AS subject_id, 'event.name' AS property_key, 'claim-chun-su-in-anshi' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-chun-su-in-anshi' AS claim_id, 'source-zizhi-tongjian-events' AS source_id,
       '通鑑卷二百二十·至德二年（丁酉，公元七五七年）年標題+入西京句（757在亂期內的紀年錨）' AS locator,
       '肅宗文明武德大聖大宣孝皇帝中之下至德二年（丁酉，公元七五七年）……遲明，諜至，守忠、歸仁與張通儒、田乾真等皆已遁矣。癸卯，大軍入西京。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-chun-su-in-anshi' AS claim_id, 'source-jiutangshu-dufu' AS source_id,
       '卷一百九十下·杜甫传（房琯陳濤斜之敗與貶琯出甫：亂中朝局內證）' AS locator,
       '房琯布衣時與甫善，時琯為宰相，請自帥師討賊，帝許之。其年十月，琯兵敗於陳濤斜。明年春，琯罷相，甫上疏言琯有才，不宜罷免。肅宗怒，貶琯為刺史，出甫為華州司功叅軍。' AS evidence_excerpt FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);
INSERT INTO poetry_relation (id, subject_id, predicate, object_id, claim_id)
SELECT * FROM (
SELECT 'rel-work-t300-209-written-during-anshi' AS id, 'work-t300-209' AS subject_id, 'written_during' AS predicate, 'event-anshi-rebellion' AS object_id, 'claim-chun-su-in-anshi' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_relation x WHERE x.id = t.id OR (x.subject_id = t.subject_id AND x.predicate = t.predicate AND x.object_id = t.object_id));

-- ---------- 8. 版本账本 ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 21, 'chun-su-zuo-sheng background layers (inserts-only): tongjian 757 recovery + two histories on the advisor year; SCENE layer has zero commentary quotes by design (no commentary snapshot locally; boundary stated in text)'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 21);
COMMIT;
