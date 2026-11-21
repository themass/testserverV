-- V073：李商隱《風雨》(work-t300-015) 四层背景（阶段 D 第 54 首·风雨两界）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V014、V015、V016、V018、V026、V033、V035、V039、V048、V053、V057、
--       V058、V059、V060、V061、V062、V063、V064、V065、V066、V067、V068、V069、V070、
--       V071、V072 已执行
--       （work-t300-015 与其 text-work-t300-015-ws（version_code=ws-raw，八行带句读，
--       与本快照 ws 页 poem 块逐字同面零分歧——与 V072 的 ws-fold 异体分工恰成对照组）
--       与其源 source-ws-t300-015（edition 字段即底本「全唐詩」）都是 V018 的行；
--       source-quantangshi-539 是 V018 已立的卷539 卷页源（V018/V067/V068/V069/V070/
--       V071/V072 已引，本迁移第八次复用——这次引到的是消歧壳+杜司勳注锚两块）；
--       source-zizhi-tongjian-events 是 V014/V015 已立的通鉴事件源；
--       source-jiutangshu-wenyuan 是 V016 已立的旧唐书文苑传源（李商隐传在此，简化字录入）；
--       判例在册句（义山/开成二年/岭表/三十六体/未几病卒/大中末/仲郢坐/还郑州 V016、
--       绹不之省/坎壈终身 V066/V067、以所业文干之/下笔不能自休 V067、恃才诡激/
--       为当涂者所薄 V068、惟山陵使長而多髯/次子綯有才器/背恩 V069、锦瑟句读式正文与
--       灞上秋居风雨 V018、春晓风雨 V053、{{:蟬 (李商隱)}}/↑…蟬 V072、{{:錦瑟}}/
--       ↑…錦瑟 V071、{{:夜雨寄北}}/↑…寄令狐郎中 V069/V070、文思清丽/庭筠过之 V072、
--       逢吉薦紳清直/丁柔立/義不臣賊/舉家西歸 V072）只对照不重开。
--       **本迁移零新建 source（连续第五首）——
--       audit 断言本文件零 poetry_source INSERT、回滚零 source 删除。**
--
-- 数据源（可复现）：emit_v073.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/風雨__李商隱_.txt（五成页首见+零标记页（正交第三枚标本）+Vtext 裸/poem 句读
--   双转录分工第二次+与 V018 零分歧面（ws-raw 对 ws-raw 八行双向断言）+notes 三连五成居首
--   （「{{唐詩三百首}}↑」相邻全库恰一页）+分类三行（2/3/4 行三形态齐）+无 times/type/from）、
--   全唐詩卷539（锚 ==[[風雨 (李商隱)|風雨]]== 与 {{:風雨 (李商隱)}} 各全唐诗唯一（机器断言）+
--   壳外全卷无本篇一行（八句全库零）+==[[杜司勳]]{{*|牧}}== 恰一（作者注挂锚首见）+
--   哭劉蕡块与杜司勳块直接相接恰一（卷页并置）+風/春風味壳各恰一闭域）、
--   舊唐書卷190下（李商隐段首引一段+段内题字二十一项全零+干恰二+段边界断言）、
--   通鑑卷202/211/248/254（风雨四段逐字入引+年标题窗口：永隆元年六八〇/開元三年七一五/
--   大中元年八四七/中和二年八八二）+卷213 吐蕃乞复旧好段入引（開元十八年七三〇窗口）
--   +卷193 马周段无酒无新豐断言+
--   通鑑 75 卷负证计数扫描（風雨恰九闭域 202/204/210/211/248/250/254/257/261+舊好恰六+
--   新豐恰九而新豐酒零+寶劍恰二+郭震恰一+青樓/管絃/薄俗/新知/淒涼/羈泊/銷愁/斗幾千全零）+
--   既有迁移引文域逐句查重——传区间归属、二引/零重开/首引零域前提全部生成时断言。
--
-- 做：4 BACKGROUND content/claim/background + 5 组逐字引用（(claim,source) 主键每对恰一行）+
--   8 background_line（八句五律 **2/2/2/2 顺次**：scene→1,2 city→3,4 world→5,6 person→7,8，
--   绑 text-work-t300-015-ws 的 8 行）+ 不碰 poetry_text_line。
-- 不做：**不新建任何 source（连续第五首）**；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「史部的风雨各有落主；诗的风雨不落在任何人的账上」）：
--   * 「风雨两界」「旧好两界」系通鉴五段逐字入引支撑的对照判决，非史实因果——通鉴不记这首诗；
--     亦不考本诗系年（编年诸说一律不采信不铸造）；
--   * 「令狐家门第在此雨里定下」「史书里只剩敲门的两下」标明读法声明；
--   * 大中元年风雨对答与诗作者本人无涉——令狐楚是令狐绹之父，只作门第背景读法不作因果；
--   * 正文第二引上限用满：V018 句读式一引在先，本迁移引 ws 页 poem 块存原样面——
--     同面各从其录，V018 句读式引文不重开（生成时硬断言），此后此诗正文关闭；
--   * 「作者注挂锚首见」「卷页并置」「五成页首见」「三形态齐」均照登不判；
--   * 分类三行系整理者动作：非史料声明、不升格，V048 判例；
--   * 通鉴風雨恰九闭域档扫（204 倪斌疏/210 宋务光疏/250 田牟犒军/257 大风雨/261 大风雨
--     震电五处不入引，只计数）；
--   * KNOWN 零如实记录（第廿九例，audit 反向断言 SQL 无 KNOWN 字面量）；
--   * V011/V016/V018/V026/V033/V035/V039/V053/V063/V066–V072 已引诸句只对照不重开。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 72，不含 73
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-015-%';             -- 空
--   SELECT id FROM poetry_source WHERE id IN ('source-ws-t300-015','source-quantangshi-539');
--    -- 两行（均 V018 所立，本迁移不新建）
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-015-ws';  -- 恰 8
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-015-%';       -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-015';                                  -- 8（2/2/2/2）
--   SELECT certainty FROM poetry_claim WHERE id LIKE 'claim-bg-015-%';  -- 四行全 LIKELY
--   SELECT COUNT(*) FROM poetry_source WHERE id='source-ws-t300-015';   -- 恰 1（V018 所立）
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-015'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-015';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-015-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
-- 回滚: recovery/V073_rollback.sql（按 id 全枚举删除；**零 source 删除**——
--   source-ws-t300-015 与 source-quantangshi-539 皆 V018 所立，绝不删）
START TRANSACTION;

