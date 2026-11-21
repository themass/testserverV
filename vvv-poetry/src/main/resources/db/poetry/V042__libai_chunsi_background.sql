-- V042：李白《春思》(work-t300-312) 四层背景（阶段 D 第 23 首·六句 2/2/1/1 第二用）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V015、V016、V018 已执行（work-t300-312 与其 text-work-t300-312-ws、
--       source-ws-t300-312 是 V018 的行；source-jiutangshu-wenyuan / source-xintangshu-wenyi
--       是 V016 的行；source-zizhi-tongjian-events 早期迁移已立——均不另开）。
-- 本迁移**恰 1 个新 source**：source-quantangshi-165（卷页桩，断言恰 1 个，回滚同步删除）。
--
-- 数据源（可复现）：emit_v042.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/春思__李白_.txt（页顶 {{Further}} 消歧模板照登；页面零异文标记——反向断言）、
--   新唐書卷202（李白传出生段+访后裔段——切片传区间归属生成时断言）、
--   通鉴 tj-214（734 幽州条——帝标题位置断言 V034 立规）、
--   quantangshi/vol165（本诗条目桩）。
--   负证机器复查（生成时）：两传李白传区间「燕」「幽州」计数均为零，否则中止。
--
-- 做：1 个新 source + 4 BACKGROUND content/claim/background +
--   4 组逐字引用（(claim,source) 主键每对恰一行）+
--   6 行 background_line（**六句形制 2/2/1/1 第二用**：scene→1-2 city→3-4 world→5 person→6，
--   绑 text-work-t300-312-ws 的 6 行）。本迁移不碰 poetry_text_line。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是代辞——persona 分离首次成为判决主题）：
--   * 抒情「我」=思妇，不并入传记「我」：两传李白妻儿零记载，
--     唯一「妻」字在曾孙辈「二孫女嫁為民妻」（访裔段逐字立证）——不写「李白思念妻子」；
--   * 双城（燕/秦）皆不在两传行迹：负证由生成时计数复查，非人工目测；
--   * 通鉴 734 幽州条只立「燕地=边镇」制度形状，与诗零关联；
--   * 整首零 KNOWN：母夢長庚单得不升、妻儿零载是负证——不为凑数升格，账本如实；
--   * 「为传不进史书者立文」等感情句全部标明读法。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 41，不含 42
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-cs-%';              -- 空
--   SELECT id FROM poetry_source WHERE id='source-quantangshi-165';     -- 空
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-312-ws';  -- 恰 6（六句）
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-cs-%';        -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-312';                                  -- 6（2/2/1/1）
--   SELECT certainty FROM poetry_claim WHERE id LIKE 'claim-bg-cs-%';   -- 四行全 LIKELY（有意零 KNOWN）
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-312'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-312';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-cs-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
-- 回滚: recovery/V042_rollback.sql（按 id 全枚举删除；删 V042 自开的 source-quantangshi-165；
--   不动 V018 的行与共用来源行）
START TRANSACTION;

