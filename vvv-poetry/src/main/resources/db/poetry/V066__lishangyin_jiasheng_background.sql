-- V066：李商隱《賈生》(work-t300-031) 四层背景（阶段 D 第 47 首·贾生与可怜）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V014、V015、V016、V018、V035、V048、V057、V058、V059、V060、V061、V062、
--       V063、V064、V065 已执行
--       （work-t300-031 与其 text-work-t300-031-ws、source-quantangshi-540 是 V018 的行
--       （V018 以卷540 卷页立本诗正文，version_code=vol-raw——ws 选本页当时未建源）；
--       source-ws-t300-031 是本迁移新建的选本页源（恰一枚；audit 断言）；
--       source-zizhi-tongjian-events 是 V014/V015 已立的通鉴事件源；
--       source-jiutangshu-wenyuan 是 V016 已立的旧唐书文苑传源（李商隐传在此，简化字录入）；
--       判例在册句（义山/开成二年/岭表/三十六体 V016、狂夫之言 V065、避地桃源诸语 V064）
--       只对照不重开）。
--       **本迁移新建恰 1 个 source（source-ws-t300-031）——连续六首零新源诚实终结；
--       audit 断言恰一枚诗源表新建插入语句且 id 唯一、回滚按 id 删且只删此行。**
--
-- 数据源（可复现）：emit_v066.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/賈生.txt（无 Textquality 评级首见+notes 只有三百首标记+零异文标记+
--   分类四行简繁混排+Vtext/poem 双转录）、
--   全唐詩卷540（旧式裸名锚+poem 块+《安定城樓》自引句；賈生恰三闭域；
--   宣室/前席/逐臣/才調/夜半/可憐 全库存档扫描）、
--   舊唐書卷190下（李商隐段首引二句+段内诗面字全零+段边界 ==弟 羲叟== 断言）、
--   通鑑卷194/238/248（贾谊恰二+可怜恰一+三处年标题窗口）+
--   通鑑 75 卷负证计数扫描（賈生/宣室/前席/逐臣/才調/虛前席/問鬼神）+
--   既有迁移引文域逐句查重——传区间归属、二引/零重开/首引零域/新源不存在前提全部生成时断言。
--
-- 做：新 poetry_source 行 1（source-ws-t300-031，PENDING）+
--   4 BACKGROUND content/claim/background + 5 组逐字引用（(claim,source) 主键每对恰一行）+
--   4 background_line（四句七绝 **1/1/1/1 第三次**（V056/V061 之后）：scene→1 city→2
--   world→3 person→4，绑 text-work-t300-031-ws 的 4 行）+ 不碰 poetry_text_line。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「詩有賈生的場景，史部只有賈誼的话头」）：
--   * 贾生场景词通鉴全零+贾谊恰二双窗口入引+可怜恰一窗口入引（一怜劳力/一怜空才）；
--   * 「贾生见而空/义山不见」错位对照标明读法声明；「名宦不进，坎壈终身」标明史臣自断；
--   * 同卷同诗人自引（虛前席/虛垂涕）系卷540 恰三闭域上的照登，非外部佐证；
--   * 无评级页/分类四行/简繁混排均照登不判（选本标记与转录评级、编排与史料是两回事）；
--   * 新源恰一枚如实开例（两引面不重叠声明在案），审计断言唯一性，回滚可精确撤销；
--   * 全唐詩宣室/前席/逐臣/才調/夜半/可憐在册零入引（audit 硬卡零混入）；
--   * KNOWN 零如实记录（第廿二例，audit 反向断言 SQL 无 KNOWN 字面量）；
--   * 义山/开成二年/岭表/三十六体/荥阳卒（V016）、狂夫之言（V065）判例只对照不重开。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 65，不含 66
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-031-%';             -- 空
--   SELECT id FROM poetry_source WHERE id IN ('source-ws-t300-031','source-quantangshi-540');  -- 只含 540
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-031-ws';  -- 恰 4
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-031-%';       -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-031';                                  -- 4（1/1/1/1）
--   SELECT certainty FROM poetry_claim WHERE id LIKE 'claim-bg-031-%';  -- 四行全 LIKELY（有意全 LIKELY）
--   SELECT COUNT(*) FROM poetry_source WHERE id='source-ws-t300-031';   -- 恰 1（本迁移新建）
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-031'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-031';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-031-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
-- 回滚: recovery/V066_rollback.sql（按 id 全枚举删除；source 只删本迁移新建的
--   source-ws-t300-031 一行——source-quantangshi-540 系 V018 所立绝不删）
START TRANSACTION;

