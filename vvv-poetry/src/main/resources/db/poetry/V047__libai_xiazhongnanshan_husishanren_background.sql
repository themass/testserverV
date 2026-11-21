-- V047：李白《下終南山過斛斯山人宿置酒》(work-t300-325) 四层背景（阶段 D 第 28 首·十四句五古）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V014、V015、V016、V018 已执行（work-t300-325 与其 text-work-t300-325-ws、
--       source-ws-t300-325 是 V018 的行；source-jiutangshu-wenyuan / source-xintangshu-wenyi
--       是 V016 的行；source-zizhi-tongjian-events 是 V014/V015 已立的通鉴事件源——均不另开）。
--       本迁移零新 source（断言）。
--
-- 数据源（可复现）：emit_v047.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/下終南山過斛斯山人宿置酒.txt（页内零标记反向断言；题「遇」/底注「過」并收）、
--   舊唐書卷190下（负证扫描）、新唐書卷202（任侠短语）、通鑑卷210（疾径段）——
--   传区间归属、通鉴年标题位置（景雲二年→先天元年）、斛斯三层负证全部生成时断言。
--
-- 做：0 个新 source（断言）+ 4 BACKGROUND content/claim/background +
--   4 组逐字引用（(claim,source) 主键每对恰一行）+
--   14 行 background_line（十四句形制：scene→1-4 city→5-8 world→9-11 person→12-14，
--   绑 text-work-t300-325-ws 的 14 行）。本迁移不碰 poetry_text_line。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「题有山有人，山有传径而人无传名」）：
--   * 山（终南）在史部档案=仕宦疾径（通鉴 711 段，年标题位置断言）；
--     人（斛斯山人）两传李白区间零见、通鉴唯一斛斯=乐工斛斯正（同姓不同人双断言）、
--     全唐詩斛斯诸人衔称俱不合——谁也认领不了；
--   * 题目跨源异文：ws 题「遇」/ws 底注锚点+全唐詩标题「過」——同页并收登记不裁决；
--   * KNOWN 零：疾径段单得、任侠短语单得（旧传此段为家世句不合龙）——都不升；
--   * 两种终南形状并置、游侠手与忘机枪并置均为读法声明，audit 双声明在 BG 文本内；
--   * 酒八仙人/竹溪六逸/崔宗之锦袍/浪迹江湖/天机/辋川/鳏居/奉佛判例只引不重开。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 46，不含 47
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-325-%';             -- 空
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-325-ws';  -- 恰 14（五古）
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-325-%';       -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-325';                                  -- 14（4/4/3/3）
--   SELECT certainty FROM poetry_claim WHERE id LIKE 'claim-bg-325-%';  -- 四行全 LIKELY（有意全 LIKELY）
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-325'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-325';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-325-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
-- 回滚: recovery/V047_rollback.sql（按 id 全枚举删除；不动 V014/V015/V018/V032/V045 的行，不动共用来源行）
START TRANSACTION;

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-325-scene' AS id, 'BACKGROUND' AS entity_type, '325-scene' AS slug, '眼前：从山里往下走的录像' AS title, '四层处境背景（阶段 D 第 28 首·十四句五古 4/4/3/3）；史实句均有逐字引证；background_line 十四句形制：scene 4 行 city 4 行 world 3 行 person 3 行；系年第二十二次判决「题有山有人，山有传径而人无传名」（题证系列第十状）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 零（通鉴疾径段单得、新传任侠短语单得——都不合龙不升，如实记录）；负证机器复查三层（斛斯两传区间全零/通鉴唯一斛斯必为乐工斛斯正/通鉴年标题位置断言）；题目跨源异文遇/過同页并收登记不裁决（首见跨源题异登记）。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-325-city' AS id, 'BACKGROUND' AS entity_type, '325-city' AS slug, '这座城：题的一半进档案' AS title, '四层处境背景（阶段 D 第 28 首·十四句五古 4/4/3/3）；史实句均有逐字引证；background_line 十四句形制：scene 4 行 city 4 行 world 3 行 person 3 行；系年第二十二次判决「题有山有人，山有传径而人无传名」（题证系列第十状）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 零（通鉴疾径段单得、新传任侠短语单得——都不合龙不升，如实记录）；负证机器复查三层（斛斯两传区间全零/通鉴唯一斛斯必为乐工斛斯正/通鉴年标题位置断言）；题目跨源异文遇/過同页并收登记不裁决（首见跨源题异登记）。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-325-world' AS id, 'BACKGROUND' AS entity_type, '325-world' AS slug, '这个天下：同一座山的两种形状' AS title, '四层处境背景（阶段 D 第 28 首·十四句五古 4/4/3/3）；史实句均有逐字引证；background_line 十四句形制：scene 4 行 city 4 行 world 3 行 person 3 行；系年第二十二次判决「题有山有人，山有传径而人无传名」（题证系列第十状）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 零（通鉴疾径段单得、新传任侠短语单得——都不合龙不升，如实记录）；负证机器复查三层（斛斯两传区间全零/通鉴唯一斛斯必为乐工斛斯正/通鉴年标题位置断言）；题目跨源异文遇/過同页并收登记不裁决（首见跨源题异登记）。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-325-person' AS id, 'BACKGROUND' AS entity_type, '325-person' AS slug, '这个人：游侠的手与忘机的脸' AS title, '四层处境背景（阶段 D 第 28 首·十四句五古 4/4/3/3）；史实句均有逐字引证；background_line 十四句形制：scene 4 行 city 4 行 world 3 行 person 3 行；系年第二十二次判决「题有山有人，山有传径而人无传名」（题证系列第十状）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 零（通鉴疾径段单得、新传任侠短语单得——都不合龙不升，如实记录）；负证机器复查三层（斛斯两传区间全零/通鉴唯一斛斯必为乐工斛斯正/通鉴年标题位置断言）；题目跨源异文遇/過同页并收登记不裁决（首见跨源题异登记）。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-325-scene' AS id, 'bg-325-scene' AS subject_id, 'context' AS property_key, '十四句全诗本文（ws 页页内零异文标记——另/别/自注三类皆无，audit 反向断言；Textquality 75% 与零标记并存如实记）；归途录像/主人出场法等为本层读法声明，非史料断言；题目跨源异文遇/過见 CITY 层。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-325-city' AS id, 'bg-325-city' AS subject_id, 'context' AS property_key, '人无传名：斛斯两传李白区间计数全零+通鉴唯一命中必为乐工斛斯正（同姓不同人位置字样双断言，生成时复查）；题有山（终南有传径，WORLD 层立证）有人（斛斯山人无传名）；题目跨源异文遇（ws 题）/過（ws 底注锚点+全唐詩标题）同页并收登记不裁决（tang300-variants.md 新行）；山有传径而人无传名→零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-325-world' AS id, 'bg-325-world' AS subject_id, 'context' AS property_key, '通鉴 711 终南疾径段单得（两唐书无此轶，合龙无望）→不升；年标题位置断言（景雲二年→先天元年之间，V034 立规）；两种终南形状并置为读法声明非史料断言；不给诗系年；certainty 不覆盖任何系年，诗 time.span/event.name/written_during 零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-325-person' AS id, 'bg-325-person' AS subject_id, 'context' AS property_key, '新传任侠短语单得（旧传此段为家世句，两传不合龙）→不升；游侠手与忘机枪的并置为读法声明；酒八仙人/竹溪六逸/崔宗之锦袍/浪迹江湖/天机/辋川/鳏居/奉佛判例零重开（audit 关键语硬卡）；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-325-scene' AS subject_id, 'context' AS property_key, 'claim-bg-325-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-325-city' AS subject_id, 'context' AS property_key, 'claim-bg-325-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-325-world' AS subject_id, 'context' AS property_key, 'claim-bg-325-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-325-person' AS subject_id, 'context' AS property_key, 'claim-bg-325-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-325-scene' AS id, 'work-t300-325' AS work_id, 'SCENE' AS layer, '十四句是一场从山里往下走的完整录像：黄昏从碧山下来，月亮跟着人走（「暮從碧山下，山月隨人歸」——归途上月光认人）；回头看走过的路，苍青色已横在山腰（「卻顧所來徑，蒼蒼橫翠微」——山在身后合拢）；牵着手的引到了田家，孩子来开柴门（「相攜及田家，童稚開荊扉」——主人没露脸，先出来的是孩子和门）；绿竹引着幽径，藤萝拂着行人的衣裳（「綠竹入幽徑，青蘿拂行衣」——庄园用植物来迎接）；欢言间找到了歇处，美酒一杯杯地挥（「歡言得所憩，美酒聊共揮」——题面的「宿」与「置酒」在此兑现）；长歌合着松风，唱到河上星稀（「長歌吟松風，曲盡河星稀」——夜向深处）；我醉了你也高兴，陶然里一起忘了机心（「我醉君復樂，陶然共忘機」——「忘機」两个字就是这个人的全部档案）。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-325-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-325-city' AS id, 'work-t300-325' AS work_id, 'CITY' AS layer, '这座「城」是终南山里一座无名田庄。题一半进档案、一半不进：山有传径（通鉴 711 年司马承祯语——终南乃「仕宦之疾徑」，入史部的身份是**仕进招牌**，WORLD 层逐字立证）；人无传名——「斛斯」在两传李白区间计数全零（生成时断言），通鉴 75 卷唯一一处「斛斯」是卷 194 的乐工斛斯正（机器断言：唯一命中必为「斛斯正」——同姓不同人，不许牵合）；全唐詩里斛斯姓存数人（斛斯融等，衔称俱不合）——谁也认领不了这位山人。
题目自身还有一层跨源异文：ws 页题「下終南山**遇**」，页底注与全唐詩·卷179 标题作「**過**」——两支在同一页上各自在场，本迁移引文并收，登记不裁决。「遇」是途遇的偶然，「過」是访友的常礼——读感之差留给读者，史料不代答。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-325-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-325-world' AS id, 'work-t300-325' AS work_id, 'WORLD' AS layer, '同一座终南山，711 年的史部档案是功名场：通鉴记尚書左丞卢藏用指着终南山对司马承祯说「此中大有佳處，何必天台」，承祯回了一句千古的坏话——「**此乃仕宦之疾徑耳**！」通鉴紧跟着补刀：「藏用嘗隱終南，則天時征為左拾遺，故承禎言之」（年标题位置断言：此事落在景雲二年与先天元年之间）。终南山在史部的形状是一块**终南捷径**的招牌。
而这首诗是同一个山的另一种形状：黄昏下山、柴门、美酒、忘机——一个不走捷径的人，去拜访一个不做官的人。**两种形状的并置是本层的读法声明**：史实只有通鉴一段，它单得（两唐书无此轶）→不升，LIKELY。盛唐的终南山同时装着这两种人——这条上下文到此为止，**不给诗系年**：李白下的是哪一年的终南，两传一鉴都不能给。' AS body_text, 'SENIOR' AS audience, 'claim-bg-325-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-325-person' AS id, 'work-t300-325' AS work_id, 'PERSON' AS layer, '新传给这个人的底色是刀：「喜縱橫術，擊劍，為任俠，輕財重施」（单得——旧传李白传此段是另一笔「父爲任城尉，因家焉」的家世，两传此处不合龙，不升）。
把这两句和诗的收句并排放：传里说他轻财好施、任侠尚气，诗末他说陶然忘机——**游侠的手与忘机的脸**，同一个人两副档案。这是读法并置，不是史实；史实只有新传一句。斛斯山人不在这句里，也不在任何传里：诗把主人写成「君」，史把主人留成零——判例零重开（audit 硬卡）：酒八仙人、竹溪六逸、崔宗之锦袍、浪迹江湖、天机画评、辋川、鳏居、奉佛，本层一个不引。' AS body_text, 'SENIOR' AS audience, 'claim-bg-325-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-325-scene' AS claim_id, 'source-ws-t300-325' AS source_id, '页面 下終南山遇斛斯山人宿置酒（header title+author+十四句七联，九段以「……」相連——页面零异文标记（Textquality 75% 但另/别/自注三类皆无），无标记即不造标记；同一 (claim,source) 主键下一行容全文，V037/V039/V040/V041/V042/V043/V044/V045/V046 判例；全文另见 V018 claim-t300-325-text 引文）' AS locator, '| title    = 下終南山遇斛斯山人宿置酒……| author   = 李白……暮從碧山下，山月隨人歸。……卻顧所來徑，蒼蒼橫翠微。……相攜及田家，童稚開荊扉。……綠竹入幽徑，青蘿拂行衣。……歡言得所憩，美酒聊共揮。……長歌吟松風，曲盡河星稀。……我醉君復樂，陶然共忘機。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-325-city' AS claim_id, 'source-ws-t300-325' AS source_id, '页面 下終南山遇斛斯山人宿置酒（header title+页底注两字段并收——跨源题目异文的两支在同一页各自在场：题面「遇」、底注锚点「過」，登记不裁决（tang300-variants.md 新行）；人无传名的负证为两传区间+通鉴斛斯正双断言，生成时机器复查，诗身不代拟进引文）' AS locator, '| title    = 下終南山遇斛斯山人宿置酒……↑ [[全唐詩/卷179#下終南山過斛斯山人宿置酒|全唐詩·卷179]]' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-325-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '卷二百一十·睿宗景雲二年条内（卢藏用指终南/司马承祯仕宦疾径/藏用尝隐终南——年标题位置断言：落在景雲二年（辛亥，七一一年）与先天元年（壬子，七一二年）之间；单得不升）' AS locator, '尚書左丞盧藏用指終南山謂承禎曰：「此中大有佳處，何必天台！」承禎曰：「以愚觀之，此乃仕宦之疾徑耳！」藏用嘗隱終南，則天時征為左拾遺，故承禎言之。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-325-person' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百零二·文藝中·李白传任侠短语（喜纵横术/击剑任侠/轻财重施——新传单得，旧传此段为家世句不合龙；与诗收句的并置是读法声明）' AS locator, '喜縱橫術，擊劍，為任俠，輕財重施。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（十四句：4/4/3/3） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-325-scene' AS background_id, 'text-work-t300-325-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-325-scene' AS background_id, 'text-work-t300-325-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-325-scene' AS background_id, 'text-work-t300-325-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-325-scene' AS background_id, 'text-work-t300-325-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-325-city' AS background_id, 'text-work-t300-325-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-325-city' AS background_id, 'text-work-t300-325-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-325-city' AS background_id, 'text-work-t300-325-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-325-city' AS background_id, 'text-work-t300-325-ws' AS version_id, 8 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-325-world' AS background_id, 'text-work-t300-325-ws' AS version_id, 9 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-325-world' AS background_id, 'text-work-t300-325-ws' AS version_id, 10 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-325-world' AS background_id, 'text-work-t300-325-ws' AS version_id, 11 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-325-person' AS background_id, 'text-work-t300-325-ws' AS version_id, 12 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-325-person' AS background_id, 'text-work-t300-325-ws' AS version_id, 13 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-325-person' AS background_id, 'text-work-t300-325-ws' AS version_id, 14 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 47, 'Li Bai Coming Down from the Southern Peak and Staying Overnight at a Hermit of the Husi Clan background layers (stage-D poem 28, fourteen-line five-character ancient, 4/4/3/3): dating verdict twenty-two, tenth shape of the title-evidence series -- the title splits into mountain and man, and only the mountain files papers: in the histories the Southern Peak has a reputation (Tongjian 711: Lu Cangyong points at it, Sima Chengzhen calls it the express path into office, and Tongjian brackets the entry positionally between the Jingyun-2 and Xiantian-1 year-headings), while the man has none: the surname Husi counts zero inside the Li Bai spans of both Tang histories, its single Tongjian occurrence is proven to be the groom Husi Zheng (same surname, different person -- position plus wording doubly asserted) -- zero forging, zero relation; a first-of-series cross-source title variant: the wikisource page title reads encountering while its own edition note and the Quantangshi heading read visiting -- both variants co-present on one page, quoted together, registered, never ruled; KNOWN zero honestly recorded (the express-path passage is single-source; the new-history phrase on swordplay and generosity is single-source -- the old history runs a family anecdote in that same slot, no agreement, no promotion); the two shapes of the mountain and the wuxia hands against the forgetting-worldliness face are declared as readings, not facts; the eight-drunk-immortals / bamboo-creek / Cui-Zongzhi / wandering / tian-ji / Wang-chuan / widower / piety lines stay closed precedents (audit keyword zero-entry); zero new sources'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 47);
COMMIT;
