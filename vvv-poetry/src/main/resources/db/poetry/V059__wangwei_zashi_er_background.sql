-- V059：王維《雜詩三首·其二》(work-t300-146) 四层背景（阶段 D 第 40 首·杂目与寒梅）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V014、V015、V016、V018、V026、V040、V057 已执行（work-t300-146 与其
--       text-work-t300-146-ws、source-ws-t300-146 是 V018 的行；source-quantangshi-128 是
--       V026/V040 已立的卷128 源行（本迁移复用，零新源）；source-jiutangshu-wenyuan 是 V016 的行；
--       source-zizhi-tongjian-events 是 V014/V015 已立的通鉴事件源）。
--       本迁移零新 source（audit 断言无诗源表新建插入语句）。
--
-- 数据源（可复现）：emit_v059.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/雜詩__君自故鄉來_.txt（四标记全零×100%+section=二 切选结构+further 消歧首见）、
--   舊唐書卷190下（行迹三句首引+全卷无故鄉断言）、新唐書卷202（王维段乡綺梅全零负证）、
--   全唐詩卷128（一锚三桩）、通鑑卷212（故鄉恰一+年标题窗口）+ 通鑑 75 卷/全唐詩 118 卷
--   存快照负证计数扫描（雜詩/故鄉/梅/寒梅/梅花/綺/綺窗）+ 快照雜詩页恰三断言 +
--   既有迁移引文域逐句查重——传区间归属、首引/第二引/零重开前提全部生成时断言。
--
-- 做：4 BACKGROUND content/claim/background + 5 组逐字引用（(claim,source) 主键每对恰一行）+
--   8 行 background_line（四句绝句：scene→1-2 city→3-4 world→3-4 person→1-2，
--   绑 text-work-t300-146-ws 的 4 行；绝句四句承载四层，一、二联可跨层复用——
--   V056 1/1/1/1 之后第二种四句挂载：2/2 联跨层）+ 零 poetry_source 行 + 不碰 poetry_text_line。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「題有雜目，雜目在史部七十五卷全零；詩問寒梅，寒梅在史部只無花可問」）：
--   * 雜詩类名全零+梅 19 全专名而寒梅/梅花等五词全零——问梅之问史部无处可问（机器六连断言）；
--   * 故鄉恰一（开元九年逃戸制）入引为判决证据，诗集侧他卷寒梅四处/綺窗三处零入引；
--   * 皇子名「和王綺」在册不引（同名有主，audit 硬卡）；
--   * 此诗正文第二引上限用满：V018 一引在先（全库查重恰一处），对后来迁移关闭；
--   * 组诗切选（section=二）与第三首桩「已見寒梅發」系结构照登——选本切断前后文如实登记、不裁决；
--   * 读法声明（问乡者即羁旅者/故乡二字连说即急处）均标明非史实；
--   * KNOWN 零如实记录（第十五例，audit 反向断言 SQL 无 KNOWN 字面量）；
--   * 柴毁骨立（V057）/事母崔氏（V055）/茶鐺（V054）判例只引不重开——行迹三连逐字跳过 V057 句。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 58，不含 59
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-146-%';             -- 空
--   SELECT id FROM poetry_source WHERE id='source-quantangshi-128';     -- 恰 1（V026/V040 已立，本迁移复用不新建）
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-146-ws';  -- 恰 4
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-146-%';       -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-146';                                  -- 8（四句×四层，2/2 联跨层）
--   SELECT certainty FROM poetry_claim WHERE id LIKE 'claim-bg-146-%';  -- 四行全 LIKELY（有意全 LIKELY）
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-146'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-146';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-146-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
--   SELECT COUNT(*) FROM poetry_source WHERE id='source-quantangshi-128';  -- 恰 1（复用，非本迁移所立）
-- 回滚: recovery/V059_rollback.sql（按 id 全枚举删除；零 source 删除——卷128 源行为 V026/V040 所立）
START TRANSACTION;

