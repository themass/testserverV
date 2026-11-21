-- V052：王維《過香積寺》(work-t300-133) 四层背景（阶段 D 第 33 首·署名异说纯文本首见）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V014、V015、V016、V018、V027、V035、V051 已执行（work-t300-133 与其
--       text-work-t300-133-ws、source-ws-t300-133、source-quantangshi-227 是 V018 的行；
--       source-quantangshi-126 是 V035 的行；source-xintangshu-wenyi 是 V016 的行；
--       source-jiutangshu-wenyuan 是 V016 的行；source-zizhi-tongjian-events 是 V014/V015 已立的通鉴事件源）。
--       **本迁移零新 source**（audit 断言 SQL 无任何诗源表新建插入语句）。
--
-- 数据源（可复现）：emit_v052.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/過香積寺.txt（零标记+Textquality|100% 互证、底注「一作王昌齡詩」）、
--   舊唐書卷190下（尤长五言句首引+王维段负证）、新唐書卷202/203（王维卷负证+附王昌齡对话句首引）、
--   通鑑卷220/233（香积寺战场四段+双年标题窗口）+ 通鑑 75 卷/全唐詩 120 卷负证计数扫描——
--   传区间归属、香積/閭丘曉/诗语全部计数与断词假命中、年标题窗口生成时断言。
--
-- 做：4 BACKGROUND content/claim/background + 8 组逐字引用（(claim,source) 主键每对恰一行）+
--   8 行 background_line（八句形制：scene→1-2 city→3-4 world→5-6 person→7-8，
--   绑 text-work-t300-133-ws 的 8 行）。本迁移不碰 poetry_text_line。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「題有寺名，寺在史部是戰場；詩有兩家，兩家各有一傳」）：
--   * 纯文本署名异说：底注「一作王昌齡詩」逐字入 CITY 引文（audit 照登硬卡），登记不裁决；
--   * 寺有史事、不是那件事：通鉴香積恰四处全归 757 之战（闭域+757/787 窗口断言）；
--   * 同名异地：卷227 涪城香积寺≠长安香积寺，并登记不合并；卷539 断词假命中机器登记不引；
--   * 三通互证不升：意愿侧（新传將戮）与执行侧（通鉴杖殺之）并置不合并，claim 保持 LIKELY；
--   * V016 已用「所殺」句两度上限关闭，本迁移零入引（audit 硬卡「以世亂還鄕里」不在引文）；
--   * 「没有一处史书替这首诗说过署名」为读法声明，audit 双声明在 BG 文本内；
--   * KNOWN 零如实记录（第八例，audit 反向断言 SQL 无 KNOWN 字面量）；
--   * 寻寺行程/入禅收束均为读法声明；不才/凝碧/輞川/蓝田/奉佛段/代宗诏集 判例只引不重开。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 51，不含 52
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-133-%';             -- 空
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-133-ws';  -- 恰 8
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-133-%';       -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-133';                                  -- 8（2/2/2/2）
--   SELECT certainty FROM poetry_claim WHERE id LIKE 'claim-bg-133-%';  -- 四行全 LIKELY（有意全 LIKELY）
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-133'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-133';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-133-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
--   SELECT COUNT(*) FROM poetry_source WHERE id LIKE 'source-quantangshi-1%';  -- 与执行前相同（零新源）
-- 回滚: recovery/V052_rollback.sql（按 id 全枚举删除；不动任何共用来源行、不动 V018 的行）
START TRANSACTION;

