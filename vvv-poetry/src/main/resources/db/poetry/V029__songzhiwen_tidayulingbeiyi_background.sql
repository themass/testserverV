-- V029：宋之問《題大庾嶺北驛》(work-t300-234) 四层背景 + 一处 V018 文本修复（阶段 D 第 11 首）。
-- MySQL 5.6.40 兼容。只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。
-- 前置：V010、V011、V015、V018 已执行（work-t300-234 与其 text-work-t300-234-ws、source-ws-t300-234
--       都是 V018 的行；source-jiutangshu-wenyuan / source-xintangshu-wenyi 是 V016 的行；
--       source-zizhi-tongjian-events 是 V015 的行——本迁移在同一通鉴来源上增引卷208/209，不另开行）。
--
-- 数据源（可复现）：emit_v029.py 对 /tmp/src-dl 维基文库 wikitext 快照做唯一锚点切片，逐字节一致：
--   ws-poems/題大庾嶺北驛.txt（页内实测无 {{另|}} 异文——如实写明）、資治通鑑卷208/209、
--   全唐詩卷052（卷首注+锚点+转引用桩）、舊唐書卷190中、新唐書卷202。
--
-- §0.5 文本修复（先修文本再挂 bg_line，同事务）：V018 对 234 落 poetry_text_line 时把
--   line_seq 3 误并为四句一行（'我行殊未已，何日復歸來？江靜潮初落，林昏瘴不開。'），8 句只落 5 行。
--   全库扫描此形状仅 234、291 两例（291 另迁移处理——其页有 {{另|}} 异文，先登记后修形）。
--   234 的 version 只被 V018 触过（grep 实测），删 5 插 8 安全；逐字对 ws 诗页 <poem> 块。
--   回滚精确恢复 V018 原 5 行（值原样枚举）。
--
-- 做：1 个新 source 登记（全唐詩卷052，PENDING——登记不等于核验）+
--   poetry_text_line 修复（删 5 行 + 插 8 行，逐字对 ws 快照）+
--   4 BACKGROUND content/claim/background + 11 组逐字引用（(claim,source) 主键每对恰一行）+
--   8 行 background_line（scene→1,2｜city→3,4｜world→5,6｜person→7,8，绑 text-work-t300-234-ws）。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布、不写 review_log；
--   **不给诗铸 time.span、不写 event.name、不挂 written_during、零 poetry_relation 行**——见下。
--
-- 诚实边界（这首的边界是「两次南贬都过岭，诗属哪一程核不到」）：
--   * 窗口一 神龙元年（705）贬泷州（两史+通鉴），窗口二 景云元年（710）流岭表（两史+通鉴）；
--     年谱定 705 本地核不到不采信；710 不在神龙政变(705)时间跨内，挂 written_during 是半证据断言——
--     time.span/event.name/written_during 一个都不造（V023/V024/V027 形状断言 + 零 relation 断言）；
--   * 告发王同皎：旧/新传指之问自为，通鉴指其弟之悌——三源两说逐字并列不裁决，此节不升 KNOWN；
--   * 籍贯虢州弘農(旧) vs 汾州(新) 并列不升；大庾梅信典故零引用不补；
--   * ws 诗页快照实测无页内异文（无 {{另|}}，八句与 V018 正文全同）——「查过、干净」不开 variants 行。
--
-- 干支对账：705=乙巳、710=庚戌（audit-migrations.py 检查4 覆盖标准形；
--   tj-209 的 710 标题为 {{*|庚戌，西元七一〇年}} 变体形，audit 正则不认「西元」——已人工核对无误）。
--
-- 执行前只读检查：
--   SELECT version_no FROM poetry_schema_version ORDER BY version_no;   -- 含 28，不含 29
--   SELECT id FROM poetry_content WHERE id LIKE 'bg-dy-%';              -- 空
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-234-ws';  -- 恰 5（V018 缺陷行）
--   SELECT id FROM poetry_source WHERE id='source-quantangshi-052';     -- 空
-- 执行后核对：
--   SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'bg-dy-%';        -- 4
--   SELECT COUNT(*) FROM poetry_text_line WHERE version_id='text-work-t300-234-ws';  -- 8
--   SELECT COUNT(*) FROM poetry_background_line bl JOIN poetry_text_version tv ON bl.version_id=tv.id
--    WHERE tv.work_id='work-t300-234';                                  -- 8
--   SELECT certainty FROM poetry_claim WHERE id='claim-bg-dy-person';   -- KNOWN
--   SELECT COUNT(*) FROM poetry_claim WHERE subject_id='work-t300-234'
--     AND property_key IN ('time.span','event.name');                   -- 0（有意为0）
--   SELECT COUNT(*) FROM poetry_relation WHERE subject_id='work-t300-234';  -- 0（有意为0）
--   SELECT claim_id, source_id, COUNT(*) c FROM poetry_citation
--    WHERE claim_id LIKE 'claim-bg-dy-%'
--    GROUP BY claim_id, source_id HAVING c > 1;                         -- 空（主键唯一）
-- 回滚: recovery/V029_rollback.sql（按 id 全枚举删除；poetry_text_line 恢复 V018 原 5 行原值；
--   不动 V018 的其他行，不动共用通鉴/两唐书来源行）
START TRANSACTION;

