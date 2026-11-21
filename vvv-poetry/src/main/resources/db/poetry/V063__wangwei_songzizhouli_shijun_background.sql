-- V063：王維《送梓州李使君》(work-t300-064) 四层背景（阶段 D 第 44 首·梓州与文翁）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V014、V015、V016、V018、V035、V039、V040、V052、V054、V060、V061、V062 已执行
--       （work-t300-064 与其 text-work-t300-064-ws、source-ws-t300-064 是 V018 的行；
--       source-quantangshi-126 是 V035/V039/V052/V054/V060/V062 已立的卷126 源行（本迁移第七次复用，零新源）；
--       source-xintangshu-wenyi 是 V016 的行；source-zizhi-tongjian-events 是 V014/V015 已立的通鉴事件源；
--       判例在册句自表己有五短（V040）/召缙（V061）/议者不之罪（V062）只引不重开）。
--       本迁移零新 source（audit 断言无诗源表新建插入语句）。
--
-- 数据源（可复现）：emit_v063.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/送梓州李使君.txt（{{另}}×3 三形态×100% 自评+底注全锚+分类双行）、
--   舊唐書卷190下/新唐書卷202（两传全文梓州/使君/杜鵑/文翁全零负证+蜀州刺史句首引+己有五短零重开）、
--   全唐詩卷126（裸名锚+桩）/卷222/卷228（杜甫文翁在册）/杜鵑 23 处/樹杪 4 处闭域扫描、
--   通鑑卷197/198/212/222/264（梓州恰 31 闭域+梓州刺史恰二+撞字三词各恰一+五处年标题窗口）+
--   通鑑 75 卷/全唐詩 118 卷存快照负证计数扫描（文翁/李使君/杜鵑/橦布/芋田/漢女/巴人/訟芋/
--   參天/樹杪/百重/梓州/使君/百重泉/漢女輸）+
--   既有迁移引文域逐句查重——传区间归属、首引/二引/零重开前提全部生成时断言。
--
-- 做：4 BACKGROUND content/claim/background + 5 组逐字引用（(claim,source) 主键每对恰一行）+
--   8 background_line（八句五律 **2/2/2/2 第五次**（V054/V058/V060/V062）：scene→1-2 city→3-4
--   world→5-6 person→7-8，绑 text-work-t300-064-ws 的 8 行）+ 零 poetry_source 行 + 不碰 poetry_text_line。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「題有梓州，梓州在史部只貶所與叛鎮；詩有文翁，文翁在史部七十五卷全零」）：
--   * 梓州恰 31 闭域/梓州刺史恰二双窗口入引/李使君全零/使君恰 14 闭域（贬所叛镇/称呼非姓名）；
--   * 文翁/杜鵑/蜀风通鉴全零+撞字三词各恰一闭域窗口入引（地名形态首见，audit 双向硬卡）；
--   * 文翁典与「诗劝人，表求己」均标明读法声明非史实（页上无自注）；
--   * 三枚异文三形态（整语支/单字支/构件描述支）引文含标记原样照登不裁决；
--   * 同页两形并存四度再验（V018 归一形 vs 本迁移三标记原样形）；
--   * 裸名锚第二见+分类双行照登（V048 判例三重断言）；
--   * 此诗正文第二引上限用满：V018 一引在先（双针查重各恰一处），对后来迁移关闭；
--   * 杜甫文翁三句/杜鵑 23/樹杪 4 他卷在册零入引（audit 硬卡零混入）；
--   * KNOWN 零如实记录（第十九例，audit 反向断言 SQL 无 KNOWN 字面量）；
--   * 己有五短（V040）/召缙句（V061）/议者句（V062）判例只引不重开。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 62，不含 63
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-064-%';             -- 空
--   SELECT id FROM poetry_source WHERE id='source-quantangshi-126';     -- 恰 1（六迁移已立，本迁移复用不新建）
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-064-ws';  -- 恰 8
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-064-%';       -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-064';                                  -- 8（2/2/2/2）
--   SELECT certainty FROM poetry_claim WHERE id LIKE 'claim-bg-064-%';  -- 四行全 LIKELY（有意全 LIKELY）
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-064'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-064';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-064-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
--   SELECT COUNT(*) FROM poetry_source WHERE id='source-quantangshi-126';  -- 恰 1（复用，非本迁移所立）
-- 回滚: recovery/V063_rollback.sql（按 id 全枚举删除；零 source 删除——卷126 源行为六迁移所立）
START TRANSACTION;

