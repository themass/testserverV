-- V058：李白《聽蜀僧濬彈琴》(work-t300-330) 四层背景（阶段 D 第 39 首·琴与流水）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V014、V015、V016、V018、V032、V051、V057 已执行（work-t300-330 与其
--       text-work-t300-330-ws、source-ws-t300-330 是 V018 的行；source-xintangshu-wenyi 是 V016 的行；
--       source-zizhi-tongjian-events 是 V014/V015 已立的通鉴事件源）。
--       **本迁移新立 1 个 source**：source-quantangshi-183（V051 卷159 之后再立全唐詩新卷源；
--       audit 断言诗源表新建插入语句恰一处且 id 必为该源，rollback 删该行）。
--
-- 数据源（可复现）：emit_v058.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/聽蜀僧濬彈琴.txt（四标记全零×75% 正交三度再验+底注非空锚片段）、
--   舊唐書卷190下（李白段负证+全卷无郭子儀断言）、新唐書卷202（并州救郭两句首引+李白段负证）、
--   通鑑卷194/217/219（琴恰二+流水恰一+三处年标题窗口）+ 通鑑 75 卷/全唐詩 118 卷存快照
--   负证计数扫描（琴/流水/蜀僧/綠綺/峨眉/萬壑/霜鐘/碧山/秋雲/一揮手）+
--   既有迁移引文域逐句查重——传区间归属、首引/第二引/零重开/新源前提全部生成时断言。
--
-- 做：4 BACKGROUND content/claim/background + 5 组逐字引用（(claim,source) 主键每对恰一行）+
--   8 行 background_line（八句形制：scene→1-2 city→3-4 world→5-6 person→7-8，
--   绑 text-work-t300-330-ws 的 8 行）+ 1 行 poetry_source（卷183）。本迁移不碰 poetry_text_line。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「題有琴名，琴在史部一藝具一權媒；詩用流水，流水在史部只車馬之喻」）：
--   * 琴通鉴恰二（翰林待诏/董庭蘭权贿）+流水恰一（車如流水）——同字两界，三段史文入引作判决证据，诗集侧他人琴句零入引（audit 硬卡）；
--   * 此诗正文第二引上限用满：V018 一引在先（全库查重恰一处），对后来迁移关闭；
--   * 新立源恰一（source-quantangshi-183，audit 数量+id 双断言；rights_note PENDING 同款模板）；
--   * 绿绮/流水之典与一救一赎并置均为读法声明，audit 双声明在 BG 文本内；
--   * 传「初」字列传回叙不锚年份（V057 追书边界延伸声明）；
--   * KNOWN 零如实记录（第十四例，audit 反向断言 SQL 无 KNOWN 字面量）；
--   * 山東人/謫仙人/脫靴/宮錦袍/夜郎/青山/解官以贖（V032 一引在册）/辭以孤窮失身 判例只引不重开。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 57，不含 58
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-330-%';             -- 空
--   SELECT id FROM poetry_source WHERE id='source-quantangshi-183';     -- 空（本迁移新立）
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-330-ws';  -- 恰 8
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-330-%';       -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-330';                                  -- 8（2/2/2/2）
--   SELECT certainty FROM poetry_claim WHERE id LIKE 'claim-bg-330-%';  -- 四行全 LIKELY（有意全 LIKELY）
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-330'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-330';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-330-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
--   SELECT COUNT(*) FROM poetry_source WHERE id='source-quantangshi-183';  -- 恰 1（本迁移新立）
-- 回滚: recovery/V058_rollback.sql（按 id 全枚举删除，含新立 source 行；不动他迁移来源行与 V018 的行）
START TRANSACTION;