-- ---------- 1. BACKGROUND content identities（零新 source——本迁移断言在生成器 audit） ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-133-scene' AS id, 'BACKGROUND' AS entity_type, '133-scene' AS slug, '眼前：一次没找到的寻寺' AS title, '四层处境背景（阶段 D 第 33 首·八句律詩 2/2/2/2）；史实句均有逐字引证；系年第二十七次判决「題有寺名，寺在史部是戰場；詩有兩家，兩家各有一傳」（题证系列第十五状·署名异说首见纯文本形态——题面「過/不知」连到过都不担保，底注「一作王昌齡詩」裸写无标记，照登不裁决；通鉴香積恰四处全归 757 香积寺之战（文件闭域+757/787 双年标题窗口断言），寺有史事不是那件事）→time.span/event.name/written_during 全缺席、零 relation；同名异地：涪城香积寺与长安香积寺并登记不合并（V051 异衔纪律跨类延伸）；卷539「雞香積」断词假命中机器登记不引；署名两侧各一句首引（尤長五言/欲與誰養——V016 已用句零入引）；三通互证不升（意愿侧与执行侧并置不合并，诚实边界第八式）；KNOWN 零如实记录（audit 反向断言）；零标记与 Textquality|100% 互证（第二张）；零新 source（六共用源行均已立）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-133-city' AS id, 'BACKGROUND' AS entity_type, '133-city' AS slug, '这座城：底注里的公案与两处同名寺' AS title, '四层处境背景（阶段 D 第 33 首·八句律詩 2/2/2/2）；史实句均有逐字引证；系年第二十七次判决「題有寺名，寺在史部是戰場；詩有兩家，兩家各有一傳」（题证系列第十五状·署名异说首见纯文本形态——题面「過/不知」连到过都不担保，底注「一作王昌齡詩」裸写无标记，照登不裁决；通鉴香積恰四处全归 757 香积寺之战（文件闭域+757/787 双年标题窗口断言），寺有史事不是那件事）→time.span/event.name/written_during 全缺席、零 relation；同名异地：涪城香积寺与长安香积寺并登记不合并（V051 异衔纪律跨类延伸）；卷539「雞香積」断词假命中机器登记不引；署名两侧各一句首引（尤長五言/欲與誰養——V016 已用句零入引）；三通互证不升（意愿侧与执行侧并置不合并，诚实边界第八式）；KNOWN 零如实记录（audit 反向断言）；零标记与 Textquality|100% 互证（第二张）；零新 source（六共用源行均已立）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-133-world' AS id, 'BACKGROUND' AS entity_type, '133-world' AS slug, '这个天下：史部的香积寺是一场胜仗' AS title, '四层处境背景（阶段 D 第 33 首·八句律詩 2/2/2/2）；史实句均有逐字引证；系年第二十七次判决「題有寺名，寺在史部是戰場；詩有兩家，兩家各有一傳」（题证系列第十五状·署名异说首见纯文本形态——题面「過/不知」连到过都不担保，底注「一作王昌齡詩」裸写无标记，照登不裁决；通鉴香積恰四处全归 757 香积寺之战（文件闭域+757/787 双年标题窗口断言），寺有史事不是那件事）→time.span/event.name/written_during 全缺席、零 relation；同名异地：涪城香积寺与长安香积寺并登记不合并（V051 异衔纪律跨类延伸）；卷539「雞香積」断词假命中机器登记不引；署名两侧各一句首引（尤長五言/欲與誰養——V016 已用句零入引）；三通互证不升（意愿侧与执行侧并置不合并，诚实边界第八式）；KNOWN 零如实记录（audit 反向断言）；零标记与 Textquality|100% 互证（第二张）；零新 source（六共用源行均已立）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-133-person' AS id, 'BACKGROUND' AS entity_type, '133-person' AS slug, '这个人：尤长五言与被谁养亲' AS title, '四层处境背景（阶段 D 第 33 首·八句律詩 2/2/2/2）；史实句均有逐字引证；系年第二十七次判决「題有寺名，寺在史部是戰場；詩有兩家，兩家各有一傳」（题证系列第十五状·署名异说首见纯文本形态——题面「過/不知」连到过都不担保，底注「一作王昌齡詩」裸写无标记，照登不裁决；通鉴香積恰四处全归 757 香积寺之战（文件闭域+757/787 双年标题窗口断言），寺有史事不是那件事）→time.span/event.name/written_during 全缺席、零 relation；同名异地：涪城香积寺与长安香积寺并登记不合并（V051 异衔纪律跨类延伸）；卷539「雞香積」断词假命中机器登记不引；署名两侧各一句首引（尤長五言/欲與誰養——V016 已用句零入引）；三通互证不升（意愿侧与执行侧并置不合并，诚实边界第八式）；KNOWN 零如实记录（audit 反向断言）；零标记与 Textquality|100% 互证（第二张）；零新 source（六共用源行均已立）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-133-scene' AS id, 'bg-133-scene' AS subject_id, 'context' AS property_key, '八句全诗本文（ws 页四标记体系全零+Textquality|100% 互证，V048 判例；同一 (claim,source) 主键一行容全文判例；正文另见 V018 claim-t300-133-text——本诗正文两度上限至此用满，后来者不得三引）；「没找到」的行程与入禅收束为本层读法声明，非史料断言。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-133-city' AS id, 'bg-133-city' AS subject_id, 'context' AS property_key, '纯文本署名异说首见：底注整行含「一作王昌齡詩」逐字入引（audit 照登硬卡；V049 <ref> 形态之后的第二形态），登记不裁决、正文仍从 ws 页；寺名两锚点结构断言（卷126 本篇+卷227 涪城县香积寺官阁各×2）——同名异地不合并（V051 异衔不牵合跨类延伸）；卷539 断词假命中机器登记不引；底注+分类行照登+非史料声明+不升格（V048 分类行判例）；零标记与 Textquality|100% 互证（第二张 100% 页）；题有寺名而寺不系年→零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-133-world' AS id, 'bg-133-world' AS subject_id, 'context' AS property_key, '香积寺在史部只有战场：通鉴「香積」恰四处=tj-220 至德二年布阵一+tj-233 贞元三年余话三（文件闭域+两处摘句双年标题窗口断言）；「王維」「王昌齡」「雲峰」「危石」「毒龍」「安禪」通鉴全零（机器扫描）；两传王维段/附王昌齡段「香積」全零（机器断言）——寺有史事、不是那件事（V050 山无史山族镜像）；certainty 不覆盖任何系年，诗 time.span/event.name/written_during 零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-133-person' AS id, 'bg-133-person' AS subject_id, 'context' AS property_key, '署名异说两侧各单得：旧传「尤長五言詩」句史部唯一（首引，段内位置断言）；新传附录「欲與誰養」对话句首引（段内位置断言；V016 已用「所殺」句零入本迁移引文——两度上限纪律，audit 硬卡）；三通互证不升：新传言意愿（將戮）、通鉴言执行（杖殺之，757 窗口）、旧传无此（JTS 全卷零）——并置不合并，claim 保持 LIKELY（诚实边界第八式）；「没有一处史书替这首诗说过署名」声明为读法非史实；判例零重开。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-133-scene' AS subject_id, 'context' AS property_key, 'claim-bg-133-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-133-city' AS subject_id, 'context' AS property_key, 'claim-bg-133-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-133-world' AS subject_id, 'context' AS property_key, 'claim-bg-133-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-133-person' AS subject_id, 'context' AS property_key, 'claim-bg-133-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-133-scene' AS id, 'work-t300-133' AS work_id, 'SCENE' AS layer, '八句是一次「没找到」的完整行程：不知道香积寺在哪，数里路走进了云遮的山峰（「不知香積寺，數里入雲峰」——题面先自陈未到）；古树夹着无人走的小径，深山在哪处响着钟声（「古木無人徑，深山何處鐘？」——寺还没到，声先来）；泉声在险石间咽住，日光在青松上变冷（「泉聲咽危石，日色冷青松」——通鉴 75 卷里「危石」「青松」这样的诗语一个字都没有）；薄暮里空潭弯弯，以安禅降伏毒龙（「薄暮空潭曲，安禪制毒龍」——十四个字走完找寺到入禅）。读法是读法，史实只有页上八句。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-133-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-133-city' AS id, 'work-t300-133' AS work_id, 'CITY' AS layer, '这座城的档案先登记一桩公案：页底注整行「↑ [[全唐詩/卷126#過香積寺|全唐詩·卷126]] 一作王昌齡詩」——「一作某某詩」五个字**裸写在 notes 字段里**，没有 <ref>、没有 {{另}}（V049 <ref> 署名异说之后的纯文本第二形态），照登不裁决；底本指向与「五言律詩」分类为整理者动作（非史料声明，V048 判例）。寺名在诗世界有两处锚点：卷126（王维卷）本篇、卷227《涪城縣香積寺官閣》——**同名异地**：涪城（蜀地）的香积寺不是长安香积寺，两处并登记、不合并（同姓不同人纪律的跨类延伸——V051 异衔不牵合）。另登记不引：卷539「雞香積露文」是断词假命中（「雞香」词组撞出「香積」二字，机器断言前字必「雞」在册）。页 {{另}}/{{别}}/{{*}}/<ref> 全零而 Textquality|100%——零标记与 100% 互证（V048 首张 100% 页判例，本迁移为第二张）。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-133-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-133-world' AS id, 'work-t300-133' AS work_id, 'WORLD' AS layer, '史部有这座寺，四处——**全是打仗**：通鉴至德二年（丁酉，757）「庚子，諸軍俱發；壬寅，至長安城西，陳於香積寺北澧水之東」——收复长安的香积寺之战，年标题窗口断言（757）。
三十年后贞元三年（丁卯，787）三处余话全是这场仗：李泌对德宗「且香積之捷，葉護欲引兵入長安，先帝親拜之於馬前以止之」，德宗「今聞泌言香積之事，朕自覺少理」（两处摘句均年标题 787 窗口断言）。机器断言：通鉴「香積」恰四处=tj-220 一+tj-233 三；「王維」「王昌齡」通鉴全零；「雲峰」「危石」「毒龍」「安禪」诗语通鉴全零。
**史部的香积寺是一场胜仗，诗里的香积寺是一座没找到的禅寺**——同名同字、一事一寺（V050「山无史山」的镜像：寺有史事、但不是那件事）。本层不铸时间，零铸造零 relation。' AS body_text, 'SENIOR' AS audience, 'claim-bg-133-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-133-person' AS id, 'work-t300-133' AS work_id, 'PERSON' AS layer, '署名之争的两侧各有一句从未入引的活句（生成时全库引文域查重）：王維侧，旧传「**維尤長五言詩**。」——史部唯一一句给他「最擅长」的判语，本诗恰是一首五律（旧传单得，首引）。
王昌齡侧，新传附录张镐–闾丘晓对话：晓误期将戮，辞以有亲，镐曰「**王昌齡之親，欲與誰養？**」晓默然——杀他的人求饶说家有老亲，张镐反问：王昌龄的爹娘谁养？（V016 已立「爲刺史閭丘曉所殺」句——那句不再引，两度上限留给后来者）。三通互证不升：晓事三源——新传附录（将戮）、通鉴 tj-220（「曉素傲很，不受鎬命……鎬召曉，杖殺之」，757 窗口断言）、旧传无此（JTS 全卷閭丘晓零，机器断言）——新史言意愿、通鉴言执行，**并置不合并**，claim 保持 LIKELY。
「争夺这首诗署名的两个人，一个在史部得了『尤长五言』、一个得了『被谁养亲』——没有一处史书替这首诗说过一个字的署名」：此句是读法声明，不是史实。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-133-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-133-scene' AS claim_id, 'source-ws-t300-133' AS source_id, '页面 過香積寺（header author+四联八句，五段以「……」相連——页 {{另}}/{{别}}/{{*}}/<ref> 全零+Textquality|100% 互证（V048 判例第二张）；同一 (claim,source) 主键一行容全文判例；正文另见 V018 claim-t300-133-text——本诗正文两度上限至此用满，后来者不得三引）' AS locator, '| author   = 王維……不知香積寺，數里入雲峰。……古木無人徑，深山何處鐘？……泉聲咽危石，日色冷青松。……薄暮空潭曲，安禪制毒龍。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-133-city' AS claim_id, 'source-ws-t300-133' AS source_id, '页面 過香積寺（header notes 整行+分类行两段并收——底注含「**一作王昌齡詩**」系纯文本署名异说首见（无 <ref>/{{另}}，V049 之后第二形态），照登不裁决（V044 反向极性同族）；底本指向与「五言律詩」分类均为整理者动作：非史料声明、不升格）' AS locator, '| notes    = {{Textquality|100%}}↑ [[全唐詩/卷126#過香積寺|全唐詩·卷126]] 一作王昌齡詩……[[Category:五言律詩]]' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-133-city' AS claim_id, 'source-quantangshi-126' AS source_id, '卷一百二十六·王维诗卷本篇篇题锚点+转引桩（香积寺诗世界档案之一；锚点×2 结构为生成时机器断言；署名异说的集部侧——异说照登不裁决）' AS locator, '==[[過香積寺]]==……{{:過香積寺}}' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-133-city' AS claim_id, 'source-quantangshi-227' AS source_id, '卷二百二十七·杜甫诗卷《涪城縣香積寺官閣》篇题锚点+转引桩（同名异地：蜀地涪城的香积寺不是长安香积寺——两处并登记不合并，V051 异衔不牵合跨类延伸；卷539「雞香積」断词假命中机器登记不引）' AS locator, '==[[涪城縣香積寺官閣]]==……{{:涪城縣香積寺官閣}}' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-133-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '卷二百二十·至德二年香积寺布阵段+闾丘晓杖杀段……卷二百三十三·贞元三年香积之捷两处余话（四段以「……」相連——通鉴「香積」恰四处全归此役：文件闭域+双年标题窗口机器断言；「王維/王昌齡/雲峰/危石/毒龍/安禪」通鉴全零为负证扫描；史部香积寺=战场，诗里香积寺=未至之寺）' AS locator, '庚子，諸軍俱發；壬寅，至長安城西，陳於香積寺北澧水之東。……曉素傲很，不受鎬命。比鎬至，睢陽城已陷三日。鎬召曉，杖殺之。……且香積之捷，葉護欲引兵入長安，先帝親拜之於馬前以止之，葉護遂不敢入城。……今聞泌言香積之事，朕自覺少理。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-133-person' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十下·文苑下·王维传尤长五言句（史部唯一「最擅长」判语——本迁移首引（V016/V035/V043/V044 均未用此句，生成时全库引文域查重）；与署名异说并读为读法）' AS locator, '維尤長五言詩。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-133-person' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百零三·文藝下·附王昌齡张镐–闾丘晓对话段（「王昌齡之親，欲與誰養」——署名异说另一侧的人；V016 已用「以世亂還鄕里，爲刺史閭丘曉所殺」句，该句对后来迁移关闭、本迁移零入引——两度上限；此对话句首引）' AS locator, '張鎬按軍河南，兵大集，曉最-{後}-期，將戮之，辭曰：「有親，乞貸-{餘}-命。」鎬曰：「王昌齡之親，欲與誰養？」曉默然。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-133-person' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '卷二百二十·至德二年闾丘晓杖杀段（三通互证执行侧：新传附录言意愿、通鉴言「杖殺之」、旧传全卷无闾丘晓——并置不合并，不升 KNOWN；与 WORLD 层引文同段——同 (claim,source) 主键本迁移仅此一行）' AS locator, '曉素傲很，不受鎬命。比鎬至，睢陽城已陷三日。鎬召曉，杖殺之。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（八句：2/2/2/2） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-133-scene' AS background_id, 'text-work-t300-133-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-133-scene' AS background_id, 'text-work-t300-133-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-133-city' AS background_id, 'text-work-t300-133-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-133-city' AS background_id, 'text-work-t300-133-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-133-world' AS background_id, 'text-work-t300-133-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-133-world' AS background_id, 'text-work-t300-133-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-133-person' AS background_id, 'text-work-t300-133-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-133-person' AS background_id, 'text-work-t300-133-ws' AS version_id, 8 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 52, 'Wang Wei Visiting Xiangji Temple background layers (stage-D poem 33, eight-line regulated verse, the authorship dispute first appears as bare prose): dating verdict twenty-seven, fifteenth shape of the title-evidence series -- the title keeps a temple-name while history keeps only a battle at that name: the Tongjian''s four occurrences of Xiangji are machine-proven to sit wholly in juan 220 (the 757 battle array north of the temple by the Li River, locked behind a Zhide-2 year heading) and juan 233 (three echoes of "the victory at Xiangji" in Li Bi''s dialogue with the emperor, locked behind a Zhenyuan-3 heading) -- history''s Xiangji Temple is a victory, the poem''s is a temple never found; the signature dispute sits bare in the notes field (no ref tag, no variant marker): "also attributed to Wang Changling" transcribed verbatim into the CITY citation (audit hard-assert) and registered without adjudication; the two rival names each contribute one sentence never before cited -- the Old History''s sole verdict "he excelled above all in five-character verse" and the New History appendix''s retort "who then will feed Wang Changling''s parents?" (the sentence V016 already used stays closed to this migration, two-use ceiling asserted absent); three sources on the murder of Lu Qiu-xiao by Zhang Hao placed side by side without merging -- intent on one side, execution on the other, so the claim stays LIKELY (no KNOWN, audit reverse-asserts); same-name-different-place: the Fucheng Xiangji temple in the Du Fu volume registered alongside, never merged; a false word-boundary hit in juan 539 machine-logged and never quoted; zero new sources (six shared source rows pre-exist, audit asserts no source-row insert statement at all); closed precedent keywords stay out of citations'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 52);
COMMIT;
