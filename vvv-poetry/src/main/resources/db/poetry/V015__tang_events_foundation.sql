-- V015：唐朝大事件骨架（阶段 A 第一批 20 个，617–907）。MySQL 5.6.40 兼容。
-- 只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。前置：V014 已执行。
--
-- 数据源（可复现）：
--   content-agent/pipeline/data/chronology/tang-events.json（每条引文已对维基文库 raw 快照逐字核验，见 validate.py）
--   生成：python3 emit_v015.py
--
-- 写入：20 个 EVENT 实体（新增 18 个；安史之乱沿用 V004 的 event-anshi-rebellion 行）；
--       time.span 断言 20 条（certainty 逐条给：核到起点+终点或单一明确年份=KNOWN，节标题错简=LIKELY）；
--       每条断言引用逐字史料原文；era_of/主题关系不在此迁移发明。
-- 更新：event-anshi-rebellion 与「叛军陷长安」是 V004 的待核草稿——
--       安史终点 763 由通鉴卷222 广德元年条核到，claim-anshi-time 升回 KNOWN；
--       claim-chang-an-capture-time 不动（本轮没有为「陷长安」单独找句子）。
-- 不做：不核验来源、不改 status、不加没有出处的句子。
--
-- 执行前: SELECT version_no FROM poetry_schema_version ORDER BY version_no;  -- 含 14，不含 15
-- 执行后: SELECT COUNT(*) FROM poetry_content WHERE id LIKE 'event-tang-%' OR id='event-anshi-rebellion';  -- 20
--         SELECT certainty FROM poetry_claim WHERE id='claim-anshi-time';  -- KNOWN
-- 回滚: recovery/V015_rollback.sql
START TRANSACTION;

-- ---------- sources ----------
INSERT INTO poetry_source (id, title, author, edition, url, rights_note, verification_status, source_kind, reliability)
SELECT 'source-jiutangshu-benji-events', '《舊唐書》本紀（大事件用：卷1、2、3、6、7、8、9、11、12、14、15、17下、20下）', '劉昫等', '维基文库录入本，页面标注未校对；引文逐字摘自 raw 原文', 'https://zh.wikisource.org/wiki/舊唐書',
       '公有领域古籍。reliability 是编者对正史本纪的分级判断，不代表本条已走 verifySource。', 'PENDING', 'OFFICIAL_HISTORY', 'HIGH'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_source WHERE id = 'source-jiutangshu-benji-events');
INSERT INTO poetry_source (id, title, author, edition, url, rights_note, verification_status, source_kind, reliability)
SELECT 'source-zizhi-tongjian-events', '《資治通鑑》唐紀（大事件用：卷222、254）', '司馬光', '维基文库录入本；年标题自带公元', 'https://zh.wikisource.org/wiki/資治通鑑',
       '公有领域编年史。安史之乱终点、黄巢入京引文取此。reliability 不代表已核验。', 'PENDING', 'OFFICIAL_HISTORY', 'HIGH'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_source WHERE id = 'source-zizhi-tongjian-events');