-- ---------- 0. 零新建 source（连续第五首；两源皆 V018 所立复用） ----------

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-015-scene' AS id, 'BACKGROUND' AS entity_type, '015-scene' AS slug, '眼前：借来的剑篇' AS title, '四层处境背景（阶段 D 第 54 首·八句五律 2/2/2/2）；史实句均有逐字引证；系年第四十八次判决（题证系列第卅六状·风雨落主与旧好无账）「通鉴的风雨每一处都有落主；诗的黃葉仍風雨不落在任何人的账上」——同字两界第十八形态·风雨形态首见：通鉴風雨恰九（202/204/210/211/248/250/254/257/261 闭域，机器断言）四段落主：裴行儉移营避雨（将令）、盧懷慎所居不蔽雨（屋顶）、宣宗忆宪宗之喪风雨独令狐楚攀灵驾（忠勤赏价——令家门第在此雨定下）、吕用之呵叱风雨（骗术）；**诗的「黃葉仍風雨」不落在任何人的账上**；「舊好」恰六（213/222/232/250/253/264 闭域）**全部是国与镇之间复盟修好，无一字落在朋友身上**——诗的「舊好隔良緣」隔的是令狐绹：邦交之好有账，故人之好无账；青樓/管絃/薄俗/新知/淒涼/羈泊/銷愁/斗幾千 通鉴全零在册闭域；新豐恰九全是地名人名而**新豐酒零**、馬周恰十五全在官迹无一杯酒、寶劍恰二无一剑篇事——诗借的典故史部只借出地名人名；**互指循环指针第三次在场成连续系列**（↑ 回指+{{:風雨 (李商隱)}} 转引；539 回指页闭域恰五：寄令狐郎中/蟬/錦瑟/韓碑/風雨）；**壳侧作者消歧器第二次在场**（V072 首见成常规）+**整理者作者注挂锚首见**（==[[杜司勳]]{{*|牧}}== 恰一）+**卷页并置机器断言**（哭劉蕡块与杜司勳块直接相接恰一——选本把李商隱哭刘蕡和杜牧读他的高楼风雨放在同一个换行上下；「高樓風雨感斯文」全唐诗恰一）；**零新建 source 连续第五首**（两源皆V018 所立，539 第八次复用）；正文第二引上限用满第二十一例（V018 句读式一引在先+本迁移 poem 原样面，同面各从其录，V018 句读式引文零重开断言）；**跨迁移零分歧面**（ws-raw 对 ws-raw 八行逐字同面——与 V072 异体分工恰成对照组，生成时双向断言）；**五成页首见**（{{Textquality|50%}}——已落九首李商隱页无此级；TQ 谱 50:92/75:142/100:26 闭域）+**零标记页×五成**（正交第三枚标本）；notes 排序谱第三态（「{{唐詩三百首}}↑」相邻全库恰一页）；分类三行（2/3/4 行三形态齐——分类行数即形态，不升格 V048）；PERSON 旧传简化段首引一段（复以文章干襜——段内干字恰二谱：干之在册/干襜首引；**段内题字二十一项全零：写风雨的人传里无一风雨字**——V068/V071/V072 同款第四枚；无持操在册零重开；「史书里只剩敲门的两下」读法声明）；V016/V018/V053/V066–V072 在册句零重开（域断言）；KNOWN 零如实记录（第廿九例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-015-city' AS id, 'BACKGROUND' AS entity_type, '015-city' AS slug, '这座城：同页并置的两案风雨' AS title, '四层处境背景（阶段 D 第 54 首·八句五律 2/2/2/2）；史实句均有逐字引证；系年第四十八次判决（题证系列第卅六状·风雨落主与旧好无账）「通鉴的风雨每一处都有落主；诗的黃葉仍風雨不落在任何人的账上」——同字两界第十八形态·风雨形态首见：通鉴風雨恰九（202/204/210/211/248/250/254/257/261 闭域，机器断言）四段落主：裴行儉移营避雨（将令）、盧懷慎所居不蔽雨（屋顶）、宣宗忆宪宗之喪风雨独令狐楚攀灵驾（忠勤赏价——令家门第在此雨定下）、吕用之呵叱风雨（骗术）；**诗的「黃葉仍風雨」不落在任何人的账上**；「舊好」恰六（213/222/232/250/253/264 闭域）**全部是国与镇之间复盟修好，无一字落在朋友身上**——诗的「舊好隔良緣」隔的是令狐绹：邦交之好有账，故人之好无账；青樓/管絃/薄俗/新知/淒涼/羈泊/銷愁/斗幾千 通鉴全零在册闭域；新豐恰九全是地名人名而**新豐酒零**、馬周恰十五全在官迹无一杯酒、寶劍恰二无一剑篇事——诗借的典故史部只借出地名人名；**互指循环指针第三次在场成连续系列**（↑ 回指+{{:風雨 (李商隱)}} 转引；539 回指页闭域恰五：寄令狐郎中/蟬/錦瑟/韓碑/風雨）；**壳侧作者消歧器第二次在场**（V072 首见成常规）+**整理者作者注挂锚首见**（==[[杜司勳]]{{*|牧}}== 恰一）+**卷页并置机器断言**（哭劉蕡块与杜司勳块直接相接恰一——选本把李商隱哭刘蕡和杜牧读他的高楼风雨放在同一个换行上下；「高樓風雨感斯文」全唐诗恰一）；**零新建 source 连续第五首**（两源皆V018 所立，539 第八次复用）；正文第二引上限用满第二十一例（V018 句读式一引在先+本迁移 poem 原样面，同面各从其录，V018 句读式引文零重开断言）；**跨迁移零分歧面**（ws-raw 对 ws-raw 八行逐字同面——与 V072 异体分工恰成对照组，生成时双向断言）；**五成页首见**（{{Textquality|50%}}——已落九首李商隱页无此级；TQ 谱 50:92/75:142/100:26 闭域）+**零标记页×五成**（正交第三枚标本）；notes 排序谱第三态（「{{唐詩三百首}}↑」相邻全库恰一页）；分类三行（2/3/4 行三形态齐——分类行数即形态，不升格 V048）；PERSON 旧传简化段首引一段（复以文章干襜——段内干字恰二谱：干之在册/干襜首引；**段内题字二十一项全零：写风雨的人传里无一风雨字**——V068/V071/V072 同款第四枚；无持操在册零重开；「史书里只剩敲门的两下」读法声明）；V016/V018/V053/V066–V072 在册句零重开（域断言）；KNOWN 零如实记录（第廿九例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-015-world' AS id, 'BACKGROUND' AS entity_type, '015-world' AS slug, '这个天下：各有落主的风雨' AS title, '四层处境背景（阶段 D 第 54 首·八句五律 2/2/2/2）；史实句均有逐字引证；系年第四十八次判决（题证系列第卅六状·风雨落主与旧好无账）「通鉴的风雨每一处都有落主；诗的黃葉仍風雨不落在任何人的账上」——同字两界第十八形态·风雨形态首见：通鉴風雨恰九（202/204/210/211/248/250/254/257/261 闭域，机器断言）四段落主：裴行儉移营避雨（将令）、盧懷慎所居不蔽雨（屋顶）、宣宗忆宪宗之喪风雨独令狐楚攀灵驾（忠勤赏价——令家门第在此雨定下）、吕用之呵叱风雨（骗术）；**诗的「黃葉仍風雨」不落在任何人的账上**；「舊好」恰六（213/222/232/250/253/264 闭域）**全部是国与镇之间复盟修好，无一字落在朋友身上**——诗的「舊好隔良緣」隔的是令狐绹：邦交之好有账，故人之好无账；青樓/管絃/薄俗/新知/淒涼/羈泊/銷愁/斗幾千 通鉴全零在册闭域；新豐恰九全是地名人名而**新豐酒零**、馬周恰十五全在官迹无一杯酒、寶劍恰二无一剑篇事——诗借的典故史部只借出地名人名；**互指循环指针第三次在场成连续系列**（↑ 回指+{{:風雨 (李商隱)}} 转引；539 回指页闭域恰五：寄令狐郎中/蟬/錦瑟/韓碑/風雨）；**壳侧作者消歧器第二次在场**（V072 首见成常规）+**整理者作者注挂锚首见**（==[[杜司勳]]{{*|牧}}== 恰一）+**卷页并置机器断言**（哭劉蕡块与杜司勳块直接相接恰一——选本把李商隱哭刘蕡和杜牧读他的高楼风雨放在同一个换行上下；「高樓風雨感斯文」全唐诗恰一）；**零新建 source 连续第五首**（两源皆V018 所立，539 第八次复用）；正文第二引上限用满第二十一例（V018 句读式一引在先+本迁移 poem 原样面，同面各从其录，V018 句读式引文零重开断言）；**跨迁移零分歧面**（ws-raw 对 ws-raw 八行逐字同面——与 V072 异体分工恰成对照组，生成时双向断言）；**五成页首见**（{{Textquality|50%}}——已落九首李商隱页无此级；TQ 谱 50:92/75:142/100:26 闭域）+**零标记页×五成**（正交第三枚标本）；notes 排序谱第三态（「{{唐詩三百首}}↑」相邻全库恰一页）；分类三行（2/3/4 行三形态齐——分类行数即形态，不升格 V048）；PERSON 旧传简化段首引一段（复以文章干襜——段内干字恰二谱：干之在册/干襜首引；**段内题字二十一项全零：写风雨的人传里无一风雨字**——V068/V071/V072 同款第四枚；无持操在册零重开；「史书里只剩敲门的两下」读法声明）；V016/V018/V053/V066–V072 在册句零重开（域断言）；KNOWN 零如实记录（第廿九例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-015-person' AS id, 'BACKGROUND' AS entity_type, '015-person' AS slug, '这个人：传里无一风雨字' AS title, '四层处境背景（阶段 D 第 54 首·八句五律 2/2/2/2）；史实句均有逐字引证；系年第四十八次判决（题证系列第卅六状·风雨落主与旧好无账）「通鉴的风雨每一处都有落主；诗的黃葉仍風雨不落在任何人的账上」——同字两界第十八形态·风雨形态首见：通鉴風雨恰九（202/204/210/211/248/250/254/257/261 闭域，机器断言）四段落主：裴行儉移营避雨（将令）、盧懷慎所居不蔽雨（屋顶）、宣宗忆宪宗之喪风雨独令狐楚攀灵驾（忠勤赏价——令家门第在此雨定下）、吕用之呵叱风雨（骗术）；**诗的「黃葉仍風雨」不落在任何人的账上**；「舊好」恰六（213/222/232/250/253/264 闭域）**全部是国与镇之间复盟修好，无一字落在朋友身上**——诗的「舊好隔良緣」隔的是令狐绹：邦交之好有账，故人之好无账；青樓/管絃/薄俗/新知/淒涼/羈泊/銷愁/斗幾千 通鉴全零在册闭域；新豐恰九全是地名人名而**新豐酒零**、馬周恰十五全在官迹无一杯酒、寶劍恰二无一剑篇事——诗借的典故史部只借出地名人名；**互指循环指针第三次在场成连续系列**（↑ 回指+{{:風雨 (李商隱)}} 转引；539 回指页闭域恰五：寄令狐郎中/蟬/錦瑟/韓碑/風雨）；**壳侧作者消歧器第二次在场**（V072 首见成常规）+**整理者作者注挂锚首见**（==[[杜司勳]]{{*|牧}}== 恰一）+**卷页并置机器断言**（哭劉蕡块与杜司勳块直接相接恰一——选本把李商隱哭刘蕡和杜牧读他的高楼风雨放在同一个换行上下；「高樓風雨感斯文」全唐诗恰一）；**零新建 source 连续第五首**（两源皆V018 所立，539 第八次复用）；正文第二引上限用满第二十一例（V018 句读式一引在先+本迁移 poem 原样面，同面各从其录，V018 句读式引文零重开断言）；**跨迁移零分歧面**（ws-raw 对 ws-raw 八行逐字同面——与 V072 异体分工恰成对照组，生成时双向断言）；**五成页首见**（{{Textquality|50%}}——已落九首李商隱页无此级；TQ 谱 50:92/75:142/100:26 闭域）+**零标记页×五成**（正交第三枚标本）；notes 排序谱第三态（「{{唐詩三百首}}↑」相邻全库恰一页）；分类三行（2/3/4 行三形态齐——分类行数即形态，不升格 V048）；PERSON 旧传简化段首引一段（复以文章干襜——段内干字恰二谱：干之在册/干襜首引；**段内题字二十一项全零：写风雨的人传里无一风雨字**——V068/V071/V072 同款第四枚；无持操在册零重开；「史书里只剩敲门的两下」读法声明）；V016/V018/V053/V066–V072 在册句零重开（域断言）；KNOWN 零如实记录（第廿九例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-015-scene' AS id, 'bg-015-scene' AS subject_id, 'context' AS property_key, '首联「淒涼寶劍篇，羈泊欲窮年」：借郭震剑篇开自己的场，第二句自陈羁泊经年——通鉴郭震恰一（劾相页）、剑篇零，新豐酒零、传段无一字酒（机器断言闭域）；ws 页五成级首见（已落九首李商隱页无此级）+零标记页（正交第三枚标本）；Vtext 裸/poem 句读双转录分工第二次在场+跨迁移零分歧面（与 V072 异体分工成对照组）' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-015-city' AS id, 'bg-015-city' AS subject_id, 'context' AS property_key, '互指循环指针第三次在场（↑ 回指+{{:風雨 (李商隱)}} 转引，539 回指页闭域恰五）；壳侧消歧器第二次在场+**整理者作者注挂锚首见**（==[[杜司勳]]{{*|牧}}== 恰一）；**卷页并置**：哭劉蕡块与杜司勳块直接相接恰一——选本把两案风雨排在同一换行上下；八句全唐诗语料全零；notes 排序谱第三态（「{{唐詩三百首}}↑」相邻全库恰一页）；分类三行（2/3/4 行三形态齐）；零新建 source 连续第五首' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-015-world' AS id, 'bg-015-world' AS subject_id, 'context' AS property_key, '通鉴風雨恰九（闭域 202/204/210/211/248/250/254/257/261）且各有落主（将令/屋顶/忠勤赏价/骗术——四段逐字入引）；**旧好恰六全在邦交**（213/222/232/250/253/264闭域，无一字落在朋友身上；開元十八年吐蕃乞复旧好段入引）——同字两界第十八形态·风雨形态首见：史部风雨各有落主，诗的黃葉仍風雨不落在任何人的账上；旧好两界：邦交之好有账，故人之好无账' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-015-person' AS id, 'bg-015-person' AS subject_id, 'context' AS property_key, '旧传简化字段首引「府罢入朝，复以文章干襜，乃补太学博士」——段内干字恰二谱（干之在册零重开/干襜首引）；**段内题字二十一项全零：写风雨的人传里无一风雨字**（V068/V071/V072 同款第四枚）；通鉴馬周恰十五无酒杯、新豐恰九无新豐酒——诗要销愁的酒，史部只借出地名；「无持操/坎壈终身」在册零重开；读法声明非史实因果' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-015-scene' AS subject_id, 'context' AS property_key, 'claim-bg-015-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-015-city' AS subject_id, 'context' AS property_key, 'claim-bg-015-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-015-world' AS subject_id, 'context' AS property_key, 'claim-bg-015-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-015-person' AS subject_id, 'context' AS property_key, 'claim-bg-015-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-015-scene' AS id, 'work-t300-015' AS work_id, 'SCENE' AS layer, '**诗一开口就借别人的一首诗**：「淒涼寶劍篇」——那篇宝剑歌行是郭震的（通鉴七十五卷郭震恰一、只在他劾相那页，剑篇零——机器断言），李商隱把别人的剑篇当作自己风雨夜的开场白，第二句才轮到「羈泊欲窮年」：一整年漂着。**ws 页是五成页首见**（{{Textquality|50%}}——已落九首李商隱诗页从无此级；300 语料 TQ 谱 50:92/75:142/100:26 闭域档扫）；**零标记页×五成**（{{另}}/{{別}}/{{*}}/<ref>/{{reflist}} 全零，机器断言——V069/V072 满级零标记谱向低级的延伸：**评级与标记多寡正交的第三枚标本**）。**双转录句读分工第二次在场**（Vtext 行全裸、poem 块全句读——V072 首见成系列）；**跨迁移零分歧面**：V018 文本行八句与本快照 poem 块逐字同面（ws-raw 对 ws-raw——与 V072 异体分工恰成对照组，生成时八行双向断言）。正文第二引上限用满第二十一例（V018 句读式一引在先，本迁移引 poem 块原样面——同面各从其录，V018 句读式引文零重开硬断言），此后此诗正文关闭。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-015-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-015-city' AS id, 'work-t300-015' AS work_id, 'CITY' AS layer, '**这座城的档案员把两案风雨钉在同一页上下**：ws notes「↑ [[全唐詩/卷539#風雨|…]]」向上回指、539 本篇正文恰是「{{:風雨 (李商隱)}}」向下转引——**互指循环指针第三次在场**（V071 首见、V072 第二次，本篇成连续系列；539 回指页闭域恰五：寄令狐郎中/蟬/錦瑟/韓碑/風雨，机器断言）；壳侧作者消歧器第二次在场（「==[[風雨 (李商隱)|風雨]]==」+转引各全唐诗恰一——消歧器上壳是 V072 首见的常规化）。**新形态：整理者作者注直接挂锚**——同卷杜牧诗题作「==[[杜司勳]]{{*|牧}}==」（{{*|牧}} 作者注挂题锚，壳侧注记首见，机器断言恰一），其诗首句恰是「高樓風雨感斯文」；**卷页并置机器断言**：李商隱《哭劉蕡》块与杜牧《杜司勳》块在 539 里直接相接（「不敢同君哭寢門」句尾与「==[[杜司勳]]{{*|牧}}==」锚之间只隔块界空行，机器断言恰一）——**选本自己把李商隱哭刘蕡和杜牧读他的高楼风雨放在同一个换行上下**。本页八句在《全唐詩》语料全零——诗只活在诗页；同卷青樓/管絃/寶劍/新豐全零（闭域）。ws notes 排序谱补全第三态：**「{{唐詩三百首}}↑」相邻形全库恰一页**（机器断言——V071 三连序/V072 三百首居首/本篇五成居首）；分类三行含作者分类（分类形态 2/3/4 行至此全齐——V071 两行无/V072 四行带类目/本篇三行；分类行系整理者动作非史料声明、不升格，V048 判例）。**零新建 source 连续第五首**（两源皆 V018 所立，539 第八次复用）。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-015-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-015-world' AS id, 'work-t300-015' AS work_id, 'WORLD' AS layer, '**通鉴七十五卷有风雨，恰九处，且每一处都有落主**（闭域 202/204/210/211/248/250/254/257/261，机器断言）：永隆元年（庚辰，六八〇）裴行儉黑山 before 移营高岡，「是夜，風雨暴至，前所營地，水深丈餘」——风雨落进将令，诸将从此不敢多问；開元三年（乙卯，七一五）盧懷慎「虽贵为卿相……**所居不蔽風雨**」——风雨落在清谨卿相的屋顶上；大中元年（丁卯，八四七）宣宗对白敏中自忆宪宗之丧「**道遇風雨，百官、六宮四散避去**，惟山陵使長而多髯，攀灵驾不去」，答案是「令狐楚」——**风雨成了忠勤的赏价：令狐家的门第正是在这场雨里定下的**（V069 在册句只对照不重开）；中和二年（壬寅，八八二）高骈府里吕用之「每對駢**呵叱風雨**」——风雨沦为方士的道具。五段逐字入引为判决证据。**同字两界第十八形态·风雨形态首见**：**史部的风雨各有落主——落进军令、落在屋顶、骗进宫闱、定下门第；诗的「黃葉仍風雨」不落在任何人的账上**。**旧字面同样在册而两界**：「舊好」恰六（213/222/232/250/253/264 闭域，机器断言）**全部是国与国、镇与镇之间复盟修好，无一字落在朋友身上**（開元十八年吐蕃乞「倘使復修舊好，死無所恨」逐字入引）；诗的「舊好隔良緣」隔的是令狐绹。青樓/管絃/薄俗/新知通鉴全零（闭域）。' AS body_text, 'SENIOR' AS audience, 'claim-bg-015-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-015-person' AS id, 'work-t300-015' AS work_id, 'PERSON' AS layer, '**旧传这一段只给了这个人与酒无关的一笔**：「府罢入朝，复以文章**干**襜，乃补太学博士」——段内「干」字恰二（「以所业文干之」/「复以文章干襜」，前者 V067 在册零重开，机器断言）：**这个人一生在敲门，史部记他敲门，没记他喝酒**——诗的「心斷新豐酒，銷愁斗幾千」要一杯新豐酒来销愁，通鉴的馬周恰十五处全在官迹、代陈便宜直门下省，**传里无一字酒**（贞观三年段机器断言）；新豐恰九全是地名人名（新豐县/新豐丞/新豐王孝傑——闭域档扫），**新豐酒零**。**段内题字全零**（風/雨/劍/篇/羈/黃/葉/青/樓/管/絃/新/舊/俗/愁/斗/銷/淒/窮+酒/飲 二十一项，机器断言）——**写风雨的人，传里无一风雨字**（V068 无一仙字/V071 无一瑟字/V072 无一蝉字同款第四枚）。紧接着史臣总评「无持操……坎壈终身」（V066/V068 在册零重开）——**诗里借剑借酒的人，史书里只剩敲门的两下**（读法声明，非史实因果）；KNOWN 零如实记录（第廿九例，audit 反向断言）。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-015-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文 ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-015-scene' AS claim_id, 'source-ws-t300-015' AS source_id, '页面 風雨（《唐詩三百首》第 15 首选本页，页题裸名；title+author+署名行+Vtext 八行裸片+poem 存原样块+notes 行以「……」相连——poem 带句读而 Vtext 全裸（双转录句读分工第二次——V072 首见成系列）；**五成页首见**（注记 {{Textquality|50%}} 入引——已落九首李商隱诗页从无此级）+零标记页（{{另}}/{{別}}/{{*}}/<ref>/{{reflist}} 全零——评级与标记正交第三枚标本）；**与 V018 零分歧面**（ws-raw 八行逐字同面，双向断言）；正文第二引第二十一例（V018 句读式一引在先不重开）' AS locator, '| title    = 風雨……| author   = 李商隱……{{Vtext|}}
{{Vtext|李商隱}}
{{Vtext|}}……{{VtextStart}}淒涼寶劍篇{{VtextEnd}}
{{VtextStart}}羈泊欲窮年{{VtextEnd}}
{{VtextStart}}黃葉仍風雨{{VtextEnd}}
{{VtextStart}}青樓自管絃{{VtextEnd}}
{{VtextStart}}新知遭薄俗{{VtextEnd}}
{{VtextStart}}舊好隔良緣{{VtextEnd}}
{{VtextStart}}心斷新豐酒{{VtextEnd}}
{{VtextStart}}銷愁斗幾千{{VtextEnd}}……淒涼寶劍篇，羈泊欲窮年。
黃葉仍風雨，青樓自管絃。
新知遭薄俗，舊好隔良緣。
心斷新豐酒，銷愁斗幾千。
</poem>……| notes    = {{Textquality|50%}}{{唐詩三百首}}↑ [[全唐詩/卷539#風雨|全唐詩·卷五百三十九]]' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-015-city' AS claim_id, 'source-quantangshi-539' AS source_id, '卷五百三十九·李商隱《風雨》消歧壳（壳侧作者消歧器第二次在场——V072 首见成常规，显示名仍裸風雨）；壳外全卷无本篇正文一字（八句全唐诗语料全零机器断言）；**与本页 notes ↑回指互指第三次在场**（539 回指页闭域恰五）；**卷页并置**：「==[[杜司勳]]{{*|牧}}==」恰一——整理者作者注直接挂题锚（壳侧挂锚注记首见），相邻《哭劉蕡》块与之直接相接恰一（杜牧「高樓風雨感斯文」全唐诗恰一——两案风雨同页上下）；源行 V018 已立、本迁移第八次复用零新建）' AS locator, '==[[風雨 (李商隱)|風雨]]==
{{:風雨 (李商隱)}}……==[[杜司勳]]{{*|牧}}==
<poem>
高樓風雨感斯文　短翼差池不及群
刻意傷春復傷別　人間惟有杜司勳
</poem>' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-015-city' AS claim_id, 'source-ws-t300-015' AS source_id, '页面 風雨（notes 三连一行整值入引（{{Textquality|50%}} 居首+{{唐詩三百首}}+↑底本回指——**notes 排序谱第三态**：「{{唐詩三百首}}↑」相邻形全库恰一页机器断言；↑ 指向恰是转引本篇的 539 壳——互指之诗页侧）+页尾分类三行（简繁并立，含 [[Category:李商隱]]；**分类三形态 2/3/4 行至此全齐**——V071 两行无作者/V072 四行带类目/本篇三行；分类行系整理者分类动作：非史料声明、不升格，V048 判例）；本迁移零新建源连续第五首）' AS locator, '| notes    = {{Textquality|50%}}{{唐詩三百首}}↑ [[全唐詩/卷539#風雨|全唐詩·卷五百三十九]]……[[Category:李商隱]]
[[Category:唐诗]]
[[Category:唐詩三百首|李]]' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-015-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '卷二百零二·永隆元年裴行儉移营「是夜，風雨暴至」（风雨落进军令）……卷二百一十一·開元三年盧懷慎「所居不蔽風雨」（风雨落卿相屋顶）……卷二百四十八·大中元年宣宗忆宪宗之喪「道遇風雨，百官、六宮四散避去」对曰「令狐楚」（风雨成忠勤赏价——令狐家门第在此雨定下；V069 山陵使在册句只对照不重开，引文越句而取）……卷二百五十四·中和二年吕用之「每對駢呵叱風雨」（风雨成方士道具）；通鉴風雨恰九九卷闭域/舊好恰六全在邦交（213 吐蕃開元十八年闭域）——五段逐字入引为判决证据）' AS locator, '軍至單于府北，抵暮，下營，掘塹已周，行儉遽命移就高岡；諸將皆言士卒已安堵，不可復動，行儉不從，趣使移。是夜，風雨暴至，前所營地，水深丈餘。諸將驚服，問其故，行儉笑曰：「自今但從我命，不必問其所由知也。……懷慎清謹儉素，不營資產，雖貴爲卿相，所得俸賜，隨散親舊。妻子不免饑寒，所居不蔽風雨。……上請白敏中曰：「朕昔從憲宗之喪，道遇風雨，百官、六宮四散避去……攀靈駕不去，誰也？」對曰：「令狐楚。」……用之每對駢呵叱風雨，仰揖空際，雲有神仙過雲表。……倘使復修舊好，死無所恨！」' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-015-person' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書卷一九〇下·李商隱（**简化字录入**照登原样，V016 locator 同款标注）（「府罢入朝，复以文章干襜，乃补太学博士」段（史部记他敲门不记他喝酒——全库查重恰零域首引；段内干字恰二谱：干之 V067 在册零重开/干襜首引；传区间归属机器断言；段内诗面题字二十一项全零——風/雨/劍/篇/羈/黃/葉/青/樓/管/絃/新/舊/俗/愁/斗/銷/淒/窮+酒/飲——**写风雨的人传里无一风雨字**（V068 无一仙/V071 无一瑟/V072 无一蝉同款）；「干字谱」系读法声明；V016/V066–V069/V072 在册句零重开）' AS locator, '府罢入朝，复以文章干襜，乃补太学博士。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-015-person' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '卷一百九十三·貞觀三年（己丑，六二九）馬周条（茌平人馬周客游长安舍常何家代陈便宜二十余条——**史部马周恰十五处全在官迹、此段无一字酒无一字新豐**（机器断言）：诗要销愁的新豐酒，通鉴新豐恰九全是地名人名而新豐酒零——诗借的酒史部只借出地名）' AS locator, '茌平人馬周，客遊長安，捨於中郎將常何之家。六月，壬午，以旱，詔文武官極言得失。何武人不學，不知所言，周代之陳便宜二十餘條。上怪其能，以問何，對曰：「此非臣所能，家客馬周為臣具草耳。」上即召之；未至，遣使督促者數輩。及謁見，與語，甚悅，令直門下省，尋除監察御史，奉使稱旨。上以常何為知人，賜絹三百匹。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（八句五律 2/2/2/2 顺次） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-015-scene' AS background_id, 'text-work-t300-015-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-015-scene' AS background_id, 'text-work-t300-015-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-015-city' AS background_id, 'text-work-t300-015-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-015-city' AS background_id, 'text-work-t300-015-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-015-world' AS background_id, 'text-work-t300-015-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-015-world' AS background_id, 'text-work-t300-015-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-015-person' AS background_id, 'text-work-t300-015-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-015-person' AS background_id, 'text-work-t300-015-ws' AS version_id, 8 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 73, 'Li Shang-yin''s Storm (work-t300-015) background layers (stage-D poem 54, eight-line regulated verse 2/2/2/2): dating verdict forty-eight, thirty-sixth shape of the title-evidence series -- every rain in the histories has an owner; the poem''s rain falls on no one''s ledger. Same-character-two-realms, eighteenth shape: the storm (fengyu) shape, first seen. The Tongjian carries exactly nine storms across seventy-five juan (closed set 202/204/210/211/248/250/254/257/261, machine-asserted); four are cited verbatim as verdict evidence: in Yonglong 1, gengzi, 680, Pei Xingjian orders the camp moved to high ground before the night -- "that night the wind and rain came violently; the ground they had camped on was a zhang deep in water" (the storm inside a commander''s order); in Kaiyuan 3, yimao, 715, Lu Huaishan, though a chancellor, "dwelt where roof and eaves did not keep out wind and rain" (the storm on a clean minister''s roof); in Dazhong 1, dingmao, 847, Emperor Xuanzong recalls his own youth at Xianzong''s funeral procession -- "we met wind and rain on the road; the hundred officials and the six palaces all scattered to shelter," and the one man who clung to the royal carriage and would not leave was Linghu Chu (the storm becomes the price tag of loyalty: the Linghu family''s rise to great-house status was set in that rain -- V069''s closed sentence quoted for contrast, never reopened); in Zhonghe 2, renyin, 882, Lu Yunzhi at Gao Pian''s court "scolded the wind and rain in front of Pian" (the storm becomes a charlatan''s prop). The poem''s "yellow leaves, still wind and rain" falls on none of these ledgers. The old-friendship word likewise on the books but in two realms: "jiuhao" (old friendship) appears exactly six times (213/222/232/250/253/264, closed set, machine-asserted), every one of them a treaty reconciliation between states or garrisons -- not once does the word touch a friend; the poem''s "old friends cut off by a thin affinity" cuts against Linghu Tao: state friendships have ledgers, friendships between old friends do not. The Tongjian scores zero on blue tower, pipes-and-strings, thin mores, new acquaintances; Xin丰 appears nine times, all place-names and籍贯, and "Xinfeng wine" zero times; Ma Zhou appears fifteen times, all in official careers, never with a cup; the two treasure-swords (Li Su gifting a sword, Lu Yunzhi faking one) are never the sword-song -- the allusions the poem borrows: the histories lend out only place-names and names of men. The mutual-pointer binding, first seen V071 and twice in V072, recurs a third time and becomes a continuous series (machine-asserted: exactly five ws pages carry the 539 back-reference -- Ji Linghu, Cicada, Inscribed Harps, Han Stele, Storm). The author-disambiguator sits on the shell side a second time (normalized from V072''s first), and in a NEW shape the compilers'' author-note hangs directly on an anchor: "==[[杜司勳]]{{*|牧}}==" (exactly one, machine-asserted) whose first line is "High tower, wind and rain: I feel the sense of this writing" -- and the page-placement assertion: in juan 539 the block of Li Shang-yin''s "Weeping over Liu Fen" and the block of Du Mu''s "Du Sixun" are directly adjacent (exactly one join), so the anthology itself stacks the two storm cases across a single line-break. The eight lines score zero across the Quan Tangshi corpus (the text lives only on the poem page). ZERO new sources, fifth poem running; both sources from V018, the 539 source at its eighth reuse. Body use-ceiling reached, twenty-first instance, and a new counter-pair to V072: V018 stored ws-raw with punctuation and this snapshot''s poem block matches it line-for-line with zero variant divergence (cross-migration zero-divergence face, the mirror image of V072''s variant division of labor; generator asserts both sides and that V018''s punctuated excerpt is never re-used); the body is now closed. Page forms: first 50 percent-grade page among the landed Li Shang-yin poems (TQ spectrum closed set 50:92/75:142/100:26), a zero-mark page at 50 percent (third specimen proving rating and mark-count orthogonal), notes ordering third state ("{{唐詩三百首}}↑" adjacency exactly one page in the corpus, machine-asserted), and the category footer three lines with the author category (forms 2/3/4 lines now complete -- the line count itself is the form; editorial, not a source claim, not upgraded, V048 precedent). PERSON first-cites one zero-domain simplified JTS passage -- "the office ended, he entered court, and again pressed for a posting with his writing, and was appointed Chancellery Academician" -- the second "press" graph in the biography (the first, pressed with his compositions, closed in V067, never reopened): the histories record the man knocking on doors and never record him drinking; the poem asks for a cup of Xinfeng wine to dissolve grief, and the Tongjian has nine Xinfengs but no Xinfeng wine, and fifteen Ma Zhous but no cup; the biography segment holds none of the twenty-one title-side graphs -- the man who wrote the storm leaves not one wind-or-rain graph in his biography (same shape as V068''s no-immortal-graph, V071''s no-harp-graph, V072''s no-cicada-graph, the fourth of the series); "the histories leave only two knocks on the door" is declared as reading, not fact. KNOWN zero honestly recorded (twenty-ninth instance, audit reverse-asserts); closed precedent keywords (including V018''s Babu Autumn Dwelling storm and V053''s Spring Dawn storm and V069''s mountain-tomb-marshal sentence) stay out of citations'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 73);
COMMIT;