-- ---------- 0. 来源登记（一律 PENDING：登记不等于核验） ----------
INSERT INTO poetry_source (id, title, author, edition, url, rights_note, verification_status, source_kind, reliability)
SELECT * FROM (
SELECT 'source-quantangshi-052' AS id, '《全唐詩》全唐詩/卷052（维基文库录入本）' AS title, NULL AS author, '全唐詩/卷052（维基文库《全唐詩》录入本）' AS edition, 'https://zh.wikisource.org/wiki/全唐詩/卷052' AS url, '维基文库录入本，公有领域古籍。本卷为宋之问诗卷，卷首 Collection header notes 标作者 ''''''宋之問''''''。本诗条目只有锚点+转引用桩，正文在诗页。本行由 emit_v029.py 对快照逐字定位。核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status, 'POETRY_COLLECTION' AS source_kind, 'HIGH' AS reliability FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_source x WHERE x.id = t.id);

-- ---------- 0.5 文本修复：text-work-t300-234-ws 5 行并句 → 8 行（逐字对 ws 诗页） ----------
DELETE FROM poetry_text_line WHERE version_id = 'text-work-t300-234-ws';
INSERT INTO poetry_text_line (version_id, line_seq, content)
SELECT * FROM (
SELECT 'text-work-t300-234-ws' AS version_id, 1 AS line_seq, '陽月南飛雁，' AS content FROM DUAL
UNION ALL
SELECT 'text-work-t300-234-ws' AS version_id, 2 AS line_seq, '傳聞至此回。' AS content FROM DUAL
UNION ALL
SELECT 'text-work-t300-234-ws' AS version_id, 3 AS line_seq, '我行殊未已，' AS content FROM DUAL
UNION ALL
SELECT 'text-work-t300-234-ws' AS version_id, 4 AS line_seq, '何日復歸來？' AS content FROM DUAL
UNION ALL
SELECT 'text-work-t300-234-ws' AS version_id, 5 AS line_seq, '江靜潮初落，' AS content FROM DUAL
UNION ALL
SELECT 'text-work-t300-234-ws' AS version_id, 6 AS line_seq, '林昏瘴不開。' AS content FROM DUAL
UNION ALL
SELECT 'text-work-t300-234-ws' AS version_id, 7 AS line_seq, '明朝望鄉處，' AS content FROM DUAL
UNION ALL
SELECT 'text-work-t300-234-ws' AS version_id, 8 AS line_seq, '應見隴頭梅。' AS content FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_text_line x WHERE x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 1. BACKGROUND content identities ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision)
SELECT * FROM (
SELECT 'bg-dy-scene' AS id, 'BACKGROUND' AS entity_type, 'dy-scene' AS slug, '眼前：雁回而人南' AS title, '四层处境背景（阶段 D 第 11 首）；史实句均有逐字引证；系年两窗口并列（705 泷州／710 钦州），不铸 time.span 不挂乱事线；本迁移并修 V018 对 234 的分行缺陷（5 行并句→8 行，逐字对 ws 诗页）。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-dy-city' AS id, 'BACKGROUND' AS entity_type, 'dy-city' AS slug, '这道岭：过岭就是另一片天' AS title, '四层处境背景（阶段 D 第 11 首）；史实句均有逐字引证；系年两窗口并列（705 泷州／710 钦州），不铸 time.span 不挂乱事线；本迁移并修 V018 对 234 的分行缺陷（5 行并句→8 行，逐字对 ws 诗页）。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-dy-world' AS id, 'BACKGROUND' AS entity_type, 'dy-world' AS slug, '这个天下：两次贬岭表，一次赐死' AS title, '四层处境背景（阶段 D 第 11 首）；史实句均有逐字引证；系年两窗口并列（705 泷州／710 钦州），不铸 time.span 不挂乱事线；本迁移并修 V018 对 234 的分行缺陷（5 行并句→8 行，逐字对 ws 诗页）。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
UNION ALL
SELECT 'bg-dy-person' AS id, 'BACKGROUND' AS entity_type, 'dy-person' AS slug, '这个人：三源对质的名声' AS title, '四层处境背景（阶段 D 第 11 首）；史实句均有逐字引证；系年两窗口并列（705 泷州／710 钦州），不铸 time.span 不挂乱事线；本迁移并修 V018 对 234 的分行缺陷（5 行并句→8 行，逐字对 ws 诗页）。' AS summary, 'UNKNOWN' AS time_precision FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

-- ---------- 2. claims（主语=BACKGROUND content 行；claim id 带 claim- 前缀，V004 同款） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-bg-dy-scene' AS id, 'bg-dy-scene' AS subject_id, 'context' AS property_key, '题壁动作由题目（题+驿）与起联本文内证支撑；贬途由两史贬泷州逐字支撑；诗属哪一程贬不裁决（见 world 层）。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-dy-city' AS id, 'bg-dy-city' AS subject_id, 'context' AS property_key, '岭南物象为诗本文；贬泷州两史各记一笔；梅信典故核不到零引用，正文照诗句不补。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-dy-world' AS id, 'bg-dy-world' AS subject_id, 'context' AS property_key, '705 追述、710 流岭表两条通鉴逐字（年标题归属已分记；710 标题为 {{*|干支，西元…}} 变体形）；旧传结局九字逐字；两窗口并列不裁决、不铸诗 time.span、不挂 written_during。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-bg-dy-person' AS id, 'bg-dy-person' AS subject_id, 'context' AS property_key, '附易之贬岭南、睿宗立流岭表、先天赐死——两史+通鉴一致处升 KNOWN；告发主谋三源两说（旧/新指之问，通鉴指其弟之悌）并列不裁决不升；籍贯两史各异并列不升；certainty 不覆盖任何系年。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);
INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'bg-dy-scene' AS subject_id, 'context' AS property_key, 'claim-bg-dy-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-dy-city' AS subject_id, 'context' AS property_key, 'claim-bg-dy-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-dy-world' AS subject_id, 'context' AS property_key, 'claim-bg-dy-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-dy-person' AS subject_id, 'context' AS property_key, 'claim-bg-dy-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 3. background rows ----------
INSERT INTO poetry_background (id, work_id, layer, body_text, audience, claim_id)
SELECT * FROM (
SELECT 'bg-dy-scene' AS id, 'work-t300-234' AS work_id, 'SCENE' AS layer, '诗的开头是一个对比：「陽月南飛雁，傳聞至此回。」——十月的大雁往南飞，听说到了大庾岭就掉头；「我行殊未已，何日復歸來？」——雁回，人却还要往南走，归期无人能答。
题目就是动作：「題」大庾嶺「北驛」——这首诗是题在岭北驿站墙上的。他为什么在这里：贬官。哪一程贬的，两程都对得上（见第 5、6 句那层），但「贬、过岭、北望」这个为什么，本传一个字都不用多给。' AS body_text, 'PRIMARY' AS audience, 'claim-bg-dy-scene' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-dy-city' AS id, 'work-t300-234' AS work_id, 'CITY' AS layer, '岭就是界线，界线是诗本文立起来的：大雁到这里回头，人过了岭就是另一片天——「江靜潮初落，林昏瘴不開」，潮水安静落下去，密林的瘴气散不开，这是他亲眼看见的岭南。
路线两史各记一笔：旧唐书「及易之等敗，左遷瀧州參軍」（泷州在岭南道），新唐书「及敗，貶瀧州，朝隱崖州，並參軍事」（与阎朝隐同句受贬）。北望的那一眼在尾联：「明朝望鄉處，應見隴頭梅」——望乡只能看见岭上的梅，岭南北之界，梅信之说本库核不到出处，照诗句原文，不补故事。' AS body_text, 'JUNIOR' AS audience, 'claim-bg-dy-city' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-dy-world' AS id, 'work-t300-234' AS work_id, 'WORLD' AS layer, '通鉴把这条政治线框在两个年标题里。神龙元年（乙巳，公元七零五年）标题下的追述：「初，少府監丞弘農宋之問及弟兗州司倉之遜皆坐附會張易之貶嶺南，逃歸東都，匿於友人光祿卿、駙馬都尉王同皎家」——他是张易之集团倒台的余党，这是第一次。
景云元年（庚戌，公元七一〇年）：「越州長史宋之問，饒州刺史冉祖雍，坐諂附韋、武，皆流嶺表」——睿宗即位，他又因为依附韦后、武三思流了一次岭表。两次南贬之间，还有告发王同皎、靠太平公主起用、又因赃污外放的全套起落。旧传只用九个字收他的结局：「配徙欽州。先天中，賜死於徙所」。
边界：这首诗可以属 705 程，也可以属 710 程——两程都过岭，核不到哪一程。年谱定 705，本地核不到不采信；两窗口并列，不铸系年。' AS body_text, 'SENIOR' AS audience, 'claim-bg-dy-world' AS claim_id FROM DUAL
UNION ALL
SELECT 'bg-dy-person' AS id, 'work-t300-234' AS work_id, 'PERSON' AS layer, '这个人的名声和下场，三源对质着看。
籍贯两史各说一座：旧传「虢州弘農人」，新传「汾州人」——并列。
夺锦袍的快事两传各记一段（旧传「奪虬錦袍以賞之」、新传「更奪袍以賜」）；新传有全库最活的一笔，记他接到赐死诏的样子：「之問得詔震汗，東西步，不引決」，冉祖雍请使者宽限时他「荒悸不能處家事」，被祖雍斥了一句「奈何遲回邪」，「乃飲食洗沐就死」。
最要紧的官司在告发：王同皎谋诛武三思，旧传「之問令兄子發其事以自贖…由是深爲義士所譏」，新传「之問得其實，令兄子曇與冉祖雍上急變，因丐贖罪…天下醜其行」——两传都指他自己告发求赎；通鉴却把告密记在弟弟头上：「之遜於簾下聞之，密遣其子曇及甥校書郎李悛告三思，欲以自贖」。三源两说，逐字并列不裁决——此节不升 KNOWN。
KNOWN 只给三源一致的：附张易之贬岭南、睿宗立再流岭表、先天中赐死于徙所。
诗人的地位新传有定评：「學者宗之，號為『沈宋』」；而旧传那九个字「之問再被竄謫，經途江、嶺，所有篇詠，傳布遠近」——路上写的诗传遍远近，这是本地史料里唯一一条说他一路都在写诗的直证。' AS body_text, 'SENIOR' AS audience, 'claim-bg-dy-person' AS claim_id FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background x WHERE x.id = t.id);

-- ---------- 4. 逐字引文（(claim,source) 主键每对恰一行） ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-bg-dy-scene' AS claim_id, 'source-ws-t300-234' AS source_id, '页面 題大庾嶺北驛（起二句+二联逐字以「……」相連；页内实测无 {{另|}} 异文标记，八句与 V018 入库正文全同——V018 分行缺陷由本迁移 §0.5 修复；全文另见 V018 claim-t300-234-text 引文）' AS locator, '陽月南飛雁，傳聞至此回。……我行殊未已，何日復歸來？' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-dy-city' AS claim_id, 'source-ws-t300-234' AS source_id, '页面 題大庾嶺北驛（三联+尾联逐字以「……」相連——瘴/潮为亲见岭南，梅为北望所见）' AS locator, '江靜潮初落，林昏瘴不開。……明朝望鄉處，應見隴頭梅。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-dy-city' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十中·文苑中·宋之问传（泷州贬+逃还段）' AS locator, '及易之等敗，左遷瀧州參軍。未幾，逃還，匿於洛陽人張仲之家。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-dy-city' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百二·文藝中·宋之问传（贬泷州句——与阎朝隐同句，逐字照登）' AS locator, '及敗，貶瀧州，朝隱崖州，並參軍事。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-dy-world' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '通鑑卷二百零八·神龍元年（乙巳，公元七零五年）标题+追述条（贬岭南、匿王同皎家、告发系于弟之悌）＋卷二百零九·景雲元年（庚戌，公元七一〇年）标题+流岭表条；四段以「……」相連，年標題歸屬已分記；710 年标题在快照中为 {{*|干支，西元…}} 变体形，逐字照登' AS locator, '=== 中宗大和大聖大昭孝皇帝中神龍元年（乙巳，公元七零五年）===……初，少府監丞弘農宋之問及弟兗州司倉之遜皆坐附會張易之貶嶺南，逃歸東都，匿於友人光祿卿、駙馬都尉王同皎家。同皎疾武三思及韋後所為，每與所親言之，輒切齒。之遜於簾下聞之，密遣其子曇及甥校書郎李悛告三思，欲以自贖。……===中宗大和大聖大昭孝皇帝下景雲元年{{*|庚戌，西元七一〇年}}===……越州長史宋之問，饒州刺史冉祖雍，坐諂附韋、武，皆流嶺表。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-dy-world' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十中·文苑中·宋之问传（钦州流+先天赐死段——结局九字）' AS locator, '睿宗即位，以之問嘗附張易之、武三思，配徙欽州。先天中，賜死於徙所。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-dy-person' AS claim_id, 'source-ws-t300-234' AS source_id, '页面 題大庾嶺北驛（header title+author 字段逐字——署名第三证，V018 T1_TITLE 路数）' AS locator, '| title    = 題大庾嶺北驛
| section  =
| author   = 宋之問' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-dy-person' AS claim_id, 'source-jiutangshu-wenyuan' AS source_id, '卷一百九十中·文苑中·宋之问传（籍贯段＋夺锦袍＋附易之＋泷州段＋告发段＋赐死段＋路上写诗句；七段以「……」相連，出处同卷同传）' AS locator, '宋之問，虢州弘農人。……則天以錦袍賜之。及之問詩成，則天稱其詞愈高，奪虬錦袍以賞之。……易之兄弟雅愛其才，之問亦傾附焉。……及易之等敗，左遷瀧州參軍。未幾，逃還，匿於洛陽人張仲之家。……仲之與駙馬都尉王同皎等謀殺武三思，之問令兄子發其事以自贖。及同皎等獲罪，起之問爲鴻臚主薄，由是深爲義士所譏。……睿宗即位，以之問嘗附張易之、武三思，配徙欽州。先天中，賜死於徙所。……之問再被竄謫，經途江、嶺，所有篇詠，傳布遠近。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-dy-person' AS claim_id, 'source-xintangshu-wenyi' AS source_id, '卷二百二·文藝中·宋之问传（籍贯段＋夺锦袍＋泷州句＋告发段＋流钦州＋赐死两细节段＋沈宋定评；七段以「……」相連，出处同卷同传）' AS locator, '宋之問，字延清，一名少連，汾州人。……后賜錦袍，之問俄頃獻，后覽之嗟賞，更奪袍以賜。……及敗，貶瀧州，朝隱崖州，並參軍事。……仲之與王同皎謀殺三思安王室，之問得其實，令兄子曇與冉祖雍上急變，因丐贖罪，由是擢鴻臚主簿，天下醜其行。……睿宗立，以獪險盈惡詔流欽州。……之問得詔震汗，東西步，不引決。……乃飲食洗沐就死。……及之問、沈佺期，又加靡麗，回忌聲病，約句准篇，如錦繡成文，學者宗之，號為「沈宋」。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-dy-person' AS claim_id, 'source-quantangshi-052' AS source_id, '页面 全唐詩/卷052（卷首作者注＋本诗锚点与转引用桩 {{:題大庾嶺北驛}}；卷页无正文，正文证据在诗页；同 V022/V025–V028 桩教训）' AS locator, '''''''宋之問''''''……==[[題大庾嶺北驛]]==
{{:題大庾嶺北驛}}' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-bg-dy-person' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '通鑑卷二百零八·追述条（告发主谋的第二说：弟之悌遣子——PERSON 层三源两说的通鉴侧出处）' AS locator, '初，少府監丞弘農宋之問及弟兗州司倉之遜皆坐附會張易之貶嶺南，逃歸東都，匿於友人光祿卿、駙馬都尉王同皎家。同皎疾武三思及韋後所為，每與所親言之，輒切齒。之遜於簾下聞之，密遣其子曇及甥校書郎李悛告三思，欲以自贖。' AS evidence_excerpt FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

-- ---------- 5. background_line（挂修复后的 8 行新 line_seq） ----------
INSERT INTO poetry_background_line (background_id, version_id, line_seq)
SELECT * FROM (
SELECT 'bg-dy-scene' AS background_id, 'text-work-t300-234-ws' AS version_id, 1 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-dy-scene' AS background_id, 'text-work-t300-234-ws' AS version_id, 2 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-dy-city' AS background_id, 'text-work-t300-234-ws' AS version_id, 3 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-dy-city' AS background_id, 'text-work-t300-234-ws' AS version_id, 4 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-dy-world' AS background_id, 'text-work-t300-234-ws' AS version_id, 5 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-dy-world' AS background_id, 'text-work-t300-234-ws' AS version_id, 6 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-dy-person' AS background_id, 'text-work-t300-234-ws' AS version_id, 7 AS line_seq FROM DUAL
UNION ALL
SELECT 'bg-dy-person' AS background_id, 'text-work-t300-234-ws' AS version_id, 8 AS line_seq FROM DUAL
) AS t
WHERE NOT EXISTS (SELECT 1 FROM poetry_background_line x WHERE x.background_id = t.background_id AND x.version_id = t.version_id AND x.line_seq = t.line_seq);

-- ---------- 6. 版本账本（不给诗铸 time.span / event.name / written_during，零 relation，理由在文件头） ----------
INSERT INTO poetry_schema_version (version_no, description)
SELECT 29, 'song-zhi-wen ti-dayu-ling-bei-yi background layers plus one V018 text-line repair (inserts-after-repair): poetry_text_line rows for text-work-t300-234-ws were mis-merged by V018 (four poem-lines packed into line_seq 3, 5 rows for an eight-line regulated verse; full-corpus scan finds this shape only for 234 and 291) -- this migration deletes the 5 rows and re-inserts 8 rows word-for-word against the ws page, and the rollback restores V018 original 5 rows verbatim; four background layers with why-written anchored by the JTS biography itself (demoted after Zhang Yizhi fell, exiled again under Ruizong, ordered to die at the place of exile; and the unique local witness that his exile-road poems spread far); deliberately NO time.span, NO event.name, NO written_during and zero relation rows -- he crossed the ridge on two separate southbound exiles (705 Longzhou and 710 Qinzhou) and neither source says which journey carried this poem; the denunciation of Wang Tongjiao is left unadjudicated in three sources two voices (JTS and XTS blame Song Zhiwen himself, the Tongjian blames his younger brother Zhi-ti)'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 29);
COMMIT;