-- ---------- events (EVENT) ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, start_year, end_year, time_precision)
SELECT * FROM (
SELECT 'event-tang-jinyang-uprising' AS id, 'EVENT' AS entity_type, 'jinyang-uprising' AS slug, '晋阳起兵' AS title, '隋大业十三年，李渊于太原斩杀副留守王威、高君雅，起兵反隋。次年受隋禅建立唐朝。' AS summary, 617 AS start_year, 617 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'event-tang-foundation' AS id, 'EVENT' AS entity_type, 'tang-foundation' AS slug, '唐高祖受禅建国' AS title, '武德元年五月，隋帝禅位，李渊即皇帝位于太极殿，改元武德，唐朝始。' AS summary, 618 AS start_year, 618 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'event-tang-xuanwu-gate' AS id, 'EVENT' AS entity_type, 'xuanwu-gate' AS slug, '玄武门之变' AS title, '武德九年六月初四，秦王李世民于玄武门诛太子建成、齐王元吉；同月立为皇太子，同年八月即位。' AS summary, 626 AS start_year, 626 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'event-tang-weishui-pledge' AS id, 'EVENT' AS entity_type, 'weishui-pledge' AS slug, '渭水便桥之盟' AS title, '玄武门之变后月余，颉利可汗进抵渭水便桥北；太宗亲至渭水责其负约，复于便桥刑白马设盟，突厥退兵。' AS summary, 626 AS start_year, 626 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'event-tang-capture-jieli' AS id, 'EVENT' AS entity_type, 'capture-jieli' AS slug, '李靖破突厥、擒颉利可汗' AS title, '贞观三年至四年唐军北伐，李靖破突厥于阴山，行军副总管张宝相生擒颉利可汗送京师，东突厥亡。' AS summary, 630 AS start_year, 630 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'event-tang-wu-zetian-proclaim' AS id, 'EVENT' AS entity_type, 'wu-zetian-proclaim' AS slug, '武则天改唐为周' AS title, '载初元年/天授元年九月九日，武则天革唐命，改国号为周，改元天授，称圣神皇帝。' AS summary, 690 AS start_year, 690 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'event-tang-shenlong-coup' AS id, 'EVENT' AS entity_type, 'shenlong-coup' AS slug, '神龙政变（中宗复位）' AS title, '神龙元年正月，张柬之等率羽林兵诛张易之、张昌宗，迫武则天传位于太子显；二月复国号为唐。' AS summary, 705 AS start_year, 705 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'event-tang-tanglong-coup' AS id, 'EVENT' AS entity_type, 'tanglong-coup' AS slug, '唐隆之变（诛韦后）' AS title, '景龙四年/唐隆元年六月庚子夜，临淄王李隆基联合太平公主等率兵入北军诛韦温、武延秀等诸韦诸武，韦太后为乱兵所杀。' AS summary, 710 AS start_year, 710 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'event-tang-xiantian-coup' AS id, 'EVENT' AS entity_type, 'xiantian-coup' AS slug, '先天之变（玄宗亲政）' AS title, '先天二年七月，玄宗先发诛常元楷、李慈，捕斩萧至忠、岑羲，太平公主之党尽诛；睿宗即日诏军国政事并取皇帝处分。' AS summary, 713 AS start_year, 713 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'event-anshi-rebellion' AS id, 'EVENT' AS entity_type, 'anshi-rebellion' AS slug, '安史之乱' AS title, '天宝十四载十一月安禄山起兵范阳，两京相继陷落；广德元年史朝义穷蹙自缢，乱平。前后九年。' AS summary, 755 AS start_year, 763 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'event-tang-mawei-mutiny' AS id, 'EVENT' AS entity_type, 'mawei-mutiny' AS slug, '玄宗西奔与马嵬之变' AS title, '潼关失守后天宝十五载六月乙未凌晨，玄宗自延秋门西奔；丙辰至马嵬驿，军人诛杨国忠、逼赐杨贵妃自尽；后太子北留、玄宗入蜀。' AS summary, 756 AS start_year, 756 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'event-tang-tuban-chang-an' AS id, 'EVENT' AS entity_type, 'tuban-chang-an' AS slug, '吐蕃入长安' AS title, '广德元年十月，吐蕃入长安，立广武王承宏为帝；代宗先奔陕州，郭子仪收合散卒复京城。' AS summary, 763 AS start_year, 763 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'event-tang-liangshui-tax' AS id, 'EVENT' AS entity_type, 'liangshui-tax' AS slug, '两税法施行' AS title, '建中元年正月大赦制令：今后除两税外辄率一钱以枉法论，杨炎所议两税正式定为国制。' AS summary, 780 AS start_year, 780 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'event-tang-jingyuan-mutiny' AS id, 'EVENT' AS entity_type, 'jingyuan-mutiny' AS slug, '泾师之变（德宗奔奉天）' AS title, '建中四年十月，泾原军过长安倒戈，德宗出奔，泾军迎朱泚为帅据含元殿；翌年改元兴元，乱平。' AS summary, 783 AS start_year, 783 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'event-tang-yongzhen-internal-zen' AS id, 'EVENT' AS entity_type, 'yongzhen-internal-zen' AS slug, '永贞内禅' AS title, '贞元二十一年正月德宗崩、顺宗立，王伾、王叔文用事；八月顺宗传位皇太子（宪宗），改元永贞。' AS summary, 805 AS start_year, 805 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'event-tang-huaixi-pacified' AS id, 'EVENT' AS entity_type, 'huaixi-pacified' AS slug, '李愬雪夜入蔡州（淮西平）' AS title, '元和十二年，随唐节度使李愬率师入蔡州，执吴元济献于京师，淮西平，元和削藩达顶点。' AS summary, 817 AS start_year, 817 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'event-tang-ganlu-mutiny' AS id, 'EVENT' AS entity_type, 'ganlu-mutiny' AS slug, '甘露之变' AS title, '大和九年十一月，李训、郑注谋诛内官，诈言金吾仗舍石榴树有甘露；事泄，仇士良率兵族诛宰相王涯等十馀家，自是天下权柄归北司。' AS summary, 835 AS start_year, 835 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'event-tang-huangchao-chang-an' AS id, 'EVENT' AS entity_type, 'huangchao-chang-an' AS slug, '黄巢入长安（僖宗出奔）' AS title, '广明元年十二月潼关失守，僖宗自金光门出奔蜀；黄巢前锋入长安，翌年黄巢称帝。' AS summary, 880 AS start_year, 880 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'event-tang-baima-station' AS id, 'EVENT' AS entity_type, 'baima-station' AS slug, '白马驿之祸' AS title, '天祐二年，裴枢、独孤损、崔远、陆扆、王溥、赵崇、王赞等朝臣被赐自尽，同殁于白马驿，尸投于河；唐衣冠为空。' AS summary, 905 AS start_year, 905 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'event-tang-tang-abdication' AS id, 'EVENT' AS entity_type, 'tang-abdication' AS slug, '唐室禅代' AS title, '天祐四年四月，哀帝禅位于朱全忠，唐朝亡；本纪载其禅位诏。' AS summary, 907 AS start_year, 907 AS end_year, 'RANGE' AS time_precision FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_content c WHERE c.id = t.id);