-- ---------- 1. 零新 source（卷128 源行 V026/V040 已立，本迁移复用） ----------
-- ---------- 2. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-146-scene' AS id, 'BACKGROUND' AS entity_type, '146-scene' AS slug, '眼前：千言万语只问一株花' AS title, '四层处境背景（阶段 D 第 40 首·四句绝句 2/2 联）；史实句均有逐字引证；系年第三十四次判决（题证系列第廿二状·杂目与寒梅）「題有雜目，雜目在史部七十五卷全零；詩問寒梅，寒梅在史部只無花可問」——通鉴「雜詩」零命中（类名不进史部）；「梅」恰 19 处全专名而寒梅/梅花/梅開/折梅/寄梅五词全零（机器断言六连）；「故鄉」恰一处=开元九年（辛酉，七二一）逃戸制「或牒歸故鄉」（闭域+窗口，同字两界第四形态，入引为判决证据）；「綺」恰四处=丝帛二+皇子和王名綺二（同名有主在册零入引）；组诗切选结构首录（title=整组题而 section=二+further 消歧首见+快照雜詩页恰三皆入选）；卷128 一锚三桩（第三首桩「已見寒梅發」——寒梅在组诗里有前文，选本切断，照登不裁决）；零新源（卷128 源 V026/V040 已立）；此诗正文第二引上限用满对后来关闭（V018 在先+全库查重）；旧传行迹三句连引首引（柴毁骨立 V057 逐字跳过零重开）；KNOWN 零如实记录（第十五例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-146-city' AS id, 'BACKGROUND' AS entity_type, '146-city' AS slug, '这座城：选本从组诗里挑走的那一首' AS title, '四层处境背景（阶段 D 第 40 首·四句绝句 2/2 联）；史实句均有逐字引证；系年第三十四次判决（题证系列第廿二状·杂目与寒梅）「題有雜目，雜目在史部七十五卷全零；詩問寒梅，寒梅在史部只無花可問」——通鉴「雜詩」零命中（类名不进史部）；「梅」恰 19 处全专名而寒梅/梅花/梅開/折梅/寄梅五词全零（机器断言六连）；「故鄉」恰一处=开元九年（辛酉，七二一）逃戸制「或牒歸故鄉」（闭域+窗口，同字两界第四形态，入引为判决证据）；「綺」恰四处=丝帛二+皇子和王名綺二（同名有主在册零入引）；组诗切选结构首录（title=整组题而 section=二+further 消歧首见+快照雜詩页恰三皆入选）；卷128 一锚三桩（第三首桩「已見寒梅發」——寒梅在组诗里有前文，选本切断，照登不裁决）；零新源（卷128 源 V026/V040 已立）；此诗正文第二引上限用满对后来关闭（V018 在先+全库查重）；旧传行迹三句连引首引（柴毁骨立 V057 逐字跳过零重开）；KNOWN 零如实记录（第十五例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-146-world' AS id, 'BACKGROUND' AS entity_type, '146-world' AS slug, '这个天下：十九个梅字无一梅花' AS title, '四层处境背景（阶段 D 第 40 首·四句绝句 2/2 联）；史实句均有逐字引证；系年第三十四次判决（题证系列第廿二状·杂目与寒梅）「題有雜目，雜目在史部七十五卷全零；詩問寒梅，寒梅在史部只無花可問」——通鉴「雜詩」零命中（类名不进史部）；「梅」恰 19 处全专名而寒梅/梅花/梅開/折梅/寄梅五词全零（机器断言六连）；「故鄉」恰一处=开元九年（辛酉，七二一）逃戸制「或牒歸故鄉」（闭域+窗口，同字两界第四形态，入引为判决证据）；「綺」恰四处=丝帛二+皇子和王名綺二（同名有主在册零入引）；组诗切选结构首录（title=整组题而 section=二+further 消歧首见+快照雜詩页恰三皆入选）；卷128 一锚三桩（第三首桩「已見寒梅發」——寒梅在组诗里有前文，选本切断，照登不裁决）；零新源（卷128 源 V026/V040 已立）；此诗正文第二引上限用满对后来关闭（V018 在先+全库查重）；旧传行迹三句连引首引（柴毁骨立 V057 逐字跳过零重开）；KNOWN 零如实记录（第十五例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-146-person' AS id, 'BACKGROUND' AS entity_type, '146-person' AS slug, '这个人：问乡的人自己就在路上' AS title, '四层处境背景（阶段 D 第 40 首·四句绝句 2/2 联）；史实句均有逐字引证；系年第三十四次判决（题证系列第廿二状·杂目与寒梅）「題有雜目，雜目在史部七十五卷全零；詩問寒梅，寒梅在史部只無花可問」——通鉴「雜詩」零命中（类名不进史部）；「梅」恰 19 处全专名而寒梅/梅花/梅開/折梅/寄梅五词全零（机器断言六连）；「故鄉」恰一处=开元九年（辛酉，七二一）逃戸制「或牒歸故鄉」（闭域+窗口，同字两界第四形态，入引为判决证据）；「綺」恰四处=丝帛二+皇子和王名綺二（同名有主在册零入引）；组诗切选结构首录（title=整组题而 section=二+further 消歧首见+快照雜詩页恰三皆入选）；卷128 一锚三桩（第三首桩「已見寒梅發」——寒梅在组诗里有前文，选本切断，照登不裁决）；零新源（卷128 源 V026/V040 已立）；此诗正文第二引上限用满对后来关闭（V018 在先+全库查重）；旧传行迹三句连引首引（柴毁骨立 V057 逐字跳过零重开）；KNOWN 零如实记录（第十五例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 3. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-146-scene' AS id, 'bg-146-scene' AS subject_id, 'context' AS property_key, '四句全诗本文（ws 页四标记全零、Textquality 100%——零标记与完备并存，同 V048/V053 判例）；全句第二引：正文 V018 text claim 已一引在先（生成时全库查重恰一处，查重针取末句尾段），两度上限至此用满、此诗正文对后来迁移关闭（audit 硬卡）；「故鄉二字连说两遍即急处」系读法声明。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-146-city' AS id, 'bg-146-city' AS subject_id, 'context' AS property_key, '组诗切选结构首录：title=雜詩三首 而 section=二——选本从组诗挑第二首，切选动作在 header 字段（section 字段第二用途，对照 V054 题异注）；{{further|雜詩}} 消歧链接首见——快照雜詩页恰三皆入选（机器断言）；底注锚点片段非空（同 V058 全锚形态）；卷128 源行 V026/V040 已立零新源；卷128 一锚三桩（三首各一桩，第三首桩题「已見寒梅發」——组诗里寒梅有前文，选本切断前后文，照登不裁决）；全唐詩「雜詩」题族六卷二十处、「寒梅」五处唯此属本篇；分类行「五言絕句」系整理者动作；题有杂目而无时→零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-146-world' AS id, 'bg-146-world' AS subject_id, 'context' AS property_key, '通鉴「雜詩」全零（类名不进史部）；「梅」恰 19 处全专名而寒梅/梅花/梅開/折梅/寄梅五词全零（机器断言六连——史部十九梅无一梅花）；故鄉恰一处=tj-212 開元九年（辛酉，七二一）逃戸自首制「或牒歸故鄉」（闭域+窗口断言，逐字入引为判决证据——同字两界第四形态）；綺恰四处=丝帛二+皇子和王名綺二（同名有主在册零入引，audit 硬卡）；两传王维段乡/綺/梅全零+旧传所在卷故鄉全零；certainty 不覆盖任何系年，诗 time.span/event.name/written_during 零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-146-person' AS id, 'bg-146-person' AS subject_id, 'context' AS property_key, '旧传行迹三句连引首引（生成时全库引文域查重：歴右拾遺句/服闋句/天寳末句既往各零命中，audit 硬卡；三句之间「柴毁骨立」V057 一引在册逐字跳过零重开，audit 硬卡）；问乡者即羁旅者为读法声明非史实；旧传所在卷故鄉全零、两传王维段乡/綺/梅全零（机器断言）；已用判例句零重开；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-146-scene' AS subject_id, 'context' AS property_key, 'claim-bg-146-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-146-city' AS subject_id, 'context' AS property_key, 'claim-bg-146-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-146-world' AS subject_id, 'context' AS property_key, 'claim-bg-146-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-146-person' AS subject_id, 'context' AS property_key, 'claim-bg-146-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 4. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-146-scene' AS id, 'work-t300-146' AS work_id, 'SCENE' AS layer, '四句是一个人在驿路上拦住老乡：你从故乡来，该知道故乡的事（「君自故鄉來，應知故鄉事」——「故鄉」二字一句里连说两遍，急处即在这里）；那么——你动身那天，绮窗前那株寒梅，开花了没有（「來日綺窗前，寒梅着花未」——千言万语，千挑万选，只问这一株花；此诗正文系**第二引**：V018 text claim 已一引在先，全库查重恰一处，两度上限至此用满，此诗正文对后来迁移关闭）。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-146-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-146-city' AS id, 'work-t300-146' AS work_id, 'CITY' AS layer, '这首诗的「户口」比诗本身有意思：页首 {{further|雜詩}} 消歧链接在先——快照里「雜詩」页恰三（王維/沈佺期/無名氏，{{唐詩三百首}} 标记各在：同名三首全入选本，机器断言）。header 里 title=「雜詩三首」而 section=「二」：**标题是整组，section 指其一**——《唐詩三百首》从组诗里只挑了第二首，切选动作就写在字段里（section 字段承载选本动作首见：V054 装题异注、本篇装选第几，同字段第二用途）。页底注「↑ [[全唐詩/卷128#雜詩三首|全唐詩·卷128]]」锚点片段非空（同 V058 全锚形态）；卷128 源行 V026/V040 已立，本迁移零新源。卷128 本篇为「一锚三桩」：篇题锚点恰一，三首各一转引桩——**组诗在卷里是一户三门**（第三首桩题「已見寒梅發」：寒梅在组诗里本有前文，选本选走的中段恰把前后文切断了——照登不裁决）。页四标记全零而 100%；分类行「五言絕句」系整理者动作（V048 判例）。全唐詩「寒梅」恰 5 处唯 vol128 属本篇，他卷四处在册不引不牵合。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-146-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-146-world' AS id, 'work-t300-146' AS work_id, 'WORLD' AS layer, '**题有杂目，杂目在史部七十五卷全零**：通鉴「雜詩」二字零命中——「杂诗」是诗集自家人给无题可归的组诗起的类名，史部连这个名目都不收。**诗问寒梅，寒梅在史部只无花可问**：「梅」字通鉴 19 处全是专名（梅福/梅叔焉/梅祿啜/梅錄/黃梅/梅山/梅金錄——人名与地名），「寒梅」「梅花」「梅開」「折梅」「寄梅」五词全零（机器断言六连）——**史部有十九个梅字，一朵梅花都没有**。**故鄉同字两界第四形态**（V056 泪/V057 已矣/V058 琴之后）：开元九年（辛酉，七二一）玄宗制逃戸自首「或於所在附籍，或牒歸故鄉，各從所欲」——故鄉在史部是户籍行政的去向（恰一处，文件闭域+年标题窗口机器断言，逐字入引为判决证据）：诗里的故乡是心的方向，史里的故乡是籍的去处。**绮字三名**：诗「綺窗」之绮是织品；通鉴「綺」恰四处——丝帛之名二（紈綺/綾綺）+皇子名二（「和王」名「綺」：tj-236 封号序列+tj-244 薨条），同名有主，在册不引不牵合（audit 硬卡皇子名两条不混入引文）。本层零铸造零 relation。' AS body_text, 'SENIOR' AS audience, 'claim-bg-146-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-146-person' AS id, 'work-t300-146' AS work_id, 'PERSON' AS layer, '问故乡的人，传里写他自己在官职上辗转：旧传三句连引——「**歴右拾遺、監察御史、左補闕、庫部郎中。**」「**服闋，拜吏部郎中。**」「**天寳末，為給事中。**」——拾遗、御史、补阙、郎中一路迁转，丧假结束又回吏部，天宝末年做到给事中（生成时全库查重：三句既往零入引，本迁移首引；三句之间原有一句「居母䘮，柴毁骨立」V057 已引在册——**逐字跳过零重开**，audit 硬卡）。**诗里他问别人故乡的事，史里他自己是宦游辗转的那个人**：问乡者即羁旅者（读法声明，非史实）。
旧传所在卷「故鄉」二字全卷零（机器断言——传不提他的故乡）；两传王维段「故鄉」「綺」「梅」全零；已用判例句（柴毁骨立 V057 一引/事母崔氏 V055/茶鐺 V054/輞川 V035 系列）一个不重开；certainty 不覆盖任何系年。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-146-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 5. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-146-scene' AS claim_id, 'source-ws-t300-146' AS source_id, '页面 雜詩 (君自故鄉來)（header author+两联四句，三段以「……」相連——全句**第二引**：正文 V018 text claim 一引在先（生成时全库查重恰一处），**两度上限至此用满，此诗正文对后来迁移关闭**；页 {{别}}/{{*}}/<ref>/{{另}} 全零、100%）' AS locator, '| author   = 王維……君自故鄉來，應知故鄉事。……來日綺窗前，寒梅着花未。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-146-city' AS claim_id, 'source-ws-t300-146' AS source_id, '页面 雜詩 (君自故鄉來)（页首消歧链接+header title+section+页底注+分类行五段并收——title=整组题而 section=二：选本切选动作在字段（首见）；further 消歧在先：快照雜詩页恰三皆入选；底注「卷128#雜詩三首」锚点片段非空（同 V058 全锚）；分类行系整理者动作：非史料声明、不升格）' AS locator, '{{further|雜詩}}……| title    = 雜詩三首……| section  = 二……| notes    = {{Textquality|100%}}↑ [[全唐詩/卷128#雜詩三首|全唐詩·卷128]]……[[Category:五言絕句]]' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-146-city' AS claim_id, 'source-quantangshi-128' AS source_id, '卷一百二十八·王維《雜詩三首》篇题锚点+三首转引桩（**一锚三桩**：组诗在卷里是一户三门——机器断言各恰一；第三首桩题「已見寒梅發」：寒梅在组诗里本有前文）' AS locator, '==[[雜詩 (王維)|雜詩三首]]==……{{:雜詩 (家住孟津河)}}……{{:雜詩 (君自故鄉來)}}……{{:雜詩 (已見寒梅發)}}' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-146-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '卷二百一十二·開元九年（辛酉，七二一）逃戸自首制段（**通鉴「故鄉」恰一处**：文件闭域+年标题窗口机器断言——故鄉在史部是户籍行政的去向，与诗中乡愁同字两界，逐字入引为判决证据；「雜詩」类名全零、「梅」19 处全专名、「綺」四处分属丝帛与皇子名——在册零入引项此处均零混入）' AS locator, '州縣逃亡戶口聽百日自首，或於所在附籍，或牒歸故鄉，各從所欲。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-146-person' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十下·文苑下·王維传行迹三句连引（生成时全库引文域查重：三句既往各零入引，本迁移首引；三句之间原句「柴毁骨立」V057 已引——逐字跳过零重开；与诗中问乡并置是读法声明）' AS locator, '歴右拾遺、監察御史、左補闕、庫部郎中。……服闋，拜吏部郎中。……天寳末，為給事中。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 6. background_line（四句绝句：scene→1-2 city→3-4 world→3-4 person→1-2） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-146-scene' AS background_id, 'text-work-t300-146-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-146-scene' AS background_id, 'text-work-t300-146-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-146-city' AS background_id, 'text-work-t300-146-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-146-city' AS background_id, 'text-work-t300-146-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-146-world' AS background_id, 'text-work-t300-146-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-146-world' AS background_id, 'text-work-t300-146-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-146-person' AS background_id, 'text-work-t300-146-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-146-person' AS background_id, 'text-work-t300-146-ws' AS version_id, 2 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 7. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 59, 'Wang Wei Miscellaneous Poems, part two of three (work-t300-146) background layers (stage-D poem 40, quatrain, couplet-mapping 2/2 across four layers): dating verdict thirty-four, twenty-second shape of the title-evidence series -- the category name and the plum that never blooms: the character-string za-shi (miscellaneous poem) scores zero across all seventy-five Tongjian volumes (a poets'' own label for unclassifiable verse: the histories do not even carry the category name), while the character mei (plum) appears nineteen times and every one of them is a proper noun -- Mei Fu the official, Mei Lu the envoy, Huang-mei and Mei-shan the place-names -- with cold-plum, plum-blossom, plum-opening, breaking-plum and sending-plum all zero: nineteen mei-characters in the histories and not one plum blossom, so the poem''s question has nowhere in the histories to be asked (six-fold machine assertion); native-village, the fourth same-character split: the Tongjian''s single native-village is the 721 edict on registering fugitive households -- "or by warrant return to the native village" -- native village as the destination of household-registration administration, against the poem''s hometown of the heart (file-closed, year-heading windowed, excerpted as the verdict''s evidence); qi (figured silk) exactly four times -- two bolts of silk and two entries naming the Prince of He as Qi: namesakes have owners and are logged never quoted (audit hard-assert); the anthology''s cutting act recorded for the first time: the page title is the whole three-poem group while the section field says "two" -- the Three Hundred Poems lifted part two out of the group, and the cut itself sits in the header; further-disambiguation notice first seen, three Miscellaneous-Poem pages all anthologized; quan tang shi juan 128 one anchor with three transclusion stubs -- stub three reads "already saw the cold plum sprout": the cold plum had a context in the group that the anthology cut away, logged as found, never adjudicated; zero new sources (juan 128''s source row registered by V026/V040); the poem body hits its two-use ceiling (V018 first, machine-swept, closure declared); PERSON first-cites three Old History career sentences while literally skipping the mother''s-mourning sentence V057 already quoted (audit hard-assert); KNOWN zero honestly recorded (fifteenth instance, audit reverse-asserts); closed precedent keywords stay out of citations'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 59);
COMMIT;
