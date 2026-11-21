-- V014：唐朝年表底座（帝王 + 已核年号）。MySQL 5.6.40 兼容。
-- 只写文件，由用户在已备份的目标库上手工执行；不要用 `mysql --force`。前置：V013 已执行。
--
-- 数据源（可复现）：
--   content-agent/pipeline/data/chronology/tang-rulers.json
--   content-agent/pipeline/data/chronology/tang-eras.json
--   生成：python3 emit_v014.py
--
-- 已写入：23 位帝王（教育部年表 + 本纪卷次）；已核年号覆盖武德–天祐全段（含武周–先天与中晚唐；公历取通鉴年标题）。
-- 不做：不核验来源、不改 status。
--
-- 执行前: SELECT version_no FROM poetry_schema_version ORDER BY version_no;  -- 含 13，不含 14
-- 执行后: SELECT COUNT(*) FROM poetry_period WHERE id LIKE 'period-tang-era-%';  -- 75
--         SELECT COUNT(*) FROM poetry_person WHERE id LIKE 'person-tang-ruler-%'; -- 23
-- 回滚: recovery/V014_rollback.sql
START TRANSACTION;

-- ---------- sources ----------
INSERT INTO poetry_source (id, title, author, edition, url, rights_note, verification_status, source_kind, reliability)
SELECT 'source-moe-rulers-table',
       '教育部《重編國語辭典修訂本》附錄·歷代帝王在位年表',
       '中華民國教育部',
       '修訂本附錄；只有帝王与公元年，没有年号列',
       'https://dict.revised.moe.edu.tw/appendix.jsp?ID=22&la=0&page=2&powerMode=0&ver=4',
       '政府公开辞书附录。reliability 是编者分级，不代表本条已走 verifySource。表内文帝/武帝/宣帝在此按《旧唐书》本纪写作文宗/武宗/宣宗。',
       'PENDING', 'ONLINE_ENTRY', 'MEDIUM'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_source WHERE id = 'source-moe-rulers-table');

INSERT INTO poetry_source (id, title, author, edition, url, rights_note, verification_status, source_kind, reliability)
SELECT 'source-jiutangshu-benji-chronology',
       '《舊唐書》本紀（年表用：卷1–20）',
       '劉昫等',
       '维基文库录入本，页面标注未校对；年号取 ==/=== 节题与贞元岁首句',
       'https://zh.wikisource.org/wiki/舊唐書',
       '公有领域古籍。与 source-jiutangshu-benji（V013）同源，覆盖年表所用全卷；reliability 不代表已核验。',
       'PENDING', 'OFFICIAL_HISTORY', 'HIGH'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_source WHERE id = 'source-jiutangshu-benji-chronology');

INSERT INTO poetry_source (id, title, author, edition, url, rights_note, verification_status, source_kind, reliability)
SELECT 'source-zizhi-tongjian-tangji',
       '《資治通鑑》唐紀（卷203–210，武周–先天公历）',
       '司馬光',
       '维基文库录入本；年标题自带公元/西元',
       'https://zh.wikisource.org/wiki/資治通鑑',
       '公有领域编年史。武周至先天段公历年取年标题；改元同异年关系仍按旧唐书。reliability 不代表已走 verifySource。',
       'PENDING', 'OFFICIAL_HISTORY', 'HIGH'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_source WHERE id = 'source-zizhi-tongjian-tangji');

-- ---------- rulers (PERSON) ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, start_year, end_year, time_precision)
SELECT * FROM (
SELECT 'person-tang-ruler-gaozu' AS id, 'PERSON' AS entity_type, 'tang-ruler-gaozu' AS slug, '高祖' AS title, '唐朝帝王；本纪 卷1。' AS summary, 618 AS start_year, 626 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-taizong' AS id, 'PERSON' AS entity_type, 'tang-ruler-taizong' AS slug, '太宗' AS title, '唐朝帝王；本纪 卷2。' AS summary, 626 AS start_year, 649 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-gaozong' AS id, 'PERSON' AS entity_type, 'tang-ruler-gaozong' AS slug, '高宗' AS title, '唐朝帝王；本纪 卷4。' AS summary, 649 AS start_year, 683 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-zhongzong-1' AS id, 'PERSON' AS entity_type, 'tang-ruler-zhongzong-1' AS slug, '中宗' AS title, '唐朝帝王；本纪 卷7。第一次在位，即位当年被废。与前一位的年份边界见 claim 与 JSON boundary_before（未决）。' AS summary, 684 AS start_year, 684 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-ruizong-1' AS id, 'PERSON' AS entity_type, 'tang-ruler-ruizong-1' AS slug, '睿宗' AS title, '唐朝帝王；本纪 卷7。第一次在位，临朝称制的武后实际掌权。' AS summary, 684 AS start_year, 684 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-wuhou' AS id, 'PERSON' AS entity_type, 'tang-ruler-wuhou' AS slug, '武后' AS title, '唐朝帝王；本纪 卷6。690 年改国号为周，705 年中宗复位恢复唐。教育部表写作「（周）武后」。' AS summary, 684 AS start_year, 705 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-zhongzong-2' AS id, 'PERSON' AS entity_type, 'tang-ruler-zhongzong-2' AS slug, '中宗' AS title, '唐朝帝王；本纪 卷7。第二次在位。' AS summary, 705 AS start_year, 710 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-ruizong-2' AS id, 'PERSON' AS entity_type, 'tang-ruler-ruizong-2' AS slug, '睿宗' AS title, '唐朝帝王；本纪 卷7。第二次在位。教育部表写作「睿宗.」。' AS summary, 710 AS start_year, 712 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-xuanzong' AS id, 'PERSON' AS entity_type, 'tang-ruler-xuanzong' AS slug, '玄宗' AS title, '唐朝帝王；本纪 卷8。' AS summary, 712 AS start_year, 756 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-suzong' AS id, 'PERSON' AS entity_type, 'tang-ruler-suzong' AS slug, '肅宗' AS title, '唐朝帝王；本纪 卷10。' AS summary, 756 AS start_year, 762 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-daizong' AS id, 'PERSON' AS entity_type, 'tang-ruler-daizong' AS slug, '代宗' AS title, '唐朝帝王；本纪 卷11。' AS summary, 762 AS start_year, 779 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-dezong' AS id, 'PERSON' AS entity_type, 'tang-ruler-dezong' AS slug, '德宗' AS title, '唐朝帝王；本纪 卷12。' AS summary, 779 AS start_year, 805 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-shunzong' AS id, 'PERSON' AS entity_type, 'tang-ruler-shunzong' AS slug, '順宗' AS title, '唐朝帝王；本纪 卷14。' AS summary, 805 AS start_year, 805 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-xianzong' AS id, 'PERSON' AS entity_type, 'tang-ruler-xianzong' AS slug, '憲宗' AS title, '唐朝帝王；本纪 卷14。' AS summary, 805 AS start_year, 820 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-muzong' AS id, 'PERSON' AS entity_type, 'tang-ruler-muzong' AS slug, '穆宗' AS title, '唐朝帝王；本纪 卷16。' AS summary, 820 AS start_year, 824 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-jingzong' AS id, 'PERSON' AS entity_type, 'tang-ruler-jingzong' AS slug, '敬宗' AS title, '唐朝帝王；本纪 卷17上。' AS summary, 824 AS start_year, 826 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-wenzong' AS id, 'PERSON' AS entity_type, 'tang-ruler-wenzong' AS slug, '文宗' AS title, '唐朝帝王；本纪 卷17上。教育部表写作「文帝」。' AS summary, 826 AS start_year, 840 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-wuzong' AS id, 'PERSON' AS entity_type, 'tang-ruler-wuzong' AS slug, '武宗' AS title, '唐朝帝王；本纪 卷18上。教育部表写作「武帝」。' AS summary, 840 AS start_year, 846 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-xuanzong-xuan' AS id, 'PERSON' AS entity_type, 'tang-ruler-xuanzong-xuan' AS slug, '宣宗' AS title, '唐朝帝王；本纪 卷18下。教育部表写作「宣帝」。' AS summary, 846 AS start_year, 859 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-yizong' AS id, 'PERSON' AS entity_type, 'tang-ruler-yizong' AS slug, '懿宗' AS title, '唐朝帝王；本纪 卷19上。' AS summary, 859 AS start_year, 873 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-xizong' AS id, 'PERSON' AS entity_type, 'tang-ruler-xizong' AS slug, '僖宗' AS title, '唐朝帝王；本纪 卷19下。' AS summary, 873 AS start_year, 888 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-zhaozong' AS id, 'PERSON' AS entity_type, 'tang-ruler-zhaozong' AS slug, '昭宗' AS title, '唐朝帝王；本纪 卷20上。' AS summary, 888 AS start_year, 904 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-aidi' AS id, 'PERSON' AS entity_type, 'tang-ruler-aidi' AS slug, '哀帝' AS title, '唐朝帝王；本纪 卷20下。' AS summary, 904 AS start_year, 907 AS end_year, 'RANGE' AS time_precision FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_content c WHERE c.id = t.id);

INSERT INTO poetry_person (id, dynasty_id, courtesy_name)
SELECT * FROM (
SELECT 'person-tang-ruler-gaozu' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS courtesy_name FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-taizong' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS courtesy_name FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-gaozong' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS courtesy_name FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-zhongzong-1' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS courtesy_name FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-ruizong-1' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS courtesy_name FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-wuhou' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS courtesy_name FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-zhongzong-2' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS courtesy_name FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-ruizong-2' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS courtesy_name FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-xuanzong' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS courtesy_name FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-suzong' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS courtesy_name FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-daizong' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS courtesy_name FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-dezong' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS courtesy_name FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-shunzong' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS courtesy_name FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-xianzong' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS courtesy_name FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-muzong' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS courtesy_name FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-jingzong' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS courtesy_name FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-wenzong' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS courtesy_name FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-wuzong' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS courtesy_name FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-xuanzong-xuan' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS courtesy_name FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-yizong' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS courtesy_name FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-xizong' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS courtesy_name FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-zhaozong' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS courtesy_name FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-aidi' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS courtesy_name FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_person p WHERE p.id = t.id);

INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-person-tang-ruler-gaozu-time' AS id, 'person-tang-ruler-gaozu' AS subject_id, 'time.span' AS property_key, '618..626 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-taizong-time' AS id, 'person-tang-ruler-taizong' AS subject_id, 'time.span' AS property_key, '626..649 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-gaozong-time' AS id, 'person-tang-ruler-gaozong' AS subject_id, 'time.span' AS property_key, '649..683 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-zhongzong-1-time' AS id, 'person-tang-ruler-zhongzong-1' AS subject_id, 'time.span' AS property_key, '684..684 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-ruizong-1-time' AS id, 'person-tang-ruler-ruizong-1' AS subject_id, 'time.span' AS property_key, '684..684 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-wuhou-time' AS id, 'person-tang-ruler-wuhou' AS subject_id, 'time.span' AS property_key, '684..705 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-zhongzong-2-time' AS id, 'person-tang-ruler-zhongzong-2' AS subject_id, 'time.span' AS property_key, '705..710 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-ruizong-2-time' AS id, 'person-tang-ruler-ruizong-2' AS subject_id, 'time.span' AS property_key, '710..712 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-xuanzong-time' AS id, 'person-tang-ruler-xuanzong' AS subject_id, 'time.span' AS property_key, '712..756 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-suzong-time' AS id, 'person-tang-ruler-suzong' AS subject_id, 'time.span' AS property_key, '756..762 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-daizong-time' AS id, 'person-tang-ruler-daizong' AS subject_id, 'time.span' AS property_key, '762..779 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-dezong-time' AS id, 'person-tang-ruler-dezong' AS subject_id, 'time.span' AS property_key, '779..805 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-shunzong-time' AS id, 'person-tang-ruler-shunzong' AS subject_id, 'time.span' AS property_key, '805..805 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-xianzong-time' AS id, 'person-tang-ruler-xianzong' AS subject_id, 'time.span' AS property_key, '805..820 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-muzong-time' AS id, 'person-tang-ruler-muzong' AS subject_id, 'time.span' AS property_key, '820..824 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-jingzong-time' AS id, 'person-tang-ruler-jingzong' AS subject_id, 'time.span' AS property_key, '824..826 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-wenzong-time' AS id, 'person-tang-ruler-wenzong' AS subject_id, 'time.span' AS property_key, '826..840 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-wuzong-time' AS id, 'person-tang-ruler-wuzong' AS subject_id, 'time.span' AS property_key, '840..846 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-xuanzong-xuan-time' AS id, 'person-tang-ruler-xuanzong-xuan' AS subject_id, 'time.span' AS property_key, '846..859 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-yizong-time' AS id, 'person-tang-ruler-yizong' AS subject_id, 'time.span' AS property_key, '859..873 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-xizong-time' AS id, 'person-tang-ruler-xizong' AS subject_id, 'time.span' AS property_key, '873..888 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-zhaozong-time' AS id, 'person-tang-ruler-zhaozong' AS subject_id, 'time.span' AS property_key, '888..904 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-aidi-time' AS id, 'person-tang-ruler-aidi' AS subject_id, 'time.span' AS property_key, '904..907 (RANGE)' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_claim c WHERE c.id = t.id);

INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'person-tang-ruler-gaozu' AS subject_id, 'time.span' AS property_key, 'claim-person-tang-ruler-gaozu-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-taizong' AS subject_id, 'time.span' AS property_key, 'claim-person-tang-ruler-taizong-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-gaozong' AS subject_id, 'time.span' AS property_key, 'claim-person-tang-ruler-gaozong-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-zhongzong-1' AS subject_id, 'time.span' AS property_key, 'claim-person-tang-ruler-zhongzong-1-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-ruizong-1' AS subject_id, 'time.span' AS property_key, 'claim-person-tang-ruler-ruizong-1-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-wuhou' AS subject_id, 'time.span' AS property_key, 'claim-person-tang-ruler-wuhou-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-zhongzong-2' AS subject_id, 'time.span' AS property_key, 'claim-person-tang-ruler-zhongzong-2-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-ruizong-2' AS subject_id, 'time.span' AS property_key, 'claim-person-tang-ruler-ruizong-2-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-xuanzong' AS subject_id, 'time.span' AS property_key, 'claim-person-tang-ruler-xuanzong-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-suzong' AS subject_id, 'time.span' AS property_key, 'claim-person-tang-ruler-suzong-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-daizong' AS subject_id, 'time.span' AS property_key, 'claim-person-tang-ruler-daizong-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-dezong' AS subject_id, 'time.span' AS property_key, 'claim-person-tang-ruler-dezong-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-shunzong' AS subject_id, 'time.span' AS property_key, 'claim-person-tang-ruler-shunzong-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-xianzong' AS subject_id, 'time.span' AS property_key, 'claim-person-tang-ruler-xianzong-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-muzong' AS subject_id, 'time.span' AS property_key, 'claim-person-tang-ruler-muzong-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-jingzong' AS subject_id, 'time.span' AS property_key, 'claim-person-tang-ruler-jingzong-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-wenzong' AS subject_id, 'time.span' AS property_key, 'claim-person-tang-ruler-wenzong-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-wuzong' AS subject_id, 'time.span' AS property_key, 'claim-person-tang-ruler-wuzong-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-xuanzong-xuan' AS subject_id, 'time.span' AS property_key, 'claim-person-tang-ruler-xuanzong-xuan-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-yizong' AS subject_id, 'time.span' AS property_key, 'claim-person-tang-ruler-yizong-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-xizong' AS subject_id, 'time.span' AS property_key, 'claim-person-tang-ruler-xizong-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-zhaozong' AS subject_id, 'time.span' AS property_key, 'claim-person-tang-ruler-zhaozong-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'person-tang-ruler-aidi' AS subject_id, 'time.span' AS property_key, 'claim-person-tang-ruler-aidi-time' AS claim_id FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection s WHERE s.subject_id = t.subject_id AND s.property_key = t.property_key);

INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-person-tang-ruler-gaozu-time' AS claim_id, 'source-moe-rulers-table' AS source_id, '歷代帝王在位年表·唐·高祖；本纪定位 卷1' AS locator, '高祖 即位元年 618，退位末年 626' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-taizong-time' AS claim_id, 'source-moe-rulers-table' AS source_id, '歷代帝王在位年表·唐·太宗；本纪定位 卷2' AS locator, '太宗 即位元年 626，退位末年 649' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-gaozong-time' AS claim_id, 'source-moe-rulers-table' AS source_id, '歷代帝王在位年表·唐·高宗；本纪定位 卷4' AS locator, '高宗 即位元年 649，退位末年 683' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-zhongzong-1-time' AS claim_id, 'source-moe-rulers-table' AS source_id, '歷代帝王在位年表·唐·中宗；本纪定位 卷7' AS locator, '中宗 即位元年 684，退位末年 684' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-ruizong-1-time' AS claim_id, 'source-moe-rulers-table' AS source_id, '歷代帝王在位年表·唐·睿宗；本纪定位 卷7' AS locator, '睿宗 即位元年 684，退位末年 684' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-wuhou-time' AS claim_id, 'source-moe-rulers-table' AS source_id, '歷代帝王在位年表·唐·武后；本纪定位 卷6' AS locator, '武后 即位元年 684，退位末年 705（表内名 （周）武后）' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-zhongzong-2-time' AS claim_id, 'source-moe-rulers-table' AS source_id, '歷代帝王在位年表·唐·中宗；本纪定位 卷7' AS locator, '中宗 即位元年 705，退位末年 710' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-ruizong-2-time' AS claim_id, 'source-moe-rulers-table' AS source_id, '歷代帝王在位年表·唐·睿宗；本纪定位 卷7' AS locator, '睿宗 即位元年 710，退位末年 712（表内名 睿宗.）' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-xuanzong-time' AS claim_id, 'source-moe-rulers-table' AS source_id, '歷代帝王在位年表·唐·玄宗；本纪定位 卷8' AS locator, '玄宗 即位元年 712，退位末年 756' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-suzong-time' AS claim_id, 'source-moe-rulers-table' AS source_id, '歷代帝王在位年表·唐·肅宗；本纪定位 卷10' AS locator, '肅宗 即位元年 756，退位末年 762' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-daizong-time' AS claim_id, 'source-moe-rulers-table' AS source_id, '歷代帝王在位年表·唐·代宗；本纪定位 卷11' AS locator, '代宗 即位元年 762，退位末年 779' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-dezong-time' AS claim_id, 'source-moe-rulers-table' AS source_id, '歷代帝王在位年表·唐·德宗；本纪定位 卷12' AS locator, '德宗 即位元年 779，退位末年 805' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-shunzong-time' AS claim_id, 'source-moe-rulers-table' AS source_id, '歷代帝王在位年表·唐·順宗；本纪定位 卷14' AS locator, '順宗 即位元年 805，退位末年 805' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-xianzong-time' AS claim_id, 'source-moe-rulers-table' AS source_id, '歷代帝王在位年表·唐·憲宗；本纪定位 卷14' AS locator, '憲宗 即位元年 805，退位末年 820' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-muzong-time' AS claim_id, 'source-moe-rulers-table' AS source_id, '歷代帝王在位年表·唐·穆宗；本纪定位 卷16' AS locator, '穆宗 即位元年 820，退位末年 824' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-jingzong-time' AS claim_id, 'source-moe-rulers-table' AS source_id, '歷代帝王在位年表·唐·敬宗；本纪定位 卷17上' AS locator, '敬宗 即位元年 824，退位末年 826' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-wenzong-time' AS claim_id, 'source-moe-rulers-table' AS source_id, '歷代帝王在位年表·唐·文宗；本纪定位 卷17上' AS locator, '文宗 即位元年 826，退位末年 840（表内名 文帝）' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-wuzong-time' AS claim_id, 'source-moe-rulers-table' AS source_id, '歷代帝王在位年表·唐·武宗；本纪定位 卷18上' AS locator, '武宗 即位元年 840，退位末年 846（表内名 武帝）' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-xuanzong-xuan-time' AS claim_id, 'source-moe-rulers-table' AS source_id, '歷代帝王在位年表·唐·宣宗；本纪定位 卷18下' AS locator, '宣宗 即位元年 846，退位末年 859（表内名 宣帝）' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-yizong-time' AS claim_id, 'source-moe-rulers-table' AS source_id, '歷代帝王在位年表·唐·懿宗；本纪定位 卷19上' AS locator, '懿宗 即位元年 859，退位末年 873' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-xizong-time' AS claim_id, 'source-moe-rulers-table' AS source_id, '歷代帝王在位年表·唐·僖宗；本纪定位 卷19下' AS locator, '僖宗 即位元年 873，退位末年 888' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-zhaozong-time' AS claim_id, 'source-moe-rulers-table' AS source_id, '歷代帝王在位年表·唐·昭宗；本纪定位 卷20上' AS locator, '昭宗 即位元年 888，退位末年 904' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-person-tang-ruler-aidi-time' AS claim_id, 'source-moe-rulers-table' AS source_id, '歷代帝王在位年表·唐·哀帝；本纪定位 卷20下' AS locator, '哀帝 即位元年 904，退位末年 907' AS evidence_excerpt FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_citation c WHERE c.claim_id = t.claim_id AND c.source_id = t.source_id);