INSERT INTO poetry_event (id, place_id)
SELECT * FROM (
SELECT 'event-tang-jinyang-uprising' AS id, CAST(NULL AS CHAR) AS place_id FROM DUAL
UNION ALL
SELECT 'event-tang-foundation' AS id, 'place-chang-an' AS place_id FROM DUAL
UNION ALL
SELECT 'event-tang-xuanwu-gate' AS id, 'place-chang-an' AS place_id FROM DUAL
UNION ALL
SELECT 'event-tang-weishui-pledge' AS id, CAST(NULL AS CHAR) AS place_id FROM DUAL
UNION ALL
SELECT 'event-tang-capture-jieli' AS id, CAST(NULL AS CHAR) AS place_id FROM DUAL
UNION ALL
SELECT 'event-tang-wu-zetian-proclaim' AS id, CAST(NULL AS CHAR) AS place_id FROM DUAL
UNION ALL
SELECT 'event-tang-shenlong-coup' AS id, CAST(NULL AS CHAR) AS place_id FROM DUAL
UNION ALL
SELECT 'event-tang-tanglong-coup' AS id, CAST(NULL AS CHAR) AS place_id FROM DUAL
UNION ALL
SELECT 'event-tang-xiantian-coup' AS id, CAST(NULL AS CHAR) AS place_id FROM DUAL
UNION ALL
SELECT 'event-tang-mawei-mutiny' AS id, CAST(NULL AS CHAR) AS place_id FROM DUAL
UNION ALL
SELECT 'event-tang-tuban-chang-an' AS id, 'place-chang-an' AS place_id FROM DUAL
UNION ALL
SELECT 'event-tang-liangshui-tax' AS id, 'place-chang-an' AS place_id FROM DUAL
UNION ALL
SELECT 'event-tang-jingyuan-mutiny' AS id, 'place-chang-an' AS place_id FROM DUAL
UNION ALL
SELECT 'event-tang-yongzhen-internal-zen' AS id, CAST(NULL AS CHAR) AS place_id FROM DUAL
UNION ALL
SELECT 'event-tang-huaixi-pacified' AS id, CAST(NULL AS CHAR) AS place_id FROM DUAL
UNION ALL
SELECT 'event-tang-ganlu-mutiny' AS id, 'place-chang-an' AS place_id FROM DUAL
UNION ALL
SELECT 'event-tang-huangchao-chang-an' AS id, 'place-chang-an' AS place_id FROM DUAL
UNION ALL
SELECT 'event-tang-baima-station' AS id, CAST(NULL AS CHAR) AS place_id FROM DUAL
UNION ALL
SELECT 'event-tang-tang-abdication' AS id, CAST(NULL AS CHAR) AS place_id FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_event e WHERE e.id = t.id);

-- ---------- time.span claims ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-event-tang-jinyang-uprising-time' AS id, 'event-tang-jinyang-uprising' AS subject_id, 'time.span' AS property_key, '617..617 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-tang-foundation-time' AS id, 'event-tang-foundation' AS subject_id, 'time.span' AS property_key, '618..618 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-tang-xuanwu-gate-time' AS id, 'event-tang-xuanwu-gate' AS subject_id, 'time.span' AS property_key, '626..626 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-tang-weishui-pledge-time' AS id, 'event-tang-weishui-pledge' AS subject_id, 'time.span' AS property_key, '626..626 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-tang-capture-jieli-time' AS id, 'event-tang-capture-jieli' AS subject_id, 'time.span' AS property_key, '630..630 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-tang-wu-zetian-proclaim-time' AS id, 'event-tang-wu-zetian-proclaim' AS subject_id, 'time.span' AS property_key, '690..690 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-tang-shenlong-coup-time' AS id, 'event-tang-shenlong-coup' AS subject_id, 'time.span' AS property_key, '705..705 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-tang-tanglong-coup-time' AS id, 'event-tang-tanglong-coup' AS subject_id, 'time.span' AS property_key, '710..710 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-tang-xiantian-coup-time' AS id, 'event-tang-xiantian-coup' AS subject_id, 'time.span' AS property_key, '713..713 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-anshi-rebellion-time' AS id, 'event-anshi-rebellion' AS subject_id, 'time.span' AS property_key, '755..763 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-tang-mawei-mutiny-time' AS id, 'event-tang-mawei-mutiny' AS subject_id, 'time.span' AS property_key, '756..756 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-tang-tuban-chang-an-time' AS id, 'event-tang-tuban-chang-an' AS subject_id, 'time.span' AS property_key, '763..763 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-tang-liangshui-tax-time' AS id, 'event-tang-liangshui-tax' AS subject_id, 'time.span' AS property_key, '780..780 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-tang-jingyuan-mutiny-time' AS id, 'event-tang-jingyuan-mutiny' AS subject_id, 'time.span' AS property_key, '783..783 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-tang-yongzhen-internal-zen-time' AS id, 'event-tang-yongzhen-internal-zen' AS subject_id, 'time.span' AS property_key, '805..805 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-tang-huaixi-pacified-time' AS id, 'event-tang-huaixi-pacified' AS subject_id, 'time.span' AS property_key, '817..817 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-tang-ganlu-mutiny-time' AS id, 'event-tang-ganlu-mutiny' AS subject_id, 'time.span' AS property_key, '835..835 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-tang-huangchao-chang-an-time' AS id, 'event-tang-huangchao-chang-an' AS subject_id, 'time.span' AS property_key, '880..880 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-tang-baima-station-time' AS id, 'event-tang-baima-station' AS subject_id, 'time.span' AS property_key, '905..905 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-tang-tang-abdication-time' AS id, 'event-tang-tang-abdication' AS subject_id, 'time.span' AS property_key, '907..907 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_claim c WHERE c.id = t.id);

INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'event-tang-jinyang-uprising' AS subject_id, 'time.span' AS property_key, 'claim-event-tang-jinyang-uprising-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-tang-foundation' AS subject_id, 'time.span' AS property_key, 'claim-event-tang-foundation-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-tang-xuanwu-gate' AS subject_id, 'time.span' AS property_key, 'claim-event-tang-xuanwu-gate-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-tang-weishui-pledge' AS subject_id, 'time.span' AS property_key, 'claim-event-tang-weishui-pledge-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-tang-capture-jieli' AS subject_id, 'time.span' AS property_key, 'claim-event-tang-capture-jieli-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-tang-wu-zetian-proclaim' AS subject_id, 'time.span' AS property_key, 'claim-event-tang-wu-zetian-proclaim-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-tang-shenlong-coup' AS subject_id, 'time.span' AS property_key, 'claim-event-tang-shenlong-coup-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-tang-tanglong-coup' AS subject_id, 'time.span' AS property_key, 'claim-event-tang-tanglong-coup-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-tang-xiantian-coup' AS subject_id, 'time.span' AS property_key, 'claim-event-tang-xiantian-coup-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-tang-mawei-mutiny' AS subject_id, 'time.span' AS property_key, 'claim-event-tang-mawei-mutiny-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-tang-tuban-chang-an' AS subject_id, 'time.span' AS property_key, 'claim-event-tang-tuban-chang-an-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-tang-liangshui-tax' AS subject_id, 'time.span' AS property_key, 'claim-event-tang-liangshui-tax-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-tang-jingyuan-mutiny' AS subject_id, 'time.span' AS property_key, 'claim-event-tang-jingyuan-mutiny-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-tang-yongzhen-internal-zen' AS subject_id, 'time.span' AS property_key, 'claim-event-tang-yongzhen-internal-zen-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-tang-huaixi-pacified' AS subject_id, 'time.span' AS property_key, 'claim-event-tang-huaixi-pacified-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-tang-ganlu-mutiny' AS subject_id, 'time.span' AS property_key, 'claim-event-tang-ganlu-mutiny-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-tang-huangchao-chang-an' AS subject_id, 'time.span' AS property_key, 'claim-event-tang-huangchao-chang-an-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-tang-baima-station' AS subject_id, 'time.span' AS property_key, 'claim-event-tang-baima-station-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-tang-tang-abdication' AS subject_id, 'time.span' AS property_key, 'claim-event-tang-tang-abdication-time' AS claim_id FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection s WHERE s.subject_id = t.subject_id AND s.property_key = t.property_key);

