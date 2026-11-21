-- V035：王维《輞川閑居贈裴秀才迪》(work-t300-062) 四层背景（阶段 D 第 16 首·第一首赠诗）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V015、V016、V018 已执行（work-t300-062 与其 text-work-t300-062-ws、
--       source-ws-t300-062 是 V018 的行；source-jiutangshu-wenyuan / source-xintangshu-wenyi
--       是 V016 的行；source-zizhi-tongjian-events 是 V015 的行——都不另开行）。
--
-- 数据源（可复现）：emit_v035.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/輞川閑居贈裴秀才迪.txt（页内实测无 {{另}}——「查过、干净」）、
--   舊唐書卷190下（王维传——辋川段「裴廸」+凝碧段诗全文+诗名段）、新唐書卷202（王维传——
--   辋川段「裴迪」+奉佛段+凝碧段，与旧传次序相反）、資治通鑑卷218（756 标准形年标题+
--   凝碧池条；快照页头 {{Textquality|50%}} 如实声明）、全唐詩卷126（锚点+转引用桩，
--   noauthor 空——卷页无作者标注）。
--   通鉴缺席断言基础：tj-191–265 75/75 完整性已验证（2026-11-20 缺口补齐+错误页扫描），
--   王维全量零命中、裴迪仅许晚唐 902/904 两卷同名命中——生成器内置复验，越界即拒绝生成。
--
-- 做：1 个新 source（source-quantangshi-126，PENDING——桩页教训同款）+
--   4 BACKGROUND content/claim/background + 9 组逐字引用（(claim,source) 主键每对恰一行）+
--   8 行 background_line（八行常形制：每层两行 1-2/3-4/5-6/7-8，绑 text-work-t300-062-ws）。
--   本迁移不碰 poetry_text_line。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「别墅无得第之年 + 两传次序相反 + 人零命中而事件在卷」）：
--   * 辋川别业存在=两传各自逐字（得宋之問藍田别墅/別墅在輞川）——两源独立一致升 KNOWN；
--     得第之年无一字（宋之問卒年 712 只是下限常识，不做年表式演算）；
--   * 旧传辋川段在安史乱前叙事侧、新传在乱后侧——**传文次序不是编年**，并列不裁决；
--   * 756 凝碧池=通鉴标准形年标题逐字（事件 KNOWN，V028/V033 判例），锁陷贼段不锁闲居——
--     事件年与诗年无关，不外溢；
--   * 王维其人在通鉴 75 卷零命中、裴迪在其世纪零命中（晚唐 902/904 同名异人两卷机器隔离）
--     ——人缺席≠事件缺席，两行分开写明；
--   * 裴廸（旧）/裴迪（新）同人次异写——两处均逐字入证，KNOWN 升酬唱一处；
--     晚唐同名刑部尚書裴迪（卷20下）异代异人已声明隔离；
--   * KNOWN 共三处（辋川别业/辋川酬唱/756 事件）；独得处（宋之問旧第/六景点名/
--     官历清单/奉佛段/集名/凝碧诗全文）按 LIKELY 照登。
--
-- 干支对账：756=丙申（至德元年，tj-218 标准形年标题，audit 检查4 覆盖）。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 34，不含 35
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-wc-%';              -- 空
--   SELECT id FROM poetry_source WHERE id='source-quantangshi-126';     -- 空
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-062-ws';  -- 恰 8
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-wc-%';        -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-062';                                  -- 8（每层两行）
--   SELECT certainty FROM poetry_claim WHERE id IN ('claim-bg-wc-city','claim-bg-wc-world','claim-bg-wc-person');
--     -- KNOWN / KNOWN / KNOWN（city=别业存在两源；world=756 事件不外溢；person=酬唱两源）
--   SELECT certainty FROM poetry_claim WHERE id='claim-bg-wc-scene';    -- LIKELY
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-062'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-062';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-wc-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
-- 回滚: recovery/V035_rollback.sql（按 id 全枚举删除；不动 V018 的行，不动共用来源行；
--   本迁移自开的 source-quantangshi-126 随回滚删除）
START TRANSACTION;