-- ---------- eras (PERIOD) ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, start_year, end_year, time_precision)
SELECT * FROM (
SELECT 'period-tang-era-wude' AS id, 'PERIOD' AS entity_type, 'era-wude' AS slug, '武德' AS title, '唐朝年号；本纪 卷1；置信 anchor-chain。' AS summary, 618 AS start_year, 626 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-zhenguan' AS id, 'PERIOD' AS entity_type, 'era-zhenguan' AS slug, '貞觀' AS title, '唐朝年号；本纪 卷2、卷3；置信 anchor-chain。' AS summary, 627 AS start_year, 649 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-yonghui' AS id, 'PERIOD' AS entity_type, 'era-yonghui' AS slug, '永徽' AS title, '唐朝年号；本纪 卷4；置信 anchor-chain。' AS summary, 650 AS start_year, 655 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-xianqing' AS id, 'PERIOD' AS entity_type, 'era-xianqing' AS slug, '顯慶' AS title, '唐朝年号；本纪 卷4；置信 anchor-chain。' AS summary, 656 AS start_year, 660 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-longshuo' AS id, 'PERIOD' AS entity_type, 'era-longshuo' AS slug, '龍朔' AS title, '唐朝年号；本纪 卷4；置信 anchor-chain。' AS summary, 661 AS start_year, 663 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-linde' AS id, 'PERIOD' AS entity_type, 'era-linde' AS slug, '麟德' AS title, '唐朝年号；本纪 卷4；置信 derived-low。' AS summary, 664 AS start_year, 665 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-qianfeng' AS id, 'PERIOD' AS entity_type, 'era-qianfeng' AS slug, '乾封' AS title, '唐朝年号；本纪 卷5；置信 derived-low。' AS summary, 666 AS start_year, 667 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-zongzhang' AS id, 'PERIOD' AS entity_type, 'era-zongzhang' AS slug, '總章' AS title, '唐朝年号；本纪 卷5；置信 anchor-chain。' AS summary, 668 AS start_year, 669 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-xianheng' AS id, 'PERIOD' AS entity_type, 'era-xianheng' AS slug, '咸亨' AS title, '唐朝年号；本纪 卷5；置信 anchor-chain。' AS summary, 670 AS start_year, 673 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-shangyuan-gaozong' AS id, 'PERIOD' AS entity_type, 'era-shangyuan-gaozong' AS slug, '上元（高宗）' AS title, '唐朝年号；本纪 卷5；置信 derived-low。' AS summary, 674 AS start_year, 675 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-yifeng' AS id, 'PERIOD' AS entity_type, 'era-yifeng' AS slug, '儀鳳' AS title, '唐朝年号；本纪 卷5；置信 derived-low。' AS summary, 676 AS start_year, 678 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-tiaolu' AS id, 'PERIOD' AS entity_type, 'era-tiaolu' AS slug, '調露' AS title, '唐朝年号；本纪 卷5；置信 derived-low。' AS summary, 679 AS start_year, 679 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-yonglong' AS id, 'PERIOD' AS entity_type, 'era-yonglong' AS slug, '永隆' AS title, '唐朝年号；本纪 卷5；置信 derived-low。' AS summary, 680 AS start_year, 680 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-kaiyao' AS id, 'PERIOD' AS entity_type, 'era-kaiyao' AS slug, '開耀' AS title, '唐朝年号；本纪 卷5；置信 derived-low。' AS summary, 681 AS start_year, 681 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-yongchun' AS id, 'PERIOD' AS entity_type, 'era-yongchun' AS slug, '永淳' AS title, '唐朝年号；本纪 卷5；置信 derived-low。' AS summary, 682 AS start_year, 682 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-hongdao' AS id, 'PERIOD' AS entity_type, 'era-hongdao' AS slug, '弘道' AS title, '唐朝年号；本纪 卷5、卷6；置信 anchor-chain。卷6：『弘道元年十二月丁巳，大帝崩，皇太子顯即位』。与 tang-rulers 中宗 684 的缺口见该文件 boundary_before。' AS summary, 683 AS start_year, 683 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-sisheng' AS id, 'PERIOD' AS entity_type, 'era-sisheng' AS slug, '嗣聖' AS title, '唐朝年号；本纪 卷6、卷7；置信 tongjian-ce。与文明、光宅同一公历年。通鉴将该年标题作光宅元年（公元六八四年）。' AS summary, 684 AS start_year, 684 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-wenming' AS id, 'PERIOD' AS entity_type, 'era-wenming' AS slug, '文明' AS title, '唐朝年号；本纪 卷6；置信 tongjian-ce。中宗被废、睿宗即位当年；九月再改光宅。' AS summary, 684 AS start_year, 684 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-guangzhai' AS id, 'PERIOD' AS entity_type, 'era-guangzhai' AS slug, '光宅' AS title, '唐朝年号；本纪 卷6；置信 tongjian-ce。' AS summary, 684 AS start_year, 684 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-chuigong' AS id, 'PERIOD' AS entity_type, 'era-chuigong' AS slug, '垂拱' AS title, '唐朝年号；本纪 卷6；置信 tongjian-ce。' AS summary, 685 AS start_year, 688 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-yongchang' AS id, 'PERIOD' AS entity_type, 'era-yongchang' AS slug, '永昌' AS title, '唐朝年号；本纪 卷6；置信 tongjian-ce。' AS summary, 689 AS start_year, 689 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-zaichu' AS id, 'PERIOD' AS entity_type, 'era-zaichu' AS slug, '載初' AS title, '唐朝年号；本纪 卷6；置信 tongjian-ce。周正建子：载初与天授同一公历年（690）。九月改国号周、改元天授。' AS summary, 690 AS start_year, 690 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-tianshou' AS id, 'PERIOD' AS entity_type, 'era-tianshou' AS slug, '天授' AS title, '唐朝年号；本纪 卷6；置信 tongjian-ce。天授三年与如意/长寿元年同一公历年692。' AS summary, 690 AS start_year, 692 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-ruyi' AS id, 'PERIOD' AS entity_type, 'era-ruyi' AS slug, '如意' AS title, '唐朝年号；本纪 卷6；置信 tongjian-ce。' AS summary, 692 AS start_year, 692 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-changshou' AS id, 'PERIOD' AS entity_type, 'era-changshou' AS slug, '長壽' AS title, '唐朝年号；本纪 卷6；置信 tongjian-ce。' AS summary, 692 AS start_year, 693 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-yanzai' AS id, 'PERIOD' AS entity_type, 'era-yanzai' AS slug, '延載' AS title, '唐朝年号；本纪 卷6；置信 tongjian-ce。' AS summary, 694 AS start_year, 694 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-zhengsheng' AS id, 'PERIOD' AS entity_type, 'era-zhengsheng' AS slug, '證聖' AS title, '唐朝年号；本纪 卷6；置信 tongjian-ce。' AS summary, 695 AS start_year, 695 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-tiancewansui' AS id, 'PERIOD' AS entity_type, 'era-tiancewansui' AS slug, '天冊萬歲' AS title, '唐朝年号；本纪 卷6；置信 tongjian-ce。' AS summary, 695 AS start_year, 695 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-wansuidengfeng' AS id, 'PERIOD' AS entity_type, 'era-wansuidengfeng' AS slug, '萬歲登封' AS title, '唐朝年号；本纪 卷6；置信 tongjian-ce。腊月登封改元；同年夏四月改万岁通天。与万岁通天同一公历年。' AS summary, 696 AS start_year, 696 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-wansuitongtian' AS id, 'PERIOD' AS entity_type, 'era-wansuitongtian' AS slug, '萬歲通天' AS title, '唐朝年号；本纪 卷6；置信 tongjian-ce。' AS summary, 696 AS start_year, 697 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-shengong' AS id, 'PERIOD' AS entity_type, 'era-shengong' AS slug, '神功' AS title, '唐朝年号；本纪 卷6；置信 tongjian-ce。' AS summary, 697 AS start_year, 697 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-shengli' AS id, 'PERIOD' AS entity_type, 'era-shengli' AS slug, '聖歷' AS title, '唐朝年号；本纪 卷6；置信 tongjian-ce。' AS summary, 698 AS start_year, 700 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-jiushi' AS id, 'PERIOD' AS entity_type, 'era-jiushi' AS slug, '久視' AS title, '唐朝年号；本纪 卷6；置信 tongjian-ce。' AS summary, 700 AS start_year, 700 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-dazu' AS id, 'PERIOD' AS entity_type, 'era-dazu' AS slug, '大足' AS title, '唐朝年号；本纪 卷6；置信 tongjian-ce。' AS summary, 701 AS start_year, 701 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-changan' AS id, 'PERIOD' AS entity_type, 'era-changan' AS slug, '長安' AS title, '唐朝年号；本纪 卷6；置信 tongjian-ce。' AS summary, 701 AS start_year, 704 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-shenlong' AS id, 'PERIOD' AS entity_type, 'era-shenlong' AS slug, '神龍' AS title, '唐朝年号；本纪 卷6、卷7；置信 tongjian-ce。正月中宗复位。神龙三年与景龙元年同一公历年707。' AS summary, 705 AS start_year, 707 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-jinglong' AS id, 'PERIOD' AS entity_type, 'era-jinglong' AS slug, '景龍' AS title, '唐朝年号；本纪 卷7；置信 tongjian-ce。' AS summary, 707 AS start_year, 710 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-tanglong' AS id, 'PERIOD' AS entity_type, 'era-tanglong' AS slug, '唐隆' AS title, '唐朝年号；本纪 卷7；置信 tongjian-ce。中宗崩后韦后临朝所用；旋改景云。与景云元年同一公历年。' AS summary, 710 AS start_year, 710 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-jingyun' AS id, 'PERIOD' AS entity_type, 'era-jingyun' AS slug, '景雲' AS title, '唐朝年号；本纪 卷7；置信 tongjian-ce。' AS summary, 710 AS start_year, 712 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-taiji' AS id, 'PERIOD' AS entity_type, 'era-taiji' AS slug, '太極' AS title, '唐朝年号；本纪 卷7；置信 tongjian-ce。' AS summary, 712 AS start_year, 712 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-yanhe' AS id, 'PERIOD' AS entity_type, 'era-yanhe' AS slug, '延和' AS title, '唐朝年号；本纪 卷7；置信 tongjian-ce。' AS summary, 712 AS start_year, 712 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-xiantian' AS id, 'PERIOD' AS entity_type, 'era-xiantian' AS slug, '先天' AS title, '唐朝年号；本纪 卷7、卷8；置信 tongjian-ce。先天二年十二月改开元，与开元元年同一公历年713。' AS summary, 712 AS start_year, 713 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-kaiyuan' AS id, 'PERIOD' AS entity_type, 'era-kaiyuan' AS slug, '開元' AS title, '唐朝年号；本纪 卷8、卷9；置信 anchor-chain。开元元年=713 与通鉴年标题及先天二年十二月改元一致；并由天寶元年=742 回推：开元二十九年=741。' AS summary, 713 AS start_year, 741 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-tianbao' AS id, 'PERIOD' AS entity_type, 'era-tianbao' AS slug, '天寶' AS title, '唐朝年号；本纪 卷9；置信 anchor。' AS summary, 742 AS start_year, 756 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-zhide' AS id, 'PERIOD' AS entity_type, 'era-zhide' AS slug, '至德' AS title, '唐朝年号；本纪 卷10；置信 anchor。与天宝十五载同一公历年（七月改元曰至德）。锚点直接写入，不靠『是否等于上一年号末年』的推断。' AS summary, 756 AS start_year, 757 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-qianyuan' AS id, 'PERIOD' AS entity_type, 'era-qianyuan' AS slug, '乾元' AS title, '唐朝年号；本纪 卷10；置信 tongjian-ce。' AS summary, 758 AS start_year, 759 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-shangyuan-suzong' AS id, 'PERIOD' AS entity_type, 'era-shangyuan-suzong' AS slug, '上元（肃宗）' AS title, '唐朝年号；本纪 卷10；置信 tongjian-ce。' AS summary, 760 AS start_year, 761 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-baoying' AS id, 'PERIOD' AS entity_type, 'era-baoying' AS slug, '寶應' AS title, '唐朝年号；本纪 卷10、卷11；置信 tongjian-ce。通鉴宝应元年=762。旧唐书卷11广德元年节：宝应二年秋七月改元曰广德，故宝应二年与广德元年同一公历年763。' AS summary, 762 AS start_year, 763 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-guangde' AS id, 'PERIOD' AS entity_type, 'era-guangde' AS slug, '廣德' AS title, '唐朝年号；本纪 卷11；置信 tongjian-ce。' AS summary, 763 AS start_year, 764 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-yongtai' AS id, 'PERIOD' AS entity_type, 'era-yongtai' AS slug, '永泰' AS title, '唐朝年号；本纪 卷11；置信 tongjian-ce。' AS summary, 765 AS start_year, 765 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-dali' AS id, 'PERIOD' AS entity_type, 'era-dali' AS slug, '大歷' AS title, '唐朝年号；本纪 卷11、卷12；置信 tongjian-ce。旧唐书作大歷，通鉴多作大曆；公历取通鉴。' AS summary, 766 AS start_year, 779 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-jianzhong' AS id, 'PERIOD' AS entity_type, 'era-jianzhong' AS slug, '建中' AS title, '唐朝年号；本纪 卷12；置信 tongjian-ce。' AS summary, 780 AS start_year, 783 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-xingyuan' AS id, 'PERIOD' AS entity_type, 'era-xingyuan' AS slug, '興元' AS title, '唐朝年号；本纪 卷12；置信 tongjian-ce。' AS summary, 784 AS start_year, 784 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-zhenyuan' AS id, 'PERIOD' AS entity_type, 'era-zhenyuan' AS slug, '貞元' AS title, '唐朝年号；本纪 卷12、卷13、卷14；置信 tongjian-ce。贞元二十一年=805，同年八月改永贞。max_n=21 含与永贞重叠之年。' AS summary, 785 AS start_year, 805 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-yongzhen' AS id, 'PERIOD' AS entity_type, 'era-yongzhen' AS slug, '永貞' AS title, '唐朝年号；本纪 卷14；置信 tongjian-ce。' AS summary, 805 AS start_year, 805 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-yuanhe' AS id, 'PERIOD' AS entity_type, 'era-yuanhe' AS slug, '元和' AS title, '唐朝年号；本纪 卷14、卷15、卷16；置信 tongjian-ce。通鉴卷面缺元和元–三年标题，由四年=809与永贞=805相邻回推。' AS summary, 806 AS start_year, 820 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-changqing' AS id, 'PERIOD' AS entity_type, 'era-changqing' AS slug, '長慶' AS title, '唐朝年号；本纪 卷16、卷17上；置信 tongjian-ce。' AS summary, 821 AS start_year, 824 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-baoli' AS id, 'PERIOD' AS entity_type, 'era-baoli' AS slug, '寶曆' AS title, '唐朝年号；本纪 卷17上；置信 tongjian-ce。' AS summary, 825 AS start_year, 826 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-daihe' AS id, 'PERIOD' AS entity_type, 'era-daihe' AS slug, '大和' AS title, '唐朝年号；本纪 卷17上、卷17下；置信 tongjian-ce。通鉴写作太和；旧唐书节题作大和。中间三年至七年标题在已取卷中缺失，按年序补公历。' AS summary, 827 AS start_year, 835 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-kaicheng' AS id, 'PERIOD' AS entity_type, 'era-kaicheng' AS slug, '開成' AS title, '唐朝年号；本纪 卷17下、卷18上；置信 tongjian-ce。' AS summary, 836 AS start_year, 840 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-huichang' AS id, 'PERIOD' AS entity_type, 'era-huichang' AS slug, '會昌' AS title, '唐朝年号；本纪 卷18上；置信 tongjian-ce。' AS summary, 841 AS start_year, 846 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-dazhong' AS id, 'PERIOD' AS entity_type, 'era-dazhong' AS slug, '大中' AS title, '唐朝年号；本纪 卷18下、卷19上；置信 tongjian-ce。' AS summary, 847 AS start_year, 859 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-xiantong' AS id, 'PERIOD' AS entity_type, 'era-xiantong' AS slug, '咸通' AS title, '唐朝年号；本纪 卷19上、卷19下；置信 tongjian-ce。' AS summary, 860 AS start_year, 873 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-qianfu' AS id, 'PERIOD' AS entity_type, 'era-qianfu' AS slug, '乾符' AS title, '唐朝年号；本纪 卷19下；置信 tongjian-ce。' AS summary, 874 AS start_year, 879 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-guangming' AS id, 'PERIOD' AS entity_type, 'era-guangming' AS slug, '廣明' AS title, '唐朝年号；本纪 卷19下；置信 tongjian-ce。' AS summary, 880 AS start_year, 880 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-zhonghe' AS id, 'PERIOD' AS entity_type, 'era-zhonghe' AS slug, '中和' AS title, '唐朝年号；本纪 卷19下；置信 tongjian-ce。' AS summary, 881 AS start_year, 884 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-guangqi' AS id, 'PERIOD' AS entity_type, 'era-guangqi' AS slug, '光啟' AS title, '唐朝年号；本纪 卷19下；置信 tongjian-ce。' AS summary, 885 AS start_year, 887 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-wende' AS id, 'PERIOD' AS entity_type, 'era-wende' AS slug, '文德' AS title, '唐朝年号；本纪 卷19下、卷20上；置信 tongjian-ce。' AS summary, 888 AS start_year, 888 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-longji' AS id, 'PERIOD' AS entity_type, 'era-longji' AS slug, '龍紀' AS title, '唐朝年号；本纪 卷20上；置信 tongjian-ce。' AS summary, 889 AS start_year, 889 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-dashun' AS id, 'PERIOD' AS entity_type, 'era-dashun' AS slug, '大順' AS title, '唐朝年号；本纪 卷20上；置信 tongjian-ce。' AS summary, 890 AS start_year, 891 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-jingfu' AS id, 'PERIOD' AS entity_type, 'era-jingfu' AS slug, '景福' AS title, '唐朝年号；本纪 卷20上；置信 tongjian-ce。' AS summary, 892 AS start_year, 893 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-qianning' AS id, 'PERIOD' AS entity_type, 'era-qianning' AS slug, '乾寧' AS title, '唐朝年号；本纪 卷20上；置信 tongjian-ce。光化元年八月改元；乾宁五年=光化元年。' AS summary, 894 AS start_year, 898 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-guanghua' AS id, 'PERIOD' AS entity_type, 'era-guanghua' AS slug, '光化' AS title, '唐朝年号；本纪 卷20上；置信 tongjian-ce。与乾宁五年同一公历年。通鉴光化元年=898至三年=900。' AS summary, 898 AS start_year, 900 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-tianfu' AS id, 'PERIOD' AS entity_type, 'era-tianfu' AS slug, '天復' AS title, '唐朝年号；本纪 卷20上；置信 tongjian-ce。' AS summary, 901 AS start_year, 903 AS end_year, 'RANGE' AS time_precision FROM DUAL
UNION ALL
SELECT 'period-tang-era-tianyou' AS id, 'PERIOD' AS entity_type, 'era-tianyou' AS slug, '天祐' AS title, '唐朝年号；本纪 卷20上、卷20下；置信 anchor。天祐元年=904、四年=907 已在 V013 核过。哀帝用天祐年号至禅位。' AS summary, 904 AS start_year, 907 AS end_year, 'RANGE' AS time_precision FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_content c WHERE c.id = t.id);

