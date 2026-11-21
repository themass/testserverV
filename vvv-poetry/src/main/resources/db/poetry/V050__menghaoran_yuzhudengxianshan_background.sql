-- V050：孟浩然《與諸子登峴山》(work-t300-117) 四层背景（阶段 D 第 31 首·八句律詩）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V014、V015、V016、V018、V031、V048 已执行（work-t300-117 与其 text-work-t300-117-ws、
--       source-ws-t300-117 是 V018 的行；source-xintangshu-wenyi 是 V016 的行；
--       source-quantangshi-160 是 V031 的行；source-zizhi-tongjian-events 是 V014/V015 已立的通鉴事件源——
--       均不另开）。本迁移零新 source（断言）。
--
-- 数据源（可复现）：emit_v050.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/與諸子登峴山.txt（{{另}} 恰一处反向断言+异文照登）、
--   舊唐書卷190下 / 新唐書卷203（孟段负证+刻碑子段）、全唐詩卷160（8 枚峴山篇题锚点）、
--   通鑑卷208（杜預摘句）+ 通鑑 75 卷/全唐詩 120 卷负证计数扫描——
--   传区间归属、景龍元年标题窗口（年份用「零」字，则字符类已扩）、
--   羊祜/墮淚/峴山/杜預/碑/{{另}} 全部计数与结构生成时断言。
--
-- 做：0 个新 source（断言）+ 4 BACKGROUND content/claim/background +
--   5 组逐字引用（(claim,source) 主键每对恰一行）+
--   8 行 background_line（八句形制 2/2/2/2，绑 text-work-t300-117-ws 的 8 行）。
--   本迁移不碰 poetry_text_line。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「題有山有碑，山無史山、碑無史碑」）：
--   * 峴山：通鉴全零、全唐詩 21 处中卷160 恰 16 处（8 枚本集篇题×2，机器结构断言）——
--     地名只活在诗世界；
--   * 羊公碑典：羊祜/墮淚通鉴全零；唯一杜預=707 卢辅疏军功样本（年标题窗口断言）——
--     V046 典无史源加重版；
--   * 读碑者亦有碑：刻碑凤林山南句新传单得、V048 一引本迁移二引=上限用满关闭；
--   * KNOWN 零如实记录（audit 反向断言 SQL 无 KNOWN 字面量）；
--   * 我辈即诸子/一浅一深/中间是同一种眼泪均为读法声明，audit 双声明在 BG 文本内；
--   * 不才/放還/韓朝宗/遑恤他/鹿門/孟亭/畫浩然像/年四十/應進士不第/署為從事/
--     不逹而卒/以詩自適/病疽背卒 判例只引不重开。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 49，不含 50
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-117-%';             -- 空
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-117-ws';  -- 恰 8
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-117-%';       -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-117';                                  -- 8（2/2/2/2）
--   SELECT certainty FROM poetry_claim WHERE id LIKE 'claim-bg-117-%';  -- 四行全 LIKELY（有意全 LIKELY）
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-117'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-117';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-117-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
-- 回滚: recovery/V050_rollback.sql（按 id 全枚举删除；不动 V014/V015/V016/V018/V031/V048 的行，不动共用来源行）
START TRANSACTION;

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-117-scene' AS id, 'BACKGROUND' AS entity_type, '117-scene' AS slug, '眼前：冬日结伴的一次登山' AS title, '四层处境背景（阶段 D 第 31 首·八句律詩 2/2/2/2）；史实句均有逐字引证；background_line 八句形制：每层 2 行；系年第二十五次判决「題有山有碑，山無史山、碑無史碑」（题证系列第十三状·断链在典的加重版·地名只活在诗世界——峴山通鉴全零而孟集八见，堕泪碑典通鉴全零而唯一杜預是军功样本）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 零如实记录（杜預句单得、刻碑句单得——都不升）；负证机器复查三层（通鉴羊祜/墮淚/峴山全零+杜預恰一处落景龍元年窗口/全唐詩峴山 21+卷160 恰 16=8 锚点×2 结构+碑字两传孟区间恰一处/ws {{另}} 恰一处必在羊公碑行）；同句第二引上限用满声明首见（刻碑凤林山南句对后来迁移关闭）；异文照登反向极性（尚/字原样入引）；底注三重断言照常；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-117-city' AS id, 'BACKGROUND' AS entity_type, '117-city' AS slug, '这座城：去了八次的山' AS title, '四层处境背景（阶段 D 第 31 首·八句律詩 2/2/2/2）；史实句均有逐字引证；background_line 八句形制：每层 2 行；系年第二十五次判决「題有山有碑，山無史山、碑無史碑」（题证系列第十三状·断链在典的加重版·地名只活在诗世界——峴山通鉴全零而孟集八见，堕泪碑典通鉴全零而唯一杜預是军功样本）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 零如实记录（杜預句单得、刻碑句单得——都不升）；负证机器复查三层（通鉴羊祜/墮淚/峴山全零+杜預恰一处落景龍元年窗口/全唐詩峴山 21+卷160 恰 16=8 锚点×2 结构+碑字两传孟区间恰一处/ws {{另}} 恰一处必在羊公碑行）；同句第二引上限用满声明首见（刻碑凤林山南句对后来迁移关闭）；异文照登反向极性（尚/字原样入引）；底注三重断言照常；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-117-world' AS id, 'BACKGROUND' AS entity_type, '117-world' AS slug, '这个天下：史部里没有的碑' AS title, '四层处境背景（阶段 D 第 31 首·八句律詩 2/2/2/2）；史实句均有逐字引证；background_line 八句形制：每层 2 行；系年第二十五次判决「題有山有碑，山無史山、碑無史碑」（题证系列第十三状·断链在典的加重版·地名只活在诗世界——峴山通鉴全零而孟集八见，堕泪碑典通鉴全零而唯一杜預是军功样本）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 零如实记录（杜預句单得、刻碑句单得——都不升）；负证机器复查三层（通鉴羊祜/墮淚/峴山全零+杜預恰一处落景龍元年窗口/全唐詩峴山 21+卷160 恰 16=8 锚点×2 结构+碑字两传孟区间恰一处/ws {{另}} 恰一处必在羊公碑行）；同句第二引上限用满声明首见（刻碑凤林山南句对后来迁移关闭）；异文照登反向极性（尚/字原样入引）；底注三重断言照常；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-117-person' AS id, 'BACKGROUND' AS entity_type, '117-person' AS slug, '这个人：读碑者亦有碑' AS title, '四层处境背景（阶段 D 第 31 首·八句律詩 2/2/2/2）；史实句均有逐字引证；background_line 八句形制：每层 2 行；系年第二十五次判决「題有山有碑，山無史山、碑無史碑」（题证系列第十三状·断链在典的加重版·地名只活在诗世界——峴山通鉴全零而孟集八见，堕泪碑典通鉴全零而唯一杜預是军功样本）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 零如实记录（杜預句单得、刻碑句单得——都不升）；负证机器复查三层（通鉴羊祜/墮淚/峴山全零+杜預恰一处落景龍元年窗口/全唐詩峴山 21+卷160 恰 16=8 锚点×2 结构+碑字两传孟区间恰一处/ws {{另}} 恰一处必在羊公碑行）；同句第二引上限用满声明首见（刻碑凤林山南句对后来迁移关闭）；异文照登反向极性（尚/字原样入引）；底注三重断言照常；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-117-scene' AS id, 'bg-117-scene' AS subject_id, 'context' AS property_key, '八句全诗本文（ws 页 {{另}} 恰一处且在羊公碑行——异文照登断言反向极性：页有标记且已登记则标记必逐字入引，V044 判例；Textquality 75% 如实记）；「我辈即诸子」「一浅一深」为本层读法声明，非史料断言。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-117-city' AS id, 'bg-117-city' AS subject_id, 'context' AS property_key, '山无史山：峴山通鉴计数全零、全唐詩恰 21 处而卷160 恰 16 处（8 枚本集篇题锚点×2 结构机器断言，全部逐字入引）——地名只活在诗世界；页底注照登+非史料声明+不升格（底注三重断言判例）；题有山而山无史档→零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-117-world' AS id, 'bg-117-world' AS subject_id, 'context' AS property_key, '碑无史碑：羊祜/墮淚通鉴计数全零（V046 典无史源加重版）；通鉴唯一杜預恰一处（tj-208，卢辅疏军功样本，年标题位置断言景龍元年七零七年——则字符类含「零」）→单得不升；「人事代謝」为诗的历史哲学非史料；certainty 不覆盖任何系年，诗 time.span/event.name/written_during 零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-117-person' AS id, 'bg-117-person' AS subject_id, 'context' AS property_key, '新传刻碑凤林山南子段单得（旧传孟段无身后事，合龙无望）→不升；同句 V048 全段一引+本迁移二引=两度上限用满，此句对后来迁移关闭（locator 声明）；「读碑者亦有碑」并置为读法声明；判例零重开（不才/放還/韓朝宗/遑恤他/鹿門/孟亭/畫浩然像/病疽背卒/開元天寶——audit 关键语硬卡）；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-117-scene' AS subject_id, 'context' AS property_key, 'claim-bg-117-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-117-city' AS subject_id, 'context' AS property_key, 'claim-bg-117-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-117-world' AS subject_id, 'context' AS property_key, 'claim-bg-117-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-117-person' AS subject_id, 'context' AS property_key, 'claim-bg-117-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-117-scene' AS id, 'work-t300-117' AS work_id, 'SCENE' AS layer, '八句是一次冬日结伴登山的完整记录：人事自有代谢，来来往往就组成了古今（「人事有代謝，往來成古今」——登山先登山的时间深度）；江山留下了胜迹，我们这辈人又来登临（「江山留勝跡，我輩復登臨」——「我輩」就是题上的诸子）；水位落了，鱼梁洲露得浅，天冷了，梦泽显得深（「水落魚梁淺，天寒夢澤深」——一浅一深是冬日眼前的实景）；羊公碑还在，读完眼泪打湿了衣襟（「羊公碑{{另|尚|字}}在，讀罷淚沾襟」——此句页内挂 {{另}} 异文：「尚」在／一作「字」在，照登不裁决——「还在」与「字样还在」是两种读法，留给读者）。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-117-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-117-city' AS id, 'work-t300-117' AS work_id, 'CITY' AS layer, '这座「城」是峴山，襄阳城南——但它在史部没有档案：通鉴 75 卷「峴山」计数全零（生成时机器断言）；全唐詩 120 卷共 21 处，其中卷160（孟浩然集）恰 16 处——全部是本集篇题：九日登峴山、峴山餞房琯崔宗之、傷峴山雲表觀主、與諸子登峴山、峴山送蕭員外之荆州、峴山送張去非遊巴東、盧明府九日峴山宴袁使君張郎中崔員外、登峴山亭寄晉陵張少府（8 枚篇题锚点×2 结构逐字入引，机器 8×2 断言）——**峴山在史部零档案，在孟浩然的诗世界里是一个去了八次的地方**。
页底注（全唐詩·卷160 底本指向）是整理者动作：照登+非史料声明+不升格（V040/V046/V048 底注三重断言判例）。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-117-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-117-world' AS id, 'work-t300-117' AS work_id, 'WORLD' AS layer, '诗的收句押在整个典故上：羊公碑=羊祜，堕泪碑。但快照史部里这个故事一行都没有：「羊祜」「墮淚」「峴山」通鉴计数全零（机器断言）——V046 牛渚典无史源的加重版。全通鉴「杜預」倒是有过恰一处：707 年（景龍元年，年标题位置断言——此文件年份写「七零七年」，则字符类已含「零」）右补阙卢辅上疏，举「杜預射不穿禮，建平吳之勳」作**军功样本**——通鉴里唯一的杜预不是碑主，是打仗的杜预。
堕泪碑的羊祜、读碑的孟浩然，都活在诗世界与选本世界里；史部的 707 年只关心突厥与平策。「人事有代謝」是诗的历史哲学，不是史料断言。本层到此为止，不给诗铸时间。' AS body_text, 'SENIOR' AS audience, 'claim-bg-117-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-117-person' AS id, 'work-t300-117' AS work_id, 'PERSON' AS layer, '传里唯一带「碑」字的一句在身后：新传记樊泽为节度使时，「澤乃更爲刻碑鳳林山南，封寵其墓」——**读碑者亦有碑**（此句 V048 已随全段一引，此处第二引、上限至此用满，locator 声明此句对后来迁移关闭；「碑」在两传孟区间恰此一处，机器位置断言）。
读羊公碑而泪沾襟的人，身后由节度使刻碑凤林山南——羊祜的碑与孟浩然的碑之间隔着诗，**中间是同一种眼泪**——这是读法声明，不是史实；史实只有新传一句（单得，旧传孟段无身后事，不合龙不升）。判例零重开（audit 硬卡）：不才明主弃、放还、韩朝宗遑恤他、鹿门、孟亭、画浩然像、病疽背卒，本层一个不引。' AS body_text, 'SENIOR' AS audience, 'claim-bg-117-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-117-scene' AS claim_id, 'source-ws-t300-117' AS source_id, '页面 與諸子登峴山（header title+author+四联八句，六段以「……」相連——「羊公碑{{另|尚|字}}在」标记原样入引（tang300-variants.md 新行已登记，尚/字不裁决）；同一 (claim,source) 主键下一行容全文判例；正文另见 V018 claim-t300-117-text——本诗正文两度上限至此用满，后来者不得三引）' AS locator, '| title    = 與諸子登峴山……| author   = 孟浩然……人事有代謝，往來成古今。……江山留勝跡，我輩復登臨。……水落魚梁淺，天寒夢澤深。……羊公碑{{另|尚|字}}在，讀罷淚沾襟。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-117-city' AS claim_id, 'source-quantangshi-160' AS source_id, '卷一百六十·孟浩然集峴山篇题锚点八枚（各取篇题行；本卷「峴山」恰 16 处=8 枚×篇题行+转引桩——山只活在诗人自己的集子里；卷首作者注 V031 已立引，此处不重引；通鉴「峴山」计数全零为生成时机器断言，诗身不代拟进引文）' AS locator, '==[[和賈主簿弁九日登峴山]]==……==[[峴山餞房琯崔宗之]]==……==[[傷峴山雲表觀主]]==……==[[與諸子登峴山]]==……==[[峴山送蕭員外之荆州]]==……==[[峴山送張去非遊巴東]]==……==[[盧明府九日峴山宴袁使君張郎中崔員外]]==……==[[登峴山亭寄晉陵張少府]]==' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-117-city' AS claim_id, 'source-ws-t300-117' AS source_id, '页面 與諸子登峴山（页底注照登——底本指向为整理者动作，非史料声明、不升格（底注三重断言判例））' AS locator, '↑ [[全唐詩/卷160#與諸子登峴山|全唐詩·卷160]]' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-117-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '卷二百零八·景龍元年（七零七年）条内卢辅上疏摘句（通鉴全库唯一「杜預」恰此一处——军功样本非碑主；年标题位置断言生成时复查；羊祜/墮淚/峴山通鉴计数全零为机器断言；单得不升）' AS locator, '杜預射不穿禮，建平吳之勳。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-117-person' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百零三·文藝下·孟浩然传刻碑凤林山南子段（读碑者身后亦有碑——新传单得不升；**同句第二引**：V048 曾随樊泽全段一引，两度上限至此用满，此句对后来迁移关闭；与羊公碑的并置是读法声明）' AS locator, '澤乃更爲刻碑鳳林山南，封寵其墓。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（八句：2/2/2/2） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-117-scene' AS background_id, 'text-work-t300-117-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-117-scene' AS background_id, 'text-work-t300-117-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-117-city' AS background_id, 'text-work-t300-117-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-117-city' AS background_id, 'text-work-t300-117-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-117-world' AS background_id, 'text-work-t300-117-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-117-world' AS background_id, 'text-work-t300-117-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-117-person' AS background_id, 'text-work-t300-117-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-117-person' AS background_id, 'text-work-t300-117-ws' AS version_id, 8 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 50, 'Meng Haoran Climbing the Xian Mountain with Friends background layers (stage-D poem 31, eight-line regulated verse 2/2/2/2): dating verdict twenty-five, thirteenth shape of the title-evidence series -- the title carries a mountain and a stele and history keeps neither: Xian Mountain has zero occurrences across all seventy-five juan of the Tongjian while among the twenty-one Quantangshi hits exactly sixteen sit in juan 160 -- eight title-anchors of Meng''s own collection counted twice each by structure (title line plus transclusion stub), machine-asserted -- the mountain exists only inside the poet''s own poetry world; the weeping-stele allusion likewise has no historical line (Yang Hu and weeping-tears zero in the Tongjian; the single surviving Du Yu passage, position-locked under the Jinglong-1 year-heading whose year is spelled with the zero glyph, is Lu Fu memorializing on military merit -- a war sample, not the stealeader), a heavier cousin of the no-source allusion verdict; the man who reads the stele weeping receives a stele himself after death: the new-history sentence on cutting the stone at Fenglin belongs to the second and final verbatim use after V048 quoted it whole -- ceiling reached, the sentence closes to all future migrations, declared in the locator; the single occurrence of the stone-stele character inside the Meng spans is position-proven to be exactly that sentence; KNOWN zero honestly recorded (audit reverse-asserts); one variant marker on the page (still/letter) transcribed verbatim per the registered-before-citing rule and left unruled; the editors'' edition note declared non-source; readings of companionship and of one shared tear declared as readings; fourteen closed precedent keywords stay out of citations; zero new sources'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 50);
COMMIT;
