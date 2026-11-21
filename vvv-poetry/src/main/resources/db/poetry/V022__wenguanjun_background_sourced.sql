-- V022：《聞官軍收河南河北》(work-t300-217) 四层背景 + 系年 + 安史线挂接（阶段 D 第 4 首）。MySQL 5.6.40 兼容。
-- 只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V004、V010、V015、V018 已执行（background_line 绑 text-work-t300-217-ws，V018 插的行；
--       source-ws-t300-217 亦 V018 所立；event-anshi-rebellion 见 V015；source-jiutangshu-dufu 见 V010）。
--
-- 数据源（可复现）：emit_v022.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   資治通鑑卷217/222（755/763 两端与 V019/V021 共用同一切片代码路径）、新唐書卷201、舊唐書卷190下、
--   ws-poems/聞官軍收河南河北.txt（诗页快照）。
--
-- 做：4 BACKGROUND content/claim/background + 8 组逐字引用 +
--   8 行 background_line（scene→1,2｜person→3,4｜world→5,6｜city→7,8，绑 text-work-t300-217-ws）+
--   系年 claim-wgjs-time-763（下限锚+春字内证合推 → LIKELY）+ written_during 安史之乱挂接。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log。
--
-- 诚实边界：
--   * 《全唐詩》卷227 快照内此诗只有转引用桩 {{:聞官軍收河南河北}} 无正文——引诗本文一律走诗页快照；
--   * 旧注「梓州说」核不到注本，SCENE 层零注家引用并向读者声明；
--   * 系年是下限锚（763 正月史朝义死）+「青春」春字内证合推，不是注本/年谱原文，故 LIKELY；
--   * 「平而不安」并置是读法，正文标明；「召补不至」单源，只并置不引申；
--   * 页面题目异文「一作收兩河」只登记（corpus/tang300-variants.md），不进正文不裁决。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 21，不含 22
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-wgjs-%';            -- 空
--   SELECT id FROM poetry_text_version WHERE id='text-work-t300-217-ws';  -- 恰 1 行（V018 已执行）
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-wgjs-%';      -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-217';                                  -- 8
--   SELECT certainty FROM poetry_claim WHERE id='claim-bg-wgjs-person'; -- KNOWN
-- 回滚: recovery/V022_rollback.sql（按 id 全枚举删除；不动 V018 的任何行）
START TRANSACTION;

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-wgjs-scene' AS id, 'BACKGROUND' AS entity_type, 'wgjs-scene' AS slug, '眼前：剑外忽然传来的捷报' AS title, '四层处境背景（阶段 D 第 4 首·弧线收口）；史实句均有逐字引证；注本核不到的（写作地点）与读法（平而不安并置）均如实标明。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-wgjs-city' AS id, 'BACKGROUND' AS entity_type, 'wgjs-city' AS slug, '这条路：通往刚被劫空的东都' AS title, '四层处境背景（阶段 D 第 4 首·弧线收口）；史实句均有逐字引证；注本核不到的（写作地点）与读法（平而不安并置）均如实标明。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-wgjs-world' AS id, 'BACKGROUND' AS entity_type, 'wgjs-world' AS slug, '这个天下：战事收场的一刻与它埋下的线头' AS title, '四层处境背景（阶段 D 第 4 首·弧线收口）；史实句均有逐字引证；注本核不到的（写作地点）与读法（平而不安并置）均如实标明。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-wgjs-person' AS id, 'BACKGROUND' AS entity_type, 'wgjs-person' AS slug, '这个人：召他回京他不去的蜀中幕客' AS title, '四层处境背景（阶段 D 第 4 首·弧线收口）；史实句均有逐字引证；注本核不到的（写作地点）与读法（平而不安并置）均如实标明。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-wgjs-scene' AS id, 'bg-wgjs-scene' AS subject_id, 'context' AS property_key, '闻讯场景为诗本文内证（题「聞官軍收河南河北」+八句）；旧注写作地点说本地无注本可核，正文已声明不采。' AS value_text, 'INTERPRETATION' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-wgjs-city' AS id, 'bg-wgjs-city' AS subject_id, 'context' AS property_key, '克东京与回纥/朔方军掠东京有通鉴卷222逐字记载；「余田园在东京」有页面原注逐字。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-wgjs-world' AS id, 'bg-wgjs-world' AS subject_id, 'context' AS property_key, '战事起讫以通鉴年标题为锚（755反于范阳/763史朝义死，与 V019/V021 同一批切片）；授降将河北有通鉴卷222逐字；「平而不安」并置读法已在正文标明为读法。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-wgjs-person' AS id, 'bg-wgjs-person' AS subject_id, 'context' AS property_key, '严武镇蜀、甫为节度参谋检校工部员外郎——两唐书本传各记一段、互不矛盾、逐字可指，升 KNOWN（与 V017/V021 同标准）；「召补京兆功曹参军不至」为新唐书单源，正文仅作并置不引申。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-wgjs-scene' AS subject_id, 'context' AS property_key, 'claim-bg-wgjs-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-wgjs-city' AS subject_id, 'context' AS property_key, 'claim-bg-wgjs-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-wgjs-world' AS subject_id, 'context' AS property_key, 'claim-bg-wgjs-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-wgjs-person' AS subject_id, 'context' AS property_key, 'claim-bg-wgjs-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-wgjs-scene' AS id, 'work-t300-217' AS work_id, 'SCENE' AS layer, '捷报是从「剑外」传来的——剑门关之外，也就是他流落寄居的蜀中。诗里写的全是身体的反应：忽然听到，先哭；回头看妻子，她的愁容不知什么时候没了；随手卷起诗书，高兴得近乎发狂。
旧注对「在哪座城听到的」有说法（梓州说），但那出自我们本地核不到的注本——所以这里不写城名。能核到的只有诗本身：题目叫「闻官军收河南河北」，这首诗记的就是「闻」的那一瞬间。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-wgjs-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-wgjs-city' AS id, 'work-t300-217' AS work_id, 'CITY' AS layer, '他要东回去的地方是洛阳——诗里的原注说「余田园在东京」（维基文库页面上的原注，带 {{*|}} 标记照登）。可《资治通鉴》卷222 记下洛阳光复的同时还有一笔：「怀恩进克东京及河阳城」之后，「回纥入东京，肆行杀略，死者万计，火累旬不灭」，连自家朔方、神策军也「所过虏掠，三月乃已，比屋荡尽，士民皆衣纸」。
「便下襄阳向洛阳」那条欢欣的路，通向的是这样一座刚收回又被劫空的城。诗里一个字没有提；这个反差不是我们加的情节，是通鉴的记事自己摆在那里的。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-wgjs-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-wgjs-world' AS id, 'work-t300-217' AS work_id, 'WORLD' AS layer, '这场战事打到这里收场：起于天宝十四年（乙未，公元七五五年）「禄山发所部兵……反于范阳」，到广德元年（癸卯，公元七六三年）「朝义穷蹙，缢于林中，怀仙取其首以献」——两端都在《资治通鉴》年标题里。
但通鉴紧接着还记了一笔：河北诸州都降了，降将薛嵩、田承嗣、李怀仙「迎仆固怀恩，拜于马首」，怀恩「恐贼平宠衰」奏请留他们分帅河北「自为党援」，而「朝廷亦厌苦兵革，敬冀无事，因而授之」。
诗里是狂喜，通鉴那页上是「平而不安」——同一个天下的两个方向。这个并置读法来自通鉴记事的先后次序，是我们的读法标注，不是史文的判断。' AS body_text, 'SENIOR' AS audience, 'claim-bg-wgjs-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-wgjs-person' AS id, 'work-t300-217' AS work_id, 'PERSON' AS layer, '写这首诗时杜甫在剑南幕府。两《唐书》本传各记一段、互相印证：《新唐书》：「流落剑南，结庐成都西郭。召补京兆功曹参军，不至。会严武节度剑南东、西川，往依焉。武再帅剑南，表为参谋，检校工部员外郎。」《旧唐书》：「严武镇成都，奏为节度参谋检校尚书工部员外郎，赐绯鱼袋。」
新唐书里还有单独一笔：朝廷召他补京兆功曹参军（京畿的官），他「不至」，人留在蜀中。而听到河南河北收复，他在诗里写「便下襄阳向洛阳」——去不去洛阳这件事，传里只记了「不至」两个字，为什么不去、听到捷报时怎么想，传没有说，我们也不替他补。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-wgjs-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文 ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-wgjs-scene' AS claim_id, 'source-ws-t300-217' AS source_id, '页面 聞官軍收河南河北（诗第一行原样含消歧链接标记 [[w:…|…]]，照登不猜字；八句全文见 V018 claim-t300-217-text 引文）' AS locator, '劍]]外忽傳收[[w:薊州 (古代)|薊]]北，初聞涕淚滿衣裳。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-wgjs-city' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '通鑑卷二百二十二·唐紀三十八（寶應元年東京之復與回紇之掠；两段以「……」相连）' AS locator, '大軍乘之而入，賊眾大敗；轉戰於石榴園、老君廟，賊又敗；人馬相蹂踐，填尚書谷，斬首六萬級，捕虜二萬人，朝義將輕騎數百東走。懷恩進克東京及河陽城，獲其中書令許叔冀、王胄等，制釋之。……回紇入東京，肆行殺略，死者萬計，火累旬不滅。朔方、神策軍亦以東京、鄭、汴、汝州皆為賊境，所過虜掠，三月乃已，比屋蕩盡，士民皆衣紙。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-wgjs-city' AS claim_id, 'source-ws-t300-217' AS source_id, '页面 聞官軍收河南河北（诗末原注，{{*|}} 标记照登）' AS locator, '{{*|原注：余田園在東京}}' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-wgjs-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '通鑑卷二百十七（755起）與卷二百二十二（763訖+授降将河北）；五段以「……」相连；卷217年標題作「天寶十四年」不作「載」，照登' AS locator, '玄宗至道大聖大明孝皇帝下之下天寶十四年（乙未，公元七五五年）……十一月，甲子，祿山發所部兵及同羅、奚、契丹、室韋凡十五萬眾，號二十萬，反於范陽。……肅宗文明武德大聖大宣孝皇帝下之下廣德元年（癸卯，公元七六三年）……朝義窮蹙，縊於林中，懷仙取其首以獻。……時河北諸州皆已降，嵩等迎僕固懷恩，拜於馬首，乞行間自效；懷恩亦恐賊平寵衰，故奏留嵩等及李寶臣分帥河北，自為黨援。朝廷亦厭苦兵革，敬冀無事，因而授之。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-wgjs-person' AS claim_id, 'source-dufu-zhuan-candidate' AS source_id, '卷二百一·文藝上·杜甫传（流落剑南—召补不至—依严武—检校工部员外郎，连续原文）' AS locator, '流落劍南，結廬成都西郭。召補京兆功曹參軍，不至。會嚴武節度劍南東、西川，往依焉。武再帥劍南，表為參謀，檢校工部員外郎。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-wgjs-person' AS claim_id, 'source-jiutangshu-dufu' AS source_id, '卷一百九十下·杜甫传（上元二年严武镇成都奏授一段；{{YL|}} 标记照登）' AS locator, '{{YL|上元二年}}冬，黄門侍郎、鄭國公嚴武鎮成都，奏為節度叅謀檢校尚書工部員外郎，賜緋魚袋。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-wgjs-time-763' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '通鑑卷二百二十二·廣德元年（癸卯，公元七六三年）年標題+史朝義死（系年下限锚；「青春作伴」为春字内证——合推非注本系年）' AS locator, '肅宗文明武德大聖大宣孝皇帝下之下廣德元年（癸卯，公元七六三年）……朝義窮蹙，縊於林中，懷仙取其首以獻。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-wgjs-in-anshi' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '通鑑卷二百二十二·廣德元年（丁…年標題+史朝義死：763在亂期內的紀年錨）' AS locator, '肅宗文明武德大聖大宣孝皇帝下之下廣德元年（癸卯，公元七六三年）……朝義窮蹙，縊於林中，懷仙取其首以獻。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-wgjs-scene' AS background_id, 'text-work-t300-217-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-wgjs-scene' AS background_id, 'text-work-t300-217-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-wgjs-person' AS background_id, 'text-work-t300-217-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-wgjs-person' AS background_id, 'text-work-t300-217-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-wgjs-world' AS background_id, 'text-work-t300-217-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-wgjs-world' AS background_id, 'text-work-t300-217-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-wgjs-city' AS background_id, 'text-work-t300-217-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-wgjs-city' AS background_id, 'text-work-t300-217-ws' AS version_id, 8 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 系年（下限锚+春字内证合推 → LIKELY；locator 写明非注本系年） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-wgjs-time-763' AS id, 'work-t300-217' AS subject_id, 'time.span' AS property_key, '763..763 (EXACT) 广德元年春说：题曰收河南河北，河北悉平（史朝义死）在763正月（通鉴卷222）为下限；「青春作伴」为春之内证——合推广德元年春，非注本/年谱原文' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'work-t300-217' AS subject_id, 'time.span' AS property_key, 'claim-wgjs-time-763' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 7. written_during 安史之乱（形状同 V017/V020/V021） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-wgjs-in-anshi' AS id, 'work-t300-217' AS subject_id, 'event.name' AS property_key, '安史之亂（755–763）。係年763在亂期內；「收河南河北」即亂事收場本身' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'work-t300-217' AS subject_id, 'event.name' AS property_key, 'claim-wgjs-in-anshi' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);
INSERT INTO poetry_relation (id, subject_id, predicate, object_id, claim_id)
SELECT * FROM (
SELECT 'rel-work-t300-217-written-during-anshi' AS id, 'work-t300-217' AS subject_id, 'written_during' AS predicate, 'event-anshi-rebellion' AS object_id, 'claim-wgjs-in-anshi' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_relation x WHERE x.id = t.id OR (x.subject_id = t.subject_id AND x.predicate = t.predicate AND x.object_id = t.object_id));

-- ---------- 8. 版本账本 ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 22, 'wen-guanjun-shou-henan-hebei background layers (inserts-only): tongjian 763 ending + two histories on the Shu sojourn; vol227 is a transclusion stub for this poem so poem-text cites the ws page snapshot; old commentary dating unverified and not used'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 22);
COMMIT;
