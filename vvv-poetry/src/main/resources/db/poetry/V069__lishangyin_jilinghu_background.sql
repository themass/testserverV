-- V069：李商隱《寄令狐郎中》(work-t300-016) 四层背景（阶段 D 第 50 首·寄与不省）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V014、V015、V016、V018、V035、V048、V057、V058、V059、V060、V061、
--       V062、V063、V064、V065、V066、V067、V068 已执行
--       （work-t300-016 与其 text-work-t300-016-ws 与其源 source-ws-t300-016 都是 V018 的行
--       （V018 以 **ws《唐詩三百首》选本页** 立本诗正文，version_code=ws-raw——
--       与 V066/V067/V068 相反：那三首底本是卷页、欠诗页；本诗底本是诗页、欠卷页）；
--       source-quantangshi-539 是 V018 已立的卷539 卷页源（V018/V067/V068 已引，
--       本迁移复用补上卷页见证面，零新建）；
--       source-zizhi-tongjian-events 是 V014/V015 已立的通鉴事件源；
--       source-jiutangshu-wenyuan 是 V016 已立的旧唐书文苑传源（李商隐传在此，简化字录入）；
--       判例在册句（义山/开成二年/岭表/三十六体 V016、绹不之省/坎壈终身 V066、
--       乘興南遊/孫處約諫書/以所业文干之/下笔不能自休 V067、置瑤池都督府/恃才诡激
--       为当涂者所薄 V068）只对照不重开）。
--       **本迁移零新建 source——连续三首开新源（V066/V067/V068）到此终结；
--       audit 断言本文件零 poetry_source INSERT、回滚零 source 删除。**
--
-- 数据源（可复现）：emit_v069.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/寄令狐郎中.txt（100% 满级页+↑底本回指链接+零标记+poem 无句读+双转录+分类三行）、
--   全唐詩卷539（锚 ==[[寄令狐郎中]]== 全唐诗唯一+字面恰一+卷内四语各恰一自足+
--   秋雨/相如/離居他诗混片闭域；全唐诗 寄令狐郎中字面恰一/茂陵恰18/相如恰29 档扫闭域）、
--   舊唐書卷190下（李商隐段首引二句+段内相如/茂陵/秋雨/双鲤/一纸/旧宾/梁园全零+段边界断言）、
--   通鑑卷205/223/248/249（七段逐字入引+七处年标题窗口断言）+
--   通鑑 75 卷负证计数扫描（茂陵/梁園/秋雨/一紙書/舊賓客/病相如/雙鯉/嵩雲/秦樹 全零+
--   令狐綯恰十八处五卷/令狐绹简体全零/司馬相如恰一/文園恰一/背恩恰一/汗沾衣恰二/
--   長日惟消一局棋恰一 闭域）+
--   既有迁移引文域逐句查重——传区间归属、二引/零重开/首引零域前提全部生成时断言。
--
-- 做：4 BACKGROUND content/claim/background + 5 组逐字引用（(claim,source) 主键每对恰一行）+
--   4 background_line（四句七绝 **1/1/1/1 第六次**（V056/V061/V066/V067/V068 之后）：scene→1
--   city→2 world→3 person→4，绑 text-work-t300-016-ws 的 4 行）+ 不碰 poetry_text_line。
-- 不做：**不新建任何 source**（连续三首开新源到此终结）；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「诗一纸书寄往的人，做了十年宰相；史部考他是忌，他汗湿了衣裳」）：
--   * 通鉴令狐綯恰十八（跨库字体分工声明：通鉴繁体綯/旧传简体绹）+ 七处年标题窗口入引；
--   * 「寄答两界」系通鉴七段逐字入引支撑的对照判决，非史实因果——通鉴不记这次寄答本身；
--   * 「一封短信抵不上一次婚姻」「一纸书要泯背恩无行」标明读法声明；
--     「以商隐背恩，尤恶其无行」标明史臣笔底绹意（非自家供状）；
--   * 通鉴背恩恰一（回纥外交辞令）与旧传背恩扣诗人——词面相同，所指两截，绝不当同一事件；
--   * 正文第二引上限用满：V018 诗页一引在先，本迁移引卷页——两引两面不重叠，
--     SCENE 不复引正文（生成时断言首末句不入 SCENE 引文），此后此诗正文关闭；
--   * 「评级谱三态」「底本回指首见」「100%×无句读正交」均照登不判；
--   * 通鉴汗沾衣恰二（另一处林甫/禄山在册）、司馬相如恰六（司馬相如字面恰一，
--     「相如」二字恰六含他人事）、長日惟消一局棋恰一在册零入引（audit 硬卡零混入）；
--   * KNOWN 零如实记录（第廿五例，audit 反向断言 SQL 无 KNOWN 字面量）；
--   * V016/V066/V067/V068 已引诸句只对照不重开。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 68，不含 69
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-016-%';             -- 空
--   SELECT id FROM poetry_source WHERE id IN ('source-ws-t300-016','source-quantangshi-539');
--    -- 两行（均 V018 所立，本迁移不新建）
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-016-ws';  -- 恰 4
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-016-%';       -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-016';                                  -- 4（1/1/1/1）
--   SELECT certainty FROM poetry_claim WHERE id LIKE 'claim-bg-016-%';  -- 四行全 LIKELY
--   SELECT COUNT(*) FROM poetry_source WHERE id LIKE 'source-%t300-016' -- 恰 1（V018 所立）
--     AND id='source-ws-t300-016';
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-016'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-016';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-016-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
-- 回滚: recovery/V069_rollback.sql（按 id 全枚举删除；**零 source 删除**——
--   source-ws-t300-016 与 source-quantangshi-539 皆 V018 所立，绝不删）
START TRANSACTION;