-- ---------- 0. 新 source 恰一枚（source-ws-t300-031 选本页；PENDING 照 V031/V035/V036 判例） ----------
INSERT INTO poetry_source (id, title, author, edition, url, rights_note, verification_status, source_kind, reliability)
SELECT * FROM (
SELECT 'source-ws-t300-031' AS id, '维基文库《唐詩三百首》页面：賈生' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/賈生' AS url, '维基文库录入本，公有领域古籍。本行由 emit_v066.py 对 /tmp/src-dl 快照逐字定位。本诗 V018 立正文时用的是《全唐詩》卷540 卷页（source-quantangshi-540，version_code vol-raw），此《唐詩三百首》选本页当时未建源——卷页与诗页是两个独立见证面（卷页锚点归属 vs 选本页 header 署名/底注/分类），本迁移引诗页非新源不能承载。页面 notes 只有 {{唐詩三百首}} 标记而无 Textquality 评级（系列唯一无评级页照登）；页内 Vtext/poem 双转录并存；分类四行含简体「唐诗」与繁体「唐詩三百首」同页混排（照登）。核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status, 'POETRY_COLLECTION' AS source_kind, 'HIGH' AS reliability FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_source x WHERE x.id = t.id);

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-031-scene' AS id, 'BACKGROUND' AS entity_type, '031-scene' AS slug, '眼前：宣室那场没问对的夜谈' AS title, '四层处境背景（阶段 D 第 47 首·四句七绝 1/1/1/1 第三次）；史实句均有逐字引证；系年第四十一次判决（题证系列第廿九状·贾生与可怜）「詩有賈生的場景，史部只有賈誼的话头」——同字两界第十一形态·咏史形态首见：通鉴賈生/宣室/前席/逐臣/才調/虛前席/問鬼神全零；賈誼恰二闭域双窗口入引（貞觀八年甲午六三四魏徵引「可為痛哭者一」对+元和七年壬辰八一二李絳引「厝火積薪之下不可謂安」——史部贾谊=谏臣话头/诗贾谊=灯火场景）；可憐恰一闭域窗口入引（會昌六年丙寅八四六「可憐彼翁每歲受撻」——一怜劳力/一怜空才）；全唐詩宣室恰 4/前席恰 2/逐臣恰 3/才調恰 3/夜半恰 9/可憐恰 39在册零入引；卷540「賈生」恰三=锚+正文+《安定城樓》「賈生年少虛垂涕」**同卷同诗人自引首见（虛前席/虛垂涕双虚字）**；ws 页**无 Textquality 评级页首见**（notes 只有三百首标记）+分类四行系列最多首录+同页简繁混排（简体「唐诗」繁体「唐詩三百首」）首见照登；**新建 source-ws-t300-031 恰一枚（连续六首零新源诚实终结——V018 以卷540 卷页立诗、ws 选本页从未建源，卷页/诗页两个独立见证面；audit 断言恰一枚新源 INSERT）**；正文第二引上限用满第十四例（V018 卷页在先+双针恰一，两引面不重叠）；PERSON 旧传简化字段首引二句（绹不之省+名宦不进坎壈终身——贾生见而空/义山不见的错位读法声明）；旧传段贾生/苍生/鬼神/宣室/前席全零；KNOWN 零如实记录（第廿二例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-031-city' AS id, 'BACKGROUND' AS entity_type, '031-city' AS slug, '这座城：同一卷里两个虛字' AS title, '四层处境背景（阶段 D 第 47 首·四句七绝 1/1/1/1 第三次）；史实句均有逐字引证；系年第四十一次判决（题证系列第廿九状·贾生与可怜）「詩有賈生的場景，史部只有賈誼的话头」——同字两界第十一形态·咏史形态首见：通鉴賈生/宣室/前席/逐臣/才調/虛前席/問鬼神全零；賈誼恰二闭域双窗口入引（貞觀八年甲午六三四魏徵引「可為痛哭者一」对+元和七年壬辰八一二李絳引「厝火積薪之下不可謂安」——史部贾谊=谏臣话头/诗贾谊=灯火场景）；可憐恰一闭域窗口入引（會昌六年丙寅八四六「可憐彼翁每歲受撻」——一怜劳力/一怜空才）；全唐詩宣室恰 4/前席恰 2/逐臣恰 3/才調恰 3/夜半恰 9/可憐恰 39在册零入引；卷540「賈生」恰三=锚+正文+《安定城樓》「賈生年少虛垂涕」**同卷同诗人自引首见（虛前席/虛垂涕双虚字）**；ws 页**无 Textquality 评级页首见**（notes 只有三百首标记）+分类四行系列最多首录+同页简繁混排（简体「唐诗」繁体「唐詩三百首」）首见照登；**新建 source-ws-t300-031 恰一枚（连续六首零新源诚实终结——V018 以卷540 卷页立诗、ws 选本页从未建源，卷页/诗页两个独立见证面；audit 断言恰一枚新源 INSERT）**；正文第二引上限用满第十四例（V018 卷页在先+双针恰一，两引面不重叠）；PERSON 旧传简化字段首引二句（绹不之省+名宦不进坎壈终身——贾生见而空/义山不见的错位读法声明）；旧传段贾生/苍生/鬼神/宣室/前席全零；KNOWN 零如实记录（第廿二例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-031-world' AS id, 'BACKGROUND' AS entity_type, '031-world' AS slug, '这个天下：史部只有贾谊的话头' AS title, '四层处境背景（阶段 D 第 47 首·四句七绝 1/1/1/1 第三次）；史实句均有逐字引证；系年第四十一次判决（题证系列第廿九状·贾生与可怜）「詩有賈生的場景，史部只有賈誼的话头」——同字两界第十一形态·咏史形态首见：通鉴賈生/宣室/前席/逐臣/才調/虛前席/問鬼神全零；賈誼恰二闭域双窗口入引（貞觀八年甲午六三四魏徵引「可為痛哭者一」对+元和七年壬辰八一二李絳引「厝火積薪之下不可謂安」——史部贾谊=谏臣话头/诗贾谊=灯火场景）；可憐恰一闭域窗口入引（會昌六年丙寅八四六「可憐彼翁每歲受撻」——一怜劳力/一怜空才）；全唐詩宣室恰 4/前席恰 2/逐臣恰 3/才調恰 3/夜半恰 9/可憐恰 39在册零入引；卷540「賈生」恰三=锚+正文+《安定城樓》「賈生年少虛垂涕」**同卷同诗人自引首见（虛前席/虛垂涕双虚字）**；ws 页**无 Textquality 评级页首见**（notes 只有三百首标记）+分类四行系列最多首录+同页简繁混排（简体「唐诗」繁体「唐詩三百首」）首见照登；**新建 source-ws-t300-031 恰一枚（连续六首零新源诚实终结——V018 以卷540 卷页立诗、ws 选本页从未建源，卷页/诗页两个独立见证面；audit 断言恰一枚新源 INSERT）**；正文第二引上限用满第十四例（V018 卷页在先+双针恰一，两引面不重叠）；PERSON 旧传简化字段首引二句（绹不之省+名宦不进坎壈终身——贾生见而空/义山不见的错位读法声明）；旧传段贾生/苍生/鬼神/宣室/前席全零；KNOWN 零如实记录（第廿二例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-031-person' AS id, 'BACKGROUND' AS entity_type, '031-person' AS slug, '这个人：求见而不被见' AS title, '四层处境背景（阶段 D 第 47 首·四句七绝 1/1/1/1 第三次）；史实句均有逐字引证；系年第四十一次判决（题证系列第廿九状·贾生与可怜）「詩有賈生的場景，史部只有賈誼的话头」——同字两界第十一形态·咏史形态首见：通鉴賈生/宣室/前席/逐臣/才調/虛前席/問鬼神全零；賈誼恰二闭域双窗口入引（貞觀八年甲午六三四魏徵引「可為痛哭者一」对+元和七年壬辰八一二李絳引「厝火積薪之下不可謂安」——史部贾谊=谏臣话头/诗贾谊=灯火场景）；可憐恰一闭域窗口入引（會昌六年丙寅八四六「可憐彼翁每歲受撻」——一怜劳力/一怜空才）；全唐詩宣室恰 4/前席恰 2/逐臣恰 3/才調恰 3/夜半恰 9/可憐恰 39在册零入引；卷540「賈生」恰三=锚+正文+《安定城樓》「賈生年少虛垂涕」**同卷同诗人自引首见（虛前席/虛垂涕双虚字）**；ws 页**无 Textquality 评级页首见**（notes 只有三百首标记）+分类四行系列最多首录+同页简繁混排（简体「唐诗」繁体「唐詩三百首」）首见照登；**新建 source-ws-t300-031 恰一枚（连续六首零新源诚实终结——V018 以卷540 卷页立诗、ws 选本页从未建源，卷页/诗页两个独立见证面；audit 断言恰一枚新源 INSERT）**；正文第二引上限用满第十四例（V018 卷页在先+双针恰一，两引面不重叠）；PERSON 旧传简化字段首引二句（绹不之省+名宦不进坎壈终身——贾生见而空/义山不见的错位读法声明）；旧传段贾生/苍生/鬼神/宣室/前席全零；KNOWN 零如实记录（第廿二例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-031-scene' AS id, 'bg-031-scene' AS subject_id, 'context' AS property_key, '四句七绝本文（ws 选本页 poem 块；页内 Vtext/poem 双转录并存恰 2，各从其录）；notes 只有 {{唐詩三百首}} 选本标记而无 Textquality 评级——无评级页系列首见；{{另}}/{{別}}/{{*}}/<ref> 全零；全句第二引：正文 V018 卷540 卷页 claim 一引在先（生成时全库查重双针「宣室求賢訪逐臣」「不問蒼生問鬼神」各恰一处），本迁移引 ws 诗页——两引两面（卷页+诗页）上限恰满不重叠；两度上限至此用满、此诗正文对后来迁移关闭（audit 硬卡）。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-031-city' AS id, 'bg-031-city' AS subject_id, 'context' AS property_key, '卷540「賈生」恰三=锚+正文+《安定城樓》自引（机器断言闭域）——同诗人同卷自引首见（虛前席/虛垂涕双虚字；安定城樓句全库域恰零本迁移首引）；卷页旧式裸名锚「==賈生==」无消歧器（同名则无消歧器判例延展至旧式卷页，audit 照登硬卡锚字样）；ws 页分类四行系列最多首录+同页简繁混排（简体「唐诗」与繁体「唐詩三百首」并存）照登；分类行非史料声明+不升格（V048 判例）；sortkey「|李」系编排动作；**新建 source-ws-t300-031 恰一枚**（V018 以卷540 卷页立本诗、ws 诗页从未建源——卷页与诗页两个独立见证面；audit 断言恰一枚新源 INSERT 且 id 唯一）。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-031-world' AS id, 'bg-031-world' AS subject_id, 'context' AS property_key, '通鉴「賈生/宣室/前席/逐臣/才調/虛前席/問鬼神」全零（诗的场景不在史部，机器断言）；「賈誼」恰二闭域双窗口逐字入引=貞觀八年（甲午，六三四）魏徵引「可為痛哭者一」对+元和七年（壬辰，八一二）李絳引「厝火積薪之下，不可謂安」（史部贾谊=谏臣话头，诗贾谊=灯火场景——同字两界第十一形态·咏史形态首见，audit 硬卡；痛哭对切片止于引文处，未及同段 V065 已引「狂夫之言」句——零重开）；「可憐」恰一闭域窗口入引=會昌六年（丙寅，八四六）「可憐彼翁每歲受撻」（一怜劳力/一怜空才）；全唐詩宣室恰 4/前席恰 2/逐臣恰 3/才調恰 3/夜半恰 9/可憐恰 39 在册零入引（机器断言）；certainty 不覆盖任何系年，诗 time.span/event.name/written_during 零铸造零 relation（audit 硬卡）。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-031-person' AS id, 'bg-031-person' AS subject_id, 'context' AS property_key, '旧传李商隐段（简化字录入，引文照登简体原样）首引二句皆生成时全库查重域恰零=「明年，令狐绹作相，商隐屡启陈情，绹不之省。」+「名宦不进，坎壈终身。」（传区间归属机器断言）；「同一种错位：贾生见而空/义山不见」系读法声明；「名宦不进，坎壈终身」系史臣自断（照登 LIKELY）；字义山/开成二年/随亚岭表/三十六体/府罷客滎陽诸在册句（V016）零重开；旧传李商隐段賈生/賈誼/蒼生/鬼神/宣室/前席全零（机器断言）；本诗无底注无岁数注（无注可登）；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-031-scene' AS subject_id, 'context' AS property_key, 'claim-bg-031-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-031-city' AS subject_id, 'context' AS property_key, 'claim-bg-031-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-031-world' AS subject_id, 'context' AS property_key, 'claim-bg-031-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-031-person' AS subject_id, 'context' AS property_key, 'claim-bg-031-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-031-scene' AS id, 'work-t300-031' AS work_id, 'SCENE' AS layer, '四句是一次没问对的夜谈：宣室求贤，访的是逐臣（「宣室求賢訪逐臣，賈生才調更無倫」）——汉文帝在宣室召见被贬的贾谊，天下第一等的才调；可怜夜半文帝不知不觉把坐席挪到贾生跟前（「可憐夜半虛前席」）——不问苍生的生计，问鬼神的所以然（「不問蒼生問鬼神」）。ws 诗页 notes **只有 {{唐詩三百首}} 选本标记而无任何 Textquality 评级**（无评级页系列首见——选本标记与转录评级是两回事）；{{另}}/{{別}}/{{*}}/<ref> 全零；页内 Vtext/poem 双转录并存（「宣室求賢訪逐臣」页内恰 2，各从其录）。此诗正文系**第二引**：V018 卷540 卷页一引在先，本迁移引 ws 选本页——**两引两面（卷页+诗页），上限恰满而不重叠**；生成时全库查重双针各恰一处，两度上限至此用满，此诗正文对后来迁移关闭。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-031-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-031-city' AS id, 'work-t300-031' AS work_id, 'CITY' AS layer, '卷540 侧：**「賈生」恰三处**（机器断言闭域）=本篇篇题锚「==賈生==」（卷页旧式裸名锚，无消歧器——同名则无消歧器判例延展至旧式卷页）+本篇正文「賈生才調更無倫」+**《安定城樓》「賈生年少虛垂涕」**——**同一卷里看得见李商隱把贾生又用了一次**：本篇替贾生问「虛前席」（君王白挪近了坐席），《安定城樓》以贾生自嘲「虛垂涕」（自己的眼泪白流）——**两个「虛」字，同诗人同卷自引首见**（安定城樓句全库域恰零，本迁移首引）。ws 诗页分类四行「李商隱+唐诗+唐詩三百首|李+七言絕句」——**系列最多（首录）**；第三行简体「唐诗」与第四行繁体「唐詩」同页并存——**同页分类简繁混排首见**（照登）；sortkey「|李」系编排动作。四行系整理者分类（V048 判例：非史料声明、不升格）。**本迁移新建 1 个 source（source-ws-t300-031）**：V018 以卷540 卷页立本诗（source-quantangshi-540，version_code vol-raw），ws《唐詩三百首》诗页从未建源——卷页与诗页是两个独立见证面（锚点归属 vs 选本转录），非新源不能承载诗页逐字引文；audit 断言恰一枚新源 INSERT。（本层零 relation。）' AS body_text, 'JUNIOR' AS audience, 'claim-bg-031-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-031-world' AS id, 'work-t300-031' AS work_id, 'WORLD' AS layer, '**詩有賈生的場景，史部只有賈誼的话头**（同字两界第十一形态·咏史形态首见）：通鉴「賈生」「宣室」「前席」「逐臣」「才調」「虛前席」「問鬼神」全零（机器断言——诗重构的那场君臣夜谈整个不在史部）；而「**賈誼**」恰二处（闭域+双窗口逐字入引）：貞觀八年（甲午，六三四）魏徵对太宗「**賈誼當漢文帝時上書，云『可為痛哭者一，可為流涕者二。』**」、元和七年（壬辰，八一二）李絳拒「天下已太平」之颂「**漢文帝時兵木無刃，家給人足，賈誼猶以為厝火積薪之下，不可謂安。**」——**史部的贾谊是谏臣嘴里的话头（引经据证的权威），诗的贾谊是灯火底下的场景（宣室、夜半、前席、鬼神）：史部引用他，诗进入他的那个夜晚**。「**可憐**」通鉴恰一处（闭域+窗口入引）——會昌六年（丙寅，八四六）知贡举者语「**可憐彼翁每歲受撻！**」：史部唯一的「可怜」可怜的是年年受杖催试期的老吏；诗「可憐夜半虛前席」可怜的是见遇如天却问错了方向的天才——**同一个怜字，一怜其劳力，一怜其空才**。全唐詩侧在册零入引（机器断言）：「宣室」恰 4 四卷、「前席」恰 2、「逐臣」恰 3、「才調」恰 3、「夜半」恰 9 八卷、「可憐」恰 39——诗眼词都有别人用，史部却不接这个场景。本层零铸造零 relation。' AS body_text, 'SENIOR' AS audience, 'claim-bg-031-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-031-person' AS id, 'work-t300-031' AS work_id, 'PERSON' AS layer, '旧传李商隐段（**简化字录入**，V016 locator 已注，本层引文照登简体原样）首引二句（皆生成时全库查重域恰零）：「**明年，令狐绹作相，商隐屡启陈情，绹不之省。**」「**名宦不进，坎壈终身。**」
**同一种错位，两界各记一半**（读法声明，非史实）：诗的贾生是**见遇而问错了方向**（宣室夜半，虚前席，不问苍生问鬼神），传的李商隐是**求见而根本不被见**（屡启陈情，绹不之省）——贾生之怜在见而空，义山之困在不见。
「名宦不进，坎壈终身」系**史臣自断**（照登，certainty LIKELY——史臣语非自家语）；传之脉络在册句零重开：字义山（V016）、开成二年登第（V016）、随郑亚岭表（V016）、三十六体（V016）、新传「府罷，客滎陽，卒」（V016）。**旧传李商隐段賈生/賈誼/蒼生/鬼神/宣室/前席全零**（机器断言——写尽贾生夜谈的人，传里没有一个贾生字）；certainty 不覆盖任何系年，本诗无底注无岁数注（无注可登），诗 time.span/event.name/written_during 仍零铸造（audit 硬卡）。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-031-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-031-scene' AS claim_id, 'source-ws-t300-031' AS source_id, '页面 賈生（《唐詩三百首》第 31 首选本页；header author+poem 块四句——全句**第二引**：V018 卷540 卷页一引在先，本引系 ws 诗页第二面——**两引面不重叠，上限恰满**，生成时全库查重双针恰一处，此后此诗正文关闭；notes 无 Textquality 评级（无评级页首见）；{{另}}/{{別}}/{{*}}/<ref> 全零；页内 Vtext/poem 双转录并存各从其录）' AS locator, '| author   = 李商隱……宣室求賢訪逐臣，賈生才調更無倫。
可憐夜半虛前席，不問蒼生問鬼神。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-031-city' AS claim_id, 'source-ws-t300-031' AS source_id, '页面 賈生（header title+整页 notes 行+分类四行连片——notes 只有三百首选本标记而无评级=无评级页首见；分类四行系列最多首录：第三行简体「唐诗」与第四行繁体「唐詩三百首」同页混排首见照登；分类行与 sortkey 系整理者/编排动作：非史料声明、不升格）' AS locator, '| title    = 賈生……| notes    = {{唐詩三百首}}……[[Category:李商隱]]
[[Category:唐诗]]
[[Category:唐詩三百首|李]]
[[Category:七言絕句]]' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-031-city' AS claim_id, 'source-quantangshi-540' AS source_id, '卷五百四十·李商隱《賈生》块（锚「==賈生==」卷页旧式裸名+poem 四句）……《安定城樓》「賈生年少虛垂涕，王粲春來更遠遊。」句（**同卷自引**——卷540「賈生」恰三=锚+正文+自引机器断言；虛前席/虛垂涕双虚字同诗人首见；安定城樓句全库域恰零本迁移首引；源行系 V018 已立、本迁移复用零新建）' AS locator, '==賈生==
<poem>
宣室求賢訪逐臣，賈生才調更無倫。
可憐夜半虛前席，不問蒼生問鬼神。
</poem>……賈生年少虛垂涕，王粲春來更遠遊。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-031-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '卷一百九十四·貞觀八年（甲午，六三四）魏徵引賈誼痛哭对段……卷二百三十八·元和七年（壬辰，八一二）李絳引厝火積薪段……卷二百四十八·會昌六年（丙寅，八四六）可憐彼翁受撻段（**通鉴賈生/宣室/前席/逐臣/才調全零、賈誼恰二、可憐恰一**：文件闭域+三处年标题窗口机器断言——史部只有贾谊的话头，唯一的可怜怜的是科场老吏；三段史文逐字入引为判决证据；痛哭对切片未及同段既有已引语——零重开；全唐詩在册句零入引）' AS locator, '賈誼當漢文帝時上書，云『可為痛哭者一，可為流涕者二。』……漢文帝時兵木無刃，家給人足，賈誼猶以為厝火積薪之下，不可謂安。……可憐彼翁每歲受撻！' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-031-person' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '舊唐書卷一九〇下·李商隱（**简化字录入**照登原样，V016 locator 同款标注）（「绹不之省」句+「名宦不进，坎壈终身。」句——皆全库查重恰零域首引；传区间归属机器断言；后者系史臣自断非自家语；「屡启而不见/见而空」对照系读法声明；字义山/岭表/三十六体诸在册句零重开）' AS locator, '明年，令狐绹作相，商隐屡启陈情，绹不之省。……名宦不进，坎壈终身。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（四句七绝 1/1/1/1 第三次） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-031-scene' AS background_id, 'text-work-t300-031-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-031-city' AS background_id, 'text-work-t300-031-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-031-world' AS background_id, 'text-work-t300-031-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-031-person' AS background_id, 'text-work-t300-031-ws' AS version_id, 4 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 66, 'Li Shang-yin''s Jia Yi (work-t300-031) background layers (stage-D poem 47, four-line jueju 1/1/1/1 third time): dating verdict forty-one, twenty-ninth shape of the title-evidence series -- Jia Sheng and kelian, the archaist split in two realms: the poem stages Jia Yi''s night audience -- the Xuan-hall summons, the midnight席 moved forward, the questions about ghosts instead of the people -- and every staging word (Jia-sheng, xuanshi, qianxi, zhuchen, caidiao, wen guishen) scores zero across the Tongjian (machine-asserted); yet Jia Yi himself appears exactly twice, both as a talking point quoted by remonstrators at court: Wei Zheng citing the "one thing to weep over" memorial (Zhenguan 8th, jiawu, 634) and Li Ziang citing "fire stacked under firewood" to refuse a peace celebration (Yuanhe 7th, renchen, 812) -- the histories quote him, the poem enters his night (the eleventh same-character split, first archaist shape); kelian appears exactly once -- "pity that old man, flogged year after year" over the exam-reminders (Huichang 6th, bingyin, 846): the histories'' pity is for a beaten clerk, the poem''s pity is for a genius asked the wrong questions; juan 540 holds exactly three Jia-sheng characters (closed-domain assert): this poem''s anchor, this poem''s line, and Li Shang-yin''s own self-quote in "Ascending the City of Ding''an" -- "Jia Yi wasted his tears when young" -- two xu (in-vain) characters, one poet, one scroll (first self-quote seen: wasted-the-seat / wasted-the-tears); the ws anthology page carries no Textquality grade at all (first grade-less page; the marker in notes is the selection mark, not a transcription grade) with four category rows (series most, first) mixing simplified tang-shi and traditional tang-shi-shi-baishou on one page (logged); PERSON first-cites two zero-domain sentences from the simplified-character JTS biography -- "Tao never glanced at his letters" and "office never advanced; hardship to the end" (the historian''s own verdict, logged as such): Jia Yi was seen and asked wrongly, Li Shang-yin was never seen at all (reading declared); the biography segment contains no Jia-sheng/cangshen/guishen/xuanshi/qianxi character (machine-asserted); exactly ONE new poetry_source row (source-ws-t300-031): V018 had sourced the poem from the juan-540 scroll page and the ws anthology page had never been sourced -- two independent witnesses (anchor attribution vs anthology header/notes/categories), so the honest zero-new-source streak of six poems ends here by principle, audit-asserted single INSERT, rollback deletes only this row; body quotes hit their two-use ceiling (V018 scroll-page citation first, twin needles; the two witnesses never overlap); KNOWN zero honestly recorded (twenty-second instance, audit reverse-asserts); closed precedent keywords stay out of citations'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 66);
COMMIT;
