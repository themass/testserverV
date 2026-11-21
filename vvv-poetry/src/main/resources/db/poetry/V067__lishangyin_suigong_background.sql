-- V067：李商隱《隋宮》(work-t300-022) 四层背景（阶段 D 第 48 首·隋宫与谏书）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V014、V015、V016、V018、V035、V048、V057、V058、V059、V060、V061、
--       V062、V063、V064、V065、V066 已执行
--       （work-t300-022 与其 text-work-t300-022-ws、source-quantangshi-539 是 V018 的行
--       （V018 以卷539 卷页立本诗正文，version_code=vol-raw——ws 选本页当时未建源）；
--       source-ws-t300-022 是本迁移新建的选本页源（恰一枚；audit 断言）；
--       source-zizhi-tongjian-events 是 V014/V015 已立的通鉴事件源；
--       source-jiutangshu-wenyuan 是 V016 已立的旧唐书文苑传源（李商隐传在此，简化字录入）；
--       判例在册句（义山/开成二年/岭表/三十六体 V016、绹不之省/坎壈终身 V066、
--       痛哭者一/厝火積薪/狂夫之言 V065/V066）只对照不重开）。
--       **本迁移再新建恰 1 个 source（source-ws-t300-022）——连续第二首开新源（V066 判例
--       同构：卷页/诗页两个独立见证面）；audit 断言恰一枚诗源表新建插入语句且 id 唯一、
--       回滚按 id 删且只删此行。**
--
-- 数据源（可复现）：emit_v067.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/隋宮__乘興南遊不戒嚴_.txt（title 行内嵌异注首见+poem 块全无句读首见+
--   notes 挂俗名七绝首见+无评级页第二见+分类三行简繁混排+Vtext/poem 双转录）、
--   全唐詩卷539（**同卷同题双《隋宮》块**：==[[隋宮]]== 恰二+{{*|一云隋堤}} 恰一
--   +紫泉/乘興诸句各恰一——消歧判例反例；全唐诗「隋宮」恰六处四卷档扫）、
--   全唐詩卷540（《隋宮守歲》锚恰一——「隋宮」第三面档扫零入引）、
--   舊唐書卷190下（李商隐段首引二句+段内隋/煬/九重/諫/戒嚴/揚州/江都全零+段边界断言）、
--   通鑑卷192/193/195/196（行留/亡隋×2/谏书四段+四处年标题窗口）+
--   通鑑 75 卷负证计数扫描（隋宮/南遊/不戒嚴/乘興/宮錦/障泥/紫泉/螢火/垂楊/迷樓/錦帆/
--   隋堤/日角/省諫 全零+亡隋/諫書/行留/幸江都/戒嚴/後庭花 闭域）+
--   既有迁移引文域逐句查重——传区间归属、二引/零重开/首引零域/新源不存在前提全部生成时断言。
--
-- 做：新 poetry_source 行 1（source-ws-t300-022，PENDING）+
--   4 BACKGROUND content/claim/background + 5 组逐字引用（(claim,source) 主键每对恰一行）+
--   4 background_line（四句七绝 **1/1/1/1 第四次**（V056/V061/V066 之后）：scene→1 city→2
--   world→3 person→4，绑 text-work-t300-022-ws 的 4 行）+ 不碰 poetry_text_line。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「诗题隋宮在史部全零，亡隋只在谏臣嘴里」）：
--   * 诗面词通鉴全零+亡隋恰二双窗口入引+谏书恰一窗口入引+行留恰一入引（一函不省/一函得赏）；
--   * 「戒嚴」通鉴恰十处七卷系闭域档扫——诗只咬其否定式「不戒嚴」系读法（万乘之防对乘兴之君）；
--   * 「谏书两界，人身为证：干谒门开/谏诤门闭」标明读法声明；
--   * 同卷同题双块两锚皆裸名系卷539 恰二闭域上的照登——消歧判例反例首见（有同名锚仍裸名）；
--   * 异注简繁两层（一云/一雲隋堤）照登不判；poem 无句读/notes 俗名「七绝」均照登；
--   * 新源恰一枚如实开例（V066 判例同构，两引面不重叠声明在案），回滚可精确撤销；
--   * 全唐詩隋宮恰六处四卷+《隋宮守歲》在册零入引（audit 硬卡零混入）；
--   * KNOWN 零如实记录（第廿三例，audit 反向断言 SQL 无 KNOWN 字面量）；
--   * V066「绹不之省/坎壈终身」、V016 诸在册句只对照不重开。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 66，不含 67
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-022-%';             -- 空
--   SELECT id FROM poetry_source WHERE id IN ('source-ws-t300-022','source-quantangshi-539');  -- 只含 539
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-022-ws';  -- 恰 4
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-022-%';       -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-022';                                  -- 4（1/1/1/1）
--   SELECT certainty FROM poetry_claim WHERE id LIKE 'claim-bg-022-%';  -- 四行全 LIKELY（有意全 LIKELY）
--   SELECT COUNT(*) FROM poetry_source WHERE id='source-ws-t300-022';   -- 恰 1（本迁移新建）
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-022'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-022';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-022-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
-- 回滚: recovery/V067_rollback.sql（按 id 全枚举删除；source 只删本迁移新建的
--   source-ws-t300-022 一行——source-quantangshi-539 系 V018 所立绝不删）
START TRANSACTION;

