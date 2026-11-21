-- V043：王维《山居秋暝》(work-t300-134) 四层背景（阶段 D 第 24 首·八句 2/2/2/2）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V015、V016、V018 已执行（work-t300-134 与其 text-work-t300-134-ws、
--       source-ws-t300-134 是 V018 的行；source-jiutangshu-wenyuan / source-xintangshu-wenyi
--       是 V016 的行——均不另开）。本迁移零新 source（断言）。
--
-- 数据源（可复现）：emit_v043.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/山居秋暝.txt（页面零异文标记——反向断言）、
--   舊唐書卷190下（画评段+辨乐段）、新唐書卷202（画评段+辨乐段）——
--   四段切片传区间归属生成时断言。
--
-- 做：0 个新 source（断言）+ 4 BACKGROUND content/claim/background +
--   6 组逐字引用（(claim,source) 主键每对恰一行）+
--   8 行 background_line（八句形制：scene→1-2 city→3-4 world→5-6 person→7-8，
--   绑 text-work-t300-134-ws 的 8 行）。本迁移不碰 poetry_text_line。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「题有时刻无地点」）：
--   * 时刻钉死（秋暝）但为体感时刻非历法时刻；地点整个松开（题与八句零地名）；
--   * 两传之山唯辋川，V035/V039 已两度逐字立证——**同句两度为上限，本迁移不三引**；
--   * KNOWN 两处：①画得天机（画评两源合龙，阶段 D 首见艺术家技能合龙）——
--     主语是画不是诗，不外溢；②辨乐事体两源一致——措辞分歧
--     （第一拍/最初拍、人有得/客有以）各归其侧不裁决（audit 互斥）；
--   * 诗名（V035）/奉佛（V039）/鳏居（V037）判例只引不重开（audit 关键语硬卡）。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 42，不含 43
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-sq-%';              -- 空
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-134-ws';  -- 恰 8（五律）
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-sq-%';        -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-134';                                  -- 8（每层两行）
--   SELECT certainty FROM poetry_claim WHERE id IN ('claim-bg-sq-world','claim-bg-sq-person');
--     -- KNOWN / KNOWN（world=画得天机两源；person=辨乐事体两源）
--   SELECT certainty FROM poetry_claim WHERE id IN ('claim-bg-sq-scene','claim-bg-sq-city');
--     -- LIKELY / LIKELY
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-134'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-134';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-sq-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
-- 回滚: recovery/V043_rollback.sql（按 id 全枚举删除；不动 V018/V035/V039 的行，不动共用来源行）
START TRANSACTION;

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-sq-scene' AS id, 'BACKGROUND' AS entity_type, 'sq-scene' AS slug, '眼前：按感知的次序下笔' AS title, '四层处境背景（阶段 D 第 24 首·八句 2/2/2/2）；史实句均有逐字引证；background_line 八句形制：每层两行（1-2/3-4/5-6/7-8）；系年第十八次判决「题有时刻无地点」（题证系列第六状）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 两处（画得天机两源合龙——阶段 D 首见艺术家技能合龙；辨乐事体两源一致）；措辞分歧各归其侧不裁决（第一拍/最初拍，audit 互斥）；辋川段两度已立本迁移不三引；奉佛/鳏居/诗名判例只引不重开。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-sq-city' AS id, 'BACKGROUND' AS entity_type, 'sq-city' AS slug, '这座城：山没有名字' AS title, '四层处境背景（阶段 D 第 24 首·八句 2/2/2/2）；史实句均有逐字引证；background_line 八句形制：每层两行（1-2/3-4/5-6/7-8）；系年第十八次判决「题有时刻无地点」（题证系列第六状）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 两处（画得天机两源合龙——阶段 D 首见艺术家技能合龙；辨乐事体两源一致）；措辞分歧各归其侧不裁决（第一拍/最初拍，audit 互斥）；辋川段两度已立本迁移不三引；奉佛/鳏居/诗名判例只引不重开。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-sq-world' AS id, 'BACKGROUND' AS entity_type, 'sq-world' AS slug, '这个天下：两种通货' AS title, '四层处境背景（阶段 D 第 24 首·八句 2/2/2/2）；史实句均有逐字引证；background_line 八句形制：每层两行（1-2/3-4/5-6/7-8）；系年第十八次判决「题有时刻无地点」（题证系列第六状）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 两处（画得天机两源合龙——阶段 D 首见艺术家技能合龙；辨乐事体两源一致）；措辞分歧各归其侧不裁决（第一拍/最初拍，audit 互斥）；辋川段两度已立本迁移不三引；奉佛/鳏居/诗名判例只引不重开。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-sq-person' AS id, 'BACKGROUND' AS entity_type, 'sq-person' AS slug, '这个人：传里留了他的耳朵' AS title, '四层处境背景（阶段 D 第 24 首·八句 2/2/2/2）；史实句均有逐字引证；background_line 八句形制：每层两行（1-2/3-4/5-6/7-8）；系年第十八次判决「题有时刻无地点」（题证系列第六状）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 两处（画得天机两源合龙——阶段 D 首见艺术家技能合龙；辨乐事体两源一致）；措辞分歧各归其侧不裁决（第一拍/最初拍，audit 互斥）；辋川段两度已立本迁移不三引；奉佛/鳏居/诗名判例只引不重开。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-sq-scene' AS id, 'bg-sq-scene' AS subject_id, 'context' AS property_key, '八句全诗本文（ws 页零页内标记——另/别/自注三类皆无，audit 反向断言；Textquality 75% 与零标记并存如实记）；先声后形/体感之秋为本层读法声明；王孙=楚辞反用系题解通义非史料断言。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-sq-city' AS id, 'bg-sq-city' AS subject_id, 'context' AS property_key, '题钉时刻（秋暝）松地点（山居无名）；八句零地名（负证=CITY 引文只有题与署名，audit 断言引文零山名水名）；两传之山唯辋川且 V035/V039 已两度立证——本迁移不三引（边界声明）；题有时刻无地点→零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-sq-world' AS id, 'bg-sq-world' AS subject_id, 'context' AS property_key, '王维画山水得天机两源独立一致：旧传「如山水平遠…絕迹天機，非繪者之所及」+新传「天機所到，學者不及」要素对榫各成句→升 KNOWN；主语是画评不是此诗，不外溢；诗名段 V035 已判 KNOWN 只引不重开；certainty 不覆盖任何系年，诗 time.span/event.name/written_during 零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-sq-person' AS id, 'bg-sq-person' AS subject_id, 'context' AS property_key, '辨乐轶事事体两源一致（辨图乐为霓裳第三叠+召乐工验证不差）→升 KNOWN；措辞分歧（第一拍/最初拍、人有得/客有以）各归其侧不裁决（audit 互斥）；鳏居 V037/奉佛 V039 判例零重开（audit 关键语硬卡）；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-sq-scene' AS subject_id, 'context' AS property_key, 'claim-bg-sq-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-sq-city' AS subject_id, 'context' AS property_key, 'claim-bg-sq-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-sq-world' AS subject_id, 'context' AS property_key, 'claim-bg-sq-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-sq-person' AS subject_id, 'context' AS property_key, 'claim-bg-sq-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-sq-scene' AS id, 'work-t300-134' AS work_id, 'SCENE' AS layer, '八句是一场感官的点名：山是空的，因为刚下过雨（「空山新雨後」——空山不是没人，是雨把杂音洗掉了）；凉是傍晚才到的秋天（「天氣晚來秋」——秋天在体感里发生，不在日历上）；月光在松树**之间**，泉声在石头上**上面**（「明月松間照，清泉石上流」——介词是这首诗的画笔画框）；先听见竹林喧闹才知道是洗衣的姑娘回来，先看见荷叶摇动才推出渔船顺流而下（「竹喧歸浣女，蓮動下漁舟」——先声后形，诗按感知的次序下笔）；春天的芳菲随它去吧，这种人本来就该留下（「隨意春芳歇，王孫自可留」——《楚辞》「王孫兮歸來」被反着用：山在留人，不是人在恋山）。
全诗零地名——地点松开，时刻钉死。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-sq-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-sq-city' AS id, 'work-t300-134' AS work_id, 'CITY' AS layer, '「山居」之山无名，「秋暝」只是时刻：题给了**什么时候**，没给**哪里**；八句之内也没有一座可考的山。两传里王维明记的居所只有一处——辋川（V035 辋川线、V039 别名侧已两度逐字立证，**本迁移第三引都不做**：同句两度再证已是上限，三引即把「未指认」拖成「已指认」）。
诗里的山可以是辋川、可以是终南、可以是任何一座雨后的山——史料一步都不陪它走。这座「城」的档案就一句话：时刻有（秋暝，还是体感的时刻），地点无——题有时刻无地点。空山的「空」由此获得一个史料学注脚：山没有名字，所以装得下所有人。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-sq-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-sq-world' AS id, 'work-t300-134' AS work_id, 'WORLD' AS layer, '两唐书有一组罕见的**独立一致的鉴定**，主语是王维的画：
旧传「書畫特臻其妙，筆蹤措思，參於造化……如山水平遠，雲峯石色，**絕迹天機，非繪者之所及也**」；新传「**畫思入神**，至山水準遠，雲勢石色，繪工以為**天機所到，學者不及也**」——两源各自成句，要素对榫（山水之远景/云峰石色/天机之境/他人到不了）：**王维画山水得天机升 KNOWN**（阶段 D 首见艺术家技能的合龙）。
于是开天边地的文化市场上，王维的名字同时挂着两种通货：诗名（V035 已判 KNOWN，此处只引不重开）与画品（本层新判）。而《山居秋暝》恰好是画评的诗体翻版——「山水平遠，雲峯石色」与「明月松間照，清泉石上流」共享同一种取景法。但**画评主语是画不是诗**：KNOWN 不外溢给这首《山居秋暝》——审计与账本双声明。' AS body_text, 'SENIOR' AS audience, 'claim-bg-sq-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-sq-person' AS id, 'work-t300-134' AS work_id, 'PERSON' AS layer, '传里给王维留了一则两源都收的轶事，主语是他的耳朵：旧传有人拿来一幅奏乐图，王维看了一眼：「**霓裳第三疊第一拍**也」，好事者把乐工召来对着弹，「一無差，咸服其精思」；新传同一幕：客出《按樂圖》，维曰「此《霓裳》第三疊**最初拍**也」，客不信，引工按曲，「乃信」——**事体两源一致升 KNOWN**（辨图乐为霓裳第三叠+召乐工验证不差）；
**措辞分歧照登不裁决**：「第一拍」／「最初拍」、「人有得奏樂圖」／「客有以《按樂圖》示者」——各归其侧（audit 互斥断言保证不串写），这与辋川段「裴廸/裴迪」（V035）、竹溪「韓沔/韓准」（V041）同一谱系。
鳏居（V037）、奉佛（V039）两条 KNOWN 判例本迁移零重开——传里那个孤居一室的人，在这首诗里只留下「王孫自可留」五个字的背影。' AS body_text, 'SENIOR' AS audience, 'claim-bg-sq-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-sq-scene' AS claim_id, 'source-ws-t300-134' AS source_id, '页面 山居秋暝（header title+author+八句四联，六段以「……」相連——页面零异文标记（Textquality 75% 但另/别/自注三类皆无），无标记即不造标记；同一 (claim,source) 主键下一行容全文，V037/V039/V040/V041/V042 判例；全文另见 V018 claim-t300-134-text 引文）' AS locator, '| title    = 山居秋暝……| author   = 王維……空山新雨後，天氣晚來秋。……明月松間照，清泉石上流。……竹喧歸浣女，蓮動下漁舟。……隨意春芳歇，王孫自可留。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-sq-city' AS claim_id, 'source-ws-t300-134' AS source_id, '页面 山居秋暝（header title+author 两字段——负证的引文形态：只题与署名，八句诗身另在 SCENE 层，此层证据不含任何山名水名；两传辋川段 V035/V039 已两度逐字立证，本迁移不三引——边界声明）' AS locator, '| title    = 山居秋暝……| author   = 王維' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-sq-world' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十下·文苑下·王维传画评段（绝迹天机/非绘者所及——两源合龙旧传侧逐字；主语是画，不外溢到此诗）' AS locator, '書畫特臻其妙，筆蹤措思，參於造化，而創意經圖，即有所缺，如山水平遠，雲峯石色，絕迹天機，非繪者之所及也。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-sq-world' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百零二·文藝中·王维传画评段（画思入神/天机所到/学者不及——两源合龙新传侧逐字）' AS locator, '畫思入神，至山水準遠，雲勢石色，繪工以為天機所到，學者不及也。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-sq-person' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十下·文苑下·王维传辨乐段（奏乐图/霓裳第三叠第一拍/集乐工按之一无差——事体两源旧传侧；「第一拍」措辞归旧侧）' AS locator, '人有得奏樂圖，不知其名，維視之曰：「霓裳第三疊第一拍也。」好事者集樂工按之，一無差，咸服其精思。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-sq-person' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百零二·文藝中·王维传辨乐段（按乐图/霓裳第三叠最初拍/引工按曲乃信——事体两源新传侧；「最初拍」措辞归新侧，与旧侧各归其侧不裁决）' AS locator, '客有以《按樂圖》示者，無題識，維徐曰：「此《霓裳》第三疊最初拍也。」客未然，引工按曲，乃信。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（八句：每层两行） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-sq-scene' AS background_id, 'text-work-t300-134-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-sq-scene' AS background_id, 'text-work-t300-134-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-sq-city' AS background_id, 'text-work-t300-134-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-sq-city' AS background_id, 'text-work-t300-134-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-sq-world' AS background_id, 'text-work-t300-134-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-sq-world' AS background_id, 'text-work-t300-134-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-sq-person' AS background_id, 'text-work-t300-134-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-sq-person' AS background_id, 'text-work-t300-134-ws' AS version_id, 8 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 43, 'Wang Wei Mountain Dwelling Autumn Dusk background layers (stage-D poem 24, 2/2/2/2): dating verdict eighteen, sixth shape of the title-evidence series -- the title pins the moment (autumn dusk, and a bodily one: autumn arrives in the body feeling, not on the calendar) while place opens wide: no mountain-name in title or eight lines, the only recorded hill in both biographies is Wang-chuan already quoted verbatim twice (V035 the Wang-chuan line, V039 the alias side) and this migration refuses a third citation -- two re-citations of one line is the ceiling, a third would drag the unclaimed into the claimed; two KNOWNs: (1) his landscape painting reaches tian-ji -- JTS jue-ji tian-ji fei hui-zhe suo-ji plus XTS tian-ji suo-dao xue-zhe bu-ji, element-for-element across independent wordings, the stage-D first two-source agreement on an artistic skill, strictly about the paintings and never overflowing to this poem; (2) the music-score anecdote as a fact agrees across both histories (identifies the score as the third die of Rainbow-Feather, musicians summoned confirm) while the wording diverges (di-yi-pai vs zui-chu-pai; a person obtained vs a guest presented) -- each kept on its own side, un-ruled, mutual-exclusion asserted, same family as the Pei-di variant (V035) and Han-Mian/Han-Zhun (V041); the fame/poverty-piety/widower lines stay closed precedents (audit keyword zero-entry); zero new sources'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 43);
COMMIT;
