-- V032：李白《登金陵鳳凰臺》(work-t300-326) 四层背景（阶段 D 第 13 首）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V015、V016、V018 已执行（work-t300-326 与其 text-work-t300-326-ws、
--       source-ws-t300-326 都是 V018 的行；source-jiutangshu-wenyuan / source-xintangshu-wenyi
--       是 V016 的行——引 卷190下/卷202 不另开行）。
--
-- 数据源（可复现）：emit_v032.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/登金陵鳳凰臺.txt（页内实测无 {{另}} 异文——「查过、干净」）、
--   舊唐書卷190下、新唐書卷202。**无全唐詩卷180 本地快照**——本诗没有卷页第二证，
--   诚实缺一条 citation，不假装在场（V025–V031 的卷页桩教训：有则引，无则明说无）。
--
-- 做：4 BACKGROUND content/claim/background + 10 组逐字引用（(claim,source) 主键每对恰一行）+
--   8 行 background_line（scene→1,2｜city→3,4｜world→5,6｜person→7,8，绑 text-work-t300-326-ws）。
--   0 个新 source（ws+两唐书来源行 V018/V016 已登记）。本迁移不碰 poetry_text_line。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「三个南行窗口都到过金陵一带，一个都没系年」）：
--   * 窗口一 赐金放还后浪迹期（740s）、窗口二 永王败后流夜郎遇赦前后（757–758）、
--     窗口三 晚年依李阳冰期（762，葬当涂青山）——两史记他「自采石至金陵」但不系年；
--     年谱推定某年本地核不到不采信；通鉴通篇无李白（tj-191–265 全检零命中）——
--     time.span/event.name/written_during 一个都不造（V023/V024/V027 形状断言+V028 零 relation 断言）；
--   * 出长安两传异写：旧传「由是斥去」vs 新传「懇求還山，帝賜金放還」——并列不裁决；
--   * 死因两说：旧传「醉死於宣城」vs 新传「以左拾遺召，而白已卒，年六十餘」——并列；
--     出生地（山東人/客巴西）、郭子儀赎罪（只新传）同理；KNOWN 只给两传一致处；
--   * 浮雲蔽日的政治指向（注家谓指杨国忠/李林甫）本地核不到，正文与引文都不写。
--
-- 干支对账：本迁移无通鉴年标题、无干支断言（audit 检查4 无涉）。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 31，不含 32
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-jl-%';              -- 空
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-326-ws';  -- 恰 8
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-jl-%';        -- 4
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-326';                                  -- 8
--   SELECT certainty FROM poetry_claim WHERE id='claim-bg-jl-person';   -- KNOWN
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-326'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-326';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-jl-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
-- 回滚: recovery/V032_rollback.sql（按 id 全枚举删除；不动 V018 的行，不动共用来源行）
START TRANSACTION;

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-jl-scene' AS id, 'BACKGROUND' AS entity_type, 'jl-scene' AS slug, '眼前：凤去台空，往北望' AS title, '四层处境背景（阶段 D 第 13 首）；史实句均有逐字引证；三窗口均可到金陵而无一系年→time.span/event.name/written_during 全缺席、零 relation；浮云所指不猜；ws 诗页无页内异文（查过、干净）。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-jl-city' AS id, 'BACKGROUND' AS entity_type, 'jl-city' AS slug, '这座城：三层叠在一起的金陵' AS title, '四层处境背景（阶段 D 第 13 首）；史实句均有逐字引证；三窗口均可到金陵而无一系年→time.span/event.name/written_during 全缺席、零 relation；浮云所指不猜；ws 诗页无页内异文（查过、干净）。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-jl-world' AS id, 'BACKGROUND' AS entity_type, 'jl-world' AS slug, '这个天下：三次贴着长安又离开' AS title, '四层处境背景（阶段 D 第 13 首）；史实句均有逐字引证；三窗口均可到金陵而无一系年→time.span/event.name/written_during 全缺席、零 relation；浮云所指不猜；ws 诗页无页内异文（查过、干净）。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-jl-person' AS id, 'BACKGROUND' AS entity_type, 'jl-person' AS slug, '这个人：传记替诗作答' AS title, '四层处境背景（阶段 D 第 13 首）；史实句均有逐字引证；三窗口均可到金陵而无一系年→time.span/event.name/written_during 全缺席、零 relation；浮云所指不猜；ws 诗页无页内异文（查过、干净）。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-jl-scene' AS id, 'bg-jl-scene' AS subject_id, 'context' AS property_key, '登台动作+所见由诗本文四联内证支撑；「到金陵」由两史采石至金陵段逐字支撑；写作年份不采任何窗口（见 world 层），本 claim 不含系年。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-jl-city' AS id, 'bg-jl-city' AS subject_id, 'context' AS property_key, '三层城为诗本文；采石至金陵两史逐字并立（同件两录）；青山终焉葬东麓为新传逐字（单源照登）。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-jl-world' AS id, 'bg-jl-world' AS subject_id, 'context' AS property_key, '入翰林/出翰林/永王幕/流夜郎/召卒五段两传逐字（各段细节异写处并列）；三窗口均可到金陵而无一系年→time.span/event.name/written_during 全缺席、零 relation；浮云所指不猜（本地核不到）。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-jl-person' AS id, 'bg-jl-person' AS subject_id, 'context' AS property_key, '两传一致处升 KNOWN：天宝初待诏/供奉翰林、高力士脱靴事、坐永王事长流夜郎、遇赦；异写处并列不升：出生地（山东人/客巴西）、出京路径（斥去/恳求赐金放还）、死因（醉酒宣城/召卒年六十餘）、郭子儀赎罪（单源）；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-jl-scene' AS subject_id, 'context' AS property_key, 'claim-bg-jl-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-jl-city' AS subject_id, 'context' AS property_key, 'claim-bg-jl-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-jl-world' AS subject_id, 'context' AS property_key, 'claim-bg-jl-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-jl-person' AS subject_id, 'context' AS property_key, 'claim-bg-jl-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-jl-scene' AS id, 'work-t300-326' AS work_id, 'SCENE' AS layer, '他登的是金陵的凤凰台：「鳳凰臺上鳳凰遊，鳳去臺空江自流。」——传说凤凰来过，如今凤去台空，只有长江照旧流。眼前是「三山半落青天外，二水中分白鷺洲」——三山在半空之外若隐若现，白鹭洲把江水分成两支，这是登台实见的金陵 geography。
但这首诗真正看的方向在北：「總爲浮雲能蔽日，長安不見使人愁」——登台往北望，长安看不见，愁。为什么愁长安：他的人生平两唐书本传写全了（见第 5–8 句那几层），三次到长安边上三次离开。金陵是他到过多次的城——两史同记他「自采石至金陵」——但这首诗写于哪一年，本地核不到（见 world 层）。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-jl-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-jl-city' AS id, 'work-t300-326' AS work_id, 'CITY' AS layer, '金陵在这首诗里是三层城叠在一起：眼下的城（三山、白鹭洲、长江），亡过的城（「吳宮花草埋幽徑，晉代衣冠成古丘」——吴宫的花草埋进荒路，东晋的名门成了古坟丘），和看不见的城（长安）。
他确实在金陵地面上活动过，两史逐字并立：旧唐书「時侍御史崔宗之謫官金陵，與白詩酒唱和。嘗月夜乘舟，自采石達金陵，白衣宮錦袍，於舟中顧瞻笑傲，傍若無人」（卷一百九十下），新唐书写同一件事「嘗乘舟與崔宗之自採石至金陵，著宮錦袍坐舟中，旁若無人」（卷二百零二）——采石到金陵是这条水路的固定一段，锦袍一段两史同记。
他最后葬的地方离金陵一步：新传「度牛渚磯至姑孰，悅謝家青山，欲終焉。及卒，葬東麓」——牛渚矶、姑孰、青山都在金陵上游几十里内。这座城是他人生的终点站。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-jl-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-jl-world' AS id, 'work-t300-326' AS work_id, 'WORLD' AS layer, '长安是这个人的太阳，这首诗的太阳被云遮着：「浮雲能蔽日，長安不見使人愁」。
两传给他三次贴着长安又离开的经过。第一次入：天宝初，旧传「與筠俱待詔翰林」，新传写得更全——贺知章叹他「謫仙人」，「召見金鑾殿……帝賜食，親為調羹，有詔供奉翰林」。第一次出：旧传五个字「由是斥去」（高力士脱靴一段后），新传写「帝欲官白，妃輒沮止」——两传对出长安的原因各写各的，并列。
第二次贴边在安史乱中：新传「安祿山反，轉側宿松、匡廬間，永王璘辟為府僚佐。璘起兵，逃還彭澤，璘敗，當誅」，随后「有詔長流夜郎。會赦，還尋陽」——旧传同段作「白坐長流夜郎。後遇赦得還」。第三次：「代宗立，以左拾遺召，而白已卒」——诏书到了人没了。
**系年的诚实话**：这首诗可能写于三个窗口任何一个（放还后浪迹期 740s、流夜郎遇赦前后 757–758、晚年依李阳冰期 762——都到过金陵一带），两史对他到金陵一句都不系年；年谱推定某年，本地核不到不采信。本诗 time.span、event.name、written_during 全部缺席。浮雲蔽日指谁（注家说指杨国忠、或李林甫）——本地核不到，正文不猜。' AS body_text, 'SENIOR' AS audience, 'claim-bg-jl-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-jl-person' AS id, 'work-t300-326' AS work_id, 'PERSON' AS layer, '李白的本传是全库写得最像他诗的两篇。
入长安前的他：旧传「少有逸才，志氣宏放，飄然有超世之心」，与孔巢父等「隠於徂徠山……時號『竹溪六逸』」；新传多一层世系「興聖皇帝九世孫。其先隋末以罪徙西域，神龍初，遁還，客巴西」——出生地两传不一致（山东人/客巴西），并列。
长安里的他：谪仙人的名号是贺知章给的（新传）；沉香亭醉草、使高力士脱靴两传都有，细节各写（旧传「由是斥去」一笔带过，新传展开到贵妃沮止）；出长安的路径也各说——旧传直接「斥去」，新传是他自己「懇求還山，帝賜金放還」。
乱中的他：永王璘幕、当诛、郭子儀请解官以赎、长流夜郎、会赦——新传全有，旧传无郭子儀赎罪一段（单源，照登不升）。结局两传不同：旧传「竟以飲酒過度，醉死於宣城」，新传「以左拾遺召，而白已卒，年六十餘」——死因两说并列，葬地新传有（青山东麓），旧传无。
「长安不见使人愁」的愁就是这个人的底色：本传说他「飄然有超世之心」，又处处写他到长安门口进不去、进去又被挤出来。登台的愁不用猜谜，传记替诗作答。' AS body_text, 'SENIOR' AS audience, 'claim-bg-jl-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-jl-scene' AS claim_id, 'source-ws-t300-326' AS source_id, '页面 登金陵鳳凰臺（首联+三联逐字以「……」相連；页内实测无 {{另|}} 异文标记——「查过、干净」，登记在计划文档不开 variants 行；全文另见 V018 claim-t300-326-text 引文）' AS locator, '鳳凰臺上鳳凰遊，鳳去臺空江自流。……三山半落青天外，二水中分白鷺洲。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-jl-scene' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百零二·文藝中·李白传（賜金放還+採石至金陵段——本传侧「他在金陵」之证）' AS locator, '懇求還山，帝賜金放還。白浮游四方，嘗乘舟與崔宗之自採石至金陵，著宮錦袍坐舟中，旁若無人。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-jl-city' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十下·文苑下·李白（崔宗之謫官金陵+月夜乘舟自采石達金陵段）' AS locator, '時侍御史崔宗之謫官金陵，與白詩酒唱和。嘗月夜乘舟，自采石達金陵，白衣宮錦袍，於舟中顧瞻笑傲，傍若無人。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-jl-city' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百零二·文藝中·李白传（青山终焉段+採石至金陵段——两史同件第二录+终点站，两段「……」相連）' AS locator, '白晚好黃老，度牛渚磯至姑孰，悅謝家青山，欲終焉。及卒，葬東麓。……懇求還山，帝賜金放還。白浮游四方，嘗乘舟與崔宗之自採石至金陵，著宮錦袍坐舟中，旁若無人。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-jl-city' AS claim_id, 'source-ws-t300-326' AS source_id, '页面 登金陵鳳凰臺（二联逐字——吴宫晋代怀古线纯内证，引此备查）' AS locator, '吳宮花草埋幽徑，晉代衣冠成古丘。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-jl-world' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十下·文苑下·李白（待诏翰林段＋脱靴斥去浪迹段＋永王流夜郎遇赦段；三段以「……」相連——三窗口旧传侧）' AS locator, '旣而玄宗詔筠赴京師，筠薦之於朝，遣使召之，與筠俱待詔翰林。……嘗沉醉殿上，引足令高力士脫靴，由是斥去。乃浪迹江湖，終日沉飲。……祿山之亂，玄宗幸蜀，在途以永王璘為江淮兵馬都督、揚州節度大使。白在宣州謁見，遂辟爲從事。永王謀亂，兵敗，白坐長流夜郎。後遇赦得還，竟以飲酒過度，醉死於宣城。有文集二十卷，行於時。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-jl-world' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百零二·文藝中·李白传（供奉翰林段+贵妃沮止段+永王当诛段+流夜郎会赦段+召卒段；五段以「……」相連——三窗口新传侧；年谱系年本地核不到不采信，见 claim 与文件头）' AS locator, '往見賀知章，知章見其文，歎曰：「子，謫仙人也！」言于玄宗，召見金鑾殿，論當世事，奏頌一篇。帝賜食，親為調羹，有詔供奉翰林。……白嘗侍帝，醉，使高力士脫靴。力士素貴，恥之，擿其詩以激楊貴妃，帝欲官白，妃輒沮止。……安祿山反，轉側宿松、匡廬間，永王璘辟為府僚佐。璘起兵，逃還彭澤，璘敗，當誅。……至是子儀請解官以贖，有詔長流夜郎。會赦，還尋陽，坐事下獄。……李陽冰為當塗令，白依之。代宗立，以左拾遺召，而白已卒，年六十餘。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-jl-world' AS claim_id, 'source-ws-t300-326' AS source_id, '页面 登金陵鳳凰臺（尾联逐字——浮雲蔽日/长安不见之愁的政治指向本地核不到，正文不猜）' AS locator, '總爲浮雲能蔽日，長安不見使人愁。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-jl-person' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十下·文苑下·李白（首段+竹溪六逸段+脱靴段+永王醉死宣城段；四段「……」相連）' AS locator, '李白字太白，山東人。少有逸才，志氣宏放，飄然有超世之心，父爲任城尉，因家焉。……少與魯中諸生孔巢父、韓沔、裴政、張叔明、陶沔等隠於徂徠山，酣歌縱酒，時號「竹溪六逸」。……嘗沉醉殿上，引足令高力士脫靴，由是斥去。乃浪迹江湖，終日沉飲。……祿山之亂，玄宗幸蜀，在途以永王璘為江淮兵馬都督、揚州節度大使。白在宣州謁見，遂辟爲從事。永王謀亂，兵敗，白坐長流夜郎。後遇赦得還，竟以飲酒過度，醉死於宣城。有文集二十卷，行於時。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-jl-person' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百零二·文藝中·李白传（世系段+谪仙人翰林段+脱靴展开段+永王段+流夜郎段+召卒段+青山段；七段以「……」相連，出处同卷同传）' AS locator, '李白，字太白，興聖皇帝九世孫。其先隋末以罪徙西域，神龍初，遁還，客巴西。……往見賀知章，知章見其文，歎曰：「子，謫仙人也！」言于玄宗，召見金鑾殿，論當世事，奏頌一篇。帝賜食，親為調羹，有詔供奉翰林。……白嘗侍帝，醉，使高力士脫靴。力士素貴，恥之，擿其詩以激楊貴妃，帝欲官白，妃輒沮止。……安祿山反，轉側宿松、匡廬間，永王璘辟為府僚佐。璘起兵，逃還彭澤，璘敗，當誅。……至是子儀請解官以贖，有詔長流夜郎。會赦，還尋陽，坐事下獄。……李陽冰為當塗令，白依之。代宗立，以左拾遺召，而白已卒，年六十餘。……白晚好黃老，度牛渚磯至姑孰，悅謝家青山，欲終焉。及卒，葬東麓。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-jl-scene' AS background_id, 'text-work-t300-326-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-jl-scene' AS background_id, 'text-work-t300-326-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-jl-city' AS background_id, 'text-work-t300-326-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-jl-city' AS background_id, 'text-work-t300-326-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-jl-world' AS background_id, 'text-work-t300-326-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-jl-world' AS background_id, 'text-work-t300-326-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-jl-person' AS background_id, 'text-work-t300-326-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-jl-person' AS background_id, 'text-work-t300-326-ws' AS version_id, 8 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 32, 'Li Bai Deng Jinling Fenghuang-tai background layers (stage-D poem 13): the biographies give the whole arc the poem looks back on -- three approaches to Chang-an and three departures (summoned to the Hanlin, expelled after the Gao Lishi boot anecdote per JTS / requesting release per XTS, the Prince Yong affair and long exile to Ye-lang, and the posthumous recall summons that reached only his death); NO time.span, NO event.name, NO written_during, zero relation rows -- all three southbound windows plausibly touch Jinling and the two histories both record his boat trip from Cai-shi to Jinling yet neither ever dates any Jinling stay, the chronology-s year is not adopted, and the Tongjian never mentions Li Bai at all (full scan of ju 191-265); every known conflict kept in parallel (birth place, departure cause, death place and cause, Guo Ziyi-ransom single source); the floating-clouds allegory-target is NOT guessed -- unverifiable locally, so the text stops at chang-an-bu-jian'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 32);
COMMIT;
