-- V056：李白《怨情》(work-t300-331) 四层背景（阶段 D 第 37 首·同字两界）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V014、V015、V016、V018、V042、V055 已执行（work-t300-331 与其
--       text-work-t300-331-ws、source-ws-t300-331 是 V018 的行；
--       source-xintangshu-wenyi 是 V016 的行；source-zizhi-tongjian-events 是 V014/V015 已立的通鉴事件源）。
--       **本迁移零新 source**（audit 断言 SQL 无任何诗源表新建插入语句；卷184 无源行亦不新建）。
--
-- 数据源（可复现）：emit_v056.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/怨情__美人捲珠簾_.txt（底注空锚片段首见+{{另}}×2 照登+页名首句消歧）、
--   新唐書卷202（孙女辞改嫁句首引+李白段负证）、舊唐書卷190下（李白段负证+无此段断言）、
--   通鑑卷256（淚痕唯一一处+光啟二年窗口）+ 通鑑 75 卷/全唐詩 118 卷存快照负证计数扫描+
--   既有迁移引文域逐句查重——传区间归属、怨情/淚痕/蛾眉/珠簾/深坐全部计数、
--   年标题窗口、vol184 不在快照、首引前提与第二引前提全部生成时断言。
--
-- 做：4 BACKGROUND content/claim/background + 4 组逐字引用（(claim,source) 主键每对恰一行）+
--   4 行 background_line（四句形制 1/1/1/1：scene→1 city→2 world→3 person→4，
--   绑 text-work-t300-331-ws 的 4 行）。本迁移不碰 poetry_text_line。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「題有怨名，怨在兩部皆無檔；詩有淚字，淚在通鑑只一袍」）：
--   * 怨情通鉴全零+全唐詩快照全零（题面无档，机器断言）；淚痕通鉴恰一=御袍之泪（闭域+窗口断言）；
--   * 此诗正文第二引上限用满：V018 一引在先（全库查重恰一处），对后来迁移关闭；
--   * 底注空锚片段首见+底本指向不可核新形态：快照缺卷184——如实登记、零引用、不伪造对勘；
--   * 异文两支（蹙蛾眉/覺淚痕）快照内零命中（孤本在册）；他人淚痕 8 处不引；
--   * 新传孙女句首引（全库查重既往零引）；V042「進止仍有風範」前句零重开（audit 硬卡）；
--   * 两种女子一虚一实、泪两界均为读法声明，audit 双声明在 BG 文本内；
--   * KNOWN 零如实记录（第十二例，audit 反向断言 SQL 无 KNOWN 字面量）；
--   * 山東人（V016/V032 两度已满）/謫仙人/脫靴/沈香亭/賜金放還/宮錦袍/夜郎/青山 判例只引不重开。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 55，不含 56
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-331-%';             -- 空
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-331-ws';  -- 恰 4
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-331-%';       -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-331';                                  -- 4（1/1/1/1）
--   SELECT certainty FROM poetry_claim WHERE id LIKE 'claim-bg-331-%';  -- 四行全 LIKELY（有意全 LIKELY）
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-331'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-331';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-331-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
--   SELECT COUNT(*) FROM poetry_source WHERE id='source-ws-t300-331';   -- 恰 1（V018 旧行，零新源）
-- 回滚: recovery/V056_rollback.sql（按 id 全枚举删除；不动任何共用来源行、不动 V018 的行）
START TRANSACTION;