-- ---------- 1. 唯一新 source（卷183——audit 断言恰一处） ----------
INSERT INTO poetry_source (id, title, author, edition, url, rights_note, verification_status, source_kind, reliability)
SELECT * FROM (
SELECT 'source-quantangshi-183' AS id, '《全唐詩》卷一百八十三（王维…李白卷次区间之李白集所在卷·维基文库录入本）' AS title, NULL AS author, '维基文库《全唐詩》卷一百八十三（录入本）' AS edition, 'https://zh.wikisource.org/wiki/全唐詩/卷183' AS url, '《全唐詩》维基文库录入本，公有领域古籍。本行由内容流水线逐字定位核验；录入本本身可能需据扬州局刻本/中华书局点校本校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status, 'POETRY_COLLECTION' AS source_kind, 'HIGH' AS reliability FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_source x WHERE x.id = t.id);

-- ---------- 2. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-330-scene' AS id, 'BACKGROUND' AS entity_type, '330-scene' AS slug, '眼前：曲终才发觉天黑' AS title, '四层处境背景（阶段 D 第 39 首·八句五律 2/2/2/2）；史实句均有逐字引证；系年第三十三次判决（题证系列第廿一状·琴与流水）「題有琴名，琴在史部一藝具一權媒；詩用流水，流水在史部只車馬之喻」——通鉴「琴」恰二=tj-217 天宝十三载翰林琴棋待诏+tj-219 至德二年房琯门客董庭蘭鼓琴大招權利+tj-194 貞觀十年車如流水馬如龍三段史文逐字入引作判决证据（闭域+三窗口断言；诗集侧他人琴句零入引）；通鉴「流水」恰一=贞观十年（丙申，六三六）車如流水馬如龍（撞字第三例，闭域+窗口+前后字断言）；诗语八词通鉴全零；新立 source-quantangshi-183（V051 之后再立全唐詩卷源，audit 恰一）；底注锚点片段非空（对照 V056 空锚）；零标记×75% 正交三度再验；此诗正文第二引上限用满对后来关闭（V018 在先+全库查重）；新传并州救郭子仪两句首引（新传单得；解官以贖 V032 零重开）；KNOWN 零如实记录（第十四例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-330-city' AS id, 'BACKGROUND' AS entity_type, '330-city' AS slug, '这座城：整理者建的琴诗档案柜' AS title, '四层处境背景（阶段 D 第 39 首·八句五律 2/2/2/2）；史实句均有逐字引证；系年第三十三次判决（题证系列第廿一状·琴与流水）「題有琴名，琴在史部一藝具一權媒；詩用流水，流水在史部只車馬之喻」——通鉴「琴」恰二=tj-217 天宝十三载翰林琴棋待诏+tj-219 至德二年房琯门客董庭蘭鼓琴大招權利+tj-194 貞觀十年車如流水馬如龍三段史文逐字入引作判决证据（闭域+三窗口断言；诗集侧他人琴句零入引）；通鉴「流水」恰一=贞观十年（丙申，六三六）車如流水馬如龍（撞字第三例，闭域+窗口+前后字断言）；诗语八词通鉴全零；新立 source-quantangshi-183（V051 之后再立全唐詩卷源，audit 恰一）；底注锚点片段非空（对照 V056 空锚）；零标记×75% 正交三度再验；此诗正文第二引上限用满对后来关闭（V018 在先+全库查重）；新传并州救郭子仪两句首引（新传单得；解官以贖 V032 零重开）；KNOWN 零如实记录（第十四例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-330-world' AS id, 'BACKGROUND' AS entity_type, '330-world' AS slug, '这个天下：史部的琴一为艺具一为权媒' AS title, '四层处境背景（阶段 D 第 39 首·八句五律 2/2/2/2）；史实句均有逐字引证；系年第三十三次判决（题证系列第廿一状·琴与流水）「題有琴名，琴在史部一藝具一權媒；詩用流水，流水在史部只車馬之喻」——通鉴「琴」恰二=tj-217 天宝十三载翰林琴棋待诏+tj-219 至德二年房琯门客董庭蘭鼓琴大招權利+tj-194 貞觀十年車如流水馬如龍三段史文逐字入引作判决证据（闭域+三窗口断言；诗集侧他人琴句零入引）；通鉴「流水」恰一=贞观十年（丙申，六三六）車如流水馬如龍（撞字第三例，闭域+窗口+前后字断言）；诗语八词通鉴全零；新立 source-quantangshi-183（V051 之后再立全唐詩卷源，audit 恰一）；底注锚点片段非空（对照 V056 空锚）；零标记×75% 正交三度再验；此诗正文第二引上限用满对后来关闭（V018 在先+全库查重）；新传并州救郭子仪两句首引（新传单得；解官以贖 V032 零重开）；KNOWN 零如实记录（第十四例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-330-person' AS id, 'BACKGROUND' AS entity_type, '330-person' AS slug, '这个人：救人者后来系于被救者之手' AS title, '四层处境背景（阶段 D 第 39 首·八句五律 2/2/2/2）；史实句均有逐字引证；系年第三十三次判决（题证系列第廿一状·琴与流水）「題有琴名，琴在史部一藝具一權媒；詩用流水，流水在史部只車馬之喻」——通鉴「琴」恰二=tj-217 天宝十三载翰林琴棋待诏+tj-219 至德二年房琯门客董庭蘭鼓琴大招權利+tj-194 貞觀十年車如流水馬如龍三段史文逐字入引作判决证据（闭域+三窗口断言；诗集侧他人琴句零入引）；通鉴「流水」恰一=贞观十年（丙申，六三六）車如流水馬如龍（撞字第三例，闭域+窗口+前后字断言）；诗语八词通鉴全零；新立 source-quantangshi-183（V051 之后再立全唐詩卷源，audit 恰一）；底注锚点片段非空（对照 V056 空锚）；零标记×75% 正交三度再验；此诗正文第二引上限用满对后来关闭（V018 在先+全库查重）；新传并州救郭子仪两句首引（新传单得；解官以贖 V032 零重开）；KNOWN 零如实记录（第十四例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 3. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-330-scene' AS id, 'bg-330-scene' AS subject_id, 'context' AS property_key, '八句全诗本文（ws 页四标记全零、Textquality 75%——零标记与不完备并存，正交三度再验）；全句第二引：正文 V018 text claim 一引在先（生成时全库查重恰一处），两度上限至此用满、此诗正文对后来迁移关闭（audit 硬卡）；绿绮=古琴名、流水=伯牙典均为读法声明非史料断言（页上无自注）。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-330-city' AS id, 'bg-330-city' AS subject_id, 'context' AS property_key, '新立 source-quantangshi-183（audit 断言新源恰一、rollback 删之）；底注锚点片段非空（指向完整，对照 V056 空锚片段——同一体系指向有全有缺各自如实）；卷183 无消歧锚+桩（机器断言各恰一）；分类行「琴詩」照登+非史料声明+不升格；页四标记全零而 75%（正交三度再验）；全唐詩「蜀僧」恰 2 唯本篇、「綠綺」恰 2、「霜鐘」恰 7 他卷在册不引；题有琴而无时→零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-330-world' AS id, 'bg-330-world' AS subject_id, 'context' AS property_key, '琴在史部恰二：tj-217 天宝十三载（甲午，七五四）翰林「琴、棋、數術之工」待诏+tj-219 至德二年（丁酉，七五七）房琯门客董庭蘭鼓琴「以是大招權利」（文件闭域+双年标题窗口机器断言）——史部的琴一为杂艺之具一为权贿之媒，与诗中琴同字两界（三句史文入引为判决证据，诗集侧他人琴句零入引，audit 硬卡）；流水撞字第三例：通鉴恰 1 处=tj-194 贞观十年（丙申，六三六）「車如流水馬如龍」（闭域+窗口+前后字断言）；诗语八词（蜀僧/綠綺/峨眉/萬壑/霜鐘/碧山/秋雲/一揮手）通鉴全零；两传李白段琴/流水/綠綺全零；certainty 不覆盖任何系年，诗 time.span/event.name/written_during 零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-330-person' AS id, 'bg-330-person' AS subject_id, 'context' AS property_key, '新传并州救郭子仪两句并引首引（生成时全库引文域查重：見郭子儀既往零命中，audit 硬卡；新传单得——旧传全卷无郭子儀三字，机器断言）；「解官以贖」V032 已引零重开（audit 硬卡字样）；一救一赎并置为读法声明非史实；传「初」字列传回叙不锚年份（V057 追书边界延伸声明）；李白其余已用判例句零重开；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-330-scene' AS subject_id, 'context' AS property_key, 'claim-bg-330-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-330-city' AS subject_id, 'context' AS property_key, 'claim-bg-330-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-330-world' AS subject_id, 'context' AS property_key, 'claim-bg-330-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-330-person' AS subject_id, 'context' AS property_key, 'claim-bg-330-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 4. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-330-scene' AS id, 'work-t300-330' AS work_id, 'SCENE' AS layer, '八句是一场音乐会的全程，而时间全在听觉里流失：蜀僧抱着绿绮琴，向西走下峨眉峰（「蜀僧抱綠綺，西下峨眉峰」——绿绮是古琴名，此读法系本层声明）；他为我挥手一弹，满耳像听万壑松风（「爲我一揮手，如聽萬壑松」——以山写声）；客居的心被流水洗过，余响融进霜天的钟声（「客心洗流水，餘響入霜鐘」——流水暗用伯牙鼓琴志在流水之典，读法声明，页上无一字自注）；不觉碧山已暮，秋云暗暗叠了几重（「不覺碧山暮，秋雲暗幾重」——曲终才发觉天黑，此诗正文系**第二引**：V018 text claim 已一引在先，全库查重恰一处，两度上限至此用满，此诗正文对后来迁移关闭）。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-330-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-330-city' AS id, 'work-t300-330' AS work_id, 'CITY' AS layer, '这条城的档案先立户籍：**本迁移新立 source-quantangshi-183**（V051 卷159 之后再立全唐詩新卷源，audit 断言新源恰一）。页底注「↑ [[全唐詩/卷183#聽蜀僧濬彈琴|全唐詩·卷183]]」——底本指向**锚点片段非空**（指向篇题完整，对照 V056 的空锚片段：同一体系里指向有全有缺，照登各自如实）。卷183 快照在案：本篇为「无消歧篇题锚点+转引桩」结构（机器断言各恰一，同 V055/V057）。分类行「琴詩」为整理者动作：照登+非史料声明+不升格（V048 判例）——「琴詩」这个类目本身就是整理者替我们建的档案柜。页 {{另}}/{{别}}/{{*}}/<ref> 四全零而 Textquality 75%：零标记×75% 正交横截面第三次复现（V055 首见、V057 再验，机器断言）。蜀僧题族唯本篇：全唐詩「蜀僧」恰 2=锚+桩；「綠綺」恰 2、「霜鐘」恰 7皆在他卷他人诗（琴名与钟声各是各诗，在册不引不牵合）。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-330-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-330-world' AS id, 'work-t300-330' AS work_id, 'WORLD' AS layer, '诗里一张琴洗客心；通鉴「琴」字 75 卷**恰二处**（文件闭域+双年标题窗口机器断言），处处不是这场音乐会：天宝十三载（甲午，七五四）「下至僧、道、書、畫、琴、棋、數術之工皆處之，謂之『待詔』」——琴挂在翰林杂艺待诏名下；至德二年（丁酉，七五七）房琯「或聽門客董庭蘭鼓琴，庭蘭以是大招權利，御史奏庭蘭贓賄」——琴开在宰相门客的权贿案卷里（董庭兰正是当日天下第一琴手）。**史部的琴：一处是杂流之具，一处是权市之媒**——与诗里那张琴同字两界，此三句史文系本层判决证据入引，诗集侧他人琴句在册零入引（audit 硬卡）。**「流水」撞字第三例**：诗中「客心洗流水」是伯牙子期的典；通鉴「流水」恰一处=贞观十年（丙申，六三六）长孙皇后著论「徒戒其車如流水馬如龍」——流水在史部是车马之喻（闭域+窗口+前字「如」后字「馬」机器断言）。诗语「蜀僧」「綠綺」「峨眉」「萬壑」「霜鐘」「碧山」「秋雲」「一揮手」通鉴八连全零（机器断言）——**听琴的语言整场进不了史部**；两传李白段「琴」「流水」「綠綺」全零（传写其人，不提这张琴）。本层零铸造零 relation。' AS body_text, 'SENIOR' AS audience, 'claim-bg-330-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-330-person' AS id, 'work-t300-330' AS work_id, 'PERSON' AS layer, '诗里请人弹琴洗心的，是个「客」；新传倒写了他救人的一面：「**初，白遊并州，見郭子儀，奇之。子儀嘗犯法，白為救免。**」（李白早年游并州，看出郭子儀不凡；郭子儀犯了法，李白出手救了他）——生成时全库查重：此两句既往零入引，本迁移首引；**新传单得**（旧传全卷无「郭子儀」三字，机器断言）。后来郭子儀请解官赎李白死罪（「至是子儀請解官以贖」）V032 已引在册零重开（audit 硬卡字样）——**一救在前、一赎在后，史书只把两头的账都记齐了**：救人者后来系于被救者之手（读法声明，非史实）。
传中「初」字系列传体的回叙（非编年追书——V057 立的追书边界在此再声明一次：回叙不锚年份）；李白其余已用句（山東人/謫仙人/脱靴/宮錦袍/夜郎/青山/辭以孤窮失身 V056 首引）一个不重开；certainty 不覆盖任何系年。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-330-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 5. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-330-scene' AS claim_id, 'source-ws-t300-330' AS source_id, '页面 聽蜀僧濬彈琴（header author+四联八句，五段以「……」相連——全句**第二引**：正文 V018 text claim 一引在先（生成时全库查重恰一处），**两度上限至此用满，此诗正文对后来迁移关闭**；页 {{别}}/{{*}}/<ref>/{{另}} 全零、75%；绿绮/流水之典页上无自注，系引者读法声明）' AS locator, '| author   = 李白……蜀僧抱綠綺，西下峨眉峰。……爲我一揮手，如聽萬壑松。……客心洗流水，餘響入霜鐘。……不覺碧山暮，秋雲暗幾重。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-330-city' AS claim_id, 'source-ws-t300-330' AS source_id, '页面 聽蜀僧濬彈琴（header title+页底注+分类行三段并收——底注「卷183#聽蜀僧濬彈琴」锚点片段非空（指向完整，对照 V056 空锚片段）；「琴詩」分类系整理者动作：非史料声明、不升格；页四标记全零而 75%——零标记×75% 正交第三次复现）' AS locator, '| title    = 聽蜀僧濬彈琴……| notes    = {{Textquality|75%}}↑ [[全唐詩/卷183#聽蜀僧濬彈琴|全唐詩·卷183]]……[[Category:琴詩]]' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-330-city' AS claim_id, 'source-quantangshi-183' AS source_id, '卷一百八十三·李白集《聽蜀僧濬彈琴》篇题锚点+转引桩（无消歧直锚——机器断言锚桩各恰一；全唐詩「蜀僧」恰 2 即此二处，綠綺/霜鐘他卷在册不引）' AS locator, '==[[聽蜀僧濬彈琴]]==……{{:聽蜀僧濬彈琴}}' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-330-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '卷二百一十七·天宝十三载翰林待诏段……卷二百一十九·至德二年房琯听董庭蘭鼓琴段……卷一百九十四·贞观十年長孫后論車如流水段（**通鉴「琴」恰二「流水」恰一**：文件闭域+三处年标题窗口机器断言——史部的琴一为杂艺之具一为权市之媒；流水系车马之喻撞字在册；三段史文皆逐字入引作判决证据，诗集侧他人琴句（綠綺/霜鐘他卷）零入引）' AS locator, '下至僧、道、書、畫、琴、棋、數術之工皆處之，謂之「待詔」。……或聽門客董庭蘭鼓琴，庭蘭以是大招權利。……徒戒其車如流水馬如龍，是開其禍敗之源而防其末流也。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-330-person' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百二·文艺中·李白传并州救郭子仪两句（生成时全库引文域查重：此二句既往零入引，本迁移首引；新传单得——旧传全卷无郭子儀；「解官以贖」V032 已引零重开；与诗中请琴洗心并置是读法声明）' AS locator, '初，白遊并州，見郭子儀，奇之。子儀嘗犯法，白為救免。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 6. background_line（八句：2/2/2/2） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-330-scene' AS background_id, 'text-work-t300-330-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-330-scene' AS background_id, 'text-work-t300-330-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-330-city' AS background_id, 'text-work-t300-330-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-330-city' AS background_id, 'text-work-t300-330-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-330-world' AS background_id, 'text-work-t300-330-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-330-world' AS background_id, 'text-work-t300-330-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-330-person' AS background_id, 'text-work-t300-330-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-330-person' AS background_id, 'text-work-t300-330-ws' AS version_id, 8 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 7. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 58, 'Li Bai Listening to a Monk from Shu Called Jun Playing the Qin background layers (stage-D poem 39, eight-line regulated verse 2/2/2/2): dating verdict thirty-three, twenty-first shape of the title-evidence series -- the same-character split, third form: the poem''s qin washes the traveler''s heart, while the Tongjian''s character qin appears exactly twice (file-closed, twin year-heading windows): under Tianbao 13 the Hanlin Academy gathers monks, Daoists, calligraphers, painters, qin and chess players and other artisans as daizhao attendants, and under Zhide 2 Fang Guan''s guest-retainer Dong Tinglan plays the qin for him and thereby grasps power and profit until the censors impeach him for bribes -- in the histories the qin is once an artisan''s tool and once a broker of power, logged never quoted (audit hard-assert); flowing-water, the third character collision: the poem''s allusion to Boya and Ziqi meets the Tongjian''s single flowing-water -- the 636 Empress Zhangsun essay''s "carriages like flowing water, horses like dragons" (file-closed, windowed, neighbor-character asserted): flowing water in the histories is a metaphor for traffic; eight poem-words score zero across the Tongjian; a new source row registered: quan tang shi juan 183 (first new Quan Tangshi volume source since V051, audit count-and-id asserted, rollback deletes it); the base-pointer anchor fragment here is non-empty (against V056''s empty fragment -- pointers come complete and incomplete, each logged as found); zero-marker-times-75% orthogonality re-verified third time; the poem body hits its two-use ceiling (V018 first, machine-swept, closure declared); PERSON first-cites both adjacent New History sentences on Li Bai rescuing Guo Ziyi at Bingzhou (New History only: the Old History never names Guo; the later redeeming sentence stays closed to V032); KNOWN zero honestly recorded (fourteenth instance, audit reverse-asserts); closed precedent keywords stay out of citations'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 58);
COMMIT;