-- ---------- 1. 零新 source（卷126 源行六迁移已立，本迁移第七次复用） ----------
-- ---------- 2. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-064-scene' AS id, 'BACKGROUND' AS entity_type, '064-scene' AS slug, '眼前：入蜀路上的视听盛景' AS title, '四层处境背景（阶段 D 第 44 首·八句五律 2/2/2/2 第五次）；史实句均有逐字引证；系年第三十八次判决（题证系列第廿六状·梓州与文翁）「題有梓州，梓州在史部只貶所與叛鎮；詩有文翁，文翁在史部七十五卷全零」——通鉴「梓州」恰 31 处十四卷闭域+「梓州刺史」恰二闭域双窗口入引（開元九年辛酉七二一貶晙為梓州刺史+上元二年辛丑七六一段子璋反——史部仅有的两个梓州刺史一贬一叛）；「李使君」全零+「使君」恰 14 处十一卷闭域（称呼非姓名）；文翁/杜鵑/橦布/芋田/漢女/巴人通鉴全零（诗的全部劝勉内容史部不载）；三字撞字各恰一处闭域窗口入引（參天可汗道貞觀二十一年丁未六四七+舉火炬於樹杪天復三年癸亥九〇三+圍其城數百重貞觀十九年乙巳六四五——诗写天景/史作军号兵形，同字两界第八形态·地名形态首见）；杜甫文翁三处+杜鵑 23+樹杪四在册零入引；100% 自评×{{另}}×3 横截面形态再复现（V054 首录侧补齐）+三枚异文三形态（整语支异文首见/单字支/支内含一作注+构件描述字首见）照登不裁决；同页两形并存四度再验；裸名锚第二见+卷126 恰二闭域+底注全锚+分类双行；零新源（卷126 源第六次立前已用六迁移、第七次复用）；此诗正文第二引上限用满第十一例对后来关闭（V018 在先+双针查重）；PERSON 首引新传「縉為蜀州刺史未還」（自表己有五短 V040 零重开；两传全文梓州/使君/杜鵑/文翁全零——传不载蜀）；KNOWN 零如实记录（第十九例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-064-city' AS id, 'BACKGROUND' AS entity_type, '064-city' AS slug, '这座城：100% 自评带三枚异文的页' AS title, '四层处境背景（阶段 D 第 44 首·八句五律 2/2/2/2 第五次）；史实句均有逐字引证；系年第三十八次判决（题证系列第廿六状·梓州与文翁）「題有梓州，梓州在史部只貶所與叛鎮；詩有文翁，文翁在史部七十五卷全零」——通鉴「梓州」恰 31 处十四卷闭域+「梓州刺史」恰二闭域双窗口入引（開元九年辛酉七二一貶晙為梓州刺史+上元二年辛丑七六一段子璋反——史部仅有的两个梓州刺史一贬一叛）；「李使君」全零+「使君」恰 14 处十一卷闭域（称呼非姓名）；文翁/杜鵑/橦布/芋田/漢女/巴人通鉴全零（诗的全部劝勉内容史部不载）；三字撞字各恰一处闭域窗口入引（參天可汗道貞觀二十一年丁未六四七+舉火炬於樹杪天復三年癸亥九〇三+圍其城數百重貞觀十九年乙巳六四五——诗写天景/史作军号兵形，同字两界第八形态·地名形态首见）；杜甫文翁三处+杜鵑 23+樹杪四在册零入引；100% 自评×{{另}}×3 横截面形态再复现（V054 首录侧补齐）+三枚异文三形态（整语支异文首见/单字支/支内含一作注+构件描述字首见）照登不裁决；同页两形并存四度再验；裸名锚第二见+卷126 恰二闭域+底注全锚+分类双行；零新源（卷126 源第六次立前已用六迁移、第七次复用）；此诗正文第二引上限用满第十一例对后来关闭（V018 在先+双针查重）；PERSON 首引新传「縉為蜀州刺史未還」（自表己有五短 V040 零重开；两传全文梓州/使君/杜鵑/文翁全零——传不载蜀）；KNOWN 零如实记录（第十九例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-064-world' AS id, 'BACKGROUND' AS entity_type, '064-world' AS slug, '这个天下：史部的梓州只贬所叛镇' AS title, '四层处境背景（阶段 D 第 44 首·八句五律 2/2/2/2 第五次）；史实句均有逐字引证；系年第三十八次判决（题证系列第廿六状·梓州与文翁）「題有梓州，梓州在史部只貶所與叛鎮；詩有文翁，文翁在史部七十五卷全零」——通鉴「梓州」恰 31 处十四卷闭域+「梓州刺史」恰二闭域双窗口入引（開元九年辛酉七二一貶晙為梓州刺史+上元二年辛丑七六一段子璋反——史部仅有的两个梓州刺史一贬一叛）；「李使君」全零+「使君」恰 14 处十一卷闭域（称呼非姓名）；文翁/杜鵑/橦布/芋田/漢女/巴人通鉴全零（诗的全部劝勉内容史部不载）；三字撞字各恰一处闭域窗口入引（參天可汗道貞觀二十一年丁未六四七+舉火炬於樹杪天復三年癸亥九〇三+圍其城數百重貞觀十九年乙巳六四五——诗写天景/史作军号兵形，同字两界第八形态·地名形态首见）；杜甫文翁三处+杜鵑 23+樹杪四在册零入引；100% 自评×{{另}}×3 横截面形态再复现（V054 首录侧补齐）+三枚异文三形态（整语支异文首见/单字支/支内含一作注+构件描述字首见）照登不裁决；同页两形并存四度再验；裸名锚第二见+卷126 恰二闭域+底注全锚+分类双行；零新源（卷126 源第六次立前已用六迁移、第七次复用）；此诗正文第二引上限用满第十一例对后来关闭（V018 在先+双针查重）；PERSON 首引新传「縉為蜀州刺史未還」（自表己有五短 V040 零重开；两传全文梓州/使君/杜鵑/文翁全零——传不载蜀）；KNOWN 零如实记录（第十九例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-064-person' AS id, 'BACKGROUND' AS entity_type, '064-person' AS slug, '这个人：送人入蜀时弟弟还在蜀中' AS title, '四层处境背景（阶段 D 第 44 首·八句五律 2/2/2/2 第五次）；史实句均有逐字引证；系年第三十八次判决（题证系列第廿六状·梓州与文翁）「題有梓州，梓州在史部只貶所與叛鎮；詩有文翁，文翁在史部七十五卷全零」——通鉴「梓州」恰 31 处十四卷闭域+「梓州刺史」恰二闭域双窗口入引（開元九年辛酉七二一貶晙為梓州刺史+上元二年辛丑七六一段子璋反——史部仅有的两个梓州刺史一贬一叛）；「李使君」全零+「使君」恰 14 处十一卷闭域（称呼非姓名）；文翁/杜鵑/橦布/芋田/漢女/巴人通鉴全零（诗的全部劝勉内容史部不载）；三字撞字各恰一处闭域窗口入引（參天可汗道貞觀二十一年丁未六四七+舉火炬於樹杪天復三年癸亥九〇三+圍其城數百重貞觀十九年乙巳六四五——诗写天景/史作军号兵形，同字两界第八形态·地名形态首见）；杜甫文翁三处+杜鵑 23+樹杪四在册零入引；100% 自评×{{另}}×3 横截面形态再复现（V054 首录侧补齐）+三枚异文三形态（整语支异文首见/单字支/支内含一作注+构件描述字首见）照登不裁决；同页两形并存四度再验；裸名锚第二见+卷126 恰二闭域+底注全锚+分类双行；零新源（卷126 源第六次立前已用六迁移、第七次复用）；此诗正文第二引上限用满第十一例对后来关闭（V018 在先+双针查重）；PERSON 首引新传「縉為蜀州刺史未還」（自表己有五短 V040 零重开；两传全文梓州/使君/杜鵑/文翁全零——传不载蜀）；KNOWN 零如实记录（第十九例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 3. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-064-scene' AS id, 'bg-064-scene' AS subject_id, 'context' AS property_key, '八句全诗本文（ws 页 {{另}}×3、其余标记全零、Textquality 100%——100%×多枚横截面再复现，V054 首录/V055-V062 75%侧对照）；三枚异文三形态逐枚照登不裁决：整语支异文首见（千山響/鄉音聽两支各三字）、单字支常式（夜/半）、支内含「一作」注+构件描述字首见（橦/一作[上宗下貝]——第二支以构件描述代字）；引文含三枚标记原样；同页两形并存四度再验：V018 正文引文系异文取首项的归一文本，本迁移 SCENE 引文含 {{另}} 标记原样，各从其录；文翁典系读法声明非史料断言（页上无自注）；全句第二引：正文 V018 text claim 一引在先（生成时全库查重双针「萬壑樹參天」「不敢倚先賢」各恰一处），两度上限至此用满、此诗正文对后来迁移关闭（audit 硬卡）。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-064-city' AS id, 'bg-064-city' AS subject_id, 'context' AS property_key, '100% 自评×{{另}}×3 横截面形态再复现（完备度与标记数正交双向在案）；裸名锚+桩（无同名诗则无消歧器——裸名式第二见，对照 V062 首录/V059 作者/V061 首句）；卷126「送梓州李使君」恰 2=锚 1+桩 1 机器断言闭域；底注全锚（同 V058–V062）；分类行双行（五言律詩+送別詩）照登+非史料声明+不升格（V048 判例）；source-quantangshi-126 系 V035/V039/V052/V054/V060/V062 已立、第七次复用零新源；题面送蜀刺史而无时→零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-064-world' AS id, 'bg-064-world' AS subject_id, 'context' AS property_key, '通鉴「梓州」恰 31 处十四卷闭域+「梓州刺史」恰二（貶晙為梓州刺史開元九年辛酉七二一+梓州刺史段子璋反上元二年辛丑七六一——贬所与叛镇，闭域+双窗口入引）+「李使君」全零+「使君」恰 14 处十一卷闭域（称呼非姓名）；「文翁」通鉴全零（诗的全部劝勉内容史部不载）+杜鵑/橦布/芋田/漢女/巴人全零（蜀风不进史部）；撞字三词各恰一闭域入引=貞觀二十一年（丁未，六四七）參天可汗道+天復三年（癸亥，九〇三）舉火炬於樹杪+貞觀十九年（乙巳，六四五）圍其城數百重（同字两界第八形态·地名形态首见——诗写天景/史作军号兵形，audit 硬卡）；全唐詩「文翁」恰三（杜甫送蜀官同语）/杜鵑恰 23/樹杪恰四在册零入引（机器断言）+橦布/芋田/百重泉全唐詩亦全零；certainty 不覆盖任何系年，诗 time.span/event.name/written_during 零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-064-person' AS id, 'bg-064-person' AS subject_id, 'context' AS property_key, '新传「縉為蜀州刺史未還」首引（生成时全库引文域查重：既往零命中，audit 硬卡）；其后自表句「己有五短」V040 已引在册零重开（audit 硬卡字样）；「诗劝人，表求己」为读法声明非史实；**两传全文梓州/使君/杜鵑/文翁全零**（机器断言——传不载蜀：送尽天下刺史的人传里没有一座梓州）；召缙句 V061/议者句 V062 在册零重开；已用判例句零重开；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-064-scene' AS subject_id, 'context' AS property_key, 'claim-bg-064-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-064-city' AS subject_id, 'context' AS property_key, 'claim-bg-064-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-064-world' AS subject_id, 'context' AS property_key, 'claim-bg-064-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-064-person' AS subject_id, 'context' AS property_key, 'claim-bg-064-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 4. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-064-scene' AS id, 'work-t300-064' AS work_id, 'SCENE' AS layer, '四联是一场入蜀路上的视听盛景：万壑的树顶着天，千山响应着杜鹃（「萬壑樹參天，{{另|千山響|鄉音聽}}杜鵑」——千山響一作鄉音聽，**整语支异文首见**：异文支不必是字，可以是三字整短语，照登不裁决）；山里下一夜的雨，树梢上百重泉同时下来（「山中一{{另|夜|半}}雨，樹杪百重泉」——夜一作半，单字支常式）；蜀地的女子交纳橦布，巴人为芋田打官司（「漢女輸{{另|橦|一作[上宗下貝]}}布，巴人訟芋田」——橦一作[上宗下貝]：**支内含「一作」注+构件描述字首见**，第二支排不出字形、以「宗头贝底」的构件描述代字入注，照登不裁决）；愿使君像汉代文翁那样翻新教化，不敢倚仗先贤余荫（「文翁翻教授，不敢倚先賢」——文翁典页上无自注，系引者按典读法声明；此诗正文系**第二引**：V018 text claim 已一引在先（其形系异文取首项的归一文本），全库查重双针恰一处，两度上限至此用满，此诗正文对后来迁移关闭）。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-064-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-064-city' AS id, 'work-t300-064' AS work_id, 'CITY' AS layer, '本页是**「100% 自评×异文多枚」横截面形态的再复现**：{{Textquality|100%}}而 {{另}}×3——完备度与标记数双向正交（V054「100% 带五枚标记」是首录，V055/V057/V061/V062 是 75%×异文侧；本篇补齐 100%×多枚侧）；三枚异文三种形态（整语支/单字支/构件描述支，见 SCENE 层逐枚照登）。篇题锚点是**裸名**「==[[送梓州李使君]]==」——无同名诗则无消歧器（同 V062 酬張少府：三种消歧形态中裸名式至此第二见）；卷126 锚+桩恰 2（闭域机器断言）；底注「↑[[全唐詩/卷126#送梓州李使君|全唐詩·卷126]]」锚点片段非空（同 V058–V062 全锚形态）；**分类行双行**（五言律詩+送別詩）系整理者动作（V048 判例：非史料声明、不升格）——「送別詩」柜里装着本篇，而「梓州」在史部只作贬所与叛镇（对照 WORLD 层）；source-quantangshi-126 系 V035/V039/V052/V054/V060/V062 已立、**第七次复用零新源**（本层零铸造零 relation）。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-064-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-064-world' AS id, 'work-t300-064' AS work_id, 'WORLD' AS layer, '**題有梓州，梓州在史部只貶所與叛鎮**：通鉴「梓州」恰 31 处十四卷（文件闭域断言），其中「梓州刺史」恰二（闭域+双窗口，逐字入引）：開元九年（辛酉，七二一）「**貶晙為梓州刺史**」——史部的梓州是贬官去处；上元二年（辛丑，七六一）「**梓州刺史段子璋反**」——史部的梓州是叛镇巢穴。**史部仅有的两个梓州刺史，一个是贬官，一个是反将**；本诗题里那位去翻新教化的李使君，通鉴「李使君」全零——「使君」恰 14 处十一卷（闭域断言）全是**称呼不是姓名**。**詩有文翁，文翁在史部七十五卷全零**：诗的劝勉全凭文翁（蜀守教化之典），史部一字不载；「杜鵑」「橦布」「芋田」「漢女」「巴人」也全零——蜀地风物整场不进史部。**三字撞字各恰一处**（闭域+窗口，入引为判决证据）：诗的「萬壑樹參天」——史部的「參天」恰一处=貞觀二十一年（丁未，六四七）回紇諸部長請開「**參天可汗道**」（參天是天至尊的称号，不是树）；诗的「樹杪百重泉」是最高最空之景——史部的「樹杪」恰一处=天復三年（癸亥，九〇三）秦皋「**舉火炬於樹杪**」举火诈敌救城（树梢是军用信号高处）、「**百重**」恰一处=貞觀十九年（乙巳，六四五）遼東城之役「圍其城數**百重**」（包围圈层数）——**诗把树梢水端写成天景，史把树梢围重用作军号与兵形**（同字两界第八形态·地名形态首见，五句史文入引，audit 硬卡）。诗集侧在册零入引（机器断言）：「文翁」全唐詩恰三处=杜甫「文翁儒化成」「直爲文翁再剖符」「直爲文翁」等——唐人送蜀官同用这个劝勉语，在册不牵合；「杜鵑」恰 23 处九卷、「樹杪」恰四处闭域在册；「橦布」「芋田」「百重泉」全唐詩亦全零（诗语无同源）。本层零铸造零 relation。' AS body_text, 'SENIOR' AS audience, 'claim-bg-064-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-064-person' AS id, 'work-t300-064' AS work_id, 'PERSON' AS layer, '诗中送的是**别人入蜀**——劝李使君去做文翁、翻新教授；传里记的是**弟弟正在蜀中**：本迁移首引新传「**縉為蜀州刺史未還，**」（生成时全库查重：既往零入引，audit 硬卡）——其后那道求换官放归田里的自表（「己有五短」诸句 V040 已引在册零重开，audit 硬卡）正是因这句前情而起。**送人入蜀劝以教化，求弟还京表以自贬：诗劝人，表求己**（读法声明，非史实）。
**两传「梓州」「使君」「杜鵑」「文翁」全零**（机器断言——送尽天下刺史的人，传里没有一座梓州；诗题的字也不进传）；已用判例句（己有五短 V040/召縉句 V061/議者不之罪 V062/願歸所任官 V040/輞川系列 V035 起）一个不重开；certainty 不覆盖任何系年。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-064-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 5. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-064-scene' AS claim_id, 'source-ws-t300-064' AS source_id, '页面 送梓州李使君（header author+四联八句，五段以「……」相連——全句**第二引**：正文 V018 text claim 一引在先（其形系异文取首项的归一文本，本引文含三枚 {{另}} 标记原样——同页两形并存各从其录），生成时全库查重双针恰一处，**两度上限至此用满，此诗正文对后来迁移关闭**；{{别}}/{{*}}/<ref> 全零、100%；三枚异文三形态照登不裁决（整语支/单字支/构件描述支）；文翁典页上无自注，系引者读法声明）' AS locator, '| author   = 王維……{{另|千山響|鄉音聽}}杜鵑。……山中一{{另|夜|半}}雨，樹杪百重泉。……漢女輸{{另|橦|一作[上宗下貝]}}布，巴人訟芋田。……文翁翻教授，不敢倚先賢。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-064-city' AS claim_id, 'source-ws-t300-064' AS source_id, '页面 送梓州李使君（header title+页底注+分类双行四段并收——100% 自评×{{另}}×3横截面形态再复现（V054 首录对照）；底注全锚「卷126#送梓州李使君」（同 V058–V062）；分类行双行（五言律詩+送別詩）系整理者动作：非史料声明、不升格）' AS locator, '| title    = 送梓州李使君……| notes    = {{Textquality|100%}} ↑ [[全唐詩/卷126#送梓州李使君|全唐詩·卷126]]……[[Category:五言律詩]]……[[Category:送別詩]]' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-064-city' AS claim_id, 'source-quantangshi-126' AS source_id, '卷一百二十六·王維《送梓州李使君》篇题锚点+转引桩（**裸名锚**——无同名诗则无消歧器（裸名式第二见，对照 V062）；卷126「送梓州李使君」恰 2=锚 1+桩 1机器断言；源行系 V035/V039/V052/V054/V060/V062 已立、本迁移第七次复用零新源）' AS locator, '==[[送梓州李使君]]==……{{:送梓州李使君}}' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-064-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '卷二百一十二·開元九年（辛酉，七二一）貶晙為梓州刺史段……卷二百二十二·上元二年（辛丑，七六一）梓州刺史段子璋反段……卷一百九十八·貞觀二十一年（丁未，六四七）參天可汗道段……卷二百六十四·天復三年（癸亥，九〇三）舉火炬於樹杪段……卷一百九十七·貞觀十九年（乙巳，六四五）圍其城數百重段（**通鉴「梓州」恰 31 处十四卷闭域、梓州刺史恰二、李使君全零、使君恰 14 处、參天/樹杪/百重各恰一处**：文件闭域+五处年标题窗口机器断言——史部两个梓州刺史一贬一叛、树梢围重皆军用；五句史文逐字入引为判决证据；文翁/杜鵑/蜀风通鉴全零，杜甫文翁诸句全唐詩在册零入引）' AS locator, '貶晙為梓州刺史……梓州刺史段子璋反……謂之參天可汗道……舉火炬於樹杪……圍其城數百重' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-064-person' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百二·文艺中·王維传缙为蜀州刺史未还句（生成时全库引文域查重：既往零入引，本迁移首引；其后自表「己有五短」诸句 V040 已引零重开；「诗劝人，表求己」是读法声明；两传全文梓州/使君/杜鵑/文翁全零——传不载蜀，机器断言）' AS locator, '縉為蜀州刺史未還' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 6. background_line（八句五律 2/2/2/2 第五次） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-064-scene' AS background_id, 'text-work-t300-064-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-064-scene' AS background_id, 'text-work-t300-064-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-064-city' AS background_id, 'text-work-t300-064-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-064-city' AS background_id, 'text-work-t300-064-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-064-world' AS background_id, 'text-work-t300-064-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-064-world' AS background_id, 'text-work-t300-064-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-064-person' AS background_id, 'text-work-t300-064-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-064-person' AS background_id, 'text-work-t300-064-ws' AS version_id, 8 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 7. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 63, 'Wang Wei''s Farewell to Senator Li of Zizhou (work-t300-064) background layers (stage-D poem 44, five-character regulated octet 2/2/2/2 fifth time): dating verdict thirty-eight, twenty-sixth shape of the title-evidence series -- the place-name and the old governor in two realms: Zizhou appears exactly 31 times across 14 Tongjian volumes (file-closed) and Zizhou Cishi exactly twice (closed, windowed, quoted): in 721 Wang Jun was demoted to be Zizhou Cishi, and in 761 Duan Zi-zhang the Zizhou Cishi revolted -- the only two Zizhou governors in the histories are one demoted minister and one rebel general, while Senator Li of the poem''s title scores zero (shijun "senator" appears 14 times over 11 volumes: a form of address, never a name); and Wen Weng -- the poem''s entire exhortation, the Han governor famed for civilizing Shu -- scores zero across all seventy-five Tongjian volumes, as do cuckoo, tong-cloth, taro fields, Han women and Ba people: all the scenery and all the urging never enter the histories; three colliding words exactly once each (closed, windowed, quoted): in 647 the Uyghur chieftains asked to open the "Sky-Canan Khagan Road" (cantian = the heavenly sovereign''s title, not a tree), in 903 Qin Gao "raised fire-torops at the treetops" to fake a rescue (the treetop as military beacon), and in 645 the siege lines at Liaodong "encircled the city in several hundred folds" -- the poem lifts treetops and spring-mists into a sky-scene, the histories use treetops and hundred-folds for beacons and siege-works: the eighth same-character split, first place-name shape (five history sentences quoted as verdict evidence, audit hard-assert); on the poetry side logged never quoted: Wen Weng exactly three times in the Quan Tangshi (Du Fu, farewell-to-a-Shu-official language), cuckoo 23 times over nine volumes, treetop four times (file-closed), while tong-cloth, taro field and "hundred-fold springs" score zero in the poetry corpus too; the page is 100%-self-rated yet carries three 另 markers -- the completeness/markers orthogonality cross-section re-verified (first recorded 100%-side is V054) -- and its three variant pairs show three species: a whole-phrase branch variant (three characters against three), the plain single-character species, and a branch carrying an inner "one reads" gloss with a component-description stand-in for an unencodable graph (first recorded); bare-name anchor (second sighting, as V062), juan 126 anchor+stub exactly two (file-closed), base note full non-empty, double category lines logged with non-source disclaimers; zero new sources (juan 126''s row reused for the seventh time); the poem body hits its two-use ceiling (V018 first, twin normalized needles, closure declared); PERSON first-cites the New History''s "Jin was Shu-prefecture governor and had not returned" (the self-demotion memorial sentence stays closed to V040) -- the poem urges another man to go civilize Shu while the biography shows the poet memorializing to bring his own brother back from it: the poem exhorts others, the memorial pleads for family (reading stance, not history); both biographies contain not one occurrence of Zizhou, shijun, cuckoo or Wen Weng (machine-asserted); KNOWN zero honestly recorded (nineteenth instance, audit reverse-asserts); closed precedent keywords stay out of citations'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 63);
COMMIT;