-- ---------- citations：逐字史料原文 ----------
INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-event-tang-jinyang-uprising-time' AS claim_id, 'source-jiutangshu-benji-events' AS source_id, '卷一·高祖本紀（大業十三年=617，由武德元年=618 推得）' AS locator, '五月甲子，高祖與威、君雅視事，太宗密嚴兵於外，以備非常。遣開陽府司馬劉政會告威等謀反，即斬之以徇，遂起義兵。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-event-tang-foundation-time' AS claim_id, 'source-jiutangshu-benji-events' AS source_id, '卷一·高祖本紀·武德元年五月（武德元年=618）' AS locator, '甲子，高祖即皇帝位於太極殿，命刑部尚書蕭造兼太尉，告於南郊，大赦天下，改隋義寧二年為唐武德元年。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-event-tang-xuanwu-gate-time' AS claim_id, 'source-jiutangshu-benji-events' AS source_id, '卷二·太宗上·武德九年六月四日（武德九年=626）' AS locator, '九年，皇太子建成、齊王元吉謀害太宗。六月四日，太宗率長孫無忌、尉遲敬德、房玄齡、杜如晦、宇文士及、高士廉、侯君集、程知節、秦叔寶、段志玄、屈突通、張士貴等於玄武門誅之。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-event-tang-weishui-pledge-time' AS claim_id, 'source-jiutangshu-benji-events' AS source_id, '卷二·太宗上·武德九年八月後（武德九年=626）' AS locator, '乙酉，又幸便橋，與頡利刑白馬設盟，突厥引退。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-event-tang-capture-jieli-time' AS claim_id, 'source-jiutangshu-benji-events' AS source_id, '卷三·太宗下·貞觀四年三月（貞觀四年=630）；卷三·太宗下·貞觀三年（貞觀三年=629）' AS locator, '三月庚辰，大同道行軍副總管張寶相生擒頡利可汗，獻於京師。……甲辰，李靖又破突厥於陰山，頡利可汗輕騎遠遁。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-event-tang-wu-zetian-proclaim-time' AS claim_id, 'source-jiutangshu-benji-events' AS source_id, '卷六·則天皇后本紀·天授元年九月九日（天授元年=690）' AS locator, '九月九日壬午，革唐命，改國號為周。改元為天授，大赦天下，賜酺七日。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-event-tang-shenlong-coup-time' AS claim_id, 'source-jiutangshu-benji-events' AS source_id, '卷七·中宗本紀·神龍元年正月（神龍元年=705）；卷七·中宗本紀·神龍元年二月' AS locator, '神龍元年正月，鳳閣侍郎張柬之、鸞臺侍郎崔玄暐、左羽林將軍敬暉、右羽林將軍桓彥範、司刑少卿袁恕己等定策率羽林兵誅易之、昌宗，迎皇太子監國，總司庶政。……二月甲寅，復國號，依舊為唐。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-event-tang-tanglong-coup-time' AS claim_id, 'source-jiutangshu-benji-events' AS source_id, '卷七·中宗本紀·唐隆元年六月（景龍四年=710）' AS locator, '庚子夜，臨淄王諱舉兵誅諸韋、武，皆梟首於安福門外，韋太后為亂兵所殺。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-event-tang-xiantian-coup-time' AS claim_id, 'source-jiutangshu-benji-events' AS source_id, '卷八·玄宗上·先天二年七月三日（先天二年=713）' AS locator, '先天二年七月三日，尚書左僕射竇懷貞、侍中岑羲、中書令蕭至忠崔湜、雍州長史李晉、左羽林大將軍常元楷、右羽林將軍李慈等與太平公主同謀，期以其月四日以羽林軍作亂。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-event-anshi-rebellion-time' AS claim_id, 'source-jiutangshu-benji-events' AS source_id, '卷九·玄宗下·天寶十四載十一月（天寶十四載=755）' AS locator, '丙寅，范陽節度使安祿山率蕃、漢之兵十餘萬，自幽州南向詣闕，以誅楊國忠為名，先殺太原尹楊光翽於博陵郡。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-event-anshi-rebellion-time' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '通鉴卷二二二·唐紀·廣德元年（癸卯，公元七六三年）' AS locator, '東奔廣陽，廣陽不受；欲北入奚、契丹，至溫泉柵，李懷仙兵追及之；朝義窮蹙，縊於林中，懷仙取其首以獻。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-event-tang-mawei-mutiny-time' AS claim_id, 'source-jiutangshu-benji-events' AS source_id, '卷九·玄宗下·天寶十五載六月（天寶十五載=756）；卷九·玄宗下·天寶十五載六月丙辰；卷九·玄宗下·天寶十五載六月丙辰' AS locator, '乙未，凌晨自延秋門出，微雨沾濕，扈從惟宰相楊國忠、韋見素、內侍高力士及太子，親王，妃主、皇孫已下多從之不及。……丙辰，次馬嵬驛，諸衛頓軍不進。……上即命力士賜貴妃自盡。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-event-tang-tuban-chang-an-time' AS claim_id, 'source-jiutangshu-benji-events' AS source_id, '卷十一·代宗本紀·廣德元年十月（录入本节标题错简，公历从通鉴）' AS locator, '戊寅，吐蕃入京師，立廣武王承宏為帝，仍逼前翰林學士於可封為制封拜。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-event-tang-liangshui-tax-time' AS claim_id, 'source-jiutangshu-benji-events' AS source_id, '卷十二·德宗上·建中元年元年正月（建中元年=780）；卷十二·德宗上·建中元年元年正月大赦条' AS locator, '建中元年春正月丁卯朔，御含元殿，政元建中，群臣上尊號曰聖神文武皇帝。……自艱難以來，征賦名目頗多。今後除兩稅外，輒率一錢，以枉法論。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-event-tang-jingyuan-mutiny-time' AS claim_id, 'source-jiutangshu-benji-events' AS source_id, '卷十二·德宗上·建中四年冬十月（建中四年=783）；卷十二·德宗上·建中四年冬十月戊申' AS locator, '冬十月丙午，詔涇原節度使姚令言率涇原之師救哥舒曜。丁未，涇原軍出京城，至滻水，倒戈謀叛，姚令言不能禁。……亂兵既剽京城，屯於白華，乃於晉昌里迎朱泚為帥，稱太尉，居含元殿。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-event-tang-yongzhen-internal-zen-time' AS claim_id, 'source-jiutangshu-benji-events' AS source_id, '卷十四·順宗本紀·貞元二十一年正月（貞元二十一年=805）；卷十四·順宗本紀（八月傳位前）' AS locator, '貞元二十一年正月癸巳，德宗崩，丙申，即位於太極殿。……事無巨細皆決于李忠言、王伾、王叔文。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-event-tang-huaixi-pacified-time' AS claim_id, 'source-jiutangshu-benji-events' AS source_id, '卷十五·憲宗下·元和十二年（元和元年=806）' AS locator, '己卯、隨、唐節度使李愬率師入蔡州，執吳元濟以獻，淮西平。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-event-tang-ganlu-mutiny-time' AS claim_id, 'source-jiutangshu-benji-events' AS source_id, '卷十七下·文宗下·大和九年十一月（大和九年=835）' AS locator, '壬戌，中尉仇士良率兵誅宰相王涯、賈餗、舒元輿、李訓，新除太原節度王璠，郭行餘、鄭注、羅立言、李孝本，韓約等十餘家，皆族誅。時李訓、鄭注謀誅內官，詐言金吾仗舍石榴樹有甘露，請上觀之。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-event-tang-huangchao-chang-an-time' AS claim_id, 'source-zizhi-tongjian-events' AS source_id, '通鉴卷二五四·唐紀·廣明元年十二月（廣明元年=880）；通鉴卷二五四·唐紀·廣明元年十二月' AS locator, '田令孜帥神策兵五百奉帝自金光門出，惟福、穆、澤、壽四王及妃嬪數人從行，百官皆莫知之。……晡時，黃巢前鋒將柴存入長安' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-event-tang-baima-station-time' AS claim_id, 'source-jiutangshu-benji-events' AS source_id, '卷二十下·哀帝本紀·天祐二年（天祐元年=904）' AS locator, '時樞等七人已至滑州，皆並命于白馬驛，全忠令投屍於河。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-event-tang-tang-abdication-time' AS claim_id, 'source-jiutangshu-benji-events' AS source_id, '卷二十下·哀帝本紀·天祐四年（天祐四年=907）' AS locator, '朕敬以天下，傳禪聖君，退居舊籓，以備三恪' AS evidence_excerpt FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_citation c WHERE c.claim_id = t.claim_id AND c.source_id = t.source_id);