-- ---------- 0. 新 source（恰 1 个：全唐詩卷165 桩页，PENDING） ----------
INSERT INTO poetry_source (id, title, author, edition, url, rights_note, verification_status, source_kind, reliability)
SELECT * FROM (
SELECT 'source-quantangshi-165' AS id, '《全唐詩》全唐詩/卷165（维基文库录入本）' AS title, NULL AS author, '全唐詩/卷165（维基文库《全唐詩》录入本）' AS edition, 'https://zh.wikisource.org/wiki/全唐詩/卷165' AS url, '维基文库录入本，公有领域古籍。卷页只有诗题锚点+转引用桩，正文在诗页。本行由 emit_v042.py 对快照逐字定位。核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status, 'POETRY_COLLECTION' AS source_kind, 'HIGH' AS reliability FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_source x WHERE x.id = t.id);

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-cs-scene' AS id, 'BACKGROUND' AS entity_type, 'cs-scene' AS slug, '眼前：独角戏对不在场的人说' AS title, '四层处境背景（阶段 D 第 23 首·六句 2/2/1/1 第二用）；史实句均有逐字引证；background_line 六句形制：scene→1-2 city→3-4 world→5 person→6；系年第十七次判决「诗语有地，地不在传；诗有人，人不系传」（题证系列第五状·首见代辞 persona 分离）→time.span/event.name/written_during 全缺席、零 relation；整首零 KNOWN（如实记录非疏漏：长庚梦新传单得，妻儿零载是负证）；两传李白区间零燕字负证生成时机器复查；通鉴 734 幽州条年标题位置断言（V034 立规）。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-cs-city' AS id, 'BACKGROUND' AS entity_type, 'cs-city' AS slug, '这座城：双城都是戏台' AS title, '四层处境背景（阶段 D 第 23 首·六句 2/2/1/1 第二用）；史实句均有逐字引证；background_line 六句形制：scene→1-2 city→3-4 world→5 person→6；系年第十七次判决「诗语有地，地不在传；诗有人，人不系传」（题证系列第五状·首见代辞 persona 分离）→time.span/event.name/written_during 全缺席、零 relation；整首零 KNOWN（如实记录非疏漏：长庚梦新传单得，妻儿零载是负证）；两传李白区间零燕字负证生成时机器复查；通鉴 734 幽州条年标题位置断言（V034 立规）。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-cs-world' AS id, 'BACKGROUND' AS entity_type, 'cs-world' AS slug, '这个天下：燕草为何而绿' AS title, '四层处境背景（阶段 D 第 23 首·六句 2/2/1/1 第二用）；史实句均有逐字引证；background_line 六句形制：scene→1-2 city→3-4 world→5 person→6；系年第十七次判决「诗语有地，地不在传；诗有人，人不系传」（题证系列第五状·首见代辞 persona 分离）→time.span/event.name/written_during 全缺席、零 relation；整首零 KNOWN（如实记录非疏漏：长庚梦新传单得，妻儿零载是负证）；两传李白区间零燕字负证生成时机器复查；通鉴 734 幽州条年标题位置断言（V034 立规）。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-cs-person' AS id, 'BACKGROUND' AS entity_type, 'cs-person' AS slug, '这个人：档案里没有家庭' AS title, '四层处境背景（阶段 D 第 23 首·六句 2/2/1/1 第二用）；史实句均有逐字引证；background_line 六句形制：scene→1-2 city→3-4 world→5 person→6；系年第十七次判决「诗语有地，地不在传；诗有人，人不系传」（题证系列第五状·首见代辞 persona 分离）→time.span/event.name/written_during 全缺席、零 relation；整首零 KNOWN（如实记录非疏漏：长庚梦新传单得，妻儿零载是负证）；两传李白区间零燕字负证生成时机器复查；通鉴 734 幽州条年标题位置断言（V034 立规）。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-cs-scene' AS id, 'bg-cs-scene' AS subject_id, 'context' AS property_key, '六句全诗本文（ws 页零页内标记——另/别/自注三类皆无，audit 反向断言；页首 {{Further}} 消歧模板照登=选本同名诗并存直证）；独角戏/两个不同步的时候为本层读法声明。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-cs-city' AS id, 'bg-cs-city' AS subject_id, 'context' AS property_key, '双城皆戏台：燕/秦两名全不在两传行迹（负证机器复查：李白传区间「燕」「幽州」计数为零，生成时断言）；诗语有地，地不在传→不补传不系年不猜代辞对象；零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-cs-world' AS id, 'bg-cs-world' AS subject_id, 'context' AS property_key, '734 幽州条（年标题+六月壬辰幽州節度使張守珪大破契丹遣使獻捷，条在 734/735 帝标题区间内，生成时位置断言 V034 立规）——燕地=开天边军驻防区的制度形状；边镇入正史不推及此诗，零关联声明；思妇诗与边镇同呼吸为读法；诗 time.span/event.name/written_during 零铸造。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-cs-person' AS id, 'bg-cs-person' AS subject_id, 'context' AS property_key, 'persona 分离：代辞抒情我≠传记我（两传李白本人妻儿零记载——新传唯一「妻」字在曾孙辈「二孫女嫁為民妻」，访裔段逐字立证）；母夢長庚/隐岷山/举有道不应新传单得不升；整首零 KNOWN 为如实记录非疏漏；「为传不进史书者立文」标明读法；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-cs-scene' AS subject_id, 'context' AS property_key, 'claim-bg-cs-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-cs-city' AS subject_id, 'context' AS property_key, 'claim-bg-cs-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-cs-world' AS subject_id, 'context' AS property_key, 'claim-bg-cs-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-cs-person' AS subject_id, 'context' AS property_key, 'claim-bg-cs-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-cs-scene' AS id, 'work-t300-312' AS work_id, 'SCENE' AS layer, '六句是一场独角戏，台词全是「对不存在于场内的另一个人说」：燕地的草该像碧丝一样了吧，秦地的桑已经压弯了绿枝（「燕草如碧絲，秦桑低綠枝」——两个地方，两个人各看各的春）；你怀想归乡的那天，正是我断肠的时候（「當君懷歸日，是妾斷腸時」——两个「时候」不同步，诗把不同步本身写成全部感情）；风你不认得我我不认得你，你凭什么掀我的帐子（「春風不相識，何事入羅幃」——把春心问罪给风，是全唐诗里最聪明的一次岔开）。页首 {{Further}} 消歧模板照登：选本系统里另有一首同名《春思》——连标题都不独有。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-cs-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-cs-city' AS id, 'work-t300-312' AS work_id, 'CITY' AS layer, '这首诗横跨两个地方，**却一个都不在作者的地图上**：燕（幽州边镇方向）是「君」所在，秦（关中）是「妾」所在。李白的两传行迹：徂徠山、會稽、長安、金陵、庐山、宣城——机器复查：**两传区间内「燕」字与「幽州」出现次数均为零**（生成时断言，快照变动即中止）。他本人从没被史料放进燕地。
于是这座「城」是双城的，且两城都是戏台：诗语有地，地不在传——不是史料缺一条燕地行迹，而是这首诗本来就不需要作者到过那里。不补传，不系年，不猜为谁代辞。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-cs-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-cs-world' AS id, 'work-t300-312' AS work_id, 'WORLD' AS layer, '「燕草」为何而绿？通鉴给得干脆：734 年（開元二十二年）条「六月，壬辰，幽州節度使張守珪大破契丹，遣使獻捷」——条在 734 与 735 帝标题之间（生成器位置断言，V034 立规）。幽州节度使是开天年间最重的边镇之一，破契丹献捷是当年国闻：燕地是**驻防区**，「君」北上从军/幕游在那个年代有充分的制度理由，思妇诗的流行与边镇征兵同呼吸——这是读法，史料部分止于：734 年幽州确有大捷且入正史。
与王维那条「节令入正史不推及诗」同理：**边镇入正史不推及这首诗**——张守珪的捷报与《春思》零关联，账本如实断开。' AS body_text, 'SENIOR' AS audience, 'claim-bg-cs-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-cs-person' AS id, 'work-t300-312' AS work_id, 'PERSON' AS layer, '代辞需要被说破：**诗里的「妾」不是李白的经验档案，因为档案里没有家庭**。两传写李白，妻儿零记载——新传全文唯一的「妻」字在身后：范传正訪後裔，「惟二孫女嫁為民妻」——连「妻子」这种身份，史料都是在他曾孙辈身上第一次用到（V041 已立祭塚句，此处访裔句异侧再证）。不写「李白思念妻子」：传里连妻子都没有。
传给的开头是神话的：新传「白之生，母夢長庚星，因以命之」——名字是梦里那颗星给的；「十歲通詩書，既長，隱岷山。州舉有道，不應」——不出仕是他选的第一条路（新传单源，不升 KNOWN）。
一个被史实抹去家庭的人，写出唐诗里最好的思妇独白——「为什么写」在这首的答案只能是：为所有传不进史书的人称情而立文。此为读法，标明。' AS body_text, 'SENIOR' AS audience, 'claim-bg-cs-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-cs-scene' AS claim_id, 'source-ws-t300-312' AS source_id, '页面 春思 (李白)（页顶消歧模板+header title+author+六句全文，九段以「……」相連——页面零异文标记（Textquality 100%），无标记即不造标记；同一 (claim,source) 主键下一行容全文，V037/V039/V040/V041 判例；全文另见 V018 claim-t300-312-text 引文）' AS locator, '{{Further|春思}}……| title    = 春思……| author   = 李白……燕草如碧絲，……燕草如碧絲，秦桑低綠枝。……當君懷歸日，……當君懷歸日，是妾斷腸時。……春風不相識，……春風不相識，何事入羅幃。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-cs-city' AS claim_id, 'source-quantangshi-165' AS source_id, '卷一百六十五·李白诗目下本诗条目（锚点+转引用桩——卷页无正文，桩文照登；本迁移开立此来源行）' AS locator, '==[[春思 (李白)|春思]]==
{{:春思 (李白)}}' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-cs-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '通鉴卷二百一十四·玄宗開元二十二年（734）条（帝标题含{{*|甲戌，西元七三四年}}+六月壬辰幽州節度使張守珪大破契丹遣使獻捷——生成时位置断言：条在 734 与 735 帝标题之间；与李白零关联）' AS locator, '開元二十二年{{*|甲戌，西元七三四年}}……六月，壬辰，幽州節度使張守珪大破契丹，遣使獻捷。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-cs-person' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百零二·文藝中·李白传（出生段+访后裔段以「……」相連，同卷同传——母梦长庚/隐岷山单得不升；唯一「妻」字在曾孙辈，本人生无妻儿记载之负证正面文本；访裔段与 V041 祭塚句异侧不重叠）' AS locator, '白之生，母夢長庚星，因以命之。十歲通詩書，既長，隱岷山。州舉有道，不應。……訪後裔，惟二孫女嫁為民妻，進止仍有風範' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（六句 2/2/1/1） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-cs-scene' AS background_id, 'text-work-t300-312-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-cs-scene' AS background_id, 'text-work-t300-312-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-cs-city' AS background_id, 'text-work-t300-312-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-cs-city' AS background_id, 'text-work-t300-312-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-cs-world' AS background_id, 'text-work-t300-312-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-cs-person' AS background_id, 'text-work-t300-312-ws' AS version_id, 6 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 42, 'Li Bai Spring Thought background layers (stage-D poem 23, six-line 2/2/1/1 second use): dating verdict seventeen, fifth shape of the title-evidence series and the first ventriloquism case -- the lyric I is a waiting wife, not the biographical Li Bai: both biographies record zero wife-and-children (the only wife-character in the whole XTS life spans his great-granddaughters -- er sun-nv jia wei min-qi, quoted verbatim), so the library refuses to write Li Bai missing his wife -- persona separation made explicit; the poem carries two places (Yan, Qin) and neither stands on either biography-s itinerary, a negative proof re-checked by the generator itself (zero occurrences of the characters Yan / You-zhou inside the Li-Bai biography spans, generation aborts otherwise); the Tongjian entry for 734 (You-zhou commissioner Zhang Shou-gui smashes the Khitan, captives presented) pins Yan as a frontier garrison zone with heading-position assertion per the V034 rule, yet touches the poem zero times -- a frontier victory in the annals never drags the poem in; the whole poem carries zero KNOWN ratings, recorded as-is rather than padded: the long-geng dream birth-legend is XTS-single and stays LIKELY; zero new sources besides exactly one opened here (quan-tang-shi juan 165 stub page, rollback deletes it)'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 42);
COMMIT;
