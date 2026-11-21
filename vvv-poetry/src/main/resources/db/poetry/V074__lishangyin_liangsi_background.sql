-- V074：李商隱《涼思》(work-t300-032) 四层背景（阶段 D 第 55 首·寄远两界）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V014、V015、V016、V018、V026、V033、V035、V039、V048、V053、V057、
--       V058、V059、V060、V061、V062、V063、V064、V065、V066、V067、V068、V069、V070、
--       V071、V072、V073 已执行
--       （work-t300-032 与其 text-work-t300-032-ws（version_code=vol-raw——V018 立此诗正文
--       用的是卷540 卷页面，八行带句读，与本快照 ws 诗页 poem 块逐字同面零分歧——跨源零分歧
--       面首见）与其源 source-quantangshi-540（V018 已立的卷540 卷页源，V018/V066 已引，
--       本迁移第三次复用）都是 V018 的行；**source-ws-t300-032 是本迁移新建的选本页源**
--       （V066 賈生判例同款：卷页与诗页是两个独立见证面，引诗页非新源不能承载）；
--       source-zizhi-tongjian-events 是 V014/V015 已立的通鉴事件源；
--       source-jiutangshu-wenyuan 是 V016 已立的旧唐书文苑传源（李商隐传在此，简化字录入）；
--       判例在册句（义山/开成二年/岭表/三十六体/未几病卒/大中末/仲郢坐/还郑州 V016、
--       绹不之省/坎壈终身/令狐绹作相 V066/V067、以所业文干之/下笔不能自休 V067、恃才诡激/
--       为当涂者所薄 V068、俄而茂元卒/检校水部员外郎 V070、文思清丽/庭筠过之 V072、
--       复以文章干襜/府罢入朝 V073、北斗七星高（西鄙人）/憐君何事到天涯（賈誼宅）/
--       客去波平檻句读式全引 V018）只对照不重开。
--       **本迁移新建 source 恰一枚（零新源连续五首在此正当终结）——
--       audit 断言本文件恰一枚 poetry_source INSERT（source-ws-t300-032）、回滚恰删此一枚。**
--
-- 数据源（可复现）：emit_v074.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/涼思.txt（五成页第二次+零标记页（正交第二枚标本）+VH1 模板锚（全库恰22页闭域）+
--   Vtext 裸/poem 句读双转录分工第三次+notes 二连无↑（排序谱再补一态）+分类四行含詠懷詩
--   （全库恰三页闭域）+无 times/type/from/无 {{clr}}/无↑）、
--   全唐詩卷540（旧式裸名锚「==涼思==」全库唯一+八句正文内联（与 V072/V073 空壳转引成两极）+
--   江上块与涼思块直接相接恰一+涼思块与鸞鳳块直接相接恰一（卷页并置第二次在场））、
--   舊唐書卷190下（李商隐段首引一段+段内寄面题字三十一项全零+思恰一恰在文思清丽+段边界断言）、
--   通鑑卷212/221/253/246（三远四段逐字入引+年标题窗口：開元十二年七二四/上元元年七六〇/
--   乾符五年八七八/會昌二年八四二）+
--   通鑑 75 卷负证计数扫描（北斗恰一+南北斗/祭南北斗恰一+南陵恰二闭域221/253+天涯恰一+
--   占夢/數夢/新知/涼思/波平/露滿/蟬休/倚立/永懷/寓使/客去/疑誤全零）+
--   既有迁移引文域逐句查重——传区间归属、二引/零重开/首引零域前提全部生成时断言。
--
-- 做：4 BACKGROUND content/claim/background + 5 组逐字引用（(claim,source) 主键每对恰一行）+
--   8 background_line（八句五律 **2/2/2/2 顺次**：scene→1,2 city→3,4 world→5,6 person→7,8，
--   绑 text-work-t300-032-ws 的 8 行）+ 1 枚新建 source（source-ws-t300-032）+
--   不碰 poetry_text_line。
-- 不做：**不新建第二枚 source**；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「诗的三处远，通鉴各有一本账，没有一本是寄信的」）：
--   * 「三远两界」「寄远形态首见」系通鉴四段逐字入引支撑的对照判决，非史实因果——通鉴不记这首诗；
--     亦不考本诗系年（编年诸说一律不采信不铸造）；
--   * 「江上吾道豈淹留压在南陵寓迟头上」「寄远的人没有信」标明读法声明；
--   * 開元十二年北斗案主角是王皇后/王守一/僧明悟，与诗作者无涉——只作两界对照不作因果；
--   * 正文第二引上限用满：V018 句读式一引在先，本迁移引 ws 页 poem 块存原样面——
--     同面各从其录，V018 句读式引文不重开（生成时硬断言），此后此诗正文关闭；
--   * 「旧式裸锚内联」「卷页并置」「五成第二次」「VH1 22页闭域」均照登不判；
--   * 分类四行与詠懷詩类目系整理者动作：非史料声明、不升格，V048 判例；
--   * KNOWN 零如实记录（第卅例，audit 反向断言 SQL 无 KNOWN 字面量）；
--   * V011/V016/V018/V026/V033/V035/V039/V053/V063/V066–V073 已引诸句只对照不重开。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 73，不含 74
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-032-%';             -- 空
--   SELECT id FROM poetry_source WHERE id IN ('source-ws-t300-032','source-quantangshi-540');
--    -- 一行（540 系 V018 所立；ws 页源本迁移新建）
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-032-ws';  -- 恰 8
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-032-%';       -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-032';                                  -- 8（2/2/2/2）
--   SELECT certainty FROM poetry_claim WHERE id LIKE 'claim-bg-032-%';  -- 四行全 LIKELY
--   SELECT COUNT(*) FROM poetry_source WHERE id='source-ws-t300-032';   -- 恰 1（本迁移所立）
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-032'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-032';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-032-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
-- 回滚: recovery/V074_rollback.sql（按 id 全枚举删除；**source 只删一行**——
--   source-ws-t300-032 是本迁移新建的选本页源（恰一枚，审计断言）按 id 删除；
--   source-quantangshi-540 是 V018 所立的卷540 卷页源（本迁移复用），绝不删；
--   work-t300-032 本体与其 text_line 8 行都是 V018 的行，绝不删）
START TRANSACTION;