-- ---------- 0. 新 source（1 个；桩页如实标注，PENDING 照 V031 判例） ----------
INSERT INTO poetry_source (id, title, author, edition, url, rights_note, verification_status, source_kind, reliability)
SELECT * FROM (
SELECT 'source-quantangshi-126' AS id, '《全唐詩》全唐詩/卷126（维基文库录入本）' AS title, NULL AS author, '全唐詩/卷126（维基文库《全唐詩》录入本）' AS edition, 'https://zh.wikisource.org/wiki/全唐詩/卷126' AS url, '维基文库录入本，公有领域古籍。卷首 Collection header 的 noauthor 字段为空——卷页无作者标注（与卷160 的孟浩然标注不同）。本诗条目只有锚点+转引用桩，正文在诗页。本行由 emit_v035.py 对快照逐字定位。核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status, 'POETRY_COLLECTION' AS source_kind, 'HIGH' AS reliability FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_source x WHERE x.id = t.id);

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-wc-scene' AS id, 'BACKGROUND' AS entity_type, 'wc-scene' AS slug, '眼前：柴门外的秋天' AS title, '四层处境背景（阶段 D 第 16 首·第一首赠诗）；史实句均有逐字引证；background_line 八行常形制：每层两行（1-2/3-4/5-6/7-8）；别墅无得第之年+两传次序相反→time.span/event.name/written_during 全缺席、零 relation；756 凝碧池 KNOWN 仅事件本体不外溢；KNOWN 三处：辋川别业（两源）+辋川酬唱（两源，廸/迪并证）+756 事件（编年直书）。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-wc-city' AS id, 'BACKGROUND' AS entity_type, 'wc-city' AS slug, '这块地：京城之侧的山谷' AS title, '四层处境背景（阶段 D 第 16 首·第一首赠诗）；史实句均有逐字引证；background_line 八行常形制：每层两行（1-2/3-4/5-6/7-8）；别墅无得第之年+两传次序相反→time.span/event.name/written_during 全缺席、零 relation；756 凝碧池 KNOWN 仅事件本体不外溢；KNOWN 三处：辋川别业（两源）+辋川酬唱（两源，廸/迪并证）+756 事件（编年直书）。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-wc-world' AS id, 'BACKGROUND' AS entity_type, 'wc-world' AS slug, '这个天下：人不进通鉴，事在通鉴' AS title, '四层处境背景（阶段 D 第 16 首·第一首赠诗）；史实句均有逐字引证；background_line 八行常形制：每层两行（1-2/3-4/5-6/7-8）；别墅无得第之年+两传次序相反→time.span/event.name/written_during 全缺席、零 relation；756 凝碧池 KNOWN 仅事件本体不外溢；KNOWN 三处：辋川别业（两源）+辋川酬唱（两源，廸/迪并证）+756 事件（编年直书）。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-wc-person' AS id, 'BACKGROUND' AS entity_type, 'wc-person' AS slug, '这两个人：接舆与五柳' AS title, '四层处境背景（阶段 D 第 16 首·第一首赠诗）；史实句均有逐字引证；background_line 八行常形制：每层两行（1-2/3-4/5-6/7-8）；别墅无得第之年+两传次序相反→time.span/event.name/written_during 全缺席、零 relation；756 凝碧池 KNOWN 仅事件本体不外溢；KNOWN 三处：辋川别业（两源）+辋川酬唱（两源，廸/迪并证）+756 事件（编年直书）。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-wc-scene' AS id, 'bg-wc-scene' AS subject_id, 'context' AS property_key, '前四句纯景全诗本文；「闲居」为诗题本文；弹琴赋诗/啸咏终日为旧传近证（LIKELY）；季节（秋水/暮蝉）有诗内证据，写作年份两传无一字——不编。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-wc-city' AS id, 'bg-wc-city' AS subject_id, 'context' AS property_key, '辋川别业存在（蓝田辋口/辞水环绕）——旧传「得宋之問藍田别墅」段与新传「別墅在輞川」段两源独立一致；产业来源（宋之問旧第）与六景点名各为单传独得（LIKELY）；两传官历清单不同——并列不裁决；到凉州/边地无关此人此诗。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-wc-world' AS id, 'bg-wc-world' AS subject_id, 'context' AS property_key, '756 年标题（标准形，丙申对账由 audit 检查4 覆盖）+凝碧池条通鉴逐字——编年体直书，事件本体升 KNOWN（V028/V033 事件判例）；此 KNOWN **只覆盖事件，不外溢到诗**：王维陷贼与辋川闲居的先后无年可系（两传次序相反）→诗 time.span/event.name/written_during 零铸造、零 relation；王维其人在通鉴 75 卷零命中、裴迪在其世纪零命中（晚唐同名异人两卷除外，见 PERSON 层护栏）（完整性已验证集上复扫）——人缺席事件在卷，两行都写明。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-wc-person' AS id, 'bg-wc-person' AS subject_id, 'context' AS property_key, 'KNOWN 一处：王维裴迪辋川酬唱——旧传「裴廸」段与新传「裴迪」段两源独立一致（廸/迪异写均逐字入证）；两传独得处（奉佛段新传/集名旧传/凝碧诗全文旧传）均 LIKELY 并列照登；晚唐同名裴迪（天祐间刑部尚書）异代异人已明说隔离；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-wc-scene' AS subject_id, 'context' AS property_key, 'claim-bg-wc-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-wc-city' AS subject_id, 'context' AS property_key, 'claim-bg-wc-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-wc-world' AS subject_id, 'context' AS property_key, 'claim-bg-wc-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-wc-person' AS subject_id, 'context' AS property_key, 'claim-bg-wc-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-wc-scene' AS id, 'work-t300-062' AS work_id, 'SCENE' AS layer, '这首诗的前四句是中国诗里最安静的一段：「寒山轉蒼翠，秋水日潺湲。倚杖柴門外，臨風聽暮蟬」——冬天的山转成苍色，秋天的水整日潺湲，老人拄着杖站在柴门外，迎风听暮色里的蝉。
「閑居」两个字写在诗题里，不用猜。本传能给的最近的一条是旧传的「彈琴賦詩，嘯詠終日」——辋川的日子就是这种规格。至于这场暮蝉是哪一年的秋天，两传无一字；「秋水」「暮蟬」是诗内证据，季节在诗里，年份不在。季节有证、年份没有——这首的诚实边界从这里开始。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-wc-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-wc-city' AS id, 'work-t300-062' AS work_id, 'CITY' AS layer, '这座城不在诗里——辋川不是城，是长安东边蓝田辋口的一片山谷别墅。旧传给出产业来源：「得宋之問藍田别墅，在輞口，輞水周於舍下」——这产业是从宋之問手里来的；新传给出地形景点：「別墅在輞川，地奇勝，有華子岡、欹湖、竹裏館、柳浪、茱萸沜、辛夷塢」——六个景点名逐一列出。两源独立一致升 KNOWN 的这一点：王维在蓝田辋口有一处辋水环绕的别业。
他实际的城串在两传里排不开：旧传「歴右拾遺、監察御史、左補闕、庫部郎中」一路到「轉尚書右丞」（后世叫他王右丞即此）；新传却从「調太樂丞，坐累為濟州司倉參軍」起，又添「張九齡執政，擢右拾遺」——**两传官历清单不同**，照登不裁决。辋川就悬在这串官职的边上：不是长安，不是边塞，是京城之侧的山。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-wc-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-wc-world' AS id, 'work-t300-062' AS work_id, 'WORLD' AS layer, '「渡頭餘落日，墟里上孤煙」——诗里的天下小到一个渡口一缕炊烟；这个人真正撞上的天下，是十几年后的一场大乱。
先说一个奇事：**王维其人不进通鉴**——通鉴 191–265 全部 75 卷（2026-11-20 完整性全量验证）零「王維」命中。但他最著名的传记场景在通鉴里：至德元年（丙申，公元七五六年）条下，「祿山宴其群臣於凝碧池……樂工雷海清不勝悲憤，擲樂器於地，西向慟哭。祿山怒……支解之」——人缺席，事件在卷，事件本体（编年体直书）升 KNOWN。两唐书各记下王维被贼所得、服药装哑、迫受伪职、闻乐潜诗——旧传连他的诗都全文收了：「萬户傷心生野煙，百官何日再朝天？秋槐花落空宫裏，凝碧池頭奏筦絃。」
但 756 锁的是陷贼那一段，锁不到辋川：这首诗是闲居赠人之作，乱前乱后无年可系——年表式演算不做。time.span、event.name、written_during 一个都不造。' AS body_text, 'SENIOR' AS audience, 'claim-bg-wc-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-wc-person' AS id, 'work-t300-062' AS work_id, 'PERSON' AS layer, '「復值接輿醉，狂歌五柳前」——这首诗的最后一联里站着两个人：接舆（楚狂人）指裴迪，五柳（陶渊明）是王维自拟。赠诗赠到这里，等于说：你是我那个疯子朋友，我是这个山谷里的陶潜。
这个朋友在两唐书里各出现一次，用字还不同——旧传作「與道友**裴廸**浮舟往來，彈琴賦詩，嘯詠終日」，新传作「與**裴迪**遊其中，賦詩相酬為樂」：廸/迪两个写法都是逐字原文，同一个人；两源独立一致升 KNOWN 的正是这一点：王维与裴迪在辋川的隐居酬唱。
两传独得处并列照登不升：新传「兄弟皆篤志奉佛，食不葷，衣不文彩」；旧传「甞聚其田園所為詩，號輞川集」（集名是旧传单得）。裴迪其人官历两传均无一字——诗题就叫他「裴秀才」，秀才是他能给的全部身份。
同名护栏必须立住：旧唐书本纪（卷二十下，天祐年间）有个做到刑部尚書的「裴迪」——晚唐百余年后的同名异人，与本诗这位 never 出仕的秀才不是一个人，查史料时千万别串。' AS body_text, 'SENIOR' AS audience, 'claim-bg-wc-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-wc-scene' AS claim_id, 'source-ws-t300-062' AS source_id, '页面 輞川閑居贈裴秀才迪（header title+author 两字段+第1、2句，四段以「……」相連——赠诗受赠人题内直证+开场纯景；页内实测无 {{另|}} 异文，「查过、干净」；全文另见 V018 claim-t300-062-text 引文）' AS locator, '| title    = 輞川閑居贈裴秀才迪……| author   = 王維……寒山轉蒼翠，……寒山轉蒼翠，秋水日潺湲。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-wc-city' AS claim_id, 'source-quantangshi-126' AS source_id, '页面 全唐詩/卷126（本诗锚点+转引用桩 {{:輞川閑居贈裴秀才迪}}；卷首 Collection header 的 noauthor 字段为空——卷页无作者标注、无正文，正文证据在诗页；同 V022/V025–V031 桩教训）' AS locator, '==[[輞川閑居贈裴秀才迪]]==
{{:輞川閑居贈裴秀才迪}}' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-wc-city' AS claim_id, 'source-ws-t300-062' AS source_id, '页面 輞川閑居贈裴秀才迪（第3、4句逐字——柴门暮蝉：别业生活的诗内直证，与两传辋川段对读）' AS locator, '倚杖柴門外，……倚杖柴門外，臨風聽暮蟬。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-wc-city' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十下·文苑下·王维传辋川段（得宋之問藍田别墅/在輞口/與道友裴廸——**旧传用「廸」字**，与新传「迪」并证同一人；「號輞川集」三字旧传单得）' AS locator, '得宋之問藍田别墅，在輞口，輞水周於舍下，别漲竹洲花塢，與道友裴廸浮舟往來，彈琴賦詩，嘯詠終日。甞聚其田園所為詩，號輞川集。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-wc-world' AS claim_id, 'source-ws-t300-062' AS source_id, '页面 輞川閑居贈裴秀才迪（第5、6句逐字——渡口炊烟的小天下与下方大乱并读）' AS locator, '渡頭餘落日，……渡頭餘落日，墟里上孤煙。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-wc-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '通鑑卷二百十八·唐紀三十四·肅宗·至德元年（丙申，公元七五六年）标题+凝碧池条（两段以「……」相連，年标题归属已分记——该卷快照页头 {{Textquality|50%}} 已声明；全卷唯一纪年标题，条目归属由生成器位置断言；**王维其人全通鉴 75 卷零命中**——人缺席事件在卷）' AS locator, '肅宗文明武德大聖大宣孝皇帝上之下至德元年（丙申，公元七五六年）……祿山宴其群臣於凝碧池，盛奏眾樂；梨園弟子往往歔欷泣下，賊皆露刃睨之。樂工雷海清不勝悲憤，擲樂器於地，西向慟哭。祿山怒，縛於試馬殿前，支解之。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-wc-person' AS claim_id, 'source-ws-t300-062' AS source_id, '页面 輞川閑居贈裴秀才迪（第7、8句逐字——接舆拟裴/五柳自拟：两人并立的诗内直证，与两传裴廸/裴迪段对读）' AS locator, '復值接輿醉，……復值接輿醉，狂歌五柳前。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-wc-person' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十下·文苑下·王维传凝碧段（禄山陷两都/服药取痢/伪称瘖/凝碧宫潜为诗——凝碧诗全文唯旧传收，诗非三百首内作，作人证引用；禄字从旧传录本）' AS locator, '禄山䧟兩都，玄宗出幸，維扈從不及，為賊所得。維服藥取痢，偽稱瘖病。禄山素憐之，遣人迎置洛陽，拘於普施寺，迫以偽署。禄山宴其徒於凝碧宫，其樂工皆梨園弟子、教坊工人。維聞之悲惻，潛為詩曰：「萬户傷心生野煙，百官何日再朝天？秋槐花落空宫裏，凝碧池頭奏筦絃。」……維以詩名盛於開元、天寶間，昆仲宦遊兩都，凡諸王駙馬豪右貴勢之門，無不拂席迎之，寧王、薛王待之如師友。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-wc-person' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百零二·文藝中·王维传（张九龄段+辋川段+奉佛段+凝碧段；四段以「……」相連，出处同卷同传——**新传辋川段在安史段之后**，与旧传次序相反，传文次序不作编年用，声明在 BG 正文）' AS locator, '張九齡執政，擢右拾遺。……別墅在輞川，地奇勝，有華子岡、欹湖、竹裏館、柳浪、茱萸沜、辛夷塢，與裴迪遊其中，賦詩相酬為樂。……兄弟皆篤志奉佛，食不葷，衣不文彩。……安祿山反，玄宗西狩，維為賊得，以藥下利，陽喑。祿山素知其才，迎置洛陽，迫為給事中。祿山大宴凝碧池，悉召梨園諸工合樂，諸工皆泣，維聞悲甚，賦詩悼痛。賊平，皆下獄。或以詩聞行在，時縉位已顯，請削官贖維罪，肅宗亦自憐之，下遷太子中允。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（八行常形制：每层两行） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-wc-scene' AS background_id, 'text-work-t300-062-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-wc-scene' AS background_id, 'text-work-t300-062-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-wc-city' AS background_id, 'text-work-t300-062-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-wc-city' AS background_id, 'text-work-t300-062-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-wc-world' AS background_id, 'text-work-t300-062-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-wc-world' AS background_id, 'text-work-t300-062-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-wc-person' AS background_id, 'text-work-t300-062-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-wc-person' AS background_id, 'text-work-t300-062-ws' AS version_id, 8 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 35, 'Wang Wei Wang-chuan xian-ju zeng Pei Xiu-cai Di background layers (stage-D poem 16, first gift-poem): the two Tang histories each record one Wang Wei -- the JTS supplies the Wang-chuan estate inherited from Tsung Chih-wen (with friend Pei Ti, graph ti with the walk radical, exchanging poems all day, and his full Ning-bi-pool mourning poem), the XTS supplies the six named garden sites, the devout-Buddhism lines and Pei Di with the walking radical -- same man, two graph variants, both quoted verbatim; KNOWN at exactly three points (the Wang-chuan estate, both sources; the Wang-Wei-Pei-Di retreat friendship, two sources; the 756 CE Ning-bi-pool banquet, standard-form year heading Zhi-de 1 (bing-shen) in tong-jian ju 218, annalistic, V028/V033 event precedent -- the event never overflows to the poem); dating absent for the tenth reason: the estate has no acquisition year (Tsung Chih-wen-d-s 712 death is only a lower-bound commonplace, no year-table arithmetic), late years is not a year, and the two histories place the Wang-chuan passage on opposite sides of the An Lushan narrative (biography order is not chronology -- side by side, no ruling); new twist: Wang Wei and Pei Di score ZERO mentions across all 75 integrity-verified tong-jian volumes (tj-191 to 265) -- the man is absent from the annals while his most famous scene stands in them, both facts said separately; a same-name guard: a much later Pei Di who became Vice Minister of Justice under the Tian-you reign (JTS basic annals 20xia) is a different man of a different century and is explicitly separated; one new source: quan-tang-shi juan 126 page (anchor plus transclusion stub; its Collection header carries an empty noauthor field -- no author attribution on the volume page, said honestly; PENDING per V031 precedent); time.span/event.name/written_during absent, zero relations; background_line shape: two lines per layer (1-2/3-4/5-6/7-8)'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 35);
COMMIT;
