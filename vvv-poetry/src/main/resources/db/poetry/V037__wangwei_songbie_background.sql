-- V037：王维《送別》(work-t300-054) 四层背景（阶段 D 第 18 首·六句第三形制）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V015、V016、V018 已执行（work-t300-054 与其 text-work-t300-054-ws、
--       source-ws-t300-054 是 V018 的行；source-jiutangshu-wenyuan / source-xintangshu-wenyi
--       是 V016 的行——不另开行）。本迁移另开 1 个 source（全唐詩卷125，见下）。
--
-- 数据源（可复现）：emit_v037.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/送別__下馬飲君酒_.txt（页内实测无 {{另}}——「查过、干净」；header title 行
--   简体「送别」诗身繁体——页形制逐字照录并在 locator 声明，不属 Witness 异文不开 variants 行）、
--   舊唐書卷190下（王维传官历段+鳏居段；孟浩然传六十三字全收）、
--   新唐書卷202（王维传擢进士段+鳏居段；切片传区间归属生成时断言）、
--   全唐詩卷125（锚点+消歧转引用桩，noauthor 空——V035/V036 判例）。
--
-- 做：1 个新 source（source-quantangshi-125，PENDING——桩页教训同款）+
--   4 BACKGROUND content/claim/background + 10 组逐字引用（(claim,source) 主键每对恰一行）+
--   6 行 background_line（**六句第三形制 2/2/1/1**：scene→1-2 city→3-4 world→5 person→6，
--   绑 text-work-t300-054-ws 的 6 行）。本迁移不碰 poetry_text_line。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「送别诗无系事 + 受赠人无名 + 饯地系推定」）：
--   * 被送者姓名不入任何史料（诗题与两处消歧只到首句）——不发明受赠人；
--   * 饯地=长安系右丞官历推定（LIKELY 非直载）；南山实指泛指不裁决；
--   * 孟浩然「应进士不第」与王维「开元初擢进士」两履历直书升 KNOWN，
--     但**被送者非孟浩然**——无任何史料连线，明说，不外溢；
--   * 鳏居孤处三十年=两传独立一致升 KNOWN；两传官历清单不同并列不裁决；
--   * 系年第十二次判决：送别无系事、两传不系年→零铸造零 relation；
--   * KNOWN 共两处，其余照 LIKELY。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 36，不含 37
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-sb-%';              -- 空
--   SELECT id FROM poetry_source WHERE id='source-quantangshi-125';     -- 空
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-054-ws';  -- 恰 6（六句）
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-sb-%';        -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-054';                                  -- 6（2/2/1/1）
--   SELECT certainty FROM poetry_claim WHERE id IN ('claim-bg-sb-world','claim-bg-sb-person');
--     -- KNOWN / KNOWN（world=两履历直书不外溢；person=鳏居两源合龙）
--   SELECT certainty FROM poetry_claim WHERE id IN ('claim-bg-sb-scene','claim-bg-sb-city');
--     -- LIKELY / LIKELY
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-054'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-054';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-sb-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
-- 回滚: recovery/V037_rollback.sql（按 id 全枚举删除；不动 V018 的行，不动共用来源行；
--   本迁移自开的 source-quantangshi-125 随回滚删除）
START TRANSACTION;

