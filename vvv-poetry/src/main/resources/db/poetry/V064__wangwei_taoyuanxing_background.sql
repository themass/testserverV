-- V064：王維《桃源行》(work-t300-060) 四层背景（阶段 D 第 45 首·桃源与避地）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V014、V015、V016、V018、V035、V037、V039、V052、V055、V057、V059 已执行
--       （work-t300-060 与其 text-work-t300-060-ws、source-ws-t300-060 是 V018 的行；
--       source-quantangshi-125 是 V037/V055/V057 已立的卷125 源行（本迁移第四次复用，零新源）；
--       source-zizhi-tongjian-events 是 V014/V015 已立的通鉴事件源；
--       本迁移 PERSON 零首引——王维两传可引句全部已入引（V016/V035/V039/V040/V052/V055），
--       零 poetry_citation 新增于 person claim；判例在册句只对照不重开）。
--       本迁移零新 source（audit 断言无诗源表新建插入语句）。
--
-- 数据源（可复现）：emit_v064.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/桃源行__王維_.txt（{{另}}×9 史上最多×75%+底注全锚+尾巴系年注「時年十九」+无三百首标记）、
--   舊唐書卷190下/新唐書卷202（两传王段桃源/武陵/仙源/避地/桃花全零负证+候选句全部已引断言）、
--   全唐詩卷125（作者消歧锚+桩）/桃源 12 处七卷/避秦/桃花水/靈境 在册扫描、
--   通鑑卷209/234/236/251（避地恰二+武陵恰 10 七卷+仙源恰一+三处年标题窗口+
--   tj-209 零年标题断言）+ 通鑑 75 卷/全唐詩 118 卷存快照负证计数扫描
--   （桃源/桃源行/武陵源/避秦/漁舟/漁人/漁樵/桃花/紅樹/房櫳/隈隩/靈境/塵心/游衍）+
--   既有迁移引文域逐句查重——传区间归属、二引/零重开/零首引前提全部生成时断言。
--
-- 做：4 BACKGROUND content/claim/background + 6 组逐字引用（(claim,source) 主键每对恰一行；
--   scene 三行正文切片合并为主键内单条长引文的三段拼接说明——见 CITATIONS 构建）+
--   32 background_line（三十二句长篇 **8/8/8/8 首次**：scene→1-8 city→9-16
--   world→17-24 person→25-32，绑 text-work-t300-060-ws 的 32 行）+ 零 poetry_source 行 + 不碰 poetry_text_line。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span（底注「時年十九」亦不铸）、不写 event.name、不挂 written_during、
--   零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「詩有桃源，桃源在史部七十五卷全零；詩有避地，避地在史部只水旱兵戎」）：
--   * 仙境十六词通鉴全零+避地恰二闭域双窗口入引+武陵恰 10 闭域入引+仙源恰一（50%页不作窗口）；
--   * 汉姓名秦衣服两朝读法/十九岁作与诗名盛期先后对照/「登记在册的世外」均标明读法声明；
--   * 九枚异文引文含标记原样；同页两形并存五度再验（V018 归一形 vs 本迁移九标记原样形）；
--   * 系年注「時年十九」照登不采信为系年（编者语非史源，audit 硬卡仍零铸造）；
--   * 消歧全链闭环照登（ws 文件名→V018 源行→诗集锚点）；同名有主在册不引（V059 判例）；
--   * 此诗正文第二引上限用满：V018 一引在先（双针查重各恰一处），对后来迁移关闭；
--   * 全唐詩避秦/桃花水/靈境/桃源 12 处他卷在册零入引（audit 硬卡零混入）；
--   * KNOWN 零如实记录（第二十例，audit 反向断言 SQL 无 KNOWN 字面量）；
--   * 詩名盛開元（V016/V035）/九歲屬辭（V040）/輞川别墅（V035/V039）判例只对照不重开。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 63，不含 64
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-060-%';             -- 空
--   SELECT id FROM poetry_source WHERE id='source-quantangshi-125';     -- 恰 1（三迁移已立，本迁移复用不新建）
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-060-ws';  -- 恰 32
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-060-%';       -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-060';                                  -- 32（8/8/8/8）
--   SELECT certainty FROM poetry_claim WHERE id LIKE 'claim-bg-060-%';  -- 四行全 LIKELY（有意全 LIKELY）
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-060'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-060';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-060-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
--   SELECT COUNT(*) FROM poetry_source WHERE id='source-quantangshi-125';  -- 恰 1（复用，非本迁移所立）
-- 回滚: recovery/V064_rollback.sql（按 id 全枚举删除；零 source 删除——卷125 源行为三迁移所立）
START TRANSACTION;