-- ---------- 1. BACKGROUND content identities（零新 source——断言在生成器 audit） ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-331-scene' AS id, 'BACKGROUND' AS entity_type, '331-scene' AS slug, '眼前：恨在不具名的人身上' AS title, '四层处境背景（阶段 D 第 37 首·四句绝句 1/1/1/1 第二次）；史实句均有逐字引证；系年第三十一次判决（题证系列第十九状·同字两界）「題有怨名，怨在兩部皆無檔；詩有淚字，淚在通鑑只一袍」——通鉴「怨情」全零+全唐詩快照「怨情」全零（机器断言）；通鉴「淚痕」恰一处=光启二年（丙午，八八六）僖宗解御袍赐王建「以其有淚痕故也」（闭域+年窗口断言）——诗的泪与史的泪同字两界互证其有不相牵合→time.span/event.name/written_during 全缺席、零 relation；底注空锚片段首见（卷184# 后直接|，不完整指向而页自评 100%，audit 硬卡）；底本指向不可核新形态首见（快照缺卷184：如实登记零引用不伪造对勘）；此诗正文第二引上限用满对后来关闭（V018 在先+全库查重）；双 {{另}}（顰/蹙、見/覺）照登双硬卡；异文两支快照零命中在册；新传孙女辞改嫁句首引（全库查重既往零引；V042 前句零重开）；KNOWN 零如实记录（第十二例，audit 反向断言）；零新 source；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-331-city' AS id, 'BACKGROUND' AS entity_type, '331-city' AS slug, '这座城：底注里一个空的锚' AS title, '四层处境背景（阶段 D 第 37 首·四句绝句 1/1/1/1 第二次）；史实句均有逐字引证；系年第三十一次判决（题证系列第十九状·同字两界）「題有怨名，怨在兩部皆無檔；詩有淚字，淚在通鑑只一袍」——通鉴「怨情」全零+全唐詩快照「怨情」全零（机器断言）；通鉴「淚痕」恰一处=光启二年（丙午，八八六）僖宗解御袍赐王建「以其有淚痕故也」（闭域+年窗口断言）——诗的泪与史的泪同字两界互证其有不相牵合→time.span/event.name/written_during 全缺席、零 relation；底注空锚片段首见（卷184# 后直接|，不完整指向而页自评 100%，audit 硬卡）；底本指向不可核新形态首见（快照缺卷184：如实登记零引用不伪造对勘）；此诗正文第二引上限用满对后来关闭（V018 在先+全库查重）；双 {{另}}（顰/蹙、見/覺）照登双硬卡；异文两支快照零命中在册；新传孙女辞改嫁句首引（全库查重既往零引；V042 前句零重开）；KNOWN 零如实记录（第十二例，audit 反向断言）；零新 source；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-331-world' AS id, 'BACKGROUND' AS entity_type, '331-world' AS slug, '这个天下：史部的泪只沾过一件御袍' AS title, '四层处境背景（阶段 D 第 37 首·四句绝句 1/1/1/1 第二次）；史实句均有逐字引证；系年第三十一次判决（题证系列第十九状·同字两界）「題有怨名，怨在兩部皆無檔；詩有淚字，淚在通鑑只一袍」——通鉴「怨情」全零+全唐詩快照「怨情」全零（机器断言）；通鉴「淚痕」恰一处=光启二年（丙午，八八六）僖宗解御袍赐王建「以其有淚痕故也」（闭域+年窗口断言）——诗的泪与史的泪同字两界互证其有不相牵合→time.span/event.name/written_during 全缺席、零 relation；底注空锚片段首见（卷184# 后直接|，不完整指向而页自评 100%，audit 硬卡）；底本指向不可核新形态首见（快照缺卷184：如实登记零引用不伪造对勘）；此诗正文第二引上限用满对后来关闭（V018 在先+全库查重）；双 {{另}}（顰/蹙、見/覺）照登双硬卡；异文两支快照零命中在册；新传孙女辞改嫁句首引（全库查重既往零引；V042 前句零重开）；KNOWN 零如实记录（第十二例，audit 反向断言）；零新 source；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-331-person' AS id, 'BACKGROUND' AS entity_type, '331-person' AS slug, '这个人：诗里的无名女子与传里的孙女' AS title, '四层处境背景（阶段 D 第 37 首·四句绝句 1/1/1/1 第二次）；史实句均有逐字引证；系年第三十一次判决（题证系列第十九状·同字两界）「題有怨名，怨在兩部皆無檔；詩有淚字，淚在通鑑只一袍」——通鉴「怨情」全零+全唐詩快照「怨情」全零（机器断言）；通鉴「淚痕」恰一处=光启二年（丙午，八八六）僖宗解御袍赐王建「以其有淚痕故也」（闭域+年窗口断言）——诗的泪与史的泪同字两界互证其有不相牵合→time.span/event.name/written_during 全缺席、零 relation；底注空锚片段首见（卷184# 后直接|，不完整指向而页自评 100%，audit 硬卡）；底本指向不可核新形态首见（快照缺卷184：如实登记零引用不伪造对勘）；此诗正文第二引上限用满对后来关闭（V018 在先+全库查重）；双 {{另}}（顰/蹙、見/覺）照登双硬卡；异文两支快照零命中在册；新传孙女辞改嫁句首引（全库查重既往零引；V042 前句零重开）；KNOWN 零如实记录（第十二例，audit 反向断言）；零新 source；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-331-scene' AS id, 'bg-331-scene' AS subject_id, 'context' AS property_key, '四句全诗本文（ws 页 {{另}} 恰二、余标记全零、Textquality 100%；顰/蹙、見/覺两支照登不裁决，双标记字样入 SCENE 引文 audit 双硬卡）；全句第二引：正文 V018 text claim 一引在先（生成时全库查重恰一处），两度上限至此用满、此诗正文对后来迁移关闭（audit 硬卡）；「为谁而恨」的任何回答系读法非史实。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-331-city' AS id, 'bg-331-city' AS subject_id, 'context' AS property_key, '底注空锚片段首见：底本指向「[[全唐詩/卷184#|全唐詩·卷184]]」#后直接|（不完整指向而页面自评 100%——指向完备度与录入完备度两回事，V054/V055 正交纪律的延伸，audit 硬卡「卷184#|」照登）；底本指向不可核新形态：全唐詩快照缺卷184（机器断言 vol184 不在册）——如实登记零引用不伪造对勘；分类行照登+非史料声明+不升格；快照「怨情/捲珠簾/心恨」全零（题族无册如实）、异文两支快照零命中（孤本在册）、他人淚痕 8 处不引；题无档而诗无时→零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-331-world' AS id, 'bg-331-world' AS subject_id, 'context' AS property_key, '怨在两部皆无档：通鉴「怨情」全零+全唐詩快照「怨情」全零（机器断言）；泪在史部只一袍：通鉴「淚痕」恰 1 处=tj-256 光启二年（丙午，八八六）僖宗「解御袍賜建曰：『以其有淚痕故也』」（文件闭域+年标题窗口断言）——诗的泪与史的泪同字两界，互证其有不相牵合；诗语蛾眉/珠簾/深坐通鉴全零；certainty 不覆盖任何系年，诗 time.span/event.name/written_during 零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-331-person' AS id, 'bg-331-person' AS subject_id, 'context' AS property_key, '新传孙女辞改嫁句首引（生成时全库引文域查重：辭以孤窮失身既往零命中，audit 硬卡；旧传无此段=新传单得，机器断言）；V042 已引前句「進止仍有風範」零重开（audit 硬卡前句字样不入引文）；两种女子一虚一实并置为读法声明非史实（传中女子非诗中人）；李白其余已用判例句零重开（山東人两度已满在册）；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-331-scene' AS subject_id, 'context' AS property_key, 'claim-bg-331-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-331-city' AS subject_id, 'context' AS property_key, 'claim-bg-331-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-331-world' AS subject_id, 'context' AS property_key, 'claim-bg-331-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-331-person' AS subject_id, 'context' AS property_key, 'claim-bg-331-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-331-scene' AS id, 'work-t300-331' AS work_id, 'SCENE' AS layer, '四句是一间深阁：美人卷起珠帘，深深独坐着蹙起蛾眉（「美人捲珠簾，深坐{{另|顰|蹙}}蛾眉」——顰/蹙两支照登不裁决）；只见泪痕湿了面庞，心里恨的是谁却没有人知道（「但{{另|見|覺}}淚痕濕，不知心恨誰」——見/覺两支照登不裁决）。全诗无年、无地、无姓名、无对象——连恨都恨在不具名的人身上；此诗正文系**第二引**：V018 text claim 已一引在先（全库查重恰一处），两度上限至此用满，此诗正文对后来迁移关闭。恨誰之问是页上原文，「为谁而恨」的任何答案都是读法，不是史实。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-331-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-331-city' AS id, 'work-t300-331' AS work_id, 'CITY' AS layer, '这条城的档案先登记底注本身：「{{Textquality|100%}}↑ [[全唐詩/卷184#|全唐詩·卷184]]」——「#」后直接「|」，**底本指向的空锚片段首见**（不完整指向，页面却自评 100%；audit 硬卡「卷184#|」字样照登不裁决；完备度与完备的指向是两回事，V054/V055 的正交纪律在「指向」这一维的延伸）。**底本指向不可核新形态首见**：全唐詩快照缺卷184（140–199 区间的李白诸卷多缺）——指向在维基文库可点开、在本快照无法逐字对勘：如实登记、零引用、不伪造对勘、不因此铸第二证。分类行「閨怨詩」为整理者动作：照登+非史料声明+不升格（V048 判例）。题族亦无册可登：全唐詩快照「怨情」「捲珠簾」「心恨」全零（机器断言）——异文两支「蹙蛾眉」「覺淚痕」快照内亦零命中：这支诗在存卷里连旁证都没有，在册如实；他人「淚痕」全唐詩 8 处（各是各诗，在册不引不牵合）。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-331-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-331-world' AS id, 'work-t300-331' AS work_id, 'WORLD' AS layer, '诗的题面有「怨」，两部书都查无此怨：通鉴「怨情」75 卷全零、全唐詩快照「怨情」亦全零（机器断言）。
诗里的美人落泪；通鉴「淚痕」75 卷**恰一处**（文件闭域+年标题窗口机器断言）——光启二年（丙午，八八六）广明之乱后僖宗幸凤翔，夜宿板下、枕王建膝而寝，觉来「解御袍賜建曰：『以其有淚痕故也。』」——**史部七十多卷里的泪痕，只沾过一件御袍**（天子的泪）。同一两个字，两个世界：诗的泪无名无人知（「不知心恨誰」），御泪有名无人见（君臣夜宿板下）——互证其有、不相牵合。
诗语「蛾眉」「珠簾」「深坐」通鉴亦全零（机器断言）——深阁的语言进不了史部。**怨在两部皆无档，泪在史部只一袍**；本层零铸造零 relation。' AS body_text, 'SENIOR' AS audience, 'claim-bg-331-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-331-person' AS id, 'work-t300-331' AS work_id, 'PERSON' AS layer, '诗里的女人至终没有名字；新传倒让李白家里两个真实的女人开了口：范傳正改葬青山、访其后裔，只有两个孙女嫁为民妻，官家要把她们改嫁士族，「**辭以孤窮失身，命也，不願更嫁**。」（生成时全库查重：此句既往零入引，本迁移首引；改葬访后裔段前句 V042 已引「進止仍有風範」至而止，本迁移只取其後相邻一句，前句零重开）。
把两处并置看：诗的「不知心恨誰」是不具名女子的无主之恨，传的「不願更嫁」是李白血脉有名有姓的自我主张——**两种女子，一虚一实，一在诗一在传**（读法声明，非史实；传中女子非诗中人，绝不牵合）。李白传其余已用句（山東人家世 V016/V032 两度已满零重开/謫仙人/脱靴/沈香亭/賜金放還/宮錦袍/夜郎/青山）一个不重开；两传李白段「怨情」「淚痕」「蛾眉」「珠簾」全零（机器断言）——传写其人，不提这四字里的任何一个。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-331-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-331-scene' AS claim_id, 'source-ws-t300-331' AS source_id, '页面 怨情 (美人捲珠簾)（header author+两联四句，三段以「……」相連——{{另}}×2（顰/蹙、見/覺）原样入引 audit 双硬卡；全句**第二引**：正文 V018 text claim 一引在先（生成时全库查重恰一处），**两度上限至此用满，此诗正文对后来迁移关闭**；页 {{别}}/{{*}}/<ref> 全零）' AS locator, '| author   = 李白……美人捲珠簾，深坐{{另|顰|蹙}}蛾眉。……但{{另|見|覺}}淚痕濕，不知心恨誰。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-331-city' AS claim_id, 'source-ws-t300-331' AS source_id, '页面 怨情 (美人捲珠簾)（header title+页底注+分类行三段并收——底本指向「全唐詩/卷184#」系**空锚片段首见**（audit 硬卡「卷184#|」字样；快照缺卷184 不可对勘：如实零引用）；「閨怨詩」分类系整理者动作：非史料声明、不升格；题面零消歧、歧解在页名以首句系之）' AS locator, '| title    = [[怨情]]……| notes    = {{Textquality|100%}}↑ [[全唐詩/卷184#|全唐詩·卷184]]……[[Category:閨怨詩]]' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-331-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '卷二百五十六·光启二年（丙午，八八六）僖宗幸凤翔宿板下解袍赐王建段（**通鉴 75 卷「淚痕」唯一一处**：文件闭域+年标题窗口机器断言——史部之泪只沾御袍；怨情/蛾眉/珠簾/深坐通鉴全零在册）' AS locator, '解御袍賜建曰：「以其有淚痕故也。」' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-331-person' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百二·文艺中·李白传范傳正访后裔段孙女辞改嫁句（生成时全库引文域查重：此句既往零入引，本迁移首引；旧传无此段新传单得；前句「進止仍有風範」V042 已引零重开；与诗中无名恨誰女子并置是读法声明——传中女子非诗中人）' AS locator, '告二女，將改妻士族，辭以孤窮失身，命也，不願更嫁。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（四句：1/1/1/1） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-331-scene' AS background_id, 'text-work-t300-331-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-331-city' AS background_id, 'text-work-t300-331-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-331-world' AS background_id, 'text-work-t300-331-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-331-person' AS background_id, 'text-work-t300-331-ws' AS version_id, 4 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 56, 'Li Bai Grief background layers (stage-D poem 37, four-line jueju shape 1/1/1/1 second use after V053, first for Li Bai): dating verdict thirty-one, nineteenth shape of the title-evidence series -- the same words, two worlds: the title''s word "grief" scores zero in the Tongjian and zero across the surviving 118 juan of the Quan Tangshi snapshot (machine-asserted: no dossier for the title, registered honestly), while the poem''s word for tear-trace appears exactly once in 75 Tongjian juan -- Guangqi 2 (886), Emperor Xizong fleeing to Fengxiang, sleeping with his head on Wang Jian''s lap and giving away his robe "because it bears tear-traces" (file-closed, year-heading window asserted): the histories'' single tear-trace stains only an imperial robe; the poem''s tear is nameless and unknown to whom -- same two characters, two worlds, mutually attested yet never conflated; zero forging, zero relation; first appearance of an empty-anchor fragment in a base-pointer (Quan Tangshi juan 184 followed by bare hash then pipe: an incomplete pointer on a page self-rated 100% -- pointer completeness is a third orthogonal dimension, audit hard-assert); first "pointer unverifiable" form: the snapshot lacks juan 184, so the pointer is neither faked into a second witness nor silently dropped -- logged, zero-cited; the poem body hits its two-use ceiling (V018 first, machine-swept) and closes for future migrations; both {{另}} pairs (pin/cu, jian/jue) transcribed verbatim with twin hard-asserts; both variant branches score zero inside the snapshot (register: orphan witnesses); PERSON first-cites the New History''s granddaughters refusing remarriage ("pleading poverty... fate; we decline another marriage", sweep proves zero prior hits; V042''s adjacent sentence stays closed); KNOWN zero honestly recorded (twelfth instance, audit reverse-asserts); zero new sources; closed precedent keywords stay out of citations'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 56);
COMMIT;
