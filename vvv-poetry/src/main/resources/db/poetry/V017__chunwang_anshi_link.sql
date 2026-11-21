-- V017：把《春望》挂到安史之乱这条线上（阶段 D 第 1 首）。MySQL 5.6.40 兼容。
-- 只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。前置：V011、V013、V015、V016 已执行。
--
-- 数据源（可复现）：
--   content-agent/pipeline/data/chronology/tang-work-links.json
--   （每条引文由脚本对维基文库 wikitext 快照做唯一锚点切片并逐字复核，见 validate.py 的 work-links 段）
--   生成：python3 emit_v017.py
--
-- 做四件事：
--   1) 1 条挂接断言 + 关系：work-chun-wang --written_during--> event-anshi-rebellion，
--      依据注本系年与本诗内证两条原文；标 LIKELY（系年本身仍是两说并存）。
--   2) 3 处占位出处换成真实定位与逐字原文
--      （V004 的「待人工核对：……」——audit C5_citation_locator_placeholder_on_published_claim 挡的就是这种）：
--      《春望》系年 757、杜甫 757 年经历、叛军陷长安 756 ——第三处正是 V015 明说「本轮没有句子」的年份，
--      占位行问的「通鉴纪事年月」和通鉴卷218 给的是同一件事，所以是替换而不是并排新增。
--   3) 1 条新增引用（断言上本来没有该来源的行）。
--   4) claim-chang-an-capture-time 的 756 年有两个独立来源一致，LIKELY 升 KNOWN。
--
-- 主题线不动：V004 第 7 节已把 work-chun-wang 作为 ordinal 4 的成员挂在 theme-anshi-rebellion 上，
--   本迁移补的是那条线里没有出处的部分——「这首诗写在乱中」这件事本身要有出处。
-- 不做：不核验来源（走 verifySource）、不改 status、不发布任何东西、不动 V004/V011/V013 的迁移文件；
--   不裁决《春望》系年——鹤注支持 757，758 一说至今无来源，两条 claim 仍是 DISPUTED，两说并存。
--   不写 poetry_review_log：那张表 V003 起就规定 append-only，只可追加不可回滚，
--   评审结论走 Studio；本迁移不替人下评审结论。
--
-- 执行前: SELECT version_no FROM poetry_schema_version ORDER BY version_no;  -- 含 16，不含 17
--         SELECT claim_id, source_id, locator FROM poetry_citation
--          WHERE claim_id IN ('claim-chun-wang-time-757','claim-exp-757-time','claim-chang-an-capture-time');
--                                                                        -- 3 条 locator 都以「待」开头
--         SHOW VARIABLES LIKE 'character_set_client';                     -- 须为 utf8mb4（与 V001–V016 同规，
--         　　本文件族一律不写 SET NAMES，字符集由连接保证；latin1 连接跑本文件 = 中文全部乱码）
-- 执行后: SELECT locator FROM poetry_citation WHERE claim_id IN
--           ('claim-chun-wang-time-757','claim-exp-757-time','claim-chang-an-capture-time');
--                                                                        -- 都不再以「待」开头
--         SELECT COUNT(*) FROM poetry_citation WHERE locator LIKE '待%';           -- 比执行前少 3
--         SELECT certainty FROM poetry_claim WHERE id='claim-chang-an-capture-time';  -- KNOWN
--         SELECT predicate, object_id FROM poetry_relation WHERE subject_id='work-chun-wang';  -- written_during
-- 回滚: recovery/V017_rollback.sql
START TRANSACTION;

-- ---------- 1. 来源登记（一律 PENDING：登记不等于核验） ----------
INSERT INTO poetry_source (id, title, author, edition, url, rights_note, verification_status, source_kind, reliability)
SELECT 'source-dushi-xiangzhu', '《杜詩詳註》卷四（清仇兆鰲注，引宋鶴注系年）', '仇兆鰲', '欽定四庫全書本（维基文库录入本，页面标注需据扫描版校对；{{YL|}}、{{SK notes|}} 等录入标记在引文中原样保留）', 'https://zh.wikisource.org/wiki/杜詩詳註_(四庫全書本)/卷04',
       '公有领域古籍。系年依据是仇注所引宋人黄鹤注，属注本单源：只用于登记「系年于至德二载」一说有出处，不用于裁决两说。reliability 不代表已核验。', 'PENDING', 'YEAR_BOOK', 'MEDIUM'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_source WHERE id = 'source-dushi-xiangzhu');