-- ---------- 0. 新 source 恰一枚（source-ws-t300-022 选本页；PENDING 照 V066 判例） ----------
INSERT INTO poetry_source (id, title, author, edition, url, rights_note, verification_status, source_kind, reliability)
SELECT * FROM (
SELECT 'source-ws-t300-022' AS id, '维基文库《唐詩三百首》页面：隋宮 (乘興南遊不戒嚴)' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/隋宮_(乘興南遊不戒嚴)' AS url, '维基文库录入本，公有领域古籍。本行由 emit_v067.py 对 /tmp/src-dl 快照逐字定位。本诗 V018 立正文时用的是《全唐詩》卷539 卷页（source-quantangshi-539，version_code vol-raw），此《唐詩三百首》选本页当时未建源——卷页与诗页是两个独立见证面（卷页同题双块锚点归属 vs 选本页 header/notes/分类），本迁移引诗页非新源不能承载（V066 source-ws-t300-031 判例同构）。页题带首句消歧「隋宮 (乘興南遊不戒嚴)」；title 行内嵌 {{*|一雲隋堤}} 异注；poem 块四句全无句读（与《賈生》页有标点并存）；notes 挂诗体俗名「七绝」；无 Textquality 评级。核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status, 'POETRY_COLLECTION' AS source_kind, 'HIGH' AS reliability FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_source x WHERE x.id = t.id);

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-022-scene' AS id, 'BACKGROUND' AS entity_type, '022-scene' AS slug, '眼前：一场没有刹车的巡幸' AS title, '四层处境背景（阶段 D 第 48 首·四句七绝 1/1/1/1 第四次）；史实句均有逐字引证；系年第四十二次判决（题证系列第卅状·隋宫与谏书）「诗题隋宮在史部全零，亡隋只在谏臣嘴里；诗的谏书函九重不省，史的谏书从叛家开箱反得赏」——同字两界第十二形态·亡国形态首见：通鉴隋宮/南遊/不戒嚴/乘興/宮錦/障泥/紫泉/螢火/垂楊/迷樓/錦帆/隋堤/日角/省諫全零；亡隋恰二闭域双窗口入引（貞觀四年庚寅六三〇「襲亡隋之弊恐又甚於煬帝」+貞觀十二年戊戌六三八「亡隋之弊俗」——谏臣的镜子对锦帆的现场）；諫書恰一闭域窗口入引（貞觀十七年癸卯六四三开箱得孫處約諫書累遷中書舍人——一函不省/一函得赏）；行留恰一入引（貞觀元年丁亥六二七「煬帝將幸江都……獨言不可臣親見之」——亲历者的声音）；戒嚴恰十处七卷闭域在册零入引（诗只咬否定式「不戒嚴」——万乘之防对乘兴之君）；後庭花恰一在册；卷539「==[[隋宮]]==」恰二=**同卷同题双块两锚皆裸名（消歧判例反例首见——有同名锚仍裸名，辨异靠孤挂 {{*|一云隋堤}} 云注）**；ws 层同名两页首句消歧（卷页裸名/诗页消歧分层形态首见）+异注简繁两层（一云/一雲隋堤）；ws 页 poem 块**全无句读**（与《賈生》页有标点并存——同一选本两种转录形态首见）+title 行内嵌异注首见+notes 挂俗名「七绝」首见+无评级页第二见+分类三行简繁混排第二见；**再新建 source-ws-t300-022 恰一枚（连续第二首开新源 145→146——卷页/诗页两个独立见证面，V066 判例同构；audit 断言恰一枚新源 INSERT）**；全唐詩隋宮恰六处四卷闭域+卷540《隋宮守歲》锚恰一（第三面）在册零入引；正文第二引上限用满第十五例（V018 在先+双针恰一，两引面不重叠）；PERSON 旧传简化段再首引二句（弱冠干文+下笔不能自休——干谒门开/谏诤门闭读法声明；V066 绹不之省/坎壈终身零重开）；旧传段隋/煬/九重/諫/戒嚴/揚州/江都全零；KNOWN 零如实记录（第廿三例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-022-city' AS id, 'BACKGROUND' AS entity_type, '022-city' AS slug, '这座城：同卷两见的双隋宮' AS title, '四层处境背景（阶段 D 第 48 首·四句七绝 1/1/1/1 第四次）；史实句均有逐字引证；系年第四十二次判决（题证系列第卅状·隋宫与谏书）「诗题隋宮在史部全零，亡隋只在谏臣嘴里；诗的谏书函九重不省，史的谏书从叛家开箱反得赏」——同字两界第十二形态·亡国形态首见：通鉴隋宮/南遊/不戒嚴/乘興/宮錦/障泥/紫泉/螢火/垂楊/迷樓/錦帆/隋堤/日角/省諫全零；亡隋恰二闭域双窗口入引（貞觀四年庚寅六三〇「襲亡隋之弊恐又甚於煬帝」+貞觀十二年戊戌六三八「亡隋之弊俗」——谏臣的镜子对锦帆的现场）；諫書恰一闭域窗口入引（貞觀十七年癸卯六四三开箱得孫處約諫書累遷中書舍人——一函不省/一函得赏）；行留恰一入引（貞觀元年丁亥六二七「煬帝將幸江都……獨言不可臣親見之」——亲历者的声音）；戒嚴恰十处七卷闭域在册零入引（诗只咬否定式「不戒嚴」——万乘之防对乘兴之君）；後庭花恰一在册；卷539「==[[隋宮]]==」恰二=**同卷同题双块两锚皆裸名（消歧判例反例首见——有同名锚仍裸名，辨异靠孤挂 {{*|一云隋堤}} 云注）**；ws 层同名两页首句消歧（卷页裸名/诗页消歧分层形态首见）+异注简繁两层（一云/一雲隋堤）；ws 页 poem 块**全无句读**（与《賈生》页有标点并存——同一选本两种转录形态首见）+title 行内嵌异注首见+notes 挂俗名「七绝」首见+无评级页第二见+分类三行简繁混排第二见；**再新建 source-ws-t300-022 恰一枚（连续第二首开新源 145→146——卷页/诗页两个独立见证面，V066 判例同构；audit 断言恰一枚新源 INSERT）**；全唐詩隋宮恰六处四卷闭域+卷540《隋宮守歲》锚恰一（第三面）在册零入引；正文第二引上限用满第十五例（V018 在先+双针恰一，两引面不重叠）；PERSON 旧传简化段再首引二句（弱冠干文+下笔不能自休——干谒门开/谏诤门闭读法声明；V066 绹不之省/坎壈终身零重开）；旧传段隋/煬/九重/諫/戒嚴/揚州/江都全零；KNOWN 零如实记录（第廿三例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-022-world' AS id, 'BACKGROUND' AS entity_type, '022-world' AS slug, '这个天下：亡隋在谏臣嘴里' AS title, '四层处境背景（阶段 D 第 48 首·四句七绝 1/1/1/1 第四次）；史实句均有逐字引证；系年第四十二次判决（题证系列第卅状·隋宫与谏书）「诗题隋宮在史部全零，亡隋只在谏臣嘴里；诗的谏书函九重不省，史的谏书从叛家开箱反得赏」——同字两界第十二形态·亡国形态首见：通鉴隋宮/南遊/不戒嚴/乘興/宮錦/障泥/紫泉/螢火/垂楊/迷樓/錦帆/隋堤/日角/省諫全零；亡隋恰二闭域双窗口入引（貞觀四年庚寅六三〇「襲亡隋之弊恐又甚於煬帝」+貞觀十二年戊戌六三八「亡隋之弊俗」——谏臣的镜子对锦帆的现场）；諫書恰一闭域窗口入引（貞觀十七年癸卯六四三开箱得孫處約諫書累遷中書舍人——一函不省/一函得赏）；行留恰一入引（貞觀元年丁亥六二七「煬帝將幸江都……獨言不可臣親見之」——亲历者的声音）；戒嚴恰十处七卷闭域在册零入引（诗只咬否定式「不戒嚴」——万乘之防对乘兴之君）；後庭花恰一在册；卷539「==[[隋宮]]==」恰二=**同卷同题双块两锚皆裸名（消歧判例反例首见——有同名锚仍裸名，辨异靠孤挂 {{*|一云隋堤}} 云注）**；ws 层同名两页首句消歧（卷页裸名/诗页消歧分层形态首见）+异注简繁两层（一云/一雲隋堤）；ws 页 poem 块**全无句读**（与《賈生》页有标点并存——同一选本两种转录形态首见）+title 行内嵌异注首见+notes 挂俗名「七绝」首见+无评级页第二见+分类三行简繁混排第二见；**再新建 source-ws-t300-022 恰一枚（连续第二首开新源 145→146——卷页/诗页两个独立见证面，V066 判例同构；audit 断言恰一枚新源 INSERT）**；全唐詩隋宮恰六处四卷闭域+卷540《隋宮守歲》锚恰一（第三面）在册零入引；正文第二引上限用满第十五例（V018 在先+双针恰一，两引面不重叠）；PERSON 旧传简化段再首引二句（弱冠干文+下笔不能自休——干谒门开/谏诤门闭读法声明；V066 绹不之省/坎壈终身零重开）；旧传段隋/煬/九重/諫/戒嚴/揚州/江都全零；KNOWN 零如实记录（第廿三例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-022-person' AS id, 'BACKGROUND' AS entity_type, '022-person' AS slug, '这个人：下笔不能自休的手' AS title, '四层处境背景（阶段 D 第 48 首·四句七绝 1/1/1/1 第四次）；史实句均有逐字引证；系年第四十二次判决（题证系列第卅状·隋宫与谏书）「诗题隋宮在史部全零，亡隋只在谏臣嘴里；诗的谏书函九重不省，史的谏书从叛家开箱反得赏」——同字两界第十二形态·亡国形态首见：通鉴隋宮/南遊/不戒嚴/乘興/宮錦/障泥/紫泉/螢火/垂楊/迷樓/錦帆/隋堤/日角/省諫全零；亡隋恰二闭域双窗口入引（貞觀四年庚寅六三〇「襲亡隋之弊恐又甚於煬帝」+貞觀十二年戊戌六三八「亡隋之弊俗」——谏臣的镜子对锦帆的现场）；諫書恰一闭域窗口入引（貞觀十七年癸卯六四三开箱得孫處約諫書累遷中書舍人——一函不省/一函得赏）；行留恰一入引（貞觀元年丁亥六二七「煬帝將幸江都……獨言不可臣親見之」——亲历者的声音）；戒嚴恰十处七卷闭域在册零入引（诗只咬否定式「不戒嚴」——万乘之防对乘兴之君）；後庭花恰一在册；卷539「==[[隋宮]]==」恰二=**同卷同题双块两锚皆裸名（消歧判例反例首见——有同名锚仍裸名，辨异靠孤挂 {{*|一云隋堤}} 云注）**；ws 层同名两页首句消歧（卷页裸名/诗页消歧分层形态首见）+异注简繁两层（一云/一雲隋堤）；ws 页 poem 块**全无句读**（与《賈生》页有标点并存——同一选本两种转录形态首见）+title 行内嵌异注首见+notes 挂俗名「七绝」首见+无评级页第二见+分类三行简繁混排第二见；**再新建 source-ws-t300-022 恰一枚（连续第二首开新源 145→146——卷页/诗页两个独立见证面，V066 判例同构；audit 断言恰一枚新源 INSERT）**；全唐詩隋宮恰六处四卷闭域+卷540《隋宮守歲》锚恰一（第三面）在册零入引；正文第二引上限用满第十五例（V018 在先+双针恰一，两引面不重叠）；PERSON 旧传简化段再首引二句（弱冠干文+下笔不能自休——干谒门开/谏诤门闭读法声明；V066 绹不之省/坎壈终身零重开）；旧传段隋/煬/九重/諫/戒嚴/揚州/江都全零；KNOWN 零如实记录（第廿三例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-022-scene' AS id, 'bg-022-scene' AS subject_id, 'context' AS property_key, '四句七绝本文（ws 选本页 poem 块四句**全无句读**——与《賈生》页有标点并存，同一选本两种转录形态首见，各从其录）；title 行内嵌 {{*|一雲隋堤}} 异注（异注进 title 行首见）；{{另}}/{{別}}/<ref> 全零；页内 Vtext/poem 双转录并存首末句各恰 2；全句**第二引**：正文 V018 卷539 卷页 claim 一引在先（生成时全库查重双针「乘興南遊不戒嚴」「半作障泥半作帆」各恰一处），本迁移引 ws 诗页——两引两面（卷页+诗页）上限恰满不重叠；两度上限至此用满、此诗正文对后来迁移关闭（audit 硬卡）。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-022-city' AS id, 'bg-022-city' AS subject_id, 'context' AS property_key, '卷539「==[[隋宮]]==」恰二闭域（机器断言）=同卷同题双块：紫泉七律块+本篇七绝块（后块孤挂「{{*|一云隋堤}}」简体异注行恰一）——**同名两见两锚皆裸名：消歧判例反例首见**（无同名则无消歧器诸判例之反面；辨异全靠孤挂云注）；ws 层同名两页各首句消歧（本页页题「隋宮 (乘興南遊不戒嚴)」）——卷页裸名/诗页消歧分层消歧形态首见；异注同案两层（卷页简体「一云隋堤」/ws 页繁体「一雲隋堤」）照登；notes「{{唐詩三百首}}七绝」选本标记挂俗名首见；无评级页第二见；分类三行简繁混排第二见（分类行非史料声明+不升格，V048 判例）；全唐詩「隋宮」恰六处四卷闭域+卷540《隋宮守歲》锚恰一（「隋宮」第三面，档扫在册零入引）；**再新建 source-ws-t300-022 恰一枚（连续第二首开新源——V018 以卷页立诗、ws 选本页从未建源，卷页/诗页两个独立见证面，V066 判例同构；audit 断言恰一枚新源 INSERT）**。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-022-world' AS id, 'bg-022-world' AS subject_id, 'context' AS property_key, '通鉴「隋宮/南遊/不戒嚴/乘興/宮錦/障泥/紫泉/螢火/垂楊/迷樓/錦帆/隋堤/日角/省諫」全零（诗面亡国现场不在史部，机器断言）；「亡隋」恰二闭域双窗口逐字入引=貞觀四年（庚寅，六三〇）「襲亡隋之弊，恐又甚於煬帝」谏+貞觀十二年（戊戌，六三八）「亡隋之弊俗」责（史部亡隋=谏臣的镜子，诗隋宮=锦帆的现场——同字两界第十二形态·亡国形态首见，audit 硬卡）；「諫書」恰一闭域窗口入引=貞觀十七年（癸卯，六四三）开箱得孫處約諫書累遷中書舍人（一函不省/一函得赏）；「行留」恰一闭域窗口入引=貞觀元年（丁亥，六二七）「煬帝將幸江都……獨言不可。臣親見之」（亲历者的声音）；「戒嚴」恰十处七卷闭域在册零入引（诗咬否定式「不戒嚴」——万乘之防对乘兴之君）；「後庭花」恰一在册零入引；certainty 不覆盖任何系年，诗 time.span/event.name/written_during 零铸造零 relation（audit 硬卡）。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-022-person' AS id, 'bg-022-person' AS subject_id, 'context' AS property_key, '旧传李商隐段（简化字录入，引文照登简体原样）再首引二句皆生成时全库查重域恰零=「商隐幼能为文。令狐楚镇河阳，以所业文干之，年才及弱冠。」+「博学强记，下笔不能自休，尤善为诔奠之辞。」（传区间归属机器断言）；「谏书两界，人身为证：干谒之门开/谏诤之门闭」系读法声明；V066 已引「绹不之省」「名宦不进，坎壈终身」零重开（域恰 [V066] 断言）；字义山/开成二年/岭表/三十六体诸在册句（V016）零重开；旧传李商隐段隋/煬/九重/諫/戒嚴/揚州/江都全零（机器断言）；本诗无底注（无注可登）；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-022-scene' AS subject_id, 'context' AS property_key, 'claim-bg-022-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-022-city' AS subject_id, 'context' AS property_key, 'claim-bg-022-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-022-world' AS subject_id, 'context' AS property_key, 'claim-bg-022-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-022-person' AS subject_id, 'context' AS property_key, 'claim-bg-022-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-022-scene' AS id, 'work-t300-022' AS work_id, 'SCENE' AS layer, '四句是一次没有刹车的人间巡幸：乘兴南游，连戒严都不要（「乘興南遊不戒嚴」）——皇帝尽兴出发，警卫仪程一概从简；九重宫门里，谁省得谏书的封皮（「九重誰省諫書函」）；春风里全国裁下来的宫锦，一半做了障泥、一半做了帆（「春風舉國裁宮錦，半作障泥半作帆」）——锦缎不是穿在人身上，是垫在马蹄下、挂在船帆上。ws 诗页 poem 块**四句全无句读**（对照 V066《賈生》页 poem 有标点——**同一《唐詩三百首》选本两种转录形态并存首见**，各从其录照登）；title 行内嵌 {{*|一雲隋堤}} 异注——**异注进 title 行首见**；{{另}}/{{別}}/<ref> 全零；页内 Vtext/poem 双转录并存（首末句页内各恰 2）。此诗正文系**第二引**：V018 卷539 卷页一引在先，本迁移引 ws 选本页——**两引两面（卷页+诗页），上限恰满而不重叠**；生成时全库查重双针各恰一处，两度上限至此用满，此诗正文对后来迁移关闭。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-022-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-022-city' AS id, 'work-t300-022' AS work_id, 'CITY' AS layer, '卷539 侧：**同卷同题双《隋宮》**——「==[[隋宮]]==」恰二（机器断言闭域）：前块「紫泉宮殿鎖煙霞　欲取蕪城作帝家……」七律（全唐诗名篇而不入三百首），后块本篇七绝，锚下**孤挂「{{*|一云隋堤}}」异注行**——**同名两见两锚皆裸名：消歧判例反例首见**（V059「无同名则无消歧器」、V062/V063/V065 裸名锚诸判例的反面：**有同名，锚仍裸名**——辨异全靠第二块孤挂的一行云注；裸名锚不能自我消歧，本卷同名只靠异注与选本各立一页分家）。ws 层同名两页各以首句消歧（本页页题「隋宮 (乘興南遊不戒嚴)」）——**卷页裸名/诗页消歧的分层消歧形态首见**；异注同案两层照登：卷页简体「一云隋堤」vs ws 页繁体「一雲隋堤」。ws 页 notes「{{唐詩三百首}}七绝」——**选本标记后挂诗体俗名「七绝」（非「七言絕句」正名）首见**；无 Textquality 评级第二见（V066 首见）；分类三行简繁混排第二见（整理者分类：非史料声明、不升格，V048 判例）。**本迁移再新建 1 个 source（source-ws-t300-022）**——连续第二首开新源：V018 以卷539 卷页立本诗（source-quantangshi-539，vol-raw），ws 选本页从未建源——卷页与诗页两个独立见证面（V066 判例同构）。全唐詩「隋宮」恰六处四卷闭域（283/525 他人同题在册零入引）+卷540《隋宮守歲》锚恰一（「隋宮」二字第三面，档扫闭域）。（本层零 relation。）' AS body_text, 'JUNIOR' AS audience, 'claim-bg-022-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-022-world' AS id, 'work-t300-022' AS work_id, 'WORLD' AS layer, '**诗题隋宮在史部全零，亡隋只在谏臣嘴里**（同字两界第十二形态·亡国形态首见）：通鉴「隋宮/南遊/不戒嚴/乘興/宮錦/障泥/紫泉/螢火/垂楊/迷樓/錦帆/隋堤/日角/省諫」全零（机器断言——锦帆未断的亡国现场整个不在史部）；「**亡隋**」恰二（闭域+双窗口逐字入引）：貞觀四年（庚寅，六三〇）「**陛下役瘡痍之人，襲亡隋之弊，恐又甚於煬帝矣！**」（洛阳宫营缮之谏）、貞觀十二年（戊戌，六三八）「**卿所為乃亡隋之弊俗也。**」（长春宫供进之责）——**史部的亡隋是谏臣手里的镜子，诗的隋宮是锦帆底下的现场**；「**諫書**」通鉴恰一处（闭域+窗口入引）——貞觀十七年（癸卯，六四三）齐王祐乱平，「**上檢祐家文疏，得記室郟城孫處約諫書，嗟賞之，累遷中書舍人。**」——**诗「九重誰省諫書函」写给不见省的九重；史部唯一进账的谏书是皇帝从叛臣箱底翻出来的，人还因此升了官：一函不省，一函得赏**；「行留」恰一处入引——貞觀元年（丁亥，六二七）邸怀道对太宗「**煬帝將幸江都，召百官問行留之計，懷道為吏部主事，獨言不可。臣親見之。**」：**幸江都当时真有人言不可，且亲历者二十年后在朝堂上讲给太宗听——通鉴留的是亲历者的声音**；「戒嚴」恰十处七卷闭域（全库扫描在册零入引）——**诗偏偏只咬这词的否定式「不戒嚴」：史部戒嚴是万乘之防，诗不戒嚴是乘兴之君**。「後庭花」通鉴恰一在册零入引。本层零铸造零 relation。' AS body_text, 'SENIOR' AS audience, 'claim-bg-022-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-022-person' AS id, 'work-t300-022' AS work_id, 'PERSON' AS layer, '旧传李商隐段（**简化字录入**，V016 locator 已注，引文照登简体原样）再首引二句（皆生成时全库查重域恰零）：「**商隐幼能为文。令狐楚镇河阳，以所业文干之，年才及弱冠。**」「**博学强记，下笔不能自休，尤善为诔奠之辞。**」
**谏书两界，人身为证**（读法声明，非史实）：诗里「九重誰省諫書函」——谏书进了宫门没人省；传里这个人弱冠之年「以所业文干」令狐楚，当场得礼遇——**同样的文字，干谒之门开，谏诤之门闭**；「下笔不能自休」的手，写进宫门的就是「誰省」二字。
V066 已引段内二句「绹不之省」「名宦不进，坎壈终身」零重开（域恰 [V066] 生成时断言）；字义山/开成二年/岭表/三十六体（V016）在册句零重开；**旧传李商隐段隋/煬/九重/諫/戒嚴/揚州/江都全零**（机器断言——写下「隋宮」定谳的人，传里没有一个隋字）；certainty 不覆盖任何系年，本诗无底注（无注可登），诗 time.span/event.name/written_during 仍零铸造（audit 硬卡）。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-022-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-022-scene' AS claim_id, 'source-ws-t300-022' AS source_id, '页面 隋宮 (乘興南遊不戒嚴)（《唐詩三百首》第 22 首选本页，页题带首句消歧；title+author+notes+poem 块四句——poem **全无句读**（与《賈生》页有标点并存，同一选本两种转录形态首见）；title 行内嵌 {{*|一雲隋堤}}（异注进 title 行首见）；全句**第二引**：V018 卷539 卷页一引在先——两引面不重叠，上限恰满，生成时全库查重双针恰一处，此后此诗正文关闭；{{另}}/{{別}}/<ref> 全零；页内 Vtext/poem 双转录并存各从其录）' AS locator, '| title    = 隋宮{{*|一雲隋堤}}……| author   = 李商隱……| notes    = {{唐詩三百首}}七绝……乘興南遊不戒嚴
九重誰省諫書函
春風舉國裁宮錦
半作障泥半作帆
</poem>' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-022-city' AS claim_id, 'source-quantangshi-539' AS source_id, '卷五百三十九·李商隱同题双《隋宮》块（**「==[[隋宮]]==」恰二机器断言**：前块紫泉七律锚+首联……后块本篇七绝锚+孤挂「{{*|一云隋堤}}」异注行+poem 四句——同名两见两锚皆裸名（消歧判例反例首见）；后块异注简体照登；源行系 V018 已立、本迁移复用零新建）' AS locator, '==[[隋宮]]==
<poem>
紫泉宮殿鎖煙霞　欲取蕪城作帝家……==[[隋宮]]==
{{*|一云隋堤}}
<poem>
乘興南遊不戒嚴　九重誰省諫書函
春風舉國裁宮錦　半作障泥半作帆
</poem>' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-022-city' AS claim_id, 'source-ws-t300-022' AS source_id, '页面 隋宮 (乘興南遊不戒嚴)（header title 整行（内嵌 {{*|一雲隋堤}} 繁体异注，与卷页简体「一云隋堤」同案两层照登）+整页 notes 行（{{唐詩三百首}}后挂诗体俗名「七绝」首见；无 Textquality 评级第二见）+分类三行连片（简体「唐诗」与繁体「唐詩三百首」同页混排第二见）；分类行与页题消歧系整理者/编排动作：非史料声明、不升格）' AS locator, '| title    = 隋宮{{*|一雲隋堤}}……| notes    = {{唐詩三百首}}七绝……[[Category:李商隱]]
[[Category:唐诗]]
[[Category:唐詩三百首|李]]' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-022-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '卷一百九十二·貞觀元年（丁亥，六二七）邸怀道对（煬帝將幸江都行留之议——独言不可+臣親見之）……卷一百九十三·貞觀四年（庚寅，六三〇）洛阳宫营缮谏段……卷一百九十五·貞觀十二年（戊戌，六三八）长春宫供进之责段……卷一百九十六·貞觀十七年（癸卯，六四三）齊王祐亂平开箱得孫處約諫書段（**通鉴隋宮/南遊/不戒嚴/乘興/宮錦/障泥全零、亡隋恰二、諫書/行留/幸江都各恰一、戒嚴恰十七卷闭域**：文件闭域+四处年标题窗口机器断言——亡隋只在谏臣嘴里；一函不省/一函得赏；四段史文逐字入引为判决证据；全唐詩在册句零入引）' AS locator, '煬帝將幸江都，召百官問行留之計，懷道為吏部主事，獨言不可。臣親見之。……陛下役瘡痍之人，襲亡隋之弊，恐又甚於煬帝矣！……卿所為乃亡隋之弊俗也。……上檢祐家文疏，得記室郟城孫處約諫書，嗟賞之，累遷中書舍人。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-022-person' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書卷一九〇下·李商隱（**简化字录入**照登原样，V016 locator 同款标注）（「商隐幼能为文……年才及弱冠」句+「博学强记……诔奠之辞」句——皆全库查重恰零域首引；传区间归属机器断言；「干谒之门开/谏诤之门闭」系读法声明；V066 已引「绹不之省/坎壈终身」句与字义山/岭表/三十六体诸在册句零重开）' AS locator, '商隐幼能为文。令狐楚镇河阳，以所业文干之，年才及弱冠。……博学强记，下笔不能自休，尤善为诔奠之辞。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（四句七绝 1/1/1/1 第四次） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-022-scene' AS background_id, 'text-work-t300-022-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-022-city' AS background_id, 'text-work-t300-022-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-022-world' AS background_id, 'text-work-t300-022-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-022-person' AS background_id, 'text-work-t300-022-ws' AS version_id, 4 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 67, 'Li Shang-yin''s Sui Palace (work-t300-022) background layers (stage-D poem 48, four-line jueju 1/1/1/1 fourth time): dating verdict forty-two, thirtieth shape of the title-evidence series -- the Sui Palace and the remonstrance letter, the fallen dynasty split in two realms: the poem''s title-word Sui-gong scores zero across the Tongjian (machine-asserted, with nan-you, bu-jieyan, chengxing, gongjin, zhangni, zi-quan, yinghuo, chuiyang, milou, jinfan, sui-di, ri-jiao, sheng-jian all zero); yet wang-sui (fallen Sui) appears exactly twice, both as a mirror in the mouths of remonstrators: "your subjecting of the scarred people, following the abuses of the fallen Sui, perhaps surpasses even Emperor Yang" (Zhenguan 4th, gengyin, 630, over rebuilding the Luoyang palace) and "what you do is the corrupt custom of the fallen Sui" (Zhenguan 12th, wuxu, 638) -- the histories'' fallen Sui is a warning-mirror, the poem''s Sui Palace is the scene under silk sails (twelfth same-character split, first fallen-dynasty shape); jian-shu (remonstrance letter) appears exactly once -- after the Prince of Qi''s revolt was quelled the emperor opened the rebel''s papers, found remonstrance letters of his secretary Sun Chuoyue, praised them, and Sun was promoted to Zhongshu Sheren (Zhenguan 17th, guimao, 643): the poem''s letter reaches the nine gates that never glance at it, the histories'' only recorded letter is dug from a traitor''s chest and its author rewarded -- one letter ignored, one letter rewarded; xing-liu (go or stay) exactly once -- Wei Zheng-era Di Huaidao telling Taizong: when Emperor Yang was about to visit Jiang-du he summoned officials to debate go or stay, and only one said no, "your servant saw it himself" (Zhenguan 1st, dinghai, 627) -- the histories keep an eyewitness voice; jie-yan (martial lockdown) appears ten times in seven scroll-volumes, all institutional guard-duty, zero quoted -- the poem bites only its negation bu-jieyan: histories'' lockdown is the ten-thousand-chariot defense, poem''s no-lockdown is a pleasure-bound ruler; juan 539 holds TWO same-titled Sui Palace blocks (closed-domain assert): the zi-quan seven-regulated and this jueju, BOTH anchors bare ==[[隋宮]]== -- the anti-case of the disambiguation precedents (first seen: same-name blocks, still bare anchors; differentiation rests on one orphan variant-note line {{*|一云隋堤}}); at the ws layer the two same-titled anthology pages each disambiguate by first line -- layered disambiguation (bare at scroll level, disambiguated at page level) first seen; the variant note itself logged in two scripts (simplified scroll page vs traditional ws title line {{*|一雲隋堤}} -- a variant note inside a title line, first seen); the ws poem block carries NO punctuation at all (contrast the Jia-sheng page which does -- two transcription styles inside one anthology, first seen) and notes append the colloquial form-name 七绝 (first seen) with no Textquality grade (second time) and three category rows mixing scripts (second time); exactly ONE new poetry_source row (source-ws-t300-022), the second consecutive new source (V066 pattern: scroll page and anthology page are two independent witnesses); body quotes hit their two-use ceiling (fifteenth instance; twin needles; witnesses never overlap); PERSON first-cites two more zero-domain sentences from the simplified JTS biography -- at twenty he visited Linghu Chu with his compositions, and "his brush could not stop itself" -- the same hand, one door open for poems, one door shut for remonstrance (reading declared); V066''s two quoted sentences stay closed (domain exactly V066 asserted); the biography segment holds no Sui/Yang/jiu-chong/jian/jie-yan/Yang-zhou/Jiang-du character (machine-asserted); KNOWN zero honestly recorded (twenty-third instance, audit reverse-asserts); closed precedent keywords stay out of citations'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 67);
COMMIT;
