-- V044：王维《積雨輞川莊作》(work-t300-142) 四层背景（阶段 D 第 25 首·八句 2/2/2/2）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V015、V016、V018 已执行（work-t300-142 与其 text-work-t300-142-ws、
--       source-ws-t300-142 是 V018 的行；source-jiutangshu-wenyuan / source-xintangshu-wenyi
--       是 V016 的行——均不另开）。本迁移零新 source（断言）。
--
-- 数据源（可复现）：emit_v044.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/積雨輞川莊作.txt（题目两条自注+一处 {{另}} 异文原样照登，先登记后引用）、
--   舊唐書卷190下（日常两笔+代宗诏集段）、新唐書卷202（施宅为寺句+宝应诏集段）——
--   五段切片传区间归属生成时断言；十个诗语两传区间计数全零生成时断言（负证机器复查）。
--
-- 做：0 个新 source（断言）+ 4 BACKGROUND content/claim/background +
--   6 组逐字引用（(claim,source) 主键每对恰一行）+
--   8 行 background_line（八句形制：scene→1-2 city→3-4 world→5-6 person→7-8，
--   绑 text-work-t300-142-ws 的 8 行）。本迁移不碰 poetry_text_line。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「题有地名有天气，地有传锚而锚不系年」）：
--   * 全池第一首题中之地正有传锚（輞川）——但新传「母亡，表輞川第為寺」不记母亡之年，
--     私宅时间窗两边不明；天气（積雨）钉死是体感/气象的，不是历法的；
--   * 辋川两句 V035/V039 已两度逐字立证——**同句两度为上限，本迁移不三引**；
--     本层新句「表輞川第為寺」为零度异句首引（V042 同段异句谱系）；
--   * KNOWN 一处：代宗诏集文集事体三要素两源一致——**身后之事不外溢为写作时间**；
--     数量分歧四百餘篇/數十百篇各归其侧不裁决（audit 互斥），
--     时间措辞代宗時/寶應中兼容不并轨（V039 判例）；
--   * 鳏居（V037）/奉佛（V039）/天机画评（V043）判例只引不重开（audit 关键语硬卡）。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 43，不含 44
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-jy-%';              -- 空
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-142-ws';  -- 恰 8（七律）
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-jy-%';        -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-142';                                  -- 8（每层两行）
--   SELECT certainty FROM poetry_claim WHERE id = 'claim-bg-jy-world';  -- KNOWN（代宗诏集两源）
--   SELECT certainty FROM poetry_claim WHERE id IN ('claim-bg-jy-scene','claim-bg-jy-city','claim-bg-jy-person');
--     -- LIKELY / LIKELY / LIKELY
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-142'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-142';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-jy-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
-- 回滚: recovery/V044_rollback.sql（按 id 全枚举删除；不动 V018/V035/V037/V039/V043 的行，不动共用来源行）
START TRANSACTION;

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-jy-scene' AS id, 'BACKGROUND' AS entity_type, 'jy-scene' AS slug, '眼前：连阴天把日程放慢' AS title, '四层处境背景（阶段 D 第 25 首·八句 2/2/2/2）；史实句均有逐字引证；background_line 八句形制：每层两行（1-2/3-4/5-6/7-8）；系年第十九次判决「题有地名有天气，地有传锚而锚不系年」（题证系列第七状·首见题地正有传）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 一处（代宗诏集文集事体三要素两源一致）；数量分歧四百餘篇/數十百篇各归其侧不裁决（audit 互斥）；负证机器复查十诗语两传区间计数全零；辋川两句两度已立不三引、施宅为寺句同段异句首引；鳏居/奉佛/天机判例只引不重开。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-jy-city' AS id, 'BACKGROUND' AS entity_type, 'jy-city' AS slug, '这座城：锚点在晃' AS title, '四层处境背景（阶段 D 第 25 首·八句 2/2/2/2）；史实句均有逐字引证；background_line 八句形制：每层两行（1-2/3-4/5-6/7-8）；系年第十九次判决「题有地名有天气，地有传锚而锚不系年」（题证系列第七状·首见题地正有传）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 一处（代宗诏集文集事体三要素两源一致）；数量分歧四百餘篇/數十百篇各归其侧不裁决（audit 互斥）；负证机器复查十诗语两传区间计数全零；辋川两句两度已立不三引、施宅为寺句同段异句首引；鳏居/奉佛/天机判例只引不重开。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-jy-world' AS id, 'BACKGROUND' AS entity_type, 'jy-world' AS slug, '这个天下：朝廷记得他' AS title, '四层处境背景（阶段 D 第 25 首·八句 2/2/2/2）；史实句均有逐字引证；background_line 八句形制：每层两行（1-2/3-4/5-6/7-8）；系年第十九次判决「题有地名有天气，地有传锚而锚不系年」（题证系列第七状·首见题地正有传）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 一处（代宗诏集文集事体三要素两源一致）；数量分歧四百餘篇/數十百篇各归其侧不裁决（audit 互斥）；负证机器复查十诗语两传区间计数全零；辋川两句两度已立不三引、施宅为寺句同段异句首引；鳏居/奉佛/天机判例只引不重开。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-jy-person' AS id, 'BACKGROUND' AS entity_type, 'jy-person' AS slug, '这个人：宅子施给了寺' AS title, '四层处境背景（阶段 D 第 25 首·八句 2/2/2/2）；史实句均有逐字引证；background_line 八句形制：每层两行（1-2/3-4/5-6/7-8）；系年第十九次判决「题有地名有天气，地有传锚而锚不系年」（题证系列第七状·首见题地正有传）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 一处（代宗诏集文集事体三要素两源一致）；数量分歧四百餘篇/數十百篇各归其侧不裁决（audit 互斥）；负证机器复查十诗语两传区间计数全零；辋川两句两度已立不三引、施宅为寺句同段异句首引；鳏居/奉佛/天机判例只引不重开。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-jy-scene' AS id, 'bg-jy-scene' AS subject_id, 'context' AS property_key, '八句全诗本文（ws 页题目两条自注+「何{{另|事|處}}」异文原样照登——先登记后引用，tang300-variants.md 新行；Textquality 75% 如实记）；湿柴迟烟/送饭田头/典出庄列为本层读法声明，非史料断言。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-jy-city' AS id, 'bg-jy-city' AS subject_id, 'context' AS property_key, '题中地名有传锚（輞川）但锚不系年：新传「母亡，表輞川第為寺」同段异句首引，母亡之年两传俱无；辋川两句 V035/V039 已两度立证本迁移不三引（边界声明）；十个诗语两传区间计数全零为机器复查负证（生成时断言）；题有地名有天气，地有传锚而锚不系年→零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-jy-world' AS id, 'bg-jy-world' AS subject_id, 'context' AS property_key, '代宗诏集王维文集事体三要素两源一致（诸王座闻乐章+缙奉诏裒集+上进）→升 KNOWN；数量分歧四百餘篇/數十百篇各归其侧不裁决（audit 互斥）；时间措辞代宗時/寶應中兼容不并轨（V039 判例）；身后之事不外溢为写作时间；certainty 不覆盖任何系年，诗 time.span/event.name/written_during 零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-jy-person' AS id, 'bg-jy-person' AS subject_id, 'context' AS property_key, '京师饭僧/退朝禅诵两笔旧传单得（不升）；「母亡，表輞川第為寺，終葬其西」新传单得（不升）且与辋川两句同段异句（V042 谱系，本迁移首引）；母亡无年=锚不系年；鳏居 V037/奉佛 V039/天机 V043 判例零重开（audit 关键语硬卡）；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-jy-scene' AS subject_id, 'context' AS property_key, 'claim-bg-jy-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-jy-city' AS subject_id, 'context' AS property_key, 'claim-bg-jy-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-jy-world' AS subject_id, 'context' AS property_key, 'claim-bg-jy-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-jy-person' AS subject_id, 'context' AS property_key, 'claim-bg-jy-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-jy-scene' AS id, 'work-t300-142' AS work_id, 'SCENE' AS layer, '连阴天把庄园的日程放慢了：湿柴点不着，炊烟迟滞（「積雨空林煙火遲」——第一句的因果是气象学的）；早饭蒸好黍米饭，送到东边的田头（「蒸藜炊黍餉東菑」——送饭到田里，是劳动日程的一部分）；水田上白鹭低飞，夏木深处黄鹂转声（「漠漠水田飛白鷺，陰陰夏木囀黃鸝」——两组叠字把雨天的湿度写进视野和听觉）；自己的日子则是另一套：看木槿朝开暮落修习静观，松下清斋折带露的葵菜（「山中習靜觀朝槿，松下清齋折露葵」）；末联连用两个典故收束——《庄子》的争席、《列子》的海鸥：老头子与人无争到连鸥鸟都不再疑他（「野老與人爭席罷，海鷗何事更相疑」——「何事/何處」页内自注照登不裁决）。
这是辋川的诗，题把地点和天气都钉死了。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-jy-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-jy-city' AS id, 'work-t300-142' AS work_id, 'CITY' AS layer, '这是全池子里**唯一题中带传记锚点地名**的一首：「輞川莊」在两传明记（那两句 V035 辋川线、V039 别名侧已两度逐字立证——**同句两度为上限，本迁移不三引**）。但锚点自己在晃：新传「母亡，表輞川第為寺，終葬其西」——母亲去世后端宅施寺，**两传都不记母亲卒年**，「輞川莊」作为私宅的时间窗因此无法闭合。
负证同样机器复查：积雨/空林/烟火/蒸藜/东菑/漠漠/白鹭/黄鹂/野老/海鸥十个诗语在两传王维区间计数全零（生成时断言，快照变动即中止）——庄园的这一日在传中零记录。题有地名有天气，地有传锚而锚不系年：这是题证七状里第一次「地终于对上了传」，而传仍然不交出年份。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-jy-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-jy-world' AS id, 'work-t300-142' AS work_id, 'WORLD' AS layer, '王维身后，朝廷记得他。两唐书各自记下同一幕：
旧传代宗对宰相王缙说「卿之伯氏，天寳中詩名冠代，朕嘗於諸王座聞其樂章」，缙答「開元中詩百千餘篇，天寳事後，十不存一」，编缀得「四百餘篇」，「翌日上之，帝優詔襃賞」；新传「寶應中」代宗语缙「朕嘗于諸王座聞維樂章，今傳幾何」，遣中人王承华往取，「縉裒集數十百篇上之」——**事体三要素两源一致**（代宗于诸王座闻王维乐章+王缙奉诏裒集+上进）：**代宗诏集王维文集升 KNOWN**。
两处分歧照登不裁决：**数量**「四百餘篇」／「數十百篇」各归其侧（audit 互斥断言）；**时间措辞**「代宗時」／「寶應中」兼容而不并轨（V039 乾元二年卒/上元初卒判例：兼容≠裁决）。乱世之后一个王朝清点一位诗人的遗产——这是「天下」层能给这首诗的最硬的上下文，但它系的是身后之事，**不外溢为写作时间**。' AS body_text, 'SENIOR' AS audience, 'claim-bg-jy-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-jy-person' AS id, 'work-t300-142' AS work_id, 'PERSON' AS layer, '旧传给这个人的日常留了两笔，都只见于旧传（单得，不升）：「在京師日飯十數名僧，以玄談為樂」——在京城的饭局是斋僧；「退朝之後，焚香獨坐，以禪誦為事」——退朝后的功课是禅诵。
新传的庄园侧则留下一句本迁移首引的：**「母亡，表輞川第為寺，終葬其西」**——把辋川第宅上表施为寺院，身后葬在其西侧（与 V035/V039 已两度立证的两句**同段异句**，V042 谱系：同段之内首尾两句已两度、此句零度——引它的不是次数，是「锚不系年」这个新事实）。母之卒年两传俱无——这座宅子变成寺的时点因此悬置，而「輞川莊作」只能悬在私宅时间窗内，窗的两边都不明。
鳏居（V037）、奉佛（V039）、天机画评（V043）判例本迁移零重开。' AS body_text, 'SENIOR' AS audience, 'claim-bg-jy-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-jy-scene' AS claim_id, 'source-ws-t300-142' AS source_id, '页面 積雨輞川莊作（header title+author+八句四联，六段以「……」相連——题目两条自注与「何{{另|事|處}}」标记原样照登（先登记后引用，tang300-variants.md 新行）；同一 (claim,source) 主键下一行容全文，V037/V039/V040/V041/V042/V043 判例；全文另见 V018 claim-t300-142-text 引文）' AS locator, '| title    = 積雨輞川莊{{*|一有上字}}作{{*|一作秋歸輞川莊作}}……| author   = 王維……積雨空林煙火遲，蒸藜炊黍餉東菑。……漠漠水田飛白鷺，陰陰夏木囀黃鸝。……山中習靜觀朝槿，松下清齋折露葵。……野老與人爭席罷，海鷗何{{另|事|處}}更相疑。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-jy-city' AS claim_id, 'source-ws-t300-142' AS source_id, '页面 積雨輞川莊作（header title 单字段——负证的引文形态：题中的地名天气即证据本体，八句诗身另在 SCENE 层；传锚侧的负证为两传区间十诗语计数全零，生成时机器复查；辋川两句 V035/V039 已两度立证本迁移不三引——边界声明）' AS locator, '| title    = 積雨輞川莊{{*|一有上字}}作{{*|一作秋歸輞川莊作}}' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-jy-world' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十下·文苑下·王维传代宗诏集段（诗名冠代/十不存一/四百余篇/翌日上之优诏褒赏——两源合龙旧传侧逐字；数量措辞归旧侧）' AS locator, '代宗時，縉為宰相，代宗好文，常謂縉曰：「卿之伯氏，天寳中詩名冠代，朕嘗於諸王座聞其樂章。今有多少文集，卿可進來。」縉曰：「臣兄開元中詩百千餘篇，天寳事後，十不存一。比於中外親故間相與編綴，都得四百餘篇。」翌日上之，帝優詔襃賞。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-jy-world' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百零二·文藝中·王维传宝应诏集段（宝应中/诸王座闻维乐章/遣王承华往取/裒集数十百篇——两源合龙新传侧逐字；数量措辞归新侧，与旧侧各归其侧不裁决）' AS locator, '寶應中，代宗語縉曰：「朕嘗于諸王座聞維樂章，今傳幾何？」遣中人王承華往取，縉裒集數十百篇上之。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-jy-person' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十下·文苑下·王维传日常两笔（京师饭僧玄谈+退朝焚香禅诵，两段以「……」相連，同卷同传——皆旧传单得不升）' AS locator, '在京師日飯十數名僧，以玄談為樂。……退朝之後，焚香獨坐，以禪誦為事。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-jy-person' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百零二·文藝中·王维传施宅为寺句（母亡/表輞川第為寺/终葬其西——本迁移首引；与辋川两句同段异句，V042 谱系声明在此；母亡之年两传俱无）' AS locator, '母亡，表輞川第為寺，終葬其西。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（八句：每层两行） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-jy-scene' AS background_id, 'text-work-t300-142-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-jy-scene' AS background_id, 'text-work-t300-142-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-jy-city' AS background_id, 'text-work-t300-142-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-jy-city' AS background_id, 'text-work-t300-142-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-jy-world' AS background_id, 'text-work-t300-142-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-jy-world' AS background_id, 'text-work-t300-142-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-jy-person' AS background_id, 'text-work-t300-142-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-jy-person' AS background_id, 'text-work-t300-142-ws' AS version_id, 8 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 44, 'Wang Wei Rainy Season at the Wang-chuan Estate background layers (stage-D poem 25, 2/2/2/2): dating verdict nineteen, seventh shape of the title-evidence series and the first where the place in the title does have a biography anchor -- the anchor itself wavers: XTS mu-wang, biao Wang-chuan di wei si (upon the death of his mother the estate was converted into a monastery) records no year for that death, so the time-window of the private estate cannot be closed; weather pinned (continuous rain), place pinned (Wang-chuan), year still absent -- zero forging, zero relation; the two established Wang-chuan sentences (quoted verbatim twice, V035 and V039) get no third citation -- the new same-paragraph different-sentence line is cited for the un-anchored anchor, not for count (V042 lineage); one KNOWN: Emperor Daizong ordered the collection of the works of Wang Wei -- substance agrees across both histories on three elements (heard his music at the seats of the princes, Wang Jin ordered to compile, compilation presented), while the count diverges (four hundred-odd vs several tens-to-hundreds, each kept on its own side, mutual-exclusion asserted) and the time wording (in the reign of Daizong vs in Baoying) is compatible but not merged (V039 precedent: compatibility is not a ruling) -- and a posthumous affair never overflows into the writing time of the poem; ten poem-words counted zero across both biography spans, asserted at generation time (machine re-check of the negative evidence); the widower/piety/tian-ji lines stay closed precedents (audit keyword zero-entry); zero new sources'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 44);
COMMIT;
