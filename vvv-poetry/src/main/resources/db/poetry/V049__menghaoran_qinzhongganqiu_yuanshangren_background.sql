-- V049：孟浩然《秦中感秋寄遠上人》(work-t300-112) 四层背景（阶段 D 第 30 首·八句律詩）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V014、V015、V016、V018、V031 已执行（work-t300-112 与其 text-work-t300-112-ws、
--       source-ws-t300-112 是 V018 的行；source-xintangshu-wenyi 是 V016 的行；
--       source-quantangshi-160 是 V031 的行——均不另开；本迁移通鉴只做负证扫描零入引）。
--       本迁移零新 source（断言）。
--
-- 数据源（可复现）：emit_v049.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/秦中感秋寄遠上人.txt（<ref> 标记体系首见，异文照登断言跨体系复用）、
--   舊唐書卷190下 / 新唐書卷203（孟段负证+匿床段）、全唐詩卷160（两枚篇题锚点）、
--   通鑑卷191–265+全唐詩 120 卷（负证计数扫描）——
--   传区间归属、京師三处位置、慧遠/遠公/遠上人精确计数全部生成时断言。
--
-- 做：0 个新 source（断言）+ 4 BACKGROUND content/claim/background +
--   5 组逐字引用（(claim,source) 主键每对恰一行）+
--   8 行 background_line（八句形制 2/2/2/2，绑 text-work-t300-112-ws 的 8 行）。
--   本迁移不碰 poetry_text_line。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--   **不裁决署名异说**（河嶽稱崔/小注归孟/崔集不载三重并列；孟集寄崔锚点只登语境不挪砝码）。
--
-- 诚实边界（这首的边界是「題有地而地屬它事、詩有主而主有異說」）：
--   * 系年链条断在**作者**这一环之前——异说登记不裁决，年份更无从属；
--   * 秦中=京畿：两传孟区间零见、京師三处全落已两入/三入旧事（位置断言，零重引）；
--   * 东林典：慧遠通鉴+全唐詩计数全零、遠公全唐詩恰九处而卷160 零——典无史源（V046 同族）；
--   * 遠上人：通鉴零、全唐詩恰六处（卷160 恰四=两枚篇题各两次）——人有诗证而无史证；
--   * KNOWN 零如实记录（audit 反向断言 SQL 无 KNOWN 字面量）；
--   * 归隐本钱/米价语法/躲床与志衰并置均为读法声明，audit 双声明在 BG 文本内；
--   * 不才明主棄/奈何誣我/放還/韓朝宗/遑恤他/鹿門/孟亭/畫浩然像/年四十/
--     應進士不第/署為從事/不逹而卒/以詩自適 判例只引不重开。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 48，不含 49
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-112-%';             -- 空
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-112-ws';  -- 恰 8
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-112-%';       -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-112';                                  -- 8（2/2/2/2）
--   SELECT certainty FROM poetry_claim WHERE id LIKE 'claim-bg-112-%';  -- 四行全 LIKELY（有意全 LIKELY）
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-112'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-112';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-112-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
-- 回滚: recovery/V049_rollback.sql（按 id 全枚举删除；不动 V014/V015/V016/V018/V031 的行，不动共用来源行）
START TRANSACTION;

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-112-scene' AS id, 'BACKGROUND' AS entity_type, '112-scene' AS slug, '眼前：秋天的自辩' AS title, '四层处境背景（阶段 D 第 30 首·八句律詩 2/2/2/2）；史实句均有逐字引证；background_line 八句形制：每层 2 行；系年第二十四次判决「題有地而地屬它事、詩有主而主有異說」（题证系列第十二状·首见断链在署名——署名异说三重并列在场，系年链条断在作者之前）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 零如实记录（匿床段单得、典与人都无史证——都不升）；负证机器复查三层（秦中零见+京師三处位置断言/慧遠全库零见+遠公精确九处/遠上人精确六处且卷160 精确四处）；<ref> 标记体系首见——异文照登断言首次跨标记体系复用（北上/旦夕两支硬卡）；底注三重断言用于署名异说（非史料+不升格+不裁决）；判例与两度上限零重引（不才/放還/韓朝宗/京師诸旧事句关键语硬卡）。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-112-city' AS id, 'BACKGROUND' AS entity_type, '112-city' AS slug, '这座城：连作者都并列着' AS title, '四层处境背景（阶段 D 第 30 首·八句律詩 2/2/2/2）；史实句均有逐字引证；background_line 八句形制：每层 2 行；系年第二十四次判决「題有地而地屬它事、詩有主而主有異說」（题证系列第十二状·首见断链在署名——署名异说三重并列在场，系年链条断在作者之前）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 零如实记录（匿床段单得、典与人都无史证——都不升）；负证机器复查三层（秦中零见+京師三处位置断言/慧遠全库零见+遠公精确九处/遠上人精确六处且卷160 精确四处）；<ref> 标记体系首见——异文照登断言首次跨标记体系复用（北上/旦夕两支硬卡）；底注三重断言用于署名异说（非史料+不升格+不裁决）；判例与两度上限零重引（不才/放還/韓朝宗/京師诸旧事句关键语硬卡）。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-112-world' AS id, 'BACKGROUND' AS entity_type, '112-world' AS slug, '这个天下：只在诗里往来的人' AS title, '四层处境背景（阶段 D 第 30 首·八句律詩 2/2/2/2）；史实句均有逐字引证；background_line 八句形制：每层 2 行；系年第二十四次判决「題有地而地屬它事、詩有主而主有異說」（题证系列第十二状·首见断链在署名——署名异说三重并列在场，系年链条断在作者之前）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 零如实记录（匿床段单得、典与人都无史证——都不升）；负证机器复查三层（秦中零见+京師三处位置断言/慧遠全库零见+遠公精确九处/遠上人精确六处且卷160 精确四处）；<ref> 标记体系首见——异文照登断言首次跨标记体系复用（北上/旦夕两支硬卡）；底注三重断言用于署名异说（非史料+不升格+不裁决）；判例与两度上限零重引（不才/放還/韓朝宗/京師诸旧事句关键语硬卡）。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-112-person' AS id, 'BACKGROUND' AS entity_type, '112-person' AS slug, '这个人：躲床的人与志衰的人' AS title, '四层处境背景（阶段 D 第 30 首·八句律詩 2/2/2/2）；史实句均有逐字引证；background_line 八句形制：每层 2 行；系年第二十四次判决「題有地而地屬它事、詩有主而主有異說」（题证系列第十二状·首见断链在署名——署名异说三重并列在场，系年链条断在作者之前）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 零如实记录（匿床段单得、典与人都无史证——都不升）；负证机器复查三层（秦中零见+京師三处位置断言/慧遠全库零见+遠公精确九处/遠上人精确六处且卷160 精确四处）；<ref> 标记体系首见——异文照登断言首次跨标记体系复用（北上/旦夕两支硬卡）；底注三重断言用于署名异说（非史料+不升格+不裁决）；判例与两度上限零重引（不才/放還/韓朝宗/京師诸旧事句关键语硬卡）。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-112-scene' AS id, 'bg-112-scene' AS subject_id, 'context' AS property_key, '八句全诗本文（ws 页 <ref> 标记体系首见——异文注两处挂 <ref> 不挂 {{另}}，audit 异文照登断言首次跨标记体系复用：北上/旦夕两支字样必在引文；Textquality 75% 如实记）；归隐本钱/米价语法为本层读法声明，非史料断言。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-112-city' AS id, 'bg-112-city' AS subject_id, 'context' AS property_key, '署名异说照登不裁决：河嶽英靈集稱崔作/其小注归孟/崔集不载三重并列（ws 页底注+题面题异<ref>，底注三重断言+非史料声明+不升格）；地属它事：秦中两传孟区间零见、京師三处逐处落进已两入/三入旧事句（位置断言，两度上限零重引）；孟集内有寄崔少府国辅诗篇题锚点（异说所涉人物在孟自有交游痕迹——只登语境，不构成任何裁决）；断链在署名→time.span/event.name/written_during 零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-112-world' AS id, 'bg-112-world' AS subject_id, 'context' AS property_key, '典无史源：慧遠通鉴+全唐詩计数全零、遠公全唐詩恰九处而卷160 零处（机器精确计数断言，快照变动即中止）——与 V046 同族；人有诗证无史证：遠上人通鉴零、全唐詩恰六处（卷160 恰四=两枚篇题各两次），卷160 篇题锚点逐字入引；季节非年份；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-112-person' AS id, 'bg-112-person' AS subject_id, 'context' AS property_key, '匿床对诗段新传单得（旧传孟段无此轶，不合龙）→不升；旧传骨架句与不才句均触两度上限零重引（audit 关键语硬卡）；躲床者与志衰者并置为读法声明；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-112-scene' AS subject_id, 'context' AS property_key, 'claim-bg-112-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-112-city' AS subject_id, 'context' AS property_key, 'claim-bg-112-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-112-world' AS subject_id, 'context' AS property_key, 'claim-bg-112-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-112-person' AS subject_id, 'context' AS property_key, 'claim-bg-112-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-112-scene' AS id, 'work-t300-112' AS work_id, 'SCENE' AS layer, '八句是一场秋天里的自辩：想卧一丘，苦于没有三径的本钱（「一丘常欲臥，三徑苦無資」——归隐也是要盘缠的）；北边的都城不是我的心愿，东林的山林才配叫我怀念的师父（「北土非吾願，東林懷我師」——一句里两个方向，此句页内挂 <ref> 异文注：北土一支，河嶽英靈集作「北上」、文苑英華作「北山」，照登不裁决）；黄金像桂一样烧尽了，壮志逐年往下掉（「黃金然桂盡，壯志逐年衰」——「然桂」即长安居大不易的米价语法）；傍晚凉风一来，听见蝉声只更添悲（「日夕涼風至，聞蟬但益悲」——此句 <ref> 注：日夕一支，文苑英華作「旦夕」，照登不裁决）。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-112-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-112-city' AS id, 'work-t300-112' AS work_id, 'CITY' AS layer, '这座「城」是秦中、是京畿——但史部不给它系年：两传孟浩然区间「秦中」计数全零、「京師」凡三处，生成时逐处定位，全落在「年四十來遊京師」「韓朝宗約浩然偕至京師」两条旧事里——地有传见、见必它事（V045 判例·都邑版），而那些它事已触两度上限，零重引。
更硬的一层在题目：页题「秦中感**秋**寄**遠**上人」，题面 <ref> 注《河嶽英靈集》题作「秦中感**興**寄**逺**上人」；页底注再照登一重异说——「《河嶽英靈集》稱崔國輔作，惟題下有小注曰：『一刻，下三首孟浩然作，崔集亦不載。』」三重说法（河嶽正文稱崔/河嶽小注归孟/崔集无此诗）并列在场，这是选本层的署名异说，非史料声明、不升格、不裁决（底注三重断言判例；tang300-variants.md 新行已登记）。连「谁的」都并列着，「哪一年」便无从属起。' AS body_text, 'SENIOR' AS audience, 'claim-bg-112-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-112-world' AS id, 'work-t300-112' AS work_id, 'WORLD' AS layer, '诗里的「我師」挂着东林典：东林=庐山东林寺，典的主人是慧远——而快照里**慧远这个名字通鉴 75 卷、全唐詩 120 卷计数全零**（生成时机器断言）；「遠公」全唐詩恰九处、卷160 零处——典在唐人它诗里活着，在史部里没有档案：与 V046 牛渚典同族——**典无史源，系年链条断在典这一环**。
收信人本身也一样：「遠上人」通鉴零见、全唐詩恰六处（卷160 恰四处——本篇与《晚春題遠上人南亭》两枚篇题各两次；卷237 恰二处，机器断言）——这个人只在诗的世界里往来：**人有诗证而无史证**。
全诗唯一的时间感「涼風至」「聞蟬」是季节不是年份。本层到此为止，不给诗铸时间。' AS body_text, 'SENIOR' AS audience, 'claim-bg-112-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-112-person' AS id, 'work-t300-112' AS work_id, 'PERSON' AS layer, '新传给了一段宫廷失仪：王维私把孟浩然邀进内署，玄宗猝至，他躲到床下，王维如实回奏，帝说「朕聞其人而未見也，何懼而匿？」诏他出来对诗——这一段**新传单得**（旧传孟段只有「年四十來遊京師，應進士不第」的骨架句，无此轶，不合龙→LIKELY；骨架句与「不才明主棄」句均已触两度上限，零重引——audit 关键语硬卡）。
把匿床一段和「黃金然桂盡，壯志逐年衰」并排：传里他见皇帝会躲，诗里他自陈壮志年年往下掉——**躲床的人与自陈志衰的人**是同一位处士的两份档案。这是读法声明，不是史实；史实只有新传一段。判例零重开（audit 硬卡）：不才明主弃、奈何诬我、放还、韩朝宗遑恤他、鹿门、孟亭、画浩然像，本层一个不引。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-112-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-112-scene' AS claim_id, 'source-ws-t300-112' AS source_id, '页面 秦中感秋寄遠上人（header author+四联八句，五段以「……」相連——正文两处 <ref> 异文注原样入引（<ref> 标记体系首见，异文照登断言跨体系复用：北上/旦夕两支在场，登记先行于引用，tang300-variants.md 新行；无裁决）；同一 (claim,source) 主键下一行容全文判例；正文另见 V018 claim-t300-112-text——本诗正文两度上限至此用满，后来者不得三引）' AS locator, '| author   = 孟浩然……一丘常欲臥，三徑苦無資。……北土非吾願，東林懷我師。<ref>北土：《河嶽英靈集》作「北上」；《文苑英華》作「北山」</ref>……黃金然桂盡，壯志逐年衰。……日夕涼風至，聞蟬但益悲。<ref>日夕：《文苑英華》作「旦夕」</ref>' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-112-city' AS claim_id, 'source-ws-t300-112' AS source_id, '页面 秦中感秋寄遠上人（header title 含题异<ref>+页底注两字段并收——题异（感秋/感興、遠/逺）与署名异说（河嶽稱崔/小注归孟/崔集不载）均为选本层记载：照登+非史料声明+不升格（底注三重断言判例），登记不裁决；地属它事的负证为两传区间秦中零见+京師三处位置断言，生成时机器复查）' AS locator, '| title    = 秦中感秋寄遠上人<ref>《河嶽英靈集》題作〈秦中感興寄逺上人〉</ref>……| notes    = 《河嶽英靈集》稱崔國輔作，惟題下有小注曰：「一刻，下三首孟浩然作，崔集亦不載。」' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-112-city' AS claim_id, 'source-quantangshi-160' AS source_id, '卷一百六十·孟浩然集篇题锚点（孟集内另有《宿永嘉江寄山陰崔少府國輔》——署名异说所涉人物崔国辅在孟浩然自己的集子里有交游痕迹；只登语境，不构成任何裁决——异说两侧不挪砝码）' AS locator, '==[[宿永嘉江寄山陰崔少府國輔]]==' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-112-world' AS claim_id, 'source-quantangshi-160' AS source_id, '卷一百六十·孟浩然集篇题锚点（《晚春題遠上人南亭》——卷160「遠上人」恰两处之一：收信人在诗的世界里有第二首，在史部零档案；人有诗证而无史证的诗证本体，机器精确计数断言）' AS locator, '==[[晚春題遠上人南亭]]==' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-112-person' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百零三·文藝下·孟浩然传匿床对诗段（王维私邀/玄宗猝至/匿床下/诏浩然出——新传单得；句止于诏浩然出，放还及不才句触两度上限零引）' AS locator, '維私邀入内署，俄而玄宗至，浩然匿床下，維以實對，帝喜曰：「朕聞其人而未見也，何懼而匿？」詔浩然出。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（八句：2/2/2/2） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-112-scene' AS background_id, 'text-work-t300-112-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-112-scene' AS background_id, 'text-work-t300-112-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-112-city' AS background_id, 'text-work-t300-112-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-112-city' AS background_id, 'text-work-t300-112-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-112-world' AS background_id, 'text-work-t300-112-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-112-world' AS background_id, 'text-work-t300-112-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-112-person' AS background_id, 'text-work-t300-112-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-112-person' AS background_id, 'text-work-t300-112-ws' AS version_id, 8 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 49, 'Meng Haoran Autumn Thoughts in the West of the Passes, Sent to Monk Yuan background layers (stage-D poem 30, eight-line regulated verse 2/2/2/2): dating verdict twenty-four, twelfth shape of the title-evidence series and the first case where the chain breaks before authorship itself -- the title names a capital region the biographies tie only to other years (zero Qinzhong hits inside the Meng spans; all three occurrences of the capital sit inside career episodes already cited to their two-use ceiling, position-asserted, zero re-quote), the addressee monk exists only in the poetry world (zero in Tongjian; exactly six Quantangshi hits, four in juan 160 as two title anchors counted twice each, one of them a second addressed poem quoted verbatim here), the Donglin allusion has no historical trace (Huiyuan zero across both corpora; the alternative title-form exactly nine hits, none in juan 160 -- machine-counted) -- and the authorship itself carries a registered dispute: the Heiyue yingling ji names Cui Guofu while its own subnote returns the poem to Meng and the Cui collection does not carry it at all; all three claims transcribed verbatim from the page note, declared non-source, never ruled, and the same juan-160 anchor showing Meng addressing Cui in his own collection is registered strictly as context, adding no weight to either side; a first for the <ref> marker system: variant notes ride on <ref> rather than the ye-ling template, and the verbatim-variant assertion (V044 polarity) is reused across marker systems for the first time (the beishang/danxi branches hard-required in the scene excerpt); the hiding-under-the-bed audience with the emperor is new-history only (old history keeps a skeleton already at ceiling -- no agreement, no promotion); KNOWN zero honestly recorded (audit reverse-asserts); readings of retreat-as-price and the shrinking of ambition declared as readings; fourteen closed precedent keywords stay out of citations; zero new sources'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 49);
COMMIT;