-- ---------- 安史之乱：起点+终点都核到了，升回 KNOWN（V013 因终点未核降的级） ----------
UPDATE poetry_claim SET certainty = 'KNOWN'
 WHERE id = 'claim-anshi-time' AND certainty = 'LIKELY' AND status <> 'PUBLISHED';

-- ---------- in_era 关系：事件落在哪个已核年号里 ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-event-tang-foundation-in-era' AS id, 'event-tang-foundation' AS subject_id, 'era.name' AS property_key, '武德' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-tang-xuanwu-gate-in-era' AS id, 'event-tang-xuanwu-gate' AS subject_id, 'era.name' AS property_key, '武德' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-tang-weishui-pledge-in-era' AS id, 'event-tang-weishui-pledge' AS subject_id, 'era.name' AS property_key, '武德' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-tang-capture-jieli-in-era' AS id, 'event-tang-capture-jieli' AS subject_id, 'era.name' AS property_key, '貞觀' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-tang-wu-zetian-proclaim-in-era' AS id, 'event-tang-wu-zetian-proclaim' AS subject_id, 'era.name' AS property_key, '載初、天授' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-tang-shenlong-coup-in-era' AS id, 'event-tang-shenlong-coup' AS subject_id, 'era.name' AS property_key, '神龍' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-tang-tanglong-coup-in-era' AS id, 'event-tang-tanglong-coup' AS subject_id, 'era.name' AS property_key, '景龍、唐隆、景雲' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-tang-xiantian-coup-in-era' AS id, 'event-tang-xiantian-coup' AS subject_id, 'era.name' AS property_key, '先天、開元' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-anshi-rebellion-in-era' AS id, 'event-anshi-rebellion' AS subject_id, 'era.name' AS property_key, '天寶、至德、乾元、上元（肃宗朝）、寶應、廣德' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-tang-mawei-mutiny-in-era' AS id, 'event-tang-mawei-mutiny' AS subject_id, 'era.name' AS property_key, '天寶、至德' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-tang-tuban-chang-an-in-era' AS id, 'event-tang-tuban-chang-an' AS subject_id, 'era.name' AS property_key, '寶應、廣德' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-tang-liangshui-tax-in-era' AS id, 'event-tang-liangshui-tax' AS subject_id, 'era.name' AS property_key, '建中' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-tang-jingyuan-mutiny-in-era' AS id, 'event-tang-jingyuan-mutiny' AS subject_id, 'era.name' AS property_key, '建中' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-tang-yongzhen-internal-zen-in-era' AS id, 'event-tang-yongzhen-internal-zen' AS subject_id, 'era.name' AS property_key, '貞元、永貞' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-tang-huaixi-pacified-in-era' AS id, 'event-tang-huaixi-pacified' AS subject_id, 'era.name' AS property_key, '元和' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-tang-ganlu-mutiny-in-era' AS id, 'event-tang-ganlu-mutiny' AS subject_id, 'era.name' AS property_key, '大和' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-tang-huangchao-chang-an-in-era' AS id, 'event-tang-huangchao-chang-an' AS subject_id, 'era.name' AS property_key, '廣明' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-tang-baima-station-in-era' AS id, 'event-tang-baima-station' AS subject_id, 'era.name' AS property_key, '天祐' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-event-tang-tang-abdication-in-era' AS id, 'event-tang-tang-abdication' AS subject_id, 'era.name' AS property_key, '天祐' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_claim c WHERE c.id = t.id);

INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'event-tang-foundation' AS subject_id, 'era.name' AS property_key, 'claim-event-tang-foundation-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-tang-xuanwu-gate' AS subject_id, 'era.name' AS property_key, 'claim-event-tang-xuanwu-gate-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-tang-weishui-pledge' AS subject_id, 'era.name' AS property_key, 'claim-event-tang-weishui-pledge-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-tang-capture-jieli' AS subject_id, 'era.name' AS property_key, 'claim-event-tang-capture-jieli-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-tang-wu-zetian-proclaim' AS subject_id, 'era.name' AS property_key, 'claim-event-tang-wu-zetian-proclaim-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-tang-shenlong-coup' AS subject_id, 'era.name' AS property_key, 'claim-event-tang-shenlong-coup-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-tang-tanglong-coup' AS subject_id, 'era.name' AS property_key, 'claim-event-tang-tanglong-coup-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-tang-xiantian-coup' AS subject_id, 'era.name' AS property_key, 'claim-event-tang-xiantian-coup-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-anshi-rebellion' AS subject_id, 'era.name' AS property_key, 'claim-event-anshi-rebellion-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-tang-mawei-mutiny' AS subject_id, 'era.name' AS property_key, 'claim-event-tang-mawei-mutiny-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-tang-tuban-chang-an' AS subject_id, 'era.name' AS property_key, 'claim-event-tang-tuban-chang-an-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-tang-liangshui-tax' AS subject_id, 'era.name' AS property_key, 'claim-event-tang-liangshui-tax-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-tang-jingyuan-mutiny' AS subject_id, 'era.name' AS property_key, 'claim-event-tang-jingyuan-mutiny-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-tang-yongzhen-internal-zen' AS subject_id, 'era.name' AS property_key, 'claim-event-tang-yongzhen-internal-zen-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-tang-huaixi-pacified' AS subject_id, 'era.name' AS property_key, 'claim-event-tang-huaixi-pacified-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-tang-ganlu-mutiny' AS subject_id, 'era.name' AS property_key, 'claim-event-tang-ganlu-mutiny-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-tang-huangchao-chang-an' AS subject_id, 'era.name' AS property_key, 'claim-event-tang-huangchao-chang-an-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-tang-baima-station' AS subject_id, 'era.name' AS property_key, 'claim-event-tang-baima-station-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'event-tang-tang-abdication' AS subject_id, 'era.name' AS property_key, 'claim-event-tang-tang-abdication-in-era' AS claim_id FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection s WHERE s.subject_id = t.subject_id AND s.property_key = t.property_key);