-- 本迁移在同一个通鉴来源上增引卷218；沿用同一版次，不另开来源行。
UPDATE poetry_source SET title = '《資治通鑑》唐紀（大事件用：卷218、222、254）'
 WHERE id = 'source-zizhi-tongjian-events' AND title = '《資治通鑑》唐紀（大事件用：卷222、254）' AND verification_status = 'PENDING';

-- ---------- 2. 占位出处 → 真实定位与逐字原文 ----------
-- claim-chun-wang-time-757：V004 占位「待人工核对：系年于至德二载的年谱与页码」换成真实定位与逐字原文
UPDATE poetry_citation
   SET source_id = 'source-dushi-xiangzhu',
       locator = '卷四·春望·鶴注（至德二載=757，由年表換算；同一條注內顧宸異議與「當從鶴説為正」並存，單源注本，故係年仍 DISPUTED）',
       evidence_excerpt = '春望{{SK notes|鶴注此當是{{YL|至德二載}}三月䧟賊營時所作三月者指季春三月趙氏謂禄山反於天寳十四載之十一月至次年正月為三月失於不考耳　顧宸云十五年正月明皇在長安六月始幸蜀安得謂之破是時公移家在奉先五月方入鄜州道路未嘗隔絶安得云家書抵萬金當從鶴説為正'
 WHERE claim_id = 'claim-chun-wang-time-757' AND source_id = 'source-dufu-nianpu-candidate'
   AND locator = '待人工核对：系年于至德二载的年谱与页码';
-- claim-exp-757-time：V004 占位「待人工核对：年谱系年」换成真实定位与逐字原文
UPDATE poetry_citation
   SET source_id = 'source-dushi-xiangzhu',
       locator = '卷四·春望·鶴注（「陷賊營時所作」：人在賊佔長安的注本依據；至德二載=757，由年表換算）',
       evidence_excerpt = '春望{{SK notes|鶴注此當是{{YL|至德二載}}三月䧟賊營時所作'
 WHERE claim_id = 'claim-exp-757-time' AND source_id = 'source-dufu-nianpu-candidate'
   AND locator = '待人工核对：年谱系年';
-- claim-chang-an-capture-time：为 V015 明言「本轮没有句子」的陷长安年份补上带公元纪年的纪事句；同时替换 V004 在同一断言上指向通鉴的占位行（占位问的正是这个年月）
UPDATE poetry_citation
   SET source_id = 'source-zizhi-tongjian-events',
       locator = '通鑑卷二百十八·唐紀三十四（卷首注「起柔兆涒灘五月，至九月」；卷內唯一帶公元的年標題）；起點年標題與入長安句以「……」相連',
       evidence_excerpt = '肅宗文明武德大聖大宣孝皇帝上之下至德元年（丙申，公元七五六年）……安祿山不意上遽西幸，遣使止崔乾祐兵留潼關，凡十日，乃遣孫孝哲將兵入長安，以張通儒為西京留守，崔光遠為京兆尹'
 WHERE claim_id = 'claim-chang-an-capture-time' AND source_id = 'source-anshi-candidate'
   AND locator = '待人工核对：通鉴纪事年月';

-- ---------- 3. 新增引用 ----------
-- 困居贼占长安的两史依据之一（另一条是本传「十五載，禄山䧞京師…宵遁赴河西」，已在 V011 引于处境背景）
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT 'claim-exp-757-time', 'source-dufu-zhuan-candidate', '卷二百一·文藝上·杜甫传（肅宗立于至德元載=756，由年表換算；為賊所得與鹤注「陷賊營」互为呼应）', '肅宗立，自鄜州羸服欲奔行在，為賊所得'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_citation WHERE claim_id = 'claim-exp-757-time' AND source_id = 'source-dufu-zhuan-candidate');