INSERT INTO poetry_period (id, dynasty_id, parent_id)
SELECT * FROM (
SELECT 'period-tang-era-wude' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-zhenguan' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-yonghui' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-xianqing' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-longshuo' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-linde' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-qianfeng' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-zongzhang' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-xianheng' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-shangyuan-gaozong' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-yifeng' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-tiaolu' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-yonglong' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-kaiyao' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-yongchun' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-hongdao' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-sisheng' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-wenming' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-guangzhai' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-chuigong' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-yongchang' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-zaichu' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-tianshou' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-ruyi' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-changshou' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-yanzai' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-zhengsheng' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-tiancewansui' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-wansuidengfeng' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-wansuitongtian' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-shengong' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-shengli' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-jiushi' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-dazu' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-changan' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-shenlong' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-jinglong' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-tanglong' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-jingyun' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-taiji' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-yanhe' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-xiantian' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-kaiyuan' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-tianbao' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-zhide' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-qianyuan' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-shangyuan-suzong' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-baoying' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-guangde' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-yongtai' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-dali' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-jianzhong' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-xingyuan' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-zhenyuan' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-yongzhen' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-yuanhe' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-changqing' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-baoli' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-daihe' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-kaicheng' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-huichang' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-dazhong' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-xiantong' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-qianfu' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-guangming' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-zhonghe' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-guangqi' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-wende' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-longji' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-dashun' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-jingfu' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-qianning' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-guanghua' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-tianfu' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-tianyou' AS id, 'dynasty-tang' AS dynasty_id, CAST(NULL AS CHAR) AS parent_id FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_period p WHERE p.id = t.id);

INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-period-tang-era-wude-time' AS id, 'period-tang-era-wude' AS subject_id, 'time.span' AS property_key, '618..626 (RANGE) max_n=9' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-zhenguan-time' AS id, 'period-tang-era-zhenguan' AS subject_id, 'time.span' AS property_key, '627..649 (RANGE) max_n=23' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yonghui-time' AS id, 'period-tang-era-yonghui' AS subject_id, 'time.span' AS property_key, '650..655 (RANGE) max_n=6' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-xianqing-time' AS id, 'period-tang-era-xianqing' AS subject_id, 'time.span' AS property_key, '656..660 (RANGE) max_n=5' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-longshuo-time' AS id, 'period-tang-era-longshuo' AS subject_id, 'time.span' AS property_key, '661..663 (RANGE) max_n=3' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-linde-time' AS id, 'period-tang-era-linde' AS subject_id, 'time.span' AS property_key, '664..665 (RANGE) max_n=2' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-qianfeng-time' AS id, 'period-tang-era-qianfeng' AS subject_id, 'time.span' AS property_key, '666..667 (RANGE) max_n=2' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-zongzhang-time' AS id, 'period-tang-era-zongzhang' AS subject_id, 'time.span' AS property_key, '668..669 (RANGE) max_n=2' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-xianheng-time' AS id, 'period-tang-era-xianheng' AS subject_id, 'time.span' AS property_key, '670..673 (RANGE) max_n=4' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-shangyuan-gaozong-time' AS id, 'period-tang-era-shangyuan-gaozong' AS subject_id, 'time.span' AS property_key, '674..675 (RANGE) max_n=2' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yifeng-time' AS id, 'period-tang-era-yifeng' AS subject_id, 'time.span' AS property_key, '676..678 (RANGE) max_n=3' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-tiaolu-time' AS id, 'period-tang-era-tiaolu' AS subject_id, 'time.span' AS property_key, '679..679 (RANGE) max_n=1' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yonglong-time' AS id, 'period-tang-era-yonglong' AS subject_id, 'time.span' AS property_key, '680..680 (RANGE) max_n=1' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-kaiyao-time' AS id, 'period-tang-era-kaiyao' AS subject_id, 'time.span' AS property_key, '681..681 (RANGE) max_n=1' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yongchun-time' AS id, 'period-tang-era-yongchun' AS subject_id, 'time.span' AS property_key, '682..682 (RANGE) max_n=1' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-hongdao-time' AS id, 'period-tang-era-hongdao' AS subject_id, 'time.span' AS property_key, '683..683 (RANGE) max_n=1' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-sisheng-time' AS id, 'period-tang-era-sisheng' AS subject_id, 'time.span' AS property_key, '684..684 (RANGE) max_n=1' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-wenming-time' AS id, 'period-tang-era-wenming' AS subject_id, 'time.span' AS property_key, '684..684 (RANGE) max_n=1' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-guangzhai-time' AS id, 'period-tang-era-guangzhai' AS subject_id, 'time.span' AS property_key, '684..684 (RANGE) max_n=1' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-chuigong-time' AS id, 'period-tang-era-chuigong' AS subject_id, 'time.span' AS property_key, '685..688 (RANGE) max_n=4' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yongchang-time' AS id, 'period-tang-era-yongchang' AS subject_id, 'time.span' AS property_key, '689..689 (RANGE) max_n=1' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-zaichu-time' AS id, 'period-tang-era-zaichu' AS subject_id, 'time.span' AS property_key, '690..690 (RANGE) max_n=1' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-tianshou-time' AS id, 'period-tang-era-tianshou' AS subject_id, 'time.span' AS property_key, '690..692 (RANGE) max_n=3' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-ruyi-time' AS id, 'period-tang-era-ruyi' AS subject_id, 'time.span' AS property_key, '692..692 (RANGE) max_n=1' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-changshou-time' AS id, 'period-tang-era-changshou' AS subject_id, 'time.span' AS property_key, '692..693 (RANGE) max_n=2' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yanzai-time' AS id, 'period-tang-era-yanzai' AS subject_id, 'time.span' AS property_key, '694..694 (RANGE) max_n=1' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-zhengsheng-time' AS id, 'period-tang-era-zhengsheng' AS subject_id, 'time.span' AS property_key, '695..695 (RANGE) max_n=1' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-tiancewansui-time' AS id, 'period-tang-era-tiancewansui' AS subject_id, 'time.span' AS property_key, '695..695 (RANGE) max_n=1' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-wansuidengfeng-time' AS id, 'period-tang-era-wansuidengfeng' AS subject_id, 'time.span' AS property_key, '696..696 (RANGE) max_n=1' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-wansuitongtian-time' AS id, 'period-tang-era-wansuitongtian' AS subject_id, 'time.span' AS property_key, '696..697 (RANGE) max_n=2' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-shengong-time' AS id, 'period-tang-era-shengong' AS subject_id, 'time.span' AS property_key, '697..697 (RANGE) max_n=1' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-shengli-time' AS id, 'period-tang-era-shengli' AS subject_id, 'time.span' AS property_key, '698..700 (RANGE) max_n=3' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-jiushi-time' AS id, 'period-tang-era-jiushi' AS subject_id, 'time.span' AS property_key, '700..700 (RANGE) max_n=1' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-dazu-time' AS id, 'period-tang-era-dazu' AS subject_id, 'time.span' AS property_key, '701..701 (RANGE) max_n=1' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-changan-time' AS id, 'period-tang-era-changan' AS subject_id, 'time.span' AS property_key, '701..704 (RANGE) max_n=4' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-shenlong-time' AS id, 'period-tang-era-shenlong' AS subject_id, 'time.span' AS property_key, '705..707 (RANGE) max_n=3' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-jinglong-time' AS id, 'period-tang-era-jinglong' AS subject_id, 'time.span' AS property_key, '707..710 (RANGE) max_n=4' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-tanglong-time' AS id, 'period-tang-era-tanglong' AS subject_id, 'time.span' AS property_key, '710..710 (RANGE) max_n=1' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-jingyun-time' AS id, 'period-tang-era-jingyun' AS subject_id, 'time.span' AS property_key, '710..712 (RANGE) max_n=3' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-taiji-time' AS id, 'period-tang-era-taiji' AS subject_id, 'time.span' AS property_key, '712..712 (RANGE) max_n=1' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yanhe-time' AS id, 'period-tang-era-yanhe' AS subject_id, 'time.span' AS property_key, '712..712 (RANGE) max_n=1' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-xiantian-time' AS id, 'period-tang-era-xiantian' AS subject_id, 'time.span' AS property_key, '712..713 (RANGE) max_n=2' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-kaiyuan-time' AS id, 'period-tang-era-kaiyuan' AS subject_id, 'time.span' AS property_key, '713..741 (RANGE) max_n=29' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-tianbao-time' AS id, 'period-tang-era-tianbao' AS subject_id, 'time.span' AS property_key, '742..756 (RANGE) max_n=15' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-zhide-time' AS id, 'period-tang-era-zhide' AS subject_id, 'time.span' AS property_key, '756..757 (RANGE) max_n=2' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-qianyuan-time' AS id, 'period-tang-era-qianyuan' AS subject_id, 'time.span' AS property_key, '758..759 (RANGE) max_n=2' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-shangyuan-suzong-time' AS id, 'period-tang-era-shangyuan-suzong' AS subject_id, 'time.span' AS property_key, '760..761 (RANGE) max_n=2' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-baoying-time' AS id, 'period-tang-era-baoying' AS subject_id, 'time.span' AS property_key, '762..763 (RANGE) max_n=2' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-guangde-time' AS id, 'period-tang-era-guangde' AS subject_id, 'time.span' AS property_key, '763..764 (RANGE) max_n=2' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yongtai-time' AS id, 'period-tang-era-yongtai' AS subject_id, 'time.span' AS property_key, '765..765 (RANGE) max_n=1' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-dali-time' AS id, 'period-tang-era-dali' AS subject_id, 'time.span' AS property_key, '766..779 (RANGE) max_n=14' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-jianzhong-time' AS id, 'period-tang-era-jianzhong' AS subject_id, 'time.span' AS property_key, '780..783 (RANGE) max_n=4' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-xingyuan-time' AS id, 'period-tang-era-xingyuan' AS subject_id, 'time.span' AS property_key, '784..784 (RANGE) max_n=1' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-zhenyuan-time' AS id, 'period-tang-era-zhenyuan' AS subject_id, 'time.span' AS property_key, '785..805 (RANGE) max_n=21' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yongzhen-time' AS id, 'period-tang-era-yongzhen' AS subject_id, 'time.span' AS property_key, '805..805 (RANGE) max_n=1' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yuanhe-time' AS id, 'period-tang-era-yuanhe' AS subject_id, 'time.span' AS property_key, '806..820 (RANGE) max_n=15' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-changqing-time' AS id, 'period-tang-era-changqing' AS subject_id, 'time.span' AS property_key, '821..824 (RANGE) max_n=4' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-baoli-time' AS id, 'period-tang-era-baoli' AS subject_id, 'time.span' AS property_key, '825..826 (RANGE) max_n=2' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-daihe-time' AS id, 'period-tang-era-daihe' AS subject_id, 'time.span' AS property_key, '827..835 (RANGE) max_n=9' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-kaicheng-time' AS id, 'period-tang-era-kaicheng' AS subject_id, 'time.span' AS property_key, '836..840 (RANGE) max_n=5' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-huichang-time' AS id, 'period-tang-era-huichang' AS subject_id, 'time.span' AS property_key, '841..846 (RANGE) max_n=6' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-dazhong-time' AS id, 'period-tang-era-dazhong' AS subject_id, 'time.span' AS property_key, '847..859 (RANGE) max_n=13' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-xiantong-time' AS id, 'period-tang-era-xiantong' AS subject_id, 'time.span' AS property_key, '860..873 (RANGE) max_n=14' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-qianfu-time' AS id, 'period-tang-era-qianfu' AS subject_id, 'time.span' AS property_key, '874..879 (RANGE) max_n=6' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-guangming-time' AS id, 'period-tang-era-guangming' AS subject_id, 'time.span' AS property_key, '880..880 (RANGE) max_n=1' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-zhonghe-time' AS id, 'period-tang-era-zhonghe' AS subject_id, 'time.span' AS property_key, '881..884 (RANGE) max_n=4' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-guangqi-time' AS id, 'period-tang-era-guangqi' AS subject_id, 'time.span' AS property_key, '885..887 (RANGE) max_n=3' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-wende-time' AS id, 'period-tang-era-wende' AS subject_id, 'time.span' AS property_key, '888..888 (RANGE) max_n=1' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-longji-time' AS id, 'period-tang-era-longji' AS subject_id, 'time.span' AS property_key, '889..889 (RANGE) max_n=1' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-dashun-time' AS id, 'period-tang-era-dashun' AS subject_id, 'time.span' AS property_key, '890..891 (RANGE) max_n=2' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-jingfu-time' AS id, 'period-tang-era-jingfu' AS subject_id, 'time.span' AS property_key, '892..893 (RANGE) max_n=2' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-qianning-time' AS id, 'period-tang-era-qianning' AS subject_id, 'time.span' AS property_key, '894..898 (RANGE) max_n=5' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-guanghua-time' AS id, 'period-tang-era-guanghua' AS subject_id, 'time.span' AS property_key, '898..900 (RANGE) max_n=3' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-tianfu-time' AS id, 'period-tang-era-tianfu' AS subject_id, 'time.span' AS property_key, '901..903 (RANGE) max_n=3' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-tianyou-time' AS id, 'period-tang-era-tianyou' AS subject_id, 'time.span' AS property_key, '904..907 (RANGE) max_n=4' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_claim c WHERE c.id = t.id);

INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'period-tang-era-wude' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-wude-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-zhenguan' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-zhenguan-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-yonghui' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-yonghui-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-xianqing' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-xianqing-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-longshuo' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-longshuo-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-linde' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-linde-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-qianfeng' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-qianfeng-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-zongzhang' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-zongzhang-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-xianheng' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-xianheng-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-shangyuan-gaozong' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-shangyuan-gaozong-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-yifeng' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-yifeng-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-tiaolu' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-tiaolu-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-yonglong' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-yonglong-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-kaiyao' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-kaiyao-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-yongchun' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-yongchun-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-hongdao' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-hongdao-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-sisheng' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-sisheng-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-wenming' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-wenming-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-guangzhai' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-guangzhai-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-chuigong' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-chuigong-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-yongchang' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-yongchang-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-zaichu' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-zaichu-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-tianshou' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-tianshou-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-ruyi' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-ruyi-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-changshou' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-changshou-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-yanzai' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-yanzai-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-zhengsheng' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-zhengsheng-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-tiancewansui' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-tiancewansui-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-wansuidengfeng' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-wansuidengfeng-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-wansuitongtian' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-wansuitongtian-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-shengong' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-shengong-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-shengli' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-shengli-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-jiushi' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-jiushi-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-dazu' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-dazu-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-changan' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-changan-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-shenlong' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-shenlong-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-jinglong' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-jinglong-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-tanglong' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-tanglong-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-jingyun' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-jingyun-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-taiji' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-taiji-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-yanhe' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-yanhe-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-xiantian' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-xiantian-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-kaiyuan' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-kaiyuan-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-tianbao' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-tianbao-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-zhide' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-zhide-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-qianyuan' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-qianyuan-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-shangyuan-suzong' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-shangyuan-suzong-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-baoying' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-baoying-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-guangde' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-guangde-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-yongtai' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-yongtai-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-dali' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-dali-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-jianzhong' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-jianzhong-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-xingyuan' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-xingyuan-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-zhenyuan' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-zhenyuan-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-yongzhen' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-yongzhen-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-yuanhe' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-yuanhe-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-changqing' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-changqing-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-baoli' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-baoli-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-daihe' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-daihe-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-kaicheng' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-kaicheng-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-huichang' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-huichang-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-dazhong' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-dazhong-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-xiantong' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-xiantong-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-qianfu' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-qianfu-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-guangming' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-guangming-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-zhonghe' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-zhonghe-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-guangqi' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-guangqi-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-wende' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-wende-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-longji' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-longji-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-dashun' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-dashun-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-jingfu' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-jingfu-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-qianning' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-qianning-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-guanghua' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-guanghua-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-tianfu' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-tianfu-time' AS claim_id FROM DUAL
UNION ALL
SELECT 'period-tang-era-tianyou' AS subject_id, 'time.span' AS property_key, 'claim-period-tang-era-tianyou-time' AS claim_id FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection s WHERE s.subject_id = t.subject_id AND s.property_key = t.property_key);

INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-period-tang-era-wude-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷1·武德' AS locator, NULL AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-zhenguan-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷2、卷3·貞觀' AS locator, '正月改元（贞观元年节）' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yonghui-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷4·永徽' AS locator, '永徽元年春正月…詔改元' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-xianqing-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷4·顯慶' AS locator, '七年…改元為顯慶（永徽七年=显庆元年）' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-longshuo-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷4·龍朔' AS locator, '龍朔元年…改元（正月）' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-linde-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷4·麟德' AS locator, '无改元句，按明年默认；整段接到贞观二十三年=649 与弘道元年=683 两个已核锚' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-qianfeng-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷5·乾封' AS locator, '无改元句，按明年默认' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-zongzhang-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷5·總章' AS locator, '三年…改元為總章（乾封三年=总章元年）' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-xianheng-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷5·咸亨' AS locator, '三年…改元（总章三年=咸亨元年）' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-shangyuan-gaozong-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷5·上元（高宗）' AS locator, '无改元句，按明年默认' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yifeng-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷5·儀鳳' AS locator, '无改元句，按明年默认' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-tiaolu-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷5·調露' AS locator, '无改元句，按明年默认' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yonglong-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷5·永隆' AS locator, '无改元句，按明年默认' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-kaiyao-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷5·開耀' AS locator, '无改元句，按明年默认' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yongchun-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷5·永淳' AS locator, '无改元句，按明年默认' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-hongdao-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷5、卷6·弘道' AS locator, '无改元句，按明年默认；结果与已核『弘道元年=683』一致' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-sisheng-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷6、卷7·嗣聖' AS locator, '通鉴卷203光宅元年条：春正月甲申朔改元嗣聖；旧唐书卷6光宅元年节首同' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-wenming-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷6·文明' AS locator, '旧唐书卷6：二月…改元文明（嗣圣年内）' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-guangzhai-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷6·光宅' AS locator, '旧唐书卷6：九月…改元為光宅；通鉴卷203标题光宅元年=684' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-chuigong-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷6·垂拱' AS locator, '垂拱元年春正月…改元；通鉴垂拱元年=685至四年=688' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yongchang-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷6·永昌' AS locator, '永昌元年春正月…改元；通鉴永昌元年=689' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-zaichu-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷6·載初' AS locator, '旧唐书卷6天授元年节：改永昌元年十一月為載初元年正月（周正）；通鉴以天授元年=690统摄该年' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-tianshou-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷6·天授' AS locator, '九月九日…改元為天授；通鉴天授元年=690、二年=691；旧唐书长寿节首『三年』=天授三年' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-ruyi-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷6·如意' AS locator, '旧唐书卷6长寿元年节：四月…改元為如意；通鉴卷205长寿元年条四月改元如意' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-changshou-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷6·長壽' AS locator, '九月…改元為長壽；通鉴长寿元年=692、二年=693' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yanzai-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷6·延載' AS locator, '旧唐书延载元年节首『三年』…五月改元為延載（长寿三年）；通鉴延载元年=694' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-zhengsheng-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷6·證聖' AS locator, '天册万岁元年节首：證聖元年春一月…改元；通鉴天册万岁元年=695条正月改元证圣' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-tiancewansui-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷6·天冊萬歲' AS locator, '秋九月…改元為天冊萬歲；通鉴该年标题天册万岁元年=695' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-wansuidengfeng-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷6·萬歲登封' AS locator, '万岁通天元年节首：萬歲登封元年臘月…改元；通鉴万岁通天元年=696' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-wansuitongtian-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷6·萬歲通天' AS locator, '夏四月…改元為萬歲通天；通鉴万岁通天元年=696；神功节『二年』九月改神功' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-shengong-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷6·神功' AS locator, '九月…改元為神功；通鉴神功元年=697' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-shengli-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷6·聖歷' AS locator, '聖歷元年正月…改元；通鉴圣历元年=698、二年=699；久视节首『三年』五月改久视' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-jiushi-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷6·久視' AS locator, '五月…改元為久視；通鉴久视元年=700' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-dazu-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷6·大足' AS locator, '长安元年节首：大足元年春正月制改元；通鉴长安元年=701条正月改元大足' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-changan-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷6·長安' AS locator, '冬十月…改元為長安；通鉴长安元年=701至四年=704' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-shenlong-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷6、卷7·神龍' AS locator, '神龍元年春正月…改元；通鉴神龙元年=705、二年=706；景龙节首『三年』九月改景龙' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-jinglong-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷7·景龍' AS locator, '九月…改元為景龍；通鉴景龙元年=707、二年=708、三年=709；四年夏改唐隆/景云' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-tanglong-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷7·唐隆' AS locator, '景龙四年…改元為唐隆；通鉴景云元年=710' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-jingyun-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷7·景雲' AS locator, '旧唐书景云元年节…改元為景雲；通鉴景云元年=710、二年=711；先天节首『三年』改太极' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-taiji-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷7·太極' AS locator, '景云三年正月…改元為太極；通鉴先天元年=712' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yanhe-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷7·延和' AS locator, '五月…改元為延和；同年八月传位改先天' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-xiantian-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷7、卷8·先天' AS locator, '八月…改元為先天；通鉴先天元年=712；开元元年十二月改元，先天二年=713' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-kaiyuan-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷8、卷9·開元' AS locator, '旧唐书卷8开元元年节：先天二年…十二月…改元為開元；通鉴开元元年=713' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-tianbao-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷9·天寶' AS locator, '天寶元年春正月…改元' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-zhide-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷10·至德' AS locator, '与天宝十五载同一公历年（七月改元曰至德）。锚点直接写入，不靠『是否等于上一年号末年』的推断。' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-qianyuan-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷10·乾元' AS locator, '通鉴乾元元年=758' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-shangyuan-suzong-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷10·上元（肃宗）' AS locator, '通鉴上元元年=760' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-baoying-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷10、卷11·寶應' AS locator, '无改元句，按明年默认；通鉴上元二年=761→宝应元年=762' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-guangde-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷11·廣德' AS locator, '旧唐书卷11：宝应二年秋七月…改元曰廣德；通鉴广德元年=763、二年=764' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yongtai-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷11·永泰' AS locator, '改廣德三年為永泰元年；通鉴永泰元年=765' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-dali-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷11、卷12·大歷' AS locator, '通鉴大曆元年=766至十四年=779' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-jianzhong-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷12·建中' AS locator, '建中元年春正月…政元建中；通鉴建中元年=780（德宗…皇帝一）至四年=783' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-xingyuan-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷12·興元' AS locator, '通鉴兴元元年=784' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-zhenyuan-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷12、卷13、卷14·貞元' AS locator, '贞元元年正月…改元贞元；通鉴贞元元年=785至二十年=804；二十一年即永贞元年' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yongzhen-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷14·永貞' AS locator, '通鉴永贞元年=805（贞元二十一年改元）' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yuanhe-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷14、卷15、卷16·元和' AS locator, '旧唐书卷14宪宗纪：改元曰元和；通鉴元和四年=809，回推元年=806；至十五年=820' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-changqing-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷16、卷17上·長慶' AS locator, '长庆元年…改元长庆；通鉴长庆元年=821至四年=824' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-baoli-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷17上·寶曆' AS locator, '宝历元年…改元宝历；通鉴宝历元年=825、二年=826' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-daihe-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷17上、卷17下·大和' AS locator, '大和元年…改元大和；通鉴太和元年=827、二年=828、八年=834、九年=835；三年至七年按序补829–833' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-kaicheng-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷17下、卷18上·開成' AS locator, '开成元年正月…改元开成；通鉴开成元年=836、二年=837；三年至五年按序至840' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-huichang-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷18上·會昌' AS locator, '会昌元年…改元；通鉴会昌三年=843，回推元年=841；至六年=846' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-dazhong-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷18下、卷19上·大中' AS locator, '大中元年…改元；通鉴大中元年=847至十三年=859' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-xiantong-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷19上、卷19下·咸通' AS locator, '咸通元年十一月…改元；通鉴咸通元年=860至十年=869；十一至十四年按序至873' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-qianfu-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷19下·乾符' AS locator, '乾符元年十一月…改元为乾符；通鉴乾符四年=877，回推元年=874；至六年=879' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-guangming-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷19下·廣明' AS locator, '通鉴广明元年=880' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-zhonghe-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷19下·中和' AS locator, '通鉴中和元年=881、二年=882、四年=884；三年按序883' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-guangqi-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷19下·光啟' AS locator, '光启元年三月…改元光启；通鉴光启元年=885至三年=887' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-wende-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷19下、卷20上·文德' AS locator, '文德元年…改元文德；通鉴文德元年=888' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-longji-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷20上·龍紀' AS locator, '龙纪元年正月…改元；通鉴龙纪元年=889' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-dashun-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷20上·大順' AS locator, '大顺元年正月…改元大顺；通鉴大顺元年=890、二年=891' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-jingfu-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷20上·景福' AS locator, '景福元年正月…改元景福；通鉴景福元年=892、二年=893' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-qianning-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷20上·乾寧' AS locator, '乾宁元年正月…改元乾宁；通鉴乾宁元年=894至四年=897；五年与光化元年同一公历年898' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-guanghua-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷20上·光化' AS locator, '旧唐书卷20上光化元年：八月…改元光化；通鉴光化元年=898' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-tianfu-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷20上·天復' AS locator, '改元天復（月份不清，按明年）' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-tianyou-time' AS claim_id, 'source-jiutangshu-benji-chronology' AS source_id, '卷20上、卷20下·天祐' AS locator, '无改元句，按明年默认；天祐元年/四年为锚点' AS evidence_excerpt FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_citation c WHERE c.claim_id = t.claim_id AND c.source_id = t.source_id);

INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-period-tang-era-sisheng-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·嗣聖（公元684年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=684 end=684' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-wenming-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·文明（公元684年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=684 end=684' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-guangzhai-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·光宅（公元684年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=684 end=684' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-chuigong-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·垂拱（公元685年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=685 end=688' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yongchang-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·永昌（公元689年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=689 end=689' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-zaichu-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·載初（公元690年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=690 end=690' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-tianshou-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·天授（公元690年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=690 end=692' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-ruyi-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·如意（公元692年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=692 end=692' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-changshou-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·長壽（公元692年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=692 end=693' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yanzai-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·延載（公元694年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=694 end=694' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-zhengsheng-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·證聖（公元695年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=695 end=695' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-tiancewansui-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·天冊萬歲（公元695年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=695 end=695' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-wansuidengfeng-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·萬歲登封（公元696年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=696 end=696' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-wansuitongtian-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·萬歲通天（公元696年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=696 end=697' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-shengong-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·神功（公元697年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=697 end=697' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-shengli-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·聖歷（公元698年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=698 end=700' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-jiushi-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·久視（公元700年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=700 end=700' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-dazu-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·大足（公元701年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=701 end=701' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-changan-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·長安（公元701年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=701 end=704' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-shenlong-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·神龍（公元705年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=705 end=707' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-jinglong-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·景龍（公元707年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=707 end=710' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-tanglong-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·唐隆（公元710年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=710 end=710' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-jingyun-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·景雲（公元710年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=710 end=712' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-taiji-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·太極（公元712年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=712 end=712' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yanhe-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·延和（公元712年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=712 end=712' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-xiantian-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·先天（公元712年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=712 end=713' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-qianyuan-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·乾元（公元758年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=758 end=759' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-shangyuan-suzong-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·上元（肃宗）（公元760年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=760 end=761' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-baoying-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·寶應（公元762年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=762 end=763' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-guangde-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·廣德（公元763年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=763 end=764' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yongtai-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·永泰（公元765年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=765 end=765' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-dali-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·大歷（公元766年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=766 end=779' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-jianzhong-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·建中（公元780年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=780 end=783' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-xingyuan-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·興元（公元784年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=784 end=784' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-zhenyuan-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·貞元（公元785年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=785 end=805' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yongzhen-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·永貞（公元805年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=805 end=805' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yuanhe-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·元和（公元806年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=806 end=820' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-changqing-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·長慶（公元821年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=821 end=824' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-baoli-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·寶曆（公元825年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=825 end=826' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-daihe-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·大和（公元827年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=827 end=835' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-kaicheng-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·開成（公元836年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=836 end=840' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-huichang-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·會昌（公元841年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=841 end=846' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-dazhong-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·大中（公元847年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=847 end=859' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-xiantong-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·咸通（公元860年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=860 end=873' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-qianfu-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·乾符（公元874年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=874 end=879' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-guangming-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·廣明（公元880年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=880 end=880' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-zhonghe-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·中和（公元881年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=881 end=884' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-guangqi-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·光啟（公元885年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=885 end=887' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-wende-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·文德（公元888年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=888 end=888' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-longji-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·龍紀（公元889年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=889 end=889' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-dashun-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·大順（公元890年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=890 end=891' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-jingfu-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·景福（公元892年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=892 end=893' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-qianning-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·乾寧（公元894年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=894 end=898' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-guanghua-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·光化（公元898年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=898 end=900' AS evidence_excerpt FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-tianfu-time' AS claim_id, 'source-zizhi-tongjian-tangji' AS source_id, '唐紀·天復（公元901年）' AS locator, '通鉴年标题给定公历；与旧唐书改元句交叉。start=901 end=903' AS evidence_excerpt FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_citation c WHERE c.claim_id = t.claim_id AND c.source_id = t.source_id);

