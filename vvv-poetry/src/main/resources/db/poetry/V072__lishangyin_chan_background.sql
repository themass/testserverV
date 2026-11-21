-- V072：李商隱《蟬》(work-t300-011) 四层背景（阶段 D 第 53 首·清直两界）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V014、V015、V016、V018、V026、V033、V035、V039、V048、V053、V057、
--       V058、V059、V060、V061、V062、V063、V064、V065、V066、V067、V068、V069、V070、
--       V071 已执行
--       （work-t300-011 与其 text-work-t300-011-ws（version_code=ws-fold，八行带句读、
--       第三行「五更疎欲斷」、第五行「薄宦梗猶汎」——**V018 存疎/汎归一面**）
--       与其源 source-ws-t300-011（edition 字段即底本「全唐詩」）都是 V018 的行；
--       source-quantangshi-539 是 V018 已立的卷539 卷页源（V018/V067/V068/V069/V070/V071
--       已引，本迁移第七次复用——**这次引到的是带作者消歧器的壳 {{:蟬 (李商隱)}}**）；
--       source-zizhi-tongjian-events 是 V014/V015 已立的通鉴事件源；
--       source-jiutangshu-wenyuan 是 V016 已立的旧唐书文苑传源（李商隐传在此，简化字录入）；
--       判例在册句（义山/开成二年/岭表/三十六体/未几病卒/大中末/仲郢坐/还郑州 V016、
--       绹不之省/坎壈终身 V066/V067、以所业文干之/下笔不能自休 V067、恃才诡激/
--       为当涂者所薄 V068、茂元爱其才/背恩无行 V069、锦瑟句读式正文与故园（春晓）
--       V018、{{:錦瑟}}/↑…錦瑟 V071、{{:夜雨寄北}}/↑…寄令狐郎中 V069/V070、
--       穆王何事不重來/雲能合長生藥 V068、別來滄海事 V033、得宋之問藍田别墅 V035/V039）
--       只对照不重开。
--       **本迁移零新建 source（连续第四首）——
--       audit 断言本文件零 poetry_source INSERT、回滚零 source 删除。**
--
-- 数据源（可复现）：emit_v072.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/蟬__李商隱_.txt（零标记×100% 满级+双转录句读分工（Vtext 裸/poem 句读）+
--   疏/泛面（对 V018 疎/汎面——跨迁移异体分工双向断言）+notes 三连一行（全库恰三页）+
--   分类四行含作者分类+詠蟬詩类目（全库恰二页）+无 times/type/from 字段）、
--   全唐詩卷539（锚 ==[[蟬 (李商隱)|蟬]]== 与 {{:蟬 (李商隱)}} 各全唐诗唯一（机器断言）+
--   **壳外全卷无本篇一行**（八句全库零）+卷内蟬八=壳二+他诗六闭域）、
--   舊唐書卷190下（李商隐段首引一段+**段内清恰一恰在文思清丽+题字十一项全零**+段边界断言）、
--   通鑑卷224/243/248/254（四段逐字入引+四处年标题窗口断言：大曆八年七七三/長慶三年八二三/
--   大中二年八四八/廣明元年八八〇）+
--   通鑑 75 卷负证计数扫描（蟬/蝉/鳴蟬/蜩/高難飽/費聲/疏欲/碧無情/梗猶/故園蕪已平/煩君/
--   舉家清/薄宦 全零+清直恰二（243/248）+舉家恰七+家無9/飽18/梗4/清297/高896/汎0 闭域）+
--   既有迁移引文域逐句查重——传区间归属、二引/零重开/首引零域前提全部生成时断言。
--
-- 做：4 BACKGROUND content/claim/background + 5 组逐字引用（(claim,source) 主键每对恰一行）+
--   8 background_line（八句七律 **2/2/2/2 顺次**：scene→1,2 city→3,4 world→5,6 person→7,8，
--   绑 text-work-t300-011-ws 的 8 行）+ 不碰 poetry_text_line。
-- 不做：**不新建任何 source（连续第四首）**；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「咏物诗的物名史部全库不识；史部的清直两头都在人事的账上」）：
--   * 「清直两界」系通鉴四段逐字入引支撑的对照判决，非史实因果——通鉴不记这首诗本身；
--     亦不考本诗系年（旧注系大中十年等说一律不采信不铸造）；
--   * 「我亦舉家清」不自证操守、「传说他无持操/诗说举家清各执一词」标明读法声明；
--   * 异体疏/疎、泛/汎只登记不裁决——V018 面与本快照面并存各从其录（生成时双向断言）；
--   * 通鉴清直恰二是逢吉荐绅/丁柔立案（长庆/大中）、舉家恰七含郑綦举家自尽（广明）——
--     与诗之清只共享字面，绝不当同一事；
--   * 正文第二引上限用满：V018 句读式一引在先，本迁移引 ws 页 poem 块存原样面——
--     各从其录，V018 句读式引文不重开（生成时硬断言），此后此诗正文关闭；
--   * 「壳侧消歧首见」「互指第二次」「零标记×满级」「句读分工」「分类行数形态」
--     均照登不判；
--   * 通鉴清297/高896/飽18/汎0 在册零入引（audit 硬卡零混入）；
--   * KNOWN 零如实记录（第廿八例，audit 反向断言 SQL 无 KNOWN 字面量）；
--   * V011/V016/V018/V026/V033/V035/V039/V053/V063/V066–V071 已引诸句只对照不重开。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 71，不含 72
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-011-%';             -- 空
--   SELECT id FROM poetry_source WHERE id IN ('source-ws-t300-011','source-quantangshi-539');
--    -- 两行（均 V018 所立，本迁移不新建）
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-011-ws';  -- 恰 8
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-011-%';       -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-011';                                  -- 8（2/2/2/2）
--   SELECT certainty FROM poetry_claim WHERE id LIKE 'claim-bg-011-%';  -- 四行全 LIKELY
--   SELECT COUNT(*) FROM poetry_source WHERE id='source-ws-t300-011';   -- 恰 1（V018 所立）
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-011'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-011';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-011-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
-- 回滚: recovery/V072_rollback.sql（按 id 全枚举删除；**零 source 删除**——
--   source-ws-t300-011 与 source-quantangshi-539 皆 V018 所立，绝不删）
START TRANSACTION;

