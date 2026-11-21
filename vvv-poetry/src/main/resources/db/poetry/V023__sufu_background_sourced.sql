-- V023：《宿府》(work-t300-221) 四层背景（阶段 D 第 5 首）。MySQL 5.6.40 兼容。
-- 只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V015、V018 已执行（background_line 绑 text-work-t300-221-ws，V018 插的行；
--       其 source 是 source-quantangshi-228——221 走卷页路线，无 source-ws-t300-221）。
--
-- 数据源（可复现）：emit_v023.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   資治通鑑卷222/223（763 两端与 V019/V021/V022 共用 emit_v019 的切片代码路径）、
--   新唐書卷201、舊唐書卷190下（切片复用 emit_v022 常量）、全唐詩卷228。
--
-- 做：4 BACKGROUND content/claim/background + 7 组逐字引用 +
--   8 行 background_line（scene→1,2｜person→3,4｜world→5,6｜city→7,8，绑 text-work-t300-221-ws）。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不铸 time.span、不挂 written_during**——见下。
--
-- 诚实边界（这首的边界就是形状本身）：
--   * 系年核不到：注本本地快照实测无此诗（qss-卷03/04/05 无「宿府」）；本地可核史料只给出
--     两个入幕窗口（761 初镇／764 再镇），PERSON 层并列两窗口，注本旧说「与 764 相合」也
--     标明出自核不到的来源——年份未定，所以 time.span 与 written_during 一个都不造；
--   * 「江城」=成都的注解未核到，正文不裁决；幕府建制词零注家引用；
--   * person 层 KNOWN 只覆盖幕府事（两唐书+通鉴各自逐字、互不矛盾，同 V017/V021/V022 标准），
--     不覆盖《宿府》属哪一窗口。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 22，不含 23
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-sufu-%';            -- 空
--   SELECT id FROM poetry_text_version WHERE id='text-work-t300-221-ws';  -- 恰 1 行（V018 已执行）
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-sufu-%';      -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-221';                                  -- 8
--   SELECT certainty FROM poetry_claim WHERE id='claim-bg-sufu-person'; -- KNOWN
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-221'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
-- 回滚: recovery/V023_rollback.sql（按 id 全枚举删除；不动 V018 的任何行）
START TRANSACTION;

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-sufu-scene' AS id, 'BACKGROUND' AS entity_type, 'sufu-scene' AS slug, '眼前：幕府井梧边的不眠夜' AS title, '四层处境背景（阶段 D 第 5 首）；史实句均有逐字引证；注本核不到的年份写成两窗口并列，不铸系年不挂乱事线。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-sufu-city' AS id, 'BACKGROUND' AS entity_type, 'sufu-city' AS slug, '这座城：寄身人眼里的幕府与江城' AS title, '四层处境背景（阶段 D 第 5 首）；史实句均有逐字引证；注本核不到的年份写成两窗口并列，不铸系年不挂乱事线。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-sufu-world' AS id, 'BACKGROUND' AS entity_type, 'sufu-world' AS slug, '这个天下：史书说已结束、长安说没有的一年' AS title, '四层处境背景（阶段 D 第 5 首）；史实句均有逐字引证；注本核不到的年份写成两窗口并列，不铸系年不挂乱事线。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-sufu-person' AS id, 'BACKGROUND' AS entity_type, 'sufu-person' AS slug, '这个人：核不到哪一年、但两个窗口都真实' AS title, '四层处境背景（阶段 D 第 5 首）；史实句均有逐字引证；注本核不到的年份写成两窗口并列，不铸系年不挂乱事线。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-sufu-scene' AS id, 'bg-sufu-scene' AS subject_id, 'context' AS property_key, '独宿场景为诗本文内证（题「宿府」+起四句）；幕府建制/驻所需注本，本地快照实测无此诗，正文已声明边界。' AS value_text, 'INTERPRETATION' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-sufu-city' AS id, 'bg-sufu-city' AS subject_id, 'context' AS property_key, '严武镇成都（旧唐书）与甫结庐成都西郭（新唐书）逐字可指；「江城」=成都的注解未核到，正文不裁决。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-sufu-world' AS id, 'bg-sufu-world' AS subject_id, 'context' AS property_key, '763 收场（通鉴年标题+史朝义死，与 V019/V021/V022 同一批切片）与同年吐蕃入长安（通鉴卷223）均有逐字记载；风尘/音书与士民避乱的并置读法已标明。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-sufu-person' AS id, 'bg-sufu-person' AS subject_id, 'context' AS property_key, '严武两度镇蜀与甫两度受幕职、765 武卒——旧唐书/新唐书/通鉴各记一段，互不矛盾、逐字可指，升 KNOWN；certainty 只覆盖幕府事本身，不覆盖《宿府》属于哪一窗口（注本未核到，正文并列两窗口）。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-sufu-scene' AS subject_id, 'context' AS property_key, 'claim-bg-sufu-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-sufu-city' AS subject_id, 'context' AS property_key, 'claim-bg-sufu-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-sufu-world' AS subject_id, 'context' AS property_key, 'claim-bg-sufu-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-sufu-person' AS subject_id, 'context' AS property_key, 'claim-bg-sufu-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-sufu-scene' AS id, 'work-t300-221' AS work_id, 'SCENE' AS layer, '这一夜在幕府。井边的梧桐在清秋里发着寒，城中独宿，蜡烛一点点烧残；长夜里号角一声声，像在自言自语，中天月色那样好，却没有人同看。
幕府是什么建制、这一夜驻在哪个衙署，要靠注本解释——本地快照里没有这部注本（实测），所以这里只说诗本文写得出的东西：一个人值夜未睡，听见了角声，看见了月亮。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-sufu-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-sufu-city' AS id, 'work-t300-221' AS work_id, 'CITY' AS layer, '他寄身的是严武的剑南幕府。《旧唐书》本传记严武「镇成都」，《新唐书》本传记他自己「流落剑南，结庐成都西郭」——幕府在成都，成都有锦江，这些是两传的原文或字面。但诗里只说「幕府」「江城」，哪座城是注家的事；把「江城」解成成都这一步，我们本地核不到注家原文，就不替他走完。
「已忍伶俜十年事，强移栖息一枝安」——寄人幕府，注本之外也看得见：这是安身，不是回家。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-sufu-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-sufu-world' AS id, 'work-t300-221' AS work_id, 'WORLD' AS layer, '天下在诗的字面上是远的：「风尘荏苒音书绝，关塞萧条行路难」。这两句能对上通鉴的两页：广德元年（癸卯，公元七六三年）「朝义穷蹙，缢于林中，怀仙取其首以献」，安史收场；同年十月，「戊寅，吐蕃入长安……长安中萧然一空」，代宗出奔陕州——乱子按史书算已结束，按这座被劫空的首都算没有。
「荏苒」「萧条」把音书与行路都断在关山之外，这是诗语；通鉴同页上恰好是「士民避乱，皆入山谷」。两件事的并置是读法，通鉴的记事先后摆在那里。' AS body_text, 'SENIOR' AS audience, 'claim-bg-sufu-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-sufu-person' AS id, 'work-t300-221' AS work_id, 'PERSON' AS layer, '这首诗确定写在某个幕府之夜，但哪一年，我们核不到——本地只有两个窗口，都逐字可指：
窗口一：《旧唐书》本传「上元二年冬，黄门侍郎、郑国公严武镇成都，奏为节度参谋检校尚书工部员外郎，赐绯鱼袋」（上元二年＝761，{{YL|}} 标记照登）。
窗口二：《资治通鉴》广德二年（甲辰，公元七六四年）「癸卯，合剑南东、西川为一道，以黄门侍郎严武为节度使」，《新唐书》本传「武再帅剑南，表为参谋，检校工部员外郎」。764 年再入幕与注本旧说相合，但旧说出自我们核不到的注本，所以只能并列，不能采信。
两传同记的结尾：「永泰元年夏，武卒，甫无所依」（旧唐书）——通鉴永泰元年（乙巳，公元七六五年）记「辛卯，剑南节度使严武薨」「吐蕃畏之，不敢犯其境」。在幕府的那几年，靠山是会先他而死的人。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-sufu-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文 ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-sufu-scene' AS claim_id, 'source-quantangshi-228' AS source_id, '页面 全唐詩/卷228（锚点实际形状 ==[[宿府]]==，即 V018 locator 所记「==宿府==」；起二句逐字，八句全文见 V018 claim-t300-221-text 引文）' AS locator, '==[[宿府]]==
<poem>
清秋幕府井梧寒，獨宿江城蠟炬殘。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-sufu-city' AS claim_id, 'source-jiutangshu-dufu' AS source_id, '卷一百九十下·杜甫传（上元二年严武镇成都奏授一段；「镇成都」在此；{{YL|}} 标记照登）' AS locator, '{{YL|上元二年}}冬，黄門侍郎、鄭國公嚴武鎮成都，奏為節度叅謀檢校尚書工部員外郎，賜緋魚袋。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-sufu-city' AS claim_id, 'source-dufu-zhuan-candidate' AS source_id, '卷二百一·文藝上·杜甫传（流落剑南—结庐成都西郭—依严武—检校工部员外郎，连续原文）' AS locator, '流落劍南，結廬成都西郭。召補京兆功曹參軍，不至。會嚴武節度劍南東、西川，往依焉。武再帥劍南，表為參謀，檢校工部員外郎。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-sufu-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '通鑑卷二百二十二（廣德元年標題+史朝義死）與卷二百二十三（同年標題+吐蕃入長安段）；四段以「……」相連，卷次不同已在定位中分記' AS locator, '肅宗文明武德大聖大宣孝皇帝下之下廣德元年（癸卯，公元七六三年）……朝義窮蹙，縊於林中，懷仙取其首以獻。……代宗睿文孝武皇帝上之下廣德元年（癸卯，公元七六三年）……戊寅，吐蕃入長安，高暉與吐蕃大將馬重英等立故邠王守禮之孫廣武王承宏為帝，改元，置百官，以前翰林學士於可封等為相。吐蕃剽掠府庫市裡，焚閭捨，長安中蕭然一空。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-sufu-person' AS claim_id, 'source-jiutangshu-dufu' AS source_id, '卷一百九十下·杜甫传（窗口一 761 奏授句 + 永泰元年武卒甫无所依句，两段以「……」相连）' AS locator, '{{YL|上元二年}}冬，黄門侍郎、鄭國公嚴武鎮成都，奏為節度叅謀檢校尚書工部員外郎，賜緋魚袋。……{{YL|永泰元年}}夏，武卒，甫無所依。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-sufu-person' AS claim_id, 'source-dufu-zhuan-candidate' AS source_id, '卷二百一·文藝上·杜甫传（窗口二「武再帥劍南」在流落剑南连续段内）' AS locator, '流落劍南，結廬成都西郭。召補京兆功曹參軍，不至。會嚴武節度劍南東、西川，往依焉。武再帥劍南，表為參謀，檢校工部員外郎。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-sufu-person' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '通鑑卷二百二十三·廣德二年標題+合劍南東西川一道（窗口二 764）＋永泰元年標題+嚴武薨段；四段以「……」相連' AS locator, '代宗睿文孝武皇帝上之下廣德二年（甲辰，公元七六四年）……癸卯，合劍南東、西川為一道，以黃門侍郎嚴武為節度使。……代宗睿文孝武皇帝上之下永泰元年（乙巳，公元七六五年）……辛卯，劍南節度使嚴武薨。武三鎮劍南，厚賦斂以窮奢侈，梓州剌史章彝小不副意，召而杖殺之；然吐蕃畏之，不敢犯其境。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-sufu-scene' AS background_id, 'text-work-t300-221-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-sufu-scene' AS background_id, 'text-work-t300-221-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-sufu-person' AS background_id, 'text-work-t300-221-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-sufu-person' AS background_id, 'text-work-t300-221-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-sufu-world' AS background_id, 'text-work-t300-221-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-sufu-world' AS background_id, 'text-work-t300-221-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-sufu-city' AS background_id, 'text-work-t300-221-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-sufu-city' AS background_id, 'text-work-t300-221-ws' AS version_id, 8 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本 ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 23, 'su-fu background layers (inserts-only): tongjian 763 ending + Tufan capture of Chang''an + both Tang histories on the two Yan Wu shu-mufu windows; deliberately NO time.span and NO written_during -- the dating window is unresolved locally and the poem-year cannot even be placed inside or after the rebellion'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 23);
COMMIT;