-- ---------- 0. 新建选本页源一枚（V066 賈生判例同款） ----------
INSERT INTO poetry_source (id, title, author, edition, url, rights_note, verification_status, source_kind, reliability)
SELECT * FROM (
SELECT 'source-ws-t300-032' AS id, '维基文库《唐詩三百首》页面：涼思' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/涼思' AS url, '维基文库录入本，公有领域古籍。本行由 emit_v074.py 对 /tmp/src-dl 快照逐字定位。本诗 V018 立正文时用的是《全唐詩》卷540 卷页（source-quantangshi-540，version_code vol-raw），此《唐詩三百首》选本页当时未建源——卷页与诗页是两个独立见证面（卷页锚点归属 vs 选本页 header 署名/底注/分类），本迁移引诗页非新源不能承载。页面 {{Textquality|50%}} 五成评级+零异文标记（正交标本）；页内 Vtext/poem 双转录并存（Vtext 全裸/poem 句读）；notes 二连无底本回指；分类四行含简体「唐诗」与繁体「唐詩三百首」同页混排+「詠懷詩」类目（照登）。核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status, 'POETRY_COLLECTION' AS source_kind, 'HIGH' AS reliability FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_source x WHERE x.id = t.id);

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-032-scene' AS id, 'BACKGROUND' AS entity_type, '032-scene' AS slug, '眼前：客去之后，声停之夜' AS title, '四层处境背景（阶段 D 第 55 首·八句五律 2/2/2/2）；史实句均有逐字引证；系年第四十九次判决（题证系列第卅七状·三远各有账寄信无账）「诗的三处远，通鉴里各有一本账，没有一本是寄信的」——同字两界第十九形态·寄远形态首见：北斗恰一（開元十二年祭南北斗咒）/南陵恰二（屯兵/败军）/天涯恰一（回鹘坟墓）闭域入引；占夢/新知/涼思全零；跨源零分歧面首见（选本页≡卷页八行逐字同面，双向断言）+五成页第二次+零标记正交第二枚；旧式裸锚+正文内联（与空壳转引成两极）；卷页并置第二次在场（江上「吾道豈淹留」压「南陵寓迟」头上——读法声明）；新建 ws 源一枚（V066 判例终结零新源五连）+540 第三次复用；写寄远的人传里无一寄字（系列第五枚）+思恰一恰在文思（V072 在册）；正文第二引第二十二例零重开；KNOWN 零如实记录第卅例（audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-032-city' AS id, 'BACKGROUND' AS entity_type, '032-city' AS slug, '这座城：江上压在涼思头上' AS title, '四层处境背景（阶段 D 第 55 首·八句五律 2/2/2/2）；史实句均有逐字引证；系年第四十九次判决（题证系列第卅七状·三远各有账寄信无账）「诗的三处远，通鉴里各有一本账，没有一本是寄信的」——同字两界第十九形态·寄远形态首见：北斗恰一（開元十二年祭南北斗咒）/南陵恰二（屯兵/败军）/天涯恰一（回鹘坟墓）闭域入引；占夢/新知/涼思全零；跨源零分歧面首见（选本页≡卷页八行逐字同面，双向断言）+五成页第二次+零标记正交第二枚；旧式裸锚+正文内联（与空壳转引成两极）；卷页并置第二次在场（江上「吾道豈淹留」压「南陵寓迟」头上——读法声明）；新建 ws 源一枚（V066 判例终结零新源五连）+540 第三次复用；写寄远的人传里无一寄字（系列第五枚）+思恰一恰在文思（V072 在册）；正文第二引第二十二例零重开；KNOWN 零如实记录第卅例（audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-032-world' AS id, 'BACKGROUND' AS entity_type, '032-world' AS slug, '这个天下：三远各有账，寄信没有账' AS title, '四层处境背景（阶段 D 第 55 首·八句五律 2/2/2/2）；史实句均有逐字引证；系年第四十九次判决（题证系列第卅七状·三远各有账寄信无账）「诗的三处远，通鉴里各有一本账，没有一本是寄信的」——同字两界第十九形态·寄远形态首见：北斗恰一（開元十二年祭南北斗咒）/南陵恰二（屯兵/败军）/天涯恰一（回鹘坟墓）闭域入引；占夢/新知/涼思全零；跨源零分歧面首见（选本页≡卷页八行逐字同面，双向断言）+五成页第二次+零标记正交第二枚；旧式裸锚+正文内联（与空壳转引成两极）；卷页并置第二次在场（江上「吾道豈淹留」压「南陵寓迟」头上——读法声明）；新建 ws 源一枚（V066 判例终结零新源五连）+540 第三次复用；写寄远的人传里无一寄字（系列第五枚）+思恰一恰在文思（V072 在册）；正文第二引第二十二例零重开；KNOWN 零如实记录第卅例（audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-032-person' AS id, 'BACKGROUND' AS entity_type, '032-person' AS slug, '这个人：典笺奏的人没有自己的信' AS title, '四层处境背景（阶段 D 第 55 首·八句五律 2/2/2/2）；史实句均有逐字引证；系年第四十九次判决（题证系列第卅七状·三远各有账寄信无账）「诗的三处远，通鉴里各有一本账，没有一本是寄信的」——同字两界第十九形态·寄远形态首见：北斗恰一（開元十二年祭南北斗咒）/南陵恰二（屯兵/败军）/天涯恰一（回鹘坟墓）闭域入引；占夢/新知/涼思全零；跨源零分歧面首见（选本页≡卷页八行逐字同面，双向断言）+五成页第二次+零标记正交第二枚；旧式裸锚+正文内联（与空壳转引成两极）；卷页并置第二次在场（江上「吾道豈淹留」压「南陵寓迟」头上——读法声明）；新建 ws 源一枚（V066 判例终结零新源五连）+540 第三次复用；写寄远的人传里无一寄字（系列第五枚）+思恰一恰在文思（V072 在册）；正文第二引第二十二例零重开；KNOWN 零如实记录第卅例（audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-032-scene' AS id, 'bg-032-scene' AS subject_id, 'context' AS property_key, '凉思八句取 ws 选本页 poem 块原样面入引（V018 句读式「客去波平檻，……疑誤有新知。」一引在先，零重开硬断言——正文第二引第二十二例）；双转录句读分工第三次在场；跨源零分歧面首见（ws 面≡V018 取自 540 之面，八行双向断言）；五成页第二次+零标记页（评级与标记正交第二枚标本）' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-032-city' AS id, 'bg-032-city' AS subject_id, 'context' AS property_key, '卷540 旧式裸名锚「==涼思==」+八句正文内联（V066 判例延展，与空壳转引成两极）；卷页并置第二次在场（江上尾句吾道豈淹留接涼思锚、涼思块尾接鸞鳳锚各恰一——并置系选本版式事实，「上压」读法声明）；ws notes 二连无↑+分类四行含詠懷詩（类目全库恰三页闭域，V048 不升格）；新建 source-ws-t300-032 一枚（V066 判例同款），540 第三次复用' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-032-world' AS id, 'bg-032-world' AS subject_id, 'context' AS property_key, '通鉴北斗恰一（開元十二年王皇后祭南北斗咒）/南陵恰二（上元元年傅子昂屯/乾符五年黄巢敗於）/天涯恰一（會昌二年回鹘坟墓隔在天涯）闭域入引；占夢/新知/涼思全零；三远各有其账、寄信没有账（同字两界第十九形态·寄远形态首见，对照判决非史实因果）' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-032-person' AS id, 'bg-032-person' AS subject_id, 'context' AS property_key, '旧传（简化字段）首引一段「三年入朝，京兆尹卢弘正奏署掾曹，令典笺奏。」（恰零域首引）；段内寄面题字三十一项全零——写寄远的人传里无一寄字书字信字（系列第五枚）；段内思字恰一恰在文思清丽（V072 在册零重开）；「寄远的人没有信」读法声明' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-032-scene' AS subject_id, 'context' AS property_key, 'claim-bg-032-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-032-city' AS subject_id, 'context' AS property_key, 'claim-bg-032-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-032-world' AS subject_id, 'context' AS property_key, 'claim-bg-032-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-032-person' AS subject_id, 'context' AS property_key, 'claim-bg-032-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-032-scene' AS id, 'work-t300-032' AS work_id, 'SCENE' AS layer, '**诗的第一笔是一场刚送客的空**：「客去波平檻，蟬休露滿枝」——人走了，水波正好平到栏杆，蝉声停了、露水满在枝头：整首凉思从「声音停了」开始。**ws 页是五成页第二次在场**（{{Textquality|50%}}——V073 首见、本篇成系列第二枚；已落李商隱诗页 TQ 谱档扫机器断言）；**零标记页×五成第二枚标本**（{{另}}/{{別}}/{{*}}/<ref>/{{reflist}}全零——评级与标记多寡正交）。**双转录句读分工第三次在场**（Vtext 行全裸、poem 块全句读——V072 首见、V073 第二次，本篇成连续系列）。**跨源零分歧面首见**：V018 给此诗立正文用的是卷540 卷页面（vol-raw），本快照 ws 诗页 poem 块与之逐字同面——同一首诗的选本页与卷页两个独立见证面在此逐字相合（生成时八行双向断言；与 V072异体分工、V073 八句全唐诗零恰成两极）。正文第二引上限用满第二十二例（V018 句读式一引在先，本迁移引 ws 页 poem 块原样面——同面各从其录，V018 句读式引文零重开硬断言），此后此诗正文关闭。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-032-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-032-city' AS id, 'work-t300-032' AS work_id, 'CITY' AS layer, '**这座城的档案员把两首诗钉成上下页**：卷540 里《江上》块尾句「吾道豈淹留」之后空一行直接接「==涼思==」锚、本篇块尾又直接接「==鸞鳳==」锚（机器断言各恰一——卷页并置第二次在场，V073 首见）：选本自己把「我这条路哪能留下」压在「托南陵的人送信迟迟」头上（读法声明）。**卷页是旧式裸名锚+正文内联**——「==涼思==」无消歧器、无「{{:}}」转引壳，八句直接内联锚下（V066 賈生旧式裸锚判例延展；与 V072/V073 的空壳转引恰成卷页见证面两极——内联 vs 空壳）；本篇八句在全唐诗语料恰一、恰在这一块（与 V073「八句全库零、诗只活在诗页」恰成两极——这首诗同时活在诗页与卷页两处）。ws 页 notes 是**二连无↑**（{{Textquality|50%}}{{唐詩三百首}}，无底本回指——V073 三连带↑/V066 无评级二连/本篇五成二连无↑：notes 排序谱再补一态）；分类**四行**含作者分类与「詠懷詩」类目（詠懷詩全库恰三页：夜雨寄北/涼思/登岳陽樓机器断言——类目行数与类目本身都是形态；分类行系整理者动作非史料声明、不升格，V048 判例）。**本迁移新建一枚 source**：source-ws-t300-032（V018 立正文时用卷页、选本页当时未建源——卷页与诗页是两个独立见证面，V066 賈生判例同款）；source-quantangshi-540 第三次复用（V018/V066 已引）。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-032-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-032-world' AS id, 'work-t300-032' AS work_id, 'WORLD' AS layer, '**诗里有三处远，通鉴里这三处没有一个在寄信**（同字两界第十九形态·寄远形态首见）：「北斗兼春遠」——通鉴「北斗」恰一：開元十二年（甲子，七二四）王皇后使其兄太子少保守一「**使僧明悟為後祭南北斗**，剖霹靂木，書天地字及上名，合而佩之」祝曰「佩此有子」——史的北斗是求子的符咒（事觉后废为庶人，守一赐死）；诗的北斗是连着春天一起远去的那颗星。「南陵寓使遲」——通鉴「南陵」恰二（221/253 闭域，机器断言）：上元元年（庚子，七六〇）「**傅子昂屯南陵**，将下江州，徇江西」（史的南陵是军队的驻地）；乾符五年（戊戌，八七八）黄巢攻宣州不克、「**敗於南陵**」（史的南陵是败军的方向）——诗的南陵是一封迟迟寄不出的信（「寓使」=托寓居的人捎信，通鉴连「寓使」这个词都不识）。「天涯占夢數」——通鉴「天涯」恰一：會昌二年（壬戌，八四二）李德裕论回鹘「**累代可汗墳墓，隔在天涯**」——史的天涯是汗祖坟的隔绝，诗的天涯是游子反复占梦的距离。**三远各有其账，寄信没有账**：「占夢」「新知」「涼思」通鉴全零（闭域档扫，机器断言）——史部连占梦这个动作都不记录；诗的三处远，一处都没落进任何人的账上（对照判决，非史实因果）。' AS body_text, 'SENIOR' AS audience, 'claim-bg-032-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-032-person' AS id, 'work-t300-032' AS work_id, 'PERSON' AS layer, '**旧传这一段给了这个人一段没有信的生活**：「三年入朝，京兆尹卢弘正奏署掾曹，**令典笺奏**」——史部记他替人管笺奏（公文），全库查重恰零域首引（简化字录入照登原样，V016 locator 同款标注）；诗的「南陵寓使遲」是他自己要寄的那封信，传里只有他替官府管的公文。**段内寄面题字三十一项全零**（客/波/檻/蟬/露/枝/永/節/倚/立/移/北/斗/春/遠/陵/寓/遲/涯/占/夢/數/疑/誤/知/寄/書/信/涼+思谱外二字，机器断言）——**写寄远的人，传里无一寄字无一书字无一信字**（V068 无一仙字/V071 无一瑟字/V072 无一蝉字/V073 无一风雨字同款第五枚）；**段内「思」字恰一恰在「文思清丽」**（V072 在册零重开，机器断言）：史部给他的思在文章的清丽里，诗的「永懷當此節」不是（读法声明，非史实因果）。紧接着「明年，令狐绹作相，商隐屡启陈情，绹不之省」在册零重开（V066/V067）——诗里数着占梦的人，史书里是他屡次递信、不看的人是他想寄信的人；「寄远的人没有信」系读法声明。KNOWN 零如实记录（第卅例，audit反向断言）。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-032-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文 ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-032-scene' AS claim_id, 'source-ws-t300-032' AS source_id, '页面 涼思（《唐詩三百首》第 32 首选本页，页题裸名；title+author+VH1 模板锚+署名行+Vtext 八行裸片+poem 存原样块以「……」相连——poem 带句读而 Vtext 全裸（双转录句读分工第三次成连续系列）；**五成页第二次在场**（V073 首见）+零标记页第二枚标本（{{另}}/{{別}}/{{*}}/<ref>/{{reflist}} 全零——评级与标记正交）；**跨源零分歧面首见**（V018 文本行取自卷540（vol-raw）与本快照 poem 块逐字同面——两独立见证面逐字相合，八行双向断言）；正文第二引第二十二例（V018 句读式一引在先不重开）' AS locator, '| title    = 涼思……| author   = 李商隱……{{VH1|涼思}}……{{Vtext|}}
{{Vtext|李商隱}}
{{Vtext|}}……{{VtextStart}}客去波平檻{{VtextEnd}}
{{VtextStart}}蟬休露滿枝{{VtextEnd}}
{{VtextStart}}永懷當此節{{VtextEnd}}
{{VtextStart}}倚立自移時{{VtextEnd}}
{{VtextStart}}北斗兼春遠{{VtextEnd}}
{{VtextStart}}南陵寓使遲{{VtextEnd}}
{{VtextStart}}天涯占夢數{{VtextEnd}}
{{VtextStart}}疑誤有新知{{VtextEnd}}……客去波平檻，蟬休露滿枝。
永懷當此節，倚立自移時。
北斗兼春遠，南陵寓使遲。
天涯占夢數，疑誤有新知。
</poem>' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-032-city' AS claim_id, 'source-quantangshi-540' AS source_id, '卷五百四十·李商隱《涼思》块（旧式裸名锚「==涼思==」+八句正文内联——V066 賈生旧式裸锚判例延展，与 V072/V073 空壳转引恰成卷页见证面两极；锚全唐诗唯一机器断言）；**卷页并置第二次在场**（V073 首见）：《江上》块尾句「吾道豈淹留」与本篇锚直接相接恰一+本篇块尾与《鸞鳳》锚直接相接恰一（选本版式事实——「上压」系读法声明）；八句全唐诗语料各恰一恰在此块（与 V073 全零成两极）；source-quantangshi-540 第三次复用零新建）' AS locator, '吾道豈淹留。
</poem>