-- ---------- 0. 零新建 source（V066–V068 三连开新源终结；两源皆 V018 所立复用） ----------

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-016-scene' AS id, 'BACKGROUND' AS entity_type, '016-scene' AS slug, '眼前：一纸书寄往嵩云秦树' AS title, '四层处境背景（阶段 D 第 50 首·四句七绝 1/1/1/1 第六次）；史实句均有逐字引证；系年第四十四次判决（题证系列第卅二状·寄令狐郎中与汗沾衣）「诗一纸书寄往的人，通鉴里做了十年宰相；史部给他的考语是忌，他自己在皇帝面前汗湿了衣裳」——同字两界第十四形态·寄答形态首见：通鉴以繁体「令狐綯」恰十八处五卷写成宰相（通鉴简体令狐绹全零——**同一人跨库字体分工：通鉴繁体綯/旧传简体绹**）；诗面茂陵/梁園/秋雨/一紙書/舊賓客/病相如/雙鯉/嵩雲/秦樹通鉴全零；大中元年丁卯八四七宣宗问元和山陵使旧事「惟山陵使長而多髯攀靈駕不去…次子綯前湖州刺史有才器」+大中二年戊辰八四八「以知制誥令狐綯為翰林學士」（**收件人第一次进通鉴以孝子之子身份**）；大中十一年丁丑八五七三连入引=李远案「令狐綯擬李遠杭州刺史…『長日惟消一局棋』安能理人…詩人托此為高興耳」（**宰相替诗人解释那句诗是写着玩，通鉴记他反着办提拔诗人**）+「剛直為令狐綯所忌而出之」（**史部考语忌贤**）+「吾十年秉政…未嘗不汗沾衣也」（**十年宰相的病是汗，诗人自比的病是雨**）；通鉴司馬相如恰一（長壽元年壬辰六九二奏疏「昔漢武帝見司馬相如賦恨不同時終文園令」——唯一相如=不堪公卿教材，**诗自比病相如，史部说相如本做不了大官**）；通鉴背恩恰一（永泰元年乙巳七六五郭子仪责回纥「背恩德而助叛臣」——**同一帽史部扣外族、传部扣诗人**）；汗沾衣恰二/長日惟消一局棋恰一在册；本篇锚「==[[寄令狐郎中]]==」全唐诗唯一（字面恰一无同名，两端裸名消歧链裸侧第四见 V061/V062/V063）；卷内一紙書/舊賓客/病相如/茂陵秋雨各恰一（诗面自足）；**零新建 source（V066–V068 三连开新源终结回零新源侧）——本诗是 V066–V068 的镜像：V018 底本是 ws 诗页（ws-raw）、卷页从未被引，两个见证面先入哪个另一个就欠着；补引 source-quantangshi-539 第四次复用**；正文第二引上限用满第十七例（V018 诗页在先+本迁移卷页，两面不重叠，SCENE 不复引正文断言）；ws 页 {{Textquality|100%}}满级页首见（75%/无评级/100% 评级谱三态齐备）+**notes 内嵌 ↑ 底本回指链接首见（选本页自指底本卷页，两见证面页内自我声明）**+poem 全无句读第三见（**100% 评级×无句读正交**）+{{另}}/{{別}}/{{*}}/<ref> 全零+分类三行简繁混排第四见；PERSON 旧传简化段首引二句（子绹为员外郎以商隐背恩尤恶其无行+茂元爱其才以子妻之——诗题官衔郎中对史传员外郎，一纸书要泯的正是背恩无行四字；**一封短信抵不上一次婚姻**读法声明；背恩无行系史臣笔底绹意照登 LIKELY）；段内相如/茂陵/秋雨/双鲤/一纸/旧宾/梁园全零；V016/V066/V067/V068 在册句零重开（域断言）；KNOWN 零如实记录（第廿五例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-016-city' AS id, 'BACKGROUND' AS entity_type, '016-city' AS slug, '这座城：底本回指的一行注' AS title, '四层处境背景（阶段 D 第 50 首·四句七绝 1/1/1/1 第六次）；史实句均有逐字引证；系年第四十四次判决（题证系列第卅二状·寄令狐郎中与汗沾衣）「诗一纸书寄往的人，通鉴里做了十年宰相；史部给他的考语是忌，他自己在皇帝面前汗湿了衣裳」——同字两界第十四形态·寄答形态首见：通鉴以繁体「令狐綯」恰十八处五卷写成宰相（通鉴简体令狐绹全零——**同一人跨库字体分工：通鉴繁体綯/旧传简体绹**）；诗面茂陵/梁園/秋雨/一紙書/舊賓客/病相如/雙鯉/嵩雲/秦樹通鉴全零；大中元年丁卯八四七宣宗问元和山陵使旧事「惟山陵使長而多髯攀靈駕不去…次子綯前湖州刺史有才器」+大中二年戊辰八四八「以知制誥令狐綯為翰林學士」（**收件人第一次进通鉴以孝子之子身份**）；大中十一年丁丑八五七三连入引=李远案「令狐綯擬李遠杭州刺史…『長日惟消一局棋』安能理人…詩人托此為高興耳」（**宰相替诗人解释那句诗是写着玩，通鉴记他反着办提拔诗人**）+「剛直為令狐綯所忌而出之」（**史部考语忌贤**）+「吾十年秉政…未嘗不汗沾衣也」（**十年宰相的病是汗，诗人自比的病是雨**）；通鉴司馬相如恰一（長壽元年壬辰六九二奏疏「昔漢武帝見司馬相如賦恨不同時終文園令」——唯一相如=不堪公卿教材，**诗自比病相如，史部说相如本做不了大官**）；通鉴背恩恰一（永泰元年乙巳七六五郭子仪责回纥「背恩德而助叛臣」——**同一帽史部扣外族、传部扣诗人**）；汗沾衣恰二/長日惟消一局棋恰一在册；本篇锚「==[[寄令狐郎中]]==」全唐诗唯一（字面恰一无同名，两端裸名消歧链裸侧第四见 V061/V062/V063）；卷内一紙書/舊賓客/病相如/茂陵秋雨各恰一（诗面自足）；**零新建 source（V066–V068 三连开新源终结回零新源侧）——本诗是 V066–V068 的镜像：V018 底本是 ws 诗页（ws-raw）、卷页从未被引，两个见证面先入哪个另一个就欠着；补引 source-quantangshi-539 第四次复用**；正文第二引上限用满第十七例（V018 诗页在先+本迁移卷页，两面不重叠，SCENE 不复引正文断言）；ws 页 {{Textquality|100%}}满级页首见（75%/无评级/100% 评级谱三态齐备）+**notes 内嵌 ↑ 底本回指链接首见（选本页自指底本卷页，两见证面页内自我声明）**+poem 全无句读第三见（**100% 评级×无句读正交**）+{{另}}/{{別}}/{{*}}/<ref> 全零+分类三行简繁混排第四见；PERSON 旧传简化段首引二句（子绹为员外郎以商隐背恩尤恶其无行+茂元爱其才以子妻之——诗题官衔郎中对史传员外郎，一纸书要泯的正是背恩无行四字；**一封短信抵不上一次婚姻**读法声明；背恩无行系史臣笔底绹意照登 LIKELY）；段内相如/茂陵/秋雨/双鲤/一纸/旧宾/梁园全零；V016/V066/V067/V068 在册句零重开（域断言）；KNOWN 零如实记录（第廿五例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-016-world' AS id, 'BACKGROUND' AS entity_type, '016-world' AS slug, '这个天下：十年宰相汗沾衣' AS title, '四层处境背景（阶段 D 第 50 首·四句七绝 1/1/1/1 第六次）；史实句均有逐字引证；系年第四十四次判决（题证系列第卅二状·寄令狐郎中与汗沾衣）「诗一纸书寄往的人，通鉴里做了十年宰相；史部给他的考语是忌，他自己在皇帝面前汗湿了衣裳」——同字两界第十四形态·寄答形态首见：通鉴以繁体「令狐綯」恰十八处五卷写成宰相（通鉴简体令狐绹全零——**同一人跨库字体分工：通鉴繁体綯/旧传简体绹**）；诗面茂陵/梁園/秋雨/一紙書/舊賓客/病相如/雙鯉/嵩雲/秦樹通鉴全零；大中元年丁卯八四七宣宗问元和山陵使旧事「惟山陵使長而多髯攀靈駕不去…次子綯前湖州刺史有才器」+大中二年戊辰八四八「以知制誥令狐綯為翰林學士」（**收件人第一次进通鉴以孝子之子身份**）；大中十一年丁丑八五七三连入引=李远案「令狐綯擬李遠杭州刺史…『長日惟消一局棋』安能理人…詩人托此為高興耳」（**宰相替诗人解释那句诗是写着玩，通鉴记他反着办提拔诗人**）+「剛直為令狐綯所忌而出之」（**史部考语忌贤**）+「吾十年秉政…未嘗不汗沾衣也」（**十年宰相的病是汗，诗人自比的病是雨**）；通鉴司馬相如恰一（長壽元年壬辰六九二奏疏「昔漢武帝見司馬相如賦恨不同時終文園令」——唯一相如=不堪公卿教材，**诗自比病相如，史部说相如本做不了大官**）；通鉴背恩恰一（永泰元年乙巳七六五郭子仪责回纥「背恩德而助叛臣」——**同一帽史部扣外族、传部扣诗人**）；汗沾衣恰二/長日惟消一局棋恰一在册；本篇锚「==[[寄令狐郎中]]==」全唐诗唯一（字面恰一无同名，两端裸名消歧链裸侧第四见 V061/V062/V063）；卷内一紙書/舊賓客/病相如/茂陵秋雨各恰一（诗面自足）；**零新建 source（V066–V068 三连开新源终结回零新源侧）——本诗是 V066–V068 的镜像：V018 底本是 ws 诗页（ws-raw）、卷页从未被引，两个见证面先入哪个另一个就欠着；补引 source-quantangshi-539 第四次复用**；正文第二引上限用满第十七例（V018 诗页在先+本迁移卷页，两面不重叠，SCENE 不复引正文断言）；ws 页 {{Textquality|100%}}满级页首见（75%/无评级/100% 评级谱三态齐备）+**notes 内嵌 ↑ 底本回指链接首见（选本页自指底本卷页，两见证面页内自我声明）**+poem 全无句读第三见（**100% 评级×无句读正交**）+{{另}}/{{別}}/{{*}}/<ref> 全零+分类三行简繁混排第四见；PERSON 旧传简化段首引二句（子绹为员外郎以商隐背恩尤恶其无行+茂元爱其才以子妻之——诗题官衔郎中对史传员外郎，一纸书要泯的正是背恩无行四字；**一封短信抵不上一次婚姻**读法声明；背恩无行系史臣笔底绹意照登 LIKELY）；段内相如/茂陵/秋雨/双鲤/一纸/旧宾/梁园全零；V016/V066/V067/V068 在册句零重开（域断言）；KNOWN 零如实记录（第廿五例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-016-person' AS id, 'BACKGROUND' AS entity_type, '016-person' AS slug, '这个人：背恩无行那一行' AS title, '四层处境背景（阶段 D 第 50 首·四句七绝 1/1/1/1 第六次）；史实句均有逐字引证；系年第四十四次判决（题证系列第卅二状·寄令狐郎中与汗沾衣）「诗一纸书寄往的人，通鉴里做了十年宰相；史部给他的考语是忌，他自己在皇帝面前汗湿了衣裳」——同字两界第十四形态·寄答形态首见：通鉴以繁体「令狐綯」恰十八处五卷写成宰相（通鉴简体令狐绹全零——**同一人跨库字体分工：通鉴繁体綯/旧传简体绹**）；诗面茂陵/梁園/秋雨/一紙書/舊賓客/病相如/雙鯉/嵩雲/秦樹通鉴全零；大中元年丁卯八四七宣宗问元和山陵使旧事「惟山陵使長而多髯攀靈駕不去…次子綯前湖州刺史有才器」+大中二年戊辰八四八「以知制誥令狐綯為翰林學士」（**收件人第一次进通鉴以孝子之子身份**）；大中十一年丁丑八五七三连入引=李远案「令狐綯擬李遠杭州刺史…『長日惟消一局棋』安能理人…詩人托此為高興耳」（**宰相替诗人解释那句诗是写着玩，通鉴记他反着办提拔诗人**）+「剛直為令狐綯所忌而出之」（**史部考语忌贤**）+「吾十年秉政…未嘗不汗沾衣也」（**十年宰相的病是汗，诗人自比的病是雨**）；通鉴司馬相如恰一（長壽元年壬辰六九二奏疏「昔漢武帝見司馬相如賦恨不同時終文園令」——唯一相如=不堪公卿教材，**诗自比病相如，史部说相如本做不了大官**）；通鉴背恩恰一（永泰元年乙巳七六五郭子仪责回纥「背恩德而助叛臣」——**同一帽史部扣外族、传部扣诗人**）；汗沾衣恰二/長日惟消一局棋恰一在册；本篇锚「==[[寄令狐郎中]]==」全唐诗唯一（字面恰一无同名，两端裸名消歧链裸侧第四见 V061/V062/V063）；卷内一紙書/舊賓客/病相如/茂陵秋雨各恰一（诗面自足）；**零新建 source（V066–V068 三连开新源终结回零新源侧）——本诗是 V066–V068 的镜像：V018 底本是 ws 诗页（ws-raw）、卷页从未被引，两个见证面先入哪个另一个就欠着；补引 source-quantangshi-539 第四次复用**；正文第二引上限用满第十七例（V018 诗页在先+本迁移卷页，两面不重叠，SCENE 不复引正文断言）；ws 页 {{Textquality|100%}}满级页首见（75%/无评级/100% 评级谱三态齐备）+**notes 内嵌 ↑ 底本回指链接首见（选本页自指底本卷页，两见证面页内自我声明）**+poem 全无句读第三见（**100% 评级×无句读正交**）+{{另}}/{{別}}/{{*}}/<ref> 全零+分类三行简繁混排第四见；PERSON 旧传简化段首引二句（子绹为员外郎以商隐背恩尤恶其无行+茂元爱其才以子妻之——诗题官衔郎中对史传员外郎，一纸书要泯的正是背恩无行四字；**一封短信抵不上一次婚姻**读法声明；背恩无行系史臣笔底绹意照登 LIKELY）；段内相如/茂陵/秋雨/双鲤/一纸/旧宾/梁园全零；V016/V066/V067/V068 在册句零重开（域断言）；KNOWN 零如实记录（第廿五例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-016-scene' AS id, 'bg-016-scene' AS subject_id, 'context' AS property_key, '四句七绝本文（ws 选本页 poem 块四句**全无句读**第三见，各从其录）；notes 内嵌「↑ [[全唐詩/卷539#…]]」底本回指链接首见（选本页自指底本卷页）；{{Textquality|100%}} 满级页首见（75%/无评级/100% 评级谱三态齐备）；**100% 评级×poem 无句读并存（评级度量转录完备，与句读正交）**；title 裸名；{{另}}/{{別}}/{{*}}/<ref> 全零；页内 Vtext/poem 双转录并存首末句各恰 2；全句**第二引**：V018 已引 ws 诗页（source-ws-t300-016，ws-raw）在先，本迁移改引卷页（两引两面不重叠，上限恰满第十七例），本 SCENE 只引页形制三行不复引正文（生成时断言首末句不入 SCENE 引文）；此后此诗正文对后来迁移关闭。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-016-city' AS id, 'bg-016-city' AS subject_id, 'context' AS property_key, '本篇锚「==[[寄令狐郎中]]==」**全《全唐詩》唯一**（机器断言：锚恰一，字面恰一——无同名诗则两端裸名，消歧链裸侧第四见，V061/V062/V063 判例）；卷内一紙書/舊賓客/病相如/茂陵秋雨各恰一（诗面自足），秋雨/相如/離居2/4/2 他诗混片闭域档扫；**零新建 source（连续三首开新源终结，回零新源侧）——本诗是 V066–V068 的镜像：V018 底本是 ws 诗页（ws-raw）、卷页从未被引**；「两个见证面先入哪个，另一个就欠着」；补引 source-quantangshi-539（第四次复用，V018/V067/V068 在册）；ws notes 底本回指+分类三行简繁混排第四见（非史料声明、不升格，V048 判例）——选本页以底本注与卷页焊成证据对。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-016-world' AS id, 'bg-016-world' AS subject_id, 'context' AS property_key, '通鉴以繁体「令狐綯」恰十八处五卷写成宰相（机器断言；通鉴简体「令狐绹」全零——跨库字体分工：通鉴繁体綯/旧传简体绹）；诗面茂陵/梁園/秋雨/一紙書/舊賓客/病相如/雙鯉/嵩雲/秦樹通鉴全零；大中元年（丁卯，八四七）宣宗问元和旧事「惟山陵使長而多髯攀靈駕不去」+「次子綯前湖州刺史有才器」+大中二年（戊辰，八四八）「以知制誥令狐綯為翰林學士」三窗口逐字入引——**收件人第一次进通鉴以孝子之子身份**；大中十一年（丁丑，八五七）三连入引=李远案「令狐綯擬李遠杭州刺史…『長日惟消一局棋』安能理人…詩人托此為高興耳」**宰相替诗人解释那句诗**+「剛直為令狐綯所忌而出之」**史部考语忌贤**+「吾十年秉政…未嘗不汗沾衣也」**宰相病在汗、诗人病在雨**（同字两界第十四形态·寄答形态首见，audit 硬卡）；通鉴司馬相如恰一（長壽元年壬辰六九二「昔漢武帝見司馬相如賦恨不同時終文園令」——唯一相如=不堪公卿教材）；通鉴背恩恰一（永泰元年乙巳七六五郭子仪责回纥「背恩德而助叛臣」——同一帽旧传扣诗人）；汗沾衣恰二/長日惟消一局棋恰一在册零入引；certainty 不覆盖任何系年，诗 time.span/event.name/written_during 零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-016-person' AS id, 'bg-016-person' AS subject_id, 'context' AS property_key, '旧传李商隐段（简化字录入，照登原样）首引二句皆生成时全库查重域恰零=「子绹为员外郎，以商隐背恩，尤恶其无行。」+「茂元爱其才，以子妻之。」（传区间归属机器断言）；诗题官衔「郎中」对史传官衔「员外郎」（郎之副）——一纸书要泯的正是「背恩」「无行」；「一封短信抵不上一次婚姻」系读法声明；「以商隐背恩，尤恶其无行」系史臣笔底绹意（照登 LIKELY）；段内相如/茂陵/秋雨/双鲤/一纸/旧宾/梁园全零（机器断言，段级零证）；V016/V066/V067/V068 在册句零重开（域断言）；本诗无底注；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-016-scene' AS subject_id, 'context' AS property_key, 'claim-bg-016-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-016-city' AS subject_id, 'context' AS property_key, 'claim-bg-016-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-016-world' AS subject_id, 'context' AS property_key, 'claim-bg-016-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-016-person' AS subject_id, 'context' AS property_key, 'claim-bg-016-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-016-scene' AS id, 'work-t300-016' AS work_id, 'SCENE' AS layer, '四句是一封短信：嵩山的云、秦地的树，我与你久隔（「嵩雲秦樹久離居」）；双鲤（古乐府「客从远方来，遗我双鲤鱼」——函札）迢迢送来一纸书（「雙鯉迢迢一紙書」）；别再问当年梁园（梁孝王游士之园，借指令狐楚幕）的旧宾客了（「休問梁園舊賓客」）——我如今像茂陵秋雨里病着的司马相如（「茂陵秋雨病相如」）。ws 诗页 notes **内嵌「↑ [[全唐詩/卷539#寄令狐郎中|全唐詩·卷五百三十九]]」底本回指链接——选本页自己指回底本卷页首见**（两个见证面在页面内部自我声明）；**{{Textquality|100%}} 满级页首见**（V055/V057/V061/V062 75% 侧、V066/V067/V068 无评级侧、本篇 100% 侧——**评级谱三态齐备**）；poem 块四句**全无句读**第三见（V067 首见）——**100% 评级与无句读并存：评级度量转录完备，与句读正交**；title 裸名、{{另}}/{{別}}/{{*}}/<ref> 全零；页内 Vtext/poem 双转录并存（首末句页内各恰 2）。**此诗正文系第二引**：V018 已引 ws 诗页（text-work-t300-016-ws，version_code 「ws-raw」，source-ws-t300-016）在先，本迁移改引《全唐詩》卷539 卷页（CITY 层）——**两引两面（诗页+卷页）不重叠，上限恰满**；本 SCENE 只引页形制三行（title/author/notes）不复引正文，生成时断言首末句不入 SCENE 引文。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-016-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-016-city' AS id, 'work-t300-016' AS work_id, 'CITY' AS layer, '卷539 侧：本篇锚「==[[寄令狐郎中]]==」**全《全唐詩》唯一**（机器断言：全库扫描锚恰一，且字面「寄令狐郎中」全唐诗**恰一**——无同名诗，两端裸名（ws 文件名/卷页锚点皆裸名，消歧链裸侧第四见，V061/V062/V063 判例——无同名则无消歧器））；卷内「一紙書/舊賓客/病相如/茂陵秋雨」各恰一=诗面自足，「秋雨/相如/離居」为 2/4/2 他诗混片（闭域档扫）。（本层零 relation。）**本迁移零新建 source——连续三首开新源（V066/V067/V068）到此终结，回到零新源侧**；理由是本诗是那三首的**镜像**：V018 给本诗立正文用的是 ws 诗页（ws-raw，source-ws-t300-016 已存在），《全唐詩》卷539 卷页这个见证面从未被引过——那三首是「底本=卷页、欠诗页」，本篇是「底本=诗页、欠卷页」；**两个见证面先入哪个，另一个就欠着**。本迁移补引卷页（source-quantangshi-539 第四次复用，V018/V067/V068 在册），正文**第二引上限用满第十七例**。ws 页 notes 底本回指（↑卷539 链接）与分类三行简繁混排第四见（整理者分类：非史料声明、不升格，V048 判例）——**选本页用一行底本注，把自己与底本卷页焊成一个证据对**。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-016-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-016-world' AS id, 'work-t300-016' AS work_id, 'WORLD' AS layer, '**诗一纸书寄往的人，通鉴里做了十年宰相；史部给他的考语是「忌」，他自己在皇帝面前汗湿了衣裳**（同字两界第十四形态·寄答形态首见）：诗题「寄令狐郎中」是这首诗唯一的史实锚点（收件人姓名+官衔），通鉴以繁体「**令狐綯**」恰十八处五卷把他写成宰相（机器断言；通鉴简体「令狐绹」全零——**同一人跨库字体分工：通鉴繁体「綯」，旧传简体「绹」**）。① 他进身靠父亲：大中元年（丁卯，八四七）宣宗追元和旧事「**惟山陵使長而多髯，攀靈駕不去，誰也？**」对以令狐楚，问「有子乎？」——「**次子綯，前湖州刺史，有才器。**」大中二年（戊辰，八四八）「**以知制誥令狐綯為翰林學士。**」：**诗的收件人第一次进通鉴，是以孝子的儿子身份**；② 大中十一年（丁丑，八五七）三连：**李远案**「**令狐綯擬李遠杭州刺史，上曰：「吾聞遠詩云：『長日惟消一局棋』，安能理人！」綯曰：「詩人托此為高興耳，未必實然。」**」——**宰相替诗人向皇帝解释「那句诗只是写着玩」；诗寄令狐郎中求的正是提拔，通鉴记他反着办**；又「**然竟以剛直為令狐綯所忌而出之。**」——**史部给綯的考语是忌贤**；又「**吾十年秉政，最承恩遇；然每延英奏事，未嘗不汗沾衣也！**」——**十年宰相的病是汗，诗人自比的病是雨**；③ 通鉴「**司馬相如**」恰一处（長壽元年壬辰六九二奏疏「**昔漢武帝見司馬相如賦，恨不同時，及置之朝廷，終文園令**」）——**通鉴唯一的司马相如是「虚文不堪公卿之任」的教材；诗自比「病相如」，史部却说相如本来就做不了大官**；④ 通鉴「**背恩**」恰一处（永泰元年乙巳七六五郭子仪责回纥「**背恩德而助叛臣**」），而旧传用同一顶帽子判李商隐（简体「以商隐背恩」，PERSON 层）——**同一词，史部扣外族，传部扣诗人**；诗面「茂陵/梁園/秋雨/一紙書/舊賓客/病相如/雙鯉/嵩雲/秦樹」通鉴全零（机器断言）；「汗沾衣」恰二（另一处 tj-216 禄山见李林甫常汗沾衣在册零入引）、「長日惟消一局棋」恰一在册。本层零铸造零 relation。' AS body_text, 'SENIOR' AS audience, 'claim-bg-016-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-016-person' AS id, 'work-t300-016' AS work_id, 'PERSON' AS layer, '旧传李商隐段（**简化字录入**，V016 locator 同款标注，引文照登简体原样）首引二句（皆零域）：「**子绹为员外郎，以商隐背恩，尤恶其无行。**」「**茂元爱其才，以子妻之。**」
诗题官衔「寄令狐**郎中**」对上史传官衔「员外**郎**」（郎之副）——这封信寄到的时刻，收件人正卡在这一行官阶上；而这一行同时落下"背恩""无行"四字——**一纸书要泯的，正是这一行里的「背恩」「无行」**。
下句给出"背恩"之实：王茂元爱其才把女儿嫁他（转投与李德裕交好的王家，时令狐楚已卒、牛李党争方炽）——**一封短信抵不上一次婚姻**（读法声明，非史实）。「以商隐背恩，尤恶其无行」系**史臣笔底绹意**（照登，certainty LIKELY——非自家供状）；段内**相如/茂陵/秋雨/双鲤/一纸/旧宾/梁园全零**（机器断言，段级零证）；V016「字义山/开成二年/岭表/三十六体」、V066「绹不之省/坎壈终身」、V067「以所业文干之/下笔不能自休」、V068「为当涂者所薄」在册句零重开（域断言）；本诗无底注（无注可登）；certainty 不覆盖任何系年，诗 time.span/event.name/written_during 仍零铸造（audit 硬卡）。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-016-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文 ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-016-scene' AS claim_id, 'source-ws-t300-016' AS source_id, '页面 寄令狐郎中（《唐詩三百首》第 16 首选本页，页题裸名；title+author+notes 三行——**notes 内嵌「↑ [[全唐詩/卷539#寄令狐郎中|全唐詩·卷五百三十九]]」底本回指链接首见**（选本页自指底本卷页）+{{Textquality|100%}} 满级页首见；poem 块全无句读（100% 评级×无句读正交，评级度量转录完备）；本 SCENE 不复引正文——正文 V018诗页一引在先，本迁移引卷页，两引两面不重叠（生成时断言首末句不入此引文）；{{另}}/{{別}}/{{*}}/<ref> 全零）' AS locator, '| title    = 寄令狐郎中……| author   = 李商隱……| notes    = {{Textquality|100%}}↑ [[全唐詩/卷539#寄令狐郎中|全唐詩·卷五百三十九]]{{唐詩三百首}}' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-016-city' AS claim_id, 'source-quantangshi-539' AS source_id, '卷五百三十九·李商隱《寄令狐郎中》块（锚「==[[寄令狐郎中]]==」**全《全唐詩》唯一**——字面恰一无同名诗，两端裸名消歧链裸侧第四见；卷内一紙書/舊賓客/病相如/茂陵秋雨各恰一（诗面自足），秋雨/相如/離居他诗混片闭域；**正文第二引两面之卷页见证面**（V018 底本是 ws 诗页、卷页从未被引——本诗系 V066–V068 之镜像）；源行系 V018 已立、本迁移复用零新建）' AS locator, '==[[寄令狐郎中]]==
<poem>
嵩雲秦樹久離居　雙鯉迢迢一紙書
休問梁園舊賓客　茂陵秋雨病相如
</poem>' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-016-city' AS claim_id, 'source-ws-t300-016' AS source_id, '页面 寄令狐郎中（整页 notes 行（↑底本回指链接）+分类三行连片（简体「唐诗」与繁体「唐詩三百首」同页混排第四见）；分类行系整理者/编排动作：非史料声明、不升格；**本迁移零新建源（V066–V068 三连开新源终结）**）' AS locator, '| notes    = {{Textquality|100%}}↑ [[全唐詩/卷539#寄令狐郎中|全唐詩·卷五百三十九]]{{唐詩三百首}}……[[Category:李商隱]]
[[Category:唐诗]]
[[Category:唐詩三百首|李]]' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-016-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '卷二百四十八·大中元年（丁卯，八四七）宣宗问元和山陵使旧事（惟山陵使長而多髯+次子綯有才器）段……大中二年（戊辰，八四八）以知制誥令狐綯為翰林學士段……卷二百四十九·大中十一年（丁丑，八五七）李远案（宰相替诗人解释『長日惟消一局棋』）+剛直為令狐綯所忌而出之（考语忌贤）+十年秉政未嘗不汗沾衣三段……卷二百零五·長壽元年（壬辰，六九二）奏疏引司馬相如終文園令段（通鉴唯一相如）……卷二百二十三·永泰元年（乙巳，七六五）郭子仪责回纥背恩德而助叛臣段（通鉴唯一背恩——旧传以同一帽扣诗人）；通鉴令狐綯恰十八处五卷/简体绹全零；汗沾衣恰二、背恩恰一（七段逐字入引为判决证据）' AS locator, '惟山陵使長而多髯，攀靈駕不去，誰也？」對曰：「令狐楚。」上曰：「有子乎？」對曰：「長子緒今為隨州刺史。」上曰：「堪為相乎？」對曰：「緒少病風痺。次子綯，前湖州刺史，有才器。」……以知制誥令狐綯為翰林學士……令狐綯擬李遠杭州刺史，上曰：「吾聞遠詩云：『長日惟消一局棋』，安能理人！」綯曰：「詩人托此為高興耳，未必實然。」……然竟以剛直為令狐綯所忌而出之。……吾十年秉政，最承恩遇；然每延英奏事，未嘗不汗沾衣也！」……昔漢武帝見司馬相如賦，恨不同時，及置之朝廷，終文園令……背恩德而助叛臣' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-016-person' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書卷一九〇下·李商隱（**简化字录入**照登原样，V016 locator 同款标注）（「子绹为员外郎，以商隐背恩，尤恶其无行」句（诗题官衔郎中对史传员外郎+背恩无行四字）+「茂元爱其才，以子妻之」句（背恩之实）——皆全库查重恰零域首引；传区间归属机器断言；「以商隐背恩，尤恶其无行」系史臣笔底绹意非自家供状；「一封短信抵不上一次婚姻」系读法声明；段内相如/茂陵/秋雨/双鲤/一纸/旧宾/梁园全零；V016/V066/V067/V068 在册句零重开）' AS locator, '子绹为员外郎，以商隐背恩，尤恶其无行。……茂元爱其才，以子妻之。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（四句七绝 1/1/1/1 第六次） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-016-scene' AS background_id, 'text-work-t300-016-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-016-city' AS background_id, 'text-work-t300-016-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-016-world' AS background_id, 'text-work-t300-016-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-016-person' AS background_id, 'text-work-t300-016-ws' AS version_id, 4 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 69, 'Li Shang-yin''s Letter to Secretary Linghu (work-t300-016) background layers (stage-D poem 50, four-line jueju 1/1/1/1 sixth time): dating verdict forty-four, thirty-second shape of the title-evidence series -- the letter sent and the letter not read; the man the poem mails a single page to ends up running the government for ten years as grand councillor; the histories'' verdict on him is "jealous", and he himself sweats through his robe in the emperor''s presence; a sending-and-answering split across realms, fourteenth shape of same-character-two-realms. The histories carry him in the traditional form of his name, Linghu Tao, exactly eighteen times across five juan (machine-asserted); the simplified spelling used by the Old Book of Tang scores zero in the Tongjian -- one man, two scripts, a cross-repository font division. All the poem''s own words (mao-ling, liang-yuan, autumn rain, a single sheet of paper, old guest, sick Sima Xiangru, twin carp, Song clouds, Qin trees) score zero in the Tongjian. Dazhong 1st, dingmao, 847: Emperor Xuan recalls the Yuanhe-era funeral-bearer''s-escort "only the escort commissioner, tall with a long beard, clung to the spirit carriage and would not leave" and asks "has he a son?" -- answer: "his second son Tao, formerly Prefect of Huzhou, has talent and capacity"; Dazhong 2nd, wuchen, 848: "appoint the edict-drafter Linghu Tao as Hanlin academician" -- the poem''s addressee first enters the histories as a filial son''s son. Dazhong 11th, dingchou, 857, three-in-one window: the Li Yuan case -- "Linghu Tao nominated Li Yuan as Prefect of Hangzhou; the emperor said: I have heard Yuan''s verse -- 『a whole long day consumed by a single game of go』 -- how can such a one govern people! Tao said: a poet just leans on such lines for high spirits, not necessarily true" (the grand councillor explains to the emperor on a poet''s behalf that the line was only play; the poem mails the郎中 seeking exactly a posting, and the histories record him doing the reverse); "yet in the end, being upright and forthright, he was out of jealousy pushed out by Tao" (the histories'' rating of Tao: jealous of the able); and "I held the government ten years, most favored of all; yet each time I reported at the Yan-ying hall I never failed to sweat through my robe" -- the ten-year chancellor''s sickness is sweat, the poet''s self-compared sickness is rain. Sima Xiangru proper appears exactly once in the Tongjian (Changshou 1st, renchen, 692, a memorial: "of old Emperor Wu of Han read Sima Xiangru''s rhapsody and grieved he had not lived at the same time; once he set him in court he ended as Prefect of the Textual Garden") -- the one and only Sima Xiangru in the histories is a case-study that empty literature cannot bear noble office; the poem likens itself to the sick Sima Xiangru, and the histories say Xiangru was never fit for great office anyway. "Betraying favor" (bei-en) appears exactly once in the Tongjian (Yongtai 1st, yisi, 765, Guo Ziyi rebuking the Uyghurs: "betraying favor to aid a rebel minister") while the Old Book uses the same cap on Li Shang-yin (simplified) -- same word, one cap for a foreign power in the histories, another for a poet in the biographies. Two use-ceiling on the body reached, seventeenth instance: V018 already quoted the ws anthology page (ws-raw), this migration quotes the Quan Tangshi juan-539 scroll page instead -- two quotations, two witness faces, never overlapping; SCENE deliberately does not re-quote the body (generator asserts the first and last lines are absent from the SCENE excerpt); the poem''s body is now closed to later migrations. ZERO new sources -- the three-in-a-row new-source run of V066/V067/V068 ends here; this poem is their mirror image: V018''s base was the ws anthology page, the scroll page was never cited, so whichever of the two faces enters first leaves the other owed; source-quantangshi-539 reused for the fourth time (audit asserts zero poetry_source INSERT and zero source deletion in rollback). The ws page: {{Textquality|100%}} full-grade page first seen (the 75% side of V055/V057/V061/V062, the ungraded side of V066/V067/V068, and the 100% side of this poem -- the grading spectrum''s three states now complete); notes embeds an "up-arrow" back-reference link to the base scroll page, first seen (the anthology page points back to the base page inside itself -- the two witness faces self-declared within one page); a punctuation-free poem block, third time, coexisting with a 100% grade (grade measures transcription completeness, orthogonal to punctuation); zero variant markers; title bare; category triple in mixed scripts, fourth time. PERSON first-cites two zero-domain sentences from the simplified JTS biography -- "his son Tao, as Vice Director, holding Shang-yin to have betrayed favor, particularly loathed his lack of conduct" (the poem-title rank "Langzhong" matches the biography rank "Vice Director / Lang": what a single sheet tries to wipe out is exactly the words "betrayed favor" and "lack of conduct" on this very line) and "Mao-yuan loved his talent and gave him his daughter in marriage" (the substance of the alleged betrayal) -- one short letter is worth less than one marriage (reading declared, not fact); the judgment phrase is the historian''s rendering of Tao''s feeling (logged, LIKELY); the biography segment holds no Xiangru/maoling/autumn-rain/twin-carp/single-sheet/old-guest/liangyuan character (machine-asserted); V016/V066/V067/V068 quoted sentences stay closed (domains asserted); KNOWN zero honestly recorded (twenty-fifth instance, audit reverse-asserts); closed precedent keywords stay out of citations'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 69);
COMMIT;