-- ---------- 1. 零新 source（卷125 源行三迁移已立，本迁移第四次复用） ----------
-- ---------- 2. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-060-scene' AS id, 'BACKGROUND' AS entity_type, '060-scene' AS slug, '眼前：渔舟入山的完整往返' AS title, '四层处境背景（阶段 D 第 45 首·三十二句长篇 8/8/8/8 首次）；史实句均有逐字引证；系年第三十九次判决（题证系列第廿七状·桃源与避地）「詩有桃源，桃源在史部七十五卷全零；詩有避地，避地在史部只水旱兵戎」——通鉴桃源/桃源行/武陵源/避秦/漁舟/桃花/紅樹/房櫳/隈隩/靈境/塵心全零（整场仙境不进史部）；仙源恰一闭域=仙源公主封号（tj-209 零年标题 50% 页——50% 页永不入围窗口断言镜像用法）；避地恰二闭域双窗口入引（貞元十年甲戌七九四版圖墮於避地+咸通九年戊子八六八往往避地江左——史册流亡窟窿/成仙起因，同字两界第九形态·仙境形态首见）；武陵恰 10 处七卷闭域入引（永貞元年乙酉八〇五郎州武陵龍陽江漲流萬餘家——史部武陵=淹万家江岸/诗武陵源=花竹世外）；全唐詩桃源恰 12 七卷（同名有主在册不引 V059 判例）+避秦/桃花水/靈境各恰一在册零入引+隈隩亦全零；消歧全链闭环首见（ws 文件名→V018 源行→卷125 作者消歧锚贯穿两层库）；底注尾巴纯文本系年注「時年十九」首见（第五形态）照登不采信为系年（audit 硬卡仍零铸造）；{{另}}×9 史上最多×75%正交第七度+同页两形并存五度再验；本页无三百首标记照登；零新源（卷125 源 V037/V055/V057 已立第四次复用）；此诗正文第二引上限用满第十二例对后来关闭（V018 在先+双针查重）；PERSON 零首引（满传无一句可首引——只引不重开的极端形态，生成时断言候选句引文域全部非空）；两传王段桃源/武陵/仙源/避地/桃花全零；KNOWN 零如实记录（第二十例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-060-city' AS id, 'BACKGROUND' AS entity_type, '060-city' AS slug, '这座城：戴到诗集锚点上的消歧器' AS title, '四层处境背景（阶段 D 第 45 首·三十二句长篇 8/8/8/8 首次）；史实句均有逐字引证；系年第三十九次判决（题证系列第廿七状·桃源与避地）「詩有桃源，桃源在史部七十五卷全零；詩有避地，避地在史部只水旱兵戎」——通鉴桃源/桃源行/武陵源/避秦/漁舟/桃花/紅樹/房櫳/隈隩/靈境/塵心全零（整场仙境不进史部）；仙源恰一闭域=仙源公主封号（tj-209 零年标题 50% 页——50% 页永不入围窗口断言镜像用法）；避地恰二闭域双窗口入引（貞元十年甲戌七九四版圖墮於避地+咸通九年戊子八六八往往避地江左——史册流亡窟窿/成仙起因，同字两界第九形态·仙境形态首见）；武陵恰 10 处七卷闭域入引（永貞元年乙酉八〇五郎州武陵龍陽江漲流萬餘家——史部武陵=淹万家江岸/诗武陵源=花竹世外）；全唐詩桃源恰 12 七卷（同名有主在册不引 V059 判例）+避秦/桃花水/靈境各恰一在册零入引+隈隩亦全零；消歧全链闭环首见（ws 文件名→V018 源行→卷125 作者消歧锚贯穿两层库）；底注尾巴纯文本系年注「時年十九」首见（第五形态）照登不采信为系年（audit 硬卡仍零铸造）；{{另}}×9 史上最多×75%正交第七度+同页两形并存五度再验；本页无三百首标记照登；零新源（卷125 源 V037/V055/V057 已立第四次复用）；此诗正文第二引上限用满第十二例对后来关闭（V018 在先+双针查重）；PERSON 零首引（满传无一句可首引——只引不重开的极端形态，生成时断言候选句引文域全部非空）；两传王段桃源/武陵/仙源/避地/桃花全零；KNOWN 零如实记录（第二十例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-060-world' AS id, 'BACKGROUND' AS entity_type, '060-world' AS slug, '这个天下：整场仙境不进史部' AS title, '四层处境背景（阶段 D 第 45 首·三十二句长篇 8/8/8/8 首次）；史实句均有逐字引证；系年第三十九次判决（题证系列第廿七状·桃源与避地）「詩有桃源，桃源在史部七十五卷全零；詩有避地，避地在史部只水旱兵戎」——通鉴桃源/桃源行/武陵源/避秦/漁舟/桃花/紅樹/房櫳/隈隩/靈境/塵心全零（整场仙境不进史部）；仙源恰一闭域=仙源公主封号（tj-209 零年标题 50% 页——50% 页永不入围窗口断言镜像用法）；避地恰二闭域双窗口入引（貞元十年甲戌七九四版圖墮於避地+咸通九年戊子八六八往往避地江左——史册流亡窟窿/成仙起因，同字两界第九形态·仙境形态首见）；武陵恰 10 处七卷闭域入引（永貞元年乙酉八〇五郎州武陵龍陽江漲流萬餘家——史部武陵=淹万家江岸/诗武陵源=花竹世外）；全唐詩桃源恰 12 七卷（同名有主在册不引 V059 判例）+避秦/桃花水/靈境各恰一在册零入引+隈隩亦全零；消歧全链闭环首见（ws 文件名→V018 源行→卷125 作者消歧锚贯穿两层库）；底注尾巴纯文本系年注「時年十九」首见（第五形态）照登不采信为系年（audit 硬卡仍零铸造）；{{另}}×9 史上最多×75%正交第七度+同页两形并存五度再验；本页无三百首标记照登；零新源（卷125 源 V037/V055/V057 已立第四次复用）；此诗正文第二引上限用满第十二例对后来关闭（V018 在先+双针查重）；PERSON 零首引（满传无一句可首引——只引不重开的极端形态，生成时断言候选句引文域全部非空）；两传王段桃源/武陵/仙源/避地/桃花全零；KNOWN 零如实记录（第二十例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-060-person' AS id, 'BACKGROUND' AS entity_type, '060-person' AS slug, '这个人：满传无一句可首引' AS title, '四层处境背景（阶段 D 第 45 首·三十二句长篇 8/8/8/8 首次）；史实句均有逐字引证；系年第三十九次判决（题证系列第廿七状·桃源与避地）「詩有桃源，桃源在史部七十五卷全零；詩有避地，避地在史部只水旱兵戎」——通鉴桃源/桃源行/武陵源/避秦/漁舟/桃花/紅樹/房櫳/隈隩/靈境/塵心全零（整场仙境不进史部）；仙源恰一闭域=仙源公主封号（tj-209 零年标题 50% 页——50% 页永不入围窗口断言镜像用法）；避地恰二闭域双窗口入引（貞元十年甲戌七九四版圖墮於避地+咸通九年戊子八六八往往避地江左——史册流亡窟窿/成仙起因，同字两界第九形态·仙境形态首见）；武陵恰 10 处七卷闭域入引（永貞元年乙酉八〇五郎州武陵龍陽江漲流萬餘家——史部武陵=淹万家江岸/诗武陵源=花竹世外）；全唐詩桃源恰 12 七卷（同名有主在册不引 V059 判例）+避秦/桃花水/靈境各恰一在册零入引+隈隩亦全零；消歧全链闭环首见（ws 文件名→V018 源行→卷125 作者消歧锚贯穿两层库）；底注尾巴纯文本系年注「時年十九」首见（第五形态）照登不采信为系年（audit 硬卡仍零铸造）；{{另}}×9 史上最多×75%正交第七度+同页两形并存五度再验；本页无三百首标记照登；零新源（卷125 源 V037/V055/V057 已立第四次复用）；此诗正文第二引上限用满第十二例对后来关闭（V018 在先+双针查重）；PERSON 零首引（满传无一句可首引——只引不重开的极端形态，生成时断言候选句引文域全部非空）；两传王段桃源/武陵/仙源/避地/桃花全零；KNOWN 零如实记录（第二十例，audit 反向断言）；判例关键语零入引文。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 3. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-060-scene' AS id, 'bg-060-scene' AS subject_id, 'context' AS property_key, '三十二句全诗本文（ws 页 {{另}}×9 史上最多、其余标记全零、Textquality 75%——九枚异文与不完备并存，正交横截面第七度复现）；九枚异文逐枚照登不裁决（去/古、不見/忽值、靜/淨、驚/忽、都/鄉、及至/更聞、遂/去、峰/岑、曲/度，引文含标记原样）；同页两形并存五度再验：V018 正文引文系异文取首项的归一文本，本迁移引文含九枚 {{另}} 标记原样，各从其录；汉姓名秦衣服两朝读法系本层声明；全句第二引：正文 V018 text claim 一引在先（生成时全库查重双针「漁舟逐水愛山春」「不辨仙源何處尋」各恰一处），两度上限至此用满、此诗正文对后来迁移关闭（audit 硬卡）。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-060-city' AS id, 'bg-060-city' AS subject_id, 'context' AS property_key, '消歧全链闭环首见（ws 文件名「桃源行__王維_」→V018 源行 URL/source_locator「桃源行 (王維)」→卷125 作者消歧锚「(王維)|桃源行」——同一首诗的消歧标记贯穿两层库，audit 照登硬卡；同 V059 作者消歧式）；全唐詩「桃源」恰 12 处七卷在册（他人同题诗——同名有主在册不引，V059 王綺判例）；底注尾巴纯文本系年注「時年十九」首见（第五形态：V052 署名/V055 题异/V057 一名/V061 一题两案之后）——照登不采信为系年（编者语非史源，audit 硬卡仍零铸造）；卷125「桃源行」恰 3=锚 2+桩 1 机器断言闭域；底注全锚（同 V058–V063）；本页无 {{唐詩三百首}} 标记照登；分类行「隱逸詩」照登+非史料声明+不升格（V048 判例）；source-quantangshi-125V037/V055/V057 已立、第四次复用零新源；行体乐府题而无时→零铸造零 relation。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-060-world' AS id, 'bg-060-world' AS subject_id, 'context' AS property_key, '通鉴「桃源/桃源行/武陵源/避秦/漁舟/漁人/漁樵/桃花/紅樹/房櫳/隈隩/靈境/塵心/游衍/雞犬相聞/不知有漢」全零（整场仙境不进史部，机器断言）；「仙源」恰一闭域=薛稷子尚仙源公主（tj-209 零年标题 50% 页——50% 页永不入围窗口断言，生成时断言该页零标题）；「避地」恰二闭域双窗口入引=貞元十年（甲戌，七九四）版圖墮於避地+咸通九年（戊子，八六八）往往避地江左（同字两界第九形态·仙境形态首见——史册窟窿/成仙起因，audit 硬卡）；「武陵」恰 10 处七卷闭域+入引一句=永貞元年（乙酉，八〇五）郎州武陵龍陽江漲流萬餘家（史部武陵=淹万家的江岸）；全唐詩桃源恰 12七卷/避秦恰一/桃花水恰一/靈境恰一在册零入引+隈隩全唐詩亦全零（诗语无同源）；certainty 不覆盖任何系年，诗 time.span/event.name/written_during 零铸造零 relation（底注「時年十九」亦不铸，audit 硬卡）。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-060-person' AS id, 'bg-060-person' AS subject_id, 'context' AS property_key, '**PERSON 零首引（系列首见）**：生成时机器断言两传全部可引候选句（詩名盛於開元 V016/V035、九歲知屬辭 V040、開元九年 V016、維尤長五言詩 V052、俱奉佛 V039、別墅在輞川 V035/V039、昆仲宦遊兩都 V035、進士擢第 V016、事母崔氏 V055）既往引文域全部非空——本层不新增逐字引文，行文只对照既有判例（只引不重开的极端形态）；十九岁作（底注）与诗名盛开元天宝（旧传在册句）先后对照系读法声明；「他写找不到的世外，自己有一座登记在册的世外」系读法声明非史实；两传王维段桃源/武陵/仙源/避地/桃花全零（机器断言）；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-060-scene' AS subject_id, 'context' AS property_key, 'claim-bg-060-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-060-city' AS subject_id, 'context' AS property_key, 'claim-bg-060-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-060-world' AS subject_id, 'context' AS property_key, 'claim-bg-060-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-060-person' AS subject_id, 'context' AS property_key, 'claim-bg-060-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 4. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-060-scene' AS id, 'work-t300-060' AS work_id, 'SCENE' AS layer, '三十二句是一次完整往返：渔舟追着水走，爱这山里的春天，两岸桃花夹着古渡口（「漁舟逐水愛山春，兩岸桃花夾{{另|去|古}}津」）；坐看红树忘了路远，青溪走尽忽然遇见人（「坐看紅樹不知遠，行盡青溪{{另|不見|忽值}}人」）；山口里暗中行走才到幽曲处，山忽然开阔尽是平陆；远看一处攒聚的云树，走近是千家散落的花竹；樵客初传下汉朝的姓名，居人还穿着秦代的衣服（「樵客初傳漢姓名，居人未改秦衣服」——两朝之间的一截时间被整村保存，此读法系本层声明）。全篇 {{另}}×9——**史上最多异文枚数**——去/古、不見/忽值、靜/淨、驚/忽、都/鄉、及至/更聞、遂/去、峰/岑、曲/度逐枚照登不裁决；同页两形并存五度再验：V018 正文引文系归一形（「漁舟逐水愛山春，……不辨仙源何處尋。」），本迁移引文含九枚标记原样；此诗正文系**第二引**：V018 一引在先，全库查重双针各恰一处，两度上限至此用满，此诗正文对后来迁移关闭。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-060-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-060-city' AS id, 'work-t300-060' AS work_id, 'CITY' AS layer, '**消歧全链闭环首见**：ws 页文件名「桃源行__王維_.txt」带作者消歧、V018 源行 URL 与 source_locator 亦「桃源行 (王維)」、卷125 诗集锚点「==[[桃源行 (王維)|桃源行]]==」把作者写进消歧器、题目留给展示（同 V059 雜詩作者消歧式）——**同一首诗的消歧标记从维基文件名一路戴到诗集锚点，两层库全链闭环首见**（audit 照登硬卡）；为什么必须消歧：全唐詩「桃源」恰 12 处七卷在册（含他人《桃源行》同题诗）——**同名有主在册不引**（V059 皇子王綺判例），消歧器正是同名之防。底注尾巴「時年十九」：**纯文本系年注首见（第五形态）**——V052 署名异说/V055 题异/V057 一名/V061 一题两案之后，整理者把作年记进底注：十九岁写的。**照登而不采信为系年**：底注系编者语非史源，audit 硬卡诗 time.span 仍零铸造。{{另}}×9×75%（九枚异文与不完备并存，正交第七度）；本页无 {{唐詩三百首}} 标记（与 V061/V063 有标记页互为有无）；底注全锚（同 V058–V063）；分类行「隱逸詩」系整理者动作（V048 判例：非史料声明、不升格）；source-quantangshi-125 系 V037/V055/V057 已立、**第四次复用零新源**（本层零铸造零 relation）。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-060-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-060-world' AS id, 'work-t300-060' AS work_id, 'WORLD' AS layer, '**詩有桃源，桃源在史部七十五卷全零**：通鉴「桃源」「桃源行」「武陵源」「避秦」「漁舟」「桃花」「紅樹」「房櫳」「隈隩」「靈境」「塵心」全零（机器断言）——陶渊明记里的世界整个在史部之外；「仙源」通鉴恰一处（闭域）=薛稷之子尚「**仙源公主**」——史部的仙源是一位公主的封号（tj-209 是零年标题 50% 页——**50% 页永不入围窗口断言**，V056 教训的镜像用法，audit 断言该页零标题）。而「**避地**」恰二处（闭域+双窗口机器断言），逐字入引为判决证据：貞元十年（甲戌，七九四）陸贄論兩税「**版圖墮於避地**」——安史乱后户籍丢在流亡路上；咸通九年（戊子，八六八）龐勳之乱「**往往避地江左**」——百姓躲进江东。**史部的避地是战乱流亡册上的窟窿；诗的「初因避地去人間」把同一动作写成成仙的起因——史部记下消失的人，诗记下消失后成了仙的人**（同字两界第九形态·仙境形态首见）。「**武陵**」通鉴恰 10 处七卷（闭域断言）全是现实地名：永貞元年（乙酉，八〇五）「**郎州武陵、龍陽江漲，流萬餘家**」（闭域+窗口入引）——**史部的武陵是淹死万家的江岸；诗的武陵源是花竹散落的世外**。全唐詩侧在册零入引（机器断言）：「桃源」恰 12 处七卷（他人同题诗）、「避秦」恰一（vol019）、「桃花水」恰一（vol228 杜甫「春岸桃花水」送别语）、「靈境」恰一（vol815）；「隈隩」全唐詩亦全零（诗语无同源）。本层零铸造零 relation。' AS body_text, 'SENIOR' AS audience, 'claim-bg-060-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-060-person' AS id, 'work-t300-060' AS work_id, 'PERSON' AS layer, '**PERSON 零首引（满传无一句可首引——只引不重开的极端形态，系列首见）**：本篇生成时机器断言王维两传全部可引候选句（詩名盛於開元、天寶間V016/V035/九歲知屬辭 V040/開元九年進士擢第 V016/維尤長五言詩 V052/維弟兄俱奉佛 V039/別墅在輞川 V035/V039/昆仲宦遊兩都 V035 等）既往引文域全部非空——**王维传已被十篇迁移引穿，本篇不新增逐字引文**，行文只对照既有判例立说（audit 断言候选句域非空，破了即中止重设计）。
判例对照（读法声明，非史实）：底注系年注说诗是**十九岁作**（开元前），旧传判例句说诗名**盛於開元、天寶間**（V016/V035 在册零重开）——桃源里的仙源「不辨何處尋」，传里王维的辋川别业却句句有地名（華子岡/欹湖/竹裏館 V035/V039 在册）：**他写找不到的世外，自己有一座登记在册的世外**。
**两传王维段桃源/武陵/仙源/避地/桃花全零**（机器断言——写过桃源行的人，传里没有一个仙源字）；certainty 不覆盖任何系年，底注「時年十九」不铸 time.span（audit 硬卡）。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-060-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 5. 逐字引文（(claim,source) 主键每对恰一行；PERSON 零首引无 citation） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-060-scene' AS claim_id, 'source-ws-t300-060' AS source_id, '页面 桃源行 (王維)（三十二句长篇**引文選段**——(claim,source) 主键唯一行内九枚异文所在七句逐枚全引、以「……」相連，余句以 background_line 繫行；全句**第二引**：正文 V018 text claim 一引在先（其形系异文取首项的归一文本，本引文含九枚 {{另}} 标记原样——同页两形并存各从其录），生成时全库查重双针恰一处，**两度上限至此用满，此诗正文对后来迁移关闭**；{{别}}/{{*}}/<ref> 全零、75%；九枚异文史上最多逐枚照登；汉姓名秦衣服两朝读法系引者声明）' AS locator, '漁舟逐水愛山春，兩岸桃花夾{{另|去|古}}津。……坐看紅樹不知遠，行盡青溪{{另|不見|忽值}}人。……月明松下房櫳{{另|靜|淨}}，日出雲中雞犬喧。……{{另|驚|忽}}聞俗客爭來集，競引還家問{{另|都|鄉}}邑。……初因避地去人間，{{另|及至|更聞}}成仙{{另|遂|去}}不還。……自謂經過舊不迷，安知{{另|峰|岑}}壑今來變。……當時只記入山深，青溪幾{{另|曲|度}}到雲林。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-060-city' AS claim_id, 'source-ws-t300-060' AS source_id, '页面 桃源行 (王維)（header title+页底注+分类行三段并收——底注尾巴纯文本系年注「時年十九」=系年式注第五形态照登（编者语非史源，不采信为系年，audit 硬卡仍零铸造）；底注全锚「卷125#桃源行」（同 V058–V063）；本页无 {{唐詩三百首}} 标记照登；分类行系整理者动作：非史料声明、不升格）' AS locator, '| title    = 桃源行……| notes    = {{Textquality|75%}}↑ [[全唐詩/卷125#桃源行|全唐詩·卷125]] 時年十九……[[Category:隱逸詩]]' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-060-city' AS claim_id, 'source-quantangshi-125' AS source_id, '卷一百二十五·王維《桃源行》篇题锚点+转引桩（**作者消歧式**——消歧全链闭环首见：ws 文件名「桃源行__王維_」→V018 源行→本锚「(王維)|桃源行」贯穿两层库；全唐詩「桃源」恰 12 处七卷=同名有主在册不引（V059 王綺判例）；卷125「桃源行」恰 3=锚 2+桩 1 机器断言；源行系V037/V055/V057 已立、本迁移第四次复用零新源）' AS locator, '==[[桃源行 (王維)|桃源行]]==……{{:桃源行 (王維)}}' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-060-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '卷二百三十四·貞元十年（甲戌，七九四）版圖墮於避地段……卷二百五十一·咸通九年（戊子，八六八）往往避地江左段……卷二百三十六·永貞元年（乙酉，八〇五）郎州武陵龍陽江漲流萬餘家段……卷二百零九·仙源公主段（**通鉴桃源全零、避地恰二、武陵恰 10 七卷、仙源恰一**：文件闭域+三处年标题窗口机器断言，tj-209 零年标题 50% 页只入闭域负证不作窗口断言——史部避地是流亡窟窿、武陵是淹万家江岸、仙源是公主封号；三段史文逐字入引为判决证据；杜甫「春岸桃花水」等全唐詩在册句零入引）' AS locator, '版圖墮於避地……往往避地江左……郎州武陵、龍陽江漲，流萬餘家。……其子伯陽尚仙源公主' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 6. background_line（三十二句长篇 8/8/8/8 首次） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-060-scene' AS background_id, 'text-work-t300-060-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-060-scene' AS background_id, 'text-work-t300-060-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-060-scene' AS background_id, 'text-work-t300-060-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-060-scene' AS background_id, 'text-work-t300-060-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-060-scene' AS background_id, 'text-work-t300-060-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-060-scene' AS background_id, 'text-work-t300-060-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-060-scene' AS background_id, 'text-work-t300-060-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-060-scene' AS background_id, 'text-work-t300-060-ws' AS version_id, 8 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-060-city' AS background_id, 'text-work-t300-060-ws' AS version_id, 9 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-060-city' AS background_id, 'text-work-t300-060-ws' AS version_id, 10 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-060-city' AS background_id, 'text-work-t300-060-ws' AS version_id, 11 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-060-city' AS background_id, 'text-work-t300-060-ws' AS version_id, 12 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-060-city' AS background_id, 'text-work-t300-060-ws' AS version_id, 13 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-060-city' AS background_id, 'text-work-t300-060-ws' AS version_id, 14 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-060-city' AS background_id, 'text-work-t300-060-ws' AS version_id, 15 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-060-city' AS background_id, 'text-work-t300-060-ws' AS version_id, 16 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-060-world' AS background_id, 'text-work-t300-060-ws' AS version_id, 17 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-060-world' AS background_id, 'text-work-t300-060-ws' AS version_id, 18 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-060-world' AS background_id, 'text-work-t300-060-ws' AS version_id, 19 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-060-world' AS background_id, 'text-work-t300-060-ws' AS version_id, 20 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-060-world' AS background_id, 'text-work-t300-060-ws' AS version_id, 21 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-060-world' AS background_id, 'text-work-t300-060-ws' AS version_id, 22 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-060-world' AS background_id, 'text-work-t300-060-ws' AS version_id, 23 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-060-world' AS background_id, 'text-work-t300-060-ws' AS version_id, 24 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-060-person' AS background_id, 'text-work-t300-060-ws' AS version_id, 25 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-060-person' AS background_id, 'text-work-t300-060-ws' AS version_id, 26 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-060-person' AS background_id, 'text-work-t300-060-ws' AS version_id, 27 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-060-person' AS background_id, 'text-work-t300-060-ws' AS version_id, 28 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-060-person' AS background_id, 'text-work-t300-060-ws' AS version_id, 29 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-060-person' AS background_id, 'text-work-t300-060-ws' AS version_id, 30 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-060-person' AS background_id, 'text-work-t300-060-ws' AS version_id, 31 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-060-person' AS background_id, 'text-work-t300-060-ws' AS version_id, 32 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 7. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 64, 'Wang Wei''s Ballad of the Peach-Blossom Spring (work-t300-060) background layers (stage-D poem 45, thirty-two-line geyue octet-quartet 8/8/8/8 first time): dating verdict thirty-nine, twenty-seventh shape of the title-evidence series -- the utopia and the flight in two realms: taoyuan, "Ballad of the Peach-Blossom Spring", Wulingyuan, "fleeing Qin", fishing-boat, peach-blossom, red trees, latticed windows, hidden coves, spirit-realm, dust-heart all score zero across the Tongjian -- Tao Yuanming''s world never enters the histories; xianyuan ("fairy source") appears exactly once (file-closed): as the title of a princess married to the son of Xue Ji -- and juan 209 is a heading-less 50%-quality page, so it enters closed-domain negatives only, never a year-window (the mirror lesson of V061''s 50% pages, asserted at build time); bi-di ("fleeing to shelter") appears exactly twice (file-closed, windowed, quoted): in 794 Lu Zhi mourning that "the registers fell into the flight" after the An Lushan wars, and in 868 households "fleeing one and all to the south of the river" before Pang Xun''s revolt -- in the histories flight is a hole in the census; in the poem "first through fleeing they left the world" and became immortals: the histories record the people who vanished, the poem the people who became immortal by vanishing (the ninth same-character split, first utopia-place-name shape); Wuling appears exactly 10 times over 7 volumes (file-closed) and one line is quoted: in 805 the Yang river at Langzhou-Wuling "rose and swept away over ten thousand households" -- the histories'' Wuling drowns households, the poem''s Wulingyuan scatters flowers and bamboo; on the poetry side logged never quoted (machine-asserted): taoyuan 12 times over 7 juan (other poets'' same-titled ballads -- the homonym-with-owner rule of V059), bi-qin once, peach-blossom-waters once (Du Fu''s farewell line), spirit-realm once, while weiyu (hidden cove) scores zero in the poetry corpus too; the disambiguation chain closes end to end for the first time: the ws filename "桃源行__王維_", V018''s source row URL and locator, and juan 125''s author-disambiguated anchor "(王維)|桃源行" -- the same poem wearing its disambiguator through both libraries (audit hard-assert); the base-note tail carries a plain-text dating gloss "written at age nineteen" (fifth plain-text form after signature/title/alternative-name/double-title) -- logged, never promoted to chronology: an editor''s note is not a source, and the poem''s time.span stays uncast (audit hard-assert); nine 另 markers (the most ever on one page) with 75% (orthogonality seventh time) and same-page two-forms co-existence re-verified a fifth time; zero new sources (juan 125''s row reused for the fourth time); the poem body hits its two-use ceiling (V018 first, twin normalized needles, closure declared); PERSON zero-first-cite (first instance: every quotable sentence in both biographies is already cited by V016/V035/V039/V040/V052/V055 -- build-time asserts each candidate''s citation domain non-empty; the layer quotes nothing new and reads the precedent set against the base-note dating instead); both biographies contain no taoyuan/Wuling/xianyuan/bi-di/peach-blossom character in the Wang Wei segments (machine-asserted); KNOWN zero honestly recorded (twentieth instance, audit reverse-asserts); closed precedent keywords stay out of citations'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 64);
COMMIT;