-- ---------- era_of relations ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-period-tang-era-wude-era-of' AS id, 'period-tang-era-wude' AS subject_id, 'era.ruler' AS property_key, '高祖' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-zhenguan-era-of' AS id, 'period-tang-era-zhenguan' AS subject_id, 'era.ruler' AS property_key, '太宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yonghui-era-of' AS id, 'period-tang-era-yonghui' AS subject_id, 'era.ruler' AS property_key, '高宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-xianqing-era-of' AS id, 'period-tang-era-xianqing' AS subject_id, 'era.ruler' AS property_key, '高宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-longshuo-era-of' AS id, 'period-tang-era-longshuo' AS subject_id, 'era.ruler' AS property_key, '高宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-linde-era-of' AS id, 'period-tang-era-linde' AS subject_id, 'era.ruler' AS property_key, '高宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-qianfeng-era-of' AS id, 'period-tang-era-qianfeng' AS subject_id, 'era.ruler' AS property_key, '高宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-zongzhang-era-of' AS id, 'period-tang-era-zongzhang' AS subject_id, 'era.ruler' AS property_key, '高宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-xianheng-era-of' AS id, 'period-tang-era-xianheng' AS subject_id, 'era.ruler' AS property_key, '高宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-shangyuan-gaozong-era-of' AS id, 'period-tang-era-shangyuan-gaozong' AS subject_id, 'era.ruler' AS property_key, '高宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yifeng-era-of' AS id, 'period-tang-era-yifeng' AS subject_id, 'era.ruler' AS property_key, '高宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-tiaolu-era-of' AS id, 'period-tang-era-tiaolu' AS subject_id, 'era.ruler' AS property_key, '高宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yonglong-era-of' AS id, 'period-tang-era-yonglong' AS subject_id, 'era.ruler' AS property_key, '高宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-kaiyao-era-of' AS id, 'period-tang-era-kaiyao' AS subject_id, 'era.ruler' AS property_key, '高宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yongchun-era-of' AS id, 'period-tang-era-yongchun' AS subject_id, 'era.ruler' AS property_key, '高宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-hongdao-era-of' AS id, 'period-tang-era-hongdao' AS subject_id, 'era.ruler' AS property_key, '高宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-sisheng-era-of' AS id, 'period-tang-era-sisheng' AS subject_id, 'era.ruler' AS property_key, '中宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-wenming-era-of' AS id, 'period-tang-era-wenming' AS subject_id, 'era.ruler' AS property_key, '睿宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-guangzhai-era-of' AS id, 'period-tang-era-guangzhai' AS subject_id, 'era.ruler' AS property_key, '武后' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-chuigong-era-of' AS id, 'period-tang-era-chuigong' AS subject_id, 'era.ruler' AS property_key, '武后' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yongchang-era-of' AS id, 'period-tang-era-yongchang' AS subject_id, 'era.ruler' AS property_key, '武后' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-zaichu-era-of' AS id, 'period-tang-era-zaichu' AS subject_id, 'era.ruler' AS property_key, '武后' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-tianshou-era-of' AS id, 'period-tang-era-tianshou' AS subject_id, 'era.ruler' AS property_key, '武后' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-ruyi-era-of' AS id, 'period-tang-era-ruyi' AS subject_id, 'era.ruler' AS property_key, '武后' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-changshou-era-of' AS id, 'period-tang-era-changshou' AS subject_id, 'era.ruler' AS property_key, '武后' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yanzai-era-of' AS id, 'period-tang-era-yanzai' AS subject_id, 'era.ruler' AS property_key, '武后' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-zhengsheng-era-of' AS id, 'period-tang-era-zhengsheng' AS subject_id, 'era.ruler' AS property_key, '武后' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-tiancewansui-era-of' AS id, 'period-tang-era-tiancewansui' AS subject_id, 'era.ruler' AS property_key, '武后' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-wansuidengfeng-era-of' AS id, 'period-tang-era-wansuidengfeng' AS subject_id, 'era.ruler' AS property_key, '武后' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-wansuitongtian-era-of' AS id, 'period-tang-era-wansuitongtian' AS subject_id, 'era.ruler' AS property_key, '武后' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-shengong-era-of' AS id, 'period-tang-era-shengong' AS subject_id, 'era.ruler' AS property_key, '武后' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-shengli-era-of' AS id, 'period-tang-era-shengli' AS subject_id, 'era.ruler' AS property_key, '武后' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-jiushi-era-of' AS id, 'period-tang-era-jiushi' AS subject_id, 'era.ruler' AS property_key, '武后' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-dazu-era-of' AS id, 'period-tang-era-dazu' AS subject_id, 'era.ruler' AS property_key, '武后' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-changan-era-of' AS id, 'period-tang-era-changan' AS subject_id, 'era.ruler' AS property_key, '武后' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-shenlong-era-of' AS id, 'period-tang-era-shenlong' AS subject_id, 'era.ruler' AS property_key, '中宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-jinglong-era-of' AS id, 'period-tang-era-jinglong' AS subject_id, 'era.ruler' AS property_key, '中宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-tanglong-era-of' AS id, 'period-tang-era-tanglong' AS subject_id, 'era.ruler' AS property_key, '中宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-jingyun-era-of' AS id, 'period-tang-era-jingyun' AS subject_id, 'era.ruler' AS property_key, '睿宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-taiji-era-of' AS id, 'period-tang-era-taiji' AS subject_id, 'era.ruler' AS property_key, '睿宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yanhe-era-of' AS id, 'period-tang-era-yanhe' AS subject_id, 'era.ruler' AS property_key, '睿宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-xiantian-era-of' AS id, 'period-tang-era-xiantian' AS subject_id, 'era.ruler' AS property_key, '玄宗/睿宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-kaiyuan-era-of' AS id, 'period-tang-era-kaiyuan' AS subject_id, 'era.ruler' AS property_key, '玄宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-tianbao-era-of' AS id, 'period-tang-era-tianbao' AS subject_id, 'era.ruler' AS property_key, '玄宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-zhide-era-of' AS id, 'period-tang-era-zhide' AS subject_id, 'era.ruler' AS property_key, '肅宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-qianyuan-era-of' AS id, 'period-tang-era-qianyuan' AS subject_id, 'era.ruler' AS property_key, '肅宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-shangyuan-suzong-era-of' AS id, 'period-tang-era-shangyuan-suzong' AS subject_id, 'era.ruler' AS property_key, '肅宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-baoying-era-of' AS id, 'period-tang-era-baoying' AS subject_id, 'era.ruler' AS property_key, '肅宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-guangde-era-of' AS id, 'period-tang-era-guangde' AS subject_id, 'era.ruler' AS property_key, '代宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yongtai-era-of' AS id, 'period-tang-era-yongtai' AS subject_id, 'era.ruler' AS property_key, '代宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-dali-era-of' AS id, 'period-tang-era-dali' AS subject_id, 'era.ruler' AS property_key, '代宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-jianzhong-era-of' AS id, 'period-tang-era-jianzhong' AS subject_id, 'era.ruler' AS property_key, '德宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-xingyuan-era-of' AS id, 'period-tang-era-xingyuan' AS subject_id, 'era.ruler' AS property_key, '德宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-zhenyuan-era-of' AS id, 'period-tang-era-zhenyuan' AS subject_id, 'era.ruler' AS property_key, '德宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yongzhen-era-of' AS id, 'period-tang-era-yongzhen' AS subject_id, 'era.ruler' AS property_key, '順宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-yuanhe-era-of' AS id, 'period-tang-era-yuanhe' AS subject_id, 'era.ruler' AS property_key, '憲宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-changqing-era-of' AS id, 'period-tang-era-changqing' AS subject_id, 'era.ruler' AS property_key, '穆宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-baoli-era-of' AS id, 'period-tang-era-baoli' AS subject_id, 'era.ruler' AS property_key, '敬宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-daihe-era-of' AS id, 'period-tang-era-daihe' AS subject_id, 'era.ruler' AS property_key, '文宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-kaicheng-era-of' AS id, 'period-tang-era-kaicheng' AS subject_id, 'era.ruler' AS property_key, '文宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-huichang-era-of' AS id, 'period-tang-era-huichang' AS subject_id, 'era.ruler' AS property_key, '武宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-dazhong-era-of' AS id, 'period-tang-era-dazhong' AS subject_id, 'era.ruler' AS property_key, '宣宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-xiantong-era-of' AS id, 'period-tang-era-xiantong' AS subject_id, 'era.ruler' AS property_key, '懿宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-qianfu-era-of' AS id, 'period-tang-era-qianfu' AS subject_id, 'era.ruler' AS property_key, '僖宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-guangming-era-of' AS id, 'period-tang-era-guangming' AS subject_id, 'era.ruler' AS property_key, '僖宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-zhonghe-era-of' AS id, 'period-tang-era-zhonghe' AS subject_id, 'era.ruler' AS property_key, '僖宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-guangqi-era-of' AS id, 'period-tang-era-guangqi' AS subject_id, 'era.ruler' AS property_key, '僖宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-wende-era-of' AS id, 'period-tang-era-wende' AS subject_id, 'era.ruler' AS property_key, '僖宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-longji-era-of' AS id, 'period-tang-era-longji' AS subject_id, 'era.ruler' AS property_key, '昭宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-dashun-era-of' AS id, 'period-tang-era-dashun' AS subject_id, 'era.ruler' AS property_key, '昭宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-jingfu-era-of' AS id, 'period-tang-era-jingfu' AS subject_id, 'era.ruler' AS property_key, '昭宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-qianning-era-of' AS id, 'period-tang-era-qianning' AS subject_id, 'era.ruler' AS property_key, '昭宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-guanghua-era-of' AS id, 'period-tang-era-guanghua' AS subject_id, 'era.ruler' AS property_key, '昭宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-tianfu-era-of' AS id, 'period-tang-era-tianfu' AS subject_id, 'era.ruler' AS property_key, '昭宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
UNION ALL
SELECT 'claim-period-tang-era-tianyou-era-of' AS id, 'period-tang-era-tianyou' AS subject_id, 'era.ruler' AS property_key, '哀帝/昭宗' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_claim c WHERE c.id = t.id);

