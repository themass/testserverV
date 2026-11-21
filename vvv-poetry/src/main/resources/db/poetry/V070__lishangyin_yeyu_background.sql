-- V070：李商隱《夜雨寄北》(work-t300-013) 四层背景（阶段 D 第 51 首·夜雨家书）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V014、V015、V016、V018、V035、V048、V053、V057、V058、V059、V060、
--       V061、V062、V063、V064、V065、V066、V067、V068、V069 已执行
--       （work-t300-013 与其 text-work-t300-013-ws（version_code=ws-xbook-fold，四行带句读、
--       第四行简体「却」）与其源 source-ws-t300-013（edition 字段即底本
--       「李義山詩集 (四部叢刊本)/卷第六」）都是 V018 的行；
--       source-quantangshi-539 是 V018 已立的卷539 卷页源（V018/V067/V068/V069 已引，
--       本迁移第五次复用——**这次引到的是空壳转引 {{:夜雨寄北}}，全卷无正文一字**）；
--       source-zizhi-tongjian-events 是 V014/V015 已立的通鉴事件源；
--       source-jiutangshu-wenyuan 是 V016 已立的旧唐书文苑传源（李商隐传在此，简化字录入）；
--       判例在册句（义山/开成二年/岭表/三十六体 V016、家書抵萬金 V011/V017、
--       四部叢刊/四庫全書 from 链与春晓诸句 V053、乘興南遊/孫處約諫書 V067、
--       穆王何事不重來/雲能合長生藥 V068、嵩雲秦樹久離居/茂陵秋雨病相如/↑底本回指 V069）
--       只对照不重开。
--       **本迁移零新建 source（连续第二首）——
--       audit 断言本文件零 poetry_source INSERT、回滚零 source 删除。**
--
-- 数据源（可复现）：emit_v070.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/夜雨寄北.txt（小写 {{textquality|75%}} 全库首见+异文三件套且无大写评级全库独页+
--   from 三行+notes 空壳+poem 存原样含 <ref> 异文注+双转录首末句各恰 2+分类四行詠懷詩首见）、
--   全唐詩卷539（锚 ==[[夜雨寄北]]== 全唐诗唯一+字面恰二全在壳内+
--   **539 全卷歸期/秋池/西窗/剪/巴山 全零（卷页无正文一字）**+夜雨3/燭2 他片闭域）、
--   舊唐書卷190下（李商隐段首引二段+**段内雨/夜/窗/燭/池五字全零**+段边界断言）、
--   通鑑卷193/225/230/248（六段逐字入引+五处年标题窗口断言：大曆十二年七七七×2/
--   興元元年七八四/貞觀四年六三〇/大中二年八四八）+
--   通鑑 75 卷负证计数扫描（夜雨/歸期/秋池/西窗/剪燭/巴山/寄北/寄内 全零+
--   秋霖恰二全在 225/家書恰一在 230/行旅恰一在 193/鄭亞恰三(248 卷二)/天子何在恰一/
--   公家無恙恰一/漲8/霖雨9/久雨10 闭域）+
--   既有迁移引文域逐句查重——传区间归属、二引/零重开/首引零域前提全部生成时断言。
--
-- 做：4 BACKGROUND content/claim/background + 5 组逐字引用（(claim,source) 主键每对恰一行）+
--   4 background_line（四句七绝 **1/1/1/1 第七次**（V056/V061/V066/V067/V068/V069 之后）：
--   scene→1 city→2 world→3 person→4，绑 text-work-t300-013-ws 的 4 行）+ 不碰 poetry_text_line。
-- 不做：**不新建任何 source（连续第二首）**；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「诗里一夜的雨通鉴全库没有；史部唯一的家书是斩封的」）：
--   * 「夜雨家书两界」系通鉴六段逐字入引支撑的对照判决，非史实因果——通鉴不记这首诗本身；
--   * 「寄给谁」不裁决——「寄北」「寄内」旧说都有，本迁移引文一字不能裁决；系年零铸造；
--   * 「史部的雨是公文」「候补」「各自飘零」标明读法声明；异文何當/何時只登记不裁决；
--   * 通鉴秋霖恰二都是奏报政务（报灾被驳/报盐造假）、家書恰一是李晟军中案（兴元元年）——
--     与诗题之雨/寄只共享字面，绝不当同一事件；
--   * 正文第二引上限用满：V018 句读式一引在先，本迁移引 ws 页 poem 块存原样面——
--     各从其录，V018 句读式引文不重开（生成时硬断言），此后此诗正文关闭；
--   * 「空壳第三形态」「双向绑定集齐」「小写评级首见」「三件套独页」「詠懷詩类目」均照登不判；
--   * 通鉴漲8/霖雨9/久雨10 在册零入引（audit 硬卡零混入）；
--   * KNOWN 零如实记录（第廿六例，audit 反向断言 SQL 无 KNOWN 字面量）；
--   * V011/V016/V053/V066–V069 已引诸句只对照不重开。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 69，不含 70
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-013-%';             -- 空
--   SELECT id FROM poetry_source WHERE id IN ('source-ws-t300-013','source-quantangshi-539');
--    -- 两行（均 V018 所立，本迁移不新建）
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-013-ws';  -- 恰 4
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-013-%';       -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-013';                                  -- 4（1/1/1/1）
--   SELECT certainty FROM poetry_claim WHERE id LIKE 'claim-bg-013-%';  -- 四行全 LIKELY
--   SELECT COUNT(*) FROM poetry_source WHERE id='source-ws-t300-013';   -- 恰 1（V018 所立）
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-013'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-013';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-013-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
-- 回滚: recovery/V070_rollback.sql（按 id 全枚举删除；**零 source 删除**——
--   source-ws-t300-013 与 source-quantangshi-539 皆 V018 所立，绝不删）
START TRANSACTION;