-- ---------- 0. 新 source（1 个；桩页如实标注，PENDING 照 V031/V035/V036 判例） ----------
INSERT INTO poetry_source (id, title, author, edition, url, rights_note, verification_status, source_kind, reliability)
SELECT * FROM (
SELECT 'source-quantangshi-125' AS id, '《全唐詩》全唐詩/卷125（维基文库录入本）' AS title, NULL AS author, '全唐詩/卷125（维基文库《全唐詩》录入本）' AS edition, 'https://zh.wikisource.org/wiki/全唐詩/卷125' AS url, '维基文库录入本，公有领域古籍。卷首 Collection header 的 noauthor 字段为空——卷页无作者标注（同卷126/卷164 无标注情形）。本诗条目只有锚点+消歧转引用桩（送別 (下馬飲君酒)），正文在诗页。本行由 emit_v037.py 对快照逐字定位。核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status, 'POETRY_COLLECTION' AS source_kind, 'HIGH' AS reliability FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_source x WHERE x.id = t.id);

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-sb-scene' AS id, 'BACKGROUND' AS entity_type, 'sb-scene' AS slug, '眼前：一杯酒的档案' AS title, '四层处境背景（阶段 D 第 18 首·六句第三形制 2/2/1/1）；史实句均有逐字引证；background_line 六句形制：scene→1-2 city→3-4 world→5 person→6；送别诗无系事+两传不系年→time.span/event.name/written_during 全缺席、零 relation；KNOWN 两处：一第一不第两履历直书（不外溢）+鳏居（两源合龙）；受赠人无名不发明；ws title 简体页形制声明不裁异文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-sb-city' AS id, 'BACKGROUND' AS entity_type, 'sb-city' AS slug, '这座城：只有归卧的方向' AS title, '四层处境背景（阶段 D 第 18 首·六句第三形制 2/2/1/1）；史实句均有逐字引证；background_line 六句形制：scene→1-2 city→3-4 world→5 person→6；送别诗无系事+两传不系年→time.span/event.name/written_during 全缺席、零 relation；KNOWN 两处：一第一不第两履历直书（不外溢）+鳏居（两源合龙）；受赠人无名不发明；ws title 简体页形制声明不裁异文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-sb-world' AS id, 'BACKGROUND' AS entity_type, 'sb-world' AS slug, '这个天下：一第与不第' AS title, '四层处境背景（阶段 D 第 18 首·六句第三形制 2/2/1/1）；史实句均有逐字引证；background_line 六句形制：scene→1-2 city→3-4 world→5 person→6；送别诗无系事+两传不系年→time.span/event.name/written_during 全缺席、零 relation；KNOWN 两处：一第一不第两履历直书（不外溢）+鳏居（两源合龙）；受赠人无名不发明；ws title 简体页形制声明不裁异文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-sb-person' AS id, 'BACKGROUND' AS entity_type, 'sb-person' AS slug, '这个人：无家可归的人送还乡的人' AS title, '四层处境背景（阶段 D 第 18 首·六句第三形制 2/2/1/1）；史实句均有逐字引证；background_line 六句形制：scene→1-2 city→3-4 world→5 person→6；送别诗无系事+两传不系年→time.span/event.name/written_during 全缺席、零 relation；KNOWN 两处：一第一不第两履历直书（不外溢）+鳏居（两源合龙）；受赠人无名不发明；ws title 简体页形制声明不裁异文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-sb-scene' AS id, 'bg-sb-scene' AS subject_id, 'context' AS property_key, '下马/饮酒/问所之全诗本文；送别场景之外零外推（两传无一字涉饯行）；被送者无名——诗题与卷125 消歧均只到首句，不发明受赠人。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-sb-city' AS id, 'bg-sb-city' AS subject_id, 'context' AS property_key, '饯地在长安=由旧传右丞官历推定（推定非直载，LIKELY）；南山实指泛指南本地无法裁决（辋川别业同山带仅作旁注）；无名无城——两源桩页逐字支持「消歧只到首句」。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-sb-world' AS id, 'bg-sb-world' AS subject_id, 'context' AS property_key, '一第一不第两条路两传各自直书：孟浩然「應進士不第」段与王维「開元初擢進士」段各自单源逐字（事件直书，V028 判例升 KNOWN）；此 KNOWN 只覆盖两条履历本身，**不外溢到诗**：被送者非孟浩然（无任何史料连线，明说）→诗 time.span/event.name/written_during 零铸造、零 relation。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-sb-person' AS id, 'bg-sb-person' AS subject_id, 'context' AS property_key, 'KNOWN 一处：王维鳏居孤处三十年——旧传「不再娶/孤居一室/屏絶塵累」与新传「喪妻不娶/孤居三十年」两源独立一致；两传官历清单不同——并列不裁决；certainty 不覆盖任何系年与受赠人身份。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-sb-scene' AS subject_id, 'context' AS property_key, 'claim-bg-sb-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-sb-city' AS subject_id, 'context' AS property_key, 'claim-bg-sb-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-sb-world' AS subject_id, 'context' AS property_key, 'claim-bg-sb-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-sb-person' AS subject_id, 'context' AS property_key, 'claim-bg-sb-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-sb-scene' AS id, 'work-t300-054' AS work_id, 'SCENE' AS layer, '这场送别从一杯酒开始：「下馬飲君酒，問君何所之」——下马，请你喝一杯，问你去哪儿。全唐诗三百首里的送别，这是最短的一道档案：没有地名，没有天气，没有流泪。
本传给不了这场酒——两传写王维，一条也没提到他给人饯行。被送的人史料里也不存在（见 CITY 层）。所以这场酒的证据只有诗本身二十个字：下马、举杯、问一句。别的都是我们想加的。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-sb-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-sb-city' AS id, 'work-t300-054' AS work_id, 'CITY' AS layer, '这座城在诗里只露一个方向：「歸臥南山陲」——你要回终南山脚下睡去了。饯别的城按王维的官历应在长安（旧传「轉尚書右丞」——右丞是长安的官），但诗连长安二字都没给；南山是实指还是泛指，本地史料无法裁决——王维自己的别业在蓝田辋口（V035 已立），与终南山同一条山带，这最多说明「南山」在他嘴里不会是无的放矢。
被送者是谁：诗题只作「送別」（ws 页与全唐诗卷125 的消歧都只到首句「(下馬飲君酒)」）——姓名不入史料，我们就不发明。无名，无城，只有「歸臥」的方向感。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-sb-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-sb-world' AS id, 'work-t300-054' AS work_id, 'WORLD' AS layer, '「但去莫復問」——去吧，不必再问了。这五个字的重量，来自那个时代人人都懂的半句话：「君言不得意」。不得意是什么？本地史料给了同时代的两条路：
旧唐书孟浩然传全文只有六十三字，字字都在说这条路的难：「年四十來遊京師，應進士不第，還」——四十岁进京，落第，回去；「襄陽張九齡鎮荆州，署為從事，與之唱和，不逹而卒」——宰相旧友给他一份幕职，最后还是「不达而卒」。旧史连安慰都懒得写。
另一条路在新唐书王维传里：「開元初，擢進士」——同一时代，有人一第入仕，有人四十落第。送别的酒桌上站着的是第二条路的人：「不得意」不需要解释，因为满朝都是听懂的人。' AS body_text, 'SENIOR' AS audience, 'claim-bg-sb-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-sb-person' AS id, 'work-t300-054' AS work_id, 'PERSON' AS layer, '「白雲無盡時」——山里的白云没有尽头。写这五个字的人，两唐书在同一个事实上合了龙：旧传「妻亡不再娶，三十年孤居一室，屏絶塵累」，新传「喪妻不娶，孤居三十年」——妻子死后不再娶，一个人住了三十年，断绝尘世牵累。两源独立一致，这一处升 KNOWN：写「白云无尽」的王维，自己就是无家可归去的人。
所以这首送别的读法整个反了过来：送的人比被送的更「归卧」——朋友回南山，是「不得意」的退路；王维的孤居一室，早就是他的常态。「但去莫復問」因此不是洒脱，是同类认出了同类：你的路我懂，别解释了。
旧传官历（太子中允→中庶子→中书舍人→给事中→右丞）与新传官历清单不同——两传做官履历各说各话，照登不裁决，与 V035 辋川段同款处理。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-sb-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-sb-scene' AS claim_id, 'source-ws-t300-054' AS source_id, '页面 送別（header title+author 两字段+第1、2句，四段以「……」相連——**title 行简体「送别」而诗身繁体，为维基文库页形制非 Witness 异文，逐字照录**；页内实测无 {{另|}} 异文，「查过、干净」；同名组诗消歧靠首句；全文另见 V018 claim-t300-054-text 引文）' AS locator, '| title    = 送别……| author   = 王維……下馬飲君酒，……下馬飲君酒，問君何所之。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-sb-city' AS claim_id, 'source-ws-t300-054' AS source_id, '页面 送別（第3、4句逐字——「南山陲」是城层唯一的诗内方位）' AS locator, '君言不得意，……君言不得意，歸臥南山陲。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-sb-city' AS claim_id, 'source-quantangshi-125' AS source_id, '页面 全唐詩/卷125（本诗锚点+消歧转引用桩 {{:送別 (下馬飲君酒)}}——卷页繁体「送別」与 ws 页 title 行简体「送别」各按本页原样；卷首 Collection header 的 noauthor 字段为空——卷页无作者标注、无正文，正文证据在诗页；同 V022/V025–V036 桩教训）' AS locator, '==[[送別 (下馬飲君酒)|送別]]==
{{:送別 (下馬飲君酒)}}' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-sb-city' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十下·文苑下·王维传官历段（太子中允至尚書右丞——右丞为长安官，饯地在长安由此推定；两传官历清单不同，另侧见新传引文）' AS locator, '太子中允，乾元中，遷太子中庶子、中書舍人，復拜給事中，轉尚書右丞。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-sb-world' AS claim_id, 'source-ws-t300-054' AS source_id, '页面 送別（第5句逐字——「但去莫復問」与下方两条履历并读）' AS locator, '但去莫復問，' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-sb-world' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十下·文苑下·孟浩然传（年四十來遊京師，應進士不第，還——旧传孟传侧全部家底六十三字中的两段，逐字全收；不第线直书）' AS locator, '年四十來遊京師，應進士不第，還。……襄陽張九齡鎮荆州，署為從事，與之唱和，不逹而卒。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-sb-world' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百零二·文藝中·王维传首段（開元初擢進士——及第线直书，与旧传孟浩然段并读成一第一不第之两路）' AS locator, '開元初，擢進士，調太樂丞，坐累為濟州司倉參軍。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-sb-person' AS claim_id, 'source-ws-t300-054' AS source_id, '页面 送別（第6句逐字——「白雲無盡時」与下方鳏居两源合龙对读）' AS locator, '但去莫復問，白雲無盡時。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-sb-person' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十下·文苑下·王维传鳏居段（妻亡不再娶/三十年孤居一室/屏絶塵累——两源合龙第一源）' AS locator, '妻亡不再娶，三十年孤居一室，屏絶塵累。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-sb-person' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百零二·文藝中·王维传鳏居段（喪妻不娶/孤居三十年——两源合龙第二源；措辞各自逐字，孤居年数两源一致）' AS locator, '喪妻不娶，孤居三十年。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（六句第三形制：2/2/1/1） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-sb-scene' AS background_id, 'text-work-t300-054-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-sb-scene' AS background_id, 'text-work-t300-054-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-sb-city' AS background_id, 'text-work-t300-054-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-sb-city' AS background_id, 'text-work-t300-054-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-sb-world' AS background_id, 'text-work-t300-054-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-sb-person' AS background_id, 'text-work-t300-054-ws' AS version_id, 6 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 37, 'Wang Wei Song-bie (seeing a friend off) background layers (stage-D poem 18, third line-shape: six-line poem 2/2/1/1): the why sits inside the twenty syllables -- jun yan bu-de-yi, gui wo Nan-shan chui (you say you came to nothing; you go home to sleep at the edge of South Mountain); local history supplies the era-weight of those three words via two parallel resumes quoted from two sources: JTS Meng Haoran, forty to the capital, failed the jinshi, went home, and died without advancement (his entire JTS biography is 63 characters, all quoted), XTS Wang Wei, passed the jinshi in early kai-yuan -- two recorded resumes raised KNOWN as annalistic statements but never overflowing to the poem: the farewell guest is NOT Meng Haoran (no source connects them; said plainly); a second KNOWN: Wang Wei widowed and unwed for thirty years, JTS (qi wang bu zai qu...) plus XTS (sang qi bu qu...) two independent sources in agreement -- the man who wrote endless white clouds had no home to go to, which reads the farewell backwards; dating verdict twelve: a farewell poem with no dated event, unnamed guest (title and both disambiguating stubs reach only the first line), no chronology in either history -- time.span/event.name/written_during absent, zero relations; the sending city Chang-an is an inference from the Right Vice Minister post (LIKELY, not stated); South Mountain literal-or-general left unruled; the ws page title line carries the simplified form of the title while the poem body is traditional -- a Wikisource page-shape quirk, not a witness variant: quoted verbatim as-is on each side, declared in the locator, no variants.md row; one new source: quan-tang-shi juan 125 page (anchor plus disambiguated transclusion stub; noauthor empty per V035/V036 precedent, PENDING)'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 37);
COMMIT;