INSERT INTO poetry_relation (id, subject_id, predicate, object_id, claim_id)
SELECT * FROM (
SELECT 'rel-period-tang-era-wude-era-of-gaozu' AS id, 'period-tang-era-wude' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-gaozu' AS object_id, 'claim-period-tang-era-wude-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-zhenguan-era-of-taizong' AS id, 'period-tang-era-zhenguan' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-taizong' AS object_id, 'claim-period-tang-era-zhenguan-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-yonghui-era-of-gaozong' AS id, 'period-tang-era-yonghui' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-gaozong' AS object_id, 'claim-period-tang-era-yonghui-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-xianqing-era-of-gaozong' AS id, 'period-tang-era-xianqing' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-gaozong' AS object_id, 'claim-period-tang-era-xianqing-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-longshuo-era-of-gaozong' AS id, 'period-tang-era-longshuo' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-gaozong' AS object_id, 'claim-period-tang-era-longshuo-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-linde-era-of-gaozong' AS id, 'period-tang-era-linde' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-gaozong' AS object_id, 'claim-period-tang-era-linde-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-qianfeng-era-of-gaozong' AS id, 'period-tang-era-qianfeng' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-gaozong' AS object_id, 'claim-period-tang-era-qianfeng-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-zongzhang-era-of-gaozong' AS id, 'period-tang-era-zongzhang' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-gaozong' AS object_id, 'claim-period-tang-era-zongzhang-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-xianheng-era-of-gaozong' AS id, 'period-tang-era-xianheng' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-gaozong' AS object_id, 'claim-period-tang-era-xianheng-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-shangyuan-gaozong-era-of-gaozong' AS id, 'period-tang-era-shangyuan-gaozong' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-gaozong' AS object_id, 'claim-period-tang-era-shangyuan-gaozong-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-yifeng-era-of-gaozong' AS id, 'period-tang-era-yifeng' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-gaozong' AS object_id, 'claim-period-tang-era-yifeng-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-tiaolu-era-of-gaozong' AS id, 'period-tang-era-tiaolu' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-gaozong' AS object_id, 'claim-period-tang-era-tiaolu-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-yonglong-era-of-gaozong' AS id, 'period-tang-era-yonglong' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-gaozong' AS object_id, 'claim-period-tang-era-yonglong-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-kaiyao-era-of-gaozong' AS id, 'period-tang-era-kaiyao' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-gaozong' AS object_id, 'claim-period-tang-era-kaiyao-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-yongchun-era-of-gaozong' AS id, 'period-tang-era-yongchun' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-gaozong' AS object_id, 'claim-period-tang-era-yongchun-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-hongdao-era-of-gaozong' AS id, 'period-tang-era-hongdao' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-gaozong' AS object_id, 'claim-period-tang-era-hongdao-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-sisheng-era-of-zhongzong-1' AS id, 'period-tang-era-sisheng' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-zhongzong-1' AS object_id, 'claim-period-tang-era-sisheng-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-wenming-era-of-ruizong-1' AS id, 'period-tang-era-wenming' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-ruizong-1' AS object_id, 'claim-period-tang-era-wenming-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-guangzhai-era-of-wuhou' AS id, 'period-tang-era-guangzhai' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-wuhou' AS object_id, 'claim-period-tang-era-guangzhai-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-chuigong-era-of-wuhou' AS id, 'period-tang-era-chuigong' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-wuhou' AS object_id, 'claim-period-tang-era-chuigong-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-yongchang-era-of-wuhou' AS id, 'period-tang-era-yongchang' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-wuhou' AS object_id, 'claim-period-tang-era-yongchang-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-zaichu-era-of-wuhou' AS id, 'period-tang-era-zaichu' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-wuhou' AS object_id, 'claim-period-tang-era-zaichu-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-tianshou-era-of-wuhou' AS id, 'period-tang-era-tianshou' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-wuhou' AS object_id, 'claim-period-tang-era-tianshou-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-ruyi-era-of-wuhou' AS id, 'period-tang-era-ruyi' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-wuhou' AS object_id, 'claim-period-tang-era-ruyi-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-changshou-era-of-wuhou' AS id, 'period-tang-era-changshou' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-wuhou' AS object_id, 'claim-period-tang-era-changshou-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-yanzai-era-of-wuhou' AS id, 'period-tang-era-yanzai' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-wuhou' AS object_id, 'claim-period-tang-era-yanzai-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-zhengsheng-era-of-wuhou' AS id, 'period-tang-era-zhengsheng' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-wuhou' AS object_id, 'claim-period-tang-era-zhengsheng-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-tiancewansui-era-of-wuhou' AS id, 'period-tang-era-tiancewansui' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-wuhou' AS object_id, 'claim-period-tang-era-tiancewansui-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-wansuidengfeng-era-of-wuhou' AS id, 'period-tang-era-wansuidengfeng' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-wuhou' AS object_id, 'claim-period-tang-era-wansuidengfeng-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-wansuitongtian-era-of-wuhou' AS id, 'period-tang-era-wansuitongtian' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-wuhou' AS object_id, 'claim-period-tang-era-wansuitongtian-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-shengong-era-of-wuhou' AS id, 'period-tang-era-shengong' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-wuhou' AS object_id, 'claim-period-tang-era-shengong-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-shengli-era-of-wuhou' AS id, 'period-tang-era-shengli' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-wuhou' AS object_id, 'claim-period-tang-era-shengli-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-jiushi-era-of-wuhou' AS id, 'period-tang-era-jiushi' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-wuhou' AS object_id, 'claim-period-tang-era-jiushi-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-dazu-era-of-wuhou' AS id, 'period-tang-era-dazu' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-wuhou' AS object_id, 'claim-period-tang-era-dazu-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-changan-era-of-wuhou' AS id, 'period-tang-era-changan' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-wuhou' AS object_id, 'claim-period-tang-era-changan-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-shenlong-era-of-zhongzong-2' AS id, 'period-tang-era-shenlong' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-zhongzong-2' AS object_id, 'claim-period-tang-era-shenlong-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-jinglong-era-of-zhongzong-2' AS id, 'period-tang-era-jinglong' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-zhongzong-2' AS object_id, 'claim-period-tang-era-jinglong-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-tanglong-era-of-zhongzong-2' AS id, 'period-tang-era-tanglong' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-zhongzong-2' AS object_id, 'claim-period-tang-era-tanglong-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-jingyun-era-of-ruizong-2' AS id, 'period-tang-era-jingyun' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-ruizong-2' AS object_id, 'claim-period-tang-era-jingyun-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-taiji-era-of-ruizong-2' AS id, 'period-tang-era-taiji' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-ruizong-2' AS object_id, 'claim-period-tang-era-taiji-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-yanhe-era-of-ruizong-2' AS id, 'period-tang-era-yanhe' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-ruizong-2' AS object_id, 'claim-period-tang-era-yanhe-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-xiantian-era-of-ruizong-2' AS id, 'period-tang-era-xiantian' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-ruizong-2' AS object_id, 'claim-period-tang-era-xiantian-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-xiantian-era-of-xuanzong' AS id, 'period-tang-era-xiantian' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-xuanzong' AS object_id, 'claim-period-tang-era-xiantian-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-kaiyuan-era-of-xuanzong' AS id, 'period-tang-era-kaiyuan' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-xuanzong' AS object_id, 'claim-period-tang-era-kaiyuan-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-tianbao-era-of-xuanzong' AS id, 'period-tang-era-tianbao' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-xuanzong' AS object_id, 'claim-period-tang-era-tianbao-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-zhide-era-of-suzong' AS id, 'period-tang-era-zhide' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-suzong' AS object_id, 'claim-period-tang-era-zhide-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-qianyuan-era-of-suzong' AS id, 'period-tang-era-qianyuan' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-suzong' AS object_id, 'claim-period-tang-era-qianyuan-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-shangyuan-suzong-era-of-suzong' AS id, 'period-tang-era-shangyuan-suzong' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-suzong' AS object_id, 'claim-period-tang-era-shangyuan-suzong-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-baoying-era-of-suzong' AS id, 'period-tang-era-baoying' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-suzong' AS object_id, 'claim-period-tang-era-baoying-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-guangde-era-of-daizong' AS id, 'period-tang-era-guangde' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-daizong' AS object_id, 'claim-period-tang-era-guangde-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-yongtai-era-of-daizong' AS id, 'period-tang-era-yongtai' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-daizong' AS object_id, 'claim-period-tang-era-yongtai-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-dali-era-of-daizong' AS id, 'period-tang-era-dali' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-daizong' AS object_id, 'claim-period-tang-era-dali-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-jianzhong-era-of-dezong' AS id, 'period-tang-era-jianzhong' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-dezong' AS object_id, 'claim-period-tang-era-jianzhong-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-xingyuan-era-of-dezong' AS id, 'period-tang-era-xingyuan' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-dezong' AS object_id, 'claim-period-tang-era-xingyuan-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-zhenyuan-era-of-dezong' AS id, 'period-tang-era-zhenyuan' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-dezong' AS object_id, 'claim-period-tang-era-zhenyuan-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-yongzhen-era-of-shunzong' AS id, 'period-tang-era-yongzhen' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-shunzong' AS object_id, 'claim-period-tang-era-yongzhen-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-yuanhe-era-of-xianzong' AS id, 'period-tang-era-yuanhe' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-xianzong' AS object_id, 'claim-period-tang-era-yuanhe-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-changqing-era-of-muzong' AS id, 'period-tang-era-changqing' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-muzong' AS object_id, 'claim-period-tang-era-changqing-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-baoli-era-of-jingzong' AS id, 'period-tang-era-baoli' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-jingzong' AS object_id, 'claim-period-tang-era-baoli-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-daihe-era-of-wenzong' AS id, 'period-tang-era-daihe' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-wenzong' AS object_id, 'claim-period-tang-era-daihe-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-kaicheng-era-of-wenzong' AS id, 'period-tang-era-kaicheng' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-wenzong' AS object_id, 'claim-period-tang-era-kaicheng-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-huichang-era-of-wuzong' AS id, 'period-tang-era-huichang' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-wuzong' AS object_id, 'claim-period-tang-era-huichang-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-dazhong-era-of-xuanzong-xuan' AS id, 'period-tang-era-dazhong' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-xuanzong-xuan' AS object_id, 'claim-period-tang-era-dazhong-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-xiantong-era-of-yizong' AS id, 'period-tang-era-xiantong' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-yizong' AS object_id, 'claim-period-tang-era-xiantong-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-qianfu-era-of-xizong' AS id, 'period-tang-era-qianfu' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-xizong' AS object_id, 'claim-period-tang-era-qianfu-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-guangming-era-of-xizong' AS id, 'period-tang-era-guangming' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-xizong' AS object_id, 'claim-period-tang-era-guangming-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-zhonghe-era-of-xizong' AS id, 'period-tang-era-zhonghe' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-xizong' AS object_id, 'claim-period-tang-era-zhonghe-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-guangqi-era-of-xizong' AS id, 'period-tang-era-guangqi' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-xizong' AS object_id, 'claim-period-tang-era-guangqi-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-wende-era-of-xizong' AS id, 'period-tang-era-wende' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-xizong' AS object_id, 'claim-period-tang-era-wende-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-longji-era-of-zhaozong' AS id, 'period-tang-era-longji' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-zhaozong' AS object_id, 'claim-period-tang-era-longji-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-dashun-era-of-zhaozong' AS id, 'period-tang-era-dashun' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-zhaozong' AS object_id, 'claim-period-tang-era-dashun-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-jingfu-era-of-zhaozong' AS id, 'period-tang-era-jingfu' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-zhaozong' AS object_id, 'claim-period-tang-era-jingfu-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-qianning-era-of-zhaozong' AS id, 'period-tang-era-qianning' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-zhaozong' AS object_id, 'claim-period-tang-era-qianning-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-guanghua-era-of-zhaozong' AS id, 'period-tang-era-guanghua' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-zhaozong' AS object_id, 'claim-period-tang-era-guanghua-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-tianfu-era-of-zhaozong' AS id, 'period-tang-era-tianfu' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-zhaozong' AS object_id, 'claim-period-tang-era-tianfu-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-tianyou-era-of-zhaozong' AS id, 'period-tang-era-tianyou' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-zhaozong' AS object_id, 'claim-period-tang-era-tianyou-era-of' AS claim_id FROM DUAL
UNION ALL
SELECT 'rel-period-tang-era-tianyou-era-of-aidi' AS id, 'period-tang-era-tianyou' AS subject_id, 'era_of' AS predicate, 'person-tang-ruler-aidi' AS object_id, 'claim-period-tang-era-tianyou-era-of' AS claim_id FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_relation r WHERE r.id = t.id);

-- ---------- coverage (verified span) ----------
INSERT INTO poetry_coverage (id, entity_type, from_year, to_year, coverage_kind, status, note, updated_by, updated_at)
SELECT * FROM (
SELECT 'cov-period-tang-era-618-907' AS id, 'PERIOD' AS entity_type, 618 AS from_year, 907 AS to_year, 'PARTIAL' AS coverage_kind, 'DRAFT' AS status, '已核年号：武德–天祐全段（含武周–先天与中晚唐；公历取通鉴年标题，缺题年份按相邻年序补）。' AS note, 'chronology-emit' AS updated_by, NOW() AS updated_at FROM DUAL
UNION ALL
SELECT 'cov-person-tang-rulers-618-907' AS id, 'PERSON' AS entity_type, 618 AS from_year, 907 AS to_year, 'PARTIAL' AS coverage_kind, 'DRAFT' AS status, '唐朝帝王 23 行已录入（含中宗/睿宗两次在位）；高宗→中宗 683/684 边界未决。' AS note, 'chronology-emit' AS updated_by, NOW() AS updated_at FROM DUAL
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_coverage c WHERE c.id = t.id);

INSERT INTO poetry_schema_version (version_no, description)
SELECT 14, 'Tang chronology foundation: 23 rulers + 75 verified eras (Wude–Tianyou; Zhou/Xiantian and mid/late via Tongjian CE)'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM poetry_schema_version WHERE version_no = 14);
COMMIT;

