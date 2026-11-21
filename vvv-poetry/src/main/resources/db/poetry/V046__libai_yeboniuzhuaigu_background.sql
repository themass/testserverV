-- V046：李白《夜泊牛渚懷古》(work-t300-328) 四层背景（阶段 D 第 27 首·八句 2/2/2/2）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V015、V016、V018 已执行（work-t300-328 与其 text-work-t300-328-ws、
--       source-ws-t300-328 是 V018 的行；source-jiutangshu-wenyuan / source-xintangshu-wenyi
--       是 V016 的行——均不另开）。本迁移零新 source（断言）。
--
-- 数据源（可复现）：emit_v046.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/夜泊牛渚懷古.txt（两处 {{另}} 自注原样照登+底注照登并声明非史料）、
--   舊唐書卷190下（逸才句）、新唐書卷202（苏颋赏句）——两段切片传区间归属生成时断言；
--   典实扫描（通鉴 75 卷+全唐詩 120 卷袁宏/谢尚计数全零）、牛渚位置断言
--   （旧传零见/新传一处且必落青山终焉句内）——全部生成时断言（负证机器复查）。
--
-- 做：0 个新 source（断言）+ 4 BACKGROUND content/claim/background +
--   4 组逐字引用（(claim,source) 主键每对恰一行）+
--   8 行 background_line（八句形制：scene→1-2 city→3-4 world→5-6 person→7-8，
--   绑 text-work-t300-328-ws 的 8 行）。本迁移不碰 poetry_text_line。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「题有典地，典无史源」）：
--   * 诗所怀之典（谢尚闻袁宏咏史）在通鉴/全唐詩/两传李白区间计数全零——
--     系年链条断在「典」这一环，断的不是年份，是年份的上游；
--   * 页底注「此地即謝尚聞袁宏詠史處」为整理者典实地注——照登、声明非史料，
--     不升格为典实来源（V040「時年十七」底注判例同族）；
--   * 整首零 KNOWN：苏颋赏新传单得、逸才句旧传单得——都不合龙不升
--     （audit 反向断言：出现 KNOWN 即 fail，V042 判例）；
--   * 青山终焉句 V016/V032/V036 已三入——本迁移零引（负证靠位置不靠引用）；
--     逸才句 V032 第一证此处第二证达上限；
--   * 谪仙人（V036）/竹溪六逸（V041）/脱靴斥去（V041）/崔宗之采石锦袍（V032/V045）
--     判例只引不重开（audit 关键语硬卡）。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 45，不含 46
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-nz-%';              -- 空
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-328-ws';  -- 恰 8（五律）
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-nz-%';        -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-328';                                  -- 8（每层两行）
--   SELECT certainty FROM poetry_claim WHERE id LIKE 'claim-bg-nz-%';   -- 四行全 LIKELY（有意全 LIKELY）
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-328'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-328';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-nz-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
-- 回滚: recovery/V046_rollback.sql（按 id 全枚举删除；不动 V018/V032/V036/V045 的行，不动共用来源行）
START TRANSACTION;

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-nz-scene' AS id, 'BACKGROUND' AS entity_type, 'nz-scene' AS slug, '眼前：什么都没遮的夜空' AS title, '四层处境背景（阶段 D 第 27 首·八句 2/2/2/2）；史实句均有逐字引证；background_line 八句形制：每层两行（1-2/3-4/5-6/7-8）；系年第二十一次判决「题有典地，典无史源」（题证系列第九状·首见断链在典不在年）→time.span/event.name/written_during 全缺席、零 relation；整首零 KNOWN 如实记录（audit 反向断言，V042 判例）；典实负证三层机器复查（通鉴 75 卷+全唐詩 120 卷袁宏谢尚计数全零/牛渚位置断言/两传区间零见）；青山终焉句三入零引；逸才句第二证达两度上限；页底注照登并声明非史料。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-nz-city' AS id, 'BACKGROUND' AS entity_type, 'nz-city' AS slug, '这座城：连一块碑都没有' AS title, '四层处境背景（阶段 D 第 27 首·八句 2/2/2/2）；史实句均有逐字引证；background_line 八句形制：每层两行（1-2/3-4/5-6/7-8）；系年第二十一次判决「题有典地，典无史源」（题证系列第九状·首见断链在典不在年）→time.span/event.name/written_during 全缺席、零 relation；整首零 KNOWN 如实记录（audit 反向断言，V042 判例）；典实负证三层机器复查（通鉴 75 卷+全唐詩 120 卷袁宏谢尚计数全零/牛渚位置断言/两传区间零见）；青山终焉句三入零引；逸才句第二证达两度上限；页底注照登并声明非史料。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-nz-world' AS id, 'BACKGROUND' AS entity_type, 'nz-world' AS slug, '这个天下：两个世纪的相看' AS title, '四层处境背景（阶段 D 第 27 首·八句 2/2/2/2）；史实句均有逐字引证；background_line 八句形制：每层两行（1-2/3-4/5-6/7-8）；系年第二十一次判决「题有典地，典无史源」（题证系列第九状·首见断链在典不在年）→time.span/event.name/written_during 全缺席、零 relation；整首零 KNOWN 如实记录（audit 反向断言，V042 判例）；典实负证三层机器复查（通鉴 75 卷+全唐詩 120 卷袁宏谢尚计数全零/牛渚位置断言/两传区间零见）；青山终焉句三入零引；逸才句第二证达两度上限；页底注照登并声明非史料。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-nz-person' AS id, 'BACKGROUND' AS entity_type, 'nz-person' AS slug, '这个人：传里是描述，诗里是痛感' AS title, '四层处境背景（阶段 D 第 27 首·八句 2/2/2/2）；史实句均有逐字引证；background_line 八句形制：每层两行（1-2/3-4/5-6/7-8）；系年第二十一次判决「题有典地，典无史源」（题证系列第九状·首见断链在典不在年）→time.span/event.name/written_during 全缺席、零 relation；整首零 KNOWN 如实记录（audit 反向断言，V042 判例）；典实负证三层机器复查（通鉴 75 卷+全唐詩 120 卷袁宏谢尚计数全零/牛渚位置断言/两传区间零见）；青山终焉句三入零引；逸才句第二证达两度上限；页底注照登并声明非史料。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-nz-scene' AS id, 'bg-nz-scene' AS subject_id, 'context' AS property_key, '八句全诗本文（ws 页两处 {{另}} 页内自注原样照登——先登记后引用，tang300-variants.md 新行；Textquality 75% 如实记；异文「洞庭去」改终点读感的注记为本层读法声明）；「枢/底气/失落」诸说为本层读法，非史料断言。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-nz-city' AS id, 'bg-nz-city' AS subject_id, 'context' AS property_key, '典实机器扫描：袁宏/谢尚在通鉴 75 卷、全唐詩 120 卷快照计数全零（生成时断言，快照变动即中止）；牛渚旧传李白区间零见、新传区块一处且必落青山终焉句内（位置断言；该句三入既往迁移本迁移零引）；页底注为整理者典实地注——照登并声明非史料（V040 判例）；题有典地，典无史源→零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-nz-world' AS id, 'bg-nz-world' AS subject_id, 'context' AS property_key, '苏颋赏句新传单得（旧传无此事，合龙无望）→不升，LIKELY 照登；谢尚/袁宏—苏颋/李白并置为读法声明非史料断言；整首零 KNOWN 如实记录（audit 反向断言，V042 判例）；certainty 不覆盖任何系年，诗 time.span/event.name/written_during 零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-nz-person' AS id, 'bg-nz-person' AS subject_id, 'context' AS property_key, '逸才句旧传单得（不升），V032 第一证此处第二证达两度上限（locator 声明）；「超世之心」与「余亦能高咏」并置为读法声明；谪仙人/竹溪/脱靴/崔宗之/青山判例零重开（audit 关键语硬卡）；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-nz-scene' AS subject_id, 'context' AS property_key, 'claim-bg-nz-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-nz-city' AS subject_id, 'context' AS property_key, 'claim-bg-nz-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-nz-world' AS subject_id, 'context' AS property_key, 'claim-bg-nz-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-nz-person' AS subject_id, 'context' AS property_key, 'claim-bg-nz-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-nz-scene' AS id, 'work-t300-328' AS work_id, 'SCENE' AS layer, '这首诗把夜钉死：牛渚、西江、没有一片云的青天（「牛渚西江夜，青天無片雲」——怀古诗里罕见的干净夜空，什么都没遮）；登船望月，空忆一个人（「登舟望秋月，空憶謝將軍」——「空」字是这首诗的枢）；忆谁？忆的是那个**听见**的人：谢尚夜泊牛渚，听见邻船袁宏咏史，连夜邀谈、援引进仕——诗人的全部底气在第五句：「余亦能高詠」，全部失落也在第五句的另一半：「斯人不可聞」（我唱得不差，听的人死了千年）；天亮解缆，枫叶纷纷（「明朝挂帆席，楓葉落紛紛」——两处页内自注挂帆席/洞庭去、落/正照登不裁决；异文「洞庭去」一支把终点从未知改成具体地名，读感全变，正是照登的价值）。
地钉死、夜钉死、月钉死——年份照旧无。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-nz-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-nz-city' AS id, 'work-t300-328' AS work_id, 'CITY' AS layer, '「牛渚」在两传李白区间里：旧传**零见**，新传**只见一次**，而那一次又是另一件事——晚年「度牛渚磯至姑孰，悅謝家青山，欲終焉」（该句 V016/V032/V036 已三入既往迁移，**本迁移零引**，位置断言在生成时机器复查——负证靠位置不靠引用）。
而这首诗真正的「城」是典里的那座城：页底注「此地即謝尚聞袁宏詠史處」替读者指认现场——但它是整理者的典实地注（V040「時年十七」底注判例同族），照登、声明非史料。机器扫描（生成时断言）：袁宏、谢尚在通鉴 75 卷、全唐詩 120 卷快照内**计数全零**。题有典地，典无史源：系年链条「诗→地→典→年」断在「典」这一环——断的不是年份，是年份的上游。这座城在诗的档案里是完整的，在史的档案里连一块碑都没有。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-nz-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-nz-world' AS id, 'work-t300-328' AS work_id, 'WORLD' AS layer, '典不可核，天下层只能回到史料能给的东西：新传里名士对少年的一次相看——「蘇頲為益州長史，見白異之，曰：『是子天才英特，少益以學，可比相如。』」（单得，不升，LIKELY 照登）。
把它和这首诗并读——不是因果，是**形状**：谢尚之于袁宏、苏颋之于李白，同一个「听见/看见然后援引」的结构在两个世纪里各出现一次，前者在诗里（典）、后者在传里（史）。诗里那位听者已不可闻，传里这位听者曾真实地看过他一眼——**这个并置是本层的读法声明**，史实只有苏颋一句。两源合龙无望（苏颋赏仅新传收，旧传无此事），audit 判例零重开硬卡之外，本层另设**整首零 KNOWN 反向断言**（V042 判例）：不为凑数升格。' AS body_text, 'SENIOR' AS audience, 'claim-bg-nz-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-nz-person' AS id, 'work-t300-328' AS work_id, 'PERSON' AS layer, '旧传给这个人的一句定调短话：「少有逸才，志氣宏放，飄然有超世之心」（V032 PERSON 侧第一证，此处第二证——**同句两度为上限，到此为止**）。
把「飄然有超世之心」和「余亦能高詠，斯人不可聞」并排放：传里说他天生把自己放得比世界高，诗里他把这份高递出去等一个听不见的回音——同一种气质，传里是描述，诗里是痛感。
判例零重开（audit 关键语硬卡）：谪仙人（V036）、竹溪六逸（V041）、脱靴斥去（V041）、崔宗之采石锦袍（V032/V045）、青山终焉（三入）——本层一个新句、一个第二证，其余全部只字不引。' AS body_text, 'SENIOR' AS audience, 'claim-bg-nz-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-nz-scene' AS claim_id, 'source-ws-t300-328' AS source_id, '页面 夜泊牛渚懷古（header title+author+八句四联，六段以「……」相連——两处 {{另}} 自注原样照登（先登记后引用，tang300-variants.md 新行）；同一 (claim,source) 主键下一行容全文，V037/V039/V040/V041/V042/V043/V044/V045 判例；全文另见 V018 claim-t300-328-text 引文）' AS locator, '| title    = 夜泊牛渚懷古……| author   = 李白……牛渚西江夜，青天無片雲。……登舟望秋月，空憶謝將軍。……余亦能高詠，斯人不可聞。……明朝{{另|挂帆席|洞庭去}}，楓葉{{另|落|正}}紛紛。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-nz-city' AS claim_id, 'source-ws-t300-328' AS source_id, '页面 夜泊牛渚懷古（header title+页底注两字段——底注「此地即謝尚聞袁宏詠史處」为整理者典实地注，**非史料**（V040「時年十七」底注判例同族），照登并声明；典实扫描（通鉴 75 卷/全唐詩 120 卷袁宏谢尚计数全零）与牛渚位置断言为生成时机器断言，诗身不代拟进引文）' AS locator, '| title    = 夜泊牛渚懷古……↑ [[全唐詩/卷181#夜泊牛渚懷古|全唐詩·卷181]] 此地即謝尚聞袁宏詠史處' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-nz-world' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百零二·文藝中·李白传苏颋赏句（见而异之/天才英特/可比相如——新传单得，旧传无此事，不升；与诗典的并置是读法声明，史实只此一句）' AS locator, '蘇頲為益州長史，見白異之，曰：「是子天才英特，少益以學，可比相如。」' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-nz-person' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十下·文苑下·李白传逸才句（少有逸才/志气宏放/飘然有超世之心——V032 PERSON 侧第一证，此处第二证——同句两度为上限）' AS locator, '少有逸才，志氣宏放，飄然有超世之心' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（八句：每层两行） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-nz-scene' AS background_id, 'text-work-t300-328-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-nz-scene' AS background_id, 'text-work-t300-328-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-nz-city' AS background_id, 'text-work-t300-328-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-nz-city' AS background_id, 'text-work-t300-328-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-nz-world' AS background_id, 'text-work-t300-328-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-nz-world' AS background_id, 'text-work-t300-328-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-nz-person' AS background_id, 'text-work-t300-328-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-nz-person' AS background_id, 'text-work-t300-328-ws' AS version_id, 8 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 46, 'Li Bai Mooring at Night at Ox-Islet, Remembering the Past background layers (stage-D poem 27, 2/2/2/2): dating verdict twenty-one, ninth shape of the title-evidence series and the first whose broken link is upstream of the year -- the title stakes ground (Ox-Islet) and moment (night, autumn moon) firmly, then invokes an allusion (Xie Shang hearing Yuan Hong recite history right here), and that allusion is unattestable in the whole snapshot corpus: counts of the two names across all 75 Tongjian files and all 120 Quantangshi files and both biography spans are zero, asserted at generation time (machine re-check of the negative evidence); the page-bottom note identifying the site is an editorial gazetteer gloss -- quoted, declared not-a-source (V040 precedent), never promoted into attestation; the chain poem-ground-allusion-year breaks at allusion: not the year that fails, but the upstream of the year; zero KNOWN honestly recorded (the praise by Su Ting is single-source in XTS, the JTS phrase on untainted talent single-source in JTS -- neither agrees across sources, neither promoted; audit asserts the zero, V042 precedent); the Green Hills sentence (three prior migrations) gets zero citation here -- the negative evidence rides on position, not on quotation; the talent phrase reaches its ceiling of two verbatim citations (V032 first, this one second, locator-declared); the banished-immortal / bamboo-creek / boots / Cui-Zongzhi lines stay closed precedents (audit keyword zero-entry); zero new sources'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 46);
COMMIT;