==涼思==……==涼思==
<poem>
客去波平檻，蟬休露滿枝。
永懷當此節，倚立自移時。
北斗兼春遠，南陵寓使遲。
天涯占夢數，疑誤有新知。
</poem>……疑誤有新知。
</poem>

==鸞鳳==' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-032-city' AS claim_id, 'source-ws-t300-032' AS source_id, '页面 涼思（notes 二连一行整值入引（{{Textquality|50%}} 居首+{{唐詩三百首}}，**无↑底本回指**——排序谱再补一态：V073 三连带↑/V066 无评级/本篇五成二连无↑）+页尾分类四行（简繁并立含 [[Category:李商隱]] 与 [[Category:詠懷詩]]——**詠懷詩类目全库恰三页**：夜雨寄北/涼思/登岳陽樓机器断言；分类行系整理者分类动作：非史料声明、不升格，V048 判例）；**新建 source-ws-t300-032 一枚**（V018 立正文用卷页、选本页当时未建源——卷页与诗页是两个独立见证面，V066 賈生判例同款）' AS locator, '| notes    = {{Textquality|50%}}{{唐詩三百首}}……[[Category:李商隱]]
[[Category:唐诗]]
[[Category:唐詩三百首|李]]
[[Category:詠懷詩]]' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-032-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '卷二百一十二·開元十二年（甲子，七二四）王皇后案「使僧明悟為後祭南北斗，剖霹靂木，書天地字及上名，合而佩之」（**史的北斗是求子符咒**）……卷二百二十一·上元元年（庚子，七六〇）「傅子昂屯南陵，将下江州，徇江西」（**史的南陵是屯兵驻地**）……卷二百五十三·乾符五年（戊戌，八七八）黄巢「敗於南陵」（**史的南陵是败军方向**）……卷二百四十六·會昌二年（壬戌，八四二）李德裕论回鹘「累代可汗墳墓，隔在天涯」（**史的天涯是汗祖坟隔绝**）；通鉴北斗恰一/南陵恰二（221/253 闭域）/天涯恰一/占夢/新知/涼思全零（机器断言）——四段逐字入引为三远两界判决证据）' AS locator, '使僧明悟為後祭南北斗，剖霹靂木，書天地字及上名，合而佩之，……傅子昂屯南陵，將下江州，徇江西。……黃巢寇宣州，宣歙觀察使王凝拒之，敗於南陵。……累代可汗墳墓，隔在天涯，回鶻忿怒之心，不施於彼' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-032-person' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書卷一九〇下·李商隱（**简化字录入**照登原样，V016 locator 同款标注）「三年入朝，京兆尹卢弘正奏署掾曹，令典笺奏。」段（全库查重恰零域首引；传区间归属机器断言；**段内寄面题字三十一项全零**（客/波/檻/蟬/露/枝/永/節/倚/立/移/北/斗/春/遠/陵/寓/遲/涯/占/夢/數/疑/誤/知/寄/書/信/涼——**写寄远的人传里无一寄字书字信字**，系列第五枚）；**段内思字恰一恰在「文思清丽」**（V072 在册零重开，机器断言）——史部给他的思在文章清丽里，诗的永懷不是（读法声明）；V016/V066–V073 在册句零重开）' AS locator, '三年入朝，京兆尹卢弘正奏署掾曹，令典笺奏。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（八句五律 2/2/2/2 顺次） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-032-scene' AS background_id, 'text-work-t300-032-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-032-scene' AS background_id, 'text-work-t300-032-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-032-city' AS background_id, 'text-work-t300-032-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-032-city' AS background_id, 'text-work-t300-032-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-032-world' AS background_id, 'text-work-t300-032-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-032-world' AS background_id, 'text-work-t300-032-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-032-person' AS background_id, 'text-work-t300-032-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-032-person' AS background_id, 'text-work-t300-032-ws' AS version_id, 8 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 74, 'Li Shang-yin''s Cool Thought (work-t300-032) background layers (stage-D poem 55, eight-line regulated verse 2/2/2/2): dating verdict forty-nine, thirty-seventh shape of the title-evidence series -- the poem holds three distances; the histories keep a ledger for each, and none of them is a letter. Same-character-two-realms, nineteenth shape: the long-distance (jiyuan) shape, first seen. Beidou appears exactly once in the Tongjian (Kaiyuan 12, jiazi, 724: deposed Empress Wang had her brother Wang Shouyi ask the monk Mingwu to sacrifice to the Northern and Southern Dipoles, split thunderstruck wood, write the characters of Heaven and Earth plus her name, wear the bundle, and pray "wearing this I shall have a son; make me like the Empress Wu" -- the history''s Dipper is a barren woman''s spell, exposed; she was deposed to commoner status and Shouyi was executed on the road; the poem''s Dipper is a star receding together with spring). Nanling appears exactly twice (closed set 221/253, machine-asserted): Shangyuan 1, gengzi, 760, "Fu Zi''ang encamped at Nanling, about to move down on Jiangzhou" (the history''s Nanling is a troop camp); Qianfu 5, wuxu, 878, Huang Chao "defeated at Nanling" (the history''s Nanling is the direction of a routed army); the poem''s Nanling is a letter that never arrives -- the Tongjian does not even know the word yushi (a lodged courier). Tianya appears exactly once (Huichang 2, renxu, 842, Li Deyu on the Uyghurs: "the tombs of their khans, generation upon generation, lie severed at the sky''s edge" -- the history''s sky''s-edge is ancestral graves; the poem''s sky''s-edge is distance for a dream-diviner''s bed). Zhanmeng (dream divination), xinzhi (new acquaintances), liangsi (cool thought) all score zero in the Tongjian (machine-asserted): the histories do not record the very act of counting dream-omens; the poem''s three distances land in no ledger. Cross-source zero-divergence face, first seen: V018 stored this poem''s eight lines from the juan-540 anthology page (vol-raw), and this snapshot''s wiki source-page poem block matches line for line -- the two independent witnesses (anthology page and source page) agree verbatim (generator asserts both directions; the mirror of V072''s variant division and V073''s zero-across-Quan-Tangshi face: here the eight lines score exactly one each in the Quan Tangshi, inside the juan-540 inline block). The 540 page shows the old-style bare anchor "==涼思==" with the poem inlined under it (extending V066''s bare-anchor precedent; the opposite pole from V072/V073''s empty transclusion shells). Page-placement, second appearance (first in V073): the Jiangshang block''s last line "how could my way be long detained" sits directly above the Liangsi anchor, and the Liangsi block sits directly above the Luanfeng anchor (each exactly one join, machine-asserted; the reading "the previous poem''s closing line becomes the next poem''s footnote" is declared as reading, not fact). The ws page: 50-percent grade for the second time (V073 first), zero-mark page (second orthogonal specimen), {{VH1}} layout template (closed set: exactly 22 pages corpus-wide), notes two-token row without the back-reference (notes ordering, a further state), four category lines including 詠懷詩 (exactly three pages corpus-wide: Ye Yu Ji Bei, Liangsi, Deng Yuelou -- machine-asserted; editorial, not a source claim, not upgraded, V048 precedent). Double transcription division of labor, third appearance, a continuous series (naked Vtext lines / punctuated poem block). NEW SOURCE, exactly one: source-ws-t300-032 (V066 precedent -- V018 registered this poem''s text from the anthology page; the source-page witness had no source row; the anthology page and the source page are two independent witnesses), ending the five-poem zero-new-source streak legitimately; the 540 source at its third reuse. Body use-ceiling, twenty-second instance: V018''s punctuated excerpt stands first and is never re-opened (hard assertion); the body is now closed. PERSON first-cites one zero-domain simplified JTS passage -- "in the third year he entered court; the prefect of Jingzhao, Lu Hongzheng, memorialized to seat him in the adjutant''s office, ordering him to keep charge of documents and memorials" -- the histories record him drafting other men''s letters and record no letter of his own; the biography segment holds none of the thirty-one letter-side graphs (qi/ji/shu/xin and every title-side graph -- the man who wrote of sending far leaves no send-graph, no letter-graph in his biography, fifth of the series after V068/V071/V072/V073); the single si (thought) graph inside the segment is exactly the one inside "his writing''s thought is clean and beautiful" (closed in V072, never reopened): the thought the histories grant him lives in his prose style, not in "forever cherishing, facing this season" (declared as reading, not fact). KNOWN zero honestly recorded (thirtieth instance, audit reverse-asserts); closed precedent keywords (V018''s Beidou qixing gao and Liangsi punctuated full quote, V018''s tianya from the Jia Yi house poem, V067/V072/V073''s biography sentences, V070/V066/V016 lines) stay out of citations'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 74);
COMMIT;
