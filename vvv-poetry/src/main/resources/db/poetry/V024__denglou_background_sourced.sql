-- V024：《登樓》(work-t300-220) 四层背景（阶段 D 第 6 首）。MySQL 5.6.40 兼容。
-- 只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V004、V010、V015、V018 已执行（background_line 绑 text-work-t300-220-ws，V018 插的行；
--       220 走诗页路线，text_version 的 source 是 source-ws-t300-220；source-quantangshi-228 亦 V018 立）。
--
-- 数据源（可复现）：emit_v024.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/登樓__杜甫_.txt（页内异文 {{另|}} 标记照登）、全唐詩卷228、
--   資治通鑑卷222/223（763 两端共用 emit_v019 代码路径）、新唐書卷201、舊唐書卷190下（复用 emit_v022/023 常量）。
--
-- 做：4 BACKGROUND content/claim/background + 7 组逐字引用 +
--   8 行 background_line（scene→1,2｜city→3,4｜world→5,6｜person→7,8，绑 text-work-t300-220-ws）。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不铸 time.span、不挂 written_during**——见下。
--
-- 诚实边界：
--   * 系年只有下限：「西山寇盜」对应通鑑卷223（廣德元年）西山诸州入吐蕃（763），窗口关不上，
--     764 说出核不到的年谱；诗可能作于安史乱事之后，written_during 亦不造；
--   * 楼名不取（注本实测三卷快照的「登樓」全是引王粲《登樓赋》，不注此诗）；
--   * 页内异文 色/水、來/流 只登记（tang300-variants.md）；「後主還祠廟」诸解不选边，只列史实；
--   * 「梁甫吟」属诸葛亮的注法未核到，不引申。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 23，不含 24
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-dl-%';              -- 空
--   SELECT id FROM poetry_text_version WHERE id='text-work-t300-220-ws';  -- 恰 1 行（V018 已执行）
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-dl-%';        -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-220';                                  -- 8
--   SELECT certainty FROM poetry_claim WHERE id='claim-bg-dl-person';   -- KNOWN
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-220'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
-- 回滚: recovery/V024_rollback.sql（按 id 全枚举删除；不动 V018 的任何行）
START TRANSACTION;

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-dl-scene' AS id, 'BACKGROUND' AS entity_type, 'dl-scene' AS slug, '眼前：花逼近楼的那次登临' AS title, '四层处境背景（阶段 D 第 6 首）；史实句均有逐字引证；页内异文只登记；年份窗口关不上，不铸系年不挂乱事线。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-dl-city' AS id, 'BACKGROUND' AS entity_type, 'dl-city' AS slug, '这一带：锦江玉垒与打得动吐蕃的剑南' AS title, '四层处境背景（阶段 D 第 6 首）；史实句均有逐字引证；页内异文只登记；年份窗口关不上，不铸系年不挂乱事线。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-dl-world' AS id, 'BACKGROUND' AS entity_type, 'dl-world' AS slug, '这个天下：乱事收了场、州郡在成片丢的一年' AS title, '四层处境背景（阶段 D 第 6 首）；史实句均有逐字引证；页内异文只登记；年份窗口关不上，不铸系年不挂乱事线。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-dl-person' AS id, 'BACKGROUND' AS entity_type, 'dl-person' AS slug, '这个人：两个窗口都真、典故都核不到' AS title, '四层处境背景（阶段 D 第 6 首）；史实句均有逐字引证；页内异文只登记；年份窗口关不上，不铸系年不挂乱事线。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-dl-scene' AS id, 'bg-dl-scene' AS subject_id, 'context' AS property_key, '登临场景为诗本文内证（题「登樓」+首联）；楼名/年份注本实测不覆盖（qss 三卷「登樓」皆引王粲赋），正文已声明。' AS value_text, 'INTERPRETATION' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-dl-city' AS id, 'bg-dl-city' AS subject_id, 'context' AS property_key, '页内并列异文（色/水、來/流）有 ws 快照逐字（{{另|}} 标记照登）；首读「春色來」有卷228 第二转录逐字；严武破吐蕃/吐蕃不敢犯境有通鉴卷223 逐字。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-dl-world' AS id, 'bg-dl-world' AS subject_id, 'context' AS property_key, '763 收场+吐蕃入长安+西山诸州入吐蕃+764 奉天戒严均有通鉴卷222/223 逐字（763 两端与 V019/V021–V023 共用切片）。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-dl-person' AS id, 'bg-dl-person' AS subject_id, 'context' AS property_key, '两度入严武幕（761/764 两窗口，两唐书+通鉴各记一段互不矛盾逐字可指）升 KNOWN，与 V023 同规矩：certainty 只覆盖幕府事，不覆盖此诗属哪一窗口；典故诸解核不到，不裁决。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-dl-scene' AS subject_id, 'context' AS property_key, 'claim-bg-dl-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-dl-city' AS subject_id, 'context' AS property_key, 'claim-bg-dl-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-dl-world' AS subject_id, 'context' AS property_key, 'claim-bg-dl-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-dl-person' AS subject_id, 'context' AS property_key, 'claim-bg-dl-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-dl-scene' AS id, 'work-t300-220' AS work_id, 'SCENE' AS layer, '这一次是登临。花逼近高楼，看的却是伤心——诗题只有一个动作：登樓；第一联把动作和心情同时给出：「花近高樓傷客心，萬方多難此登臨。」
哪座楼、哪一年登的，要靠注本和年谱——实测本地《杜詩詳註》三卷快照里出现的「登樓」全是注家引王粲的《登樓赋》，没有一处注这首诗，所以我们连楼名都不给。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-dl-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-dl-city' AS id, 'work-t300-220' AS work_id, 'CITY' AS layer, '他望见的两处地名都在诗里：锦江、玉垒。维基文库诗页在第三行里**并列印着两读**——「錦江春{{另|色|水}}{{另|來|流}}天地」（{{另|}} 是页面的异文标记，原样引）；《全唐詩》卷228 的转录取首读作「錦江春色來天地」。两读只登记，不裁决。
这一年蜀中的边境有自己的分量：通鑑记严武「三鎮劍南」时写「吐蕃畏之，不敢犯其境」，又在廣德二年记他「破吐蕃七萬眾，拔當狗城」。锦江玉垒之南是一个打得动吐蕃的剑南；但往西北看，就是下一条。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-dl-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-dl-world' AS id, 'work-t300-220' AS work_id, 'WORLD' AS layer, '「萬方多難」在这首诗的时间点上，有一串通鑑逐字可对的事。安史收场（廣德元年「朝義窮蹙，縢于林中」）之后紧接着：同年十月「吐蕃入長安……長安中蕭然一空」；同年，「吐蕃陷松、維、保三州及雲山新築二城，西川節度使高適不能救，於是劍南西山諸州亦入於吐蕃矣」；廣德二年，「僕固懷恩與回紇、吐蕃進逼奉天，京師戒嚴」。
所以「北極朝廷終不改，西山寇盜莫相侵」不是泛泛的忧世：北边京师刚被占过又夺回，西边的剑南州郡正在成片丢。朝廷与寇盗，通鑑同一年代里两页都有。' AS body_text, 'SENIOR' AS audience, 'claim-bg-dl-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-dl-person' AS id, 'work-t300-220' AS work_id, 'PERSON' AS layer, '写诗的人此时在剑南，具体年份与《宿府》同案：只有两个窗口——《旧唐书》本传「上元二年冬……严武镇成都，奏为节度参谋检校尚书工部员外郎」（761），《通鉴》广德二年「合剑南东、西川为一道，以黄门侍郎严武为节度使」+《新唐书》「武再帅剑南，表为参谋」（764）；注本年谱核不到，两说并列。
末联的两个典故都不注不行，但我们核不到注：「後主還祠廟」历来多解——不选边，只把史实摆出：763 年长安确实被占（「吐蕃入長安」），代宗确实还了京；「梁甫吟」旧属诸葛亮，注本没核到，也不替他续。一首诗收在「日暮」二字上，这是诗本文写得出的全部。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-dl-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文 ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-dl-scene' AS claim_id, 'source-ws-t300-220' AS source_id, '页面 登樓 (杜甫)（起二句逐字，八句全文见 V018 claim-t300-220-text 引文）' AS locator, '花近高樓傷客心，萬方多難此登臨。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-dl-city' AS claim_id, 'source-ws-t300-220' AS source_id, '页面 登樓 (杜甫)（第三行含页内异文标记 {{另|色|水}}{{另|來|流}}，原样引；登记 corpus/tang300-variants.md 不裁决）' AS locator, '錦江春{{另|色|水}}{{另|來|流}}天地，' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-dl-city' AS claim_id, 'source-quantangshi-228' AS source_id, '页面 全唐詩/卷228（锚点 ==[[登樓 (杜甫)|登樓]]==，<poem> 标记照登；第二转录取首读）' AS locator, '==[[登樓 (杜甫)|登樓]]==
<poem>
花近高樓傷客心，萬方多難此登臨。……錦江春色來天地，
玉壘浮雲變古今。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-dl-city' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '通鑑卷二百二十三·永泰元年（嚴武薨段含「三鎮劍南」「吐蕃畏之不敢犯其境」）' AS locator, '辛卯，劍南節度使嚴武薨。武三鎮劍南，厚賦斂以窮奢侈，梓州剌史章彝小不副意，召而杖殺之；然吐蕃畏之，不敢犯其境。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-dl-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '通鑑卷二百二十二（廣德元年標題+史朝義死）與卷二百二十三（吐蕃入長安段〔廣德元年〕、陷松維保三州〔廣德元年〕、廣德二年奉天戒嚴、嚴武破吐蕃拔當狗城）；六段以「……」相連，卷次與年標題歸屬已在定位分記' AS locator, '肅宗文明武德大聖大宣孝皇帝下之下廣德元年（癸卯，公元七六三年）……朝義窮蹙，縊於林中，懷仙取其首以獻。……戊寅，吐蕃入長安，高暉與吐蕃大將馬重英等立故邠王守禮之孫廣武王承宏為帝，改元，置百官，以前翰林學士於可封等為相。吐蕃剽掠府庫市裡，焚閭捨，長安中蕭然一空。……吐蕃陷松、維、保三州及雲山新築二城，西川節度使高適不能救，於是劍南西山諸州亦入於吐蕃矣。……僕固懷恩與回紇、吐蕃進逼奉天，京師戒嚴。……己未，劍南節度使嚴武破吐蕃七萬眾，拔當狗城。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-dl-person' AS claim_id, 'source-jiutangshu-dufu' AS source_id, '卷一百九十下·杜甫传（窗口一 761 奏授句；{{YL|}} 标记照登）' AS locator, '{{YL|上元二年}}冬，黄門侍郎、鄭國公嚴武鎮成都，奏為節度叅謀檢校尚書工部員外郎，賜緋魚袋。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-dl-person' AS claim_id, 'source-dufu-zhuan-candidate' AS source_id, '卷二百一·文藝上·杜甫传（窗口二「武再帥劍南」在流落剑南连续段内）' AS locator, '流落劍南，結廬成都西郭。召補京兆功曹參軍，不至。會嚴武節度劍南東、西川，往依焉。武再帥劍南，表為參謀，檢校工部員外郎。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-dl-scene' AS background_id, 'text-work-t300-220-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-dl-scene' AS background_id, 'text-work-t300-220-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-dl-city' AS background_id, 'text-work-t300-220-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-dl-city' AS background_id, 'text-work-t300-220-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-dl-world' AS background_id, 'text-work-t300-220-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-dl-world' AS background_id, 'text-work-t300-220-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-dl-person' AS background_id, 'text-work-t300-220-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-dl-person' AS background_id, 'text-work-t300-220-ws' AS version_id, 8 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（字面量里不用裸撇号——V023 教训；此处无撇号） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 24, 'deng-lou background layers (inserts-only): tongjian vol223 Xishan lost + Fengtian alarm + Yan Wu victory; ws page carries inline variant pairs (se/shui, lai/liu) quoted verbatim and registered not adjudicated; deliberately NO time.span (only a 763 lower bound closes locally) and NO written_during (the poem may postdate the An-Shi ending)'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 24);
COMMIT;
