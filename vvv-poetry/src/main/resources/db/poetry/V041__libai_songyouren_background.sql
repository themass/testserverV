-- V041：李白《送友人》(work-t300-323) 四层背景（阶段 D 第 22 首·八句 2/2/2/2）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V015、V016、V018 已执行（work-t300-323 与其 text-work-t300-323-ws、
--       source-ws-t300-323 是 V018 的行；source-jiutangshu-wenyuan / source-xintangshu-wenyi
--       是 V016 的行——均不另开）。本迁移零新 source（断言）。
--
-- 数据源（可复现）：emit_v041.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/送友人__李白_.txt（页面零异文标记——生成时反向断言）、
--   舊唐書卷190下（李白传浪迹句+竹溪六逸段+斥去段——后两段 V032 部分已立，
--   异侧再证声明入 locator）、新唐書卷202（竹溪段+酒八仙人段+还山段+身后两段；
--   切片传区间归属生成时断言）。
--
-- 做：0 个新 source（断言）+ 4 BACKGROUND content/claim/background +
--   6 组逐字引用（(claim,source) 主键每对恰一行）+
--   8 行 background_line（八句形制：scene→1-2 city→3-4 world→5-6 person→7-8，
--   绑 text-work-t300-323-ws 的 8 行）。本迁移不碰 poetry_text_line。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「题有角色无人，诗有意象无地」）：
--   * 受赠人=类别名「友人」零实名（连 V037 的首句消歧都没有）；饯地=通用对零锚点；
--   * 两传行迹满纸而零系此别（负证以「乃浪迹江湖」句为界正面立出）；
--   * KNOWN 一处：竹溪六逸之集两源合龙（徂徠山+集名+四名同列）；不外溢；
--   * 分歧两处并列不裁决：第六人韩沔/韩准（各归其侧）、去翰林斥去/还山（各归其侧）
--     ——audit 互斥断言双侧保证；
--   * 酒八仙人/范传正祭塚/文宗三绝均新传单得不升；
--   * 死状两条线 V036 已并列——本迁移零重开（醉死/葬東麓零入引文，audit 硬卡）；
--   * 跨迁移同句再证两处（JTS_ZX/JTS_CQ，V038 合规先例），locator 声明。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 40，不含 41
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-fr-%';              -- 空
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-323-ws';  -- 恰 8（五律）
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-fr-%';        -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-323';                                  -- 8（每层两行）
--   SELECT certainty FROM poetry_claim WHERE id = 'claim-bg-fr-world';  -- KNOWN（六逸两源合龙）
--   SELECT certainty FROM poetry_claim WHERE id IN ('claim-bg-fr-scene','claim-bg-fr-city','claim-bg-fr-person');
--     -- LIKELY / LIKELY / LIKELY（person 层两分歧并列整体 LIKELY）
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-323'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-323';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-fr-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
-- 回滚: recovery/V041_rollback.sql（按 id 全枚举删除；不动 V018/V032/V036 的行，不动共用来源行）
START TRANSACTION;

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-fr-scene' AS id, 'BACKGROUND' AS entity_type, 'fr-scene' AS slug, '眼前：一场没有名物的送别' AS title, '四层处境背景（阶段 D 第 22 首·八句 2/2/2/2）；史实句均有逐字引证；background_line 八句形制：每层两行（1-2/3-4/5-6/7-8）；系年第十六次判决「题有角色无人，诗有意象无地」（题证系列第四状）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 一处（竹溪六逸两源合龙）；两处分歧并列不裁决（韩沔/韩准、斥去/还山，audit 互斥）；死状 V036 判例零重开；ws 页零标记反向断言。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-fr-city' AS id, 'BACKGROUND' AS entity_type, 'fr-city' AS slug, '这座城：通用对不锚地' AS title, '四层处境背景（阶段 D 第 22 首·八句 2/2/2/2）；史实句均有逐字引证；background_line 八句形制：每层两行（1-2/3-4/5-6/7-8）；系年第十六次判决「题有角色无人，诗有意象无地」（题证系列第四状）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 一处（竹溪六逸两源合龙）；两处分歧并列不裁决（韩沔/韩准、斥去/还山，audit 互斥）；死状 V036 判例零重开；ws 页零标记反向断言。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-fr-world' AS id, 'BACKGROUND' AS entity_type, 'fr-world' AS slug, '这个天下：竹溪的六人编制' AS title, '四层处境背景（阶段 D 第 22 首·八句 2/2/2/2）；史实句均有逐字引证；background_line 八句形制：每层两行（1-2/3-4/5-6/7-8）；系年第十六次判决「题有角色无人，诗有意象无地」（题证系列第四状）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 一处（竹溪六逸两源合龙）；两处分歧并列不裁决（韩沔/韩准、斥去/还山，audit 互斥）；死状 V036 判例零重开；ws 页零标记反向断言。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-fr-person' AS id, 'BACKGROUND' AS entity_type, 'fr-person' AS slug, '这个人：被赶的还是自己走的' AS title, '四层处境背景（阶段 D 第 22 首·八句 2/2/2/2）；史实句均有逐字引证；background_line 八句形制：每层两行（1-2/3-4/5-6/7-8）；系年第十六次判决「题有角色无人，诗有意象无地」（题证系列第四状）→time.span/event.name/written_during 全缺席、零 relation；KNOWN 一处（竹溪六逸两源合龙）；两处分歧并列不裁决（韩沔/韩准、斥去/还山，audit 互斥）；死状 V036 判例零重开；ws 页零标记反向断言。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-fr-scene' AS id, 'bg-fr-scene' AS subject_id, 'context' AS property_key, '八句全诗本文（ws 页零页内标记——另/别/自注三类皆无，audit 反向断言无标记即不造标记；V018 已立异体字折叠路径）；无名词锚点为本层读法声明；班马=离群之马系题解通义非史料断言。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-fr-city' AS id, 'bg-fr-city' AS subject_id, 'context' AS property_key, '饯地不可考：「北郭/東城」通用对不锚地（CITY 引文零诗语，audit 断言）；旧传放还后行迹总括「乃浪迹江湖，終日沉飲」——行迹一团零系此别（负证正面文本）；历代注家所指不在引证范围；题有角色无人、诗有意象无地→零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-fr-world' AS id, 'bg-fr-world' AS subject_id, 'context' AS property_key, '竹溪六逸之集两源独立一致（徂徠山+集名+四名同列）→升 KNOWN；第六人名单旧「韓沔」/新「韓准」一名之异并列不裁决（V036 先例，audit 互斥断言各归其侧）；六逸与「友人」之关联系读法不外溢；诗 time.span/event.name/written_during 零铸造、零 relation。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-fr-person' AS id, 'bg-fr-person' AS subject_id, 'context' AS property_key, '去翰林因果两传分歧并列不裁决（旧「由是斥去」/新「懇求還山，帝賜金放還」，audit 互斥断言）；酒八仙人/范传正祭塚/文宗三绝均新传单得不升；死状两条线 V036 已立——本迁移零重开（audit 硬卡醉死/葬東麓零入引文）；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-fr-scene' AS subject_id, 'context' AS property_key, 'claim-bg-fr-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-fr-city' AS subject_id, 'context' AS property_key, 'claim-bg-fr-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-fr-world' AS subject_id, 'context' AS property_key, 'claim-bg-fr-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-fr-person' AS subject_id, 'context' AS property_key, 'claim-bg-fr-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-fr-scene' AS id, 'work-t300-323' AS work_id, 'SCENE' AS layer, '八句全诗是一场**没有名物的送别**：山横着，水绕着（「青山橫北郭，白水繞東城」——青/白、北郭/東城，工整到没有一座具体的城）；就在这里分手，他像断根的蓬草走一万里（「此地一為別，孤蓬萬里征」）；云是游子的心思，落日老朋友的脸色（「浮雲遊子意，落日故人情」）；挥手，各走，连马都不忍分别地萧萧叫着（「揮手自茲去，蕭蕭班馬鳴」——班马=离群之马，诗把最后的感情外包给牲口）。
全诗可考之物为零：不写友人名、不写所去之地、不写何年何节——每个名词都是类别。这首的「为什么」全押在送别这个动作本身。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-fr-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-fr-city' AS id, 'work-t300-323' AS work_id, 'CITY' AS layer, '饯地在哪，史料不说，诗也不给：「北郭」「東城」是律诗通用对——**通用对不锚地**（audit 断言 CITY 引文不含诗语）。旧传写尽李白行迹：徂徠山、會稽、翰林、金陵采石、夜郎、宣城——唯独放还之后的总括只有一句「乃浪迹江湖，終日沉飲」：行迹是一团，没有一条拴住这场送别。
于是这座「城」只能这样立：它存在（诗有城），不可考（两传零记载）。历代注家指安陆、指宣城、指桐江——都不在本库引证范围内。题有角色无人，诗有意象无地。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-fr-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-fr-world' AS id, 'work-t300-323' AS work_id, 'WORLD' AS layer, '但李白年轻时有编制：旧传「少與魯中諸生孔巢父、韓沔、裴政、張叔明、陶沔等隠於徂徠山，酣歌縱酒，時號『竹溪六逸』」，新传「更客任城，與孔巢父、韓准、裴政、張叔明、陶沔居徂徠山，日沈飲，號『竹溪六逸』」——集名、徂徠山、四名同列，两源独立一致：**竹溪六逸之集升 KNOWN**。
一处名单分歧照登不裁决：旧传作**韓沔**，新传作**韓准**——同一位置的第六人两传名字不同，各归其侧（V036 卒地分歧同款纪律，audit 互斥断言保证不串写）。开元前后的士人年轻时代就是这样的：隐居是合伙制，酒是社务；《送友人》写给的那个「友人」，最像六逸这样来来去去的人——但这是读法，史料不认领。' AS body_text, 'SENIOR' AS audience, 'claim-bg-fr-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-fr-person' AS id, 'work-t300-323' AS work_id, 'PERSON' AS layer, '离开朝廷这一页，两传各写了一个版本，本库并列不裁决：旧传一句「嘗沉醉殿上，引足令高力士脫靴，**由是斥去**」——得罪史笔；新传一句「**懇求還山，帝賜金放還**」——体面史笔。同一个人离同一种生活，一说是被赶的，一说是自己走的；两说都进了正史，各归其侧（audit 互斥）。
新传还留了两段身后的故事：元和末宣歙观察使范传正去祭他的坟、下令禁樵采；文宗时朝廷下诏，把李白的歌诗与裴旻剑舞、张旭草书并号「**三絕**」——新传单源，不升 KNOWN。全诗最大的反讽在此：他生前写给无名友人的这首送别，身后他本人成了被整个朝廷送进经典的人。死状两条线（醉死宣城/葬東麓）V036 已并列——本迁移零重开。' AS body_text, 'SENIOR' AS audience, 'claim-bg-fr-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-fr-scene' AS claim_id, 'source-ws-t300-323' AS source_id, '页面 送友人 (李白)（header title+author+八句全文，十段以「……」相連——页面零异文标记（Textquality 100%），无标记即不造标记；同一 (claim,source) 主键下一行容全文，V037/V039/V040 判例；全文另见 V018 claim-t300-323-text 引文）' AS locator, '| title    = 送友人……| author   = 李白……青山橫北郭，……青山橫北郭，白水繞東城。……此地一為別，……此地一為別，孤蓬萬里征。……浮雲遊子意，……浮雲遊子意，落日故人情。……揮手自茲去，……揮手自茲去，蕭蕭班馬鳴。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-fr-city' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十下·文苑下·李白传放还后行迹句（「乃浪迹江湖，終日沉飲」——行迹总括无锚点，零系此别之负证以本句为界成立；V032 未引此半句，零重叠）' AS locator, '乃浪迹江湖，終日沉飲。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-fr-world' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十下·文苑下·李白传竹溪六逸段（时号竹溪六逸/韩沔名单——两源合龙旧传侧；V032 已立此句（徂徠线），此处集名侧再证——跨迁移同句再证，claim 不同故主键不冲突）' AS locator, '少與魯中諸生孔巢父、韓沔、裴政、張叔明、陶沔等隠於徂徠山，酣歌縱酒，時號「竹溪六逸」。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-fr-world' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百零二·文藝中·李白传竹溪六逸段（号竹溪六逸/韩准名单——两源合龙新传侧；第六人名与旧传一异，并列不裁决各归其侧）' AS locator, '更客任城，與孔巢父、韓准、裴政、張叔明、陶沔居徂徠山，日沈飲，號「竹溪六逸」。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-fr-person' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十下·文苑下·李白传斥去段（由是斥去——得罪侧因果；V032 已立此句前半（脱靴），此处斥去侧再证——跨迁移同句再证声明）' AS locator, '嘗沉醉殿上，引足令高力士脫靴，由是斥去。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-fr-person' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百零二·文藝中·李白传（酒八仙人段+恳求还山段+范传正祭塚段+文宗三绝段，四段以「……」相連，同卷同传——还山体面侧/三编制/身后经典化两幕均单得；死状句不在此四段内，V036 已立零重开）' AS locator, '與知章、李適之、汝陽王璡、崔宗之、蘇晉、張旭、焦遂為「酒八仙人」。……懇求還山，帝賜金放還。……元和末，宣歙觀察使范傳正祭其塚，禁樵採。……文宗時，詔以白歌詩、裴旻劍舞、張旭草書為「三絕」。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（八句：每层两行） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-fr-scene' AS background_id, 'text-work-t300-323-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-fr-scene' AS background_id, 'text-work-t300-323-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-fr-city' AS background_id, 'text-work-t300-323-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-fr-city' AS background_id, 'text-work-t300-323-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-fr-world' AS background_id, 'text-work-t300-323-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-fr-world' AS background_id, 'text-work-t300-323-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-fr-person' AS background_id, 'text-work-t300-323-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-fr-person' AS background_id, 'text-work-t300-323-ws' AS version_id, 8 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 41, 'Li Bai Seeing Off a Friend background layers (stage-D poem 22, 2/2/2/2): dating verdict sixteen, fourth shape of the title-evidence series -- the title names only a role (a friend, no name; not even V037-s first-line disambiguation exists) while the poem offers only generic couplets: green hills north wall, white water east gate is a regulated-verse universal pair, and a universal pair anchors no city (audit asserts zero poem-words in CITY evidence); the biographies fill every other itinerary line (Cu-lai mountain, Kuai-ji, Han-lin, Jin-ling, Ye-lang, Xuancheng) yet tie zero of them to this farewell -- the negative proof stands on the JTS summary line nai lang-ji jiang-hu (after release his tracks were one blur); one KNOWN: the Bamboo Creek Six Recluses circle, JTS yin Cu-lai shan ... shi hao Zhu-xi liu-yi plus XTS ... ju Cu-lai shan ... hao Zhu-xi liu-yi -- circle name, mountain and four members agree across two sources; the sixth member diverges (JTS Han Mian vs XTS Han Zhun) and is filed side by side, un-ruled, V036 death-place precedent, mutual-exclusion asserted in audit; second un-ruled divergence in PERSON: leaving the Han-lin academy -- JTS says driven out (you-shi chi-qu) while XTS says he begged to return to the mountains and was granted gold (ken-qiu huan-shan), each kept on its own side; Eight Immortals of Wine, Fan Chuan-zheng-s grave rites and Wenzong-s Three Perfections edict are all XTS-single, not raised; death accounts stay closed under V036 (zero re-entry asserted); two lawful cross-migration re-citations (JTS Zu-lai and boot lines from V032, different claims)'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 41);
COMMIT;