-- ---------- 4. 两个独立来源一致才升级 ----------
-- claim-chang-an-capture-time：756 年由两个独立来源一致：旧唐书·杜甫传「十五載，禄山䧞京師」（V011 已引，天宝十五载=756）+ 通鉴卷218「至德元年（丙申，公元七五六年）」年标题下的入长安句
UPDATE poetry_claim SET certainty = 'KNOWN'
 WHERE id = 'claim-chang-an-capture-time' AND certainty = 'LIKELY' AND status <> 'PUBLISHED';

-- ---------- 5. 诗 × 事件：挂接断言、其出处、以及关系行 ----------
-- audit C4_claim_subject_mismatch_on_relation 要求关系的 claim 主语与关系主语一致，
-- 所以这条断言的主语是 work-chun-wang（「这首诗写于乱中」是诗的属性），关系从它指向事件。
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-chun-wang-in-anshi' AS id, 'work-chun-wang' AS subject_id, 'event.name' AS property_key, '安史之亂（755–763）。757 與 758 兩說年份均落在亂期內，本掛接不受係年分歧影響；鶴注「陷賊營時所作」與詩中「國破」「烽火連三月」為亂中語境依據' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_claim c WHERE c.id = t.id);

INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'work-chun-wang' AS subject_id, 'event.name' AS property_key, 'claim-chun-wang-in-anshi' AS claim_id FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection s WHERE s.subject_id = t.subject_id AND s.property_key = t.property_key);

INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-chun-wang-in-anshi' AS claim_id, 'source-dushi-xiangzhu' AS source_id, '卷四·春望·鶴注（「陷賊營時所作」；至德二載=757，由年表換算）' AS locator, '春望{{SK notes|鶴注此當是{{YL|至德二載}}三月䧟賊營時所作三月者指季春三月趙氏謂禄山反於天寳十四載之十一月至次年正月為三月失於不考耳　顧宸云十五年正月明皇在長安六月始幸蜀安得謂之破是時公移家在奉先五月方入鄜州道路未嘗隔絶安得云家書抵萬金當從鶴説為正' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-chun-wang-in-anshi' AS claim_id, 'source-quantangshi-224' AS source_id, '卷二百二十四·杜甫·春望（「國破」「烽火連三月」為本詩內證）' AS locator, '春望　杜甫：國破山河在，城春草木深。感時花濺淚，恨別鳥驚心。烽火連三月，家書抵萬金。白頭搔更短，渾欲不勝簪。' AS evidence_excerpt FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_citation c WHERE c.claim_id = t.claim_id AND c.source_id = t.source_id);

INSERT INTO poetry_relation (id, subject_id, predicate, object_id, claim_id)
SELECT * FROM (
SELECT 'rel-work-chun-wang-written-during-anshi' AS id, 'work-chun-wang' AS subject_id, 'written_during' AS predicate, 'event-anshi-rebellion' AS object_id, 'claim-chun-wang-in-anshi' AS claim_id FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_relation r WHERE r.id = t.id OR (r.subject_id = t.subject_id AND r.predicate = t.predicate AND r.object_id = t.object_id));

-- ---------- 6. 没有裁决的：数据库里没有表能表达「两说未裁决」，写在数据文件与文档里 ----------
-- gap-chunwang-dating-open（OPEN）
--   · 鹤注（杜诗详注卷四）支持至德二载=757；同一注条内顾宸逐点反驳并主张别解，末附「當從鶴説為正」是仇兆鰲的取舍，不是史裁
--   · 758 一说自 V004 起就没有任何来源，本轮仍未找到任何支持它的材料
--   待决：春望到底系于 757 还是 758：需要能独立于鹤注的系年材料（年谱原本或更早总集题注）才能裁决；裁决前两说并存、相关 claim 保持 DISPUTED

INSERT INTO poetry_schema_version (version_no, description)
SELECT 17, 'Chun Wang linked to the An Lushan rebellion with a sourced relation; 3 V004 placeholder citations replaced by verbatim notes/annals text; Chang-an fall 756 re-verified (KNOWN)'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 17);
COMMIT;

