-- V054：王維《終南山》(work-t300-137) 四层背景（阶段 D 第 35 首·皇家山与无时诗）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V014、V015、V016、V018、V035、V047、V053 已执行（work-t300-137 与其
--       text-work-t300-137-ws、source-ws-t300-137 是 V018 的行；source-quantangshi-126 是 V035 的行；
--       source-jiutangshu-wenyuan 是 V016 的行；source-zizhi-tongjian-events 是 V014/V015 已立的通鉴事件源）。
--       **本迁移零新 source**（audit 断言 SQL 无任何诗源表新建插入语句）。
--
-- 数据源（可复现）：emit_v054.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/終南山__王維_.txt（{{*}} 题异注在 section 字段首见+相邻双 {{另}} 首见+
--   100% 与五枚标记正交修正）、舊唐書卷190下（斋中四物句首引+王维段负证）、
--   新唐書卷202（王维段负证）、通鑑卷191/198/208/210（皇家事五处+五年标题窗口）
--   + 通鑑 75 卷/全唐詩 120 卷负证计数扫描+既有迁移引文域逐句查重——
--   传区间归属、終南山/疾徑全部计数、断词与作者名两类假命中、年标题窗口、
--   首引前提与第二引前提全部生成时断言。
--
-- 做：4 BACKGROUND content/claim/background + 5 组逐字引用（(claim,source) 主键每对恰一行）+
--   8 行 background_line（八句形制：scene→1-2 city→3-4 world→5-6 person→7-8，
--   绑 text-work-t300-137-ws 的 8 行）。本迁移不碰 poetry_text_line。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「題有山有史，史是皇家事；詩有山無時，無時亦無年」）：
--   * 山有史、史非诗史：通鉴恰 5 处全归皇家事（闭域+五年窗口断言，含七零七年「零」字防线）；
--   * 「仕宦之疾徑」第二引上限用满：V047 一引在先（全库查重恰一处），此句对后来迁移关闭；
--   * 两类假命中在册零入引：tj-251 断词「疾徑奄至」（后字必奄）+卷784 作者名「終南山翁」（后字必翁）；
--   * 100% 与异文数正交（V048 判例边界修正——只适用零标记页，本页 100% 带五枚标记）；
--   * {{*}} 题异注首见 section 字段+同行相邻双 {{另}} 首见（audit 双照登硬卡）；
--   * 旧传斋中四物句首引（全库查重既往零引）——与 V053「传句用尽」互为镜像；
--   * 全景无时/大山小房并置均为读法声明，audit 双声明在 BG 文本内；
--   * KNOWN 零如实记录（第十例，audit 反向断言 SQL 无 KNOWN 字面量）；
--   * 不才/凝碧/輞川/藍田/長齋/茶鐺以外的奉佛句/尤長五言/以詩名盛/代宗诏集 判例只引不重开。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 53，不含 54
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-137-%';             -- 空
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-137-ws';  -- 恰 8
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-137-%';       -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-137';                                  -- 8（2/2/2/2）
--   SELECT certainty FROM poetry_claim WHERE id LIKE 'claim-bg-137-%';  -- 四行全 LIKELY（有意全 LIKELY）
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-137'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-137';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-137-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
--   SELECT COUNT(*) FROM poetry_source WHERE id='source-ws-t300-137';   -- 恰 1（V018 旧行，零新源）
-- 回滚: recovery/V054_rollback.sql（按 id 全枚举删除；不动任何共用来源行、不动 V018 的行）
START TRANSACTION;