INSERT INTO poetry_relation (id, subject_id, predicate, object_id, claim_id)
SELECT * FROM (
SELECT 'rel-event-tang-foundation-in-era-wude' AS id, 'event-tang-foundation' AS subject_id, 'in_era' AS predicate, 'period-tang-era-wude' AS object_id, 'claim-event-tang-foundation-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-event-tang-xuanwu-gate-in-era-wude' AS id, 'event-tang-xuanwu-gate' AS subject_id, 'in_era' AS predicate, 'period-tang-era-wude' AS object_id, 'claim-event-tang-xuanwu-gate-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-event-tang-weishui-pledge-in-era-wude' AS id, 'event-tang-weishui-pledge' AS subject_id, 'in_era' AS predicate, 'period-tang-era-wude' AS object_id, 'claim-event-tang-weishui-pledge-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-event-tang-capture-jieli-in-era-zhenguan' AS id, 'event-tang-capture-jieli' AS subject_id, 'in_era' AS predicate, 'period-tang-era-zhenguan' AS object_id, 'claim-event-tang-capture-jieli-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-event-tang-wu-zetian-proclaim-in-era-zaichu' AS id, 'event-tang-wu-zetian-proclaim' AS subject_id, 'in_era' AS predicate, 'period-tang-era-zaichu' AS object_id, 'claim-event-tang-wu-zetian-proclaim-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-event-tang-wu-zetian-proclaim-in-era-tianshou' AS id, 'event-tang-wu-zetian-proclaim' AS subject_id, 'in_era' AS predicate, 'period-tang-era-tianshou' AS object_id, 'claim-event-tang-wu-zetian-proclaim-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-event-tang-shenlong-coup-in-era-shenlong' AS id, 'event-tang-shenlong-coup' AS subject_id, 'in_era' AS predicate, 'period-tang-era-shenlong' AS object_id, 'claim-event-tang-shenlong-coup-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-event-tang-tanglong-coup-in-era-jinglong' AS id, 'event-tang-tanglong-coup' AS subject_id, 'in_era' AS predicate, 'period-tang-era-jinglong' AS object_id, 'claim-event-tang-tanglong-coup-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-event-tang-tanglong-coup-in-era-tanglong' AS id, 'event-tang-tanglong-coup' AS subject_id, 'in_era' AS predicate, 'period-tang-era-tanglong' AS object_id, 'claim-event-tang-tanglong-coup-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-event-tang-tanglong-coup-in-era-jingyun' AS id, 'event-tang-tanglong-coup' AS subject_id, 'in_era' AS predicate, 'period-tang-era-jingyun' AS object_id, 'claim-event-tang-tanglong-coup-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-event-tang-xiantian-coup-in-era-xiantian' AS id, 'event-tang-xiantian-coup' AS subject_id, 'in_era' AS predicate, 'period-tang-era-xiantian' AS object_id, 'claim-event-tang-xiantian-coup-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-event-tang-xiantian-coup-in-era-kaiyuan' AS id, 'event-tang-xiantian-coup' AS subject_id, 'in_era' AS predicate, 'period-tang-era-kaiyuan' AS object_id, 'claim-event-tang-xiantian-coup-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-event-anshi-rebellion-in-era-tianbao' AS id, 'event-anshi-rebellion' AS subject_id, 'in_era' AS predicate, 'period-tang-era-tianbao' AS object_id, 'claim-event-anshi-rebellion-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-event-anshi-rebellion-in-era-zhide' AS id, 'event-anshi-rebellion' AS subject_id, 'in_era' AS predicate, 'period-tang-era-zhide' AS object_id, 'claim-event-anshi-rebellion-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-event-anshi-rebellion-in-era-qianyuan' AS id, 'event-anshi-rebellion' AS subject_id, 'in_era' AS predicate, 'period-tang-era-qianyuan' AS object_id, 'claim-event-anshi-rebellion-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-event-anshi-rebellion-in-era-shangyuan-suzong' AS id, 'event-anshi-rebellion' AS subject_id, 'in_era' AS predicate, 'period-tang-era-shangyuan-suzong' AS object_id, 'claim-event-anshi-rebellion-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-event-anshi-rebellion-in-era-baoying' AS id, 'event-anshi-rebellion' AS subject_id, 'in_era' AS predicate, 'period-tang-era-baoying' AS object_id, 'claim-event-anshi-rebellion-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-event-anshi-rebellion-in-era-guangde' AS id, 'event-anshi-rebellion' AS subject_id, 'in_era' AS predicate, 'period-tang-era-guangde' AS object_id, 'claim-event-anshi-rebellion-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-event-tang-mawei-mutiny-in-era-tianbao' AS id, 'event-tang-mawei-mutiny' AS subject_id, 'in_era' AS predicate, 'period-tang-era-tianbao' AS object_id, 'claim-event-tang-mawei-mutiny-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-event-tang-mawei-mutiny-in-era-zhide' AS id, 'event-tang-mawei-mutiny' AS subject_id, 'in_era' AS predicate, 'period-tang-era-zhide' AS object_id, 'claim-event-tang-mawei-mutiny-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-event-tang-tuban-chang-an-in-era-baoying' AS id, 'event-tang-tuban-chang-an' AS subject_id, 'in_era' AS predicate, 'period-tang-era-baoying' AS object_id, 'claim-event-tang-tuban-chang-an-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-event-tang-tuban-chang-an-in-era-guangde' AS id, 'event-tang-tuban-chang-an' AS subject_id, 'in_era' AS predicate, 'period-tang-era-guangde' AS object_id, 'claim-event-tang-tuban-chang-an-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-event-tang-liangshui-tax-in-era-jianzhong' AS id, 'event-tang-liangshui-tax' AS subject_id, 'in_era' AS predicate, 'period-tang-era-jianzhong' AS object_id, 'claim-event-tang-liangshui-tax-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-event-tang-jingyuan-mutiny-in-era-jianzhong' AS id, 'event-tang-jingyuan-mutiny' AS subject_id, 'in_era' AS predicate, 'period-tang-era-jianzhong' AS object_id, 'claim-event-tang-jingyuan-mutiny-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-event-tang-yongzhen-internal-zen-in-era-zhenyuan' AS id, 'event-tang-yongzhen-internal-zen' AS subject_id, 'in_era' AS predicate, 'period-tang-era-zhenyuan' AS object_id, 'claim-event-tang-yongzhen-internal-zen-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-event-tang-yongzhen-internal-zen-in-era-yongzhen' AS id, 'event-tang-yongzhen-internal-zen' AS subject_id, 'in_era' AS predicate, 'period-tang-era-yongzhen' AS object_id, 'claim-event-tang-yongzhen-internal-zen-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-event-tang-huaixi-pacified-in-era-yuanhe' AS id, 'event-tang-huaixi-pacified' AS subject_id, 'in_era' AS predicate, 'period-tang-era-yuanhe' AS object_id, 'claim-event-tang-huaixi-pacified-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-event-tang-ganlu-mutiny-in-era-daihe' AS id, 'event-tang-ganlu-mutiny' AS subject_id, 'in_era' AS predicate, 'period-tang-era-daihe' AS object_id, 'claim-event-tang-ganlu-mutiny-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-event-tang-huangchao-chang-an-in-era-guangming' AS id, 'event-tang-huangchao-chang-an' AS subject_id, 'in_era' AS predicate, 'period-tang-era-guangming' AS object_id, 'claim-event-tang-huangchao-chang-an-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-event-tang-baima-station-in-era-tianyou' AS id, 'event-tang-baima-station' AS subject_id, 'in_era' AS predicate, 'period-tang-era-tianyou' AS object_id, 'claim-event-tang-baima-station-in-era' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-event-tang-tang-abdication-in-era-tianyou' AS id, 'event-tang-tang-abdication' AS subject_id, 'in_era' AS predicate, 'period-tang-era-tianyou' AS object_id, 'claim-event-tang-tang-abdication-in-era' AS claim_id FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_relation r WHERE r.id = t.id);

-- ---------- coverage ----------
INSERT INTO poetry_coverage (id, entity_type, from_year, to_year, coverage_kind, status, note, updated_by, updated_at)
SELECT * FROM (
SELECT 'cov-event-tang-617-907' AS id, 'EVENT' AS entity_type, 617 AS from_year, 907 AS to_year, 'PARTIAL' AS coverage_kind, 'DRAFT' AS status, '大事件骨架第一批 20 条（政治军事转折为主），每条有逐字史料原文；经济文化与地方性事件未录。' AS note, 'chronology-emit' AS updated_by, NOW() AS updated_at FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_coverage c WHERE c.id = t.id);

INSERT INTO poetry_schema_version (version_no, description)
SELECT 15, 'Tang events foundation: 20 dated events 617-907, every time.span cited with verbatim annals text; anshi end re-verified KNOWN'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 15);
COMMIT;

