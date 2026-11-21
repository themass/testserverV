-- V045：李白《金陵酒肆留別》(work-t300-320) 四层背景（阶段 D 第 26 首·六句 2/2/1/1）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V015、V016、V018 已执行（work-t300-320 与其 text-work-t300-320-ws、
--       source-ws-t300-320 是 V018 的行；source-jiutangshu-wenyuan / source-xintangshu-wenyi
--       是 V016 的行——均不另开）。本迁移零新 source（断言）。
--
-- 数据源（可复现）：emit_v045.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/金陵酒肆留別.txt（三处 {{另}} 自注原样照登，先登记后引用）、
--   舊唐書卷190下（采石夜航段+嗜酒短句）、新唐書卷202（采石夜航段）——
--   三段切片传区间归属生成时断言；六诗语两传区间计数全零+金陵位置断言+
--   旧传酒肆两见新传零见不对称，全部生成时断言（负证机器复查）。
--
-- 做：0 个新 source（断言）+ 4 BACKGROUND content/claim/background +
--   5 组逐字引用（(claim,source) 主键每对恰一行）+
--   6 行 background_line（六句形制：scene→1-2 city→3-4 world→5 person→6，
--   绑 text-work-t300-320-ws 的 6 行）。本迁移不碰 poetry_text_line。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「题有地名有物色，地有传见而见必它事」）：
--   * 题三钉齐全（金陵/酒肆/留別）但两传李白区间金陵仅一处关联、且必为崔宗之句
--     （位置断言机器复查）；同舟笑傲之城与酒肆留別之城同城两会会各一事；
--   * 采石夜航两句（V032 城层已立）与嗜酒短句（V036 已立）各为第二证——
--     **同句两度为上限**，locator 逐一声明；
--   * KNOWN 一处：同舟游赏金陵段事体四要素两源一致（合龙看要素不看层名）——
--     叙事框架/袍之措辞/舟中之态分歧各归其侧不裁决（audit 双向互斥），
--     同城异景不外溢为写作时间；
--   * 旧传酒肆两见新传零见的词汇不对称如实照登不推论；
--   * 浪迹江湖（V032/V041）/竹溪六逸（V041）/脫靴斥去（V041）/青山终焉（V032）
--     判例只引不重开（audit 关键语硬卡）。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 44，不含 45
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-lb-%';              -- 空
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-320-ws';  -- 恰 6（七古）
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-lb-%';        -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-320';                                  -- 6（2/2/1/1）
--   SELECT certainty FROM poetry_claim WHERE id = 'claim-bg-lb-world';  -- KNOWN（同舟金陵两源）
--   SELECT certainty FROM poetry_claim WHERE id IN ('claim-bg-lb-scene','claim-bg-lb-city','claim-bg-lb-person');
--     -- LIKELY / LIKELY / LIKELY
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-320'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-320';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-lb-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
-- 回滚: recovery/V045_rollback.sql（按 id 全枚举删除；不动 V018/V032/V036/V041 的行，不动共用来源行）
START TRANSACTION;

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-lb-scene' AS id, 'BACKGROUND' AS entity_type, 'lb-scene' AS slug, '眼前：春天开进店里' AS title, '四层处境背景（阶段 D 第 26 首·六句 2/2/1/1）；史实句均有逐字引证；background_line 六句形制：scene 两行 city 两行 world/person 各一行；系年第二十次判决「题有地名有物色，地有传见而见必它事」（题证系列第八状）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 一处（同舟游赏金陵段事体四要素两源一致——合龙看要素不看层名）；叙事框架分歧各归其侧不裁决（audit 双向互斥）；负证机器复查（六诗语零计数+金陵位置断言+酒肆两见/零见不对称）；采石两句与嗜酒一句各达两度上限；判例零重开。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-lb-city' AS id, 'BACKGROUND' AS entity_type, 'lb-city' AS slug, '这座城：同城两会' AS title, '四层处境背景（阶段 D 第 26 首·六句 2/2/1/1）；史实句均有逐字引证；background_line 六句形制：scene 两行 city 两行 world/person 各一行；系年第二十次判决「题有地名有物色，地有传见而见必它事」（题证系列第八状）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 一处（同舟游赏金陵段事体四要素两源一致——合龙看要素不看层名）；叙事框架分歧各归其侧不裁决（audit 双向互斥）；负证机器复查（六诗语零计数+金陵位置断言+酒肆两见/零见不对称）；采石两句与嗜酒一句各达两度上限；判例零重开。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-lb-world' AS id, 'BACKGROUND' AS entity_type, 'lb-world' AS slug, '这个天下：一场两史共证的夜航' AS title, '四层处境背景（阶段 D 第 26 首·六句 2/2/1/1）；史实句均有逐字引证；background_line 六句形制：scene 两行 city 两行 world/person 各一行；系年第二十次判决「题有地名有物色，地有传见而见必它事」（题证系列第八状）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 一处（同舟游赏金陵段事体四要素两源一致——合龙看要素不看层名）；叙事框架分歧各归其侧不裁决（audit 双向互斥）；负证机器复查（六诗语零计数+金陵位置断言+酒肆两见/零见不对称）；采石两句与嗜酒一句各达两度上限；判例零重开。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-lb-person' AS id, 'BACKGROUND' AS entity_type, 'lb-person' AS slug, '这个人：两传词汇学' AS title, '四层处境背景（阶段 D 第 26 首·六句 2/2/1/1）；史实句均有逐字引证；background_line 六句形制：scene 两行 city 两行 world/person 各一行；系年第二十次判决「题有地名有物色，地有传见而见必它事」（题证系列第八状）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 一处（同舟游赏金陵段事体四要素两源一致——合龙看要素不看层名）；叙事框架分歧各归其侧不裁决（audit 双向互斥）；负证机器复查（六诗语零计数+金陵位置断言+酒肆两见/零见不对称）；采石两句与嗜酒一句各达两度上限；判例零重开。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-lb-scene' AS id, 'bg-lb-scene' AS subject_id, 'context' AS property_key, '六句全诗本文（ws 页三处 {{另}} 页内自注原样照登——先登记后引用，tang300-variants.md 新行；Textquality 75% 如实记；异文「白門」自带金陵别称仅作读法注记不裁决）；香之归属/欲行不行/问水比别意为本层读法声明，非史料断言。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-lb-city' AS id, 'bg-lb-city' AS subject_id, 'context' AS property_key, '题三钉（地名+场所+场面）；两传李白区间金陵仅一处关联且必为崔宗之句（位置断言生成时复查）；六诗语两传区间计数全零（生成时断言）；同城两会会各一事→题有地名有物色，地有传见而见必它事→零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-lb-world' AS id, 'bg-lb-world' AS subject_id, 'context' AS property_key, '同舟游赏金陵段事体四要素两源独立一致（与崔宗之同舟/采石—金陵之间/宫锦袍/旁若无人）→升 KNOWN（V032 城层并立判 LIKELY 系合盘而言，本层就事体合龙——合龙看要素不看层名）；叙事框架与措辞分歧（谪官唱和/浮游四方、白衣宮錦袍/著宮錦袍、顧瞻笑傲/坐舟中）各归其侧不裁决（audit 双向互斥）；同城异景不外溢为写作时间；certainty 不覆盖任何系年，诗 time.span/event.name/written_during 零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-lb-person' AS id, 'bg-lb-person' AS subject_id, 'context' AS property_key, '旧传李白区间酒肆两见（嗜酒常态句再证达两度上限）而新传区块酒肆零见（生成时断言）——两传词汇密度不对称如实照登不推论；场所同坐标异；浪迹江湖/竹溪六逸/脫靴斥去/青山终焉判例零重开（audit 关键语硬卡）；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-lb-scene' AS subject_id, 'context' AS property_key, 'claim-bg-lb-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-lb-city' AS subject_id, 'context' AS property_key, 'claim-bg-lb-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-lb-world' AS subject_id, 'context' AS property_key, 'claim-bg-lb-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-lb-person' AS subject_id, 'context' AS property_key, 'claim-bg-lb-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-lb-scene' AS id, 'work-t300-320' AS work_id, 'SCENE' AS layer, '题三个钉子：金陵（城）、酒肆（店）、留別（场面）。开场是春天开进店里：柳絮（异文作「白門」——白門本是金陵别称，一支异文自带地名，照登不裁决）飞满店铺，酒是新压的，唤客人来尝的是吴地酒家女（「柳花滿店香，吳姬壓酒喚客嘗」——香是柳花的还是酒的，句法故意不分）；来送行的是本地一群年轻朋友，走走停停、停停又饮（「金陵子弟來相送，欲行不行各盡觴」——「欲行不行」四字把起身又坐下的拖延全装下）；最后客人干了件痴事：请诸位试问东流的水，这别意跟水比谁长谁短（「請君試問東流水，別意與之誰短長」——把抽象的「别意」递给水去称量，是李白送别的招牌手势）。
三处页内自注（風吹/白門、喚/勸、試問/問取）照登不裁决，引文含标记原样。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-lb-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-lb-city' AS id, 'work-t300-320' AS work_id, 'CITY' AS layer, '这座城在两传李白区间只有一处关联，而那处是**另一件事**：采石到金陵的夜航、同舟的是崔宗之、看的是顾瞻笑傲——同舟笑傲之城，与这首诗的酒肆留別之城同城两会，会各一事。
负证机器复查（生成时断言，快照变动即中止）：吳姬/柳花/盡觴/東流水/子弟/留別六个诗语在两传李白区间计数全零；两传区间内每一处「金陵」都落在崔宗之句内——诗里的店、人、水在传中无处落籍，城里唯一的传见又被另一场宴会占了。题有地名有物色，地有传见而见必它事：同城不同事，年份仍无——金陵在传给不出这条街的坐标，金陵在诗给不出这一年的日期。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-lb-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-lb-world' AS id, 'work-t300-320' AS work_id, 'WORLD' AS layer, '两唐书共同保住了李白生涯里一场著名的夜航：
旧传「時侍御史崔宗之謫官金陵，與白詩酒唱和。嘗月夜乘舟，自采石達金陵，白衣宮錦袍，於舟中顧瞻笑傲，傍若無人」；新传「白浮游四方，嘗乘舟與崔宗之自採石至金陵，著宮錦袍坐舟中，旁若無人」——**事体四要素两源一致**（与崔宗之同舟/采石—金陵之间/着宫锦袍/旁若无人）：**同舟游赏金陵段升 KNOWN**（V032 城层已两史并立逐字，当时判 LIKELY 系就城层合盘而言；本层就事体本身两源合龙——判例：合龙看要素不看层名）。
**叙事框架分歧各归其侧不裁决**：旧传以崔宗之谪官金陵为事由、白往和之，新传以白浮游四方为主线、崔为同舟——袍之「白衣宮錦袍」／「著宮錦袍」、态之「顧瞻笑傲」／「坐舟中」亦然（audit 双向互斥断言）。
这条 KNOWN 是「天下」层给这首诗的上下文：盛唐士人游赏的排场由两史共证——但它**不外溢为写作时间**：同舟是夜航，留別是晨饮，同城异景，谁也不给谁系年。' AS body_text, 'SENIOR' AS audience, 'claim-bg-lb-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-lb-person' AS id, 'work-t300-320' AS work_id, 'PERSON' AS layer, '旧传给李白留了一个词汇学的事实：**「酒肆」在他传内两见**（「白旣嗜酒，日與飲徒醉於酒肆」——嗜酒常态侧，V036 已引全段第一证、此句再证即达两度上限；后一处即玄宗亟召、醉卧酒肆那个著名段子），而**新传李白区块「酒肆」零见**（生成时机器断言）——同一人同一癖好，两传的词汇密度不同，照登不推论（不裁「哪个传更真」，只记两传各用什么词讲这个人）。
这首诗把这个词汇学的事实变成前台：诗题的「酒肆」正是旧传的两处酒肆之一所住的那种场所——但诗里的酒肆在金陵、传里的酒肆不明所在，场所同、坐标异。判例零重开：浪迹江湖（V032/V041）、竹溪六逸（V041）、脫靴斥去（V041）、青山终焉（V032）皆不引。' AS body_text, 'SENIOR' AS audience, 'claim-bg-lb-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-lb-scene' AS claim_id, 'source-ws-t300-320' AS source_id, '页面 金陵酒肆留別（header title+author+六句三联，五段以「……」相連——三处 {{另}} 自注原样照登（先登记后引用，tang300-variants.md 新行）；同一 (claim,source) 主键下一行容全文，V037/V039/V040/V041/V042/V043/V044 判例；全文另见 V018 claim-t300-320-text 引文）' AS locator, '| title    = 金陵酒肆留別……| author   = 李白……{{另|風吹|白門}}柳花滿店香，吳姬壓酒{{另|喚|勸}}客嘗。……金陵子弟來相送，欲行不行各盡觴。……請君{{另|試問|問取}}東流水，別意與之誰短長。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-lb-city' AS claim_id, 'source-ws-t300-320' AS source_id, '页面 金陵酒肆留別（header title 单字段——题三钉（地名+场所+场面）即证据本体；六诗语与金陵位置的负证为两传区间生成时机器断言，诗身不代拟进引文）' AS locator, '| title    = 金陵酒肆留別' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-lb-world' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十下·文苑下·李白传采石夜航段（崔谪官金陵/月夜乘舟自采石达金陵/白衣宫锦袍顾瞻笑傲——同舟金陵两源合龙旧传侧逐字；V032 城层已立此句，此处事体侧再证——第二证已达两度上限，locator 声明）' AS locator, '時侍御史崔宗之謫官金陵，與白詩酒唱和。嘗月夜乘舟，自采石達金陵，白衣宮錦袍，於舟中顧瞻笑傲，傍若無人。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-lb-world' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百零二·文藝中·李白传采石夜航段（浮游四方/乘舟与崔宗之自采石至金陵/著宫锦袍坐舟中旁若无人——两源合龙新传侧逐字；框架与措辞归新侧与旧侧各归其侧不裁决；V032 城层已立此句，此处事体侧再证——第二证已达两度上限）' AS locator, '白浮游四方，嘗乘舟與崔宗之自採石至金陵，著宮錦袍坐舟中，旁若無人。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-lb-person' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十下·文苑下·李白传嗜酒短句（日与饮徒醉于酒肆——V036 全段乐府新词侧第一证，此处嗜酒常态侧再证——同句两度为上限；新传区块酒肆零见的不对称由生成时断言保证，无新传侧引文即无代拟）' AS locator, '白旣嗜酒，日與飲徒醉於酒肆。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（六句：2/2/1/1） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-lb-scene' AS background_id, 'text-work-t300-320-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-lb-scene' AS background_id, 'text-work-t300-320-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-lb-city' AS background_id, 'text-work-t300-320-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-lb-city' AS background_id, 'text-work-t300-320-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-lb-world' AS background_id, 'text-work-t300-320-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-lb-person' AS background_id, 'text-work-t300-320-ws' AS version_id, 6 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 45, 'Li Bai Staying at a Wine Shop in Jinling background layers (stage-D poem 26, six-line 2/2/1/1): dating verdict twenty, eighth shape of the title-evidence series -- the title drives three stakes (city / venue / parting) yet the city appears exactly once inside the Li Bai span of both histories and that appearance is always a different affair (the moonlit boat with Cui Zongzhi, established verbatim at the city layer by V032): the city of boating-side-by-side-laughing and the city of wine-shop-parting are one city, two gatherings -- zero forging, zero relation; machine re-checks at generation time (six poem-words counted zero across both spans, every occurrence of Jinling proven to sit inside the Cui sentence, the two-vs-zero asymmetry of the word for wine-shop between the two histories recorded without inference); one KNOWN: the moonlit boat segment as a fact agrees across both histories on four elements (fellow travelers with Cui Zongzhi / Caishi to Jinling / brocade robe / oblivious air) -- the stage-D rule: agreement is judged on elements, not on layer names; the narrative framing (Cui demoted to Jinling vs Li roaming the four quarters), the robe wording (in white brocade vs wearing brocade) and the posture on the boat all diverge and each stays on its side (bidirectional mutual-exclusion asserted); same city, different scene, never overflowing into writing time; the two Cui sentences and the one drinking sentence each reach the ceiling of two verbatim citations (locator-declared); the wandering/bamboo-creek/boots/banishment and Green Hills lines stay closed precedents (audit keyword zero-entry); zero new sources'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 45);
COMMIT;