-- ---------- 1. BACKGROUND content identities（零新 source——断言在生成器 audit） ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-137-scene' AS id, 'BACKGROUND' AS entity_type, '137-scene' AS slug, '眼前：一座没有时间的全景山' AS title, '四层处境背景（阶段 D 第 35 首·八句律詩 2/2/2/2）；史实句均有逐字引证；系年第二十九次判决（题证系列第十七状·皇家山与无时诗）「題有山有史，史是皇家事；詩有山無時，無時亦無年」——通鉴「終南山」恰 5 处五年标题窗口全归营宫/亡入/修宫/杀太子/隐宦捷径（V050 山无史山的镜像：山有史、史非诗史）→time.span/event.name/written_during 全缺席、零 relation；{{*}} 题异注首见 section 字段（終南山/終南山行/終山行并挂照登不裁决）；同行相邻双 {{另}} 首见（連山接/連天到四种组合——audit 硬卡连续标记）；诚实边界修正：100% 与五枚标记正交（V048 判例仅适用零标记页）；「仕宦之疾徑」第二引上限用满对后来关闭（V047 在先+全库查重）；断词假命中第二例在册（tj-251 疾徑奄至后字必奄）；作者名假命中在册（卷784 終南山翁后字必翁）；旧传斋中四物句首引（全库查重既往零引——与 V053 传句用尽互为镜像）；KNOWN 零如实记录（第十例，audit 反向断言）；零新 source；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-137-city' AS id, 'BACKGROUND' AS entity_type, '137-city' AS slug, '这座城：三个题目与四件物外的斋' AS title, '四层处境背景（阶段 D 第 35 首·八句律詩 2/2/2/2）；史实句均有逐字引证；系年第二十九次判决（题证系列第十七状·皇家山与无时诗）「題有山有史，史是皇家事；詩有山無時，無時亦無年」——通鉴「終南山」恰 5 处五年标题窗口全归营宫/亡入/修宫/杀太子/隐宦捷径（V050 山无史山的镜像：山有史、史非诗史）→time.span/event.name/written_during 全缺席、零 relation；{{*}} 题异注首见 section 字段（終南山/終南山行/終山行并挂照登不裁决）；同行相邻双 {{另}} 首见（連山接/連天到四种组合——audit 硬卡连续标记）；诚实边界修正：100% 与五枚标记正交（V048 判例仅适用零标记页）；「仕宦之疾徑」第二引上限用满对后来关闭（V047 在先+全库查重）；断词假命中第二例在册（tj-251 疾徑奄至后字必奄）；作者名假命中在册（卷784 終南山翁后字必翁）；旧传斋中四物句首引（全库查重既往零引——与 V053 传句用尽互为镜像）；KNOWN 零如实记录（第十例，audit 反向断言）；零新 source；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-137-world' AS id, 'BACKGROUND' AS entity_type, '137-world' AS slug, '这个天下：山从 625 排到 711 都是皇家的事' AS title, '四层处境背景（阶段 D 第 35 首·八句律詩 2/2/2/2）；史实句均有逐字引证；系年第二十九次判决（题证系列第十七状·皇家山与无时诗）「題有山有史，史是皇家事；詩有山無時，無時亦無年」——通鉴「終南山」恰 5 处五年标题窗口全归营宫/亡入/修宫/杀太子/隐宦捷径（V050 山无史山的镜像：山有史、史非诗史）→time.span/event.name/written_during 全缺席、零 relation；{{*}} 题异注首见 section 字段（終南山/終南山行/終山行并挂照登不裁决）；同行相邻双 {{另}} 首见（連山接/連天到四种组合——audit 硬卡连续标记）；诚实边界修正：100% 与五枚标记正交（V048 判例仅适用零标记页）；「仕宦之疾徑」第二引上限用满对后来关闭（V047 在先+全库查重）；断词假命中第二例在册（tj-251 疾徑奄至后字必奄）；作者名假命中在册（卷784 終南山翁后字必翁）；旧传斋中四物句首引（全库查重既往零引——与 V053 传句用尽互为镜像）；KNOWN 零如实记录（第十例，audit 反向断言）；零新 source；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-137-person' AS id, 'BACKGROUND' AS entity_type, '137-person' AS slug, '这个人：最大的山与最小的房' AS title, '四层处境背景（阶段 D 第 35 首·八句律詩 2/2/2/2）；史实句均有逐字引证；系年第二十九次判决（题证系列第十七状·皇家山与无时诗）「題有山有史，史是皇家事；詩有山無時，無時亦無年」——通鉴「終南山」恰 5 处五年标题窗口全归营宫/亡入/修宫/杀太子/隐宦捷径（V050 山无史山的镜像：山有史、史非诗史）→time.span/event.name/written_during 全缺席、零 relation；{{*}} 题异注首见 section 字段（終南山/終南山行/終山行并挂照登不裁决）；同行相邻双 {{另}} 首见（連山接/連天到四种组合——audit 硬卡连续标记）；诚实边界修正：100% 与五枚标记正交（V048 判例仅适用零标记页）；「仕宦之疾徑」第二引上限用满对后来关闭（V047 在先+全库查重）；断词假命中第二例在册（tj-251 疾徑奄至后字必奄）；作者名假命中在册（卷784 終南山翁后字必翁）；旧传斋中四物句首引（全库查重既往零引——与 V053 传句用尽互为镜像）；KNOWN 零如实记录（第十例，audit 反向断言）；零新 source；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-137-scene' AS id, 'bg-137-scene' AS subject_id, 'context' AS property_key, '八句全诗本文（ws 页 {{另}} 恰四/{{*}} 恰一，{{Textquality|100%}}——相邻双 {{另}} 组合四种整读照登不裁决，audit 硬卡双标记字样连续入引；同一 (claim,source) 主键一行容全文判例；正文另见 V018 claim-t300-137-text——本诗正文两度上限至此用满，后来者不得三引）；全景无时与投宿读法为本层声明，非史料断言。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-137-city' AS id, 'bg-137-city' AS subject_id, 'context' AS property_key, '{{*}} 题异注首见 section 字段：終南山/終南山行/終山行三题面并挂逐字入引（audit 照登硬卡），登记不裁决；底注+分类行照登+非史料声明+不升格；诚实边界修正在册：100% 与五枚标记正交（V048 判例仅适用零标记页，如实登记）；卷126 标准锚点+桩结构（机器断言）；诗世界题族恰 25 处 13 卷在册不引；卷784「終南山翁」作者名假命中机器断言后字必翁、零入引；题有山而无时→零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-137-world' AS id, 'bg-137-world' AS subject_id, 'context' AS property_key, '山有史、史非诗史（V050 镜像）：通鉴「終南山」恰 5 处=四卷闭域（武德八年营太和宫/武德九年亡入/贞观二十一年修翠微宫/景龙元年太子走山被杀/景云二年疾径句——**五年标题窗口机器断言**，含七零七年「零」字年号防线）；「仕宦之疾徑」子句第二引上限用满（V047 一引在先，locator 声明+全库查重）；「疾徑」第二处=tj-251 断词假命中（后字必「奄」机器断言），在册零入引；两传王维段終南山/疾徑全零（传不系山，机器断言）；certainty 不覆盖任何系年，诗 time.span/event.name/written_during 零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-137-person' AS id, 'bg-137-person' AS subject_id, 'context' AS property_key, '旧传斋中四物句首引（生成时全库引文域查重：茶鐺既往零命中，audit 硬卡——与 V053「传句用尽」相反的镜像：这是王维传里最后一句未用活句）；旧传单得（新传无此句，不合并）；最大的山与最小的房并置为读法声明非史实；王维其余已用判例句零重开；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-137-scene' AS subject_id, 'context' AS property_key, 'claim-bg-137-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-137-city' AS subject_id, 'context' AS property_key, 'claim-bg-137-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-137-world' AS subject_id, 'context' AS property_key, 'claim-bg-137-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-137-person' AS subject_id, 'context' AS property_key, 'claim-bg-137-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-137-scene' AS id, 'work-t300-137' AS work_id, 'SCENE' AS layer, '八句是一整座山的全景，没有一个字带时间：远望太乙峰逼近天帝之都，山势连绵接向海隅（「太乙近天都，連{{另|山|天}}{{另|接|到}}海隅」——此联两处 {{另}} 彼此相邻：山/天、接/到，两两组合是四种整句读法——連山接、連山到、連天接、連天到，照登不裁决，同行双标记首见）；回头看白云合拢，走进青雾反而什么都看不见（「白雲迴望合，青靄入看無」——远近两试都是雾）；中峰一变便是分野，阴晴使千壑各异（「分野中峰變，陰晴{{另|眾|聚}}壑殊」——山把天空切开）；想找个有人处投宿，隔着水向樵夫问路（「欲投人處宿，隔{{另|水|浦}}問樵夫」——全景里唯一的小动作收束全诗）。全诗无一时一事，读法是读法，史实只有页上八句。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-137-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-137-city' AS id, 'work-t300-137' AS work_id, 'CITY' AS layer, '这座城的档案先登记题目本身的三个名字：section 字段挂着「{{*|題下一有「行」字，一作「終山行」}}」——終南山/終南山行/終山行并挂不裁决（{{*}} 题异注首见 section 字段，audit 照登硬卡）。页底注与分类行（五言律詩）为整理者动作：照登+非史料声明+不升格（V048 判例）。**诚实边界修正**：本页 {{Textquality|100%}} 却带五枚标记（{{另}}×4+{{*}}×1）——完备度与异文数**正交**：100% 说的是底本录入完备、不是没有异文；V048「100% 与零标记互证」仅适用于零标记页，本迁移如实登记此边界。卷126 本篇是标准「消歧锚点+转引桩」结构（对照 V053《春曉》的全卷唯一内联）。诗世界的山名题族：全唐詩「終南山」恰 25 处分布 13 卷——他人的终南山各是各诗，在册不引不牵合；机器断言卷784 两处命中后字必「翁」：「終南山翁」是**作者名**不是诗题（假命中在册第二例，V053 雞香積之后）。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-137-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-137-world' AS id, 'work-t300-137' AS work_id, 'WORLD' AS layer, 'V050 的峴山在史部零档案；这座山正相反——通鉴「終南山」恰五处，处处是皇家的事（五年标题窗口机器断言）：武德八年（乙酉，625）高祖「營太和宮於終南山」；武德九年（丙戌，626）玄武门余波「萬徹與數十騎亡入終南山」；贞观二十一年（丁未，647）太宗「命修終南山太和廢宮為翠微宮」；景龙元年（丁未，七零七年）太子重俊兵败「以百騎走終南山……憩於林下，為左右所殺」（此年号写「零」字——V050 立的异体年号机器防线在岗）；景云二年（辛亥，711）卢藏用指此山，司马承祯答「以愚觀之，此乃仕宦之疾徑耳」——隐士的捷径。
「仕宦之疾徑耳」子句系**第二引**：全句 V047 已随卢藏用故事一引，两度上限至此用满，此句对后来迁移关闭（locator 声明+生成时全库查重）。
「疾徑」通鉴恰两处，第二处是断词假命中：tj-251 濠州贼将王弘立「引兵數萬疾徑奄至」——疾=疾速、徑=取道，撞出二字（机器断言后字必「奄」，在册零入引）。**山从 625 排到 711 全是皇帝、太子、隐宦——山的全部档案没有一条属于这首诗**（V050 山无史山的镜像：山有史、史非诗史）。本层不铸时间，零铸造零 relation。' AS body_text, 'SENIOR' AS audience, 'claim-bg-137-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-137-person' AS id, 'work-t300-137' AS work_id, 'PERSON' AS layer, '旧传给这个人一间斋房：「**齋中無所有，唯茶鐺、藥臼、經案、繩牀而已**。」——茶铛、药臼、经案、绳床，四件物之外一无所有（生成时全库查重：此句从未入任何迁移引文，本迁移首引；旧传单得，新传无此句不合并）。
把斋房和山对读：诗里的终南山大到处处分野变、阴晴殊，传里的斋房小到四件物——**最大的山与最小的房**，同一个人（读法声明，不是史实）。这是本迁移唯一判例外的旧传句：王维传其余已用句（以诗名盛/凝碧/辋川/奉佛段/茶铛以外的奉佛句/代宗诏集/尤长五言）一个不重开；两传王维段「終南山」「疾徑」全零（机器断言）——传里写这个人时，根本没提这座山。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-137-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-137-scene' AS claim_id, 'source-ws-t300-137' AS source_id, '页面 終南山 (王維)（header author+四联八句，五段以「……」相連——「連{{另|山|天}}{{另|接|到}}海隅」相邻双 {{另}} 原样入引（四种整读不裁决，同行双标记首见，tang300-variants.md 新行）；同一 (claim,source) 主键一行容全文判例；正文另见 V018 claim-t300-137-text——本诗正文两度上限至此用满，后来者不得三引）' AS locator, '| author   = 王維……太乙近天都，連{{另|山|天}}{{另|接|到}}海隅。……白雲迴望合，青靄入看無。……分野中峰變，陰晴{{另|眾|聚}}壑殊。……欲投人處宿，隔{{另|水|浦}}問樵夫。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-137-city' AS claim_id, 'source-ws-t300-137' AS source_id, '页面 終南山 (王維)（section 字段 {{*}} 题异注+页底注+分类行三段并收——「題下一有「行」字，一作「終山行」」系 {{*}} 题异注首见 section 字段（三题面并挂照登不裁决，audit 照登硬卡）；底本指向与「五言律詩」分类均为整理者动作：非史料声明、不升格；本页 100% 带五枚标记=完备度与异文数正交（V048 边界修正））' AS locator, '| section  ={{*|題下一有「行」字，一作「終山行」}}……| notes    = {{Textquality|100%}}↑ [[全唐詩/卷126#終南山|全唐詩·卷126]]……[[Category:五言律詩]]' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-137-city' AS claim_id, 'source-quantangshi-126' AS source_id, '卷一百二十六·王维集《終南山 (王維)》篇题锚点+转引桩（标准 2× 结构——对照 V053《春曉》全卷唯一正文内联；诗世界题族恰 25 处 13 卷在册不引；卷784「終南山翁」作者名假命中机器在册零入引）' AS locator, '==[[終南山 (王維)|終南山]]==……{{:終南山 (王維)}}' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-137-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '卷一百九十一·武德八年营太和宫段……卷一百九十八·贞观二十一年修翠微宫段……卷二百零八·景龙元年太子走山段……卷二百一十·景云二年疾径句（皇家事五处取四段+疾径**第二引**：全句 V047 一引在先、本迁移子句二引，**两度上限至此用满，此句对后来迁移关闭**；五年标题窗口+文件闭域机器断言；tj-251 断词假命中「疾徑奄至」在册零入引）' AS locator, '甲申，上幸鄠縣，校獵於甘谷，營太和宮於終南山；丙戌，還宮。……萬徹與數十騎亡入終南山。……命修終南山太和廢宮為翠微宮……太子以百騎走終南山，至鄠西，能屬者才數人，憩於林下，為左右所殺。……承禎曰：「以愚觀之，此乃仕宦之疾徑耳！」' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-137-person' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十下·文苑下·王维传斋中四物句（茶铛/药臼/经案/绳床——生成时全库引文域查重：此句既往零入引，本迁移首引；旧传单得不合并；与诗中大山并置是读法声明）' AS locator, '齋中無所有，唯茶鐺、藥臼、經案、繩牀而已。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（八句：2/2/2/2） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-137-scene' AS background_id, 'text-work-t300-137-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-137-scene' AS background_id, 'text-work-t300-137-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-137-city' AS background_id, 'text-work-t300-137-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-137-city' AS background_id, 'text-work-t300-137-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-137-world' AS background_id, 'text-work-t300-137-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-137-world' AS background_id, 'text-work-t300-137-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-137-person' AS background_id, 'text-work-t300-137-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-137-person' AS background_id, 'text-work-t300-137-ws' AS version_id, 8 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 54, 'Wang Wei On Zhongnan Mountain background layers (stage-D poem 35, eight-line regulated verse 2/2/2/2, the mirror image of the mountain without history): dating verdict twenty-nine, seventeenth shape of the title-evidence series -- the title keeps a mountain with a full archive and a poem without a single time-word: the Tongjian''s five occurrences of Zhongnan Mountain are machine-proven to be wholly imperial (Wude 8 founding the Taihe palace, Wude 9 a fleeing prince, Zhenguan 21 rebuilding it as Cuiwei, Jinglong 1 a defeated crown prince killed in the grove -- the year written with the zero glyph, the V050 defense line on duty -- and Jingyun 2''s "the shortcut of careers"), five year-heading windows locked; the mountain''s entire archive belongs to no poem (the inversion of V050''s history-less mountain: here history is plentiful and none of it is the poem''s); the title itself carries three names registered in the section field via {{*}} for the first time (zhongnan shan / shan xing / zhong shan xing, side by side unadjudicated, audit hard-assert) and the poem''s first couplet carries the first adjacent double {{另}} pair on one line (four combinations = two whole readings, transcription verbatim); honest-boundary correction registered: Textquality 100% coexists with five markers -- completeness is orthogonal to variant count, V048''s zero-marker corollary applies only to marker-free pages; the career-shortcut sentence is cited for the second time (full sentence used in V047, machine-swept single prior hit) so the two-use ceiling closes it for all future migrations (locator declares it, audit asserts); second false hit on record: the 251st juan''s cut-word "疾徑奄至" (fast + take-road, machine-asserted next char) and juan 784''s author-name "終南山翁" (next char must be weng) -- both logged, never quoted; the Old History''s four-objects room sentence is first-cited (sweep proves zero prior citations -- the mirror of V053''s exhausted biographies); KNOWN zero honestly recorded (tenth instance, audit reverse-asserts); zero new sources; closed precedent keywords stay out of citations'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 54);
COMMIT;