-- ---------- 0. 零新建 source（连续第二首；两源皆 V018 所立复用） ----------

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-013-scene' AS id, 'BACKGROUND' AS entity_type, '013-scene' AS slug, '眼前：回不了期的一夜雨' AS title, '四层处境背景（阶段 D 第 51 首·四句七绝 1/1/1/1 第七次）；史实句均有逐字引证；系年第四十五次判决（题证系列第卅三状·夜雨寄北与天子何在）「诗里一夜的雨通鉴全库没有；史部唯一的家书是斩封的」——同字两界第十五形态·家书形态首见：通鉴夜雨/歸期/秋池/西窗/剪燭/巴山/寄北/寄内全零（机器断言）；「秋霖」恰二全在大曆十二年丁巳七七七（黎幹奏秋霖損稼被驳「所損凡三萬餘頃」+韩滉奏「仍有瑞鹽生」造假——**史部的雨是公文，一场雨两条奏状；诗里同一场雨只写给一个人**）；「家書」恰一在興元元年甲子七八四李晟困长安（「天子何在，敢言家乎」+朱泚遗家書「公家無恙」晟立斬之——**史部的家书是斩封的，诗的家书是想象共剪的**）；「行旅」恰一在貞觀四年庚寅六三〇（外戶不閉行旅不繼糧——**史部唯一行旅是贞观之治，诗的行旅是巴山一夜回不去**）；「鄭亞」恰三，大中二年戊辰八四八亞貶循州刺史——**诗的老板史部只有官没有雨**；涨8/霖雨9/久雨10 在册闭域；**卷539 见证面系空壳转引「{{:夜雨寄北}}」——全卷无正文一字**（539 歸期/秋池/西窗/剪/巴山 全零机器断言）：绑定第三形态（底本=选本《李義山詩集》四部叢刊本、卷页挂壳），与 V069 ↑回指合成**双向绑定集齐**（↑向上/{{:}}向下各见一次）；锚全唐诗唯一+字面恰二全在壳内（两端裸名消歧链裸侧第五见 V061/V062/V063/V069）；**零新建 source连续第二首**（source-ws-t300-013 系 V018 所立、source-quantangshi-539第五次复用——壳本身就是证据）；正文第二引上限用满第十八例（V018 句读式在先+本迁移 ws 原样面含<ref>异文注，各从其录，V018 句读式引文不重开断言）；异文只登记不裁决（何當/何時，《墨莊漫録》《浄徳集》；from 三行版本目录入引——第三书墨莊漫録四庫全書本恰是异文注出处）；**小写 {{textquality|75%}}全库首见（大写全零）+异文三件套 {{另}}+<ref>+{{reflist}} 且无大写评级全 ws 库仅此一页**（机器断言）+notes 行空壳（无注可登，V069 ↑回指的反面）+分类四行简繁混排第五见+「詠懷詩」类目首见照登（非史料声明不升格 V048）；「寄北/寄内」两读并记不裁决；PERSON 旧传简化段首引二段（俄而茂元卒来游京师久之不调+郑亚廉察桂州检校水部员外郎——**回不了的归期在史部叫作候补**；**段内雨/夜/窗/燭/池五字全零：诗题有雨传段无一雨字**——段级零证机器断言）；V016 在册句零重开（域断言）；KNOWN 零如实记录（第廿六例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-013-city' AS id, 'BACKGROUND' AS entity_type, '013-city' AS slug, '这座城：只挂壳的卷页' AS title, '四层处境背景（阶段 D 第 51 首·四句七绝 1/1/1/1 第七次）；史实句均有逐字引证；系年第四十五次判决（题证系列第卅三状·夜雨寄北与天子何在）「诗里一夜的雨通鉴全库没有；史部唯一的家书是斩封的」——同字两界第十五形态·家书形态首见：通鉴夜雨/歸期/秋池/西窗/剪燭/巴山/寄北/寄内全零（机器断言）；「秋霖」恰二全在大曆十二年丁巳七七七（黎幹奏秋霖損稼被驳「所損凡三萬餘頃」+韩滉奏「仍有瑞鹽生」造假——**史部的雨是公文，一场雨两条奏状；诗里同一场雨只写给一个人**）；「家書」恰一在興元元年甲子七八四李晟困长安（「天子何在，敢言家乎」+朱泚遗家書「公家無恙」晟立斬之——**史部的家书是斩封的，诗的家书是想象共剪的**）；「行旅」恰一在貞觀四年庚寅六三〇（外戶不閉行旅不繼糧——**史部唯一行旅是贞观之治，诗的行旅是巴山一夜回不去**）；「鄭亞」恰三，大中二年戊辰八四八亞貶循州刺史——**诗的老板史部只有官没有雨**；涨8/霖雨9/久雨10 在册闭域；**卷539 见证面系空壳转引「{{:夜雨寄北}}」——全卷无正文一字**（539 歸期/秋池/西窗/剪/巴山 全零机器断言）：绑定第三形态（底本=选本《李義山詩集》四部叢刊本、卷页挂壳），与 V069 ↑回指合成**双向绑定集齐**（↑向上/{{:}}向下各见一次）；锚全唐诗唯一+字面恰二全在壳内（两端裸名消歧链裸侧第五见 V061/V062/V063/V069）；**零新建 source连续第二首**（source-ws-t300-013 系 V018 所立、source-quantangshi-539第五次复用——壳本身就是证据）；正文第二引上限用满第十八例（V018 句读式在先+本迁移 ws 原样面含<ref>异文注，各从其录，V018 句读式引文不重开断言）；异文只登记不裁决（何當/何時，《墨莊漫録》《浄徳集》；from 三行版本目录入引——第三书墨莊漫録四庫全書本恰是异文注出处）；**小写 {{textquality|75%}}全库首见（大写全零）+异文三件套 {{另}}+<ref>+{{reflist}} 且无大写评级全 ws 库仅此一页**（机器断言）+notes 行空壳（无注可登，V069 ↑回指的反面）+分类四行简繁混排第五见+「詠懷詩」类目首见照登（非史料声明不升格 V048）；「寄北/寄内」两读并记不裁决；PERSON 旧传简化段首引二段（俄而茂元卒来游京师久之不调+郑亚廉察桂州检校水部员外郎——**回不了的归期在史部叫作候补**；**段内雨/夜/窗/燭/池五字全零：诗题有雨传段无一雨字**——段级零证机器断言）；V016 在册句零重开（域断言）；KNOWN 零如实记录（第廿六例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-013-world' AS id, 'BACKGROUND' AS entity_type, '013-world' AS slug, '这个天下：斩封的家书' AS title, '四层处境背景（阶段 D 第 51 首·四句七绝 1/1/1/1 第七次）；史实句均有逐字引证；系年第四十五次判决（题证系列第卅三状·夜雨寄北与天子何在）「诗里一夜的雨通鉴全库没有；史部唯一的家书是斩封的」——同字两界第十五形态·家书形态首见：通鉴夜雨/歸期/秋池/西窗/剪燭/巴山/寄北/寄内全零（机器断言）；「秋霖」恰二全在大曆十二年丁巳七七七（黎幹奏秋霖損稼被驳「所損凡三萬餘頃」+韩滉奏「仍有瑞鹽生」造假——**史部的雨是公文，一场雨两条奏状；诗里同一场雨只写给一个人**）；「家書」恰一在興元元年甲子七八四李晟困长安（「天子何在，敢言家乎」+朱泚遗家書「公家無恙」晟立斬之——**史部的家书是斩封的，诗的家书是想象共剪的**）；「行旅」恰一在貞觀四年庚寅六三〇（外戶不閉行旅不繼糧——**史部唯一行旅是贞观之治，诗的行旅是巴山一夜回不去**）；「鄭亞」恰三，大中二年戊辰八四八亞貶循州刺史——**诗的老板史部只有官没有雨**；涨8/霖雨9/久雨10 在册闭域；**卷539 见证面系空壳转引「{{:夜雨寄北}}」——全卷无正文一字**（539 歸期/秋池/西窗/剪/巴山 全零机器断言）：绑定第三形态（底本=选本《李義山詩集》四部叢刊本、卷页挂壳），与 V069 ↑回指合成**双向绑定集齐**（↑向上/{{:}}向下各见一次）；锚全唐诗唯一+字面恰二全在壳内（两端裸名消歧链裸侧第五见 V061/V062/V063/V069）；**零新建 source连续第二首**（source-ws-t300-013 系 V018 所立、source-quantangshi-539第五次复用——壳本身就是证据）；正文第二引上限用满第十八例（V018 句读式在先+本迁移 ws 原样面含<ref>异文注，各从其录，V018 句读式引文不重开断言）；异文只登记不裁决（何當/何時，《墨莊漫録》《浄徳集》；from 三行版本目录入引——第三书墨莊漫録四庫全書本恰是异文注出处）；**小写 {{textquality|75%}}全库首见（大写全零）+异文三件套 {{另}}+<ref>+{{reflist}} 且无大写评级全 ws 库仅此一页**（机器断言）+notes 行空壳（无注可登，V069 ↑回指的反面）+分类四行简繁混排第五见+「詠懷詩」类目首见照登（非史料声明不升格 V048）；「寄北/寄内」两读并记不裁决；PERSON 旧传简化段首引二段（俄而茂元卒来游京师久之不调+郑亚廉察桂州检校水部员外郎——**回不了的归期在史部叫作候补**；**段内雨/夜/窗/燭/池五字全零：诗题有雨传段无一雨字**——段级零证机器断言）；V016 在册句零重开（域断言）；KNOWN 零如实记录（第廿六例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-013-person' AS id, 'BACKGROUND' AS entity_type, '013-person' AS slug, '这个人：久之不调' AS title, '四层处境背景（阶段 D 第 51 首·四句七绝 1/1/1/1 第七次）；史实句均有逐字引证；系年第四十五次判决（题证系列第卅三状·夜雨寄北与天子何在）「诗里一夜的雨通鉴全库没有；史部唯一的家书是斩封的」——同字两界第十五形态·家书形态首见：通鉴夜雨/歸期/秋池/西窗/剪燭/巴山/寄北/寄内全零（机器断言）；「秋霖」恰二全在大曆十二年丁巳七七七（黎幹奏秋霖損稼被驳「所損凡三萬餘頃」+韩滉奏「仍有瑞鹽生」造假——**史部的雨是公文，一场雨两条奏状；诗里同一场雨只写给一个人**）；「家書」恰一在興元元年甲子七八四李晟困长安（「天子何在，敢言家乎」+朱泚遗家書「公家無恙」晟立斬之——**史部的家书是斩封的，诗的家书是想象共剪的**）；「行旅」恰一在貞觀四年庚寅六三〇（外戶不閉行旅不繼糧——**史部唯一行旅是贞观之治，诗的行旅是巴山一夜回不去**）；「鄭亞」恰三，大中二年戊辰八四八亞貶循州刺史——**诗的老板史部只有官没有雨**；涨8/霖雨9/久雨10 在册闭域；**卷539 见证面系空壳转引「{{:夜雨寄北}}」——全卷无正文一字**（539 歸期/秋池/西窗/剪/巴山 全零机器断言）：绑定第三形态（底本=选本《李義山詩集》四部叢刊本、卷页挂壳），与 V069 ↑回指合成**双向绑定集齐**（↑向上/{{:}}向下各见一次）；锚全唐诗唯一+字面恰二全在壳内（两端裸名消歧链裸侧第五见 V061/V062/V063/V069）；**零新建 source连续第二首**（source-ws-t300-013 系 V018 所立、source-quantangshi-539第五次复用——壳本身就是证据）；正文第二引上限用满第十八例（V018 句读式在先+本迁移 ws 原样面含<ref>异文注，各从其录，V018 句读式引文不重开断言）；异文只登记不裁决（何當/何時，《墨莊漫録》《浄徳集》；from 三行版本目录入引——第三书墨莊漫録四庫全書本恰是异文注出处）；**小写 {{textquality|75%}}全库首见（大写全零）+异文三件套 {{另}}+<ref>+{{reflist}} 且无大写评级全 ws 库仅此一页**（机器断言）+notes 行空壳（无注可登，V069 ↑回指的反面）+分类四行简繁混排第五见+「詠懷詩」类目首见照登（非史料声明不升格 V048）；「寄北/寄内」两读并记不裁决；PERSON 旧传简化段首引二段（俄而茂元卒来游京师久之不调+郑亚廉察桂州检校水部员外郎——**回不了的归期在史部叫作候补**；**段内雨/夜/窗/燭/池五字全零：诗题有雨传段无一雨字**——段级零证机器断言）；V016 在册句零重开（域断言）；KNOWN 零如实记录（第廿六例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-013-scene' AS id, 'bg-013-scene' AS subject_id, 'context' AS property_key, '四句七绝本文**第二引上限用满第十八例**：V018 句读式一引在先（「君問歸期未有期，……却話巴山夜雨時。」），本迁移二引 ws 页 poem 块**存原样**（四句裸行+第三行行尾 <ref> 异文注，各从其录；生成时断言 V018 句读式引文不重开），此后正文对后来迁移关闭；异文只登记不裁决：「何當」，《墨莊漫録》及《浄徳集》均作「何時」；**小写 {{textquality|75%}} 评级形态全库首见**（本页大写 Textquality 全零，机器断言）；**异文三件套{{另|當|時}}+<ref>+{{reflist}} 且无大写评级——全 ws 库仅此一页**（机器断言）；notes 行空壳（三百首标记在 header 外）；「寄北/寄内」两种读法并记不裁决；系年零铸造。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-013-city' AS id, 'bg-013-city' AS subject_id, 'context' AS property_key, '本篇在《全唐詩》卷539 的见证面系**空壳转引**：「==[[夜雨寄北]]==」+「{{:夜雨寄北}}」，**全卷无正文一字**（机器断言：539 歸期/秋池/西窗/剪/巴山全零；夜雨3=壳二+他诗异文标记一/燭2 皆他诗闭域）——卷页/诗页绑定**第三形态**（V066–V068 卷页载正文、V069 诗页底本+↑回指、本篇底本=选本+卷页挂壳）；**双向绑定至此集齐**（V069 ↑向上 vs 本篇 {{:}} 向下）；锚全唐诗唯一+字面恰二全在壳内——无同名诗两端裸名，消歧链裸侧第五见（V061/V062/V063/V069 判例）；**零新建 source 连续第二首**（source-ws-t300-013 系 V018 所立、edition 即底本李義山詩集四部叢刊本；source-quantangshi-539 第五次复用）；ws from 三行版本目录入引——**第三书墨莊漫録四庫全書本恰是异文注出处**（from 链挂异文旁证书单）；分类四行简繁混排第五见+「詠懷詩」类目首见照登（非史料声明不升格，V048 判例）。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-013-world' AS id, 'bg-013-world' AS subject_id, 'context' AS property_key, '通鉴「夜雨/歸期/秋池/西窗/剪燭/巴山/寄北/寄内」全零（机器断言）而雨在他字：「秋霖」恰二全在大曆十二年丁巳七七七（黎幹奏秋霖損稼韩滉驳不实「所損凡三萬餘頃」+韩滉奏「雨雖多不害鹽仍有瑞鹽生」——**史部的雨是公文，一场雨两条奏状**）；「家書」恰一在興元元年甲子七八四李晟困长安（「軍中有言及家者…天子何在敢言家乎」+朱泚家書「公家無恙」晟立斬之——**史部的家书是斩封的，诗的家书是想象共剪的**）；「行旅」恰一在貞觀四年庚寅六三〇（「外戶不閉行旅不繼糧取給於道路」——**史部唯一行旅是贞观之治，诗的行旅是巴山一夜回不去**）；「鄭亞」恰三，大中二年戊辰八四八「桂管觀察使鄭亞坐前不能直吳湘冤…亞貶循州刺史」——**诗的老板史部只有官没有雨**（同字两界第十五形态·家书形态首见，audit 硬卡）；漲恰八/霖雨恰九/久雨恰十在册零入引；certainty 不覆盖任何系年，time.span/event.name/written_during 零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-013-person' AS id, 'bg-013-person' AS subject_id, 'context' AS property_key, '旧传李商隐段（简化字录入照登原样）首引二段皆生成时全库查重域恰零=「俄而茂元卒，来游京师，久之不调。」+「会给事中郑亚廉察桂州…检校水部员外郎。」（传区间归属机器断言）；**段级零雨字**：段内雨/夜/窗/燭/池五字全零（机器断言）——诗题有雨，传段无一雨字；「回不了的归期在史部那一栏叫作候补」「老板贬循州幕客困巴山」系读法声明非史实因果；本诗 notes 行空壳（无注可登）；V016 在册句（字义山/开成二年/岭表/三十六体/商隐随亚在岭表累载）零重开（域断言）；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-013-scene' AS subject_id, 'context' AS property_key, 'claim-bg-013-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-013-city' AS subject_id, 'context' AS property_key, 'claim-bg-013-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-013-world' AS subject_id, 'context' AS property_key, 'claim-bg-013-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-013-person' AS subject_id, 'context' AS property_key, 'claim-bg-013-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-013-scene' AS id, 'work-t300-013' AS work_id, 'SCENE' AS layer, '四句是一封回信：你问我归期，我没有归期（「君問歸期未有期」）；巴山连夜雨，涨满秋池（「巴山夜雨漲秋池」）；何时能共剪西窗之烛（「何當共剪西窗燭」）——再细说今夜巴山这场雨（「卻話巴山夜雨時」）。**寄给谁不裁决**——「寄北」「寄内」两种读法旧说都有，本迁移引文一字不能裁决（通鉴「寄北/寄内」二字全零，机器断言）；系年同样零铸造。ws 诗页：**小写 {{textquality|75%}} 评级形态全库首见**（此前 ws 库只有大写{{Textquality|75%}}/100% 或无评级三态——本页大写全零，机器断言；评级书写形态的分岔只照登不判）；**异文三件套 {{另|當|時}}+<ref>注+{{reflist}}且无大写评级——全 ws 库仅此一页**（机器断言）；异文只登记不裁决：「何當」，《墨莊漫録》及《浄徳集》均作「何時」；**notes 行空壳**（| notes 空值+{{唐詩三百首}}标记在 header 外——V069「↑底本回指链接」的反面：这页 notes 是空的，绑定方向反由卷页 {{:}} 转引承担）。**此诗正文系第二引（上限用满第十八例）**：V018 已引句读式（「君問歸期未有期，……却話巴山夜雨時。」——却，简体），本迁移改引 ws 页 poem 块**存原样**：四句裸行+第三行行尾 <ref> 异文注（各从其录；生成时断言 V018 句读式引文不重开）；此后此诗正文对后来迁移关闭。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-013-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-013-city' AS id, 'work-t300-013' AS work_id, 'CITY' AS layer, '卷539 侧是本迁移最特殊的一块：本篇在《全唐詩》卷539 的见证面是**空壳转引**——「==[[夜雨寄北]]==」下一行「{{:夜雨寄北}}」，**全卷无正文一字**（机器断言：539 全卷 歸期/秋池/西窗/剪/巴山 全零；「夜雨」三处=壳内两处+他诗异文标记一处，「燭」二处皆他诗——闭域档扫）。这是卷页/诗页绑定形态的**第三种**：V066–V068 卷页载正文（底本=卷页）、V069 诗页底本+↑回指链接（底本=诗页）、本篇**底本=选本《李義山詩集》（ws version_code ws-xbook-fold、from 行自述），卷页只挂壳**——**双向绑定至此集齐**：V069 是诗页 notes「↑」向上回指卷页，本篇是卷页「{{:}}」向下转引诗页，两个方向各见过一次（机器断言锚「==[[夜雨寄北]]==」全唐诗恰一、「夜雨寄北」字面恰二全在壳内——无同名诗，两端裸名，消歧链裸侧第五见，V061/V062/V063/V069 判例）。（本层零 relation。）**本迁移零新建 source（连续第二首）**：source-ws-t300-013 是 V018 所立诗页源（edition 字段即底本「李義山詩集 (四部叢刊本)/卷第六」），source-quantangshi-539 第五次复用（V018/V067/V068/V069 在册）——引卷页这一次，引到的正是一个空壳：**壳本身就是证据**，它证明编诗者视此诗归属已定、不必重抄。ws 侧 from 三行版本目录：底本四部叢刊本《李義山詩集》卷六+萬首唐人絶句四庫全書本+**第三书墨莊漫録四庫全書本卷05——恰是本页异文注的出处**（from 链不止底本目录，还挂着异文旁证的书单）；分类四行连片简繁混排第五见，「詠懷詩」类目首见（整理者归类：非史料声明、不升格，V048 判例）。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-013-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-013-world' AS id, 'work-t300-013' AS work_id, 'WORLD' AS layer, '**诗里一夜的雨，通鉴全库没有；史部唯一的家书是斩封的**（同字两界第十五形态·家书形态首见）：通鉴「**夜雨/歸期/秋池/西窗/剪燭/巴山/寄北/寄内**」全零（机器断言）——诗题连「寄北」二字史部都不识。可通鉴不是没有雨：① 「**秋霖**」恰二，全在大曆十二年（丁巳，七七七）：「**京兆尹黎幹奏秋霖損稼，韓滉奏幹不實；上命御史按視，丁未，還奏，『所損凡三萬餘頃。』**」——报灾的挨了驳；又「**先是，秋霖，河中府池鹽多敗。戶部侍郎判度支韓滉恐鹽戶減稅，丁亥，奏雨雖多，不害鹽，仍有瑞鹽生。**」——报平安的造了假。**史部的雨是公文：一场雨两条奏状；诗里同一场雨只写给一个人**；② 「**家書**」通鉴恰一，在興元元年（甲子，七八四）李晟困长安：「**軍中有言及家者，晟泣曰：『天子何在，敢言家乎！』」**朱泚使以家書遺晟曰「**公家無恙**」，晟怒曰「爾敢為賊為間！」**立斬之**」——**史部的家书是斩封的；诗的家书是想象共剪的**。「君問歸期未有期」对「天子何在，敢言家乎」：一个是回不了的归期，一个是不许问的家（对照判决，非史实因果——通鉴不记这首诗本身）；③ 「**行旅**」恰一，在貞觀四年（庚寅，六三〇）：「**東至於海，南及五嶺，皆外戶不閉，行旅不繼糧，取給於道路焉**」——**史部唯一的行旅是贞观之治的路不拾遗；诗的行旅是巴山一夜，回不去**；④ 「**鄭亞**」恰三（247/248 卷），大中二年（戊辰，八四八）「**桂管觀察使鄭亞坐前不能直吳湘冤……亞貶循州刺史**」——**诗的老板在通鉴只有贬官一行：史部有他的官，没有他的雨**。「漲」恰八他事、「霖雨」恰九/「久雨」恰十在册零入引（闭域档扫）。本层零铸造零 relation。' AS body_text, 'SENIOR' AS audience, 'claim-bg-013-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-013-person' AS id, 'work-t300-013' AS work_id, 'PERSON' AS layer, '旧传李商隐段（**简化字录入**，V016 locator 同款标注，引文照登简体原样）首引二段（皆零域）：「**俄而茂元卒，来游京师，久之不调。**」「**会给事中郑亚廉察桂州……检校水部员外郎。**」
史部没有这场雨（段级零证：段内**雨/夜/窗/燭/池五字全零**，机器断言——**诗题有雨，传段无一雨字**），却把诗的「未有期」四个字写成了官历：王茂元死了，李商隐到京师游了多年，「久之不调」——**回不了的归期，在史部那一栏叫作候补**；下一段给出老板之实：给事中郑亚出镇桂州，带他入幕带检校衔——而这位郑亚，通鉴大中二年「亞貶循州刺史」（WORLD 层）：老板和幕客各自飘零，一个贬循州，一个困巴山（读法声明，非史实因果）。
本诗 ws 页 **notes 行空壳**（无注可登——V069 有↑回指注、V055/V057 等有底注，本篇空：注的有无本身也是形态）；certainty 不覆盖任何系年，诗 time.span/event.name/written_during 仍零铸造（audit 硬卡）；V016「商隐随亚在岭表累载/字义山/开成二年/三十六体」等在册句零重开（域断言）。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-013-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文 ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-013-scene' AS claim_id, 'source-ws-t300-013' AS source_id, '页面 夜雨寄北（《唐詩三百首》第 13 首选本页，页题裸名；title+author+小写评级+Vtext 折叠行+poem 块以「……」相连——**小写 {{textquality|75%}} 全库首见（大写全零）**；页内异文双写形态：Vtext 行用 {{另|當|時}} 折叠、poem 行尾用 <ref> 注（「何當」：《墨莊漫録》及《浄徳集》均作「何時」——只登记不裁决）；poem 块**存原样**：正文第二引上限用满第十八例（V018 句读式一引在先，本迁移引原样面，各从其录，生成时断言 V018 句读式引文不重开）；{{reflist}} 在页尾）' AS locator, '| title    = 夜雨寄北……| author   = 李商隱……{{textquality|75%}}……何{{另|當|時}}共剪西窗燭……君問歸期未有期
巴山夜雨漲秋池
何當共剪西窗燭<ref>「何當」：《墨莊漫録》及《浄徳集》均作「何時」</ref>
卻話巴山夜雨時
</poem>' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-013-city' AS claim_id, 'source-quantangshi-539' AS source_id, '卷五百三十九·李商隱《夜雨寄北》**空壳转引块**（「==[[夜雨寄北]]==」+「{{:夜雨寄北}}」——**卷页无正文一字**：539 全卷歸期/秋池/西窗/剪/巴山 全零机器断言；夜雨3/燭2 他片闭域；绑定第三形态：底本=选本《李義山詩集》、卷页只挂壳，与 V069 ↑回指合成双向绑定；锚全唐诗唯一+字面恰二全在壳内——两端裸名消歧链裸侧第五见；源行系 V018 已立、本迁移第五次复用零新建）' AS locator, '==[[夜雨寄北]]==
{{:夜雨寄北}}' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-013-city' AS claim_id, 'source-ws-t300-013' AS source_id, '页面 夜雨寄北（from 三行版本目录整段入引（底本四部叢刊本《李義山詩集》卷六+萬首唐人絶句四庫全書本+**第三书墨莊漫録四庫全書本卷05恰是异文注出处**——版本目录链非史料断言，V053 判例只引不重开他书 from 链）+notes 空壳块（| notes 空值+三百首标记在 header 外）+分类四行连片（简繁混排第五见+「詠懷詩」类目首见照登；分类行系整理者分类动作：非史料声明、不升格，V048 判例）；本迁移零新建源连续第二首）' AS locator, '| from     = 李義山詩集 (四部叢刊本)/卷第六
| from2    = 萬首唐人絶句 (四庫全書本)/七言卷40
| from3    = 墨莊漫録 (四庫全書本)/卷05
……| notes    = 
}}
{{唐詩三百首}}
……[[Category:李商隱]]
[[Category:唐诗]]
[[Category:唐詩三百首|李]]
[[Category:詠懷詩]]' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-013-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '卷二百二十五·大曆十二年（丁巳，七七七）秋霖双案（黎幹奏秋霖損稼被驳「所損凡三萬餘頃」+韩滉奏「仍有瑞鹽生」——史部的雨是公文）……卷二百三十·興元元年（甲子，七八四）李晟家书斩封案（「天子何在，敢言家乎」+「公家無恙」立斬之——史部唯一家书是斩的）……卷一百九十三·貞觀四年（庚寅，六三〇）「外戶不閉行旅不繼糧」段（唯一行旅=贞观之治）……卷二百四十八·大中二年（戊辰，八四八）鄭亞貶循州刺史段（老板有官无雨）；通鉴诗面夜雨/寄北等八字全零，秋霖恰二/家書恰一/行旅恰一/鄭亞恰三（六段逐字入引为判决证据）' AS locator, '京兆尹黎幹奏秋霖損稼，韓滉奏幹不實；上命御史按視，丁未，還奏，「所損凡三萬餘頃。」……先是，秋霖，河中府池鹽多敗。戶部侍郎判度支韓滉恐鹽戶減稅，丁亥，奏雨雖多，不害鹽，仍有瑞鹽生。……軍中有言及家者，晟泣曰：「天子何在，敢言家乎！」泚使晟親近以家書遺晟曰：「公家無恙。」晟怒曰：「爾敢為賊為間！」立斬之。……東至於海，南及五嶺，皆外戶不閉，行旅不繼糧，取給於道路焉。……桂管觀察使鄭亞坐前不能直吳湘冤，乙酉，回左遷湖南觀察使，亞貶循州刺史，' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-013-person' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書卷一九〇下·李商隱（**简化字录入**照登原样，V016 locator 同款标注）（「俄而茂元卒，来游京师，久之不调」段（诗的未有期对上史传官历）+「会给事中郑亚廉察桂州…检校水部员外郎」段（老板之实，对 WORLD 层亚贬循州）——皆全库查重恰零域首引；传区间归属机器断言；段内雨/夜/窗/燭/池五字全零（段级零雨字——诗题有雨传段无雨字）；「候补」「各自飘零」系读法声明；V016 在册句零重开）' AS locator, '俄而茂元卒，来游京师，久之不调。……会给事中郑亚廉察桂州，请为观察判官、检校水部员外郎。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（四句七绝 1/1/1/1 第七次） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-013-scene' AS background_id, 'text-work-t300-013-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-013-city' AS background_id, 'text-work-t300-013-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-013-world' AS background_id, 'text-work-t300-013-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-013-person' AS background_id, 'text-work-t300-013-ws' AS version_id, 4 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 70, 'Li Shang-yin''s Night Rain, Sent North (work-t300-013) background layers (stage-D poem 51, four-line jueju 1/1/1/1 seventh time): dating verdict forty-five, thirty-third shape of the title-evidence series -- a single night of rain in the poem, nowhere in the whole Zizhi Tongjian; the histories'' one and only family letter is a beheaded one. Same-character-two-realms, fifteenth shape: the home-letter shape, first seen. The Tongjian scores zero on every word of the poem''s night -- yeyu (night rain), guiqi (date of return), qiuchi (autumn pool), xichuang (west window), cutting the candle, Bashan, "sent north", "sent to my wife" (machine-asserted) -- the histories do not even recognise the two words of the title. Yet the histories do have rain: "autumn rain (qiulin)" appears exactly twice, both in Dali 12, dingsi, 777: "Jingzhao Yin Li Gan memorialised that autumn rain damaged the crops; Han Huang memorialised that Gan''s report was not truthful... the damage came to over thirty thousand qing" -- the reporter of disaster was impeached; and "before this, autumn rain had spoiled the pond-salt at Hezhong; Huang, fearing a cut in the salt households'' tax, memorialised that though the rain was much it did not harm the salt, and that auspicious salt had even grown" -- the reporter of good weather faked it. The histories'' rain is an official dispatch: one rain, two memorials; the poem''s same rain is written to exactly one person. "Family letter (jiashu)" appears exactly once in the Tongjian, in Xingyuan 1, jiazi, 784, with Li Cheng penned inside Chang''an: "when any man in the army spoke of home, Cheng wept and said: where is the Son of Heaven, that you dare speak of home!" Zhu Ci had a family letter sent him saying "your household is unharmed"; Cheng flew into a rage and had the bearer beheaded at once" -- the histories'' home letter is a letter cut open and its bearer killed; the poem''s home letter is an imagined shared trimming of the west-window candle. "Travelers (xinglu)" appears exactly once, in Zhenguan 4, gengyin, 630: "from the sea in the east to the five ridges in the south, outer gates stood unbarred and travelers carried no grain, sourcing it along the roads" -- the histories'' one journey is the peace of Zhenguan; the poem''s journey is one night in Bashan, with no way back. Zheng Ya appears exactly three times, and in Dazhong 2, wuchen, 848: "Zheng Ya,观察者 of Guiguan, was demoted to Prefect of Xunzhou for failing earlier to redress the Wu Xiang injustice" -- the poem''s own patron exists in the histories only as one demotion line: the histories have his office, not his rain. The juan-539 witness face of this poem in the Quan Tangshi is a transclusion stub: heading plus {{:夜雨寄北}} and nothing else -- **not one character of the poem text anywhere in juan 539** (machine-asserted: guiqi/qiuchi/xichuang/cut/Bashan all score zero across the juan) -- the third binding form: base text = the anthology Li Yishan shiji (Sibu Congkan edition), the scroll page merely hangs the shell; with V069''s up-arrow back-reference the two binding directions now come complete (poem page pointing up at the scroll page, scroll page transcluding down from the poem page, one sighting each). ZERO new sources, second poem running (audit asserts zero poetry_source INSERT and zero source deletion); the shell itself is the evidence: the compilers treated the attribution as settled. Body use-ceiling reached, eighteenth instance: V018 quoted the punctuated text (with the simplified qi character); this migration quotes the ws page''s raw poem block, its third line carrying the apparatus <ref> registering the variant (hedaing vs. heshi, sourced to the Mozhuang manlu and the Jingde ji) -- registering only, never adjudicating (generator asserts V018''s punctuated excerpt is never re-used); the body is now closed. The ws page shows, first anywhere in the corpus, the lowercase rating form {{textquality|75%}} (this page''s uppercase Textquality count is zero, machine-asserted), and is the only page in the whole ws corpus that carries {{reflist}} with no uppercase rating (machine-asserted); its notes field is an empty shell (no annotation to log -- the mirror of V069''s back-reference arrow); its from-chain names the declared base plus, as its third book, precisely the Mozhuang manlu cited by the variant note (the chain lists not only bases but witnesses); the category quadruple''s 詠懷詩 tag, first seen, logged (editorial, not a source claim, not upgraded, V048 precedent); the title''s addressee (north? my wife?) is left undecided -- neither reading can be adjudicated from these citations. PERSON first-cites two zero-domain simplified JTS passages -- "when Mao-yuan soon after died, [Shang-yin] came to roam the capital and for a long while was not assigned" (the poem''s "no date of return" rendered, in the histories'' column, as years of waiting), and "it happened that Zhen Ya, as supervising censore, proceeded to Guizhou... [he followed him as] supernumerary Vice Director of the Bureau of Waterways" -- with the biography segment holding not a single character of rain/night/window/candle/pool (machine-asserted: the poem''s title carries rain, the biography segment not one rain-graph); "the histories'' column for the unreachable return date is called waiting-for-post" and "patron demoted to Xunzhou, clerk stranded in Bashan" are readings declared, not facts. KNOWN zero honestly recorded (twenty-sixth instance, audit reverse-asserts); closed precedent keywords (including V011''s family-letters-worth-ten-thousand-gold and V053''s from-chains) stay out of citations'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 70);
COMMIT;