-- ---------- 0. 零新建 source（连续第四首；两源皆 V018 所立复用） ----------

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-011-scene' AS id, 'BACKGROUND' AS entity_type, '011-scene' AS slug, '眼前：对蝉开口的八句' AS title, '四层处境背景（阶段 D 第 53 首·八句七律 2/2/2/2）；史实句均有逐字引证；系年第四十七次判决（题证系列第卅五状·蟬无一字与清直恰二）「通鉴七十五卷连一个蟬字都没有；可它有清直，且两头都在人事的账上」——同字两界第十七形态·清直形态首见：通鉴蟬/蝉/鳴蟬/蜩/高難飽/費聲/疏欲/碧無情/梗猶/故園蕪已平/煩君/舉家清/薄宦全零（机器断言——咏物诗的物名史部全库不识）；「清直」恰二分長慶三年癸卯八二三（逢吉荐李绅清直宜居风宪——政敌递出去的梯子）与大中二年戊辰八四八（丁柔立以清直荐、德裕不能用、讼德裕冤、坐阿附贬南阳尉——还不清的代价）——**史部的清直两头都在人事的账上；诗的我亦舉家清不在任何账上**；「舉家」恰七闭域，廣明元年庚子八八〇鄭綦鄭系義不臣賊舉家自殺（赴死）+大曆八年癸丑七七三李建举家西归（拒位）——**史部的举家要么拒位要么赴死，诗的举家清是活着清**；清297/高896/飽18/汎0 在册闭域；**互指循环指针第二次在场**（V071 首见本篇坐实成系列）：ws notes「↑ 卷539#蟬」向上回指+539 本篇「{{:蟬 (李商隱)}}」向下转引（机器断言：notes 三连页全库恰三——蟬/錦瑟/韓碑；八句全唐诗语料全零——诗只活在诗页）；**壳侧作者消歧器首见**：锚「==[[蟬 (李商隱)|蟬]]==」+转引「{{:蟬 (李商隱)}}」全唐诗各恰一——消歧器第一次挂上壳侧且显示名仍裸（V059/V061 锚侧消歧/V062,V063 裸名/V067 同名裸锚反例/V069–V071 壳侧裸名——消歧谱补全壳侧一层）；消歧理由在册可查：ws 蟬名页恰三+全唐诗蟬字 83（539 内八=壳二+他诗六闭域档扫）；**零新建 source 连续第四首**（两源皆V018 所立，539 第七次复用）；正文第二引上限用满第二十例（V018 句读式疎/汎面在先+本迁移 ws 原样疏/泛面，各从其录，V018 句读式引文零重开断言）；**跨迁移异体分工首见**（V018 存疎/汎归一面、本快照存疏/泛面——同一页两次快照异体不同，逐行对读折叠判一致，双向断言）；**零标记页×100% 满级**（V069 同形第二例，与 V071 双{{另}}×100% 对照成谱：评级与异文多寡正交）+,**双转录句读分工首见**（Vtext 全裸/poem 全句读——夜雨寄北两侧皆裸的反面）+分类四行含作者分类（对照 V071 两行无）+「詠蟬詩」类目首见（全库恰二页：本篇+在獄詠蟬机器断言；非史料声明不升格 V048）；八句对蝉说话的第二人称形态照登；PERSON 旧传简化段首引一段（文思清丽庭筠过之——**段内清字恰一恰在笔底：史部给他的清在文章里，诗自己把清认领到门第上**；**段内题字十一项全零：写蝉的人传里无一蝉字**——V071 无一瑟字同款）；「无持操对举家清两部书各执一词」读法声明；V016/V066–V068/V070/V071 在册句零重开（域断言）；KNOWN 零如实记录（第廿八例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-011-city' AS id, 'BACKGROUND' AS entity_type, '011-city' AS slug, '这座城：带消歧器的壳' AS title, '四层处境背景（阶段 D 第 53 首·八句七律 2/2/2/2）；史实句均有逐字引证；系年第四十七次判决（题证系列第卅五状·蟬无一字与清直恰二）「通鉴七十五卷连一个蟬字都没有；可它有清直，且两头都在人事的账上」——同字两界第十七形态·清直形态首见：通鉴蟬/蝉/鳴蟬/蜩/高難飽/費聲/疏欲/碧無情/梗猶/故園蕪已平/煩君/舉家清/薄宦全零（机器断言——咏物诗的物名史部全库不识）；「清直」恰二分長慶三年癸卯八二三（逢吉荐李绅清直宜居风宪——政敌递出去的梯子）与大中二年戊辰八四八（丁柔立以清直荐、德裕不能用、讼德裕冤、坐阿附贬南阳尉——还不清的代价）——**史部的清直两头都在人事的账上；诗的我亦舉家清不在任何账上**；「舉家」恰七闭域，廣明元年庚子八八〇鄭綦鄭系義不臣賊舉家自殺（赴死）+大曆八年癸丑七七三李建举家西归（拒位）——**史部的举家要么拒位要么赴死，诗的举家清是活着清**；清297/高896/飽18/汎0 在册闭域；**互指循环指针第二次在场**（V071 首见本篇坐实成系列）：ws notes「↑ 卷539#蟬」向上回指+539 本篇「{{:蟬 (李商隱)}}」向下转引（机器断言：notes 三连页全库恰三——蟬/錦瑟/韓碑；八句全唐诗语料全零——诗只活在诗页）；**壳侧作者消歧器首见**：锚「==[[蟬 (李商隱)|蟬]]==」+转引「{{:蟬 (李商隱)}}」全唐诗各恰一——消歧器第一次挂上壳侧且显示名仍裸（V059/V061 锚侧消歧/V062,V063 裸名/V067 同名裸锚反例/V069–V071 壳侧裸名——消歧谱补全壳侧一层）；消歧理由在册可查：ws 蟬名页恰三+全唐诗蟬字 83（539 内八=壳二+他诗六闭域档扫）；**零新建 source 连续第四首**（两源皆V018 所立，539 第七次复用）；正文第二引上限用满第二十例（V018 句读式疎/汎面在先+本迁移 ws 原样疏/泛面，各从其录，V018 句读式引文零重开断言）；**跨迁移异体分工首见**（V018 存疎/汎归一面、本快照存疏/泛面——同一页两次快照异体不同，逐行对读折叠判一致，双向断言）；**零标记页×100% 满级**（V069 同形第二例，与 V071 双{{另}}×100% 对照成谱：评级与异文多寡正交）+,**双转录句读分工首见**（Vtext 全裸/poem 全句读——夜雨寄北两侧皆裸的反面）+分类四行含作者分类（对照 V071 两行无）+「詠蟬詩」类目首见（全库恰二页：本篇+在獄詠蟬机器断言；非史料声明不升格 V048）；八句对蝉说话的第二人称形态照登；PERSON 旧传简化段首引一段（文思清丽庭筠过之——**段内清字恰一恰在笔底：史部给他的清在文章里，诗自己把清认领到门第上**；**段内题字十一项全零：写蝉的人传里无一蝉字**——V071 无一瑟字同款）；「无持操对举家清两部书各执一词」读法声明；V016/V066–V068/V070/V071 在册句零重开（域断言）；KNOWN 零如实记录（第廿八例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-011-world' AS id, 'BACKGROUND' AS entity_type, '011-world' AS slug, '这个天下：账上的清直' AS title, '四层处境背景（阶段 D 第 53 首·八句七律 2/2/2/2）；史实句均有逐字引证；系年第四十七次判决（题证系列第卅五状·蟬无一字与清直恰二）「通鉴七十五卷连一个蟬字都没有；可它有清直，且两头都在人事的账上」——同字两界第十七形态·清直形态首见：通鉴蟬/蝉/鳴蟬/蜩/高難飽/費聲/疏欲/碧無情/梗猶/故園蕪已平/煩君/舉家清/薄宦全零（机器断言——咏物诗的物名史部全库不识）；「清直」恰二分長慶三年癸卯八二三（逢吉荐李绅清直宜居风宪——政敌递出去的梯子）与大中二年戊辰八四八（丁柔立以清直荐、德裕不能用、讼德裕冤、坐阿附贬南阳尉——还不清的代价）——**史部的清直两头都在人事的账上；诗的我亦舉家清不在任何账上**；「舉家」恰七闭域，廣明元年庚子八八〇鄭綦鄭系義不臣賊舉家自殺（赴死）+大曆八年癸丑七七三李建举家西归（拒位）——**史部的举家要么拒位要么赴死，诗的举家清是活着清**；清297/高896/飽18/汎0 在册闭域；**互指循环指针第二次在场**（V071 首见本篇坐实成系列）：ws notes「↑ 卷539#蟬」向上回指+539 本篇「{{:蟬 (李商隱)}}」向下转引（机器断言：notes 三连页全库恰三——蟬/錦瑟/韓碑；八句全唐诗语料全零——诗只活在诗页）；**壳侧作者消歧器首见**：锚「==[[蟬 (李商隱)|蟬]]==」+转引「{{:蟬 (李商隱)}}」全唐诗各恰一——消歧器第一次挂上壳侧且显示名仍裸（V059/V061 锚侧消歧/V062,V063 裸名/V067 同名裸锚反例/V069–V071 壳侧裸名——消歧谱补全壳侧一层）；消歧理由在册可查：ws 蟬名页恰三+全唐诗蟬字 83（539 内八=壳二+他诗六闭域档扫）；**零新建 source 连续第四首**（两源皆V018 所立，539 第七次复用）；正文第二引上限用满第二十例（V018 句读式疎/汎面在先+本迁移 ws 原样疏/泛面，各从其录，V018 句读式引文零重开断言）；**跨迁移异体分工首见**（V018 存疎/汎归一面、本快照存疏/泛面——同一页两次快照异体不同，逐行对读折叠判一致，双向断言）；**零标记页×100% 满级**（V069 同形第二例，与 V071 双{{另}}×100% 对照成谱：评级与异文多寡正交）+,**双转录句读分工首见**（Vtext 全裸/poem 全句读——夜雨寄北两侧皆裸的反面）+分类四行含作者分类（对照 V071 两行无）+「詠蟬詩」类目首见（全库恰二页：本篇+在獄詠蟬机器断言；非史料声明不升格 V048）；八句对蝉说话的第二人称形态照登；PERSON 旧传简化段首引一段（文思清丽庭筠过之——**段内清字恰一恰在笔底：史部给他的清在文章里，诗自己把清认领到门第上**；**段内题字十一项全零：写蝉的人传里无一蝉字**——V071 无一瑟字同款）；「无持操对举家清两部书各执一词」读法声明；V016/V066–V068/V070/V071 在册句零重开（域断言）；KNOWN 零如实记录（第廿八例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-011-person' AS id, 'BACKGROUND' AS entity_type, '011-person' AS slug, '这个人：清在笔底' AS title, '四层处境背景（阶段 D 第 53 首·八句七律 2/2/2/2）；史实句均有逐字引证；系年第四十七次判决（题证系列第卅五状·蟬无一字与清直恰二）「通鉴七十五卷连一个蟬字都没有；可它有清直，且两头都在人事的账上」——同字两界第十七形态·清直形态首见：通鉴蟬/蝉/鳴蟬/蜩/高難飽/費聲/疏欲/碧無情/梗猶/故園蕪已平/煩君/舉家清/薄宦全零（机器断言——咏物诗的物名史部全库不识）；「清直」恰二分長慶三年癸卯八二三（逢吉荐李绅清直宜居风宪——政敌递出去的梯子）与大中二年戊辰八四八（丁柔立以清直荐、德裕不能用、讼德裕冤、坐阿附贬南阳尉——还不清的代价）——**史部的清直两头都在人事的账上；诗的我亦舉家清不在任何账上**；「舉家」恰七闭域，廣明元年庚子八八〇鄭綦鄭系義不臣賊舉家自殺（赴死）+大曆八年癸丑七七三李建举家西归（拒位）——**史部的举家要么拒位要么赴死，诗的举家清是活着清**；清297/高896/飽18/汎0 在册闭域；**互指循环指针第二次在场**（V071 首见本篇坐实成系列）：ws notes「↑ 卷539#蟬」向上回指+539 本篇「{{:蟬 (李商隱)}}」向下转引（机器断言：notes 三连页全库恰三——蟬/錦瑟/韓碑；八句全唐诗语料全零——诗只活在诗页）；**壳侧作者消歧器首见**：锚「==[[蟬 (李商隱)|蟬]]==」+转引「{{:蟬 (李商隱)}}」全唐诗各恰一——消歧器第一次挂上壳侧且显示名仍裸（V059/V061 锚侧消歧/V062,V063 裸名/V067 同名裸锚反例/V069–V071 壳侧裸名——消歧谱补全壳侧一层）；消歧理由在册可查：ws 蟬名页恰三+全唐诗蟬字 83（539 内八=壳二+他诗六闭域档扫）；**零新建 source 连续第四首**（两源皆V018 所立，539 第七次复用）；正文第二引上限用满第二十例（V018 句读式疎/汎面在先+本迁移 ws 原样疏/泛面，各从其录，V018 句读式引文零重开断言）；**跨迁移异体分工首见**（V018 存疎/汎归一面、本快照存疏/泛面——同一页两次快照异体不同，逐行对读折叠判一致，双向断言）；**零标记页×100% 满级**（V069 同形第二例，与 V071 双{{另}}×100% 对照成谱：评级与异文多寡正交）+,**双转录句读分工首见**（Vtext 全裸/poem 全句读——夜雨寄北两侧皆裸的反面）+分类四行含作者分类（对照 V071 两行无）+「詠蟬詩」类目首见（全库恰二页：本篇+在獄詠蟬机器断言；非史料声明不升格 V048）；八句对蝉说话的第二人称形态照登；PERSON 旧传简化段首引一段（文思清丽庭筠过之——**段内清字恰一恰在笔底：史部给他的清在文章里，诗自己把清认领到门第上**；**段内题字十一项全零：写蝉的人传里无一蝉字**——V071 无一瑟字同款）；「无持操对举家清两部书各执一词」读法声明；V016/V066–V068/V070/V071 在册句零重开（域断言）；KNOWN 零如实记录（第廿八例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-011-scene' AS id, 'bg-011-scene' AS subject_id, 'context' AS property_key, '八句七律本文**第二引上限用满第二十例**：V018 句读式一引在先（「本以高難飽，……我亦舉家清。」——疎/汎面），本迁移二引 ws 页 poem 块**存原样**（疏/泛面，各从其录；生成时断言 V018 句读式引文不重开），此后正文对后来迁移关闭；**跨迁移异体分工首见**：V018 文本行存疎/汎（ws-fold 归一面）、本快照页存疏/泛——同一页两次快照异体不同，逐行对读折叠判一致（双向断言），异体只登记不裁决；**零标记页×100% 满级**（{{另}}/{{別}}/{{*}}/<ref>/{{reflist}}全零机器断言——V069 同形第二例，与 V071 双{{另}}×100% 对照成谱）；**双转录句读分工首见**（Vtext 全裸/poem 全句读）；分类四行含作者分类+「詠蟬詩」类目首见照登（V048 不升格）；八句对蝉说话的第二人称形态照登；系年零铸造。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-011-city' AS id, 'bg-011-city' AS subject_id, 'context' AS property_key, '**互指循环指针第二次在场**（V071 首见本篇坐实成系列）：ws notes「↑ 卷539#蟬」向上回指+539 本篇「{{:蟬 (李商隱)}}」向下转引（机器断言：notes 三连页全库恰三蟬/錦瑟/韓碑；八句全唐诗语料全零——诗只活在诗页）；**壳侧作者消歧器首见**：锚「==[[蟬 (李商隱)|蟬]]==」+转引「{{:蟬 (李商隱)}}」全唐诗各恰一——消歧器第一次挂上壳侧且显示名仍裸（V059/V061 卷页锚侧消歧/V062,V063 裸名/V067 同名裸锚反例/V069–V071 壳侧裸名——消歧谱补全壳侧一层）；消歧理由在册可查：ws 蟬名页恰三+全唐诗蟬字 83（539 内八=壳二+他诗六闭域）；**零新建 source 连续第四首**（两源皆 V018 所立，539 第七次复用）。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-011-world' AS id, 'bg-011-world' AS subject_id, 'context' AS property_key, '通鉴「蟬/蝉/鳴蟬/蜩/高難飽/費聲/疏欲/碧無情/梗猶/故園蕪已平/煩君/舉家清/薄宦」全零（机器断言——咏物诗的物名史部全库不识）而清与举家在他字：「清直」恰二分長慶三年癸卯八二三（逢吉荐李绅清直宜居风宪——政敌的梯子）与大中二年戊辰八四八（丁柔立以清直荐、德裕不能用、讼德裕冤、坐阿附贬南阳尉——还不清的代价）——**史部的清直两头都在人事的账上；诗的我亦舉家清不在任何账上**；「舉家」恰七闭域（廣明元年庚子八八〇鄭綦鄭系義不臣賊舉家自殺=赴死+大曆八年癸丑七七三李建举家西归=拒位——**史部的举家要么拒位要么赴死，诗的举家清是活着清**）（同字两界第十七形态·清直形态首见，audit 硬卡）；清297/高896/飽18/汎0 在册闭域零入引；certainty 不覆盖任何系年，time.span/event.name/written_during 零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-011-person' AS id, 'bg-011-person' AS subject_id, 'context' AS property_key, '旧传李商隐段（简化字录入照登原样）首引一段零域=「文思清丽，庭筠过之。」（传区间归属机器断言）；**段内「清」恰一恰在笔底**（机器断言）——史部给他的清在文章里（且庭筠过之），诗自己把清认领到门第上「我亦舉家清」（对照判决非因果）；「传说他无持操/诗说举家清——同一个人的清两部书各执一词」系读法声明；**段内题字十一项全零**（蟬/飽/費/斷/碧/蕪/煩/警/薄宦/故園/舉家——机器断言）**写蝉的人传里无一蝉字**（V071 无一瑟字同款）；V016/V066–V068/V070/V071 在册句零重开（域断言）；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-011-scene' AS subject_id, 'context' AS property_key, 'claim-bg-011-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-011-city' AS subject_id, 'context' AS property_key, 'claim-bg-011-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-011-world' AS subject_id, 'context' AS property_key, 'claim-bg-011-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-011-person' AS subject_id, 'context' AS property_key, 'claim-bg-011-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-011-scene' AS id, 'work-t300-011' AS work_id, 'SCENE' AS layer, '八句是一封写给蝉的回信（2/2/2/2 起两句入眼前层）：你因栖高所以难饱，白白空费鸣声（「本以高難飽，徒勞恨費聲。」——本诗对蝉说话，第二人称从第一句就开始）；五更鸣声疏得快要断，一树碧绿毫无情味（「五更疏欲斷，一樹碧無情。」）；薄宦如梗飘泛，故园荒秽已平（「薄宦梗猶泛，故園蕪已平。」）；劳你最能警我——我也举家清廉（「煩君最相警，我亦舉家清。」）。**咏物诗的对像开口了：**全诗八句句句是对蝉说——史部没有任何东西对李商隐开过口。ws 诗页：**零标记页×100% 满级**（{{另}}/{{別}}/{{*}}/<ref>/{{reflist}} 全零，机器断言——V069 寄令狐郎中满级无标记同形第二例，与 V071 錦瑟双{{另}}×100% 对照：评级度量转录完备，与异文多寡正交）；**双转录句读分工首见**：Vtext 行全裸无句读、poem 块全带句读（夜雨寄北两侧皆裸、寄令狐郎中 poem 无句读——本篇一裸一读=分工形态，照登不判）；**跨迁移异体分工**：V018 文本行存「五更疎欲斷／薄宦梗猶汎」（ws-fold 归一面），本快照 ws 页存「五更疏欲斷／薄宦梗猶泛」——同一页两次快照异体不同，逐行对读折叠判读法甲一致（生成时双向断言），异体只登记不裁决；分类四行**含作者分类**+「詠蟬詩」类目首见（对照 V071 錦瑟页两行无作者分类——分类行数本身也是形态；类目系整理者归类非史料声明不升格，V048 判例）。**此诗正文系第二引（上限用满第二十例）**：V018 已引句读式（「本以高難飽，……我亦舉家清。」——疎/汎面），本迁移二引 poem 块存原样（疏/泛面，各从其录；V018 句读式引文零重开，生成时硬断言）；此后此诗正文关闭。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-011-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-011-city' AS id, 'work-t300-011' AS work_id, 'CITY' AS layer, '卷539 侧把 V071 立的形态坐实成系列：**互指循环指针第二次在场**——ws notes 带「↑ [[全唐詩/卷539#蟬|全唐詩·卷五百三十九]]」向上回指，卷539 本篇正文恰是转引壳向下引回诗页（机器断言：notes 三连一行页全库恰三——蟬/錦瑟/韓碑，本页与韓碑同形；壳外全卷无本篇一行——八句全唐诗语料全零）。本篇新增一层：**壳侧作者消歧器首见**——锚是「==[[蟬 (李商隱)|蟬]]==」，转引是「{{:蟬 (李商隱)}}」：**消歧器第一次出现在壳侧**（V059 作者消歧在卷页锚、V061 首句消歧在卷页锚、V062/V063 裸名、V067 同名裸锚反例、V069–V071 壳侧皆裸名——本篇壳侧带消歧器，显示名仍裸「蟬」；机器断言锚与转引全唐诗各恰一）。**消歧理由在册可查**：ws 库蟬名页恰三（在獄詠蟬/塞下曲「蟬鳴空桑林」/本篇），《全唐诗》蟬字八十三处（539 卷内八处=壳二+他诗六：韓翃「蟬是怨齊王」/李商隱《桂林路中作》「空餘蟬嘒嘒」/自《柳》「已帶斜陽又帶蟬」等——闭域档扫）：同名风险真实存在，壳侧才挂了消歧器。**零新建 source 连续第四首**：source-ws-t300-011 与 source-quantangshi-539 皆 V018 所立，539 第七次复用——壳本身就是证据，带消歧器的壳是更重的证据。（本层零 relation。）' AS body_text, 'JUNIOR' AS audience, 'claim-bg-011-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-011-world' AS id, 'work-t300-011' AS work_id, 'WORLD' AS layer, '**通鉴七十五卷连一个「蟬」字都没有；可它有清直，且清直两头都在人事的账上**（同字两界第十七形态·清直形态首见）：通鉴「**蟬/蝉/鳴蟬/蜩/高難飽/費聲/疏欲/碧無情/梗猶/故園蕪已平/煩君/舉家清/薄宦**」全零（机器断言）——咏物诗的物名史部全库不识，题字「蟬」连字面都不进。可通鉴不是没有清与举家：① 「**清直**」恰二：長慶三年（癸卯，八二三）李逢吉患李紳排抑自己，「**會御史中丞缺，逢吉薦紳清直，宜居風憲之地。上以中丞亦次對官，不疑而可之**」——荐完就把他与韩愈挤去外任；又大中二年（戊辰，八四八）「**初，李德裕執政，有薦丁柔立清直可任諫官者，德裕不能用……德裕貶潮州，柔立上疏訟其冤。丙寅，坐阿附貶南陽尉**」——当年以清直被荐、后来为贬官的前宰相喊冤，贬回去当尉。「**史部的清直两头都在人事的账上：一头是政敌递出去的梯子，一头是还不清的代价**；诗的「我亦舉家清」不在任何账上——一家人在薄宦里清着，蝉是证人；② 「**舉家**」恰七（闭域档扫），最近诗面的两条：廣明元年（庚子，八八〇）黄巢入京「**將作監鄭綦、庫部郎中鄭系義不臣賊，舉家自殺**」；大曆八年（癸丑，七七三）李忠臣子建拒被拥立「**建誓死不從，舉家西歸**」——**史部的举家要么拒位要么赴死；诗的举家清是活着清**（「薄宦梗猶泛」——漂着的清）。题字侧「清」恰二百九十七/「高」恰八百九十六/「飽」恰十八在册零入引（闭域档扫）；异体「汎」通鉴全零（V018 面的异体在史部无位置）。本层零铸造零 relation。' AS body_text, 'SENIOR' AS audience, 'claim-bg-011-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-011-person' AS id, 'work-t300-011' AS work_id, 'PERSON' AS layer, '旧传李商隐段（**简化字录入**，V016 locator 同款标注，引文照登简体原样）首引一段（零域）：「**文思清丽，庭筠过之。**」
传里唯一一个「清」字（机器断言：段内「清」恰一）恰在**笔底**——文思清丽，而且还不全是他的：温庭筠超过他。**史部给这个人的清在文章里；诗自己把清认领到门第上**：「我亦舉家清」——一家人的清，不是文思的清（对照判决，非史实因果）。紧接着史臣自断：「而俱无持操，恃才诡激，为当涂者所薄。名宦不进，坎壈终身。」（V066/V067/V068 在册零重开，域断言）——**传说他无持操，诗说举家清；同一个人的清，两部书各执一词**（读法声明：诗不自证操守，史不裁诗）。
**段内题字零**：蟬/飽/費/斷/碧/蕪/煩/警/薄宦/故園/舉家全零（机器断言）——**写蝉的人，传里无一蝉字**（V071「写尽锦瑟的人传里无一瑟字」同款，蝉是题面通名比瑟更冷）；「举家清」的举家在传里只剩官历（V016 在册句零重开）。本诗 ws 页 notes 有回指注（与 V071 同形）；certainty 不覆盖任何系年，诗 time.span/event.name/written_during 仍零铸造（audit 硬卡）。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-011-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文 ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-011-scene' AS claim_id, 'source-ws-t300-011' AS source_id, '页面 蟬（《唐詩三百首》第 11 首选本页，页题裸名；title+author+Vtext 首行裸面+poem 块以「……」相连——**双转录句读分工首见**：Vtext 行全裸无句读、poem 块全带句读；poem 块存原样：八句疏/泛面（V018 文本行系疎/汎归一面——跨迁移异体分工，各从其录，逐行对读折叠判一致生成时双向断言）；零标记×100% 满级（{{另}}/{{別}}/{{*}}/<ref>/{{reflist}} 全零机器断言）；正文第二引上限用满第二十例（V018 句读式一引在先，本迁移引原样面，生成时断言 V018 句读式引文不重开）' AS locator, '| title    = 蟬……| author   = 李商隱……{{VtextStart}}本以高難飽{{VtextEnd}}……本以高難飽，徒勞恨費聲。
五更疏欲斷，一樹碧無情。
薄宦梗猶泛，故園蕪已平。
煩君最相警，我亦舉家清。
</poem>' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-011-city' AS claim_id, 'source-quantangshi-539' AS source_id, '卷五百三十九·李商隱《蟬》**消歧壳转引块**（「==[[蟬 (李商隱)|蟬]]==」+「{{:蟬 (李商隱)}}」——**壳侧作者消歧器首见**：消歧器第一次挂上壳侧且显示名仍裸「蟬」（V059/V061 锚侧/V062,V063 裸名/V067 反例/V069–V071 壳侧裸名——消歧谱补全壳侧一层；机器断言锚与转引全唐诗各恰一）；壳外全卷无本篇一行（八句全唐诗语料全零；卷内蟬八处=壳二+他诗六闭域）；**与本页 notes ↑回指互指**（V071 首见本篇第二次在场——循环指针成系列）；源行系 V018 已立、本迁移第七次复用零新建）' AS locator, '==[[蟬 (李商隱)|蟬]]==
{{:蟬 (李商隱)}}' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-011-city' AS claim_id, 'source-ws-t300-011' AS source_id, '页面 蟬（notes 三连一行整值入引（{{唐詩三百首}}+{{Textquality|100%}}+↑底本回指同挤一值——与錦瑟/韓碑同形全库恰三页机器断言；↑ 指向恰是转引本篇的 539 消歧壳——互指之诗页侧）+分类四行连片（**含作者分类 [[Category:李商隱]]**——对照 V071 錦瑟页两行无作者分类，分类行数本身也是形态；「詠蟬詩」类目首见照登——全库恰二页：本篇+在獄詠蟬机器断言；分类行系整理者分类动作：非史料声明、不升格，V048 判例）；本迁移零新建源连续第四首）' AS locator, '| notes    = {{唐詩三百首}}{{Textquality|100%}}↑ [[全唐詩/卷539#蟬|全唐詩·卷五百三十九]]……[[Category:李商隱]]
[[Category:唐诗]]
[[Category:唐詩三百首|李]]
[[Category:詠蟬詩]]' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-011-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '卷二百四十三·長慶三年（癸卯，八二三）逢吉荐李绅清直段（「宜居風憲之地…不疑而可之」——清直作政敌的梯子）……卷二百四十八·大中二年（戊辰，八四八）丁柔立案（荐以清直/德裕不能用/讼德裕冤/坐阿附貶南陽尉——清直者贬回去）……卷二百五十四·廣明元年（庚子，八八〇）鄭綦鄭系「義不臣賊，舉家自殺」段（举家赴义）……卷二百二十四·大曆八年（癸丑，七七三）李建「舉家西歸」段（举家拒位）；通鉴蟬/蝉/鳴蟬/蜩及诗面语全零（咏物诗物名不识），清直恰二/舉家恰七（四段逐字入引为判决证据）' AS locator, '會御史中丞缺，逢吉薦紳清直，宜居風憲之地。上以中丞亦次對官，不疑而可之。……初，李德裕執政，有薦丁柔立清直可任諫官者，德裕不能用。上即位，柔立為右補闕。德裕貶潮州，柔立上疏訟其冤。丙寅，坐阿附貶南陽尉。……將作監鄭綦、庫部郎中鄭系義不臣賊，舉家自殺。……建誓死不從，舉家西歸。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-011-person' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書卷一九〇下·李商隱（**简化字录入**照登原样，V016 locator 同款标注）（「文思清丽，庭筠过之」段（段内「清」字恰一恰在笔底——传的清在文章里；全库查重恰零域首引；传区间归属机器断言；段内题字蟬/飽/費/斷/碧/蕪/煩/警/薄宦/故園/舉家全零——写蝉的人传里无一蝉字；「无持操对举家清各执一词」系读法声明；V016/V066–V068/V070/V071 在册句零重开）' AS locator, '文思清丽，庭筠过之。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（八句七律 2/2/2/2 顺次） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-011-scene' AS background_id, 'text-work-t300-011-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-011-scene' AS background_id, 'text-work-t300-011-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-011-city' AS background_id, 'text-work-t300-011-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-011-city' AS background_id, 'text-work-t300-011-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-011-world' AS background_id, 'text-work-t300-011-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-011-world' AS background_id, 'text-work-t300-011-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-011-person' AS background_id, 'text-work-t300-011-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-011-person' AS background_id, 'text-work-t300-011-ws' AS version_id, 8 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 72, 'Li Shang-yin''s Cicada (work-t300-011) background layers (stage-D poem 53, eight-line regulated verse 2/2/2/2): dating verdict forty-seven, thirty-fifth shape of the title-evidence series -- not one graph of the cicada in all seventy-five juan of the Tongjian, yet the histories have "pure and upright" (qingzhi) exactly twice, and both times on the payroll of office-seeking. Same-character-two-realms, seventeenth shape: the qingzhi shape, first seen. The Tongjian scores zero on cicada, the simplified cicada, sounding cicada, tiao (the old word), and on every phrase of the poem -- "built high, hard to be full", "wasting one''s cry", "sparse near to snapping", "one tree, green and heartless", "thin office, like driftwood still afloat", "the old garden, weeds leveled flat", "troubling you, most alerting me", "I too, my whole household pure" -- the object of the thing-poem is not even a word the histories recognize. Yet qingzhi appears exactly twice, and both times inside personnel politics: in Changqing 3, guimao, 823, Li Fengji, troubled by Li Shen''s strictures, "recommended Shen as pure and upright, fit to occupy the post of Censor-in-Chief; the emperor, taking the office likewise one of attested rank, suspected nothing and approved" -- a ladder handed to a rival, and Shen was shunted to Jiangxi within months; and in Dazhong 2, wuchen, 848: "at first, when Li Deyu was in government, one recommended Ding Rouli as pure and upright, fit for a remonstrance office; Deyu could not use him... after Deyu was demoted to Chaozhou, Rouli memorialized in plead his injustice; on bingyin, for fawning attachment he was demoted to County Commandant of Nanyang" -- the man certified pure and upright pays for defending the man who had refused him: the histories'' purity sits on either end of an office ledger, a political ladder or an unpaid debt; the poem''s "I too, my whole household pure" sits on no ledger at all. "Whole household" (jüjia) appears exactly seven times (closed-set archive), the two nearest the poem: in Guangming 1, gengzi, 880, when Chang''an fell, "Zheng Qi and Zheng Xi, deeming it unrighteous to serve the rebel, killed themselves, whole household together" -- a household that dies for purity; and in Dali 8, guichou, 773, when the soldiers tried to proclaim Li Jian after his father''s death, "Jian swore he would not obey, and led his whole household west back home" -- a household that refuses office: the histories'' whole households either die or refuse; the poem''s whole household is pure while living, afloat in a thin post with the cicada as its only witness. The mutual-pointer binding, first seen in V071, recurs here and becomes a series: the ws page''s notes carry the up-arrow back-reference to 卷539#蟬 while the scroll page''s text is the transclusion stub pointing back (machine-asserted: exactly three pages in the whole ws corpus carry this 539 notes triple -- Cicada, Inscribed Harps, Han Stele; all eight lines of the poem score zero across the Quan Tangshi corpus -- the text lives only on the poem page). New in this poem: the first time the stub itself wears an author-disambiguator -- the anchor is "==[[蟬 (李商隱)|蟬]]==" and the transclusion "{{:蟬 (李商隱)}}", machine-asserted each unique in the whole Quan Tangshi -- the disambiguator climbs onto the shell side for the first time (V059/V061 anchored it scroll-side, V062/V063 sat bare, V067 proved a bare twin-anchor can fail to disambiguate, V069-V071 shells were bare), while the display name stays bare 蟬. Why a disambiguator is warranted is on the record: exactly three cicada-named ws pages and 83 cicada graphs in the Quan Tangshi (eight inside juan 539: two in the shell plus six in other poems -- closed set). ZERO new sources, fourth poem running (audit asserts zero poetry_source INSERT and zero source deletion); both sources date from V018, the 539 source at its seventh reuse. Body use-ceiling reached, twentieth instance: V018 quoted the punctuated abbreviation built from the folded-variant reading (with graphs shu-variant/fan-variant); this migration quotes the ws page''s raw poem block in the graph forms the live page now carries (shu/fan) -- a cross-migration variant division of labor never before seen (one page, two snapshots, two graph sets; line-by-line collation confirms the fold reading; generator asserts both sides and that V018''s punctuated excerpt is never re-used); the body is now closed. The page is a zero-mark 100 percent page (no variant braces, no refs, no reflist -- machine-asserted; second specimen of V069''s满-level shape, and with V071''s double-brace 100 percent page it completes the orthogonality of rating and variant count); the dual transcription divides punctuation labor for the first time (Vtext lines bare, poem block fully punctuated -- the inverse of the Night Rain page where both sides run bare); the category footer is four lines and includes the author category (against V071''s two-line author-less footer -- the line count itself is the form) with the 詠蟬詩 (poems-on-cicadas) tag, first seen, exactly two such category pages in the corpus (machine-asserted; editorial, not a source claim, not upgraded, V048 precedent); the eight lines all speak to the cicada in the second person -- logged as form. PERSON first-cites one zero-domain simplified JTS passage -- "his writing was pure and beautiful; Tingyun surpassed him" -- the one and only "pure" graph in the whole biography segment (machine-asserted), and it sits in his prose style, not his household, and is even rated below Wen Tingyun''s; the histories put his purity in the writing while the poem claims it for the whole household, and the same historian elsewhere calls him unprincipled (V068 closed) -- two books hold rival verdicts on one man''s purity; readings declared, not facts; the segment holds none of the eleven title-side graphs -- the man who wrote the cicada leaves not one cicada-graph in his biography (same shape as V068''s no-immortal-graph, V071''s no-harp-graph). KNOWN zero honestly recorded (twenty-eighth instance, audit reverse-asserts); closed precedent keywords (including V016''s Lingbiao years and V018''s punctuated cicada and old-garden lines) stay out of citations'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 72);
COMMIT;
