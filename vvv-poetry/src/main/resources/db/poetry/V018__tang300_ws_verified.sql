-- V018：三百首 94 首——选本正文经维基文库诗页逐字复核（底本《全唐詩》或异源他书）入库。
-- 生成器：poetry-agent-platform/content-agent/pipeline/data/chronology/emit_v018.py
-- 资格判定与逐首明细：corpus/tang300-ws-poems-proof.{json,md}
-- 全部 DRAFT/PENDING；人工核验走 scripts/db/verify-sources.sh --apply，本文件不做核验。
-- 执行前确认连接：
SHOW VARIABLES LIKE 'character_set_client'; -- 须为 utf8mb4（与 V001–V017 同规，本文件族一律不写 SET NAMES，字符集属于连接配置）

-- ---------- 0. 迁移台账 ----------
INSERT INTO poetry_schema_version (version_no, description) VALUES (18, '125 Tang-300 poems whose text verbatim-matches Wikisource (poem pages declaring their base text, or Quan Tangshi volume pages with entry anchors). All rows DRAFT/PENDING') ON DUPLICATE KEY UPDATE description = VALUES(description);

-- ---------- 1. 新作者（正文旁两个转录署名一致；生平年份留空，不编） ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, start_year, end_year, time_precision)
SELECT * FROM (
SELECT 'person-tang-chen-ziang' AS id, 'PERSON' AS entity_type, 'tang-chen-ziang' AS slug, '陳子昂' AS title, '《唐詩三百首》收其詩 1 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'person-tang-wang-jian' AS id, 'PERSON' AS entity_type, 'tang-wang-jian' AS slug, '王建' AS title, '《唐詩三百首》收其詩 1 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'person-tang-wei-zhuang' AS id, 'PERSON' AS entity_type, 'tang-wei-zhuang' AS slug, '韋莊' AS title, '《唐詩三百首》收其詩 2 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'person-tang-ma-dai' AS id, 'PERSON' AS entity_type, 'tang-ma-dai' AS slug, '馬戴' AS title, '《唐詩三百首》收其詩 1 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'person-tang-zheng-tian' AS id, 'PERSON' AS entity_type, 'tang-zheng-tian' AS slug, '鄭畋' AS title, '《唐詩三百首》收其詩 1 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'person-tang-jin-changxu' AS id, 'PERSON' AS entity_type, 'tang-jin-changxu' AS slug, '金昌緒' AS title, '《唐詩三百首》收其詩 1 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'person-tang-yuan-zhen' AS id, 'PERSON' AS entity_type, 'tang-yuan-zhen' AS slug, '元稹' AS title, '《唐詩三百首》收其詩 2 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'person-tang-xibi-ren' AS id, 'PERSON' AS entity_type, 'tang-xibi-ren' AS slug, '西鄙人' AS title, '《唐詩三百首》收其詩 1 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'person-tang-wang-wan' AS id, 'PERSON' AS entity_type, 'tang-wang-wan' AS slug, '王灣' AS title, '《唐詩三百首》收其詩 1 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'person-tang-zhang-xu' AS id, 'PERSON' AS entity_type, 'tang-zhang-xu' AS slug, '張旭' AS title, '《唐詩三百首》收其詩 1 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'person-tang-du-mu' AS id, 'PERSON' AS entity_type, 'tang-du-mu' AS slug, '杜牧' AS title, '《唐詩三百首》收其詩 2 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'person-tang-li-yi' AS id, 'PERSON' AS entity_type, 'tang-li-yi' AS slug, '李益' AS title, '《唐詩三百首》收其詩 2 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'person-tang-liu-changqing' AS id, 'PERSON' AS entity_type, 'tang-liu-changqing' AS slug, '劉長卿' AS title, '《唐詩三百首》收其詩 4 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'person-tang-wang-han' AS id, 'PERSON' AS entity_type, 'tang-wang-han' AS slug, '王翰' AS title, '《唐詩三百首》收其詩 1 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'person-tang-lu-lun' AS id, 'PERSON' AS entity_type, 'tang-lu-lun' AS slug, '盧綸' AS title, '《唐詩三百首》收其詩 1 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'person-tang-qiu-wei' AS id, 'PERSON' AS entity_type, 'tang-qiu-wei' AS slug, '丘爲' AS title, '《唐詩三百首》收其詩 1 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'person-tang-zu-yong' AS id, 'PERSON' AS entity_type, 'tang-zu-yong' AS slug, '祖詠' AS title, '《唐詩三百首》收其詩 2 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'person-tang-li-qi' AS id, 'PERSON' AS entity_type, 'tang-li-qi' AS slug, '李頎' AS title, '《唐詩三百首》收其詩 6 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'person-tang-qi-wu-qian' AS id, 'PERSON' AS entity_type, 'tang-qi-wu-qian' AS slug, '綦毋潛' AS title, '《唐詩三百首》收其詩 1 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'person-tang-chang-jian' AS id, 'PERSON' AS entity_type, 'tang-chang-jian' AS slug, '常建' AS title, '《唐詩三百首》收其詩 1 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'person-tang-wen-tingyun' AS id, 'PERSON' AS entity_type, 'tang-wen-tingyun' AS slug, '溫庭筠' AS title, '《唐詩三百首》收其詩 1 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'person-tang-qin-taoyu' AS id, 'PERSON' AS entity_type, 'tang-qin-taoyu' AS slug, '秦韜玉' AS title, '《唐詩三百首》收其詩 1 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'person-tang-zhang-hu' AS id, 'PERSON' AS entity_type, 'tang-zhang-hu' AS slug, '張祜' AS title, '《唐詩三百首》收其詩 2 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'person-tang-zhu-qingyu' AS id, 'PERSON' AS entity_type, 'tang-zhu-qingyu' AS slug, '朱慶餘' AS title, '《唐詩三百首》收其詩 1 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'person-tang-zhang-jiuling' AS id, 'PERSON' AS entity_type, 'tang-zhang-jiuling' AS slug, '張九齡' AS title, '《唐詩三百首》收其詩 1 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'person-tang-song-zhiwen' AS id, 'PERSON' AS entity_type, 'tang-song-zhiwen' AS slug, '宋之問' AS title, '《唐詩三百首》收其詩 1 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'person-tang-gao-shi' AS id, 'PERSON' AS entity_type, 'tang-gao-shi' AS slug, '高適' AS title, '《唐詩三百首》收其詩 1 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'person-tang-anon' AS id, 'PERSON' AS entity_type, 'tang-anon' AS slug, '不詳' AS title, '《唐詩三百首》收其詩 1 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'person-tang-qian-qi' AS id, 'PERSON' AS entity_type, 'tang-qian-qi' AS slug, '錢起' AS title, '《唐詩三百首》收其詩 2 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'person-tang-han-hong' AS id, 'PERSON' AS entity_type, 'tang-han-hong' AS slug, '韓翃' AS title, '《唐詩三百首》收其詩 1 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'person-tang-wei-yingwu' AS id, 'PERSON' AS entity_type, 'tang-wei-yingwu' AS slug, '韋應物' AS title, '《唐詩三百首》收其詩 7 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'person-tang-cen-shen' AS id, 'PERSON' AS entity_type, 'tang-cen-shen' AS slug, '岑參' AS title, '《唐詩三百首》收其詩 4 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'person-tang-huangfu-ran' AS id, 'PERSON' AS entity_type, 'tang-huangfu-ran' AS slug, '皇甫冉' AS title, '《唐詩三百首》收其詩 1 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'person-tang-liu-fangping' AS id, 'PERSON' AS entity_type, 'tang-liu-fangping' AS slug, '劉方平' AS title, '《唐詩三百首》收其詩 1 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'person-tang-wang-zhihuan' AS id, 'PERSON' AS entity_type, 'tang-wang-zhihuan' AS slug, '王之渙' AS title, '《唐詩三百首》收其詩 1 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'person-tang-liu-shenxu' AS id, 'PERSON' AS entity_type, 'tang-liu-shenxu' AS slug, '劉眘虛' AS title, '《唐詩三百首》收其詩 1 首；正文复核时维基文库页面署名与选本一致（tang300-ws-poems-proof）。生卒年里未核，留空。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

INSERT INTO poetry_person (id, dynasty_id)
SELECT * FROM (
SELECT 'person-tang-chen-ziang' AS id, 'dynasty-tang' AS dynasty_id
UNION ALL
SELECT 'person-tang-wang-jian' AS id, 'dynasty-tang' AS dynasty_id
UNION ALL
SELECT 'person-tang-wei-zhuang' AS id, 'dynasty-tang' AS dynasty_id
UNION ALL
SELECT 'person-tang-ma-dai' AS id, 'dynasty-tang' AS dynasty_id
UNION ALL
SELECT 'person-tang-zheng-tian' AS id, 'dynasty-tang' AS dynasty_id
UNION ALL
SELECT 'person-tang-jin-changxu' AS id, 'dynasty-tang' AS dynasty_id
UNION ALL
SELECT 'person-tang-yuan-zhen' AS id, 'dynasty-tang' AS dynasty_id
UNION ALL
SELECT 'person-tang-xibi-ren' AS id, 'dynasty-tang' AS dynasty_id
UNION ALL
SELECT 'person-tang-wang-wan' AS id, 'dynasty-tang' AS dynasty_id
UNION ALL
SELECT 'person-tang-zhang-xu' AS id, 'dynasty-tang' AS dynasty_id
UNION ALL
SELECT 'person-tang-du-mu' AS id, 'dynasty-tang' AS dynasty_id
UNION ALL
SELECT 'person-tang-li-yi' AS id, 'dynasty-tang' AS dynasty_id
UNION ALL
SELECT 'person-tang-liu-changqing' AS id, 'dynasty-tang' AS dynasty_id
UNION ALL
SELECT 'person-tang-wang-han' AS id, 'dynasty-tang' AS dynasty_id
UNION ALL
SELECT 'person-tang-lu-lun' AS id, 'dynasty-tang' AS dynasty_id
UNION ALL
SELECT 'person-tang-qiu-wei' AS id, 'dynasty-tang' AS dynasty_id
UNION ALL
SELECT 'person-tang-zu-yong' AS id, 'dynasty-tang' AS dynasty_id
UNION ALL
SELECT 'person-tang-li-qi' AS id, 'dynasty-tang' AS dynasty_id
UNION ALL
SELECT 'person-tang-qi-wu-qian' AS id, 'dynasty-tang' AS dynasty_id
UNION ALL
SELECT 'person-tang-chang-jian' AS id, 'dynasty-tang' AS dynasty_id
UNION ALL
SELECT 'person-tang-wen-tingyun' AS id, 'dynasty-tang' AS dynasty_id
UNION ALL
SELECT 'person-tang-qin-taoyu' AS id, 'dynasty-tang' AS dynasty_id
UNION ALL
SELECT 'person-tang-zhang-hu' AS id, 'dynasty-tang' AS dynasty_id
UNION ALL
SELECT 'person-tang-zhu-qingyu' AS id, 'dynasty-tang' AS dynasty_id
UNION ALL
SELECT 'person-tang-zhang-jiuling' AS id, 'dynasty-tang' AS dynasty_id
UNION ALL
SELECT 'person-tang-song-zhiwen' AS id, 'dynasty-tang' AS dynasty_id
UNION ALL
SELECT 'person-tang-gao-shi' AS id, 'dynasty-tang' AS dynasty_id
UNION ALL
SELECT 'person-tang-anon' AS id, 'dynasty-tang' AS dynasty_id
UNION ALL
SELECT 'person-tang-qian-qi' AS id, 'dynasty-tang' AS dynasty_id
UNION ALL
SELECT 'person-tang-han-hong' AS id, 'dynasty-tang' AS dynasty_id
UNION ALL
SELECT 'person-tang-wei-yingwu' AS id, 'dynasty-tang' AS dynasty_id
UNION ALL
SELECT 'person-tang-cen-shen' AS id, 'dynasty-tang' AS dynasty_id
UNION ALL
SELECT 'person-tang-huangfu-ran' AS id, 'dynasty-tang' AS dynasty_id
UNION ALL
SELECT 'person-tang-liu-fangping' AS id, 'dynasty-tang' AS dynasty_id
UNION ALL
SELECT 'person-tang-wang-zhihuan' AS id, 'dynasty-tang' AS dynasty_id
UNION ALL
SELECT 'person-tang-liu-shenxu' AS id, 'dynasty-tang' AS dynasty_id
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_person x WHERE x.id = t.id);

-- ---------- 2. 来源：逐页定位（诗页 header 自述底本 / 卷页锚点 = 硬证据） ----------
INSERT INTO poetry_source (id, title, author, edition, url, rights_note, verification_status)
SELECT * FROM (
SELECT 'source-quantangshi-18' AS id, '《全唐詩》全唐詩/卷018（维基文库录入本）' AS title, NULL AS author, '全唐詩/卷018（维基文库《全唐詩》录入本）' AS edition, 'https://zh.wikisource.org/wiki/全唐詩/卷018' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-quantangshi-218' AS id, '《全唐詩》全唐詩/卷218（维基文库录入本）' AS title, NULL AS author, '全唐詩/卷218（维基文库《全唐詩》录入本）' AS edition, 'https://zh.wikisource.org/wiki/全唐詩/卷218' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-quantangshi-220' AS id, '《全唐詩》全唐詩/卷220（维基文库录入本）' AS title, NULL AS author, '全唐詩/卷220（维基文库《全唐詩》录入本）' AS edition, 'https://zh.wikisource.org/wiki/全唐詩/卷220' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-quantangshi-225' AS id, '《全唐詩》全唐詩/卷225（维基文库录入本）' AS title, NULL AS author, '全唐詩/卷225（维基文库《全唐詩》录入本）' AS edition, 'https://zh.wikisource.org/wiki/全唐詩/卷225' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-quantangshi-226' AS id, '《全唐詩》全唐詩/卷226（维基文库录入本）' AS title, NULL AS author, '全唐詩/卷226（维基文库《全唐詩》录入本）' AS edition, 'https://zh.wikisource.org/wiki/全唐詩/卷226' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-quantangshi-227' AS id, '《全唐詩》全唐詩/卷227（维基文库录入本）' AS title, NULL AS author, '全唐詩/卷227（维基文库《全唐詩》录入本）' AS edition, 'https://zh.wikisource.org/wiki/全唐詩/卷227' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-quantangshi-228' AS id, '《全唐詩》全唐詩/卷228（维基文库录入本）' AS title, NULL AS author, '全唐詩/卷228（维基文库《全唐詩》录入本）' AS edition, 'https://zh.wikisource.org/wiki/全唐詩/卷228' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-quantangshi-28' AS id, '《全唐詩》全唐詩/卷028（维基文库录入本）' AS title, NULL AS author, '全唐詩/卷028（维基文库《全唐詩》录入本）' AS edition, 'https://zh.wikisource.org/wiki/全唐詩/卷028' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-quantangshi-301' AS id, '《全唐詩》全唐詩/卷301（维基文库录入本）' AS title, NULL AS author, '全唐詩/卷301（维基文库《全唐詩》录入本）' AS edition, 'https://zh.wikisource.org/wiki/全唐詩/卷301' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-quantangshi-511' AS id, '《全唐詩》全唐詩/卷511（维基文库录入本）' AS title, NULL AS author, '全唐詩/卷511（维基文库《全唐詩》录入本）' AS edition, 'https://zh.wikisource.org/wiki/全唐詩/卷511' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-quantangshi-514' AS id, '《全唐詩》全唐詩/卷514（维基文库录入本）' AS title, NULL AS author, '全唐詩/卷514（维基文库《全唐詩》录入本）' AS edition, 'https://zh.wikisource.org/wiki/全唐詩/卷514' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-quantangshi-523' AS id, '《全唐詩》全唐詩/卷523（维基文库录入本）' AS title, NULL AS author, '全唐詩/卷523（维基文库《全唐詩》录入本）' AS edition, 'https://zh.wikisource.org/wiki/全唐詩/卷523' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-quantangshi-525' AS id, '《全唐詩》全唐詩/卷525（维基文库录入本）' AS title, NULL AS author, '全唐詩/卷525（维基文库《全唐詩》录入本）' AS edition, 'https://zh.wikisource.org/wiki/全唐詩/卷525' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-quantangshi-539' AS id, '《全唐詩》全唐詩/卷539（维基文库录入本）' AS title, NULL AS author, '全唐詩/卷539（维基文库《全唐詩》录入本）' AS edition, 'https://zh.wikisource.org/wiki/全唐詩/卷539' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-quantangshi-540' AS id, '《全唐詩》全唐詩/卷540（维基文库录入本）' AS title, NULL AS author, '全唐詩/卷540（维基文库《全唐詩》录入本）' AS edition, 'https://zh.wikisource.org/wiki/全唐詩/卷540' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-quantangshi-555' AS id, '《全唐詩》全唐詩/卷555（维基文库录入本）' AS title, NULL AS author, '全唐詩/卷555（维基文库《全唐詩》录入本）' AS edition, 'https://zh.wikisource.org/wiki/全唐詩/卷555' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-quantangshi-557' AS id, '《全唐詩》全唐詩/卷557（维基文库录入本）' AS title, NULL AS author, '全唐詩/卷557（维基文库《全唐詩》录入本）' AS edition, 'https://zh.wikisource.org/wiki/全唐詩/卷557' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-quantangshi-581' AS id, '《全唐詩》全唐詩/卷581（维基文库录入本）' AS title, NULL AS author, '全唐詩/卷581（维基文库《全唐詩》录入本）' AS edition, 'https://zh.wikisource.org/wiki/全唐詩/卷581' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-quantangshi-697' AS id, '《全唐詩》全唐詩/卷697（维基文库录入本）' AS title, NULL AS author, '全唐詩/卷697（维基文库《全唐詩》录入本）' AS edition, 'https://zh.wikisource.org/wiki/全唐詩/卷697' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-quantangshi-784' AS id, '《全唐詩》全唐詩/卷784（维基文库录入本）' AS title, NULL AS author, '全唐詩/卷784（维基文库《全唐詩》录入本）' AS edition, 'https://zh.wikisource.org/wiki/全唐詩/卷784' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-002' AS id, '维基文库《唐詩三百首》页面：登幽州臺歌' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/登幽州臺歌' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-005' AS id, '维基文库《唐詩三百首》页面：出塞 (秦時明月漢時關)' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/出塞 (秦時明月漢時關)' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-010' AS id, '维基文库《唐詩三百首》页面：錦瑟' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/錦瑟' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-011' AS id, '维基文库《唐詩三百首》页面：蟬 (李商隱)' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/蟬 (李商隱)' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-013' AS id, '维基文库《唐詩三百首》页面：夜雨寄北' AS title, NULL AS author, '李義山詩集 (四部叢刊本)/卷第六' AS edition, 'https://zh.wikisource.org/wiki/夜雨寄北' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-015' AS id, '维基文库《唐詩三百首》页面：風雨 (李商隱)' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/風雨 (李商隱)' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-016' AS id, '维基文库《唐詩三百首》页面：寄令狐郎中' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/寄令狐郎中' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-043' AS id, '维基文库《唐詩三百首》页面：春怨 (金昌緒)' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/春怨 (金昌緒)' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-045' AS id, '维基文库《唐詩三百首》页面：遣悲懷之二' AS title, NULL AS author, '全唐詩/卷404' AS edition, 'https://zh.wikisource.org/wiki/遣悲懷之二' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-047' AS id, '维基文库《唐詩三百首》页面：行宮' AS title, NULL AS author, '全唐詩/卷410|type=詩' AS edition, 'https://zh.wikisource.org/wiki/行宮' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-052' AS id, '维基文库《唐詩三百首》页面：次北固山下' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/次北固山下' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-053' AS id, '维基文库《唐詩三百首》页面：桃花谿' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/桃花谿' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-054' AS id, '维基文库《唐詩三百首》页面：送別 (下馬飲君酒)' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/送別 (下馬飲君酒)' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-056' AS id, '维基文库《唐詩三百首》页面：青谿' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/青谿' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-057' AS id, '维基文库《唐詩三百首》页面：渭川田家' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/渭川田家' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-060' AS id, '维基文库《唐詩三百首》页面：桃源行 (王維)' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/桃源行 (王維)' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-061' AS id, '维基文库《唐詩三百首》页面：洛陽女兒行' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/洛陽女兒行' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-062' AS id, '维基文库《唐詩三百首》页面：輞川閑居贈裴秀才迪' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/輞川閑居贈裴秀才迪' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-063' AS id, '维基文库《唐詩三百首》页面：酬張少府' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/酬張少府' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-064' AS id, '维基文库《唐詩三百首》页面：送梓州李使君' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/送梓州李使君' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-087' AS id, '维基文库《唐詩三百首》页面：喜見外弟又言別' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/喜見外弟又言別' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-097' AS id, '维基文库《唐詩三百首》页面：新年作 (劉長卿)' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/新年作 (劉長卿)' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-100' AS id, '维基文库《唐詩三百首》页面：餞別王十一南遊' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/餞別王十一南遊' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-101' AS id, '维基文库《唐詩三百首》页面：江州重別薛六柳八二員外' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/江州重別薛六柳八二員外' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-102' AS id, '维基文库《唐詩三百首》页面：長沙過賈誼宅' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/長沙過賈誼宅' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-106' AS id, '维基文库《唐詩三百首》页面：涼州詞 (葡萄美酒夜光杯)' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/涼州詞 (葡萄美酒夜光杯)' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-108' AS id, '维基文库《唐詩三百首》页面：夏日南亭懷辛大' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/夏日南亭懷辛大' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-112' AS id, '维基文库《唐詩三百首》页面：秦中感秋寄遠上人' AS title, NULL AS author, '全唐詩/卷160#秦中感秋寄遠' AS edition, 'https://zh.wikisource.org/wiki/秦中感秋寄遠上人' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-117' AS id, '维基文库《唐詩三百首》页面：與諸子登峴山' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/與諸子登峴山' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-118' AS id, '维基文库《唐詩三百首》页面：過故人莊' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/過故人莊' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-119' AS id, '维基文库《唐詩三百首》页面：歲暮歸南山' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/歲暮歸南山' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-121' AS id, '维基文库《唐詩三百首》页面：春曉 (孟浩然)' AS title, NULL AS author, '文苑英華 (四庫全書本)/卷0157' AS edition, 'https://zh.wikisource.org/wiki/春曉 (孟浩然)' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-122' AS id, '维基文库《唐詩三百首》页面：宿建德江' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/宿建德江' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-131' AS id, '维基文库《唐詩三百首》页面：晚次鄂州' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/晚次鄂州' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-133' AS id, '维基文库《唐詩三百首》页面：過香積寺' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/過香積寺' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-134' AS id, '维基文库《唐詩三百首》页面：山居秋暝' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/山居秋暝' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-135' AS id, '维基文库《唐詩三百首》页面：終南別業' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/終南別業' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-136' AS id, '维基文库《唐詩三百首》页面：歸嵩山作' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/歸嵩山作' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-137' AS id, '维基文库《唐詩三百首》页面：終南山 (王維)' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/終南山 (王維)' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-140' AS id, '维基文库《唐詩三百首》页面：和賈舍人早朝大明宮之作' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/和賈舍人早朝大明宮之作' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-142' AS id, '维基文库《唐詩三百首》页面：積雨輞川莊作' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/積雨輞川莊作' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-145' AS id, '维基文库《唐詩三百首》页面：送別 (山中相送罷)' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/送別 (山中相送罷)' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-146' AS id, '维基文库《唐詩三百首》页面：雜詩 (君自故鄉來)' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/雜詩 (君自故鄉來)' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-148' AS id, '维基文库《唐詩三百首》页面：九月九日憶山東兄弟' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/九月九日憶山東兄弟' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-151' AS id, '维基文库《唐詩三百首》页面：尋西山隱者不遇' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/尋西山隱者不遇' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-153' AS id, '维基文库《唐詩三百首》页面：行經華陰' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/行經華陰' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-156' AS id, '维基文库《唐詩三百首》页面：望薊門' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/望薊門' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-157' AS id, '维基文库《唐詩三百首》页面：終南望餘雪' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/終南望餘雪' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-158' AS id, '维基文库《唐詩三百首》页面：古從軍行' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/古從軍行' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-159' AS id, '维基文库《唐詩三百首》页面：琴歌 (李頎)' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/琴歌 (李頎)' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-160' AS id, '维基文库《唐詩三百首》页面：送陳章甫' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/送陳章甫' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-161' AS id, '维基文库《唐詩三百首》页面：聽安萬善吹觱篥歌' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/聽安萬善吹觱篥歌' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-162' AS id, '维基文库《唐詩三百首》页面：古意 (李頎)' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/古意 (李頎)' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-164' AS id, '维基文库《唐詩三百首》页面：送魏萬之京' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/送魏萬之京' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-165' AS id, '维基文库《唐詩三百首》页面：春泛若耶溪' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/春泛若耶溪' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-170' AS id, '维基文库《唐詩三百首》页面：春宮曲' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/春宮曲' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-171' AS id, '维基文库《唐詩三百首》页面：閨怨 (王昌齡)' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/閨怨 (王昌齡)' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-173' AS id, '维基文库《唐詩三百首》页面：宿王昌齡隱居' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/宿王昌齡隱居' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-189' AS id, '维基文库《唐詩三百首》页面：貧女(秦韜玉)' AS title, NULL AS author, '全唐詩/卷670' AS edition, 'https://zh.wikisource.org/wiki/貧女(秦韜玉)' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-216' AS id, '维基文库《唐詩三百首》页面：奉濟驛重送嚴公四韻' AS title, NULL AS author, '全唐詩/卷227' AS edition, 'https://zh.wikisource.org/wiki/奉濟驛重送嚴公四韻' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-217' AS id, '维基文库《唐詩三百首》页面：聞官軍收河南河北' AS title, NULL AS author, '全唐詩/卷227' AS edition, 'https://zh.wikisource.org/wiki/聞官軍收河南河北' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-220' AS id, '维基文库《唐詩三百首》页面：登樓 (杜甫)' AS title, NULL AS author, '全唐詩 (四庫全書本)/卷22' AS edition, 'https://zh.wikisource.org/wiki/登樓 (杜甫)' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-231' AS id, '维基文库《唐詩三百首》页面：登岳陽樓 (杜甫)' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/登岳陽樓 (杜甫)' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-233' AS id, '维基文库《唐詩三百首》页面：望月懷遠' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/望月懷遠' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-234' AS id, '维基文库《唐詩三百首》页面：題大庾嶺北驛' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/題大庾嶺北驛' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-240' AS id, '维基文库《唐詩三百首》页面：送李少府貶峽中王少府貶長沙' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/送李少府貶峽中王少府貶長沙' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-274' AS id, '维基文库《唐詩三百首》页面：谷口書齋寄楊補闕' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/谷口書齋寄楊補闕' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-276' AS id, '维基文库《唐詩三百首》页面：贈闕下裴舍人' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/贈闕下裴舍人' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-283' AS id, '维基文库《唐詩三百首》页面：寒食 (韓翃)' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/寒食 (韓翃)' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-284' AS id, '维基文库《唐詩三百首》页面：寄李儋元錫' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/寄李儋元錫' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-285' AS id, '维基文库《唐詩三百首》页面：寄全椒山中道士' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/寄全椒山中道士' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-289' AS id, '维基文库《唐詩三百首》页面：長安遇馮著' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/長安遇馮著' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-290' AS id, '维基文库《唐詩三百首》页面：夕次盱眙縣' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/夕次盱眙縣' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-291' AS id, '维基文库《唐詩三百首》页面：東郊' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/東郊' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-292' AS id, '维基文库《唐詩三百首》页面：滁州西澗' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/滁州西澗' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-296' AS id, '维基文库《唐詩三百首》页面：輪臺歌奉送封大夫出師西征' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/輪臺歌奉送封大夫出師西征' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-298' AS id, '维基文库《唐詩三百首》页面：寄左省杜拾遺' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/寄左省杜拾遺' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-299' AS id, '维基文库《唐詩三百首》页面：奉和中書舍人賈至早朝大明宮' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/奉和中書舍人賈至早朝大明宮' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-300' AS id, '维基文库《唐詩三百首》页面：逢入京使' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/逢入京使' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-308' AS id, '维基文库《唐詩三百首》页面：玉階怨 (李白)' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/玉階怨 (李白)' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-312' AS id, '维基文库《唐詩三百首》页面：春思 (李白)' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/春思 (李白)' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-320' AS id, '维基文库《唐詩三百首》页面：金陵酒肆留別' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/金陵酒肆留別' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-323' AS id, '维基文库《唐詩三百首》页面：送友人 (李白)' AS title, NULL AS author, '全唐詩 (四庫全書本)/卷17' AS edition, 'https://zh.wikisource.org/wiki/送友人 (李白)' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-325' AS id, '维基文库《唐詩三百首》页面：下終南山過斛斯山人宿置酒' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/下終南山過斛斯山人宿置酒' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-326' AS id, '维基文库《唐詩三百首》页面：登金陵鳳凰臺' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/登金陵鳳凰臺' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-328' AS id, '维基文库《唐詩三百首》页面：夜泊牛渚懷古' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/夜泊牛渚懷古' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-330' AS id, '维基文库《唐詩三百首》页面：聽蜀僧濬彈琴' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/聽蜀僧濬彈琴' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-331' AS id, '维基文库《唐詩三百首》页面：怨情 (美人捲珠簾)' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/怨情 (美人捲珠簾)' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-334' AS id, '维基文库《唐詩三百首》页面：初發揚子寄元大校書' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/初發揚子寄元大校書' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-335' AS id, '维基文库《唐詩三百首》页面：江南曲 (嫁得瞿塘賈)' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/江南曲 (嫁得瞿塘賈)' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-358' AS id, '维基文库《唐詩三百首》页面：春思 (皇甫冉)' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/春思 (皇甫冉)' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-360' AS id, '维基文库《唐詩三百首》页面：春怨 (劉方平)' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/春怨 (劉方平)' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-361' AS id, '维基文库《唐詩三百首》页面：登鸛雀樓 (王之渙)' AS title, NULL AS author, '全唐詩 (四庫全書本)/卷25' AS edition, 'https://zh.wikisource.org/wiki/登鸛雀樓 (王之渙)' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
UNION ALL
SELECT 'source-ws-t300-363' AS id, '维基文库《唐詩三百首》页面：闕題 (劉眘虛)' AS title, NULL AS author, '全唐詩' AS edition, 'https://zh.wikisource.org/wiki/闕題 (劉眘虛)' AS url, '维基文库录入本，公有领域古籍。本行由 corpus 下复核脚本逐字定位；录入本本身可能需据扫描版校对，核验状态保持 PENDING。' AS rights_note, 'PENDING' AS verification_status
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_source x WHERE x.id = t.id);

-- ---------- 3. 作品（id=选本序号；title 照录选本，题名分歧见复核报告，不裁决；既有 work 只挂证据不重建） ----------
INSERT INTO poetry_content (id, entity_type, slug, title, summary, start_year, end_year, time_precision)
SELECT * FROM (
SELECT 'work-t300-002' AS id, 'WORK' AS entity_type, 't300-002' AS slug, '登幽州臺歌' AS title, '《唐詩三百首》第 2 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-005' AS id, 'WORK' AS entity_type, 't300-005' AS slug, '橫吹曲辭 出塞 一' AS title, '《唐詩三百首》第 5 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-009' AS id, 'WORK' AS entity_type, 't300-009' AS slug, '故行宮' AS title, '《唐詩三百首》第 9 首。正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷301（维基文库《全唐詩》录入本）；卷页锚点「卷301_23故行宮王建」。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-010' AS id, 'WORK' AS entity_type, 't300-010' AS slug, '錦瑟' AS title, '《唐詩三百首》第 10 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-011' AS id, 'WORK' AS entity_type, 't300-011' AS slug, '蟬' AS title, '《唐詩三百首》第 11 首。正文与维基文库页面逐字一致（先折叠登记过的异体字：读法甲折叠异体字后一致；页面自述底本 全唐詩（同书异转录，第二证成立））；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-013' AS id, 'WORK' AS entity_type, 't300-013' AS slug, '夜雨寄北' AS title, '《唐詩三百首》第 13 首。正文与维基文库页面逐字一致（先折叠登记过的异体字：读法甲折叠异体字后一致；页面自述底本 李義山詩集 (四部叢刊本)/卷第六（异源他书，第二证成立；其差异属跨书异文））；底本为他书 李義山詩集 (四部叢刊本)/卷第六，属跨书比对。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-015' AS id, 'WORK' AS entity_type, 't300-015' AS slug, '風雨' AS title, '《唐詩三百首》第 15 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-016' AS id, 'WORK' AS entity_type, 't300-016' AS slug, '寄令狐郎中' AS title, '《唐詩三百首》第 16 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-020' AS id, 'WORK' AS entity_type, 't300-020' AS slug, '無題四首 一' AS title, '《唐詩三百首》第 20 首。正文与维基文库《全唐詩》卷页逐字一致（先折叠登记过的异体字：踪/蹤）；底本 全唐詩/卷539（维基文库《全唐詩》录入本）；卷页锚点「==無題四首_來是空言去絕蹤|無題四首==」。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-022' AS id, 'WORK' AS entity_type, 't300-022' AS slug, '隋宮' AS title, '《唐詩三百首》第 22 首。正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷539（维基文库《全唐詩》录入本）；卷页锚点「==隋宮==」。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-024' AS id, 'WORK' AS entity_type, 't300-024' AS slug, '爲有' AS title, '《唐詩三百首》第 24 首。正文与维基文库《全唐詩》卷页逐字一致（先折叠登记过的异体字：壻/婿）；底本 全唐詩/卷539（维基文库《全唐詩》录入本）；卷页锚点「==為有==」。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-025' AS id, 'WORK' AS entity_type, 't300-025' AS slug, '無題' AS title, '《唐詩三百首》第 25 首。正文与维基文库《全唐詩》卷页逐字一致（先折叠登记过的异体字：爲/為）；底本 全唐詩/卷539（维基文库《全唐詩》录入本）；卷页锚点「==無題_相見時難別亦難|無題==」。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-026' AS id, 'WORK' AS entity_type, 't300-026' AS slug, '瑤池' AS title, '《唐詩三百首》第 26 首。正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷539（维基文库《全唐詩》录入本）；卷页锚点「==瑤池==」。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-028' AS id, 'WORK' AS entity_type, 't300-028' AS slug, '常娥' AS title, '《唐詩三百首》第 28 首。正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷540（维基文库《全唐詩》录入本）；卷页锚点「==常娥==」。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-029' AS id, 'WORK' AS entity_type, 't300-029' AS slug, '無題二首 一' AS title, '《唐詩三百首》第 29 首。正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷540（维基文库《全唐詩》录入本）；卷页锚点「==無題二首==」。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-031' AS id, 'WORK' AS entity_type, 't300-031' AS slug, '賈生' AS title, '《唐詩三百首》第 31 首。正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷540（维基文库《全唐詩》录入本）；卷页锚点「==賈生==」。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-032' AS id, 'WORK' AS entity_type, 't300-032' AS slug, '涼思' AS title, '《唐詩三百首》第 32 首。正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷540（维基文库《全唐詩》录入本）；卷页锚点「==涼思==」。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-036' AS id, 'WORK' AS entity_type, 't300-036' AS slug, '金陵圖' AS title, '《唐詩三百首》第 36 首。正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷697（维基文库《全唐詩》录入本）；卷页锚点「===金陵圖===」。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-037' AS id, 'WORK' AS entity_type, 't300-037' AS slug, '臺城' AS title, '《唐詩三百首》第 37 首。正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷697（维基文库《全唐詩》录入本）；卷页锚点「===台城===」。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-040' AS id, 'WORK' AS entity_type, 't300-040' AS slug, '灞上秋居' AS title, '《唐詩三百首》第 40 首。正文与维基文库《全唐詩》卷页逐字一致（先折叠登记过的异体字：隣/鄰、鴈/雁）；底本 全唐詩/卷555（维基文库《全唐詩》录入本）；卷页锚点「===灞上秋居===」。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-041' AS id, 'WORK' AS entity_type, 't300-041' AS slug, '馬嵬坡' AS title, '《唐詩三百首》第 41 首。正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷557（维基文库《全唐詩》录入本）；卷页锚点「===馬嵬坡===」。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-043' AS id, 'WORK' AS entity_type, 't300-043' AS slug, '春怨' AS title, '《唐詩三百首》第 43 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-045' AS id, 'WORK' AS entity_type, 't300-045' AS slug, '遣悲懷三首 二' AS title, '《唐詩三百首》第 45 首。正文与维基文库页面逐字一致；底本 全唐詩/卷404。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-047' AS id, 'WORK' AS entity_type, 't300-047' AS slug, '行宮' AS title, '《唐詩三百首》第 47 首。正文与维基文库页面逐字一致；底本 全唐詩/卷410|type=詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-048' AS id, 'WORK' AS entity_type, 't300-048' AS slug, '哥舒歌' AS title, '《唐詩三百首》第 48 首。正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷784（维基文库《全唐詩》录入本）；卷页锚点「==西鄙人====」。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-052' AS id, 'WORK' AS entity_type, 't300-052' AS slug, '次北固山下' AS title, '《唐詩三百首》第 52 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-053' AS id, 'WORK' AS entity_type, 't300-053' AS slug, '桃花谿' AS title, '《唐詩三百首》第 53 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-054' AS id, 'WORK' AS entity_type, 't300-054' AS slug, '送別' AS title, '《唐詩三百首》第 54 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-056' AS id, 'WORK' AS entity_type, 't300-056' AS slug, '青谿' AS title, '《唐詩三百首》第 56 首。正文与维基文库页面逐字一致（先折叠登记过的异体字：读法甲折叠异体字后一致；页面自述底本 全唐詩（同书异转录，第二证成立））；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-057' AS id, 'WORK' AS entity_type, 't300-057' AS slug, '渭川田家' AS title, '《唐詩三百首》第 57 首。正文与维基文库页面逐字一致（先折叠登记过的异体字：读法甲折叠异体字后一致；页面自述底本 全唐詩（同书异转录，第二证成立））；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-060' AS id, 'WORK' AS entity_type, 't300-060' AS slug, '桃源行' AS title, '《唐詩三百首》第 60 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-061' AS id, 'WORK' AS entity_type, 't300-061' AS slug, '洛陽女兒行' AS title, '《唐詩三百首》第 61 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-062' AS id, 'WORK' AS entity_type, 't300-062' AS slug, '輞川閑居贈裴秀才迪' AS title, '《唐詩三百首》第 62 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-063' AS id, 'WORK' AS entity_type, 't300-063' AS slug, '酬張少府' AS title, '《唐詩三百首》第 63 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-064' AS id, 'WORK' AS entity_type, 't300-064' AS slug, '送梓州李使君' AS title, '《唐詩三百首》第 64 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-074' AS id, 'WORK' AS entity_type, 't300-074' AS slug, '泊秦淮' AS title, '《唐詩三百首》第 74 首。正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷523（维基文库《全唐詩》录入本）；卷页锚点「===泊秦淮===」。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-079' AS id, 'WORK' AS entity_type, 't300-079' AS slug, '金谷園' AS title, '《唐詩三百首》第 79 首。正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷525（维基文库《全唐詩》录入本）；卷页锚点「===金谷園===」。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-087' AS id, 'WORK' AS entity_type, 't300-087' AS slug, '喜見外弟又言別' AS title, '《唐詩三百首》第 87 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-097' AS id, 'WORK' AS entity_type, 't300-097' AS slug, '新年作' AS title, '《唐詩三百首》第 97 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-100' AS id, 'WORK' AS entity_type, 't300-100' AS slug, '餞別王十一南遊' AS title, '《唐詩三百首》第 100 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-101' AS id, 'WORK' AS entity_type, 't300-101' AS slug, '江州重別薛六柳八二員外' AS title, '《唐詩三百首》第 101 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-102' AS id, 'WORK' AS entity_type, 't300-102' AS slug, '長沙過賈誼宅' AS title, '《唐詩三百首》第 102 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-106' AS id, 'WORK' AS entity_type, 't300-106' AS slug, '涼州詞二首 一' AS title, '《唐詩三百首》第 106 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-108' AS id, 'WORK' AS entity_type, 't300-108' AS slug, '夏日南亭懷辛大' AS title, '《唐詩三百首》第 108 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-112' AS id, 'WORK' AS entity_type, 't300-112' AS slug, '秦中感秋寄遠上人' AS title, '《唐詩三百首》第 112 首。正文与维基文库页面逐字一致；底本 全唐詩/卷160#秦中感秋寄遠。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-117' AS id, 'WORK' AS entity_type, 't300-117' AS slug, '與諸子登峴山' AS title, '《唐詩三百首》第 117 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-118' AS id, 'WORK' AS entity_type, 't300-118' AS slug, '過故人莊' AS title, '《唐詩三百首》第 118 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-119' AS id, 'WORK' AS entity_type, 't300-119' AS slug, '歲暮歸南山' AS title, '《唐詩三百首》第 119 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-121' AS id, 'WORK' AS entity_type, 't300-121' AS slug, '春曉' AS title, '《唐詩三百首》第 121 首。正文与维基文库页面逐字一致；底本为他书 文苑英華 (四庫全書本)/卷0157，属跨书比对。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-122' AS id, 'WORK' AS entity_type, 't300-122' AS slug, '宿建德江' AS title, '《唐詩三百首》第 122 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-131' AS id, 'WORK' AS entity_type, 't300-131' AS slug, '晚次鄂州' AS title, '《唐詩三百首》第 131 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-133' AS id, 'WORK' AS entity_type, 't300-133' AS slug, '過香積寺' AS title, '《唐詩三百首》第 133 首。正文与维基文库页面逐字一致（先折叠登记过的异体字：读法甲折叠异体字后一致；页面自述底本 全唐詩（同书异转录，第二证成立））；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-134' AS id, 'WORK' AS entity_type, 't300-134' AS slug, '山居秋暝' AS title, '《唐詩三百首》第 134 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-135' AS id, 'WORK' AS entity_type, 't300-135' AS slug, '終南別業' AS title, '《唐詩三百首》第 135 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-136' AS id, 'WORK' AS entity_type, 't300-136' AS slug, '歸嵩山作' AS title, '《唐詩三百首》第 136 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-137' AS id, 'WORK' AS entity_type, 't300-137' AS slug, '終南山' AS title, '《唐詩三百首》第 137 首。正文与维基文库页面逐字一致（先折叠登记过的异体字：读法甲折叠异体字后一致；页面自述底本 全唐詩（同书异转录，第二证成立））；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-140' AS id, 'WORK' AS entity_type, 't300-140' AS slug, '和賈舍人早朝大明宮之作' AS title, '《唐詩三百首》第 140 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-142' AS id, 'WORK' AS entity_type, 't300-142' AS slug, '積雨輞川莊作' AS title, '《唐詩三百首》第 142 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-145' AS id, 'WORK' AS entity_type, 't300-145' AS slug, '送別' AS title, '《唐詩三百首》第 145 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-146' AS id, 'WORK' AS entity_type, 't300-146' AS slug, '雜詩三首 二' AS title, '《唐詩三百首》第 146 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-148' AS id, 'WORK' AS entity_type, 't300-148' AS slug, '九月九日憶山東兄弟' AS title, '《唐詩三百首》第 148 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-151' AS id, 'WORK' AS entity_type, 't300-151' AS slug, '尋西山隱者不遇' AS title, '《唐詩三百首》第 151 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-153' AS id, 'WORK' AS entity_type, 't300-153' AS slug, '行經華陰' AS title, '《唐詩三百首》第 153 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-156' AS id, 'WORK' AS entity_type, 't300-156' AS slug, '望薊門' AS title, '《唐詩三百首》第 156 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-157' AS id, 'WORK' AS entity_type, 't300-157' AS slug, '終南望餘雪' AS title, '《唐詩三百首》第 157 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-158' AS id, 'WORK' AS entity_type, 't300-158' AS slug, '古從軍行' AS title, '《唐詩三百首》第 158 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-159' AS id, 'WORK' AS entity_type, 't300-159' AS slug, '琴歌' AS title, '《唐詩三百首》第 159 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-160' AS id, 'WORK' AS entity_type, 't300-160' AS slug, '送陳章甫' AS title, '《唐詩三百首》第 160 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-161' AS id, 'WORK' AS entity_type, 't300-161' AS slug, '聽安萬善吹觱篥歌' AS title, '《唐詩三百首》第 161 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-162' AS id, 'WORK' AS entity_type, 't300-162' AS slug, '古意' AS title, '《唐詩三百首》第 162 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-164' AS id, 'WORK' AS entity_type, 't300-164' AS slug, '送魏萬之京' AS title, '《唐詩三百首》第 164 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-165' AS id, 'WORK' AS entity_type, 't300-165' AS slug, '春泛若耶溪' AS title, '《唐詩三百首》第 165 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-169' AS id, 'WORK' AS entity_type, 't300-169' AS slug, '出塞二首 一' AS title, '《唐詩三百首》第 169 首。正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷018（维基文库《全唐詩》录入本）；卷页锚点「==橫吹曲辭出塞==」。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-170' AS id, 'WORK' AS entity_type, 't300-170' AS slug, '春宮曲' AS title, '《唐詩三百首》第 170 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-171' AS id, 'WORK' AS entity_type, 't300-171' AS slug, '閨怨' AS title, '《唐詩三百首》第 171 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-173' AS id, 'WORK' AS entity_type, 't300-173' AS slug, '宿王昌齡隱居' AS title, '《唐詩三百首》第 173 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-186' AS id, 'WORK' AS entity_type, 't300-186' AS slug, '送人東遊' AS title, '《唐詩三百首》第 186 首。正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷581（维基文库《全唐詩》录入本）；卷页锚点「===送人東===」。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-189' AS id, 'WORK' AS entity_type, 't300-189' AS slug, '貧女' AS title, '《唐詩三百首》第 189 首。正文与维基文库页面逐字一致；底本 全唐詩/卷670。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-193' AS id, 'WORK' AS entity_type, 't300-193' AS slug, '宮詞二首 一' AS title, '《唐詩三百首》第 193 首。正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷511（维基文库《全唐詩》录入本）；卷页锚点「===宮詞二首===」。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-197' AS id, 'WORK' AS entity_type, 't300-197' AS slug, '題金陵渡' AS title, '《唐詩三百首》第 197 首。正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷511（维基文库《全唐詩》录入本）；卷页锚点「===延年不語望三星莫說夫人上涕零爭奈世間惆悵在甘泉宮夜看圖形===」。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-198' AS id, 'WORK' AS entity_type, 't300-198' AS slug, '宮詞' AS title, '《唐詩三百首》第 198 首。正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷514（维基文库《全唐詩》录入本）；卷页锚点「===石抱龍堂蘚石乾山遮白日寺門寒長松瀑布饒奇狀曾有僊人駐鶴看===」。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-207' AS id, 'WORK' AS entity_type, 't300-207' AS slug, '月夜' AS title, '《唐詩三百首》第 207 首。正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷224（维基文库《全唐詩》录入本）；卷页锚点「==月夜==」。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-209' AS id, 'WORK' AS entity_type, 't300-209' AS slug, '春宿左省' AS title, '《唐詩三百首》第 209 首。正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷225（维基文库《全唐詩》录入本）；卷页锚点「==春宿左省==」。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-210' AS id, 'WORK' AS entity_type, 't300-210' AS slug, '至德二載甫自京金光門出問道歸鳳翔乾元初從左拾遺移華州掾與親故別因出此門有悲往事' AS title, '《唐詩三百首》第 210 首。正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷225（维基文库《全唐詩》录入本）；卷页锚点「==因許八奉寄江甯旻上人==」。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-211' AS id, 'WORK' AS entity_type, 't300-211' AS slug, '月夜憶舍弟' AS title, '《唐詩三百首》第 211 首。正文与维基文库《全唐詩》卷页逐字一致（先折叠登记过的异体字：鄉/鄕）；底本 全唐詩/卷225（维基文库《全唐詩》录入本）；卷页锚点「==月夜憶舍弟==」。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-214' AS id, 'WORK' AS entity_type, 't300-214' AS slug, '客至' AS title, '《唐詩三百首》第 214 首。正文与维基文库《全唐詩》卷页逐字一致（先折叠登记过的异体字：桮/杯）；底本 全唐詩/卷226（维基文库《全唐詩》录入本）；卷页锚点「==客至喜崔明府相過==」。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-215' AS id, 'WORK' AS entity_type, 't300-215' AS slug, '野望' AS title, '《唐詩三百首》第 215 首。正文与维基文库《全唐詩》卷页逐字一致（先折叠登记过的异体字：荅/答）；底本 全唐詩/卷227（维基文库《全唐詩》录入本）；卷页锚点「==野望杜甫|野望==」。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-216' AS id, 'WORK' AS entity_type, 't300-216' AS slug, '奉濟驛重送嚴公四韻' AS title, '《唐詩三百首》第 216 首。正文与维基文库页面逐字一致（先折叠登记过的异体字：读法甲折叠异体字后一致；页面自述底本 全唐詩/卷227（同书异转录，第二证成立））；底本 全唐詩/卷227。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-217' AS id, 'WORK' AS entity_type, 't300-217' AS slug, '聞官軍收河南河北' AS title, '《唐詩三百首》第 217 首。正文与维基文库页面逐字一致（先折叠登记过的异体字：读法甲折叠异体字后一致；页面自述底本 全唐詩/卷227（同书异转录，第二证成立））；底本 全唐詩/卷227。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-220' AS id, 'WORK' AS entity_type, 't300-220' AS slug, '登樓' AS title, '《唐詩三百首》第 220 首。正文与维基文库页面逐字一致（先折叠登记过的异体字：读法甲折叠异体字后一致；页面自述底本 全唐詩 (四庫全書本)/卷22（同书异转录，第二证成立））；底本 全唐詩 (四庫全書本)/卷22。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-221' AS id, 'WORK' AS entity_type, 't300-221' AS slug, '宿府' AS title, '《唐詩三百首》第 221 首。正文与维基文库《全唐詩》卷页逐字一致（先折叠登记过的异体字：栖/棲）；底本 全唐詩/卷228（维基文库《全唐詩》录入本）；卷页锚点「==宿府==」。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-231' AS id, 'WORK' AS entity_type, 't300-231' AS slug, '登岳陽樓' AS title, '《唐詩三百首》第 231 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-233' AS id, 'WORK' AS entity_type, 't300-233' AS slug, '望月懷遠' AS title, '《唐詩三百首》第 233 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-234' AS id, 'WORK' AS entity_type, 't300-234' AS slug, '題大庾嶺北驛' AS title, '《唐詩三百首》第 234 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-240' AS id, 'WORK' AS entity_type, 't300-240' AS slug, '送李少府貶峽中王少府貶長沙' AS title, '《唐詩三百首》第 240 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-248' AS id, 'WORK' AS entity_type, 't300-248' AS slug, '夢李白二首 一' AS title, '《唐詩三百首》第 248 首。正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷218（维基文库《全唐詩》录入本）；卷页锚点「==夢李白二首==」。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-252' AS id, 'WORK' AS entity_type, 't300-252' AS slug, '寄韓諫議' AS title, '《唐詩三百首》第 252 首。正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷220（维基文库《全唐詩》录入本）；卷页锚点「==寄韓諫議==」。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-262' AS id, 'WORK' AS entity_type, 't300-262' AS slug, '雜曲歌辭 金縷衣' AS title, '《唐詩三百首》第 262 首。正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷028（维基文库《全唐詩》录入本）；卷页锚点「==雜曲歌辭金縷衣==」。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-274' AS id, 'WORK' AS entity_type, 't300-274' AS slug, '谷口書齋寄楊補闕' AS title, '《唐詩三百首》第 274 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-276' AS id, 'WORK' AS entity_type, 't300-276' AS slug, '贈闕下裴舍人' AS title, '《唐詩三百首》第 276 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-283' AS id, 'WORK' AS entity_type, 't300-283' AS slug, '寒食' AS title, '《唐詩三百首》第 283 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-284' AS id, 'WORK' AS entity_type, 't300-284' AS slug, '寄李儋元錫' AS title, '《唐詩三百首》第 284 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-285' AS id, 'WORK' AS entity_type, 't300-285' AS slug, '寄全椒山中道士' AS title, '《唐詩三百首》第 285 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-289' AS id, 'WORK' AS entity_type, 't300-289' AS slug, '長安遇馮著' AS title, '《唐詩三百首》第 289 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-290' AS id, 'WORK' AS entity_type, 't300-290' AS slug, '夕次盱眙縣' AS title, '《唐詩三百首》第 290 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-291' AS id, 'WORK' AS entity_type, 't300-291' AS slug, '東郊' AS title, '《唐詩三百首》第 291 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-292' AS id, 'WORK' AS entity_type, 't300-292' AS slug, '滁州西澗' AS title, '《唐詩三百首》第 292 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-296' AS id, 'WORK' AS entity_type, 't300-296' AS slug, '輪臺歌奉送封大夫出師西征' AS title, '《唐詩三百首》第 296 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-298' AS id, 'WORK' AS entity_type, 't300-298' AS slug, '寄左省杜拾遺' AS title, '《唐詩三百首》第 298 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-299' AS id, 'WORK' AS entity_type, 't300-299' AS slug, '奉和中書舍人賈至早朝大明宮' AS title, '《唐詩三百首》第 299 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-300' AS id, 'WORK' AS entity_type, 't300-300' AS slug, '逢入京使' AS title, '《唐詩三百首》第 300 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-308' AS id, 'WORK' AS entity_type, 't300-308' AS slug, '玉階怨' AS title, '《唐詩三百首》第 308 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-312' AS id, 'WORK' AS entity_type, 't300-312' AS slug, '春思' AS title, '《唐詩三百首》第 312 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-320' AS id, 'WORK' AS entity_type, 't300-320' AS slug, '金陵酒肆留別' AS title, '《唐詩三百首》第 320 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-323' AS id, 'WORK' AS entity_type, 't300-323' AS slug, '送友人' AS title, '《唐詩三百首》第 323 首。正文与维基文库页面逐字一致（先折叠登记过的异体字：读法甲折叠异体字后一致；页面自述底本 全唐詩 (四庫全書本)/卷17（同书异转录，第二证成立））；底本 全唐詩 (四庫全書本)/卷17。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-325' AS id, 'WORK' AS entity_type, 't300-325' AS slug, '下終南山過斛斯山人宿置酒' AS title, '《唐詩三百首》第 325 首。正文与维基文库页面逐字一致（先折叠登记过的异体字：读法甲折叠异体字后一致；页面自述底本 全唐詩（同书异转录，第二证成立））；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-326' AS id, 'WORK' AS entity_type, 't300-326' AS slug, '登金陵鳳凰臺' AS title, '《唐詩三百首》第 326 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-328' AS id, 'WORK' AS entity_type, 't300-328' AS slug, '夜泊牛渚懷古' AS title, '《唐詩三百首》第 328 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-330' AS id, 'WORK' AS entity_type, 't300-330' AS slug, '聽蜀僧濬彈琴' AS title, '《唐詩三百首》第 330 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-331' AS id, 'WORK' AS entity_type, 't300-331' AS slug, '怨情' AS title, '《唐詩三百首》第 331 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-334' AS id, 'WORK' AS entity_type, 't300-334' AS slug, '初發揚子寄元大校書' AS title, '《唐詩三百首》第 334 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-335' AS id, 'WORK' AS entity_type, 't300-335' AS slug, '相和歌辭 江南曲' AS title, '《唐詩三百首》第 335 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-358' AS id, 'WORK' AS entity_type, 't300-358' AS slug, '春思' AS title, '《唐詩三百首》第 358 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-360' AS id, 'WORK' AS entity_type, 't300-360' AS slug, '春怨' AS title, '《唐詩三百首》第 360 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-361' AS id, 'WORK' AS entity_type, 't300-361' AS slug, '登鸛雀樓' AS title, '《唐詩三百首》第 361 首。正文与维基文库页面逐字一致；底本 全唐詩 (四庫全書本)/卷25。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
UNION ALL
SELECT 'work-t300-363' AS id, 'WORK' AS entity_type, 't300-363' AS slug, '闕題' AS title, '《唐詩三百首》第 363 首。正文与维基文库页面逐字一致；底本 全唐詩。判定与异文登记：corpus 下 tang300-ws-poems-proof / tang300-wikisource-proof。' AS summary, NULL AS start_year, NULL AS end_year, 'UNKNOWN' AS time_precision
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_content x WHERE x.id = t.id);

INSERT INTO poetry_work (id, dynasty_id, genre)
SELECT * FROM (
SELECT 'work-t300-002' AS id, 'dynasty-tang' AS dynasty_id, '七言古詩' AS genre
UNION ALL
SELECT 'work-t300-005' AS id, 'dynasty-tang' AS dynasty_id, '樂府' AS genre
UNION ALL
SELECT 'work-t300-009' AS id, 'dynasty-tang' AS dynasty_id, '五言絕句' AS genre
UNION ALL
SELECT 'work-t300-010' AS id, 'dynasty-tang' AS dynasty_id, '七言律詩' AS genre
UNION ALL
SELECT 'work-t300-011' AS id, 'dynasty-tang' AS dynasty_id, '五言律詩' AS genre
UNION ALL
SELECT 'work-t300-013' AS id, 'dynasty-tang' AS dynasty_id, '七言絕句' AS genre
UNION ALL
SELECT 'work-t300-015' AS id, 'dynasty-tang' AS dynasty_id, '五言律詩' AS genre
UNION ALL
SELECT 'work-t300-016' AS id, 'dynasty-tang' AS dynasty_id, '七言絕句' AS genre
UNION ALL
SELECT 'work-t300-020' AS id, 'dynasty-tang' AS dynasty_id, '七言律詩' AS genre
UNION ALL
SELECT 'work-t300-022' AS id, 'dynasty-tang' AS dynasty_id, '七言絕句' AS genre
UNION ALL
SELECT 'work-t300-024' AS id, 'dynasty-tang' AS dynasty_id, '七言絕句' AS genre
UNION ALL
SELECT 'work-t300-025' AS id, 'dynasty-tang' AS dynasty_id, '七言律詩' AS genre
UNION ALL
SELECT 'work-t300-026' AS id, 'dynasty-tang' AS dynasty_id, '七言絕句' AS genre
UNION ALL
SELECT 'work-t300-028' AS id, 'dynasty-tang' AS dynasty_id, '七言絕句' AS genre
UNION ALL
SELECT 'work-t300-029' AS id, 'dynasty-tang' AS dynasty_id, '七言律詩' AS genre
UNION ALL
SELECT 'work-t300-031' AS id, 'dynasty-tang' AS dynasty_id, '七言絕句' AS genre
UNION ALL
SELECT 'work-t300-032' AS id, 'dynasty-tang' AS dynasty_id, '五言律詩' AS genre
UNION ALL
SELECT 'work-t300-036' AS id, 'dynasty-tang' AS dynasty_id, '七言絕句' AS genre
UNION ALL
SELECT 'work-t300-037' AS id, 'dynasty-tang' AS dynasty_id, NULL AS genre
UNION ALL
SELECT 'work-t300-040' AS id, 'dynasty-tang' AS dynasty_id, '五言律詩' AS genre
UNION ALL
SELECT 'work-t300-041' AS id, 'dynasty-tang' AS dynasty_id, '七言絕句' AS genre
UNION ALL
SELECT 'work-t300-043' AS id, 'dynasty-tang' AS dynasty_id, '五言絕句' AS genre
UNION ALL
SELECT 'work-t300-045' AS id, 'dynasty-tang' AS dynasty_id, '七言律詩' AS genre
UNION ALL
SELECT 'work-t300-047' AS id, 'dynasty-tang' AS dynasty_id, '五言絕句' AS genre
UNION ALL
SELECT 'work-t300-048' AS id, 'dynasty-tang' AS dynasty_id, '五言絕句' AS genre
UNION ALL
SELECT 'work-t300-052' AS id, 'dynasty-tang' AS dynasty_id, '五言律詩' AS genre
UNION ALL
SELECT 'work-t300-053' AS id, 'dynasty-tang' AS dynasty_id, '七言絕句' AS genre
UNION ALL
SELECT 'work-t300-054' AS id, 'dynasty-tang' AS dynasty_id, NULL AS genre
UNION ALL
SELECT 'work-t300-056' AS id, 'dynasty-tang' AS dynasty_id, '五言古詩' AS genre
UNION ALL
SELECT 'work-t300-057' AS id, 'dynasty-tang' AS dynasty_id, '五言古詩' AS genre
UNION ALL
SELECT 'work-t300-060' AS id, 'dynasty-tang' AS dynasty_id, '樂府' AS genre
UNION ALL
SELECT 'work-t300-061' AS id, 'dynasty-tang' AS dynasty_id, '樂府' AS genre
UNION ALL
SELECT 'work-t300-062' AS id, 'dynasty-tang' AS dynasty_id, '五言律詩' AS genre
UNION ALL
SELECT 'work-t300-063' AS id, 'dynasty-tang' AS dynasty_id, '五言律詩' AS genre
UNION ALL
SELECT 'work-t300-064' AS id, 'dynasty-tang' AS dynasty_id, '五言律詩' AS genre
UNION ALL
SELECT 'work-t300-074' AS id, 'dynasty-tang' AS dynasty_id, '七言絕句' AS genre
UNION ALL
SELECT 'work-t300-079' AS id, 'dynasty-tang' AS dynasty_id, '七言絕句' AS genre
UNION ALL
SELECT 'work-t300-087' AS id, 'dynasty-tang' AS dynasty_id, '五言律詩' AS genre
UNION ALL
SELECT 'work-t300-097' AS id, 'dynasty-tang' AS dynasty_id, '五言律詩' AS genre
UNION ALL
SELECT 'work-t300-100' AS id, 'dynasty-tang' AS dynasty_id, '五言律詩' AS genre
UNION ALL
SELECT 'work-t300-101' AS id, 'dynasty-tang' AS dynasty_id, '七言律詩' AS genre
UNION ALL
SELECT 'work-t300-102' AS id, 'dynasty-tang' AS dynasty_id, '七言律詩' AS genre
UNION ALL
SELECT 'work-t300-106' AS id, 'dynasty-tang' AS dynasty_id, '七言絕句' AS genre
UNION ALL
SELECT 'work-t300-108' AS id, 'dynasty-tang' AS dynasty_id, '五言古詩' AS genre
UNION ALL
SELECT 'work-t300-112' AS id, 'dynasty-tang' AS dynasty_id, '五言律詩' AS genre
UNION ALL
SELECT 'work-t300-117' AS id, 'dynasty-tang' AS dynasty_id, '五言律詩' AS genre
UNION ALL
SELECT 'work-t300-118' AS id, 'dynasty-tang' AS dynasty_id, '五言律詩' AS genre
UNION ALL
SELECT 'work-t300-119' AS id, 'dynasty-tang' AS dynasty_id, NULL AS genre
UNION ALL
SELECT 'work-t300-121' AS id, 'dynasty-tang' AS dynasty_id, '五言絕句' AS genre
UNION ALL
SELECT 'work-t300-122' AS id, 'dynasty-tang' AS dynasty_id, '五言絕句' AS genre
UNION ALL
SELECT 'work-t300-131' AS id, 'dynasty-tang' AS dynasty_id, '七言律詩' AS genre
UNION ALL
SELECT 'work-t300-133' AS id, 'dynasty-tang' AS dynasty_id, '五言律詩' AS genre
UNION ALL
SELECT 'work-t300-134' AS id, 'dynasty-tang' AS dynasty_id, '五言律詩' AS genre
UNION ALL
SELECT 'work-t300-135' AS id, 'dynasty-tang' AS dynasty_id, '五言律詩' AS genre
UNION ALL
SELECT 'work-t300-136' AS id, 'dynasty-tang' AS dynasty_id, '五言律詩' AS genre
UNION ALL
SELECT 'work-t300-137' AS id, 'dynasty-tang' AS dynasty_id, '五言律詩' AS genre
UNION ALL
SELECT 'work-t300-140' AS id, 'dynasty-tang' AS dynasty_id, '七言律詩' AS genre
UNION ALL
SELECT 'work-t300-142' AS id, 'dynasty-tang' AS dynasty_id, '七言律詩' AS genre
UNION ALL
SELECT 'work-t300-145' AS id, 'dynasty-tang' AS dynasty_id, '五言絕句' AS genre
UNION ALL
SELECT 'work-t300-146' AS id, 'dynasty-tang' AS dynasty_id, '五言絕句' AS genre
UNION ALL
SELECT 'work-t300-148' AS id, 'dynasty-tang' AS dynasty_id, '七言絕句' AS genre
UNION ALL
SELECT 'work-t300-151' AS id, 'dynasty-tang' AS dynasty_id, '五言古詩' AS genre
UNION ALL
SELECT 'work-t300-153' AS id, 'dynasty-tang' AS dynasty_id, '七言律詩' AS genre
UNION ALL
SELECT 'work-t300-156' AS id, 'dynasty-tang' AS dynasty_id, '七言律詩' AS genre
UNION ALL
SELECT 'work-t300-157' AS id, 'dynasty-tang' AS dynasty_id, '五言絕句' AS genre
UNION ALL
SELECT 'work-t300-158' AS id, 'dynasty-tang' AS dynasty_id, '樂府' AS genre
UNION ALL
SELECT 'work-t300-159' AS id, 'dynasty-tang' AS dynasty_id, '七言古詩' AS genre
UNION ALL
SELECT 'work-t300-160' AS id, 'dynasty-tang' AS dynasty_id, '七言古詩' AS genre
UNION ALL
SELECT 'work-t300-161' AS id, 'dynasty-tang' AS dynasty_id, '七言古詩' AS genre
UNION ALL
SELECT 'work-t300-162' AS id, 'dynasty-tang' AS dynasty_id, '七言古詩' AS genre
UNION ALL
SELECT 'work-t300-164' AS id, 'dynasty-tang' AS dynasty_id, '七言律詩' AS genre
UNION ALL
SELECT 'work-t300-165' AS id, 'dynasty-tang' AS dynasty_id, '五言古詩' AS genre
UNION ALL
SELECT 'work-t300-169' AS id, 'dynasty-tang' AS dynasty_id, '樂府' AS genre
UNION ALL
SELECT 'work-t300-170' AS id, 'dynasty-tang' AS dynasty_id, '七言絕句' AS genre
UNION ALL
SELECT 'work-t300-171' AS id, 'dynasty-tang' AS dynasty_id, '七言絕句' AS genre
UNION ALL
SELECT 'work-t300-173' AS id, 'dynasty-tang' AS dynasty_id, '五言古詩' AS genre
UNION ALL
SELECT 'work-t300-186' AS id, 'dynasty-tang' AS dynasty_id, '五言律詩' AS genre
UNION ALL
SELECT 'work-t300-189' AS id, 'dynasty-tang' AS dynasty_id, '七言律詩' AS genre
UNION ALL
SELECT 'work-t300-193' AS id, 'dynasty-tang' AS dynasty_id, '五言絕句' AS genre
UNION ALL
SELECT 'work-t300-197' AS id, 'dynasty-tang' AS dynasty_id, '七言絕句' AS genre
UNION ALL
SELECT 'work-t300-198' AS id, 'dynasty-tang' AS dynasty_id, '七言絕句' AS genre
UNION ALL
SELECT 'work-t300-207' AS id, 'dynasty-tang' AS dynasty_id, '五言律詩' AS genre
UNION ALL
SELECT 'work-t300-209' AS id, 'dynasty-tang' AS dynasty_id, '五言律詩' AS genre
UNION ALL
SELECT 'work-t300-210' AS id, 'dynasty-tang' AS dynasty_id, '五言律詩' AS genre
UNION ALL
SELECT 'work-t300-211' AS id, 'dynasty-tang' AS dynasty_id, '五言律詩' AS genre
UNION ALL
SELECT 'work-t300-214' AS id, 'dynasty-tang' AS dynasty_id, NULL AS genre
UNION ALL
SELECT 'work-t300-215' AS id, 'dynasty-tang' AS dynasty_id, '七言律詩' AS genre
UNION ALL
SELECT 'work-t300-216' AS id, 'dynasty-tang' AS dynasty_id, '五言律詩' AS genre
UNION ALL
SELECT 'work-t300-217' AS id, 'dynasty-tang' AS dynasty_id, '七言律詩' AS genre
UNION ALL
SELECT 'work-t300-220' AS id, 'dynasty-tang' AS dynasty_id, '七言律詩' AS genre
UNION ALL
SELECT 'work-t300-221' AS id, 'dynasty-tang' AS dynasty_id, '七言律詩' AS genre
UNION ALL
SELECT 'work-t300-231' AS id, 'dynasty-tang' AS dynasty_id, '五言律詩' AS genre
UNION ALL
SELECT 'work-t300-233' AS id, 'dynasty-tang' AS dynasty_id, '五言律詩' AS genre
UNION ALL
SELECT 'work-t300-234' AS id, 'dynasty-tang' AS dynasty_id, '五言律詩' AS genre
UNION ALL
SELECT 'work-t300-240' AS id, 'dynasty-tang' AS dynasty_id, '七言律詩' AS genre
UNION ALL
SELECT 'work-t300-248' AS id, 'dynasty-tang' AS dynasty_id, NULL AS genre
UNION ALL
SELECT 'work-t300-252' AS id, 'dynasty-tang' AS dynasty_id, '七言古詩' AS genre
UNION ALL
SELECT 'work-t300-262' AS id, 'dynasty-tang' AS dynasty_id, '樂府' AS genre
UNION ALL
SELECT 'work-t300-274' AS id, 'dynasty-tang' AS dynasty_id, '五言律詩' AS genre
UNION ALL
SELECT 'work-t300-276' AS id, 'dynasty-tang' AS dynasty_id, '七言律詩' AS genre
UNION ALL
SELECT 'work-t300-283' AS id, 'dynasty-tang' AS dynasty_id, '七言絕句' AS genre
UNION ALL
SELECT 'work-t300-284' AS id, 'dynasty-tang' AS dynasty_id, '七言律詩' AS genre
UNION ALL
SELECT 'work-t300-285' AS id, 'dynasty-tang' AS dynasty_id, '五言古詩' AS genre
UNION ALL
SELECT 'work-t300-289' AS id, 'dynasty-tang' AS dynasty_id, '五言古詩' AS genre
UNION ALL
SELECT 'work-t300-290' AS id, 'dynasty-tang' AS dynasty_id, '五言古詩' AS genre
UNION ALL
SELECT 'work-t300-291' AS id, 'dynasty-tang' AS dynasty_id, NULL AS genre
UNION ALL
SELECT 'work-t300-292' AS id, 'dynasty-tang' AS dynasty_id, '七言絕句' AS genre
UNION ALL
SELECT 'work-t300-296' AS id, 'dynasty-tang' AS dynasty_id, '七言古詩' AS genre
UNION ALL
SELECT 'work-t300-298' AS id, 'dynasty-tang' AS dynasty_id, '五言律詩' AS genre
UNION ALL
SELECT 'work-t300-299' AS id, 'dynasty-tang' AS dynasty_id, '七言律詩' AS genre
UNION ALL
SELECT 'work-t300-300' AS id, 'dynasty-tang' AS dynasty_id, '七言絕句' AS genre
UNION ALL
SELECT 'work-t300-308' AS id, 'dynasty-tang' AS dynasty_id, '樂府' AS genre
UNION ALL
SELECT 'work-t300-312' AS id, 'dynasty-tang' AS dynasty_id, '五言古詩' AS genre
UNION ALL
SELECT 'work-t300-320' AS id, 'dynasty-tang' AS dynasty_id, '七言古詩' AS genre
UNION ALL
SELECT 'work-t300-323' AS id, 'dynasty-tang' AS dynasty_id, '五言律詩' AS genre
UNION ALL
SELECT 'work-t300-325' AS id, 'dynasty-tang' AS dynasty_id, '五言古詩' AS genre
UNION ALL
SELECT 'work-t300-326' AS id, 'dynasty-tang' AS dynasty_id, '七言律詩' AS genre
UNION ALL
SELECT 'work-t300-328' AS id, 'dynasty-tang' AS dynasty_id, '五言律詩' AS genre
UNION ALL
SELECT 'work-t300-330' AS id, 'dynasty-tang' AS dynasty_id, '五言律詩' AS genre
UNION ALL
SELECT 'work-t300-331' AS id, 'dynasty-tang' AS dynasty_id, '五言絕句' AS genre
UNION ALL
SELECT 'work-t300-334' AS id, 'dynasty-tang' AS dynasty_id, '五言古詩' AS genre
UNION ALL
SELECT 'work-t300-335' AS id, 'dynasty-tang' AS dynasty_id, '樂府' AS genre
UNION ALL
SELECT 'work-t300-358' AS id, 'dynasty-tang' AS dynasty_id, '七言律詩' AS genre
UNION ALL
SELECT 'work-t300-360' AS id, 'dynasty-tang' AS dynasty_id, '七言絕句' AS genre
UNION ALL
SELECT 'work-t300-361' AS id, 'dynasty-tang' AS dynasty_id, '五言絕句' AS genre
UNION ALL
SELECT 'work-t300-363' AS id, 'dynasty-tang' AS dynasty_id, '五言律詩' AS genre
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_work x WHERE x.id = t.id);

-- ---------- 4. 作者署名：选本与维基文库页面一致（PENDING——判定权在人） ----------
INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-t300-002-author' AS id, 'work-t300-002' AS subject_id, 'author.attribution' AS property_key, '署名 陳子昂：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-005-author' AS id, 'work-t300-005' AS subject_id, 'author.attribution' AS property_key, '署名 王昌齡：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-009-author' AS id, 'work-t300-009' AS subject_id, 'author.attribution' AS property_key, '署名 王建：选本与维基文库《全唐詩》卷页两处转录一致（锚点含署名：「卷301_23故行宮王建」）。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-010-author' AS id, 'work-t300-010' AS subject_id, 'author.attribution' AS property_key, '署名 李商隱：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-011-author' AS id, 'work-t300-011' AS subject_id, 'author.attribution' AS property_key, '署名 李商隱：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-013-author' AS id, 'work-t300-013' AS subject_id, 'author.attribution' AS property_key, '署名 李商隱：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-015-author' AS id, 'work-t300-015' AS subject_id, 'author.attribution' AS property_key, '署名 李商隱：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-016-author' AS id, 'work-t300-016' AS subject_id, 'author.attribution' AS property_key, '署名 李商隱：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-020-author' AS id, 'work-t300-020' AS subject_id, 'author.attribution' AS property_key, '署名 李商隱：选本所署；维基文库《全唐詩》卷页按 ==無題四首_來是空言去絕蹤|無題四首== 收录，锚点未含署名，作者归属依该卷编排体例——更弱一档。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-022-author' AS id, 'work-t300-022' AS subject_id, 'author.attribution' AS property_key, '署名 李商隱：选本所署；维基文库《全唐詩》卷页按 ==隋宮== 收录，锚点未含署名，作者归属依该卷编排体例——更弱一档。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-024-author' AS id, 'work-t300-024' AS subject_id, 'author.attribution' AS property_key, '署名 李商隱：选本所署；维基文库《全唐詩》卷页按 ==為有== 收录，锚点未含署名，作者归属依该卷编排体例——更弱一档。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-025-author' AS id, 'work-t300-025' AS subject_id, 'author.attribution' AS property_key, '署名 李商隱：选本所署；维基文库《全唐詩》卷页按 ==無題_相見時難別亦難|無題== 收录，锚点未含署名，作者归属依该卷编排体例——更弱一档。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-026-author' AS id, 'work-t300-026' AS subject_id, 'author.attribution' AS property_key, '署名 李商隱：选本所署；维基文库《全唐詩》卷页按 ==瑤池== 收录，锚点未含署名，作者归属依该卷编排体例——更弱一档。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-028-author' AS id, 'work-t300-028' AS subject_id, 'author.attribution' AS property_key, '署名 李商隱：选本所署；维基文库《全唐詩》卷页按 ==常娥== 收录，锚点未含署名，作者归属依该卷编排体例——更弱一档。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-029-author' AS id, 'work-t300-029' AS subject_id, 'author.attribution' AS property_key, '署名 李商隱：选本所署；维基文库《全唐詩》卷页按 ==無題二首== 收录，锚点未含署名，作者归属依该卷编排体例——更弱一档。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-031-author' AS id, 'work-t300-031' AS subject_id, 'author.attribution' AS property_key, '署名 李商隱：选本所署；维基文库《全唐詩》卷页按 ==賈生== 收录，锚点未含署名，作者归属依该卷编排体例——更弱一档。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-032-author' AS id, 'work-t300-032' AS subject_id, 'author.attribution' AS property_key, '署名 李商隱：选本所署；维基文库《全唐詩》卷页按 ==涼思== 收录，锚点未含署名，作者归属依该卷编排体例——更弱一档。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-036-author' AS id, 'work-t300-036' AS subject_id, 'author.attribution' AS property_key, '署名 韋莊：选本所署；维基文库《全唐詩》卷页按 ===金陵圖=== 收录，锚点未含署名，作者归属依该卷编排体例——更弱一档。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-037-author' AS id, 'work-t300-037' AS subject_id, 'author.attribution' AS property_key, '署名 韋莊：选本所署；维基文库《全唐詩》卷页按 ===台城=== 收录，锚点未含署名，作者归属依该卷编排体例——更弱一档。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-040-author' AS id, 'work-t300-040' AS subject_id, 'author.attribution' AS property_key, '署名 馬戴：选本所署；维基文库《全唐詩》卷页按 ===灞上秋居=== 收录，锚点未含署名，作者归属依该卷编排体例——更弱一档。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-041-author' AS id, 'work-t300-041' AS subject_id, 'author.attribution' AS property_key, '署名 鄭畋：选本所署；维基文库《全唐詩》卷页按 ===馬嵬坡=== 收录，锚点未含署名，作者归属依该卷编排体例——更弱一档。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-043-author' AS id, 'work-t300-043' AS subject_id, 'author.attribution' AS property_key, '署名 金昌緒：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-045-author' AS id, 'work-t300-045' AS subject_id, 'author.attribution' AS property_key, '署名 元稹：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-047-author' AS id, 'work-t300-047' AS subject_id, 'author.attribution' AS property_key, '署名 元稹：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-048-author' AS id, 'work-t300-048' AS subject_id, 'author.attribution' AS property_key, '署名 西鄙人：选本与维基文库《全唐詩》卷页两处转录一致（锚点含署名：「==西鄙人====」）。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-052-author' AS id, 'work-t300-052' AS subject_id, 'author.attribution' AS property_key, '署名 王灣：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-053-author' AS id, 'work-t300-053' AS subject_id, 'author.attribution' AS property_key, '署名 張旭：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-054-author' AS id, 'work-t300-054' AS subject_id, 'author.attribution' AS property_key, '署名 王維：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-056-author' AS id, 'work-t300-056' AS subject_id, 'author.attribution' AS property_key, '署名 王維：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-057-author' AS id, 'work-t300-057' AS subject_id, 'author.attribution' AS property_key, '署名 王維：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-060-author' AS id, 'work-t300-060' AS subject_id, 'author.attribution' AS property_key, '署名 王維：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-061-author' AS id, 'work-t300-061' AS subject_id, 'author.attribution' AS property_key, '署名 王維：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-062-author' AS id, 'work-t300-062' AS subject_id, 'author.attribution' AS property_key, '署名 王維：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-063-author' AS id, 'work-t300-063' AS subject_id, 'author.attribution' AS property_key, '署名 王維：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-064-author' AS id, 'work-t300-064' AS subject_id, 'author.attribution' AS property_key, '署名 王維：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-074-author' AS id, 'work-t300-074' AS subject_id, 'author.attribution' AS property_key, '署名 杜牧：选本所署；维基文库《全唐詩》卷页按 ===泊秦淮=== 收录，锚点未含署名，作者归属依该卷编排体例——更弱一档。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-079-author' AS id, 'work-t300-079' AS subject_id, 'author.attribution' AS property_key, '署名 杜牧：选本所署；维基文库《全唐詩》卷页按 ===金谷園=== 收录，锚点未含署名，作者归属依该卷编排体例——更弱一档。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-087-author' AS id, 'work-t300-087' AS subject_id, 'author.attribution' AS property_key, '署名 李益：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-097-author' AS id, 'work-t300-097' AS subject_id, 'author.attribution' AS property_key, '署名 劉長卿：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-100-author' AS id, 'work-t300-100' AS subject_id, 'author.attribution' AS property_key, '署名 劉長卿：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-101-author' AS id, 'work-t300-101' AS subject_id, 'author.attribution' AS property_key, '署名 劉長卿：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-102-author' AS id, 'work-t300-102' AS subject_id, 'author.attribution' AS property_key, '署名 劉長卿：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-106-author' AS id, 'work-t300-106' AS subject_id, 'author.attribution' AS property_key, '署名 王翰：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-108-author' AS id, 'work-t300-108' AS subject_id, 'author.attribution' AS property_key, '署名 孟浩然：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-112-author' AS id, 'work-t300-112' AS subject_id, 'author.attribution' AS property_key, '署名 孟浩然：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-117-author' AS id, 'work-t300-117' AS subject_id, 'author.attribution' AS property_key, '署名 孟浩然：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-118-author' AS id, 'work-t300-118' AS subject_id, 'author.attribution' AS property_key, '署名 孟浩然：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-119-author' AS id, 'work-t300-119' AS subject_id, 'author.attribution' AS property_key, '署名 孟浩然：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-121-author' AS id, 'work-t300-121' AS subject_id, 'author.attribution' AS property_key, '署名 孟浩然：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-122-author' AS id, 'work-t300-122' AS subject_id, 'author.attribution' AS property_key, '署名 孟浩然：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-131-author' AS id, 'work-t300-131' AS subject_id, 'author.attribution' AS property_key, '署名 盧綸：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-133-author' AS id, 'work-t300-133' AS subject_id, 'author.attribution' AS property_key, '署名 王維：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-134-author' AS id, 'work-t300-134' AS subject_id, 'author.attribution' AS property_key, '署名 王維：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-135-author' AS id, 'work-t300-135' AS subject_id, 'author.attribution' AS property_key, '署名 王維：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-136-author' AS id, 'work-t300-136' AS subject_id, 'author.attribution' AS property_key, '署名 王維：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-137-author' AS id, 'work-t300-137' AS subject_id, 'author.attribution' AS property_key, '署名 王維：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-140-author' AS id, 'work-t300-140' AS subject_id, 'author.attribution' AS property_key, '署名 王維：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-142-author' AS id, 'work-t300-142' AS subject_id, 'author.attribution' AS property_key, '署名 王維：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-145-author' AS id, 'work-t300-145' AS subject_id, 'author.attribution' AS property_key, '署名 王維：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-146-author' AS id, 'work-t300-146' AS subject_id, 'author.attribution' AS property_key, '署名 王維：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-148-author' AS id, 'work-t300-148' AS subject_id, 'author.attribution' AS property_key, '署名 王維：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-151-author' AS id, 'work-t300-151' AS subject_id, 'author.attribution' AS property_key, '署名 丘爲：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-153-author' AS id, 'work-t300-153' AS subject_id, 'author.attribution' AS property_key, '署名 崔顥：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-156-author' AS id, 'work-t300-156' AS subject_id, 'author.attribution' AS property_key, '署名 祖詠：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-157-author' AS id, 'work-t300-157' AS subject_id, 'author.attribution' AS property_key, '署名 祖詠：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-158-author' AS id, 'work-t300-158' AS subject_id, 'author.attribution' AS property_key, '署名 李頎：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-159-author' AS id, 'work-t300-159' AS subject_id, 'author.attribution' AS property_key, '署名 李頎：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-160-author' AS id, 'work-t300-160' AS subject_id, 'author.attribution' AS property_key, '署名 李頎：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-161-author' AS id, 'work-t300-161' AS subject_id, 'author.attribution' AS property_key, '署名 李頎：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-162-author' AS id, 'work-t300-162' AS subject_id, 'author.attribution' AS property_key, '署名 李頎：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-164-author' AS id, 'work-t300-164' AS subject_id, 'author.attribution' AS property_key, '署名 李頎：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-165-author' AS id, 'work-t300-165' AS subject_id, 'author.attribution' AS property_key, '署名 綦毋潛：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-169-author' AS id, 'work-t300-169' AS subject_id, 'author.attribution' AS property_key, '署名 王昌齡：选本所署；维基文库《全唐詩》卷页按 ==橫吹曲辭出塞== 收录，锚点未含署名，作者归属依该卷编排体例——更弱一档。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-170-author' AS id, 'work-t300-170' AS subject_id, 'author.attribution' AS property_key, '署名 王昌齡：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-171-author' AS id, 'work-t300-171' AS subject_id, 'author.attribution' AS property_key, '署名 王昌齡：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-173-author' AS id, 'work-t300-173' AS subject_id, 'author.attribution' AS property_key, '署名 常建：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-186-author' AS id, 'work-t300-186' AS subject_id, 'author.attribution' AS property_key, '署名 溫庭筠：选本所署；维基文库《全唐詩》卷页按 ===送人東=== 收录，锚点未含署名，作者归属依该卷编排体例——更弱一档。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-189-author' AS id, 'work-t300-189' AS subject_id, 'author.attribution' AS property_key, '署名 秦韜玉：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-193-author' AS id, 'work-t300-193' AS subject_id, 'author.attribution' AS property_key, '署名 張祜：选本所署；维基文库《全唐詩》卷页按 ===宮詞二首=== 收录，锚点未含署名，作者归属依该卷编排体例——更弱一档。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-197-author' AS id, 'work-t300-197' AS subject_id, 'author.attribution' AS property_key, '署名 張祜：选本所署；维基文库《全唐詩》卷页按 ===延年不語望三星莫說夫人上涕零爭奈世間惆悵在甘泉宮夜看圖形=== 收录，锚点未含署名，作者归属依该卷编排体例——更弱一档。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-198-author' AS id, 'work-t300-198' AS subject_id, 'author.attribution' AS property_key, '署名 朱慶餘：选本所署；维基文库《全唐詩》卷页按 ===石抱龍堂蘚石乾山遮白日寺門寒長松瀑布饒奇狀曾有僊人駐鶴看=== 收录，锚点未含署名，作者归属依该卷编排体例——更弱一档。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-207-author' AS id, 'work-t300-207' AS subject_id, 'author.attribution' AS property_key, '署名 杜甫：选本所署；维基文库《全唐詩》卷页按 ==月夜== 收录，锚点未含署名，作者归属依该卷编排体例——更弱一档。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-208-author' AS id, 'work-chun-wang' AS subject_id, 'author.attribution' AS property_key, '署名 杜甫：选本所署；维基文库《全唐詩》卷页按 ==春望== 收录，锚点未含署名，作者归属依该卷编排体例——更弱一档。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-209-author' AS id, 'work-t300-209' AS subject_id, 'author.attribution' AS property_key, '署名 杜甫：选本所署；维基文库《全唐詩》卷页按 ==春宿左省== 收录，锚点未含署名，作者归属依该卷编排体例——更弱一档。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-210-author' AS id, 'work-t300-210' AS subject_id, 'author.attribution' AS property_key, '署名 杜甫：选本所署；维基文库《全唐詩》卷页按 ==因許八奉寄江甯旻上人== 收录，锚点未含署名，作者归属依该卷编排体例——更弱一档。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-211-author' AS id, 'work-t300-211' AS subject_id, 'author.attribution' AS property_key, '署名 杜甫：选本所署；维基文库《全唐詩》卷页按 ==月夜憶舍弟== 收录，锚点未含署名，作者归属依该卷编排体例——更弱一档。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-214-author' AS id, 'work-t300-214' AS subject_id, 'author.attribution' AS property_key, '署名 杜甫：选本所署；维基文库《全唐詩》卷页按 ==客至喜崔明府相過== 收录，锚点未含署名，作者归属依该卷编排体例——更弱一档。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-215-author' AS id, 'work-t300-215' AS subject_id, 'author.attribution' AS property_key, '署名 杜甫：选本与维基文库《全唐詩》卷页两处转录一致（锚点含署名：「==野望杜甫|野望==」）。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-216-author' AS id, 'work-t300-216' AS subject_id, 'author.attribution' AS property_key, '署名 杜甫：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-217-author' AS id, 'work-t300-217' AS subject_id, 'author.attribution' AS property_key, '署名 杜甫：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-220-author' AS id, 'work-t300-220' AS subject_id, 'author.attribution' AS property_key, '署名 杜甫：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-221-author' AS id, 'work-t300-221' AS subject_id, 'author.attribution' AS property_key, '署名 杜甫：选本所署；维基文库《全唐詩》卷页按 ==宿府== 收录，锚点未含署名，作者归属依该卷编排体例——更弱一档。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-231-author' AS id, 'work-t300-231' AS subject_id, 'author.attribution' AS property_key, '署名 杜甫：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-233-author' AS id, 'work-t300-233' AS subject_id, 'author.attribution' AS property_key, '署名 張九齡：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-234-author' AS id, 'work-t300-234' AS subject_id, 'author.attribution' AS property_key, '署名 宋之問：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-240-author' AS id, 'work-t300-240' AS subject_id, 'author.attribution' AS property_key, '署名 高適：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-248-author' AS id, 'work-t300-248' AS subject_id, 'author.attribution' AS property_key, '署名 杜甫：选本所署；维基文库《全唐詩》卷页按 ==夢李白二首== 收录，锚点未含署名，作者归属依该卷编排体例——更弱一档。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-252-author' AS id, 'work-t300-252' AS subject_id, 'author.attribution' AS property_key, '署名 杜甫：选本所署；维基文库《全唐詩》卷页按 ==寄韓諫議== 收录，锚点未含署名，作者归属依该卷编排体例——更弱一档。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-262-author' AS id, 'work-t300-262' AS subject_id, 'author.attribution' AS property_key, '署名 不詳：选本所署；维基文库《全唐詩》卷页按 ==雜曲歌辭金縷衣== 收录，锚点未含署名，作者归属依该卷编排体例——更弱一档。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-274-author' AS id, 'work-t300-274' AS subject_id, 'author.attribution' AS property_key, '署名 錢起：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-276-author' AS id, 'work-t300-276' AS subject_id, 'author.attribution' AS property_key, '署名 錢起：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-283-author' AS id, 'work-t300-283' AS subject_id, 'author.attribution' AS property_key, '署名 韓翃：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-284-author' AS id, 'work-t300-284' AS subject_id, 'author.attribution' AS property_key, '署名 韋應物：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-285-author' AS id, 'work-t300-285' AS subject_id, 'author.attribution' AS property_key, '署名 韋應物：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-289-author' AS id, 'work-t300-289' AS subject_id, 'author.attribution' AS property_key, '署名 韋應物：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-290-author' AS id, 'work-t300-290' AS subject_id, 'author.attribution' AS property_key, '署名 韋應物：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-291-author' AS id, 'work-t300-291' AS subject_id, 'author.attribution' AS property_key, '署名 韋應物：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-292-author' AS id, 'work-t300-292' AS subject_id, 'author.attribution' AS property_key, '署名 韋應物：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-296-author' AS id, 'work-t300-296' AS subject_id, 'author.attribution' AS property_key, '署名 岑參：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-298-author' AS id, 'work-t300-298' AS subject_id, 'author.attribution' AS property_key, '署名 岑參：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-299-author' AS id, 'work-t300-299' AS subject_id, 'author.attribution' AS property_key, '署名 岑參：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-300-author' AS id, 'work-t300-300' AS subject_id, 'author.attribution' AS property_key, '署名 岑參：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-308-author' AS id, 'work-t300-308' AS subject_id, 'author.attribution' AS property_key, '署名 李白：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-312-author' AS id, 'work-t300-312' AS subject_id, 'author.attribution' AS property_key, '署名 李白：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-320-author' AS id, 'work-t300-320' AS subject_id, 'author.attribution' AS property_key, '署名 李白：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-323-author' AS id, 'work-t300-323' AS subject_id, 'author.attribution' AS property_key, '署名 李白：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-325-author' AS id, 'work-t300-325' AS subject_id, 'author.attribution' AS property_key, '署名 李白：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-326-author' AS id, 'work-t300-326' AS subject_id, 'author.attribution' AS property_key, '署名 李白：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-328-author' AS id, 'work-t300-328' AS subject_id, 'author.attribution' AS property_key, '署名 李白：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-330-author' AS id, 'work-t300-330' AS subject_id, 'author.attribution' AS property_key, '署名 李白：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-331-author' AS id, 'work-t300-331' AS subject_id, 'author.attribution' AS property_key, '署名 李白：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-334-author' AS id, 'work-t300-334' AS subject_id, 'author.attribution' AS property_key, '署名 韋應物：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-335-author' AS id, 'work-t300-335' AS subject_id, 'author.attribution' AS property_key, '署名 李益：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-358-author' AS id, 'work-t300-358' AS subject_id, 'author.attribution' AS property_key, '署名 皇甫冉：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-360-author' AS id, 'work-t300-360' AS subject_id, 'author.attribution' AS property_key, '署名 劉方平：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-361-author' AS id, 'work-t300-361' AS subject_id, 'author.attribution' AS property_key, '署名 王之渙：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
UNION ALL
SELECT 'claim-t300-363-author' AS id, 'work-t300-363' AS subject_id, 'author.attribution' AS property_key, '署名 劉眘虛：选本与维基文库页面两处转录一致。' AS value_text, 'FACT' AS claim_kind, 'LIKELY' AS certainty
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);

INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-t300-002-author' AS claim_id, 'source-ws-t300-002' AS source_id, '页面 登幽州臺歌（header author 字段）' AS locator, 'header author=陳子昂' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-005-author' AS claim_id, 'source-ws-t300-005' AS source_id, '页面 出塞 (秦時明月漢時關)（header author 字段）' AS locator, 'header author=王昌齡' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-009-author' AS claim_id, 'source-quantangshi-301' AS source_id, '页面 全唐詩/卷301（锚点 卷301_23故行宮王建）' AS locator, '卷301_23故行宮王建' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-010-author' AS claim_id, 'source-ws-t300-010' AS source_id, '页面 錦瑟（header author 字段）' AS locator, 'header author=李商隱' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-011-author' AS claim_id, 'source-ws-t300-011' AS source_id, '页面 蟬 (李商隱)（header author 字段）' AS locator, 'header author=李商隱' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-013-author' AS claim_id, 'source-ws-t300-013' AS source_id, '页面 夜雨寄北（header author 字段）' AS locator, 'header author=李商隱' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-015-author' AS claim_id, 'source-ws-t300-015' AS source_id, '页面 風雨 (李商隱)（header author 字段）' AS locator, 'header author=李商隱' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-016-author' AS claim_id, 'source-ws-t300-016' AS source_id, '页面 寄令狐郎中（header author 字段）' AS locator, 'header author=李商隱' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-020-author' AS claim_id, 'source-quantangshi-539' AS source_id, '页面 全唐詩/卷539（卷页无 header；归属证据在锚点）' AS locator, '锚点「==無題四首_來是空言去絕蹤|無題四首==」（不含作者名）' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-022-author' AS claim_id, 'source-quantangshi-539' AS source_id, '页面 全唐詩/卷539（卷页无 header；归属证据在锚点）' AS locator, '锚点「==隋宮==」（不含作者名）' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-024-author' AS claim_id, 'source-quantangshi-539' AS source_id, '页面 全唐詩/卷539（卷页无 header；归属证据在锚点）' AS locator, '锚点「==為有==」（不含作者名）' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-025-author' AS claim_id, 'source-quantangshi-539' AS source_id, '页面 全唐詩/卷539（卷页无 header；归属证据在锚点）' AS locator, '锚点「==無題_相見時難別亦難|無題==」（不含作者名）' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-026-author' AS claim_id, 'source-quantangshi-539' AS source_id, '页面 全唐詩/卷539（卷页无 header；归属证据在锚点）' AS locator, '锚点「==瑤池==」（不含作者名）' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-028-author' AS claim_id, 'source-quantangshi-540' AS source_id, '页面 全唐詩/卷540（卷页无 header；归属证据在锚点）' AS locator, '锚点「==常娥==」（不含作者名）' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-029-author' AS claim_id, 'source-quantangshi-540' AS source_id, '页面 全唐詩/卷540（卷页无 header；归属证据在锚点）' AS locator, '锚点「==無題二首==」（不含作者名）' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-031-author' AS claim_id, 'source-quantangshi-540' AS source_id, '页面 全唐詩/卷540（卷页无 header；归属证据在锚点）' AS locator, '锚点「==賈生==」（不含作者名）' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-032-author' AS claim_id, 'source-quantangshi-540' AS source_id, '页面 全唐詩/卷540（卷页无 header；归属证据在锚点）' AS locator, '锚点「==涼思==」（不含作者名）' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-036-author' AS claim_id, 'source-quantangshi-697' AS source_id, '页面 全唐詩/卷697（卷页无 header；归属证据在锚点）' AS locator, '锚点「===金陵圖===」（不含作者名）' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-037-author' AS claim_id, 'source-quantangshi-697' AS source_id, '页面 全唐詩/卷697（卷页无 header；归属证据在锚点）' AS locator, '锚点「===台城===」（不含作者名）' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-040-author' AS claim_id, 'source-quantangshi-555' AS source_id, '页面 全唐詩/卷555（卷页无 header；归属证据在锚点）' AS locator, '锚点「===灞上秋居===」（不含作者名）' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-041-author' AS claim_id, 'source-quantangshi-557' AS source_id, '页面 全唐詩/卷557（卷页无 header；归属证据在锚点）' AS locator, '锚点「===馬嵬坡===」（不含作者名）' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-043-author' AS claim_id, 'source-ws-t300-043' AS source_id, '页面 春怨 (金昌緒)（header author 字段）' AS locator, 'header author=金昌緒' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-045-author' AS claim_id, 'source-ws-t300-045' AS source_id, '页面 遣悲懷之二（header author 字段）' AS locator, 'header author=元稹' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-047-author' AS claim_id, 'source-ws-t300-047' AS source_id, '页面 行宮（header author 字段）' AS locator, 'header author=元稹' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-048-author' AS claim_id, 'source-quantangshi-784' AS source_id, '页面 全唐詩/卷784（锚点 ==西鄙人====）' AS locator, '==西鄙人====' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-052-author' AS claim_id, 'source-ws-t300-052' AS source_id, '页面 次北固山下（header author 字段）' AS locator, 'header author=王灣' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-053-author' AS claim_id, 'source-ws-t300-053' AS source_id, '页面 桃花谿（header author 字段）' AS locator, 'header author=張旭' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-054-author' AS claim_id, 'source-ws-t300-054' AS source_id, '页面 送別 (下馬飲君酒)（header author 字段）' AS locator, 'header author=王維' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-056-author' AS claim_id, 'source-ws-t300-056' AS source_id, '页面 青谿（header author 字段）' AS locator, 'header author=王維' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-057-author' AS claim_id, 'source-ws-t300-057' AS source_id, '页面 渭川田家（header author 字段）' AS locator, 'header author=王維' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-060-author' AS claim_id, 'source-ws-t300-060' AS source_id, '页面 桃源行 (王維)（header author 字段）' AS locator, 'header author=王維' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-061-author' AS claim_id, 'source-ws-t300-061' AS source_id, '页面 洛陽女兒行（header author 字段）' AS locator, 'header author=王維' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-062-author' AS claim_id, 'source-ws-t300-062' AS source_id, '页面 輞川閑居贈裴秀才迪（header author 字段）' AS locator, 'header author=王維' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-063-author' AS claim_id, 'source-ws-t300-063' AS source_id, '页面 酬張少府（header author 字段）' AS locator, 'header author=王維' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-064-author' AS claim_id, 'source-ws-t300-064' AS source_id, '页面 送梓州李使君（header author 字段）' AS locator, 'header author=王維' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-074-author' AS claim_id, 'source-quantangshi-523' AS source_id, '页面 全唐詩/卷523（卷页无 header；归属证据在锚点）' AS locator, '锚点「===泊秦淮===」（不含作者名）' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-079-author' AS claim_id, 'source-quantangshi-525' AS source_id, '页面 全唐詩/卷525（卷页无 header；归属证据在锚点）' AS locator, '锚点「===金谷園===」（不含作者名）' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-087-author' AS claim_id, 'source-ws-t300-087' AS source_id, '页面 喜見外弟又言別（header author 字段）' AS locator, 'header author=李益' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-097-author' AS claim_id, 'source-ws-t300-097' AS source_id, '页面 新年作 (劉長卿)（header author 字段）' AS locator, 'header author=劉長卿' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-100-author' AS claim_id, 'source-ws-t300-100' AS source_id, '页面 餞別王十一南遊（header author 字段）' AS locator, 'header author=劉長卿' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-101-author' AS claim_id, 'source-ws-t300-101' AS source_id, '页面 江州重別薛六柳八二員外（header author 字段）' AS locator, 'header author=劉長卿' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-102-author' AS claim_id, 'source-ws-t300-102' AS source_id, '页面 長沙過賈誼宅（header author 字段）' AS locator, 'header author=劉長卿' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-106-author' AS claim_id, 'source-ws-t300-106' AS source_id, '页面 涼州詞 (葡萄美酒夜光杯)（header author 字段）' AS locator, 'header author=王翰' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-108-author' AS claim_id, 'source-ws-t300-108' AS source_id, '页面 夏日南亭懷辛大（header author 字段）' AS locator, 'header author=孟浩然' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-112-author' AS claim_id, 'source-ws-t300-112' AS source_id, '页面 秦中感秋寄遠上人（header author 字段）' AS locator, 'header author=孟浩然' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-117-author' AS claim_id, 'source-ws-t300-117' AS source_id, '页面 與諸子登峴山（header author 字段）' AS locator, 'header author=孟浩然' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-118-author' AS claim_id, 'source-ws-t300-118' AS source_id, '页面 過故人莊（header author 字段）' AS locator, 'header author=孟浩然' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-119-author' AS claim_id, 'source-ws-t300-119' AS source_id, '页面 歲暮歸南山（header author 字段）' AS locator, 'header author=孟浩然' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-121-author' AS claim_id, 'source-ws-t300-121' AS source_id, '页面 春曉 (孟浩然)（header author 字段）' AS locator, 'header author=孟浩然' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-122-author' AS claim_id, 'source-ws-t300-122' AS source_id, '页面 宿建德江（header author 字段）' AS locator, 'header author=孟浩然' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-131-author' AS claim_id, 'source-ws-t300-131' AS source_id, '页面 晚次鄂州（header author 字段）' AS locator, 'header author=盧綸' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-133-author' AS claim_id, 'source-ws-t300-133' AS source_id, '页面 過香積寺（header author 字段）' AS locator, 'header author=王維' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-134-author' AS claim_id, 'source-ws-t300-134' AS source_id, '页面 山居秋暝（header author 字段）' AS locator, 'header author=王維' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-135-author' AS claim_id, 'source-ws-t300-135' AS source_id, '页面 終南別業（header author 字段）' AS locator, 'header author=王維' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-136-author' AS claim_id, 'source-ws-t300-136' AS source_id, '页面 歸嵩山作（header author 字段）' AS locator, 'header author=王維' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-137-author' AS claim_id, 'source-ws-t300-137' AS source_id, '页面 終南山 (王維)（header author 字段）' AS locator, 'header author=王維' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-140-author' AS claim_id, 'source-ws-t300-140' AS source_id, '页面 和賈舍人早朝大明宮之作（header author 字段）' AS locator, 'header author=王維' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-142-author' AS claim_id, 'source-ws-t300-142' AS source_id, '页面 積雨輞川莊作（header author 字段）' AS locator, 'header author=王維' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-145-author' AS claim_id, 'source-ws-t300-145' AS source_id, '页面 送別 (山中相送罷)（header author 字段）' AS locator, 'header author=王維' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-146-author' AS claim_id, 'source-ws-t300-146' AS source_id, '页面 雜詩 (君自故鄉來)（header author 字段）' AS locator, 'header author=王維' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-148-author' AS claim_id, 'source-ws-t300-148' AS source_id, '页面 九月九日憶山東兄弟（header author 字段）' AS locator, 'header author=王維' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-151-author' AS claim_id, 'source-ws-t300-151' AS source_id, '页面 尋西山隱者不遇（header author 字段）' AS locator, 'header author=丘爲' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-153-author' AS claim_id, 'source-ws-t300-153' AS source_id, '页面 行經華陰（header author 字段）' AS locator, 'header author=崔顥' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-156-author' AS claim_id, 'source-ws-t300-156' AS source_id, '页面 望薊門（header author 字段）' AS locator, 'header author=祖詠' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-157-author' AS claim_id, 'source-ws-t300-157' AS source_id, '页面 終南望餘雪（header author 字段）' AS locator, 'header author=祖詠' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-158-author' AS claim_id, 'source-ws-t300-158' AS source_id, '页面 古從軍行（header author 字段）' AS locator, 'header author=李頎' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-159-author' AS claim_id, 'source-ws-t300-159' AS source_id, '页面 琴歌 (李頎)（header author 字段）' AS locator, 'header author=李頎' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-160-author' AS claim_id, 'source-ws-t300-160' AS source_id, '页面 送陳章甫（header author 字段）' AS locator, 'header author=李頎' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-161-author' AS claim_id, 'source-ws-t300-161' AS source_id, '页面 聽安萬善吹觱篥歌（header author 字段）' AS locator, 'header author=李頎' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-162-author' AS claim_id, 'source-ws-t300-162' AS source_id, '页面 古意 (李頎)（header author 字段）' AS locator, 'header author=李頎' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-164-author' AS claim_id, 'source-ws-t300-164' AS source_id, '页面 送魏萬之京（header author 字段）' AS locator, 'header author=李頎' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-165-author' AS claim_id, 'source-ws-t300-165' AS source_id, '页面 春泛若耶溪（header author 字段）' AS locator, 'header author=綦毋潜' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-169-author' AS claim_id, 'source-quantangshi-18' AS source_id, '页面 全唐詩/卷018（卷页无 header；归属证据在锚点）' AS locator, '锚点「==橫吹曲辭出塞==」（不含作者名）' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-170-author' AS claim_id, 'source-ws-t300-170' AS source_id, '页面 春宮曲（header author 字段）' AS locator, 'header author=王昌齡' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-171-author' AS claim_id, 'source-ws-t300-171' AS source_id, '页面 閨怨 (王昌齡)（header author 字段）' AS locator, 'header author=王昌齡' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-173-author' AS claim_id, 'source-ws-t300-173' AS source_id, '页面 宿王昌齡隱居（header author 字段）' AS locator, 'header author=常建' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-186-author' AS claim_id, 'source-quantangshi-581' AS source_id, '页面 全唐詩/卷581（卷页无 header；归属证据在锚点）' AS locator, '锚点「===送人東===」（不含作者名）' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-189-author' AS claim_id, 'source-ws-t300-189' AS source_id, '页面 貧女(秦韜玉)（header author 字段）' AS locator, 'header author=秦韜玉' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-193-author' AS claim_id, 'source-quantangshi-511' AS source_id, '页面 全唐詩/卷511（卷页无 header；归属证据在锚点）' AS locator, '锚点「===宮詞二首===」（不含作者名）' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-197-author' AS claim_id, 'source-quantangshi-511' AS source_id, '页面 全唐詩/卷511（卷页无 header；归属证据在锚点）' AS locator, '锚点「===延年不語望三星莫說夫人上涕零爭奈世間惆悵在甘泉宮夜看圖形===」（不含作者名）' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-198-author' AS claim_id, 'source-quantangshi-514' AS source_id, '页面 全唐詩/卷514（卷页无 header；归属证据在锚点）' AS locator, '锚点「===石抱龍堂蘚石乾山遮白日寺門寒長松瀑布饒奇狀曾有僊人駐鶴看===」（不含作者名）' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-207-author' AS claim_id, 'source-quantangshi-224' AS source_id, '页面 全唐詩/卷224（卷页无 header；归属证据在锚点）' AS locator, '锚点「==月夜==」（不含作者名）' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-208-author' AS claim_id, 'source-quantangshi-224' AS source_id, '页面 全唐詩/卷224（卷页无 header；归属证据在锚点）' AS locator, '锚点「==春望==」（不含作者名）' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-209-author' AS claim_id, 'source-quantangshi-225' AS source_id, '页面 全唐詩/卷225（卷页无 header；归属证据在锚点）' AS locator, '锚点「==春宿左省==」（不含作者名）' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-210-author' AS claim_id, 'source-quantangshi-225' AS source_id, '页面 全唐詩/卷225（卷页无 header；归属证据在锚点）' AS locator, '锚点「==因許八奉寄江甯旻上人==」（不含作者名）' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-211-author' AS claim_id, 'source-quantangshi-225' AS source_id, '页面 全唐詩/卷225（卷页无 header；归属证据在锚点）' AS locator, '锚点「==月夜憶舍弟==」（不含作者名）' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-214-author' AS claim_id, 'source-quantangshi-226' AS source_id, '页面 全唐詩/卷226（卷页无 header；归属证据在锚点）' AS locator, '锚点「==客至喜崔明府相過==」（不含作者名）' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-215-author' AS claim_id, 'source-quantangshi-227' AS source_id, '页面 全唐詩/卷227（锚点 ==野望杜甫|野望==）' AS locator, '==野望杜甫|野望==' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-216-author' AS claim_id, 'source-ws-t300-216' AS source_id, '页面 奉濟驛重送嚴公四韻（header author 字段）' AS locator, 'header author=杜甫' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-217-author' AS claim_id, 'source-ws-t300-217' AS source_id, '页面 聞官軍收河南河北（header author 字段）' AS locator, 'header author=杜甫' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-220-author' AS claim_id, 'source-ws-t300-220' AS source_id, '页面 登樓 (杜甫)（header author 字段）' AS locator, 'header author=杜甫' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-221-author' AS claim_id, 'source-quantangshi-228' AS source_id, '页面 全唐詩/卷228（卷页无 header；归属证据在锚点）' AS locator, '锚点「==宿府==」（不含作者名）' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-231-author' AS claim_id, 'source-ws-t300-231' AS source_id, '页面 登岳陽樓 (杜甫)（header author 字段）' AS locator, 'header author=杜甫' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-233-author' AS claim_id, 'source-ws-t300-233' AS source_id, '页面 望月懷遠（header author 字段）' AS locator, 'header author=張九齡' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-234-author' AS claim_id, 'source-ws-t300-234' AS source_id, '页面 題大庾嶺北驛（header author 字段）' AS locator, 'header author=宋之問' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-240-author' AS claim_id, 'source-ws-t300-240' AS source_id, '页面 送李少府貶峽中王少府貶長沙（header author 字段）' AS locator, 'header author=高適' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-248-author' AS claim_id, 'source-quantangshi-218' AS source_id, '页面 全唐詩/卷218（卷页无 header；归属证据在锚点）' AS locator, '锚点「==夢李白二首==」（不含作者名）' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-252-author' AS claim_id, 'source-quantangshi-220' AS source_id, '页面 全唐詩/卷220（卷页无 header；归属证据在锚点）' AS locator, '锚点「==寄韓諫議==」（不含作者名）' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-262-author' AS claim_id, 'source-quantangshi-28' AS source_id, '页面 全唐詩/卷028（卷页无 header；归属证据在锚点）' AS locator, '锚点「==雜曲歌辭金縷衣==」（不含作者名）' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-274-author' AS claim_id, 'source-ws-t300-274' AS source_id, '页面 谷口書齋寄楊補闕（header author 字段）' AS locator, 'header author=錢起' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-276-author' AS claim_id, 'source-ws-t300-276' AS source_id, '页面 贈闕下裴舍人（header author 字段）' AS locator, 'header author=錢起' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-283-author' AS claim_id, 'source-ws-t300-283' AS source_id, '页面 寒食 (韓翃)（header author 字段）' AS locator, 'header author=韓翃' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-284-author' AS claim_id, 'source-ws-t300-284' AS source_id, '页面 寄李儋元錫（header author 字段）' AS locator, 'header author=韋應物' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-285-author' AS claim_id, 'source-ws-t300-285' AS source_id, '页面 寄全椒山中道士（header author 字段）' AS locator, 'header author=韋應物' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-289-author' AS claim_id, 'source-ws-t300-289' AS source_id, '页面 長安遇馮著（header author 字段）' AS locator, 'header author=韋應物' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-290-author' AS claim_id, 'source-ws-t300-290' AS source_id, '页面 夕次盱眙縣（header author 字段）' AS locator, 'header author=韋應物' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-291-author' AS claim_id, 'source-ws-t300-291' AS source_id, '页面 東郊（header author 字段）' AS locator, 'header author=韋應物' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-292-author' AS claim_id, 'source-ws-t300-292' AS source_id, '页面 滁州西澗（header author 字段）' AS locator, 'header author=韋應物' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-296-author' AS claim_id, 'source-ws-t300-296' AS source_id, '页面 輪臺歌奉送封大夫出師西征（header author 字段）' AS locator, 'header author=岑參' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-298-author' AS claim_id, 'source-ws-t300-298' AS source_id, '页面 寄左省杜拾遺（header author 字段）' AS locator, 'header author=岑參' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-299-author' AS claim_id, 'source-ws-t300-299' AS source_id, '页面 奉和中書舍人賈至早朝大明宮（header author 字段）' AS locator, 'header author=岑參' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-300-author' AS claim_id, 'source-ws-t300-300' AS source_id, '页面 逢入京使（header author 字段）' AS locator, 'header author=岑參' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-308-author' AS claim_id, 'source-ws-t300-308' AS source_id, '页面 玉階怨 (李白)（header author 字段）' AS locator, 'header author=李白' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-312-author' AS claim_id, 'source-ws-t300-312' AS source_id, '页面 春思 (李白)（header author 字段）' AS locator, 'header author=李白' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-320-author' AS claim_id, 'source-ws-t300-320' AS source_id, '页面 金陵酒肆留別（header author 字段）' AS locator, 'header author=李白' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-323-author' AS claim_id, 'source-ws-t300-323' AS source_id, '页面 送友人 (李白)（header author 字段）' AS locator, 'header author=李白' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-325-author' AS claim_id, 'source-ws-t300-325' AS source_id, '页面 下終南山過斛斯山人宿置酒（header author 字段）' AS locator, 'header author=李白' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-326-author' AS claim_id, 'source-ws-t300-326' AS source_id, '页面 登金陵鳳凰臺（header author 字段）' AS locator, 'header author=李白' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-328-author' AS claim_id, 'source-ws-t300-328' AS source_id, '页面 夜泊牛渚懷古（header author 字段）' AS locator, 'header author=李白' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-330-author' AS claim_id, 'source-ws-t300-330' AS source_id, '页面 聽蜀僧濬彈琴（header author 字段）' AS locator, 'header author=李白' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-331-author' AS claim_id, 'source-ws-t300-331' AS source_id, '页面 怨情 (美人捲珠簾)（header author 字段）' AS locator, 'header author=李白' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-334-author' AS claim_id, 'source-ws-t300-334' AS source_id, '页面 初發揚子寄元大校書（header author 字段）' AS locator, 'header author=韋應物' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-335-author' AS claim_id, 'source-ws-t300-335' AS source_id, '页面 江南曲 (嫁得瞿塘賈)（header author 字段）' AS locator, 'header author=李益' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-358-author' AS claim_id, 'source-ws-t300-358' AS source_id, '页面 春思 (皇甫冉)（header author 字段）' AS locator, 'header author=皇甫冉' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-360-author' AS claim_id, 'source-ws-t300-360' AS source_id, '页面 春怨 (劉方平)（header author 字段）' AS locator, 'header author=劉方平' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-361-author' AS claim_id, 'source-ws-t300-361' AS source_id, '页面 登鸛雀樓 (王之渙)（header author 字段）' AS locator, 'header author=王之渙' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-363-author' AS claim_id, 'source-ws-t300-363' AS source_id, '页面 闕題 (劉眘虛)（header author 字段）' AS locator, 'header author=劉眘虛' AS evidence_excerpt
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

INSERT INTO poetry_work_author (work_id, person_id, attribution, claim_id)
SELECT * FROM (
SELECT 'work-t300-002' AS work_id, 'person-tang-chen-ziang' AS person_id, 'PENDING' AS attribution, 'claim-t300-002-author' AS claim_id
UNION ALL
SELECT 'work-t300-005' AS work_id, 'person-tang-wang-changling' AS person_id, 'PENDING' AS attribution, 'claim-t300-005-author' AS claim_id
UNION ALL
SELECT 'work-t300-009' AS work_id, 'person-tang-wang-jian' AS person_id, 'PENDING' AS attribution, 'claim-t300-009-author' AS claim_id
UNION ALL
SELECT 'work-t300-010' AS work_id, 'person-tang-li-shangyin' AS person_id, 'PENDING' AS attribution, 'claim-t300-010-author' AS claim_id
UNION ALL
SELECT 'work-t300-011' AS work_id, 'person-tang-li-shangyin' AS person_id, 'PENDING' AS attribution, 'claim-t300-011-author' AS claim_id
UNION ALL
SELECT 'work-t300-013' AS work_id, 'person-tang-li-shangyin' AS person_id, 'PENDING' AS attribution, 'claim-t300-013-author' AS claim_id
UNION ALL
SELECT 'work-t300-015' AS work_id, 'person-tang-li-shangyin' AS person_id, 'PENDING' AS attribution, 'claim-t300-015-author' AS claim_id
UNION ALL
SELECT 'work-t300-016' AS work_id, 'person-tang-li-shangyin' AS person_id, 'PENDING' AS attribution, 'claim-t300-016-author' AS claim_id
UNION ALL
SELECT 'work-t300-020' AS work_id, 'person-tang-li-shangyin' AS person_id, 'PENDING' AS attribution, 'claim-t300-020-author' AS claim_id
UNION ALL
SELECT 'work-t300-022' AS work_id, 'person-tang-li-shangyin' AS person_id, 'PENDING' AS attribution, 'claim-t300-022-author' AS claim_id
UNION ALL
SELECT 'work-t300-024' AS work_id, 'person-tang-li-shangyin' AS person_id, 'PENDING' AS attribution, 'claim-t300-024-author' AS claim_id
UNION ALL
SELECT 'work-t300-025' AS work_id, 'person-tang-li-shangyin' AS person_id, 'PENDING' AS attribution, 'claim-t300-025-author' AS claim_id
UNION ALL
SELECT 'work-t300-026' AS work_id, 'person-tang-li-shangyin' AS person_id, 'PENDING' AS attribution, 'claim-t300-026-author' AS claim_id
UNION ALL
SELECT 'work-t300-028' AS work_id, 'person-tang-li-shangyin' AS person_id, 'PENDING' AS attribution, 'claim-t300-028-author' AS claim_id
UNION ALL
SELECT 'work-t300-029' AS work_id, 'person-tang-li-shangyin' AS person_id, 'PENDING' AS attribution, 'claim-t300-029-author' AS claim_id
UNION ALL
SELECT 'work-t300-031' AS work_id, 'person-tang-li-shangyin' AS person_id, 'PENDING' AS attribution, 'claim-t300-031-author' AS claim_id
UNION ALL
SELECT 'work-t300-032' AS work_id, 'person-tang-li-shangyin' AS person_id, 'PENDING' AS attribution, 'claim-t300-032-author' AS claim_id
UNION ALL
SELECT 'work-t300-036' AS work_id, 'person-tang-wei-zhuang' AS person_id, 'PENDING' AS attribution, 'claim-t300-036-author' AS claim_id
UNION ALL
SELECT 'work-t300-037' AS work_id, 'person-tang-wei-zhuang' AS person_id, 'PENDING' AS attribution, 'claim-t300-037-author' AS claim_id
UNION ALL
SELECT 'work-t300-040' AS work_id, 'person-tang-ma-dai' AS person_id, 'PENDING' AS attribution, 'claim-t300-040-author' AS claim_id
UNION ALL
SELECT 'work-t300-041' AS work_id, 'person-tang-zheng-tian' AS person_id, 'PENDING' AS attribution, 'claim-t300-041-author' AS claim_id
UNION ALL
SELECT 'work-t300-043' AS work_id, 'person-tang-jin-changxu' AS person_id, 'PENDING' AS attribution, 'claim-t300-043-author' AS claim_id
UNION ALL
SELECT 'work-t300-045' AS work_id, 'person-tang-yuan-zhen' AS person_id, 'PENDING' AS attribution, 'claim-t300-045-author' AS claim_id
UNION ALL
SELECT 'work-t300-047' AS work_id, 'person-tang-yuan-zhen' AS person_id, 'PENDING' AS attribution, 'claim-t300-047-author' AS claim_id
UNION ALL
SELECT 'work-t300-048' AS work_id, 'person-tang-xibi-ren' AS person_id, 'PENDING' AS attribution, 'claim-t300-048-author' AS claim_id
UNION ALL
SELECT 'work-t300-052' AS work_id, 'person-tang-wang-wan' AS person_id, 'PENDING' AS attribution, 'claim-t300-052-author' AS claim_id
UNION ALL
SELECT 'work-t300-053' AS work_id, 'person-tang-zhang-xu' AS person_id, 'PENDING' AS attribution, 'claim-t300-053-author' AS claim_id
UNION ALL
SELECT 'work-t300-054' AS work_id, 'person-tang-wang-wei' AS person_id, 'PENDING' AS attribution, 'claim-t300-054-author' AS claim_id
UNION ALL
SELECT 'work-t300-056' AS work_id, 'person-tang-wang-wei' AS person_id, 'PENDING' AS attribution, 'claim-t300-056-author' AS claim_id
UNION ALL
SELECT 'work-t300-057' AS work_id, 'person-tang-wang-wei' AS person_id, 'PENDING' AS attribution, 'claim-t300-057-author' AS claim_id
UNION ALL
SELECT 'work-t300-060' AS work_id, 'person-tang-wang-wei' AS person_id, 'PENDING' AS attribution, 'claim-t300-060-author' AS claim_id
UNION ALL
SELECT 'work-t300-061' AS work_id, 'person-tang-wang-wei' AS person_id, 'PENDING' AS attribution, 'claim-t300-061-author' AS claim_id
UNION ALL
SELECT 'work-t300-062' AS work_id, 'person-tang-wang-wei' AS person_id, 'PENDING' AS attribution, 'claim-t300-062-author' AS claim_id
UNION ALL
SELECT 'work-t300-063' AS work_id, 'person-tang-wang-wei' AS person_id, 'PENDING' AS attribution, 'claim-t300-063-author' AS claim_id
UNION ALL
SELECT 'work-t300-064' AS work_id, 'person-tang-wang-wei' AS person_id, 'PENDING' AS attribution, 'claim-t300-064-author' AS claim_id
UNION ALL
SELECT 'work-t300-074' AS work_id, 'person-tang-du-mu' AS person_id, 'PENDING' AS attribution, 'claim-t300-074-author' AS claim_id
UNION ALL
SELECT 'work-t300-079' AS work_id, 'person-tang-du-mu' AS person_id, 'PENDING' AS attribution, 'claim-t300-079-author' AS claim_id
UNION ALL
SELECT 'work-t300-087' AS work_id, 'person-tang-li-yi' AS person_id, 'PENDING' AS attribution, 'claim-t300-087-author' AS claim_id
UNION ALL
SELECT 'work-t300-097' AS work_id, 'person-tang-liu-changqing' AS person_id, 'PENDING' AS attribution, 'claim-t300-097-author' AS claim_id
UNION ALL
SELECT 'work-t300-100' AS work_id, 'person-tang-liu-changqing' AS person_id, 'PENDING' AS attribution, 'claim-t300-100-author' AS claim_id
UNION ALL
SELECT 'work-t300-101' AS work_id, 'person-tang-liu-changqing' AS person_id, 'PENDING' AS attribution, 'claim-t300-101-author' AS claim_id
UNION ALL
SELECT 'work-t300-102' AS work_id, 'person-tang-liu-changqing' AS person_id, 'PENDING' AS attribution, 'claim-t300-102-author' AS claim_id
UNION ALL
SELECT 'work-t300-106' AS work_id, 'person-tang-wang-han' AS person_id, 'PENDING' AS attribution, 'claim-t300-106-author' AS claim_id
UNION ALL
SELECT 'work-t300-108' AS work_id, 'person-tang-meng-haoran' AS person_id, 'PENDING' AS attribution, 'claim-t300-108-author' AS claim_id
UNION ALL
SELECT 'work-t300-112' AS work_id, 'person-tang-meng-haoran' AS person_id, 'PENDING' AS attribution, 'claim-t300-112-author' AS claim_id
UNION ALL
SELECT 'work-t300-117' AS work_id, 'person-tang-meng-haoran' AS person_id, 'PENDING' AS attribution, 'claim-t300-117-author' AS claim_id
UNION ALL
SELECT 'work-t300-118' AS work_id, 'person-tang-meng-haoran' AS person_id, 'PENDING' AS attribution, 'claim-t300-118-author' AS claim_id
UNION ALL
SELECT 'work-t300-119' AS work_id, 'person-tang-meng-haoran' AS person_id, 'PENDING' AS attribution, 'claim-t300-119-author' AS claim_id
UNION ALL
SELECT 'work-t300-121' AS work_id, 'person-tang-meng-haoran' AS person_id, 'PENDING' AS attribution, 'claim-t300-121-author' AS claim_id
UNION ALL
SELECT 'work-t300-122' AS work_id, 'person-tang-meng-haoran' AS person_id, 'PENDING' AS attribution, 'claim-t300-122-author' AS claim_id
UNION ALL
SELECT 'work-t300-131' AS work_id, 'person-tang-lu-lun' AS person_id, 'PENDING' AS attribution, 'claim-t300-131-author' AS claim_id
UNION ALL
SELECT 'work-t300-133' AS work_id, 'person-tang-wang-wei' AS person_id, 'PENDING' AS attribution, 'claim-t300-133-author' AS claim_id
UNION ALL
SELECT 'work-t300-134' AS work_id, 'person-tang-wang-wei' AS person_id, 'PENDING' AS attribution, 'claim-t300-134-author' AS claim_id
UNION ALL
SELECT 'work-t300-135' AS work_id, 'person-tang-wang-wei' AS person_id, 'PENDING' AS attribution, 'claim-t300-135-author' AS claim_id
UNION ALL
SELECT 'work-t300-136' AS work_id, 'person-tang-wang-wei' AS person_id, 'PENDING' AS attribution, 'claim-t300-136-author' AS claim_id
UNION ALL
SELECT 'work-t300-137' AS work_id, 'person-tang-wang-wei' AS person_id, 'PENDING' AS attribution, 'claim-t300-137-author' AS claim_id
UNION ALL
SELECT 'work-t300-140' AS work_id, 'person-tang-wang-wei' AS person_id, 'PENDING' AS attribution, 'claim-t300-140-author' AS claim_id
UNION ALL
SELECT 'work-t300-142' AS work_id, 'person-tang-wang-wei' AS person_id, 'PENDING' AS attribution, 'claim-t300-142-author' AS claim_id
UNION ALL
SELECT 'work-t300-145' AS work_id, 'person-tang-wang-wei' AS person_id, 'PENDING' AS attribution, 'claim-t300-145-author' AS claim_id
UNION ALL
SELECT 'work-t300-146' AS work_id, 'person-tang-wang-wei' AS person_id, 'PENDING' AS attribution, 'claim-t300-146-author' AS claim_id
UNION ALL
SELECT 'work-t300-148' AS work_id, 'person-tang-wang-wei' AS person_id, 'PENDING' AS attribution, 'claim-t300-148-author' AS claim_id
UNION ALL
SELECT 'work-t300-151' AS work_id, 'person-tang-qiu-wei' AS person_id, 'PENDING' AS attribution, 'claim-t300-151-author' AS claim_id
UNION ALL
SELECT 'work-t300-153' AS work_id, 'person-tang-cui-hao' AS person_id, 'PENDING' AS attribution, 'claim-t300-153-author' AS claim_id
UNION ALL
SELECT 'work-t300-156' AS work_id, 'person-tang-zu-yong' AS person_id, 'PENDING' AS attribution, 'claim-t300-156-author' AS claim_id
UNION ALL
SELECT 'work-t300-157' AS work_id, 'person-tang-zu-yong' AS person_id, 'PENDING' AS attribution, 'claim-t300-157-author' AS claim_id
UNION ALL
SELECT 'work-t300-158' AS work_id, 'person-tang-li-qi' AS person_id, 'PENDING' AS attribution, 'claim-t300-158-author' AS claim_id
UNION ALL
SELECT 'work-t300-159' AS work_id, 'person-tang-li-qi' AS person_id, 'PENDING' AS attribution, 'claim-t300-159-author' AS claim_id
UNION ALL
SELECT 'work-t300-160' AS work_id, 'person-tang-li-qi' AS person_id, 'PENDING' AS attribution, 'claim-t300-160-author' AS claim_id
UNION ALL
SELECT 'work-t300-161' AS work_id, 'person-tang-li-qi' AS person_id, 'PENDING' AS attribution, 'claim-t300-161-author' AS claim_id
UNION ALL
SELECT 'work-t300-162' AS work_id, 'person-tang-li-qi' AS person_id, 'PENDING' AS attribution, 'claim-t300-162-author' AS claim_id
UNION ALL
SELECT 'work-t300-164' AS work_id, 'person-tang-li-qi' AS person_id, 'PENDING' AS attribution, 'claim-t300-164-author' AS claim_id
UNION ALL
SELECT 'work-t300-165' AS work_id, 'person-tang-qi-wu-qian' AS person_id, 'PENDING' AS attribution, 'claim-t300-165-author' AS claim_id
UNION ALL
SELECT 'work-t300-169' AS work_id, 'person-tang-wang-changling' AS person_id, 'PENDING' AS attribution, 'claim-t300-169-author' AS claim_id
UNION ALL
SELECT 'work-t300-170' AS work_id, 'person-tang-wang-changling' AS person_id, 'PENDING' AS attribution, 'claim-t300-170-author' AS claim_id
UNION ALL
SELECT 'work-t300-171' AS work_id, 'person-tang-wang-changling' AS person_id, 'PENDING' AS attribution, 'claim-t300-171-author' AS claim_id
UNION ALL
SELECT 'work-t300-173' AS work_id, 'person-tang-chang-jian' AS person_id, 'PENDING' AS attribution, 'claim-t300-173-author' AS claim_id
UNION ALL
SELECT 'work-t300-186' AS work_id, 'person-tang-wen-tingyun' AS person_id, 'PENDING' AS attribution, 'claim-t300-186-author' AS claim_id
UNION ALL
SELECT 'work-t300-189' AS work_id, 'person-tang-qin-taoyu' AS person_id, 'PENDING' AS attribution, 'claim-t300-189-author' AS claim_id
UNION ALL
SELECT 'work-t300-193' AS work_id, 'person-tang-zhang-hu' AS person_id, 'PENDING' AS attribution, 'claim-t300-193-author' AS claim_id
UNION ALL
SELECT 'work-t300-197' AS work_id, 'person-tang-zhang-hu' AS person_id, 'PENDING' AS attribution, 'claim-t300-197-author' AS claim_id
UNION ALL
SELECT 'work-t300-198' AS work_id, 'person-tang-zhu-qingyu' AS person_id, 'PENDING' AS attribution, 'claim-t300-198-author' AS claim_id
UNION ALL
SELECT 'work-t300-207' AS work_id, 'person-du-fu' AS person_id, 'PENDING' AS attribution, 'claim-t300-207-author' AS claim_id
UNION ALL
SELECT 'work-t300-209' AS work_id, 'person-du-fu' AS person_id, 'PENDING' AS attribution, 'claim-t300-209-author' AS claim_id
UNION ALL
SELECT 'work-t300-210' AS work_id, 'person-du-fu' AS person_id, 'PENDING' AS attribution, 'claim-t300-210-author' AS claim_id
UNION ALL
SELECT 'work-t300-211' AS work_id, 'person-du-fu' AS person_id, 'PENDING' AS attribution, 'claim-t300-211-author' AS claim_id
UNION ALL
SELECT 'work-t300-214' AS work_id, 'person-du-fu' AS person_id, 'PENDING' AS attribution, 'claim-t300-214-author' AS claim_id
UNION ALL
SELECT 'work-t300-215' AS work_id, 'person-du-fu' AS person_id, 'PENDING' AS attribution, 'claim-t300-215-author' AS claim_id
UNION ALL
SELECT 'work-t300-216' AS work_id, 'person-du-fu' AS person_id, 'PENDING' AS attribution, 'claim-t300-216-author' AS claim_id
UNION ALL
SELECT 'work-t300-217' AS work_id, 'person-du-fu' AS person_id, 'PENDING' AS attribution, 'claim-t300-217-author' AS claim_id
UNION ALL
SELECT 'work-t300-220' AS work_id, 'person-du-fu' AS person_id, 'PENDING' AS attribution, 'claim-t300-220-author' AS claim_id
UNION ALL
SELECT 'work-t300-221' AS work_id, 'person-du-fu' AS person_id, 'PENDING' AS attribution, 'claim-t300-221-author' AS claim_id
UNION ALL
SELECT 'work-t300-231' AS work_id, 'person-du-fu' AS person_id, 'PENDING' AS attribution, 'claim-t300-231-author' AS claim_id
UNION ALL
SELECT 'work-t300-233' AS work_id, 'person-tang-zhang-jiuling' AS person_id, 'PENDING' AS attribution, 'claim-t300-233-author' AS claim_id
UNION ALL
SELECT 'work-t300-234' AS work_id, 'person-tang-song-zhiwen' AS person_id, 'PENDING' AS attribution, 'claim-t300-234-author' AS claim_id
UNION ALL
SELECT 'work-t300-240' AS work_id, 'person-tang-gao-shi' AS person_id, 'PENDING' AS attribution, 'claim-t300-240-author' AS claim_id
UNION ALL
SELECT 'work-t300-248' AS work_id, 'person-du-fu' AS person_id, 'PENDING' AS attribution, 'claim-t300-248-author' AS claim_id
UNION ALL
SELECT 'work-t300-252' AS work_id, 'person-du-fu' AS person_id, 'PENDING' AS attribution, 'claim-t300-252-author' AS claim_id
UNION ALL
SELECT 'work-t300-262' AS work_id, 'person-tang-anon' AS person_id, 'PENDING' AS attribution, 'claim-t300-262-author' AS claim_id
UNION ALL
SELECT 'work-t300-274' AS work_id, 'person-tang-qian-qi' AS person_id, 'PENDING' AS attribution, 'claim-t300-274-author' AS claim_id
UNION ALL
SELECT 'work-t300-276' AS work_id, 'person-tang-qian-qi' AS person_id, 'PENDING' AS attribution, 'claim-t300-276-author' AS claim_id
UNION ALL
SELECT 'work-t300-283' AS work_id, 'person-tang-han-hong' AS person_id, 'PENDING' AS attribution, 'claim-t300-283-author' AS claim_id
UNION ALL
SELECT 'work-t300-284' AS work_id, 'person-tang-wei-yingwu' AS person_id, 'PENDING' AS attribution, 'claim-t300-284-author' AS claim_id
UNION ALL
SELECT 'work-t300-285' AS work_id, 'person-tang-wei-yingwu' AS person_id, 'PENDING' AS attribution, 'claim-t300-285-author' AS claim_id
UNION ALL
SELECT 'work-t300-289' AS work_id, 'person-tang-wei-yingwu' AS person_id, 'PENDING' AS attribution, 'claim-t300-289-author' AS claim_id
UNION ALL
SELECT 'work-t300-290' AS work_id, 'person-tang-wei-yingwu' AS person_id, 'PENDING' AS attribution, 'claim-t300-290-author' AS claim_id
UNION ALL
SELECT 'work-t300-291' AS work_id, 'person-tang-wei-yingwu' AS person_id, 'PENDING' AS attribution, 'claim-t300-291-author' AS claim_id
UNION ALL
SELECT 'work-t300-292' AS work_id, 'person-tang-wei-yingwu' AS person_id, 'PENDING' AS attribution, 'claim-t300-292-author' AS claim_id
UNION ALL
SELECT 'work-t300-296' AS work_id, 'person-tang-cen-shen' AS person_id, 'PENDING' AS attribution, 'claim-t300-296-author' AS claim_id
UNION ALL
SELECT 'work-t300-298' AS work_id, 'person-tang-cen-shen' AS person_id, 'PENDING' AS attribution, 'claim-t300-298-author' AS claim_id
UNION ALL
SELECT 'work-t300-299' AS work_id, 'person-tang-cen-shen' AS person_id, 'PENDING' AS attribution, 'claim-t300-299-author' AS claim_id
UNION ALL
SELECT 'work-t300-300' AS work_id, 'person-tang-cen-shen' AS person_id, 'PENDING' AS attribution, 'claim-t300-300-author' AS claim_id
UNION ALL
SELECT 'work-t300-308' AS work_id, 'person-tang-li-bai' AS person_id, 'PENDING' AS attribution, 'claim-t300-308-author' AS claim_id
UNION ALL
SELECT 'work-t300-312' AS work_id, 'person-tang-li-bai' AS person_id, 'PENDING' AS attribution, 'claim-t300-312-author' AS claim_id
UNION ALL
SELECT 'work-t300-320' AS work_id, 'person-tang-li-bai' AS person_id, 'PENDING' AS attribution, 'claim-t300-320-author' AS claim_id
UNION ALL
SELECT 'work-t300-323' AS work_id, 'person-tang-li-bai' AS person_id, 'PENDING' AS attribution, 'claim-t300-323-author' AS claim_id
UNION ALL
SELECT 'work-t300-325' AS work_id, 'person-tang-li-bai' AS person_id, 'PENDING' AS attribution, 'claim-t300-325-author' AS claim_id
UNION ALL
SELECT 'work-t300-326' AS work_id, 'person-tang-li-bai' AS person_id, 'PENDING' AS attribution, 'claim-t300-326-author' AS claim_id
UNION ALL
SELECT 'work-t300-328' AS work_id, 'person-tang-li-bai' AS person_id, 'PENDING' AS attribution, 'claim-t300-328-author' AS claim_id
UNION ALL
SELECT 'work-t300-330' AS work_id, 'person-tang-li-bai' AS person_id, 'PENDING' AS attribution, 'claim-t300-330-author' AS claim_id
UNION ALL
SELECT 'work-t300-331' AS work_id, 'person-tang-li-bai' AS person_id, 'PENDING' AS attribution, 'claim-t300-331-author' AS claim_id
UNION ALL
SELECT 'work-t300-334' AS work_id, 'person-tang-wei-yingwu' AS person_id, 'PENDING' AS attribution, 'claim-t300-334-author' AS claim_id
UNION ALL
SELECT 'work-t300-335' AS work_id, 'person-tang-li-yi' AS person_id, 'PENDING' AS attribution, 'claim-t300-335-author' AS claim_id
UNION ALL
SELECT 'work-t300-358' AS work_id, 'person-tang-huangfu-ran' AS person_id, 'PENDING' AS attribution, 'claim-t300-358-author' AS claim_id
UNION ALL
SELECT 'work-t300-360' AS work_id, 'person-tang-liu-fangping' AS person_id, 'PENDING' AS attribution, 'claim-t300-360-author' AS claim_id
UNION ALL
SELECT 'work-t300-361' AS work_id, 'person-tang-wang-zhihuan' AS person_id, 'PENDING' AS attribution, 'claim-t300-361-author' AS claim_id
UNION ALL
SELECT 'work-t300-363' AS work_id, 'person-tang-liu-shenxu' AS person_id, 'PENDING' AS attribution, 'claim-t300-363-author' AS claim_id
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_work_author x WHERE x.work_id = t.work_id AND x.person_id = t.person_id);

-- ---------- 5. 正文版本：维基文库页面底本；异体折叠只作判定、正文存选本原样 ----------
INSERT INTO poetry_text_version (id, work_id, version_code, label, script, source_id, source_locator)
SELECT * FROM (
SELECT 'text-work-t300-002-ws' AS id, 'work-t300-002' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-002' AS source_id, '页面 登幽州臺歌' AS source_locator
UNION ALL
SELECT 'text-work-t300-005-ws' AS id, 'work-t300-005' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-005' AS source_id, '页面 出塞 (秦時明月漢時關)' AS source_locator
UNION ALL
SELECT 'text-work-t300-009-ws' AS id, 'work-t300-009' AS work_id, 'vol-raw' AS version_code, '维基文库《全唐詩》卷页（逐字一致）；底本 全唐詩/卷301（维基文库《全唐詩》录入本）' AS label, 'TRADITIONAL' AS script, 'source-quantangshi-301' AS source_id, '页面 全唐詩/卷301（锚点 卷301_23故行宮王建）' AS source_locator
UNION ALL
SELECT 'text-work-t300-010-ws' AS id, 'work-t300-010' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-010' AS source_id, '页面 錦瑟' AS source_locator
UNION ALL
SELECT 'text-work-t300-011-ws' AS id, 'work-t300-011' AS work_id, 'ws-fold' AS version_code, '维基文库页面（异体折叠后一致，存选本原样）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-011' AS source_id, '页面 蟬 (李商隱)' AS source_locator
UNION ALL
SELECT 'text-work-t300-013-ws' AS id, 'work-t300-013' AS work_id, 'ws-xbook-fold' AS version_code, '维基文库页面（异体折叠后一致，存选本原样）；底本 李義山詩集 (四部叢刊本)/卷第六' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-013' AS source_id, '页面 夜雨寄北' AS source_locator
UNION ALL
SELECT 'text-work-t300-015-ws' AS id, 'work-t300-015' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-015' AS source_id, '页面 風雨 (李商隱)' AS source_locator
UNION ALL
SELECT 'text-work-t300-016-ws' AS id, 'work-t300-016' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-016' AS source_id, '页面 寄令狐郎中' AS source_locator
UNION ALL
SELECT 'text-work-t300-020-ws' AS id, 'work-t300-020' AS work_id, 'vol-fold' AS version_code, '维基文库《全唐詩》卷页（异体折叠后一致，存选本原样）；底本 全唐詩/卷539（维基文库《全唐詩》录入本）' AS label, 'TRADITIONAL' AS script, 'source-quantangshi-539' AS source_id, '页面 全唐詩/卷539（锚点 ==無題四首_來是空言去絕蹤|無題四首==）' AS source_locator
UNION ALL
SELECT 'text-work-t300-022-ws' AS id, 'work-t300-022' AS work_id, 'vol-raw' AS version_code, '维基文库《全唐詩》卷页（逐字一致）；底本 全唐詩/卷539（维基文库《全唐詩》录入本）' AS label, 'TRADITIONAL' AS script, 'source-quantangshi-539' AS source_id, '页面 全唐詩/卷539（锚点 ==隋宮==）' AS source_locator
UNION ALL
SELECT 'text-work-t300-024-ws' AS id, 'work-t300-024' AS work_id, 'vol-fold' AS version_code, '维基文库《全唐詩》卷页（异体折叠后一致，存选本原样）；底本 全唐詩/卷539（维基文库《全唐詩》录入本）' AS label, 'TRADITIONAL' AS script, 'source-quantangshi-539' AS source_id, '页面 全唐詩/卷539（锚点 ==為有==）' AS source_locator
UNION ALL
SELECT 'text-work-t300-025-ws' AS id, 'work-t300-025' AS work_id, 'vol-fold' AS version_code, '维基文库《全唐詩》卷页（异体折叠后一致，存选本原样）；底本 全唐詩/卷539（维基文库《全唐詩》录入本）' AS label, 'TRADITIONAL' AS script, 'source-quantangshi-539' AS source_id, '页面 全唐詩/卷539（锚点 ==無題_相見時難別亦難|無題==）' AS source_locator
UNION ALL
SELECT 'text-work-t300-026-ws' AS id, 'work-t300-026' AS work_id, 'vol-raw' AS version_code, '维基文库《全唐詩》卷页（逐字一致）；底本 全唐詩/卷539（维基文库《全唐詩》录入本）' AS label, 'TRADITIONAL' AS script, 'source-quantangshi-539' AS source_id, '页面 全唐詩/卷539（锚点 ==瑤池==）' AS source_locator
UNION ALL
SELECT 'text-work-t300-028-ws' AS id, 'work-t300-028' AS work_id, 'vol-raw' AS version_code, '维基文库《全唐詩》卷页（逐字一致）；底本 全唐詩/卷540（维基文库《全唐詩》录入本）' AS label, 'TRADITIONAL' AS script, 'source-quantangshi-540' AS source_id, '页面 全唐詩/卷540（锚点 ==常娥==）' AS source_locator
UNION ALL
SELECT 'text-work-t300-029-ws' AS id, 'work-t300-029' AS work_id, 'vol-raw' AS version_code, '维基文库《全唐詩》卷页（逐字一致）；底本 全唐詩/卷540（维基文库《全唐詩》录入本）' AS label, 'TRADITIONAL' AS script, 'source-quantangshi-540' AS source_id, '页面 全唐詩/卷540（锚点 ==無題二首==）' AS source_locator
UNION ALL
SELECT 'text-work-t300-031-ws' AS id, 'work-t300-031' AS work_id, 'vol-raw' AS version_code, '维基文库《全唐詩》卷页（逐字一致）；底本 全唐詩/卷540（维基文库《全唐詩》录入本）' AS label, 'TRADITIONAL' AS script, 'source-quantangshi-540' AS source_id, '页面 全唐詩/卷540（锚点 ==賈生==）' AS source_locator
UNION ALL
SELECT 'text-work-t300-032-ws' AS id, 'work-t300-032' AS work_id, 'vol-raw' AS version_code, '维基文库《全唐詩》卷页（逐字一致）；底本 全唐詩/卷540（维基文库《全唐詩》录入本）' AS label, 'TRADITIONAL' AS script, 'source-quantangshi-540' AS source_id, '页面 全唐詩/卷540（锚点 ==涼思==）' AS source_locator
UNION ALL
SELECT 'text-work-t300-036-ws' AS id, 'work-t300-036' AS work_id, 'vol-raw' AS version_code, '维基文库《全唐詩》卷页（逐字一致）；底本 全唐詩/卷697（维基文库《全唐詩》录入本）' AS label, 'TRADITIONAL' AS script, 'source-quantangshi-697' AS source_id, '页面 全唐詩/卷697（锚点 ===金陵圖===）' AS source_locator
UNION ALL
SELECT 'text-work-t300-037-ws' AS id, 'work-t300-037' AS work_id, 'vol-raw' AS version_code, '维基文库《全唐詩》卷页（逐字一致）；底本 全唐詩/卷697（维基文库《全唐詩》录入本）' AS label, 'TRADITIONAL' AS script, 'source-quantangshi-697' AS source_id, '页面 全唐詩/卷697（锚点 ===台城===）' AS source_locator
UNION ALL
SELECT 'text-work-t300-040-ws' AS id, 'work-t300-040' AS work_id, 'vol-fold' AS version_code, '维基文库《全唐詩》卷页（异体折叠后一致，存选本原样）；底本 全唐詩/卷555（维基文库《全唐詩》录入本）' AS label, 'TRADITIONAL' AS script, 'source-quantangshi-555' AS source_id, '页面 全唐詩/卷555（锚点 ===灞上秋居===）' AS source_locator
UNION ALL
SELECT 'text-work-t300-041-ws' AS id, 'work-t300-041' AS work_id, 'vol-raw' AS version_code, '维基文库《全唐詩》卷页（逐字一致）；底本 全唐詩/卷557（维基文库《全唐詩》录入本）' AS label, 'TRADITIONAL' AS script, 'source-quantangshi-557' AS source_id, '页面 全唐詩/卷557（锚点 ===馬嵬坡===）' AS source_locator
UNION ALL
SELECT 'text-work-t300-043-ws' AS id, 'work-t300-043' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-043' AS source_id, '页面 春怨 (金昌緒)' AS source_locator
UNION ALL
SELECT 'text-work-t300-045-ws' AS id, 'work-t300-045' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩/卷404' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-045' AS source_id, '页面 遣悲懷之二' AS source_locator
UNION ALL
SELECT 'text-work-t300-047-ws' AS id, 'work-t300-047' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩/卷410|type=詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-047' AS source_id, '页面 行宮' AS source_locator
UNION ALL
SELECT 'text-work-t300-048-ws' AS id, 'work-t300-048' AS work_id, 'vol-raw' AS version_code, '维基文库《全唐詩》卷页（逐字一致）；底本 全唐詩/卷784（维基文库《全唐詩》录入本）' AS label, 'TRADITIONAL' AS script, 'source-quantangshi-784' AS source_id, '页面 全唐詩/卷784（锚点 ==西鄙人====）' AS source_locator
UNION ALL
SELECT 'text-work-t300-052-ws' AS id, 'work-t300-052' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-052' AS source_id, '页面 次北固山下' AS source_locator
UNION ALL
SELECT 'text-work-t300-053-ws' AS id, 'work-t300-053' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-053' AS source_id, '页面 桃花谿' AS source_locator
UNION ALL
SELECT 'text-work-t300-054-ws' AS id, 'work-t300-054' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-054' AS source_id, '页面 送別 (下馬飲君酒)' AS source_locator
UNION ALL
SELECT 'text-work-t300-056-ws' AS id, 'work-t300-056' AS work_id, 'ws-fold' AS version_code, '维基文库页面（异体折叠后一致，存选本原样）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-056' AS source_id, '页面 青谿' AS source_locator
UNION ALL
SELECT 'text-work-t300-057-ws' AS id, 'work-t300-057' AS work_id, 'ws-fold' AS version_code, '维基文库页面（异体折叠后一致，存选本原样）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-057' AS source_id, '页面 渭川田家' AS source_locator
UNION ALL
SELECT 'text-work-t300-060-ws' AS id, 'work-t300-060' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-060' AS source_id, '页面 桃源行 (王維)' AS source_locator
UNION ALL
SELECT 'text-work-t300-061-ws' AS id, 'work-t300-061' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-061' AS source_id, '页面 洛陽女兒行' AS source_locator
UNION ALL
SELECT 'text-work-t300-062-ws' AS id, 'work-t300-062' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-062' AS source_id, '页面 輞川閑居贈裴秀才迪' AS source_locator
UNION ALL
SELECT 'text-work-t300-063-ws' AS id, 'work-t300-063' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-063' AS source_id, '页面 酬張少府' AS source_locator
UNION ALL
SELECT 'text-work-t300-064-ws' AS id, 'work-t300-064' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-064' AS source_id, '页面 送梓州李使君' AS source_locator
UNION ALL
SELECT 'text-work-t300-074-ws' AS id, 'work-t300-074' AS work_id, 'vol-raw' AS version_code, '维基文库《全唐詩》卷页（逐字一致）；底本 全唐詩/卷523（维基文库《全唐詩》录入本）' AS label, 'TRADITIONAL' AS script, 'source-quantangshi-523' AS source_id, '页面 全唐詩/卷523（锚点 ===泊秦淮===）' AS source_locator
UNION ALL
SELECT 'text-work-t300-079-ws' AS id, 'work-t300-079' AS work_id, 'vol-raw' AS version_code, '维基文库《全唐詩》卷页（逐字一致）；底本 全唐詩/卷525（维基文库《全唐詩》录入本）' AS label, 'TRADITIONAL' AS script, 'source-quantangshi-525' AS source_id, '页面 全唐詩/卷525（锚点 ===金谷園===）' AS source_locator
UNION ALL
SELECT 'text-work-t300-087-ws' AS id, 'work-t300-087' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-087' AS source_id, '页面 喜見外弟又言別' AS source_locator
UNION ALL
SELECT 'text-work-t300-097-ws' AS id, 'work-t300-097' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-097' AS source_id, '页面 新年作 (劉長卿)' AS source_locator
UNION ALL
SELECT 'text-work-t300-100-ws' AS id, 'work-t300-100' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-100' AS source_id, '页面 餞別王十一南遊' AS source_locator
UNION ALL
SELECT 'text-work-t300-101-ws' AS id, 'work-t300-101' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-101' AS source_id, '页面 江州重別薛六柳八二員外' AS source_locator
UNION ALL
SELECT 'text-work-t300-102-ws' AS id, 'work-t300-102' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-102' AS source_id, '页面 長沙過賈誼宅' AS source_locator
UNION ALL
SELECT 'text-work-t300-106-ws' AS id, 'work-t300-106' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-106' AS source_id, '页面 涼州詞 (葡萄美酒夜光杯)' AS source_locator
UNION ALL
SELECT 'text-work-t300-108-ws' AS id, 'work-t300-108' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-108' AS source_id, '页面 夏日南亭懷辛大' AS source_locator
UNION ALL
SELECT 'text-work-t300-112-ws' AS id, 'work-t300-112' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩/卷160#秦中感秋寄遠' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-112' AS source_id, '页面 秦中感秋寄遠上人' AS source_locator
UNION ALL
SELECT 'text-work-t300-117-ws' AS id, 'work-t300-117' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-117' AS source_id, '页面 與諸子登峴山' AS source_locator
UNION ALL
SELECT 'text-work-t300-118-ws' AS id, 'work-t300-118' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-118' AS source_id, '页面 過故人莊' AS source_locator
UNION ALL
SELECT 'text-work-t300-119-ws' AS id, 'work-t300-119' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-119' AS source_id, '页面 歲暮歸南山' AS source_locator
UNION ALL
SELECT 'text-work-t300-121-ws' AS id, 'work-t300-121' AS work_id, 'ws-xbook-raw' AS version_code, '维基文库页面（逐字一致）；底本 文苑英華 (四庫全書本)/卷0157' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-121' AS source_id, '页面 春曉 (孟浩然)' AS source_locator
UNION ALL
SELECT 'text-work-t300-122-ws' AS id, 'work-t300-122' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-122' AS source_id, '页面 宿建德江' AS source_locator
UNION ALL
SELECT 'text-work-t300-131-ws' AS id, 'work-t300-131' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-131' AS source_id, '页面 晚次鄂州' AS source_locator
UNION ALL
SELECT 'text-work-t300-133-ws' AS id, 'work-t300-133' AS work_id, 'ws-fold' AS version_code, '维基文库页面（异体折叠后一致，存选本原样）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-133' AS source_id, '页面 過香積寺' AS source_locator
UNION ALL
SELECT 'text-work-t300-134-ws' AS id, 'work-t300-134' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-134' AS source_id, '页面 山居秋暝' AS source_locator
UNION ALL
SELECT 'text-work-t300-135-ws' AS id, 'work-t300-135' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-135' AS source_id, '页面 終南別業' AS source_locator
UNION ALL
SELECT 'text-work-t300-136-ws' AS id, 'work-t300-136' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-136' AS source_id, '页面 歸嵩山作' AS source_locator
UNION ALL
SELECT 'text-work-t300-137-ws' AS id, 'work-t300-137' AS work_id, 'ws-fold' AS version_code, '维基文库页面（异体折叠后一致，存选本原样）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-137' AS source_id, '页面 終南山 (王維)' AS source_locator
UNION ALL
SELECT 'text-work-t300-140-ws' AS id, 'work-t300-140' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-140' AS source_id, '页面 和賈舍人早朝大明宮之作' AS source_locator
UNION ALL
SELECT 'text-work-t300-142-ws' AS id, 'work-t300-142' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-142' AS source_id, '页面 積雨輞川莊作' AS source_locator
UNION ALL
SELECT 'text-work-t300-145-ws' AS id, 'work-t300-145' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-145' AS source_id, '页面 送別 (山中相送罷)' AS source_locator
UNION ALL
SELECT 'text-work-t300-146-ws' AS id, 'work-t300-146' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-146' AS source_id, '页面 雜詩 (君自故鄉來)' AS source_locator
UNION ALL
SELECT 'text-work-t300-148-ws' AS id, 'work-t300-148' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-148' AS source_id, '页面 九月九日憶山東兄弟' AS source_locator
UNION ALL
SELECT 'text-work-t300-151-ws' AS id, 'work-t300-151' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-151' AS source_id, '页面 尋西山隱者不遇' AS source_locator
UNION ALL
SELECT 'text-work-t300-153-ws' AS id, 'work-t300-153' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-153' AS source_id, '页面 行經華陰' AS source_locator
UNION ALL
SELECT 'text-work-t300-156-ws' AS id, 'work-t300-156' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-156' AS source_id, '页面 望薊門' AS source_locator
UNION ALL
SELECT 'text-work-t300-157-ws' AS id, 'work-t300-157' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-157' AS source_id, '页面 終南望餘雪' AS source_locator
UNION ALL
SELECT 'text-work-t300-158-ws' AS id, 'work-t300-158' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-158' AS source_id, '页面 古從軍行' AS source_locator
UNION ALL
SELECT 'text-work-t300-159-ws' AS id, 'work-t300-159' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-159' AS source_id, '页面 琴歌 (李頎)' AS source_locator
UNION ALL
SELECT 'text-work-t300-160-ws' AS id, 'work-t300-160' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-160' AS source_id, '页面 送陳章甫' AS source_locator
UNION ALL
SELECT 'text-work-t300-161-ws' AS id, 'work-t300-161' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-161' AS source_id, '页面 聽安萬善吹觱篥歌' AS source_locator
UNION ALL
SELECT 'text-work-t300-162-ws' AS id, 'work-t300-162' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-162' AS source_id, '页面 古意 (李頎)' AS source_locator
UNION ALL
SELECT 'text-work-t300-164-ws' AS id, 'work-t300-164' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-164' AS source_id, '页面 送魏萬之京' AS source_locator
UNION ALL
SELECT 'text-work-t300-165-ws' AS id, 'work-t300-165' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-165' AS source_id, '页面 春泛若耶溪' AS source_locator
UNION ALL
SELECT 'text-work-t300-169-ws' AS id, 'work-t300-169' AS work_id, 'vol-raw' AS version_code, '维基文库《全唐詩》卷页（逐字一致）；底本 全唐詩/卷018（维基文库《全唐詩》录入本）' AS label, 'TRADITIONAL' AS script, 'source-quantangshi-18' AS source_id, '页面 全唐詩/卷018（锚点 ==橫吹曲辭出塞==）' AS source_locator
UNION ALL
SELECT 'text-work-t300-170-ws' AS id, 'work-t300-170' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-170' AS source_id, '页面 春宮曲' AS source_locator
UNION ALL
SELECT 'text-work-t300-171-ws' AS id, 'work-t300-171' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-171' AS source_id, '页面 閨怨 (王昌齡)' AS source_locator
UNION ALL
SELECT 'text-work-t300-173-ws' AS id, 'work-t300-173' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-173' AS source_id, '页面 宿王昌齡隱居' AS source_locator
UNION ALL
SELECT 'text-work-t300-186-ws' AS id, 'work-t300-186' AS work_id, 'vol-raw' AS version_code, '维基文库《全唐詩》卷页（逐字一致）；底本 全唐詩/卷581（维基文库《全唐詩》录入本）' AS label, 'TRADITIONAL' AS script, 'source-quantangshi-581' AS source_id, '页面 全唐詩/卷581（锚点 ===送人東===）' AS source_locator
UNION ALL
SELECT 'text-work-t300-189-ws' AS id, 'work-t300-189' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩/卷670' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-189' AS source_id, '页面 貧女(秦韜玉)' AS source_locator
UNION ALL
SELECT 'text-work-t300-193-ws' AS id, 'work-t300-193' AS work_id, 'vol-raw' AS version_code, '维基文库《全唐詩》卷页（逐字一致）；底本 全唐詩/卷511（维基文库《全唐詩》录入本）' AS label, 'TRADITIONAL' AS script, 'source-quantangshi-511' AS source_id, '页面 全唐詩/卷511（锚点 ===宮詞二首===）' AS source_locator
UNION ALL
SELECT 'text-work-t300-197-ws' AS id, 'work-t300-197' AS work_id, 'vol-raw' AS version_code, '维基文库《全唐詩》卷页（逐字一致）；底本 全唐詩/卷511（维基文库《全唐詩》录入本）' AS label, 'TRADITIONAL' AS script, 'source-quantangshi-511' AS source_id, '页面 全唐詩/卷511（锚点 ===延年不語望三星莫說夫人上涕零爭奈世間惆悵在甘泉宮夜看圖形===）' AS source_locator
UNION ALL
SELECT 'text-work-t300-198-ws' AS id, 'work-t300-198' AS work_id, 'vol-raw' AS version_code, '维基文库《全唐詩》卷页（逐字一致）；底本 全唐詩/卷514（维基文库《全唐詩》录入本）' AS label, 'TRADITIONAL' AS script, 'source-quantangshi-514' AS source_id, '页面 全唐詩/卷514（锚点 ===石抱龍堂蘚石乾山遮白日寺門寒長松瀑布饒奇狀曾有僊人駐鶴看===）' AS source_locator
UNION ALL
SELECT 'text-work-t300-207-ws' AS id, 'work-t300-207' AS work_id, 'vol-raw' AS version_code, '维基文库《全唐詩》卷页（逐字一致）；底本 全唐詩/卷224（维基文库《全唐詩》录入本）' AS label, 'TRADITIONAL' AS script, 'source-quantangshi-224' AS source_id, '页面 全唐詩/卷224（锚点 ==月夜==）' AS source_locator
UNION ALL
SELECT 'text-work-chun-wang-ws' AS id, 'work-chun-wang' AS work_id, 'vol-raw' AS version_code, '维基文库《全唐詩》卷页（逐字一致）；底本 全唐詩/卷224（维基文库《全唐詩》录入本）' AS label, 'TRADITIONAL' AS script, 'source-quantangshi-224' AS source_id, '页面 全唐詩/卷224（锚点 ==春望==）' AS source_locator
UNION ALL
SELECT 'text-work-t300-209-ws' AS id, 'work-t300-209' AS work_id, 'vol-raw' AS version_code, '维基文库《全唐詩》卷页（逐字一致）；底本 全唐詩/卷225（维基文库《全唐詩》录入本）' AS label, 'TRADITIONAL' AS script, 'source-quantangshi-225' AS source_id, '页面 全唐詩/卷225（锚点 ==春宿左省==）' AS source_locator
UNION ALL
SELECT 'text-work-t300-210-ws' AS id, 'work-t300-210' AS work_id, 'vol-raw' AS version_code, '维基文库《全唐詩》卷页（逐字一致）；底本 全唐詩/卷225（维基文库《全唐詩》录入本）' AS label, 'TRADITIONAL' AS script, 'source-quantangshi-225' AS source_id, '页面 全唐詩/卷225（锚点 ==因許八奉寄江甯旻上人==）' AS source_locator
UNION ALL
SELECT 'text-work-t300-211-ws' AS id, 'work-t300-211' AS work_id, 'vol-fold' AS version_code, '维基文库《全唐詩》卷页（异体折叠后一致，存选本原样）；底本 全唐詩/卷225（维基文库《全唐詩》录入本）' AS label, 'TRADITIONAL' AS script, 'source-quantangshi-225' AS source_id, '页面 全唐詩/卷225（锚点 ==月夜憶舍弟==）' AS source_locator
UNION ALL
SELECT 'text-work-t300-214-ws' AS id, 'work-t300-214' AS work_id, 'vol-fold' AS version_code, '维基文库《全唐詩》卷页（异体折叠后一致，存选本原样）；底本 全唐詩/卷226（维基文库《全唐詩》录入本）' AS label, 'TRADITIONAL' AS script, 'source-quantangshi-226' AS source_id, '页面 全唐詩/卷226（锚点 ==客至喜崔明府相過==）' AS source_locator
UNION ALL
SELECT 'text-work-t300-215-ws' AS id, 'work-t300-215' AS work_id, 'vol-fold' AS version_code, '维基文库《全唐詩》卷页（异体折叠后一致，存选本原样）；底本 全唐詩/卷227（维基文库《全唐詩》录入本）' AS label, 'TRADITIONAL' AS script, 'source-quantangshi-227' AS source_id, '页面 全唐詩/卷227（锚点 ==野望杜甫|野望==）' AS source_locator
UNION ALL
SELECT 'text-work-t300-216-ws' AS id, 'work-t300-216' AS work_id, 'ws-fold' AS version_code, '维基文库页面（异体折叠后一致，存选本原样）；底本 全唐詩/卷227' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-216' AS source_id, '页面 奉濟驛重送嚴公四韻' AS source_locator
UNION ALL
SELECT 'text-work-t300-217-ws' AS id, 'work-t300-217' AS work_id, 'ws-fold' AS version_code, '维基文库页面（异体折叠后一致，存选本原样）；底本 全唐詩/卷227' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-217' AS source_id, '页面 聞官軍收河南河北' AS source_locator
UNION ALL
SELECT 'text-work-t300-220-ws' AS id, 'work-t300-220' AS work_id, 'ws-fold' AS version_code, '维基文库页面（异体折叠后一致，存选本原样）；底本 全唐詩 (四庫全書本)/卷22' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-220' AS source_id, '页面 登樓 (杜甫)' AS source_locator
UNION ALL
SELECT 'text-work-t300-221-ws' AS id, 'work-t300-221' AS work_id, 'vol-fold' AS version_code, '维基文库《全唐詩》卷页（异体折叠后一致，存选本原样）；底本 全唐詩/卷228（维基文库《全唐詩》录入本）' AS label, 'TRADITIONAL' AS script, 'source-quantangshi-228' AS source_id, '页面 全唐詩/卷228（锚点 ==宿府==）' AS source_locator
UNION ALL
SELECT 'text-work-t300-231-ws' AS id, 'work-t300-231' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-231' AS source_id, '页面 登岳陽樓 (杜甫)' AS source_locator
UNION ALL
SELECT 'text-work-t300-233-ws' AS id, 'work-t300-233' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-233' AS source_id, '页面 望月懷遠' AS source_locator
UNION ALL
SELECT 'text-work-t300-234-ws' AS id, 'work-t300-234' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-234' AS source_id, '页面 題大庾嶺北驛' AS source_locator
UNION ALL
SELECT 'text-work-t300-240-ws' AS id, 'work-t300-240' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-240' AS source_id, '页面 送李少府貶峽中王少府貶長沙' AS source_locator
UNION ALL
SELECT 'text-work-t300-248-ws' AS id, 'work-t300-248' AS work_id, 'vol-raw' AS version_code, '维基文库《全唐詩》卷页（逐字一致）；底本 全唐詩/卷218（维基文库《全唐詩》录入本）' AS label, 'TRADITIONAL' AS script, 'source-quantangshi-218' AS source_id, '页面 全唐詩/卷218（锚点 ==夢李白二首==）' AS source_locator
UNION ALL
SELECT 'text-work-t300-252-ws' AS id, 'work-t300-252' AS work_id, 'vol-raw' AS version_code, '维基文库《全唐詩》卷页（逐字一致）；底本 全唐詩/卷220（维基文库《全唐詩》录入本）' AS label, 'TRADITIONAL' AS script, 'source-quantangshi-220' AS source_id, '页面 全唐詩/卷220（锚点 ==寄韓諫議==）' AS source_locator
UNION ALL
SELECT 'text-work-t300-262-ws' AS id, 'work-t300-262' AS work_id, 'vol-raw' AS version_code, '维基文库《全唐詩》卷页（逐字一致）；底本 全唐詩/卷028（维基文库《全唐詩》录入本）' AS label, 'TRADITIONAL' AS script, 'source-quantangshi-28' AS source_id, '页面 全唐詩/卷028（锚点 ==雜曲歌辭金縷衣==）' AS source_locator
UNION ALL
SELECT 'text-work-t300-274-ws' AS id, 'work-t300-274' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-274' AS source_id, '页面 谷口書齋寄楊補闕' AS source_locator
UNION ALL
SELECT 'text-work-t300-276-ws' AS id, 'work-t300-276' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-276' AS source_id, '页面 贈闕下裴舍人' AS source_locator
UNION ALL
SELECT 'text-work-t300-283-ws' AS id, 'work-t300-283' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-283' AS source_id, '页面 寒食 (韓翃)' AS source_locator
UNION ALL
SELECT 'text-work-t300-284-ws' AS id, 'work-t300-284' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-284' AS source_id, '页面 寄李儋元錫' AS source_locator
UNION ALL
SELECT 'text-work-t300-285-ws' AS id, 'work-t300-285' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-285' AS source_id, '页面 寄全椒山中道士' AS source_locator
UNION ALL
SELECT 'text-work-t300-289-ws' AS id, 'work-t300-289' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-289' AS source_id, '页面 長安遇馮著' AS source_locator
UNION ALL
SELECT 'text-work-t300-290-ws' AS id, 'work-t300-290' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-290' AS source_id, '页面 夕次盱眙縣' AS source_locator
UNION ALL
SELECT 'text-work-t300-291-ws' AS id, 'work-t300-291' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-291' AS source_id, '页面 東郊' AS source_locator
UNION ALL
SELECT 'text-work-t300-292-ws' AS id, 'work-t300-292' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-292' AS source_id, '页面 滁州西澗' AS source_locator
UNION ALL
SELECT 'text-work-t300-296-ws' AS id, 'work-t300-296' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-296' AS source_id, '页面 輪臺歌奉送封大夫出師西征' AS source_locator
UNION ALL
SELECT 'text-work-t300-298-ws' AS id, 'work-t300-298' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-298' AS source_id, '页面 寄左省杜拾遺' AS source_locator
UNION ALL
SELECT 'text-work-t300-299-ws' AS id, 'work-t300-299' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-299' AS source_id, '页面 奉和中書舍人賈至早朝大明宮' AS source_locator
UNION ALL
SELECT 'text-work-t300-300-ws' AS id, 'work-t300-300' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-300' AS source_id, '页面 逢入京使' AS source_locator
UNION ALL
SELECT 'text-work-t300-308-ws' AS id, 'work-t300-308' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-308' AS source_id, '页面 玉階怨 (李白)' AS source_locator
UNION ALL
SELECT 'text-work-t300-312-ws' AS id, 'work-t300-312' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-312' AS source_id, '页面 春思 (李白)' AS source_locator
UNION ALL
SELECT 'text-work-t300-320-ws' AS id, 'work-t300-320' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-320' AS source_id, '页面 金陵酒肆留別' AS source_locator
UNION ALL
SELECT 'text-work-t300-323-ws' AS id, 'work-t300-323' AS work_id, 'ws-fold' AS version_code, '维基文库页面（异体折叠后一致，存选本原样）；底本 全唐詩 (四庫全書本)/卷17' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-323' AS source_id, '页面 送友人 (李白)' AS source_locator
UNION ALL
SELECT 'text-work-t300-325-ws' AS id, 'work-t300-325' AS work_id, 'ws-fold' AS version_code, '维基文库页面（异体折叠后一致，存选本原样）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-325' AS source_id, '页面 下終南山過斛斯山人宿置酒' AS source_locator
UNION ALL
SELECT 'text-work-t300-326-ws' AS id, 'work-t300-326' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-326' AS source_id, '页面 登金陵鳳凰臺' AS source_locator
UNION ALL
SELECT 'text-work-t300-328-ws' AS id, 'work-t300-328' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-328' AS source_id, '页面 夜泊牛渚懷古' AS source_locator
UNION ALL
SELECT 'text-work-t300-330-ws' AS id, 'work-t300-330' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-330' AS source_id, '页面 聽蜀僧濬彈琴' AS source_locator
UNION ALL
SELECT 'text-work-t300-331-ws' AS id, 'work-t300-331' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-331' AS source_id, '页面 怨情 (美人捲珠簾)' AS source_locator
UNION ALL
SELECT 'text-work-t300-334-ws' AS id, 'work-t300-334' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-334' AS source_id, '页面 初發揚子寄元大校書' AS source_locator
UNION ALL
SELECT 'text-work-t300-335-ws' AS id, 'work-t300-335' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-335' AS source_id, '页面 江南曲 (嫁得瞿塘賈)' AS source_locator
UNION ALL
SELECT 'text-work-t300-358-ws' AS id, 'work-t300-358' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-358' AS source_id, '页面 春思 (皇甫冉)' AS source_locator
UNION ALL
SELECT 'text-work-t300-360-ws' AS id, 'work-t300-360' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-360' AS source_id, '页面 春怨 (劉方平)' AS source_locator
UNION ALL
SELECT 'text-work-t300-361-ws' AS id, 'work-t300-361' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩 (四庫全書本)/卷25' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-361' AS source_id, '页面 登鸛雀樓 (王之渙)' AS source_locator
UNION ALL
SELECT 'text-work-t300-363-ws' AS id, 'work-t300-363' AS work_id, 'ws-raw' AS version_code, '维基文库页面（逐字一致）；底本 全唐詩' AS label, 'TRADITIONAL' AS script, 'source-ws-t300-363' AS source_id, '页面 闕題 (劉眘虛)' AS source_locator
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_text_version x WHERE x.id = t.id);

INSERT INTO poetry_text_line (version_id, line_seq, content)
SELECT * FROM (
SELECT 'text-work-t300-002-ws' AS version_id, 1 AS line_seq, '前不見古人，' AS content
UNION ALL
SELECT 'text-work-t300-002-ws' AS version_id, 2 AS line_seq, '後不見來者。' AS content
UNION ALL
SELECT 'text-work-t300-002-ws' AS version_id, 3 AS line_seq, '念天地之悠悠，' AS content
UNION ALL
SELECT 'text-work-t300-002-ws' AS version_id, 4 AS line_seq, '獨愴然而涕下。' AS content
UNION ALL
SELECT 'text-work-t300-005-ws' AS version_id, 1 AS line_seq, '秦時明月漢時關，' AS content
UNION ALL
SELECT 'text-work-t300-005-ws' AS version_id, 2 AS line_seq, '萬里長征人未還。' AS content
UNION ALL
SELECT 'text-work-t300-005-ws' AS version_id, 3 AS line_seq, '但使龍城飛將在，' AS content
UNION ALL
SELECT 'text-work-t300-005-ws' AS version_id, 4 AS line_seq, '不教胡馬度陰山。' AS content
UNION ALL
SELECT 'text-work-t300-009-ws' AS version_id, 1 AS line_seq, '寥落古行宮，' AS content
UNION ALL
SELECT 'text-work-t300-009-ws' AS version_id, 2 AS line_seq, '宮花寂寞紅。' AS content
UNION ALL
SELECT 'text-work-t300-009-ws' AS version_id, 3 AS line_seq, '白頭宮女在，' AS content
UNION ALL
SELECT 'text-work-t300-009-ws' AS version_id, 4 AS line_seq, '閑坐說玄宗。' AS content
UNION ALL
SELECT 'text-work-t300-010-ws' AS version_id, 1 AS line_seq, '錦瑟無端五十絃，' AS content
UNION ALL
SELECT 'text-work-t300-010-ws' AS version_id, 2 AS line_seq, '一絃一柱思華年。' AS content
UNION ALL
SELECT 'text-work-t300-010-ws' AS version_id, 3 AS line_seq, '莊生曉夢迷蝴蝶，' AS content
UNION ALL
SELECT 'text-work-t300-010-ws' AS version_id, 4 AS line_seq, '望帝春心託杜鵑。' AS content
UNION ALL
SELECT 'text-work-t300-010-ws' AS version_id, 5 AS line_seq, '滄海月明珠有淚，' AS content
UNION ALL
SELECT 'text-work-t300-010-ws' AS version_id, 6 AS line_seq, '藍田日暖玉生煙。' AS content
UNION ALL
SELECT 'text-work-t300-010-ws' AS version_id, 7 AS line_seq, '此情可待成追憶，' AS content
UNION ALL
SELECT 'text-work-t300-010-ws' AS version_id, 8 AS line_seq, '只是當時已惘然。' AS content
UNION ALL
SELECT 'text-work-t300-011-ws' AS version_id, 1 AS line_seq, '本以高難飽，' AS content
UNION ALL
SELECT 'text-work-t300-011-ws' AS version_id, 2 AS line_seq, '徒勞恨費聲。' AS content
UNION ALL
SELECT 'text-work-t300-011-ws' AS version_id, 3 AS line_seq, '五更疎欲斷，' AS content
UNION ALL
SELECT 'text-work-t300-011-ws' AS version_id, 4 AS line_seq, '一樹碧無情。' AS content
UNION ALL
SELECT 'text-work-t300-011-ws' AS version_id, 5 AS line_seq, '薄宦梗猶汎，' AS content
UNION ALL
SELECT 'text-work-t300-011-ws' AS version_id, 6 AS line_seq, '故園蕪已平。' AS content
UNION ALL
SELECT 'text-work-t300-011-ws' AS version_id, 7 AS line_seq, '煩君最相警，' AS content
UNION ALL
SELECT 'text-work-t300-011-ws' AS version_id, 8 AS line_seq, '我亦舉家清。' AS content
UNION ALL
SELECT 'text-work-t300-013-ws' AS version_id, 1 AS line_seq, '君問歸期未有期，' AS content
UNION ALL
SELECT 'text-work-t300-013-ws' AS version_id, 2 AS line_seq, '巴山夜雨漲秋池。' AS content
UNION ALL
SELECT 'text-work-t300-013-ws' AS version_id, 3 AS line_seq, '何當共剪西窗燭，' AS content
UNION ALL
SELECT 'text-work-t300-013-ws' AS version_id, 4 AS line_seq, '却話巴山夜雨時。' AS content
UNION ALL
SELECT 'text-work-t300-015-ws' AS version_id, 1 AS line_seq, '淒涼寶劍篇，' AS content
UNION ALL
SELECT 'text-work-t300-015-ws' AS version_id, 2 AS line_seq, '羈泊欲窮年。' AS content
UNION ALL
SELECT 'text-work-t300-015-ws' AS version_id, 3 AS line_seq, '黃葉仍風雨，' AS content
UNION ALL
SELECT 'text-work-t300-015-ws' AS version_id, 4 AS line_seq, '青樓自管絃。' AS content
UNION ALL
SELECT 'text-work-t300-015-ws' AS version_id, 5 AS line_seq, '新知遭薄俗，' AS content
UNION ALL
SELECT 'text-work-t300-015-ws' AS version_id, 6 AS line_seq, '舊好隔良緣。' AS content
UNION ALL
SELECT 'text-work-t300-015-ws' AS version_id, 7 AS line_seq, '心斷新豐酒，' AS content
UNION ALL
SELECT 'text-work-t300-015-ws' AS version_id, 8 AS line_seq, '銷愁斗幾千。' AS content
UNION ALL
SELECT 'text-work-t300-016-ws' AS version_id, 1 AS line_seq, '嵩雲秦樹久離居，' AS content
UNION ALL
SELECT 'text-work-t300-016-ws' AS version_id, 2 AS line_seq, '雙鯉迢迢一紙書。' AS content
UNION ALL
SELECT 'text-work-t300-016-ws' AS version_id, 3 AS line_seq, '休問梁園舊賓客，' AS content
UNION ALL
SELECT 'text-work-t300-016-ws' AS version_id, 4 AS line_seq, '茂陵秋雨病相如。' AS content
UNION ALL
SELECT 'text-work-t300-020-ws' AS version_id, 1 AS line_seq, '來是空言去絕踪，' AS content
UNION ALL
SELECT 'text-work-t300-020-ws' AS version_id, 2 AS line_seq, '月斜樓上五更鐘。' AS content
UNION ALL
SELECT 'text-work-t300-020-ws' AS version_id, 3 AS line_seq, '夢爲遠別啼難喚，' AS content
UNION ALL
SELECT 'text-work-t300-020-ws' AS version_id, 4 AS line_seq, '書被催成墨未濃。' AS content
UNION ALL
SELECT 'text-work-t300-020-ws' AS version_id, 5 AS line_seq, '蠟照半籠金翡翠，' AS content
UNION ALL
SELECT 'text-work-t300-020-ws' AS version_id, 6 AS line_seq, '麝熏微度繡芙蓉。' AS content
UNION ALL
SELECT 'text-work-t300-020-ws' AS version_id, 7 AS line_seq, '劉郎已恨蓬山遠，' AS content
UNION ALL
SELECT 'text-work-t300-020-ws' AS version_id, 8 AS line_seq, '更隔蓬山一萬重。' AS content
UNION ALL
SELECT 'text-work-t300-022-ws' AS version_id, 1 AS line_seq, '乘興南遊不戒嚴，' AS content
UNION ALL
SELECT 'text-work-t300-022-ws' AS version_id, 2 AS line_seq, '九重誰省諫書函。' AS content
UNION ALL
SELECT 'text-work-t300-022-ws' AS version_id, 3 AS line_seq, '春風舉國裁宮錦，' AS content
UNION ALL
SELECT 'text-work-t300-022-ws' AS version_id, 4 AS line_seq, '半作障泥半作帆。' AS content
UNION ALL
SELECT 'text-work-t300-024-ws' AS version_id, 1 AS line_seq, '爲有雲屏無限嬌，' AS content
UNION ALL
SELECT 'text-work-t300-024-ws' AS version_id, 2 AS line_seq, '鳳城寒盡怕春宵。' AS content
UNION ALL
SELECT 'text-work-t300-024-ws' AS version_id, 3 AS line_seq, '無端嫁得金龜壻，' AS content
UNION ALL
SELECT 'text-work-t300-024-ws' AS version_id, 4 AS line_seq, '辜負香衾事早朝。' AS content
UNION ALL
SELECT 'text-work-t300-025-ws' AS version_id, 1 AS line_seq, '相見時難別亦難，' AS content
UNION ALL
SELECT 'text-work-t300-025-ws' AS version_id, 2 AS line_seq, '東風無力百花殘。' AS content
UNION ALL
SELECT 'text-work-t300-025-ws' AS version_id, 3 AS line_seq, '春蠶到死絲方盡，' AS content
UNION ALL
SELECT 'text-work-t300-025-ws' AS version_id, 4 AS line_seq, '蠟炬成灰淚始乾。' AS content
UNION ALL
SELECT 'text-work-t300-025-ws' AS version_id, 5 AS line_seq, '曉鏡但愁雲鬢改，' AS content
UNION ALL
SELECT 'text-work-t300-025-ws' AS version_id, 6 AS line_seq, '夜吟應覺月光寒。' AS content
UNION ALL
SELECT 'text-work-t300-025-ws' AS version_id, 7 AS line_seq, '蓬山此去無多路，' AS content
UNION ALL
SELECT 'text-work-t300-025-ws' AS version_id, 8 AS line_seq, '青鳥殷勤爲探看。' AS content
UNION ALL
SELECT 'text-work-t300-026-ws' AS version_id, 1 AS line_seq, '瑤池阿母綺窗開，' AS content
UNION ALL
SELECT 'text-work-t300-026-ws' AS version_id, 2 AS line_seq, '黃竹歌聲動地哀。' AS content
UNION ALL
SELECT 'text-work-t300-026-ws' AS version_id, 3 AS line_seq, '八駿日行三萬里，' AS content
UNION ALL
SELECT 'text-work-t300-026-ws' AS version_id, 4 AS line_seq, '穆王何事不重來。' AS content
UNION ALL
SELECT 'text-work-t300-028-ws' AS version_id, 1 AS line_seq, '雲母屏風燭影深，' AS content
UNION ALL
SELECT 'text-work-t300-028-ws' AS version_id, 2 AS line_seq, '長河漸落曉星沈。' AS content
UNION ALL
SELECT 'text-work-t300-028-ws' AS version_id, 3 AS line_seq, '常娥應悔偷靈藥，' AS content
UNION ALL
SELECT 'text-work-t300-028-ws' AS version_id, 4 AS line_seq, '碧海青天夜夜心。' AS content
UNION ALL
SELECT 'text-work-t300-029-ws' AS version_id, 1 AS line_seq, '鳳尾香羅薄幾重，' AS content
UNION ALL
SELECT 'text-work-t300-029-ws' AS version_id, 2 AS line_seq, '碧文圓頂夜深縫。' AS content
UNION ALL
SELECT 'text-work-t300-029-ws' AS version_id, 3 AS line_seq, '扇裁月魄羞難掩，' AS content
UNION ALL
SELECT 'text-work-t300-029-ws' AS version_id, 4 AS line_seq, '車走雷聲語未通。' AS content
UNION ALL
SELECT 'text-work-t300-029-ws' AS version_id, 5 AS line_seq, '曾是寂寥金燼暗，' AS content
UNION ALL
SELECT 'text-work-t300-029-ws' AS version_id, 6 AS line_seq, '斷無消息石榴紅。' AS content
UNION ALL
SELECT 'text-work-t300-031-ws' AS version_id, 1 AS line_seq, '宣室求賢訪逐臣，' AS content
UNION ALL
SELECT 'text-work-t300-031-ws' AS version_id, 2 AS line_seq, '賈生才調更無倫。' AS content
UNION ALL
SELECT 'text-work-t300-031-ws' AS version_id, 3 AS line_seq, '可憐夜半虛前席，' AS content
UNION ALL
SELECT 'text-work-t300-031-ws' AS version_id, 4 AS line_seq, '不問蒼生問鬼神。' AS content
UNION ALL
SELECT 'text-work-t300-032-ws' AS version_id, 1 AS line_seq, '客去波平檻，' AS content
UNION ALL
SELECT 'text-work-t300-032-ws' AS version_id, 2 AS line_seq, '蟬休露滿枝。' AS content
UNION ALL
SELECT 'text-work-t300-032-ws' AS version_id, 3 AS line_seq, '永懷當此節，' AS content
UNION ALL
SELECT 'text-work-t300-032-ws' AS version_id, 4 AS line_seq, '倚立自移時。' AS content
UNION ALL
SELECT 'text-work-t300-032-ws' AS version_id, 5 AS line_seq, '北斗兼春遠，' AS content
UNION ALL
SELECT 'text-work-t300-032-ws' AS version_id, 6 AS line_seq, '南陵寓使遲。' AS content
UNION ALL
SELECT 'text-work-t300-032-ws' AS version_id, 7 AS line_seq, '天涯占夢數，' AS content
UNION ALL
SELECT 'text-work-t300-032-ws' AS version_id, 8 AS line_seq, '疑誤有新知。' AS content
UNION ALL
SELECT 'text-work-t300-036-ws' AS version_id, 1 AS line_seq, '誰謂傷心畫不成，' AS content
UNION ALL
SELECT 'text-work-t300-036-ws' AS version_id, 2 AS line_seq, '畫人心逐世人情。' AS content
UNION ALL
SELECT 'text-work-t300-036-ws' AS version_id, 3 AS line_seq, '君看六幅南朝事，' AS content
UNION ALL
SELECT 'text-work-t300-036-ws' AS version_id, 4 AS line_seq, '老木寒雲滿故城。' AS content
UNION ALL
SELECT 'text-work-t300-037-ws' AS version_id, 1 AS line_seq, '江雨霏霏江草齊，' AS content
UNION ALL
SELECT 'text-work-t300-037-ws' AS version_id, 2 AS line_seq, '六朝如夢鳥空啼。' AS content
UNION ALL
SELECT 'text-work-t300-037-ws' AS version_id, 3 AS line_seq, '無情最是臺城柳，' AS content
UNION ALL
SELECT 'text-work-t300-037-ws' AS version_id, 4 AS line_seq, '依舊煙籠十里堤。' AS content
UNION ALL
SELECT 'text-work-t300-040-ws' AS version_id, 1 AS line_seq, '灞原風雨定，' AS content
UNION ALL
SELECT 'text-work-t300-040-ws' AS version_id, 2 AS line_seq, '晚見鴈行頻。' AS content
UNION ALL
SELECT 'text-work-t300-040-ws' AS version_id, 3 AS line_seq, '落葉他鄉樹，' AS content
UNION ALL
SELECT 'text-work-t300-040-ws' AS version_id, 4 AS line_seq, '寒燈獨夜人。' AS content
UNION ALL
SELECT 'text-work-t300-040-ws' AS version_id, 5 AS line_seq, '空園白露滴，' AS content
UNION ALL
SELECT 'text-work-t300-040-ws' AS version_id, 6 AS line_seq, '孤壁野僧隣。' AS content
UNION ALL
SELECT 'text-work-t300-040-ws' AS version_id, 7 AS line_seq, '寄臥郊扉久，' AS content
UNION ALL
SELECT 'text-work-t300-040-ws' AS version_id, 8 AS line_seq, '何門致此身。' AS content
UNION ALL
SELECT 'text-work-t300-041-ws' AS version_id, 1 AS line_seq, '[玄]宗回馬楊妃死，' AS content
UNION ALL
SELECT 'text-work-t300-041-ws' AS version_id, 2 AS line_seq, '雲雨雖亡日月新。' AS content
UNION ALL
SELECT 'text-work-t300-041-ws' AS version_id, 3 AS line_seq, '終是聖明天子事，' AS content
UNION ALL
SELECT 'text-work-t300-041-ws' AS version_id, 4 AS line_seq, '景陽宮井又何人。' AS content
UNION ALL
SELECT 'text-work-t300-043-ws' AS version_id, 1 AS line_seq, '打起黃鶯兒，' AS content
UNION ALL
SELECT 'text-work-t300-043-ws' AS version_id, 2 AS line_seq, '莫教枝上啼。' AS content
UNION ALL
SELECT 'text-work-t300-043-ws' AS version_id, 3 AS line_seq, '啼時驚妾夢，' AS content
UNION ALL
SELECT 'text-work-t300-043-ws' AS version_id, 4 AS line_seq, '不得到遼西。' AS content
UNION ALL
SELECT 'text-work-t300-045-ws' AS version_id, 1 AS line_seq, '昔日戲言身後意，' AS content
UNION ALL
SELECT 'text-work-t300-045-ws' AS version_id, 2 AS line_seq, '今朝皆到眼前來。' AS content
UNION ALL
SELECT 'text-work-t300-045-ws' AS version_id, 3 AS line_seq, '衣裳已施行看盡，' AS content
UNION ALL
SELECT 'text-work-t300-045-ws' AS version_id, 4 AS line_seq, '針線猶存未忍開。' AS content
UNION ALL
SELECT 'text-work-t300-045-ws' AS version_id, 5 AS line_seq, '尚想舊情憐婢僕，' AS content
UNION ALL
SELECT 'text-work-t300-045-ws' AS version_id, 6 AS line_seq, '也曾因夢送錢財。' AS content
UNION ALL
SELECT 'text-work-t300-045-ws' AS version_id, 7 AS line_seq, '誠知此恨人人有，' AS content
UNION ALL
SELECT 'text-work-t300-045-ws' AS version_id, 8 AS line_seq, '貧賤夫妻百事哀。' AS content
UNION ALL
SELECT 'text-work-t300-047-ws' AS version_id, 1 AS line_seq, '寥落古行宮，' AS content
UNION ALL
SELECT 'text-work-t300-047-ws' AS version_id, 2 AS line_seq, '宮花寂寞紅。' AS content
UNION ALL
SELECT 'text-work-t300-047-ws' AS version_id, 3 AS line_seq, '白頭宮女在，' AS content
UNION ALL
SELECT 'text-work-t300-047-ws' AS version_id, 4 AS line_seq, '閑坐說玄宗。' AS content
UNION ALL
SELECT 'text-work-t300-048-ws' AS version_id, 1 AS line_seq, '北斗七星高，' AS content
UNION ALL
SELECT 'text-work-t300-048-ws' AS version_id, 2 AS line_seq, '哥舒夜帶刀。' AS content
UNION ALL
SELECT 'text-work-t300-048-ws' AS version_id, 3 AS line_seq, '至今窺牧馬，' AS content
UNION ALL
SELECT 'text-work-t300-048-ws' AS version_id, 4 AS line_seq, '不敢過臨洮。' AS content
UNION ALL
SELECT 'text-work-t300-052-ws' AS version_id, 1 AS line_seq, '客路青山外，' AS content
UNION ALL
SELECT 'text-work-t300-052-ws' AS version_id, 2 AS line_seq, '行舟綠水前。' AS content
UNION ALL
SELECT 'text-work-t300-052-ws' AS version_id, 3 AS line_seq, '潮平兩岸闊，' AS content
UNION ALL
SELECT 'text-work-t300-052-ws' AS version_id, 4 AS line_seq, '風正一帆懸。' AS content
UNION ALL
SELECT 'text-work-t300-052-ws' AS version_id, 5 AS line_seq, '海日生殘夜，' AS content
UNION ALL
SELECT 'text-work-t300-052-ws' AS version_id, 6 AS line_seq, '江春入舊年。' AS content
UNION ALL
SELECT 'text-work-t300-052-ws' AS version_id, 7 AS line_seq, '鄉書何處達，' AS content
UNION ALL
SELECT 'text-work-t300-052-ws' AS version_id, 8 AS line_seq, '歸雁洛陽邊。' AS content
UNION ALL
SELECT 'text-work-t300-053-ws' AS version_id, 1 AS line_seq, '隱隱飛橋隔野煙，' AS content
UNION ALL
SELECT 'text-work-t300-053-ws' AS version_id, 2 AS line_seq, '石磯西畔問漁船。' AS content
UNION ALL
SELECT 'text-work-t300-053-ws' AS version_id, 3 AS line_seq, '桃花盡日隨流水，' AS content
UNION ALL
SELECT 'text-work-t300-053-ws' AS version_id, 4 AS line_seq, '洞在清谿何處邊。' AS content
UNION ALL
SELECT 'text-work-t300-054-ws' AS version_id, 1 AS line_seq, '下馬飲君酒，' AS content
UNION ALL
SELECT 'text-work-t300-054-ws' AS version_id, 2 AS line_seq, '問君何所之。' AS content
UNION ALL
SELECT 'text-work-t300-054-ws' AS version_id, 3 AS line_seq, '君言不得意，' AS content
UNION ALL
SELECT 'text-work-t300-054-ws' AS version_id, 4 AS line_seq, '歸臥南山陲。' AS content
UNION ALL
SELECT 'text-work-t300-054-ws' AS version_id, 5 AS line_seq, '但去莫復問，' AS content
UNION ALL
SELECT 'text-work-t300-054-ws' AS version_id, 6 AS line_seq, '白雲無盡時。' AS content
UNION ALL
SELECT 'text-work-t300-056-ws' AS version_id, 1 AS line_seq, '言入黃花川，' AS content
UNION ALL
SELECT 'text-work-t300-056-ws' AS version_id, 2 AS line_seq, '每逐青谿水。' AS content
UNION ALL
SELECT 'text-work-t300-056-ws' AS version_id, 3 AS line_seq, '隨山將萬轉，' AS content
UNION ALL
SELECT 'text-work-t300-056-ws' AS version_id, 4 AS line_seq, '趣途無百里。' AS content
UNION ALL
SELECT 'text-work-t300-056-ws' AS version_id, 5 AS line_seq, '聲喧亂石中，' AS content
UNION ALL
SELECT 'text-work-t300-056-ws' AS version_id, 6 AS line_seq, '色靜深松裏。' AS content
UNION ALL
SELECT 'text-work-t300-056-ws' AS version_id, 7 AS line_seq, '漾漾汎菱荇，' AS content
UNION ALL
SELECT 'text-work-t300-056-ws' AS version_id, 8 AS line_seq, '澄澄映葭葦。' AS content
UNION ALL
SELECT 'text-work-t300-056-ws' AS version_id, 9 AS line_seq, '我心素已閑，' AS content
UNION ALL
SELECT 'text-work-t300-056-ws' AS version_id, 10 AS line_seq, '清川澹如此。' AS content
UNION ALL
SELECT 'text-work-t300-056-ws' AS version_id, 11 AS line_seq, '請留盤石上，' AS content
UNION ALL
SELECT 'text-work-t300-056-ws' AS version_id, 12 AS line_seq, '垂釣將已矣。' AS content
UNION ALL
SELECT 'text-work-t300-057-ws' AS version_id, 1 AS line_seq, '斜陽照墟落，' AS content
UNION ALL
SELECT 'text-work-t300-057-ws' AS version_id, 2 AS line_seq, '窮巷牛羊歸。' AS content
UNION ALL
SELECT 'text-work-t300-057-ws' AS version_id, 3 AS line_seq, '野老念牧童，' AS content
UNION ALL
SELECT 'text-work-t300-057-ws' AS version_id, 4 AS line_seq, '倚杖候荆扉。' AS content
UNION ALL
SELECT 'text-work-t300-057-ws' AS version_id, 5 AS line_seq, '雉雊麥苗秀，' AS content
UNION ALL
SELECT 'text-work-t300-057-ws' AS version_id, 6 AS line_seq, '蠶眠桑葉稀。' AS content
UNION ALL
SELECT 'text-work-t300-057-ws' AS version_id, 7 AS line_seq, '田夫荷鋤至，' AS content
UNION ALL
SELECT 'text-work-t300-057-ws' AS version_id, 8 AS line_seq, '相見語依依。' AS content
UNION ALL
SELECT 'text-work-t300-057-ws' AS version_id, 9 AS line_seq, '即此羨閑逸，' AS content
UNION ALL
SELECT 'text-work-t300-057-ws' AS version_id, 10 AS line_seq, '悵然吟式微。' AS content
UNION ALL
SELECT 'text-work-t300-060-ws' AS version_id, 1 AS line_seq, '漁舟逐水愛山春，' AS content
UNION ALL
SELECT 'text-work-t300-060-ws' AS version_id, 2 AS line_seq, '兩岸桃花夾去津。' AS content
UNION ALL
SELECT 'text-work-t300-060-ws' AS version_id, 3 AS line_seq, '坐看紅樹不知遠，' AS content
UNION ALL
SELECT 'text-work-t300-060-ws' AS version_id, 4 AS line_seq, '行盡青溪不見人。' AS content
UNION ALL
SELECT 'text-work-t300-060-ws' AS version_id, 5 AS line_seq, '山口潛行始隈隩，' AS content
UNION ALL
SELECT 'text-work-t300-060-ws' AS version_id, 6 AS line_seq, '山開曠望旋平陸。' AS content
UNION ALL
SELECT 'text-work-t300-060-ws' AS version_id, 7 AS line_seq, '遙看一處攢雲樹，' AS content
UNION ALL
SELECT 'text-work-t300-060-ws' AS version_id, 8 AS line_seq, '近入千家散花竹。' AS content
UNION ALL
SELECT 'text-work-t300-060-ws' AS version_id, 9 AS line_seq, '樵客初傳漢姓名，' AS content
UNION ALL
SELECT 'text-work-t300-060-ws' AS version_id, 10 AS line_seq, '居人未改秦衣服。' AS content
UNION ALL
SELECT 'text-work-t300-060-ws' AS version_id, 11 AS line_seq, '居人共住武陵源，' AS content
UNION ALL
SELECT 'text-work-t300-060-ws' AS version_id, 12 AS line_seq, '還從物外起田園。' AS content
UNION ALL
SELECT 'text-work-t300-060-ws' AS version_id, 13 AS line_seq, '月明松下房櫳靜，' AS content
UNION ALL
SELECT 'text-work-t300-060-ws' AS version_id, 14 AS line_seq, '日出雲中雞犬喧。' AS content
UNION ALL
SELECT 'text-work-t300-060-ws' AS version_id, 15 AS line_seq, '驚聞俗客爭來集，' AS content
UNION ALL
SELECT 'text-work-t300-060-ws' AS version_id, 16 AS line_seq, '競引還家問都邑。' AS content
UNION ALL
SELECT 'text-work-t300-060-ws' AS version_id, 17 AS line_seq, '平明閭巷埽花開，' AS content
UNION ALL
SELECT 'text-work-t300-060-ws' AS version_id, 18 AS line_seq, '薄暮漁樵乘水入。' AS content
UNION ALL
SELECT 'text-work-t300-060-ws' AS version_id, 19 AS line_seq, '初因避地去人間，' AS content
UNION ALL
SELECT 'text-work-t300-060-ws' AS version_id, 20 AS line_seq, '及至成仙遂不還。' AS content
UNION ALL
SELECT 'text-work-t300-060-ws' AS version_id, 21 AS line_seq, '峽裏誰知有人事，' AS content
UNION ALL
SELECT 'text-work-t300-060-ws' AS version_id, 22 AS line_seq, '世中遙望空雲山。' AS content
UNION ALL
SELECT 'text-work-t300-060-ws' AS version_id, 23 AS line_seq, '不疑靈境難聞見，' AS content
UNION ALL
SELECT 'text-work-t300-060-ws' AS version_id, 24 AS line_seq, '塵心未盡思鄉縣。' AS content
UNION ALL
SELECT 'text-work-t300-060-ws' AS version_id, 25 AS line_seq, '出洞無論隔山水，' AS content
UNION ALL
SELECT 'text-work-t300-060-ws' AS version_id, 26 AS line_seq, '辭家終擬長游衍。' AS content
UNION ALL
SELECT 'text-work-t300-060-ws' AS version_id, 27 AS line_seq, '自謂經過舊不迷，' AS content
UNION ALL
SELECT 'text-work-t300-060-ws' AS version_id, 28 AS line_seq, '安知峰壑今來變。' AS content
UNION ALL
SELECT 'text-work-t300-060-ws' AS version_id, 29 AS line_seq, '當時只記入山深，' AS content
UNION ALL
SELECT 'text-work-t300-060-ws' AS version_id, 30 AS line_seq, '青溪幾曲到雲林。' AS content
UNION ALL
SELECT 'text-work-t300-060-ws' AS version_id, 31 AS line_seq, '春來遍是桃花水，' AS content
UNION ALL
SELECT 'text-work-t300-060-ws' AS version_id, 32 AS line_seq, '不辨仙源何處尋。' AS content
UNION ALL
SELECT 'text-work-t300-061-ws' AS version_id, 1 AS line_seq, '洛陽女兒對門居，' AS content
UNION ALL
SELECT 'text-work-t300-061-ws' AS version_id, 2 AS line_seq, '纔可容顏十五餘。' AS content
UNION ALL
SELECT 'text-work-t300-061-ws' AS version_id, 3 AS line_seq, '良人玉勒乘驄馬，' AS content
UNION ALL
SELECT 'text-work-t300-061-ws' AS version_id, 4 AS line_seq, '侍女金盤鱠鯉魚。' AS content
UNION ALL
SELECT 'text-work-t300-061-ws' AS version_id, 5 AS line_seq, '畫閣朱樓盡相望，' AS content
UNION ALL
SELECT 'text-work-t300-061-ws' AS version_id, 6 AS line_seq, '紅桃綠柳垂簷向。' AS content
UNION ALL
SELECT 'text-work-t300-061-ws' AS version_id, 7 AS line_seq, '羅幃送上七香車，' AS content
UNION ALL
SELECT 'text-work-t300-061-ws' AS version_id, 8 AS line_seq, '寶扇迎歸九華帳。' AS content
UNION ALL
SELECT 'text-work-t300-061-ws' AS version_id, 9 AS line_seq, '狂夫富貴在青春，' AS content
UNION ALL
SELECT 'text-work-t300-061-ws' AS version_id, 10 AS line_seq, '意氣驕奢劇季倫。' AS content
UNION ALL
SELECT 'text-work-t300-061-ws' AS version_id, 11 AS line_seq, '自憐碧玉親教舞，' AS content
UNION ALL
SELECT 'text-work-t300-061-ws' AS version_id, 12 AS line_seq, '不惜珊瑚持與人。' AS content
UNION ALL
SELECT 'text-work-t300-061-ws' AS version_id, 13 AS line_seq, '春窗曙滅九微火，' AS content
UNION ALL
SELECT 'text-work-t300-061-ws' AS version_id, 14 AS line_seq, '九微片片飛花璅。' AS content
UNION ALL
SELECT 'text-work-t300-061-ws' AS version_id, 15 AS line_seq, '戲罷曾無理曲時，' AS content
UNION ALL
SELECT 'text-work-t300-061-ws' AS version_id, 16 AS line_seq, '妝成秪是薰香坐。' AS content
UNION ALL
SELECT 'text-work-t300-061-ws' AS version_id, 17 AS line_seq, '城中相識盡繁華，' AS content
UNION ALL
SELECT 'text-work-t300-061-ws' AS version_id, 18 AS line_seq, '日夜經過趙李家。' AS content
UNION ALL
SELECT 'text-work-t300-061-ws' AS version_id, 19 AS line_seq, '誰憐越女顏如玉，' AS content
UNION ALL
SELECT 'text-work-t300-061-ws' AS version_id, 20 AS line_seq, '貧賤江頭自浣紗。' AS content
UNION ALL
SELECT 'text-work-t300-062-ws' AS version_id, 1 AS line_seq, '寒山轉蒼翠，' AS content
UNION ALL
SELECT 'text-work-t300-062-ws' AS version_id, 2 AS line_seq, '秋水日潺湲。' AS content
UNION ALL
SELECT 'text-work-t300-062-ws' AS version_id, 3 AS line_seq, '倚杖柴門外，' AS content
UNION ALL
SELECT 'text-work-t300-062-ws' AS version_id, 4 AS line_seq, '臨風聽暮蟬。' AS content
UNION ALL
SELECT 'text-work-t300-062-ws' AS version_id, 5 AS line_seq, '渡頭餘落日，' AS content
UNION ALL
SELECT 'text-work-t300-062-ws' AS version_id, 6 AS line_seq, '墟里上孤煙。' AS content
UNION ALL
SELECT 'text-work-t300-062-ws' AS version_id, 7 AS line_seq, '復值接輿醉，' AS content
UNION ALL
SELECT 'text-work-t300-062-ws' AS version_id, 8 AS line_seq, '狂歌五柳前。' AS content
UNION ALL
SELECT 'text-work-t300-063-ws' AS version_id, 1 AS line_seq, '晚年唯好靜，' AS content
UNION ALL
SELECT 'text-work-t300-063-ws' AS version_id, 2 AS line_seq, '萬事不關心。' AS content
UNION ALL
SELECT 'text-work-t300-063-ws' AS version_id, 3 AS line_seq, '自顧無長策，' AS content
UNION ALL
SELECT 'text-work-t300-063-ws' AS version_id, 4 AS line_seq, '空知返舊林。' AS content
UNION ALL
SELECT 'text-work-t300-063-ws' AS version_id, 5 AS line_seq, '松風吹解帶，' AS content
UNION ALL
SELECT 'text-work-t300-063-ws' AS version_id, 6 AS line_seq, '山月照彈琴。' AS content
UNION ALL
SELECT 'text-work-t300-063-ws' AS version_id, 7 AS line_seq, '君問窮通理，' AS content
UNION ALL
SELECT 'text-work-t300-063-ws' AS version_id, 8 AS line_seq, '漁歌入浦深。' AS content
UNION ALL
SELECT 'text-work-t300-064-ws' AS version_id, 1 AS line_seq, '萬壑樹參天，' AS content
UNION ALL
SELECT 'text-work-t300-064-ws' AS version_id, 2 AS line_seq, '千山響杜鵑。' AS content
UNION ALL
SELECT 'text-work-t300-064-ws' AS version_id, 3 AS line_seq, '山中一夜雨，' AS content
UNION ALL
SELECT 'text-work-t300-064-ws' AS version_id, 4 AS line_seq, '樹杪百重泉。' AS content
UNION ALL
SELECT 'text-work-t300-064-ws' AS version_id, 5 AS line_seq, '漢女輸橦布，' AS content
UNION ALL
SELECT 'text-work-t300-064-ws' AS version_id, 6 AS line_seq, '巴人訟芋田。' AS content
UNION ALL
SELECT 'text-work-t300-064-ws' AS version_id, 7 AS line_seq, '文翁翻教授，' AS content
UNION ALL
SELECT 'text-work-t300-064-ws' AS version_id, 8 AS line_seq, '不敢倚先賢。' AS content
UNION ALL
SELECT 'text-work-t300-074-ws' AS version_id, 1 AS line_seq, '煙籠寒水月籠沙，' AS content
UNION ALL
SELECT 'text-work-t300-074-ws' AS version_id, 2 AS line_seq, '夜泊秦淮近酒家。' AS content
UNION ALL
SELECT 'text-work-t300-074-ws' AS version_id, 3 AS line_seq, '商女不知亡國恨，' AS content
UNION ALL
SELECT 'text-work-t300-074-ws' AS version_id, 4 AS line_seq, '隔江猶唱後庭花。' AS content
UNION ALL
SELECT 'text-work-t300-079-ws' AS version_id, 1 AS line_seq, '繁華事散逐香塵，' AS content
UNION ALL
SELECT 'text-work-t300-079-ws' AS version_id, 2 AS line_seq, '流水無情草自春。' AS content
UNION ALL
SELECT 'text-work-t300-079-ws' AS version_id, 3 AS line_seq, '日暮東風怨啼鳥，' AS content
UNION ALL
SELECT 'text-work-t300-079-ws' AS version_id, 4 AS line_seq, '落花猶似墮樓人。' AS content
UNION ALL
SELECT 'text-work-t300-087-ws' AS version_id, 1 AS line_seq, '十年離亂後，' AS content
UNION ALL
SELECT 'text-work-t300-087-ws' AS version_id, 2 AS line_seq, '長大一相逢。' AS content
UNION ALL
SELECT 'text-work-t300-087-ws' AS version_id, 3 AS line_seq, '問姓驚初見，' AS content
UNION ALL
SELECT 'text-work-t300-087-ws' AS version_id, 4 AS line_seq, '稱名憶舊容。' AS content
UNION ALL
SELECT 'text-work-t300-087-ws' AS version_id, 5 AS line_seq, '別來滄海事，' AS content
UNION ALL
SELECT 'text-work-t300-087-ws' AS version_id, 6 AS line_seq, '語罷暮天鐘。' AS content
UNION ALL
SELECT 'text-work-t300-087-ws' AS version_id, 7 AS line_seq, '明日巴陵道，' AS content
UNION ALL
SELECT 'text-work-t300-087-ws' AS version_id, 8 AS line_seq, '秋山又幾重。' AS content
UNION ALL
SELECT 'text-work-t300-097-ws' AS version_id, 1 AS line_seq, '鄉心新歲切，' AS content
UNION ALL
SELECT 'text-work-t300-097-ws' AS version_id, 2 AS line_seq, '天畔獨潸然。' AS content
UNION ALL
SELECT 'text-work-t300-097-ws' AS version_id, 3 AS line_seq, '老至居人下，' AS content
UNION ALL
SELECT 'text-work-t300-097-ws' AS version_id, 4 AS line_seq, '春歸在客先。' AS content
UNION ALL
SELECT 'text-work-t300-097-ws' AS version_id, 5 AS line_seq, '嶺猨同旦暮，' AS content
UNION ALL
SELECT 'text-work-t300-097-ws' AS version_id, 6 AS line_seq, '江柳共風煙。' AS content
UNION ALL
SELECT 'text-work-t300-097-ws' AS version_id, 7 AS line_seq, '已是長沙傅，' AS content
UNION ALL
SELECT 'text-work-t300-097-ws' AS version_id, 8 AS line_seq, '從今又幾年。' AS content
UNION ALL
SELECT 'text-work-t300-100-ws' AS version_id, 1 AS line_seq, '望君煙水闊，' AS content
UNION ALL
SELECT 'text-work-t300-100-ws' AS version_id, 2 AS line_seq, '揮手淚霑巾。' AS content
UNION ALL
SELECT 'text-work-t300-100-ws' AS version_id, 3 AS line_seq, '飛鳥沒何處，' AS content
UNION ALL
SELECT 'text-work-t300-100-ws' AS version_id, 4 AS line_seq, '青山空向人。' AS content
UNION ALL
SELECT 'text-work-t300-100-ws' AS version_id, 5 AS line_seq, '長江一帆遠，' AS content
UNION ALL
SELECT 'text-work-t300-100-ws' AS version_id, 6 AS line_seq, '落日五湖春。' AS content
UNION ALL
SELECT 'text-work-t300-100-ws' AS version_id, 7 AS line_seq, '誰見汀洲上，' AS content
UNION ALL
SELECT 'text-work-t300-100-ws' AS version_id, 8 AS line_seq, '相思愁白蘋。' AS content
UNION ALL
SELECT 'text-work-t300-101-ws' AS version_id, 1 AS line_seq, '生涯豈料承優詔，' AS content
UNION ALL
SELECT 'text-work-t300-101-ws' AS version_id, 2 AS line_seq, '世事空知學醉歌。' AS content
UNION ALL
SELECT 'text-work-t300-101-ws' AS version_id, 3 AS line_seq, '江上月明胡鴈過，' AS content
UNION ALL
SELECT 'text-work-t300-101-ws' AS version_id, 4 AS line_seq, '淮南木落楚山多。' AS content
UNION ALL
SELECT 'text-work-t300-101-ws' AS version_id, 5 AS line_seq, '寄身且喜滄洲近，' AS content
UNION ALL
SELECT 'text-work-t300-101-ws' AS version_id, 6 AS line_seq, '顧影無如白髮何。' AS content
UNION ALL
SELECT 'text-work-t300-101-ws' AS version_id, 7 AS line_seq, '今日龍鍾人共棄，' AS content
UNION ALL
SELECT 'text-work-t300-101-ws' AS version_id, 8 AS line_seq, '媿君猶遣慎風波。' AS content
UNION ALL
SELECT 'text-work-t300-102-ws' AS version_id, 1 AS line_seq, '三年謫宦此棲遲，' AS content
UNION ALL
SELECT 'text-work-t300-102-ws' AS version_id, 2 AS line_seq, '萬古惟留楚客悲。' AS content
UNION ALL
SELECT 'text-work-t300-102-ws' AS version_id, 3 AS line_seq, '秋草獨尋人去後，' AS content
UNION ALL
SELECT 'text-work-t300-102-ws' AS version_id, 4 AS line_seq, '寒林空見日斜時。' AS content
UNION ALL
SELECT 'text-work-t300-102-ws' AS version_id, 5 AS line_seq, '漢文有道恩猶薄，' AS content
UNION ALL
SELECT 'text-work-t300-102-ws' AS version_id, 6 AS line_seq, '湘水無情弔豈知。' AS content
UNION ALL
SELECT 'text-work-t300-102-ws' AS version_id, 7 AS line_seq, '寂寂江山搖落處，' AS content
UNION ALL
SELECT 'text-work-t300-102-ws' AS version_id, 8 AS line_seq, '憐君何事到天涯。' AS content
UNION ALL
SELECT 'text-work-t300-106-ws' AS version_id, 1 AS line_seq, '葡萄美酒夜光杯，' AS content
UNION ALL
SELECT 'text-work-t300-106-ws' AS version_id, 2 AS line_seq, '欲飲琵琶馬上催。' AS content
UNION ALL
SELECT 'text-work-t300-106-ws' AS version_id, 3 AS line_seq, '醉臥沙場君莫笑，' AS content
UNION ALL
SELECT 'text-work-t300-106-ws' AS version_id, 4 AS line_seq, '古來征戰幾人回。' AS content
UNION ALL
SELECT 'text-work-t300-108-ws' AS version_id, 1 AS line_seq, '山光忽西落，' AS content
UNION ALL
SELECT 'text-work-t300-108-ws' AS version_id, 2 AS line_seq, '池月漸東上。' AS content
UNION ALL
SELECT 'text-work-t300-108-ws' AS version_id, 3 AS line_seq, '散髮乘夕涼，' AS content
UNION ALL
SELECT 'text-work-t300-108-ws' AS version_id, 4 AS line_seq, '開軒臥閑敞。' AS content
UNION ALL
SELECT 'text-work-t300-108-ws' AS version_id, 5 AS line_seq, '荷風送香氣，' AS content
UNION ALL
SELECT 'text-work-t300-108-ws' AS version_id, 6 AS line_seq, '竹露滴清響。' AS content
UNION ALL
SELECT 'text-work-t300-108-ws' AS version_id, 7 AS line_seq, '欲取鳴琴彈，' AS content
UNION ALL
SELECT 'text-work-t300-108-ws' AS version_id, 8 AS line_seq, '恨無知音賞。' AS content
UNION ALL
SELECT 'text-work-t300-108-ws' AS version_id, 9 AS line_seq, '感此懷故人，' AS content
UNION ALL
SELECT 'text-work-t300-108-ws' AS version_id, 10 AS line_seq, '中宵勞夢想。' AS content
UNION ALL
SELECT 'text-work-t300-112-ws' AS version_id, 1 AS line_seq, '一丘常欲臥，' AS content
UNION ALL
SELECT 'text-work-t300-112-ws' AS version_id, 2 AS line_seq, '三徑苦無資。' AS content
UNION ALL
SELECT 'text-work-t300-112-ws' AS version_id, 3 AS line_seq, '北土非吾願，' AS content
UNION ALL
SELECT 'text-work-t300-112-ws' AS version_id, 4 AS line_seq, '東林懷我師。' AS content
UNION ALL
SELECT 'text-work-t300-112-ws' AS version_id, 5 AS line_seq, '黃金然桂盡，' AS content
UNION ALL
SELECT 'text-work-t300-112-ws' AS version_id, 6 AS line_seq, '壯志逐年衰。' AS content
UNION ALL
SELECT 'text-work-t300-112-ws' AS version_id, 7 AS line_seq, '日夕涼風至，' AS content
UNION ALL
SELECT 'text-work-t300-112-ws' AS version_id, 8 AS line_seq, '聞蟬但益悲。' AS content
UNION ALL
SELECT 'text-work-t300-117-ws' AS version_id, 1 AS line_seq, '人事有代謝，' AS content
UNION ALL
SELECT 'text-work-t300-117-ws' AS version_id, 2 AS line_seq, '往來成古今。' AS content
UNION ALL
SELECT 'text-work-t300-117-ws' AS version_id, 3 AS line_seq, '江山留勝跡，' AS content
UNION ALL
SELECT 'text-work-t300-117-ws' AS version_id, 4 AS line_seq, '我輩復登臨。' AS content
UNION ALL
SELECT 'text-work-t300-117-ws' AS version_id, 5 AS line_seq, '水落魚梁淺，' AS content
UNION ALL
SELECT 'text-work-t300-117-ws' AS version_id, 6 AS line_seq, '天寒夢澤深。' AS content
UNION ALL
SELECT 'text-work-t300-117-ws' AS version_id, 7 AS line_seq, '羊公碑字在，' AS content
UNION ALL
SELECT 'text-work-t300-117-ws' AS version_id, 8 AS line_seq, '讀罷淚沾襟。' AS content
UNION ALL
SELECT 'text-work-t300-118-ws' AS version_id, 1 AS line_seq, '故人具雞黍，' AS content
UNION ALL
SELECT 'text-work-t300-118-ws' AS version_id, 2 AS line_seq, '邀我至田家。' AS content
UNION ALL
SELECT 'text-work-t300-118-ws' AS version_id, 3 AS line_seq, '綠樹村邊合，' AS content
UNION ALL
SELECT 'text-work-t300-118-ws' AS version_id, 4 AS line_seq, '青山郭外斜。' AS content
UNION ALL
SELECT 'text-work-t300-118-ws' AS version_id, 5 AS line_seq, '開筵面場圃，' AS content
UNION ALL
SELECT 'text-work-t300-118-ws' AS version_id, 6 AS line_seq, '把酒話桑麻。' AS content
UNION ALL
SELECT 'text-work-t300-118-ws' AS version_id, 7 AS line_seq, '待到重陽日，' AS content
UNION ALL
SELECT 'text-work-t300-118-ws' AS version_id, 8 AS line_seq, '還來就菊花。' AS content
UNION ALL
SELECT 'text-work-t300-119-ws' AS version_id, 1 AS line_seq, '北闕休上書，' AS content
UNION ALL
SELECT 'text-work-t300-119-ws' AS version_id, 2 AS line_seq, '南山歸敝廬。' AS content
UNION ALL
SELECT 'text-work-t300-119-ws' AS version_id, 3 AS line_seq, '不才明主棄，' AS content
UNION ALL
SELECT 'text-work-t300-119-ws' AS version_id, 4 AS line_seq, '多病故人疎。' AS content
UNION ALL
SELECT 'text-work-t300-119-ws' AS version_id, 5 AS line_seq, '白髮催年老，' AS content
UNION ALL
SELECT 'text-work-t300-119-ws' AS version_id, 6 AS line_seq, '青陽逼歲除。' AS content
UNION ALL
SELECT 'text-work-t300-119-ws' AS version_id, 7 AS line_seq, '永懷愁不寐，' AS content
UNION ALL
SELECT 'text-work-t300-119-ws' AS version_id, 8 AS line_seq, '松月夜窗虛。' AS content
UNION ALL
SELECT 'text-work-t300-121-ws' AS version_id, 1 AS line_seq, '春眠不覺曉，' AS content
UNION ALL
SELECT 'text-work-t300-121-ws' AS version_id, 2 AS line_seq, '處處聞啼鳥。' AS content
UNION ALL
SELECT 'text-work-t300-121-ws' AS version_id, 3 AS line_seq, '夜來風雨聲，' AS content
UNION ALL
SELECT 'text-work-t300-121-ws' AS version_id, 4 AS line_seq, '花落知多少。' AS content
UNION ALL
SELECT 'text-work-t300-122-ws' AS version_id, 1 AS line_seq, '移舟泊煙渚，' AS content
UNION ALL
SELECT 'text-work-t300-122-ws' AS version_id, 2 AS line_seq, '日暮客愁新。' AS content
UNION ALL
SELECT 'text-work-t300-122-ws' AS version_id, 3 AS line_seq, '野曠天低樹，' AS content
UNION ALL
SELECT 'text-work-t300-122-ws' AS version_id, 4 AS line_seq, '江清月近人。' AS content
UNION ALL
SELECT 'text-work-t300-131-ws' AS version_id, 1 AS line_seq, '雲開遠見漢陽城，' AS content
UNION ALL
SELECT 'text-work-t300-131-ws' AS version_id, 2 AS line_seq, '猶是孤帆一日程。' AS content
UNION ALL
SELECT 'text-work-t300-131-ws' AS version_id, 3 AS line_seq, '估客晝眠知浪靜，' AS content
UNION ALL
SELECT 'text-work-t300-131-ws' AS version_id, 4 AS line_seq, '舟人夜語覺潮生。' AS content
UNION ALL
SELECT 'text-work-t300-131-ws' AS version_id, 5 AS line_seq, '三湘衰鬢逢秋色，' AS content
UNION ALL
SELECT 'text-work-t300-131-ws' AS version_id, 6 AS line_seq, '萬里歸心對月明。' AS content
UNION ALL
SELECT 'text-work-t300-131-ws' AS version_id, 7 AS line_seq, '舊業已隨征戰盡，' AS content
UNION ALL
SELECT 'text-work-t300-131-ws' AS version_id, 8 AS line_seq, '更堪江上鼓鼙聲。' AS content
UNION ALL
SELECT 'text-work-t300-133-ws' AS version_id, 1 AS line_seq, '不知香積寺，' AS content
UNION ALL
SELECT 'text-work-t300-133-ws' AS version_id, 2 AS line_seq, '數里入雲峰。' AS content
UNION ALL
SELECT 'text-work-t300-133-ws' AS version_id, 3 AS line_seq, '古木無人逕，' AS content
UNION ALL
SELECT 'text-work-t300-133-ws' AS version_id, 4 AS line_seq, '深山何處鐘。' AS content
UNION ALL
SELECT 'text-work-t300-133-ws' AS version_id, 5 AS line_seq, '泉聲咽危石，' AS content
UNION ALL
SELECT 'text-work-t300-133-ws' AS version_id, 6 AS line_seq, '日色冷青松。' AS content
UNION ALL
SELECT 'text-work-t300-133-ws' AS version_id, 7 AS line_seq, '薄暮空潭曲，' AS content
UNION ALL
SELECT 'text-work-t300-133-ws' AS version_id, 8 AS line_seq, '安禪制毒龍。' AS content
UNION ALL
SELECT 'text-work-t300-134-ws' AS version_id, 1 AS line_seq, '空山新雨後，' AS content
UNION ALL
SELECT 'text-work-t300-134-ws' AS version_id, 2 AS line_seq, '天氣晚來秋。' AS content
UNION ALL
SELECT 'text-work-t300-134-ws' AS version_id, 3 AS line_seq, '明月松間照，' AS content
UNION ALL
SELECT 'text-work-t300-134-ws' AS version_id, 4 AS line_seq, '清泉石上流。' AS content
UNION ALL
SELECT 'text-work-t300-134-ws' AS version_id, 5 AS line_seq, '竹喧歸浣女，' AS content
UNION ALL
SELECT 'text-work-t300-134-ws' AS version_id, 6 AS line_seq, '蓮動下漁舟。' AS content
UNION ALL
SELECT 'text-work-t300-134-ws' AS version_id, 7 AS line_seq, '隨意春芳歇，' AS content
UNION ALL
SELECT 'text-work-t300-134-ws' AS version_id, 8 AS line_seq, '王孫自可留。' AS content
UNION ALL
SELECT 'text-work-t300-135-ws' AS version_id, 1 AS line_seq, '中歲頗好道，' AS content
UNION ALL
SELECT 'text-work-t300-135-ws' AS version_id, 2 AS line_seq, '晚家南山陲。' AS content
UNION ALL
SELECT 'text-work-t300-135-ws' AS version_id, 3 AS line_seq, '興來每獨往，' AS content
UNION ALL
SELECT 'text-work-t300-135-ws' AS version_id, 4 AS line_seq, '勝事空自知。' AS content
UNION ALL
SELECT 'text-work-t300-135-ws' AS version_id, 5 AS line_seq, '行到水窮處，' AS content
UNION ALL
SELECT 'text-work-t300-135-ws' AS version_id, 6 AS line_seq, '坐看雲起時。' AS content
UNION ALL
SELECT 'text-work-t300-135-ws' AS version_id, 7 AS line_seq, '偶然值林叟，' AS content
UNION ALL
SELECT 'text-work-t300-135-ws' AS version_id, 8 AS line_seq, '談笑無還期。' AS content
UNION ALL
SELECT 'text-work-t300-136-ws' AS version_id, 1 AS line_seq, '清川帶長薄，' AS content
UNION ALL
SELECT 'text-work-t300-136-ws' AS version_id, 2 AS line_seq, '車馬去閑閑。' AS content
UNION ALL
SELECT 'text-work-t300-136-ws' AS version_id, 3 AS line_seq, '流水如有意，' AS content
UNION ALL
SELECT 'text-work-t300-136-ws' AS version_id, 4 AS line_seq, '暮禽相與還。' AS content
UNION ALL
SELECT 'text-work-t300-136-ws' AS version_id, 5 AS line_seq, '荒城臨古渡，' AS content
UNION ALL
SELECT 'text-work-t300-136-ws' AS version_id, 6 AS line_seq, '落日滿秋山。' AS content
UNION ALL
SELECT 'text-work-t300-136-ws' AS version_id, 7 AS line_seq, '迢遞嵩高下，' AS content
UNION ALL
SELECT 'text-work-t300-136-ws' AS version_id, 8 AS line_seq, '歸來且閉關。' AS content
UNION ALL
SELECT 'text-work-t300-137-ws' AS version_id, 1 AS line_seq, '太乙近天都，' AS content
UNION ALL
SELECT 'text-work-t300-137-ws' AS version_id, 2 AS line_seq, '連山接海隅。' AS content
UNION ALL
SELECT 'text-work-t300-137-ws' AS version_id, 3 AS line_seq, '白雲迴望合，' AS content
UNION ALL
SELECT 'text-work-t300-137-ws' AS version_id, 4 AS line_seq, '青靄入看無。' AS content
UNION ALL
SELECT 'text-work-t300-137-ws' AS version_id, 5 AS line_seq, '分野中峰變，' AS content
UNION ALL
SELECT 'text-work-t300-137-ws' AS version_id, 6 AS line_seq, '陰晴衆壑殊。' AS content
UNION ALL
SELECT 'text-work-t300-137-ws' AS version_id, 7 AS line_seq, '欲投人處宿，' AS content
UNION ALL
SELECT 'text-work-t300-137-ws' AS version_id, 8 AS line_seq, '隔水問樵夫。' AS content
UNION ALL
SELECT 'text-work-t300-140-ws' AS version_id, 1 AS line_seq, '絳幘雞人送曉籌，' AS content
UNION ALL
SELECT 'text-work-t300-140-ws' AS version_id, 2 AS line_seq, '尚衣方進翠雲裘。' AS content
UNION ALL
SELECT 'text-work-t300-140-ws' AS version_id, 3 AS line_seq, '九天閶闔開宮殿，' AS content
UNION ALL
SELECT 'text-work-t300-140-ws' AS version_id, 4 AS line_seq, '萬國衣冠拜冕旒。' AS content
UNION ALL
SELECT 'text-work-t300-140-ws' AS version_id, 5 AS line_seq, '日色纔臨仙掌動，' AS content
UNION ALL
SELECT 'text-work-t300-140-ws' AS version_id, 6 AS line_seq, '香煙欲傍衮龍浮。' AS content
UNION ALL
SELECT 'text-work-t300-140-ws' AS version_id, 7 AS line_seq, '朝罷須裁五色詔，' AS content
UNION ALL
SELECT 'text-work-t300-140-ws' AS version_id, 8 AS line_seq, '佩聲歸向鳳池頭。' AS content
UNION ALL
SELECT 'text-work-t300-142-ws' AS version_id, 1 AS line_seq, '積雨空林煙火遲，' AS content
UNION ALL
SELECT 'text-work-t300-142-ws' AS version_id, 2 AS line_seq, '蒸藜炊黍餉東菑。' AS content
UNION ALL
SELECT 'text-work-t300-142-ws' AS version_id, 3 AS line_seq, '漠漠水田飛白鷺，' AS content
UNION ALL
SELECT 'text-work-t300-142-ws' AS version_id, 4 AS line_seq, '陰陰夏木囀黃鸝。' AS content
UNION ALL
SELECT 'text-work-t300-142-ws' AS version_id, 5 AS line_seq, '山中習靜觀朝槿，' AS content
UNION ALL
SELECT 'text-work-t300-142-ws' AS version_id, 6 AS line_seq, '松下清齋折露葵。' AS content
UNION ALL
SELECT 'text-work-t300-142-ws' AS version_id, 7 AS line_seq, '野老與人爭席罷，' AS content
UNION ALL
SELECT 'text-work-t300-142-ws' AS version_id, 8 AS line_seq, '海鷗何事更相疑。' AS content
UNION ALL
SELECT 'text-work-t300-145-ws' AS version_id, 1 AS line_seq, '山中相送罷，' AS content
UNION ALL
SELECT 'text-work-t300-145-ws' AS version_id, 2 AS line_seq, '日暮掩柴扉。' AS content
UNION ALL
SELECT 'text-work-t300-145-ws' AS version_id, 3 AS line_seq, '春草明年綠，' AS content
UNION ALL
SELECT 'text-work-t300-145-ws' AS version_id, 4 AS line_seq, '王孫歸不歸。' AS content
UNION ALL
SELECT 'text-work-t300-146-ws' AS version_id, 1 AS line_seq, '君自故鄉來，' AS content
UNION ALL
SELECT 'text-work-t300-146-ws' AS version_id, 2 AS line_seq, '應知故鄉事。' AS content
UNION ALL
SELECT 'text-work-t300-146-ws' AS version_id, 3 AS line_seq, '來日綺窗前，' AS content
UNION ALL
SELECT 'text-work-t300-146-ws' AS version_id, 4 AS line_seq, '寒梅着花未。' AS content
UNION ALL
SELECT 'text-work-t300-148-ws' AS version_id, 1 AS line_seq, '獨在異鄉爲異客，' AS content
UNION ALL
SELECT 'text-work-t300-148-ws' AS version_id, 2 AS line_seq, '每逢佳節倍思親。' AS content
UNION ALL
SELECT 'text-work-t300-148-ws' AS version_id, 3 AS line_seq, '遙知兄弟登高處，' AS content
UNION ALL
SELECT 'text-work-t300-148-ws' AS version_id, 4 AS line_seq, '遍插茱萸少一人。' AS content
UNION ALL
SELECT 'text-work-t300-151-ws' AS version_id, 1 AS line_seq, '絕頂一茅茨，' AS content
UNION ALL
SELECT 'text-work-t300-151-ws' AS version_id, 2 AS line_seq, '直[上]三十里。' AS content
UNION ALL
SELECT 'text-work-t300-151-ws' AS version_id, 3 AS line_seq, '扣關無僮僕，' AS content
UNION ALL
SELECT 'text-work-t300-151-ws' AS version_id, 4 AS line_seq, '窺室唯案几。' AS content
UNION ALL
SELECT 'text-work-t300-151-ws' AS version_id, 5 AS line_seq, '若非巾柴車，' AS content
UNION ALL
SELECT 'text-work-t300-151-ws' AS version_id, 6 AS line_seq, '應是釣秋水。' AS content
UNION ALL
SELECT 'text-work-t300-151-ws' AS version_id, 7 AS line_seq, '差池不相見，' AS content
UNION ALL
SELECT 'text-work-t300-151-ws' AS version_id, 8 AS line_seq, '黽勉空仰止。' AS content
UNION ALL
SELECT 'text-work-t300-151-ws' AS version_id, 9 AS line_seq, '草色新雨中，' AS content
UNION ALL
SELECT 'text-work-t300-151-ws' AS version_id, 10 AS line_seq, '松聲晚牕裏。' AS content
UNION ALL
SELECT 'text-work-t300-151-ws' AS version_id, 11 AS line_seq, '及茲契幽絕，' AS content
UNION ALL
SELECT 'text-work-t300-151-ws' AS version_id, 12 AS line_seq, '自足蕩心耳。' AS content
UNION ALL
SELECT 'text-work-t300-151-ws' AS version_id, 13 AS line_seq, '雖無賓主意，' AS content
UNION ALL
SELECT 'text-work-t300-151-ws' AS version_id, 14 AS line_seq, '頗得清淨理。' AS content
UNION ALL
SELECT 'text-work-t300-151-ws' AS version_id, 15 AS line_seq, '興盡方下山，' AS content
UNION ALL
SELECT 'text-work-t300-151-ws' AS version_id, 16 AS line_seq, '何必待之子。' AS content
UNION ALL
SELECT 'text-work-t300-153-ws' AS version_id, 1 AS line_seq, '岧嶤太華俯咸京，' AS content
UNION ALL
SELECT 'text-work-t300-153-ws' AS version_id, 2 AS line_seq, '天外三峰削不成。' AS content
UNION ALL
SELECT 'text-work-t300-153-ws' AS version_id, 3 AS line_seq, '武帝祠前雲欲散，' AS content
UNION ALL
SELECT 'text-work-t300-153-ws' AS version_id, 4 AS line_seq, '仙人掌上雨初晴。' AS content
UNION ALL
SELECT 'text-work-t300-153-ws' AS version_id, 5 AS line_seq, '河山北枕秦關險，' AS content
UNION ALL
SELECT 'text-work-t300-153-ws' AS version_id, 6 AS line_seq, '驛樹西連漢畤平。' AS content
UNION ALL
SELECT 'text-work-t300-153-ws' AS version_id, 7 AS line_seq, '借問路傍名利客，' AS content
UNION ALL
SELECT 'text-work-t300-153-ws' AS version_id, 8 AS line_seq, '無如此處學長生。' AS content
UNION ALL
SELECT 'text-work-t300-156-ws' AS version_id, 1 AS line_seq, '燕臺一望客心驚，' AS content
UNION ALL
SELECT 'text-work-t300-156-ws' AS version_id, 2 AS line_seq, '簫鼓喧喧漢將營。' AS content
UNION ALL
SELECT 'text-work-t300-156-ws' AS version_id, 3 AS line_seq, '萬里寒光生積雪，' AS content
UNION ALL
SELECT 'text-work-t300-156-ws' AS version_id, 4 AS line_seq, '三邊曙色動危旌。' AS content
UNION ALL
SELECT 'text-work-t300-156-ws' AS version_id, 5 AS line_seq, '沙場烽火連胡月，' AS content
UNION ALL
SELECT 'text-work-t300-156-ws' AS version_id, 6 AS line_seq, '海畔雲山擁薊城。' AS content
UNION ALL
SELECT 'text-work-t300-156-ws' AS version_id, 7 AS line_seq, '少小雖非投筆吏，' AS content
UNION ALL
SELECT 'text-work-t300-156-ws' AS version_id, 8 AS line_seq, '論功還欲請長纓。' AS content
UNION ALL
SELECT 'text-work-t300-157-ws' AS version_id, 1 AS line_seq, '終南陰嶺秀，' AS content
UNION ALL
SELECT 'text-work-t300-157-ws' AS version_id, 2 AS line_seq, '積雪浮雲端。' AS content
UNION ALL
SELECT 'text-work-t300-157-ws' AS version_id, 3 AS line_seq, '林表明霽色，' AS content
UNION ALL
SELECT 'text-work-t300-157-ws' AS version_id, 4 AS line_seq, '城中增暮寒。' AS content
UNION ALL
SELECT 'text-work-t300-158-ws' AS version_id, 1 AS line_seq, '白日登山望烽火，' AS content
UNION ALL
SELECT 'text-work-t300-158-ws' AS version_id, 2 AS line_seq, '黃昏飲馬傍交河。' AS content
UNION ALL
SELECT 'text-work-t300-158-ws' AS version_id, 3 AS line_seq, '行人刁斗風沙暗，' AS content
UNION ALL
SELECT 'text-work-t300-158-ws' AS version_id, 4 AS line_seq, '公主琵琶幽怨多。' AS content
UNION ALL
SELECT 'text-work-t300-158-ws' AS version_id, 5 AS line_seq, '野雲萬里無城郭，' AS content
UNION ALL
SELECT 'text-work-t300-158-ws' AS version_id, 6 AS line_seq, '雨雪紛紛連大漠。' AS content
UNION ALL
SELECT 'text-work-t300-158-ws' AS version_id, 7 AS line_seq, '胡鴈哀鳴夜夜飛，' AS content
UNION ALL
SELECT 'text-work-t300-158-ws' AS version_id, 8 AS line_seq, '胡兒眼淚雙雙落。' AS content
UNION ALL
SELECT 'text-work-t300-158-ws' AS version_id, 9 AS line_seq, '聞道玉門猶被遮，' AS content
UNION ALL
SELECT 'text-work-t300-158-ws' AS version_id, 10 AS line_seq, '應將性命逐輕車。' AS content
UNION ALL
SELECT 'text-work-t300-158-ws' AS version_id, 11 AS line_seq, '年年戰骨埋荒外，' AS content
UNION ALL
SELECT 'text-work-t300-158-ws' AS version_id, 12 AS line_seq, '空見蒲桃入漢家。' AS content
UNION ALL
SELECT 'text-work-t300-159-ws' AS version_id, 1 AS line_seq, '主人有酒歡今夕，' AS content
UNION ALL
SELECT 'text-work-t300-159-ws' AS version_id, 2 AS line_seq, '請奏鳴琴廣陵客。' AS content
UNION ALL
SELECT 'text-work-t300-159-ws' AS version_id, 3 AS line_seq, '月照城頭烏半飛，' AS content
UNION ALL
SELECT 'text-work-t300-159-ws' AS version_id, 4 AS line_seq, '霜淒萬樹風入衣。' AS content
UNION ALL
SELECT 'text-work-t300-159-ws' AS version_id, 5 AS line_seq, '銅鑪華燭燭增輝，' AS content
UNION ALL
SELECT 'text-work-t300-159-ws' AS version_id, 6 AS line_seq, '初彈淥水後楚妃。' AS content
UNION ALL
SELECT 'text-work-t300-159-ws' AS version_id, 7 AS line_seq, '一聲已動物皆靜，' AS content
UNION ALL
SELECT 'text-work-t300-159-ws' AS version_id, 8 AS line_seq, '四座無言星欲稀。' AS content
UNION ALL
SELECT 'text-work-t300-159-ws' AS version_id, 9 AS line_seq, '清淮奉使千餘里，' AS content
UNION ALL
SELECT 'text-work-t300-159-ws' AS version_id, 10 AS line_seq, '敢告雲山從此始。' AS content
UNION ALL
SELECT 'text-work-t300-160-ws' AS version_id, 1 AS line_seq, '四月南風大麥黃，' AS content
UNION ALL
SELECT 'text-work-t300-160-ws' AS version_id, 2 AS line_seq, '棗花未落桐陰長。' AS content
UNION ALL
SELECT 'text-work-t300-160-ws' AS version_id, 3 AS line_seq, '青山朝別暮還見，' AS content
UNION ALL
SELECT 'text-work-t300-160-ws' AS version_id, 4 AS line_seq, '嘶馬出門思舊鄉。' AS content
UNION ALL
SELECT 'text-work-t300-160-ws' AS version_id, 5 AS line_seq, '陳侯立身何坦蕩，' AS content
UNION ALL
SELECT 'text-work-t300-160-ws' AS version_id, 6 AS line_seq, '虬鬚虎眉仍大顙。' AS content
UNION ALL
SELECT 'text-work-t300-160-ws' AS version_id, 7 AS line_seq, '腹中貯書一萬卷，' AS content
UNION ALL
SELECT 'text-work-t300-160-ws' AS version_id, 8 AS line_seq, '不肯低頭在草莽。' AS content
UNION ALL
SELECT 'text-work-t300-160-ws' AS version_id, 9 AS line_seq, '東門酤酒飲我曹，' AS content
UNION ALL
SELECT 'text-work-t300-160-ws' AS version_id, 10 AS line_seq, '心輕萬事皆鴻毛。' AS content
UNION ALL
SELECT 'text-work-t300-160-ws' AS version_id, 11 AS line_seq, '醉臥不知白日暮，' AS content
UNION ALL
SELECT 'text-work-t300-160-ws' AS version_id, 12 AS line_seq, '有時空望孤雲高。' AS content
UNION ALL
SELECT 'text-work-t300-160-ws' AS version_id, 13 AS line_seq, '長河浪頭連天黑，' AS content
UNION ALL
SELECT 'text-work-t300-160-ws' AS version_id, 14 AS line_seq, '津口停舟渡不得。' AS content
UNION ALL
SELECT 'text-work-t300-160-ws' AS version_id, 15 AS line_seq, '鄭國遊人未及家，' AS content
UNION ALL
SELECT 'text-work-t300-160-ws' AS version_id, 16 AS line_seq, '洛陽行子空歎息。' AS content
UNION ALL
SELECT 'text-work-t300-160-ws' AS version_id, 17 AS line_seq, '聞道故林相識多，' AS content
UNION ALL
SELECT 'text-work-t300-160-ws' AS version_id, 18 AS line_seq, '罷官昨日今如何。' AS content
UNION ALL
SELECT 'text-work-t300-161-ws' AS version_id, 1 AS line_seq, '南山截竹爲觱篥，' AS content
UNION ALL
SELECT 'text-work-t300-161-ws' AS version_id, 2 AS line_seq, '此樂本自龜茲出。' AS content
UNION ALL
SELECT 'text-work-t300-161-ws' AS version_id, 3 AS line_seq, '流傳漢地曲轉奇，' AS content
UNION ALL
SELECT 'text-work-t300-161-ws' AS version_id, 4 AS line_seq, '涼州胡人爲我吹。' AS content
UNION ALL
SELECT 'text-work-t300-161-ws' AS version_id, 5 AS line_seq, '傍鄰聞者多歎息，' AS content
UNION ALL
SELECT 'text-work-t300-161-ws' AS version_id, 6 AS line_seq, '遠客思鄉皆淚垂。' AS content
UNION ALL
SELECT 'text-work-t300-161-ws' AS version_id, 7 AS line_seq, '世人解聽不解賞，' AS content
UNION ALL
SELECT 'text-work-t300-161-ws' AS version_id, 8 AS line_seq, '長飆風中自來往。' AS content
UNION ALL
SELECT 'text-work-t300-161-ws' AS version_id, 9 AS line_seq, '枯桑老柏寒颼飀，' AS content
UNION ALL
SELECT 'text-work-t300-161-ws' AS version_id, 10 AS line_seq, '九雛鳴鳳亂啾啾。' AS content
UNION ALL
SELECT 'text-work-t300-161-ws' AS version_id, 11 AS line_seq, '龍吟虎嘯一時發，' AS content
UNION ALL
SELECT 'text-work-t300-161-ws' AS version_id, 12 AS line_seq, '萬籟百泉相與秋。' AS content
UNION ALL
SELECT 'text-work-t300-161-ws' AS version_id, 13 AS line_seq, '忽然更作漁陽摻，' AS content
UNION ALL
SELECT 'text-work-t300-161-ws' AS version_id, 14 AS line_seq, '黃雲蕭條白日暗。' AS content
UNION ALL
SELECT 'text-work-t300-161-ws' AS version_id, 15 AS line_seq, '變調如聞楊柳春，' AS content
UNION ALL
SELECT 'text-work-t300-161-ws' AS version_id, 16 AS line_seq, '上林繁花照眼新。' AS content
UNION ALL
SELECT 'text-work-t300-161-ws' AS version_id, 17 AS line_seq, '歲夜高堂列明燭，' AS content
UNION ALL
SELECT 'text-work-t300-161-ws' AS version_id, 18 AS line_seq, '美酒一杯聲一曲。' AS content
UNION ALL
SELECT 'text-work-t300-162-ws' AS version_id, 1 AS line_seq, '男兒事長征，' AS content
UNION ALL
SELECT 'text-work-t300-162-ws' AS version_id, 2 AS line_seq, '少小幽燕客。' AS content
UNION ALL
SELECT 'text-work-t300-162-ws' AS version_id, 3 AS line_seq, '賭勝馬蹄下，' AS content
UNION ALL
SELECT 'text-work-t300-162-ws' AS version_id, 4 AS line_seq, '由來輕七尺。' AS content
UNION ALL
SELECT 'text-work-t300-162-ws' AS version_id, 5 AS line_seq, '殺人莫敢前，' AS content
UNION ALL
SELECT 'text-work-t300-162-ws' AS version_id, 6 AS line_seq, '鬚如蝟毛磔。' AS content
UNION ALL
SELECT 'text-work-t300-162-ws' AS version_id, 7 AS line_seq, '黃雲隴底白雪飛，' AS content
UNION ALL
SELECT 'text-work-t300-162-ws' AS version_id, 8 AS line_seq, '未得報恩不能歸。' AS content
UNION ALL
SELECT 'text-work-t300-162-ws' AS version_id, 9 AS line_seq, '遼東小婦年十五，' AS content
UNION ALL
SELECT 'text-work-t300-162-ws' AS version_id, 10 AS line_seq, '慣彈琵琶解歌舞。' AS content
UNION ALL
SELECT 'text-work-t300-162-ws' AS version_id, 11 AS line_seq, '今爲羗笛出塞聲，' AS content
UNION ALL
SELECT 'text-work-t300-162-ws' AS version_id, 12 AS line_seq, '使我三軍淚如雨。' AS content
UNION ALL
SELECT 'text-work-t300-164-ws' AS version_id, 1 AS line_seq, '朝聞遊子唱離歌，' AS content
UNION ALL
SELECT 'text-work-t300-164-ws' AS version_id, 2 AS line_seq, '昨夜微霜初渡河。' AS content
UNION ALL
SELECT 'text-work-t300-164-ws' AS version_id, 3 AS line_seq, '鴻鴈不堪愁裏聽，' AS content
UNION ALL
SELECT 'text-work-t300-164-ws' AS version_id, 4 AS line_seq, '雲山況是客中過。' AS content
UNION ALL
SELECT 'text-work-t300-164-ws' AS version_id, 5 AS line_seq, '關城樹色催寒近，' AS content
UNION ALL
SELECT 'text-work-t300-164-ws' AS version_id, 6 AS line_seq, '御苑砧聲向晚多。' AS content
UNION ALL
SELECT 'text-work-t300-164-ws' AS version_id, 7 AS line_seq, '莫見長安行樂處，' AS content
UNION ALL
SELECT 'text-work-t300-164-ws' AS version_id, 8 AS line_seq, '空令歲月易蹉跎。' AS content
UNION ALL
SELECT 'text-work-t300-165-ws' AS version_id, 1 AS line_seq, '幽意無斷絕，' AS content
UNION ALL
SELECT 'text-work-t300-165-ws' AS version_id, 2 AS line_seq, '此去隨所偶。' AS content
UNION ALL
SELECT 'text-work-t300-165-ws' AS version_id, 3 AS line_seq, '晚風吹行舟，' AS content
UNION ALL
SELECT 'text-work-t300-165-ws' AS version_id, 4 AS line_seq, '花路入溪口。' AS content
UNION ALL
SELECT 'text-work-t300-165-ws' AS version_id, 5 AS line_seq, '際夜轉西壑，' AS content
UNION ALL
SELECT 'text-work-t300-165-ws' AS version_id, 6 AS line_seq, '隔山望南斗。' AS content
UNION ALL
SELECT 'text-work-t300-165-ws' AS version_id, 7 AS line_seq, '潭煙飛溶溶，' AS content
UNION ALL
SELECT 'text-work-t300-165-ws' AS version_id, 8 AS line_seq, '林月低向後。' AS content
UNION ALL
SELECT 'text-work-t300-165-ws' AS version_id, 9 AS line_seq, '生事且彌漫，' AS content
UNION ALL
SELECT 'text-work-t300-165-ws' AS version_id, 10 AS line_seq, '願爲持竿叟。' AS content
UNION ALL
SELECT 'text-work-t300-169-ws' AS version_id, 1 AS line_seq, '秦時明月漢時關，' AS content
UNION ALL
SELECT 'text-work-t300-169-ws' AS version_id, 2 AS line_seq, '萬里長征人未還。' AS content
UNION ALL
SELECT 'text-work-t300-169-ws' AS version_id, 3 AS line_seq, '但使龍城飛將在，' AS content
UNION ALL
SELECT 'text-work-t300-169-ws' AS version_id, 4 AS line_seq, '不教胡馬度陰山。' AS content
UNION ALL
SELECT 'text-work-t300-170-ws' AS version_id, 1 AS line_seq, '昨夜風開露井桃，' AS content
UNION ALL
SELECT 'text-work-t300-170-ws' AS version_id, 2 AS line_seq, '未央前殿月輪高。' AS content
UNION ALL
SELECT 'text-work-t300-170-ws' AS version_id, 3 AS line_seq, '平陽歌舞新承寵，' AS content
UNION ALL
SELECT 'text-work-t300-170-ws' AS version_id, 4 AS line_seq, '簾外春寒賜錦袍。' AS content
UNION ALL
SELECT 'text-work-t300-171-ws' AS version_id, 1 AS line_seq, '閨中少婦不曾愁，' AS content
UNION ALL
SELECT 'text-work-t300-171-ws' AS version_id, 2 AS line_seq, '春日凝妝上翠樓。' AS content
UNION ALL
SELECT 'text-work-t300-171-ws' AS version_id, 3 AS line_seq, '忽見陌頭楊柳色，' AS content
UNION ALL
SELECT 'text-work-t300-171-ws' AS version_id, 4 AS line_seq, '悔教夫壻覓封侯。' AS content
UNION ALL
SELECT 'text-work-t300-173-ws' AS version_id, 1 AS line_seq, '清溪深不測，' AS content
UNION ALL
SELECT 'text-work-t300-173-ws' AS version_id, 2 AS line_seq, '隱處唯孤雲。' AS content
UNION ALL
SELECT 'text-work-t300-173-ws' AS version_id, 3 AS line_seq, '松際露微月，' AS content
UNION ALL
SELECT 'text-work-t300-173-ws' AS version_id, 4 AS line_seq, '清光猶爲君。' AS content
UNION ALL
SELECT 'text-work-t300-173-ws' AS version_id, 5 AS line_seq, '茅亭宿花影，' AS content
UNION ALL
SELECT 'text-work-t300-173-ws' AS version_id, 6 AS line_seq, '藥院滋苔紋。' AS content
UNION ALL
SELECT 'text-work-t300-173-ws' AS version_id, 7 AS line_seq, '余亦謝時去，' AS content
UNION ALL
SELECT 'text-work-t300-173-ws' AS version_id, 8 AS line_seq, '西山鸞鶴羣。' AS content
UNION ALL
SELECT 'text-work-t300-186-ws' AS version_id, 1 AS line_seq, '荒戍落黃葉，' AS content
UNION ALL
SELECT 'text-work-t300-186-ws' AS version_id, 2 AS line_seq, '浩然離故關。' AS content
UNION ALL
SELECT 'text-work-t300-186-ws' AS version_id, 3 AS line_seq, '高風漢陽渡，' AS content
UNION ALL
SELECT 'text-work-t300-186-ws' AS version_id, 4 AS line_seq, '初日郢門山。' AS content
UNION ALL
SELECT 'text-work-t300-186-ws' AS version_id, 5 AS line_seq, '江上幾人在，' AS content
UNION ALL
SELECT 'text-work-t300-186-ws' AS version_id, 6 AS line_seq, '天涯孤櫂還。' AS content
UNION ALL
SELECT 'text-work-t300-186-ws' AS version_id, 7 AS line_seq, '何當重相見，' AS content
UNION ALL
SELECT 'text-work-t300-186-ws' AS version_id, 8 AS line_seq, '尊酒慰離顏。' AS content
UNION ALL
SELECT 'text-work-t300-189-ws' AS version_id, 1 AS line_seq, '蓬門未識綺羅香，' AS content
UNION ALL
SELECT 'text-work-t300-189-ws' AS version_id, 2 AS line_seq, '擬託良媒益自傷。' AS content
UNION ALL
SELECT 'text-work-t300-189-ws' AS version_id, 3 AS line_seq, '誰愛風流高格調，' AS content
UNION ALL
SELECT 'text-work-t300-189-ws' AS version_id, 4 AS line_seq, '共憐時世儉梳妝。' AS content
UNION ALL
SELECT 'text-work-t300-189-ws' AS version_id, 5 AS line_seq, '敢將十指誇偏巧，' AS content
UNION ALL
SELECT 'text-work-t300-189-ws' AS version_id, 6 AS line_seq, '不把雙眉鬬畫長。' AS content
UNION ALL
SELECT 'text-work-t300-189-ws' AS version_id, 7 AS line_seq, '苦恨年年壓金線，' AS content
UNION ALL
SELECT 'text-work-t300-189-ws' AS version_id, 8 AS line_seq, '爲他人作嫁衣裳。' AS content
UNION ALL
SELECT 'text-work-t300-193-ws' AS version_id, 1 AS line_seq, '故國三千里，' AS content
UNION ALL
SELECT 'text-work-t300-193-ws' AS version_id, 2 AS line_seq, '深宮二十年。' AS content
UNION ALL
SELECT 'text-work-t300-193-ws' AS version_id, 3 AS line_seq, '一聲河滿子，' AS content
UNION ALL
SELECT 'text-work-t300-193-ws' AS version_id, 4 AS line_seq, '雙淚落君前。' AS content
UNION ALL
SELECT 'text-work-t300-197-ws' AS version_id, 1 AS line_seq, '金陵津渡小山樓，' AS content
UNION ALL
SELECT 'text-work-t300-197-ws' AS version_id, 2 AS line_seq, '一宿行人自可愁。' AS content
UNION ALL
SELECT 'text-work-t300-197-ws' AS version_id, 3 AS line_seq, '潮落夜江斜月裏，' AS content
UNION ALL
SELECT 'text-work-t300-197-ws' AS version_id, 4 AS line_seq, '兩三星火是瓜州。' AS content
UNION ALL
SELECT 'text-work-t300-198-ws' AS version_id, 1 AS line_seq, '寂寂花時閉院門，' AS content
UNION ALL
SELECT 'text-work-t300-198-ws' AS version_id, 2 AS line_seq, '美人相並立瓊軒。' AS content
UNION ALL
SELECT 'text-work-t300-198-ws' AS version_id, 3 AS line_seq, '含情欲說宮中事，' AS content
UNION ALL
SELECT 'text-work-t300-198-ws' AS version_id, 4 AS line_seq, '鸚鵡前頭不敢言。' AS content
UNION ALL
SELECT 'text-work-t300-207-ws' AS version_id, 1 AS line_seq, '今夜鄜州月，' AS content
UNION ALL
SELECT 'text-work-t300-207-ws' AS version_id, 2 AS line_seq, '閨中只獨看。' AS content
UNION ALL
SELECT 'text-work-t300-207-ws' AS version_id, 3 AS line_seq, '遙憐小兒女，' AS content
UNION ALL
SELECT 'text-work-t300-207-ws' AS version_id, 4 AS line_seq, '未解憶長安。' AS content
UNION ALL
SELECT 'text-work-t300-207-ws' AS version_id, 5 AS line_seq, '香霧雲鬟濕，' AS content
UNION ALL
SELECT 'text-work-t300-207-ws' AS version_id, 6 AS line_seq, '清輝玉臂寒。' AS content
UNION ALL
SELECT 'text-work-t300-207-ws' AS version_id, 7 AS line_seq, '何時倚虛幌，' AS content
UNION ALL
SELECT 'text-work-t300-207-ws' AS version_id, 8 AS line_seq, '雙照淚痕乾。' AS content
UNION ALL
SELECT 'text-work-chun-wang-ws' AS version_id, 1 AS line_seq, '國破山河在，' AS content
UNION ALL
SELECT 'text-work-chun-wang-ws' AS version_id, 2 AS line_seq, '城春草木深。' AS content
UNION ALL
SELECT 'text-work-chun-wang-ws' AS version_id, 3 AS line_seq, '感時花濺淚，' AS content
UNION ALL
SELECT 'text-work-chun-wang-ws' AS version_id, 4 AS line_seq, '恨別鳥驚心。' AS content
UNION ALL
SELECT 'text-work-chun-wang-ws' AS version_id, 5 AS line_seq, '烽火連三月，' AS content
UNION ALL
SELECT 'text-work-chun-wang-ws' AS version_id, 6 AS line_seq, '家書抵萬金。' AS content
UNION ALL
SELECT 'text-work-chun-wang-ws' AS version_id, 7 AS line_seq, '白頭搔更短，' AS content
UNION ALL
SELECT 'text-work-chun-wang-ws' AS version_id, 8 AS line_seq, '渾欲不勝簪。' AS content
UNION ALL
SELECT 'text-work-t300-209-ws' AS version_id, 1 AS line_seq, '花隱掖垣暮，' AS content
UNION ALL
SELECT 'text-work-t300-209-ws' AS version_id, 2 AS line_seq, '啾啾棲鳥過。' AS content
UNION ALL
SELECT 'text-work-t300-209-ws' AS version_id, 3 AS line_seq, '星臨萬戶動，' AS content
UNION ALL
SELECT 'text-work-t300-209-ws' AS version_id, 4 AS line_seq, '月傍九霄多。' AS content
UNION ALL
SELECT 'text-work-t300-209-ws' AS version_id, 5 AS line_seq, '不寢聽金鑰，' AS content
UNION ALL
SELECT 'text-work-t300-209-ws' AS version_id, 6 AS line_seq, '因風想玉珂。' AS content
UNION ALL
SELECT 'text-work-t300-209-ws' AS version_id, 7 AS line_seq, '明朝有封事，' AS content
UNION ALL
SELECT 'text-work-t300-209-ws' AS version_id, 8 AS line_seq, '數問夜如何。' AS content
UNION ALL
SELECT 'text-work-t300-210-ws' AS version_id, 1 AS line_seq, '此道昔歸順，' AS content
UNION ALL
SELECT 'text-work-t300-210-ws' AS version_id, 2 AS line_seq, '西郊胡正繁。' AS content
UNION ALL
SELECT 'text-work-t300-210-ws' AS version_id, 3 AS line_seq, '至今殘破膽，' AS content
UNION ALL
SELECT 'text-work-t300-210-ws' AS version_id, 4 AS line_seq, '應有未招魂。' AS content
UNION ALL
SELECT 'text-work-t300-210-ws' AS version_id, 5 AS line_seq, '近得歸京邑，' AS content
UNION ALL
SELECT 'text-work-t300-210-ws' AS version_id, 6 AS line_seq, '移官豈至尊。' AS content
UNION ALL
SELECT 'text-work-t300-210-ws' AS version_id, 7 AS line_seq, '無才日衰老，' AS content
UNION ALL
SELECT 'text-work-t300-210-ws' AS version_id, 8 AS line_seq, '駐馬望千門。' AS content
UNION ALL
SELECT 'text-work-t300-211-ws' AS version_id, 1 AS line_seq, '戍鼓斷人行，' AS content
UNION ALL
SELECT 'text-work-t300-211-ws' AS version_id, 2 AS line_seq, '秋邊一雁聲。' AS content
UNION ALL
SELECT 'text-work-t300-211-ws' AS version_id, 3 AS line_seq, '露從今夜白，' AS content
UNION ALL
SELECT 'text-work-t300-211-ws' AS version_id, 4 AS line_seq, '月是故鄉明。' AS content
UNION ALL
SELECT 'text-work-t300-211-ws' AS version_id, 5 AS line_seq, '有弟皆分散，' AS content
UNION ALL
SELECT 'text-work-t300-211-ws' AS version_id, 6 AS line_seq, '無家問死生。' AS content
UNION ALL
SELECT 'text-work-t300-211-ws' AS version_id, 7 AS line_seq, '寄書長不避，' AS content
UNION ALL
SELECT 'text-work-t300-211-ws' AS version_id, 8 AS line_seq, '況乃未休兵。' AS content
UNION ALL
SELECT 'text-work-t300-214-ws' AS version_id, 1 AS line_seq, '舍南舍北皆春水，' AS content
UNION ALL
SELECT 'text-work-t300-214-ws' AS version_id, 2 AS line_seq, '但見羣鷗日日來。' AS content
UNION ALL
SELECT 'text-work-t300-214-ws' AS version_id, 3 AS line_seq, '花徑不曾緣客掃，' AS content
UNION ALL
SELECT 'text-work-t300-214-ws' AS version_id, 4 AS line_seq, '蓬門今始爲君開。' AS content
UNION ALL
SELECT 'text-work-t300-214-ws' AS version_id, 5 AS line_seq, '盤餐市遠無兼味，' AS content
UNION ALL
SELECT 'text-work-t300-214-ws' AS version_id, 6 AS line_seq, '樽酒家貧只舊醅。' AS content
UNION ALL
SELECT 'text-work-t300-214-ws' AS version_id, 7 AS line_seq, '肯與鄰翁相對飲，' AS content
UNION ALL
SELECT 'text-work-t300-214-ws' AS version_id, 8 AS line_seq, '隔籬呼取盡餘桮。' AS content
UNION ALL
SELECT 'text-work-t300-215-ws' AS version_id, 1 AS line_seq, '西山白雪三奇戍，' AS content
UNION ALL
SELECT 'text-work-t300-215-ws' AS version_id, 2 AS line_seq, '南浦清江萬里橋。' AS content
UNION ALL
SELECT 'text-work-t300-215-ws' AS version_id, 3 AS line_seq, '海內風塵諸弟隔，' AS content
UNION ALL
SELECT 'text-work-t300-215-ws' AS version_id, 4 AS line_seq, '天涯涕淚一身遙。' AS content
UNION ALL
SELECT 'text-work-t300-215-ws' AS version_id, 5 AS line_seq, '唯將遲暮供多病，' AS content
UNION ALL
SELECT 'text-work-t300-215-ws' AS version_id, 6 AS line_seq, '未有涓埃荅聖朝。' AS content
UNION ALL
SELECT 'text-work-t300-215-ws' AS version_id, 7 AS line_seq, '跨馬出郊時極目，' AS content
UNION ALL
SELECT 'text-work-t300-215-ws' AS version_id, 8 AS line_seq, '不堪人事日蕭條。' AS content
UNION ALL
SELECT 'text-work-t300-216-ws' AS version_id, 1 AS line_seq, '遠送從此別，' AS content
UNION ALL
SELECT 'text-work-t300-216-ws' AS version_id, 2 AS line_seq, '青山空復情。' AS content
UNION ALL
SELECT 'text-work-t300-216-ws' AS version_id, 3 AS line_seq, '幾時桮重把，' AS content
UNION ALL
SELECT 'text-work-t300-216-ws' AS version_id, 4 AS line_seq, '昨夜月同行。' AS content
UNION ALL
SELECT 'text-work-t300-216-ws' AS version_id, 5 AS line_seq, '列郡謳歌惜，' AS content
UNION ALL
SELECT 'text-work-t300-216-ws' AS version_id, 6 AS line_seq, '三朝出入榮。' AS content
UNION ALL
SELECT 'text-work-t300-216-ws' AS version_id, 7 AS line_seq, '江村獨歸處，' AS content
UNION ALL
SELECT 'text-work-t300-216-ws' AS version_id, 8 AS line_seq, '寂寞養殘生。' AS content
UNION ALL
SELECT 'text-work-t300-217-ws' AS version_id, 1 AS line_seq, '劒外忽傳收薊北，' AS content
UNION ALL
SELECT 'text-work-t300-217-ws' AS version_id, 2 AS line_seq, '初聞涕淚滿衣裳。' AS content
UNION ALL
SELECT 'text-work-t300-217-ws' AS version_id, 3 AS line_seq, '却看妻子愁何在，' AS content
UNION ALL
SELECT 'text-work-t300-217-ws' AS version_id, 4 AS line_seq, '漫卷詩書喜欲狂。' AS content
UNION ALL
SELECT 'text-work-t300-217-ws' AS version_id, 5 AS line_seq, '白日放歌須縱酒，' AS content
UNION ALL
SELECT 'text-work-t300-217-ws' AS version_id, 6 AS line_seq, '青春作伴好還鄉。' AS content
UNION ALL
SELECT 'text-work-t300-217-ws' AS version_id, 7 AS line_seq, '即從巴峽穿巫峽，' AS content
UNION ALL
SELECT 'text-work-t300-217-ws' AS version_id, 8 AS line_seq, '便下襄陽向洛陽。' AS content
UNION ALL
SELECT 'text-work-t300-220-ws' AS version_id, 1 AS line_seq, '花近高樓傷客心，' AS content
UNION ALL
SELECT 'text-work-t300-220-ws' AS version_id, 2 AS line_seq, '萬方多難此登臨。' AS content
UNION ALL
SELECT 'text-work-t300-220-ws' AS version_id, 3 AS line_seq, '錦江春色來天地，' AS content
UNION ALL
SELECT 'text-work-t300-220-ws' AS version_id, 4 AS line_seq, '玉壘浮雲變古今。' AS content
UNION ALL
SELECT 'text-work-t300-220-ws' AS version_id, 5 AS line_seq, '北極朝廷終不改，' AS content
UNION ALL
SELECT 'text-work-t300-220-ws' AS version_id, 6 AS line_seq, '西山寇盜莫相侵。' AS content
UNION ALL
SELECT 'text-work-t300-220-ws' AS version_id, 7 AS line_seq, '可憐後主還祠廟，' AS content
UNION ALL
SELECT 'text-work-t300-220-ws' AS version_id, 8 AS line_seq, '日暮聊爲梁甫吟。' AS content
UNION ALL
SELECT 'text-work-t300-221-ws' AS version_id, 1 AS line_seq, '清秋幕府井梧寒，' AS content
UNION ALL
SELECT 'text-work-t300-221-ws' AS version_id, 2 AS line_seq, '獨宿江城蠟炬殘。' AS content
UNION ALL
SELECT 'text-work-t300-221-ws' AS version_id, 3 AS line_seq, '永夜角聲悲自語，' AS content
UNION ALL
SELECT 'text-work-t300-221-ws' AS version_id, 4 AS line_seq, '中天月色好誰看。' AS content
UNION ALL
SELECT 'text-work-t300-221-ws' AS version_id, 5 AS line_seq, '風塵荏苒音書絕，' AS content
UNION ALL
SELECT 'text-work-t300-221-ws' AS version_id, 6 AS line_seq, '關塞蕭條行路難。' AS content
UNION ALL
SELECT 'text-work-t300-221-ws' AS version_id, 7 AS line_seq, '已忍伶俜十年事，' AS content
UNION ALL
SELECT 'text-work-t300-221-ws' AS version_id, 8 AS line_seq, '強移栖息一枝安。' AS content
UNION ALL
SELECT 'text-work-t300-231-ws' AS version_id, 1 AS line_seq, '昔聞洞庭水，' AS content
UNION ALL
SELECT 'text-work-t300-231-ws' AS version_id, 2 AS line_seq, '今上岳陽樓。' AS content
UNION ALL
SELECT 'text-work-t300-231-ws' AS version_id, 3 AS line_seq, '吳楚東南坼，' AS content
UNION ALL
SELECT 'text-work-t300-231-ws' AS version_id, 4 AS line_seq, '乾坤日夜浮。' AS content
UNION ALL
SELECT 'text-work-t300-231-ws' AS version_id, 5 AS line_seq, '親朋無一字，' AS content
UNION ALL
SELECT 'text-work-t300-231-ws' AS version_id, 6 AS line_seq, '老病有孤舟。' AS content
UNION ALL
SELECT 'text-work-t300-231-ws' AS version_id, 7 AS line_seq, '戎馬關山北，' AS content
UNION ALL
SELECT 'text-work-t300-231-ws' AS version_id, 8 AS line_seq, '憑軒涕泗流。' AS content
UNION ALL
SELECT 'text-work-t300-233-ws' AS version_id, 1 AS line_seq, '海上生明月，' AS content
UNION ALL
SELECT 'text-work-t300-233-ws' AS version_id, 2 AS line_seq, '天涯共此時。' AS content
UNION ALL
SELECT 'text-work-t300-233-ws' AS version_id, 3 AS line_seq, '情人怨遙夜，' AS content
UNION ALL
SELECT 'text-work-t300-233-ws' AS version_id, 4 AS line_seq, '竟夕起相思。' AS content
UNION ALL
SELECT 'text-work-t300-233-ws' AS version_id, 5 AS line_seq, '滅燭憐光滿，' AS content
UNION ALL
SELECT 'text-work-t300-233-ws' AS version_id, 6 AS line_seq, '披衣覺露滋。' AS content
UNION ALL
SELECT 'text-work-t300-233-ws' AS version_id, 7 AS line_seq, '不堪盈手贈，' AS content
UNION ALL
SELECT 'text-work-t300-233-ws' AS version_id, 8 AS line_seq, '還寢夢佳期。' AS content
UNION ALL
SELECT 'text-work-t300-234-ws' AS version_id, 1 AS line_seq, '陽月南飛雁，' AS content
UNION ALL
SELECT 'text-work-t300-234-ws' AS version_id, 2 AS line_seq, '傳聞至此回。' AS content
UNION ALL
SELECT 'text-work-t300-234-ws' AS version_id, 3 AS line_seq, '我行殊未已，何日復歸來？江靜潮初落，林昏瘴不開。' AS content
UNION ALL
SELECT 'text-work-t300-234-ws' AS version_id, 4 AS line_seq, '明朝望鄉處，' AS content
UNION ALL
SELECT 'text-work-t300-234-ws' AS version_id, 5 AS line_seq, '應見隴頭梅。' AS content
UNION ALL
SELECT 'text-work-t300-240-ws' AS version_id, 1 AS line_seq, '嗟君此別意何如，' AS content
UNION ALL
SELECT 'text-work-t300-240-ws' AS version_id, 2 AS line_seq, '駐馬銜桮問謫居。' AS content
UNION ALL
SELECT 'text-work-t300-240-ws' AS version_id, 3 AS line_seq, '巫峽啼猿數行淚，' AS content
UNION ALL
SELECT 'text-work-t300-240-ws' AS version_id, 4 AS line_seq, '衡陽歸雁幾封書。' AS content
UNION ALL
SELECT 'text-work-t300-240-ws' AS version_id, 5 AS line_seq, '青楓江上秋天遠，' AS content
UNION ALL
SELECT 'text-work-t300-240-ws' AS version_id, 6 AS line_seq, '白帝城邊古木疎。' AS content
UNION ALL
SELECT 'text-work-t300-240-ws' AS version_id, 7 AS line_seq, '聖代即今多雨露，' AS content
UNION ALL
SELECT 'text-work-t300-240-ws' AS version_id, 8 AS line_seq, '暫時分手莫躊躇。' AS content
UNION ALL
SELECT 'text-work-t300-248-ws' AS version_id, 1 AS line_seq, '死別已吞聲，' AS content
UNION ALL
SELECT 'text-work-t300-248-ws' AS version_id, 2 AS line_seq, '生別常惻惻。' AS content
UNION ALL
SELECT 'text-work-t300-248-ws' AS version_id, 3 AS line_seq, '江南瘴癘地，' AS content
UNION ALL
SELECT 'text-work-t300-248-ws' AS version_id, 4 AS line_seq, '逐客無消息。' AS content
UNION ALL
SELECT 'text-work-t300-248-ws' AS version_id, 5 AS line_seq, '故人入我夢，' AS content
UNION ALL
SELECT 'text-work-t300-248-ws' AS version_id, 6 AS line_seq, '明我長相憶。' AS content
UNION ALL
SELECT 'text-work-t300-248-ws' AS version_id, 7 AS line_seq, '恐非平生魂，' AS content
UNION ALL
SELECT 'text-work-t300-248-ws' AS version_id, 8 AS line_seq, '路遠不可測。' AS content
UNION ALL
SELECT 'text-work-t300-248-ws' AS version_id, 9 AS line_seq, '魂來楓葉青，' AS content
UNION ALL
SELECT 'text-work-t300-248-ws' AS version_id, 10 AS line_seq, '魂返關塞黑。' AS content
UNION ALL
SELECT 'text-work-t300-248-ws' AS version_id, 11 AS line_seq, '君今在羅網，' AS content
UNION ALL
SELECT 'text-work-t300-248-ws' AS version_id, 12 AS line_seq, '何以有羽翼。' AS content
UNION ALL
SELECT 'text-work-t300-248-ws' AS version_id, 13 AS line_seq, '落月滿屋梁，' AS content
UNION ALL
SELECT 'text-work-t300-248-ws' AS version_id, 14 AS line_seq, '猶疑照顏色。' AS content
UNION ALL
SELECT 'text-work-t300-248-ws' AS version_id, 15 AS line_seq, '水深波浪闊，' AS content
UNION ALL
SELECT 'text-work-t300-248-ws' AS version_id, 16 AS line_seq, '無使蛟龍得。' AS content
UNION ALL
SELECT 'text-work-t300-252-ws' AS version_id, 1 AS line_seq, '今我不樂思岳陽，' AS content
UNION ALL
SELECT 'text-work-t300-252-ws' AS version_id, 2 AS line_seq, '身欲奮飛病在牀。' AS content
UNION ALL
SELECT 'text-work-t300-252-ws' AS version_id, 3 AS line_seq, '美人娟娟隔秋水，' AS content
UNION ALL
SELECT 'text-work-t300-252-ws' AS version_id, 4 AS line_seq, '濯足洞庭望八荒。' AS content
UNION ALL
SELECT 'text-work-t300-252-ws' AS version_id, 5 AS line_seq, '鴻飛冥冥日月白，' AS content
UNION ALL
SELECT 'text-work-t300-252-ws' AS version_id, 6 AS line_seq, '青楓葉赤天雨霜。' AS content
UNION ALL
SELECT 'text-work-t300-252-ws' AS version_id, 7 AS line_seq, '玉京羣帝集北斗，' AS content
UNION ALL
SELECT 'text-work-t300-252-ws' AS version_id, 8 AS line_seq, '或騎騏驎翳鳳皇。' AS content
UNION ALL
SELECT 'text-work-t300-252-ws' AS version_id, 9 AS line_seq, '芙蓉旌旗煙霧樂，' AS content
UNION ALL
SELECT 'text-work-t300-252-ws' AS version_id, 10 AS line_seq, '影動倒景搖瀟湘。' AS content
UNION ALL
SELECT 'text-work-t300-252-ws' AS version_id, 11 AS line_seq, '星宮之君醉瓊漿，' AS content
UNION ALL
SELECT 'text-work-t300-252-ws' AS version_id, 12 AS line_seq, '羽人稀少不在旁。' AS content
UNION ALL
SELECT 'text-work-t300-252-ws' AS version_id, 13 AS line_seq, '似聞昨者赤松子，' AS content
UNION ALL
SELECT 'text-work-t300-252-ws' AS version_id, 14 AS line_seq, '恐是漢代韓張良。' AS content
UNION ALL
SELECT 'text-work-t300-252-ws' AS version_id, 15 AS line_seq, '昔隨劉氏定長安，' AS content
UNION ALL
SELECT 'text-work-t300-252-ws' AS version_id, 16 AS line_seq, '帷幄未改神慘傷。' AS content
UNION ALL
SELECT 'text-work-t300-252-ws' AS version_id, 17 AS line_seq, '國家成敗吾豈敢，' AS content
UNION ALL
SELECT 'text-work-t300-252-ws' AS version_id, 18 AS line_seq, '色難腥腐餐風香。' AS content
UNION ALL
SELECT 'text-work-t300-252-ws' AS version_id, 19 AS line_seq, '周南留滯古所惜，' AS content
UNION ALL
SELECT 'text-work-t300-252-ws' AS version_id, 20 AS line_seq, '南極老人應壽昌。' AS content
UNION ALL
SELECT 'text-work-t300-252-ws' AS version_id, 21 AS line_seq, '美人胡爲隔秋水，' AS content
UNION ALL
SELECT 'text-work-t300-252-ws' AS version_id, 22 AS line_seq, '焉得置之貢玉堂。' AS content
UNION ALL
SELECT 'text-work-t300-262-ws' AS version_id, 1 AS line_seq, '勸君莫惜金縷衣，' AS content
UNION ALL
SELECT 'text-work-t300-262-ws' AS version_id, 2 AS line_seq, '勸君惜取少年時。' AS content
UNION ALL
SELECT 'text-work-t300-262-ws' AS version_id, 3 AS line_seq, '花開堪折直須折，' AS content
UNION ALL
SELECT 'text-work-t300-262-ws' AS version_id, 4 AS line_seq, '莫待無花空折枝。' AS content
UNION ALL
SELECT 'text-work-t300-274-ws' AS version_id, 1 AS line_seq, '泉壑帶茅茨，' AS content
UNION ALL
SELECT 'text-work-t300-274-ws' AS version_id, 2 AS line_seq, '雲霞生薜帷。' AS content
UNION ALL
SELECT 'text-work-t300-274-ws' AS version_id, 3 AS line_seq, '竹憐新雨後，' AS content
UNION ALL
SELECT 'text-work-t300-274-ws' AS version_id, 4 AS line_seq, '山愛夕陽時。' AS content
UNION ALL
SELECT 'text-work-t300-274-ws' AS version_id, 5 AS line_seq, '閑鷺棲常早，' AS content
UNION ALL
SELECT 'text-work-t300-274-ws' AS version_id, 6 AS line_seq, '秋花落更遲。' AS content
UNION ALL
SELECT 'text-work-t300-274-ws' AS version_id, 7 AS line_seq, '家童掃蘿逕，' AS content
UNION ALL
SELECT 'text-work-t300-274-ws' AS version_id, 8 AS line_seq, '昨與故人期。' AS content
UNION ALL
SELECT 'text-work-t300-276-ws' AS version_id, 1 AS line_seq, '二月黃鶯飛上林，' AS content
UNION ALL
SELECT 'text-work-t300-276-ws' AS version_id, 2 AS line_seq, '春城紫禁曉陰陰。' AS content
UNION ALL
SELECT 'text-work-t300-276-ws' AS version_id, 3 AS line_seq, '長樂鐘聲花外盡，' AS content
UNION ALL
SELECT 'text-work-t300-276-ws' AS version_id, 4 AS line_seq, '龍池柳色雨中深。' AS content
UNION ALL
SELECT 'text-work-t300-276-ws' AS version_id, 5 AS line_seq, '陽和不散窮途恨，' AS content
UNION ALL
SELECT 'text-work-t300-276-ws' AS version_id, 6 AS line_seq, '霄漢長懷捧日新。' AS content
UNION ALL
SELECT 'text-work-t300-276-ws' AS version_id, 7 AS line_seq, '獻賦十年猶未遇，' AS content
UNION ALL
SELECT 'text-work-t300-276-ws' AS version_id, 8 AS line_seq, '羞將白髮對華簪。' AS content
UNION ALL
SELECT 'text-work-t300-283-ws' AS version_id, 1 AS line_seq, '春城無處不飛花，' AS content
UNION ALL
SELECT 'text-work-t300-283-ws' AS version_id, 2 AS line_seq, '寒食東風御柳斜。' AS content
UNION ALL
SELECT 'text-work-t300-283-ws' AS version_id, 3 AS line_seq, '日暮漢宮傳蠟燭，' AS content
UNION ALL
SELECT 'text-work-t300-283-ws' AS version_id, 4 AS line_seq, '輕煙散入五侯家。' AS content
UNION ALL
SELECT 'text-work-t300-284-ws' AS version_id, 1 AS line_seq, '去年花裏逢君別，' AS content
UNION ALL
SELECT 'text-work-t300-284-ws' AS version_id, 2 AS line_seq, '今日花開已一年。' AS content
UNION ALL
SELECT 'text-work-t300-284-ws' AS version_id, 3 AS line_seq, '世事茫茫難自料，' AS content
UNION ALL
SELECT 'text-work-t300-284-ws' AS version_id, 4 AS line_seq, '春愁黯黯獨成眠。' AS content
UNION ALL
SELECT 'text-work-t300-284-ws' AS version_id, 5 AS line_seq, '身多疾病思田里，' AS content
UNION ALL
SELECT 'text-work-t300-284-ws' AS version_id, 6 AS line_seq, '邑有流亡愧俸錢。' AS content
UNION ALL
SELECT 'text-work-t300-284-ws' AS version_id, 7 AS line_seq, '聞道欲來相問訊，' AS content
UNION ALL
SELECT 'text-work-t300-284-ws' AS version_id, 8 AS line_seq, '西樓望月幾廻圓。' AS content
UNION ALL
SELECT 'text-work-t300-285-ws' AS version_id, 1 AS line_seq, '今朝郡齋冷，' AS content
UNION ALL
SELECT 'text-work-t300-285-ws' AS version_id, 2 AS line_seq, '忽念山中客。' AS content
UNION ALL
SELECT 'text-work-t300-285-ws' AS version_id, 3 AS line_seq, '澗底束荆薪，' AS content
UNION ALL
SELECT 'text-work-t300-285-ws' AS version_id, 4 AS line_seq, '歸來煮白石。' AS content
UNION ALL
SELECT 'text-work-t300-285-ws' AS version_id, 5 AS line_seq, '欲持一瓢酒，' AS content
UNION ALL
SELECT 'text-work-t300-285-ws' AS version_id, 6 AS line_seq, '遠慰風雨夕。' AS content
UNION ALL
SELECT 'text-work-t300-285-ws' AS version_id, 7 AS line_seq, '落葉滿空山，' AS content
UNION ALL
SELECT 'text-work-t300-285-ws' AS version_id, 8 AS line_seq, '何處尋行跡。' AS content
UNION ALL
SELECT 'text-work-t300-289-ws' AS version_id, 1 AS line_seq, '客從東方來，' AS content
UNION ALL
SELECT 'text-work-t300-289-ws' AS version_id, 2 AS line_seq, '衣上灞陵雨。' AS content
UNION ALL
SELECT 'text-work-t300-289-ws' AS version_id, 3 AS line_seq, '問客何爲來，' AS content
UNION ALL
SELECT 'text-work-t300-289-ws' AS version_id, 4 AS line_seq, '采山因買斧。' AS content
UNION ALL
SELECT 'text-work-t300-289-ws' AS version_id, 5 AS line_seq, '冥冥花正開，' AS content
UNION ALL
SELECT 'text-work-t300-289-ws' AS version_id, 6 AS line_seq, '颺颺燕新乳。' AS content
UNION ALL
SELECT 'text-work-t300-289-ws' AS version_id, 7 AS line_seq, '昨別今已春，' AS content
UNION ALL
SELECT 'text-work-t300-289-ws' AS version_id, 8 AS line_seq, '鬢絲生幾縷。' AS content
UNION ALL
SELECT 'text-work-t300-290-ws' AS version_id, 1 AS line_seq, '落帆逗淮鎮，' AS content
UNION ALL
SELECT 'text-work-t300-290-ws' AS version_id, 2 AS line_seq, '停舫臨孤驛。' AS content
UNION ALL
SELECT 'text-work-t300-290-ws' AS version_id, 3 AS line_seq, '浩浩風起波，' AS content
UNION ALL
SELECT 'text-work-t300-290-ws' AS version_id, 4 AS line_seq, '冥冥日沈夕。' AS content
UNION ALL
SELECT 'text-work-t300-290-ws' AS version_id, 5 AS line_seq, '人歸山郭暗，' AS content
UNION ALL
SELECT 'text-work-t300-290-ws' AS version_id, 6 AS line_seq, '雁下蘆洲白。' AS content
UNION ALL
SELECT 'text-work-t300-290-ws' AS version_id, 7 AS line_seq, '獨夜憶秦關，' AS content
UNION ALL
SELECT 'text-work-t300-290-ws' AS version_id, 8 AS line_seq, '聽鐘未眠客。' AS content
UNION ALL
SELECT 'text-work-t300-291-ws' AS version_id, 1 AS line_seq, '吏舍跼終年，' AS content
UNION ALL
SELECT 'text-work-t300-291-ws' AS version_id, 2 AS line_seq, '出郊曠清曙。' AS content
UNION ALL
SELECT 'text-work-t300-291-ws' AS version_id, 3 AS line_seq, '楊柳散和風，' AS content
UNION ALL
SELECT 'text-work-t300-291-ws' AS version_id, 4 AS line_seq, '青山澹吾慮。' AS content
UNION ALL
SELECT 'text-work-t300-291-ws' AS version_id, 5 AS line_seq, '依叢適自憩，' AS content
UNION ALL
SELECT 'text-work-t300-291-ws' AS version_id, 6 AS line_seq, '緣澗還復去。' AS content
UNION ALL
SELECT 'text-work-t300-291-ws' AS version_id, 7 AS line_seq, '微雨靄芳原，春鳩鳴何處？樂幽心屢止，遵事跡猶遽。' AS content
UNION ALL
SELECT 'text-work-t300-291-ws' AS version_id, 8 AS line_seq, '終罷斯結廬，' AS content
UNION ALL
SELECT 'text-work-t300-291-ws' AS version_id, 9 AS line_seq, '慕陶真可庶。' AS content
UNION ALL
SELECT 'text-work-t300-292-ws' AS version_id, 1 AS line_seq, '獨憐幽草澗邊生，' AS content
UNION ALL
SELECT 'text-work-t300-292-ws' AS version_id, 2 AS line_seq, '上有黃鸝深樹鳴。' AS content
UNION ALL
SELECT 'text-work-t300-292-ws' AS version_id, 3 AS line_seq, '春潮帶雨晚來急，' AS content
UNION ALL
SELECT 'text-work-t300-292-ws' AS version_id, 4 AS line_seq, '野渡無人舟自橫。' AS content
UNION ALL
SELECT 'text-work-t300-296-ws' AS version_id, 1 AS line_seq, '輪臺城頭夜吹角，' AS content
UNION ALL
SELECT 'text-work-t300-296-ws' AS version_id, 2 AS line_seq, '輪臺城北旄頭落。' AS content
UNION ALL
SELECT 'text-work-t300-296-ws' AS version_id, 3 AS line_seq, '羽書昨夜過渠黎，' AS content
UNION ALL
SELECT 'text-work-t300-296-ws' AS version_id, 4 AS line_seq, '單于已在金山西。' AS content
UNION ALL
SELECT 'text-work-t300-296-ws' AS version_id, 5 AS line_seq, '戍樓西望煙塵黑，' AS content
UNION ALL
SELECT 'text-work-t300-296-ws' AS version_id, 6 AS line_seq, '漢兵屯在輪臺北。' AS content
UNION ALL
SELECT 'text-work-t300-296-ws' AS version_id, 7 AS line_seq, '上將擁旄西出征，' AS content
UNION ALL
SELECT 'text-work-t300-296-ws' AS version_id, 8 AS line_seq, '平明吹笛大軍行。' AS content
UNION ALL
SELECT 'text-work-t300-296-ws' AS version_id, 9 AS line_seq, '四邊伐鼓雪海湧，' AS content
UNION ALL
SELECT 'text-work-t300-296-ws' AS version_id, 10 AS line_seq, '三軍大呼陰山動。' AS content
UNION ALL
SELECT 'text-work-t300-296-ws' AS version_id, 11 AS line_seq, '虜塞兵氣連雲屯，' AS content
UNION ALL
SELECT 'text-work-t300-296-ws' AS version_id, 12 AS line_seq, '戰場白骨纏草根。' AS content
UNION ALL
SELECT 'text-work-t300-296-ws' AS version_id, 13 AS line_seq, '劒河風急雪片闊，' AS content
UNION ALL
SELECT 'text-work-t300-296-ws' AS version_id, 14 AS line_seq, '沙口石凍馬蹄脫。' AS content
UNION ALL
SELECT 'text-work-t300-296-ws' AS version_id, 15 AS line_seq, '亞相勤王甘苦辛，' AS content
UNION ALL
SELECT 'text-work-t300-296-ws' AS version_id, 16 AS line_seq, '誓將報主靜邊塵。' AS content
UNION ALL
SELECT 'text-work-t300-296-ws' AS version_id, 17 AS line_seq, '古來青史誰不見，' AS content
UNION ALL
SELECT 'text-work-t300-296-ws' AS version_id, 18 AS line_seq, '今見功名勝古人。' AS content
UNION ALL
SELECT 'text-work-t300-298-ws' AS version_id, 1 AS line_seq, '聯步趨丹陛，' AS content
UNION ALL
SELECT 'text-work-t300-298-ws' AS version_id, 2 AS line_seq, '分曹限紫微。' AS content
UNION ALL
SELECT 'text-work-t300-298-ws' AS version_id, 3 AS line_seq, '曉隨天仗入，' AS content
UNION ALL
SELECT 'text-work-t300-298-ws' AS version_id, 4 AS line_seq, '暮惹御香歸。' AS content
UNION ALL
SELECT 'text-work-t300-298-ws' AS version_id, 5 AS line_seq, '白髮悲花落，' AS content
UNION ALL
SELECT 'text-work-t300-298-ws' AS version_id, 6 AS line_seq, '青雲羨鳥飛。' AS content
UNION ALL
SELECT 'text-work-t300-298-ws' AS version_id, 7 AS line_seq, '聖朝無闕事，' AS content
UNION ALL
SELECT 'text-work-t300-298-ws' AS version_id, 8 AS line_seq, '自覺諫書稀。' AS content
UNION ALL
SELECT 'text-work-t300-299-ws' AS version_id, 1 AS line_seq, '雞鳴紫陌曙光寒，' AS content
UNION ALL
SELECT 'text-work-t300-299-ws' AS version_id, 2 AS line_seq, '鶯囀皇州春色闌。' AS content
UNION ALL
SELECT 'text-work-t300-299-ws' AS version_id, 3 AS line_seq, '金闕曉鐘開萬戶，' AS content
UNION ALL
SELECT 'text-work-t300-299-ws' AS version_id, 4 AS line_seq, '玉階仙仗擁千官。' AS content
UNION ALL
SELECT 'text-work-t300-299-ws' AS version_id, 5 AS line_seq, '花迎劒珮星初落，' AS content
UNION ALL
SELECT 'text-work-t300-299-ws' AS version_id, 6 AS line_seq, '柳拂旌旗露未乾。' AS content
UNION ALL
SELECT 'text-work-t300-299-ws' AS version_id, 7 AS line_seq, '獨有鳳皇池上客，' AS content
UNION ALL
SELECT 'text-work-t300-299-ws' AS version_id, 8 AS line_seq, '陽春一曲和皆難。' AS content
UNION ALL
SELECT 'text-work-t300-300-ws' AS version_id, 1 AS line_seq, '故園東望路漫漫，' AS content
UNION ALL
SELECT 'text-work-t300-300-ws' AS version_id, 2 AS line_seq, '雙袖龍鍾淚不乾。' AS content
UNION ALL
SELECT 'text-work-t300-300-ws' AS version_id, 3 AS line_seq, '馬上相逢無紙筆，' AS content
UNION ALL
SELECT 'text-work-t300-300-ws' AS version_id, 4 AS line_seq, '憑君傳語報平安。' AS content
UNION ALL
SELECT 'text-work-t300-308-ws' AS version_id, 1 AS line_seq, '玉階生白露，' AS content
UNION ALL
SELECT 'text-work-t300-308-ws' AS version_id, 2 AS line_seq, '夜久侵羅襪。' AS content
UNION ALL
SELECT 'text-work-t300-308-ws' AS version_id, 3 AS line_seq, '却下水晶簾，' AS content
UNION ALL
SELECT 'text-work-t300-308-ws' AS version_id, 4 AS line_seq, '玲瓏望秋月。' AS content
UNION ALL
SELECT 'text-work-t300-312-ws' AS version_id, 1 AS line_seq, '燕草如碧絲，' AS content
UNION ALL
SELECT 'text-work-t300-312-ws' AS version_id, 2 AS line_seq, '秦桑低綠枝。' AS content
UNION ALL
SELECT 'text-work-t300-312-ws' AS version_id, 3 AS line_seq, '當君懷歸日，' AS content
UNION ALL
SELECT 'text-work-t300-312-ws' AS version_id, 4 AS line_seq, '是妾斷腸時。' AS content
UNION ALL
SELECT 'text-work-t300-312-ws' AS version_id, 5 AS line_seq, '春風不相識，' AS content
UNION ALL
SELECT 'text-work-t300-312-ws' AS version_id, 6 AS line_seq, '何事入羅幃。' AS content
UNION ALL
SELECT 'text-work-t300-320-ws' AS version_id, 1 AS line_seq, '風吹柳花滿店香，' AS content
UNION ALL
SELECT 'text-work-t300-320-ws' AS version_id, 2 AS line_seq, '吳姬壓酒喚客嘗。' AS content
UNION ALL
SELECT 'text-work-t300-320-ws' AS version_id, 3 AS line_seq, '金陵子弟來相送，' AS content
UNION ALL
SELECT 'text-work-t300-320-ws' AS version_id, 4 AS line_seq, '欲行不行各盡觴。' AS content
UNION ALL
SELECT 'text-work-t300-320-ws' AS version_id, 5 AS line_seq, '請君試問東流水，' AS content
UNION ALL
SELECT 'text-work-t300-320-ws' AS version_id, 6 AS line_seq, '別意與之誰短長。' AS content
UNION ALL
SELECT 'text-work-t300-323-ws' AS version_id, 1 AS line_seq, '青山橫北郭，' AS content
UNION ALL
SELECT 'text-work-t300-323-ws' AS version_id, 2 AS line_seq, '白水遶東城。' AS content
UNION ALL
SELECT 'text-work-t300-323-ws' AS version_id, 3 AS line_seq, '此地一爲別，' AS content
UNION ALL
SELECT 'text-work-t300-323-ws' AS version_id, 4 AS line_seq, '孤蓬萬里征。' AS content
UNION ALL
SELECT 'text-work-t300-323-ws' AS version_id, 5 AS line_seq, '浮雲遊子意，' AS content
UNION ALL
SELECT 'text-work-t300-323-ws' AS version_id, 6 AS line_seq, '落日故人情。' AS content
UNION ALL
SELECT 'text-work-t300-323-ws' AS version_id, 7 AS line_seq, '揮手自茲去，' AS content
UNION ALL
SELECT 'text-work-t300-323-ws' AS version_id, 8 AS line_seq, '蕭蕭班馬鳴。' AS content
UNION ALL
SELECT 'text-work-t300-325-ws' AS version_id, 1 AS line_seq, '暮從碧山下，' AS content
UNION ALL
SELECT 'text-work-t300-325-ws' AS version_id, 2 AS line_seq, '山月隨人歸。' AS content
UNION ALL
SELECT 'text-work-t300-325-ws' AS version_id, 3 AS line_seq, '却顧所來徑，' AS content
UNION ALL
SELECT 'text-work-t300-325-ws' AS version_id, 4 AS line_seq, '蒼蒼橫翠微。' AS content
UNION ALL
SELECT 'text-work-t300-325-ws' AS version_id, 5 AS line_seq, '相攜及田家，' AS content
UNION ALL
SELECT 'text-work-t300-325-ws' AS version_id, 6 AS line_seq, '童稚開荆扉。' AS content
UNION ALL
SELECT 'text-work-t300-325-ws' AS version_id, 7 AS line_seq, '綠竹入幽徑，' AS content
UNION ALL
SELECT 'text-work-t300-325-ws' AS version_id, 8 AS line_seq, '青蘿拂行衣。' AS content
UNION ALL
SELECT 'text-work-t300-325-ws' AS version_id, 9 AS line_seq, '歡言得所憩，' AS content
UNION ALL
SELECT 'text-work-t300-325-ws' AS version_id, 10 AS line_seq, '美酒聊共揮。' AS content
UNION ALL
SELECT 'text-work-t300-325-ws' AS version_id, 11 AS line_seq, '長歌吟松風，' AS content
UNION ALL
SELECT 'text-work-t300-325-ws' AS version_id, 12 AS line_seq, '曲盡河星稀。' AS content
UNION ALL
SELECT 'text-work-t300-325-ws' AS version_id, 13 AS line_seq, '我醉君復樂，' AS content
UNION ALL
SELECT 'text-work-t300-325-ws' AS version_id, 14 AS line_seq, '陶然共忘機。' AS content
UNION ALL
SELECT 'text-work-t300-326-ws' AS version_id, 1 AS line_seq, '鳳凰臺上鳳凰遊，' AS content
UNION ALL
SELECT 'text-work-t300-326-ws' AS version_id, 2 AS line_seq, '鳳去臺空江自流。' AS content
UNION ALL
SELECT 'text-work-t300-326-ws' AS version_id, 3 AS line_seq, '吳宮花草埋幽徑，' AS content
UNION ALL
SELECT 'text-work-t300-326-ws' AS version_id, 4 AS line_seq, '晉代衣冠成古丘。' AS content
UNION ALL
SELECT 'text-work-t300-326-ws' AS version_id, 5 AS line_seq, '三山半落青天外，' AS content
UNION ALL
SELECT 'text-work-t300-326-ws' AS version_id, 6 AS line_seq, '二水中分白鷺洲。' AS content
UNION ALL
SELECT 'text-work-t300-326-ws' AS version_id, 7 AS line_seq, '總爲浮雲能蔽日，' AS content
UNION ALL
SELECT 'text-work-t300-326-ws' AS version_id, 8 AS line_seq, '長安不見使人愁。' AS content
UNION ALL
SELECT 'text-work-t300-328-ws' AS version_id, 1 AS line_seq, '牛渚西江夜，' AS content
UNION ALL
SELECT 'text-work-t300-328-ws' AS version_id, 2 AS line_seq, '青天無片雲。' AS content
UNION ALL
SELECT 'text-work-t300-328-ws' AS version_id, 3 AS line_seq, '登舟望秋月，' AS content
UNION ALL
SELECT 'text-work-t300-328-ws' AS version_id, 4 AS line_seq, '空憶謝將軍。' AS content
UNION ALL
SELECT 'text-work-t300-328-ws' AS version_id, 5 AS line_seq, '余亦能高詠，' AS content
UNION ALL
SELECT 'text-work-t300-328-ws' AS version_id, 6 AS line_seq, '斯人不可聞。' AS content
UNION ALL
SELECT 'text-work-t300-328-ws' AS version_id, 7 AS line_seq, '明朝挂帆席，' AS content
UNION ALL
SELECT 'text-work-t300-328-ws' AS version_id, 8 AS line_seq, '楓葉落紛紛。' AS content
UNION ALL
SELECT 'text-work-t300-330-ws' AS version_id, 1 AS line_seq, '蜀僧抱綠綺，' AS content
UNION ALL
SELECT 'text-work-t300-330-ws' AS version_id, 2 AS line_seq, '西下峨眉峰。' AS content
UNION ALL
SELECT 'text-work-t300-330-ws' AS version_id, 3 AS line_seq, '爲我一揮手，' AS content
UNION ALL
SELECT 'text-work-t300-330-ws' AS version_id, 4 AS line_seq, '如聽萬壑松。' AS content
UNION ALL
SELECT 'text-work-t300-330-ws' AS version_id, 5 AS line_seq, '客心洗流水，' AS content
UNION ALL
SELECT 'text-work-t300-330-ws' AS version_id, 6 AS line_seq, '餘響入霜鐘。' AS content
UNION ALL
SELECT 'text-work-t300-330-ws' AS version_id, 7 AS line_seq, '不覺碧山暮，' AS content
UNION ALL
SELECT 'text-work-t300-330-ws' AS version_id, 8 AS line_seq, '秋雲暗幾重。' AS content
UNION ALL
SELECT 'text-work-t300-331-ws' AS version_id, 1 AS line_seq, '美人捲珠簾，' AS content
UNION ALL
SELECT 'text-work-t300-331-ws' AS version_id, 2 AS line_seq, '深坐顰蛾眉。' AS content
UNION ALL
SELECT 'text-work-t300-331-ws' AS version_id, 3 AS line_seq, '但見淚痕濕，' AS content
UNION ALL
SELECT 'text-work-t300-331-ws' AS version_id, 4 AS line_seq, '不知心恨誰。' AS content
UNION ALL
SELECT 'text-work-t300-334-ws' AS version_id, 1 AS line_seq, '悽悽去親愛，' AS content
UNION ALL
SELECT 'text-work-t300-334-ws' AS version_id, 2 AS line_seq, '泛泛入煙霧。' AS content
UNION ALL
SELECT 'text-work-t300-334-ws' AS version_id, 3 AS line_seq, '歸棹洛陽人，' AS content
UNION ALL
SELECT 'text-work-t300-334-ws' AS version_id, 4 AS line_seq, '殘鐘廣陵樹。' AS content
UNION ALL
SELECT 'text-work-t300-334-ws' AS version_id, 5 AS line_seq, '今朝此爲別，' AS content
UNION ALL
SELECT 'text-work-t300-334-ws' AS version_id, 6 AS line_seq, '何處還相遇。' AS content
UNION ALL
SELECT 'text-work-t300-334-ws' AS version_id, 7 AS line_seq, '世事波上舟，' AS content
UNION ALL
SELECT 'text-work-t300-334-ws' AS version_id, 8 AS line_seq, '沿洄安得住。' AS content
UNION ALL
SELECT 'text-work-t300-335-ws' AS version_id, 1 AS line_seq, '嫁得瞿塘賈，' AS content
UNION ALL
SELECT 'text-work-t300-335-ws' AS version_id, 2 AS line_seq, '朝朝誤妾期。' AS content
UNION ALL
SELECT 'text-work-t300-335-ws' AS version_id, 3 AS line_seq, '早知潮有信，' AS content
UNION ALL
SELECT 'text-work-t300-335-ws' AS version_id, 4 AS line_seq, '嫁與弄潮兒。' AS content
UNION ALL
SELECT 'text-work-t300-358-ws' AS version_id, 1 AS line_seq, '鶯啼燕語報新年，' AS content
UNION ALL
SELECT 'text-work-t300-358-ws' AS version_id, 2 AS line_seq, '馬邑龍堆路幾千。' AS content
UNION ALL
SELECT 'text-work-t300-358-ws' AS version_id, 3 AS line_seq, '家住秦城鄰漢苑，' AS content
UNION ALL
SELECT 'text-work-t300-358-ws' AS version_id, 4 AS line_seq, '心隨明月到胡天。' AS content
UNION ALL
SELECT 'text-work-t300-358-ws' AS version_id, 5 AS line_seq, '機中錦字論長恨，' AS content
UNION ALL
SELECT 'text-work-t300-358-ws' AS version_id, 6 AS line_seq, '樓上花枝笑獨眠。' AS content
UNION ALL
SELECT 'text-work-t300-358-ws' AS version_id, 7 AS line_seq, '爲問元戎竇車騎，' AS content
UNION ALL
SELECT 'text-work-t300-358-ws' AS version_id, 8 AS line_seq, '何時反斾勒燕然。' AS content
UNION ALL
SELECT 'text-work-t300-360-ws' AS version_id, 1 AS line_seq, '紗窗日落漸黃昏，' AS content
UNION ALL
SELECT 'text-work-t300-360-ws' AS version_id, 2 AS line_seq, '金屋無人見淚痕。' AS content
UNION ALL
SELECT 'text-work-t300-360-ws' AS version_id, 3 AS line_seq, '寂寞空庭春欲晚，' AS content
UNION ALL
SELECT 'text-work-t300-360-ws' AS version_id, 4 AS line_seq, '梨花滿地不開門。' AS content
UNION ALL
SELECT 'text-work-t300-361-ws' AS version_id, 1 AS line_seq, '白日依山盡，' AS content
UNION ALL
SELECT 'text-work-t300-361-ws' AS version_id, 2 AS line_seq, '黃河入海流。' AS content
UNION ALL
SELECT 'text-work-t300-361-ws' AS version_id, 3 AS line_seq, '欲窮千里目，' AS content
UNION ALL
SELECT 'text-work-t300-361-ws' AS version_id, 4 AS line_seq, '更上一層樓。' AS content
UNION ALL
SELECT 'text-work-t300-363-ws' AS version_id, 1 AS line_seq, '道由白雲盡，' AS content
UNION ALL
SELECT 'text-work-t300-363-ws' AS version_id, 2 AS line_seq, '春與青溪長。' AS content
UNION ALL
SELECT 'text-work-t300-363-ws' AS version_id, 3 AS line_seq, '時有落花至，' AS content
UNION ALL
SELECT 'text-work-t300-363-ws' AS version_id, 4 AS line_seq, '遠隨流水香。' AS content
UNION ALL
SELECT 'text-work-t300-363-ws' AS version_id, 5 AS line_seq, '閑門向山路，' AS content
UNION ALL
SELECT 'text-work-t300-363-ws' AS version_id, 6 AS line_seq, '深柳讀書堂。' AS content
UNION ALL
SELECT 'text-work-t300-363-ws' AS version_id, 7 AS line_seq, '幽映每白日，' AS content
UNION ALL
SELECT 'text-work-t300-363-ws' AS version_id, 8 AS line_seq, '清輝照衣裳。' AS content
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_text_line x WHERE x.version_id = t.version_id AND x.line_seq = t.line_seq);

INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty)
SELECT * FROM (
SELECT 'claim-t300-002-text' AS id, 'work-t300-002' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-005-text' AS id, 'work-t300-005' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-009-text' AS id, 'work-t300-009' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷301（维基文库《全唐詩》录入本）（同书异转录）；锚点「卷301_23故行宮王建」。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-010-text' AS id, 'work-t300-010' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-011-text' AS id, 'work-t300-011' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面折叠异体字后一致（读法甲折叠异体字后一致；页面自述底本 全唐詩（同书异转录，第二证成立））；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-013-text' AS id, 'work-t300-013' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面折叠异体字后一致（读法甲折叠异体字后一致；页面自述底本 李義山詩集 (四部叢刊本)/卷第六（异源他书，第二证成立；其差异属跨书异文））；底本 李義山詩集 (四部叢刊本)/卷第六（异源他书，跨书比对）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-015-text' AS id, 'work-t300-015' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-016-text' AS id, 'work-t300-016' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-020-text' AS id, 'work-t300-020' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库《全唐詩》卷页折叠异体字后一致（踪/蹤）；底本 全唐詩/卷539（维基文库《全唐詩》录入本）（同书异转录）；锚点「==無題四首_來是空言去絕蹤|無題四首==」。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-022-text' AS id, 'work-t300-022' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷539（维基文库《全唐詩》录入本）（同书异转录）；锚点「==隋宮==」。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-024-text' AS id, 'work-t300-024' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库《全唐詩》卷页折叠异体字后一致（壻/婿）；底本 全唐詩/卷539（维基文库《全唐詩》录入本）（同书异转录）；锚点「==為有==」。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-025-text' AS id, 'work-t300-025' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库《全唐詩》卷页折叠异体字后一致（爲/為）；底本 全唐詩/卷539（维基文库《全唐詩》录入本）（同书异转录）；锚点「==無題_相見時難別亦難|無題==」。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-026-text' AS id, 'work-t300-026' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷539（维基文库《全唐詩》录入本）（同书异转录）；锚点「==瑤池==」。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-028-text' AS id, 'work-t300-028' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷540（维基文库《全唐詩》录入本）（同书异转录）；锚点「==常娥==」。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-029-text' AS id, 'work-t300-029' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷540（维基文库《全唐詩》录入本）（同书异转录）；锚点「==無題二首==」。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-031-text' AS id, 'work-t300-031' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷540（维基文库《全唐詩》录入本）（同书异转录）；锚点「==賈生==」。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-032-text' AS id, 'work-t300-032' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷540（维基文库《全唐詩》录入本）（同书异转录）；锚点「==涼思==」。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-036-text' AS id, 'work-t300-036' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷697（维基文库《全唐詩》录入本）（同书异转录）；锚点「===金陵圖===」。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-037-text' AS id, 'work-t300-037' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷697（维基文库《全唐詩》录入本）（同书异转录）；锚点「===台城===」。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-040-text' AS id, 'work-t300-040' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库《全唐詩》卷页折叠异体字后一致（隣/鄰、鴈/雁）；底本 全唐詩/卷555（维基文库《全唐詩》录入本）（同书异转录）；锚点「===灞上秋居===」。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-041-text' AS id, 'work-t300-041' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷557（维基文库《全唐詩》录入本）（同书异转录）；锚点「===馬嵬坡===」。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-043-text' AS id, 'work-t300-043' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-045-text' AS id, 'work-t300-045' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩/卷404（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-047-text' AS id, 'work-t300-047' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩/卷410|type=詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-048-text' AS id, 'work-t300-048' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷784（维基文库《全唐詩》录入本）（同书异转录）；锚点「==西鄙人====」。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-052-text' AS id, 'work-t300-052' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-053-text' AS id, 'work-t300-053' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-054-text' AS id, 'work-t300-054' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-056-text' AS id, 'work-t300-056' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面折叠异体字后一致（读法甲折叠异体字后一致；页面自述底本 全唐詩（同书异转录，第二证成立））；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-057-text' AS id, 'work-t300-057' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面折叠异体字后一致（读法甲折叠异体字后一致；页面自述底本 全唐詩（同书异转录，第二证成立））；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-060-text' AS id, 'work-t300-060' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-061-text' AS id, 'work-t300-061' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-062-text' AS id, 'work-t300-062' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-063-text' AS id, 'work-t300-063' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-064-text' AS id, 'work-t300-064' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-074-text' AS id, 'work-t300-074' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷523（维基文库《全唐詩》录入本）（同书异转录）；锚点「===泊秦淮===」。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-079-text' AS id, 'work-t300-079' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷525（维基文库《全唐詩》录入本）（同书异转录）；锚点「===金谷園===」。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-087-text' AS id, 'work-t300-087' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-097-text' AS id, 'work-t300-097' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-100-text' AS id, 'work-t300-100' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-101-text' AS id, 'work-t300-101' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-102-text' AS id, 'work-t300-102' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-106-text' AS id, 'work-t300-106' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-108-text' AS id, 'work-t300-108' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-112-text' AS id, 'work-t300-112' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩/卷160#秦中感秋寄遠（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-117-text' AS id, 'work-t300-117' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-118-text' AS id, 'work-t300-118' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-119-text' AS id, 'work-t300-119' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-121-text' AS id, 'work-t300-121' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 文苑英華 (四庫全書本)/卷0157（异源他书，跨书比对）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-122-text' AS id, 'work-t300-122' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-131-text' AS id, 'work-t300-131' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-133-text' AS id, 'work-t300-133' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面折叠异体字后一致（读法甲折叠异体字后一致；页面自述底本 全唐詩（同书异转录，第二证成立））；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-134-text' AS id, 'work-t300-134' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-135-text' AS id, 'work-t300-135' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-136-text' AS id, 'work-t300-136' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-137-text' AS id, 'work-t300-137' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面折叠异体字后一致（读法甲折叠异体字后一致；页面自述底本 全唐詩（同书异转录，第二证成立））；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-140-text' AS id, 'work-t300-140' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-142-text' AS id, 'work-t300-142' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-145-text' AS id, 'work-t300-145' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-146-text' AS id, 'work-t300-146' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-148-text' AS id, 'work-t300-148' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-151-text' AS id, 'work-t300-151' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-153-text' AS id, 'work-t300-153' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-156-text' AS id, 'work-t300-156' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-157-text' AS id, 'work-t300-157' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-158-text' AS id, 'work-t300-158' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-159-text' AS id, 'work-t300-159' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-160-text' AS id, 'work-t300-160' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-161-text' AS id, 'work-t300-161' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-162-text' AS id, 'work-t300-162' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-164-text' AS id, 'work-t300-164' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-165-text' AS id, 'work-t300-165' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-169-text' AS id, 'work-t300-169' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷018（维基文库《全唐詩》录入本）（同书异转录）；锚点「==橫吹曲辭出塞==」。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-170-text' AS id, 'work-t300-170' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-171-text' AS id, 'work-t300-171' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-173-text' AS id, 'work-t300-173' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-186-text' AS id, 'work-t300-186' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷581（维基文库《全唐詩》录入本）（同书异转录）；锚点「===送人東===」。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-189-text' AS id, 'work-t300-189' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩/卷670（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-193-text' AS id, 'work-t300-193' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷511（维基文库《全唐詩》录入本）（同书异转录）；锚点「===宮詞二首===」。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-197-text' AS id, 'work-t300-197' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷511（维基文库《全唐詩》录入本）（同书异转录）；锚点「===延年不語望三星莫說夫人上涕零爭奈世間惆悵在甘泉宮夜看圖形===」。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-198-text' AS id, 'work-t300-198' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷514（维基文库《全唐詩》录入本）（同书异转录）；锚点「===石抱龍堂蘚石乾山遮白日寺門寒長松瀑布饒奇狀曾有僊人駐鶴看===」。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-207-text' AS id, 'work-t300-207' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷224（维基文库《全唐詩》录入本）（同书异转录）；锚点「==月夜==」。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-208-text' AS id, 'work-chun-wang' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷224（维基文库《全唐詩》录入本）（同书异转录）；锚点「==春望==」。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-209-text' AS id, 'work-t300-209' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷225（维基文库《全唐詩》录入本）（同书异转录）；锚点「==春宿左省==」。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-210-text' AS id, 'work-t300-210' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷225（维基文库《全唐詩》录入本）（同书异转录）；锚点「==因許八奉寄江甯旻上人==」。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-211-text' AS id, 'work-t300-211' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库《全唐詩》卷页折叠异体字后一致（鄉/鄕）；底本 全唐詩/卷225（维基文库《全唐詩》录入本）（同书异转录）；锚点「==月夜憶舍弟==」。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-214-text' AS id, 'work-t300-214' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库《全唐詩》卷页折叠异体字后一致（桮/杯）；底本 全唐詩/卷226（维基文库《全唐詩》录入本）（同书异转录）；锚点「==客至喜崔明府相過==」。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-215-text' AS id, 'work-t300-215' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库《全唐詩》卷页折叠异体字后一致（荅/答）；底本 全唐詩/卷227（维基文库《全唐詩》录入本）（同书异转录）；锚点「==野望杜甫|野望==」。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-216-text' AS id, 'work-t300-216' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面折叠异体字后一致（读法甲折叠异体字后一致；页面自述底本 全唐詩/卷227（同书异转录，第二证成立））；底本 全唐詩/卷227（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-217-text' AS id, 'work-t300-217' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面折叠异体字后一致（读法甲折叠异体字后一致；页面自述底本 全唐詩/卷227（同书异转录，第二证成立））；底本 全唐詩/卷227（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-220-text' AS id, 'work-t300-220' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面折叠异体字后一致（读法甲折叠异体字后一致；页面自述底本 全唐詩 (四庫全書本)/卷22（同书异转录，第二证成立））；底本 全唐詩 (四庫全書本)/卷22（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-221-text' AS id, 'work-t300-221' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库《全唐詩》卷页折叠异体字后一致（栖/棲）；底本 全唐詩/卷228（维基文库《全唐詩》录入本）（同书异转录）；锚点「==宿府==」。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-231-text' AS id, 'work-t300-231' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-233-text' AS id, 'work-t300-233' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-234-text' AS id, 'work-t300-234' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-240-text' AS id, 'work-t300-240' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-248-text' AS id, 'work-t300-248' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷218（维基文库《全唐詩》录入本）（同书异转录）；锚点「==夢李白二首==」。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-252-text' AS id, 'work-t300-252' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷220（维基文库《全唐詩》录入本）（同书异转录）；锚点「==寄韓諫議==」。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-262-text' AS id, 'work-t300-262' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库《全唐詩》卷页逐字一致；底本 全唐詩/卷028（维基文库《全唐詩》录入本）（同书异转录）；锚点「==雜曲歌辭金縷衣==」。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-274-text' AS id, 'work-t300-274' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-276-text' AS id, 'work-t300-276' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-283-text' AS id, 'work-t300-283' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-284-text' AS id, 'work-t300-284' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-285-text' AS id, 'work-t300-285' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-289-text' AS id, 'work-t300-289' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-290-text' AS id, 'work-t300-290' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-291-text' AS id, 'work-t300-291' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-292-text' AS id, 'work-t300-292' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-296-text' AS id, 'work-t300-296' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-298-text' AS id, 'work-t300-298' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-299-text' AS id, 'work-t300-299' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-300-text' AS id, 'work-t300-300' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-308-text' AS id, 'work-t300-308' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-312-text' AS id, 'work-t300-312' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-320-text' AS id, 'work-t300-320' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-323-text' AS id, 'work-t300-323' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面折叠异体字后一致（读法甲折叠异体字后一致；页面自述底本 全唐詩 (四庫全書本)/卷17（同书异转录，第二证成立））；底本 全唐詩 (四庫全書本)/卷17（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-325-text' AS id, 'work-t300-325' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面折叠异体字后一致（读法甲折叠异体字后一致；页面自述底本 全唐詩（同书异转录，第二证成立））；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-326-text' AS id, 'work-t300-326' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-328-text' AS id, 'work-t300-328' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-330-text' AS id, 'work-t300-330' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-331-text' AS id, 'work-t300-331' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-334-text' AS id, 'work-t300-334' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-335-text' AS id, 'work-t300-335' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-358-text' AS id, 'work-t300-358' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-360-text' AS id, 'work-t300-360' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-361-text' AS id, 'work-t300-361' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩 (四庫全書本)/卷25（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
UNION ALL
SELECT 'claim-t300-363-text' AS id, 'work-t300-363' AS subject_id, 'text.body' AS property_key, '选本正文与维基文库页面逐字一致；底本 全唐詩（同书异转录）。本地御定/poet.tang 为同仓库转录，只作旁注，不作本断言的依据。' AS value_text, 'FACT' AS claim_kind, 'KNOWN' AS certainty
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_claim x WHERE x.id = t.id);

INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt)
SELECT * FROM (
SELECT 'claim-t300-002-text' AS claim_id, 'source-ws-t300-002' AS source_id, '页面 登幽州臺歌' AS locator, '前不見古人，……獨愴然而涕下。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-005-text' AS claim_id, 'source-ws-t300-005' AS source_id, '页面 出塞 (秦時明月漢時關)' AS locator, '秦時明月漢時關，……不教胡馬度陰山。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-009-text' AS claim_id, 'source-quantangshi-301' AS source_id, '页面 全唐詩/卷301（锚点 卷301_23故行宮王建）' AS locator, '寥落古行宮，……閑坐說玄宗。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-010-text' AS claim_id, 'source-ws-t300-010' AS source_id, '页面 錦瑟' AS locator, '錦瑟無端五十絃，……只是當時已惘然。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-011-text' AS claim_id, 'source-ws-t300-011' AS source_id, '页面 蟬 (李商隱)' AS locator, '本以高難飽，……我亦舉家清。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-013-text' AS claim_id, 'source-ws-t300-013' AS source_id, '页面 夜雨寄北' AS locator, '君問歸期未有期，……却話巴山夜雨時。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-015-text' AS claim_id, 'source-ws-t300-015' AS source_id, '页面 風雨 (李商隱)' AS locator, '淒涼寶劍篇，……銷愁斗幾千。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-016-text' AS claim_id, 'source-ws-t300-016' AS source_id, '页面 寄令狐郎中' AS locator, '嵩雲秦樹久離居，……茂陵秋雨病相如。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-020-text' AS claim_id, 'source-quantangshi-539' AS source_id, '页面 全唐詩/卷539（锚点 ==無題四首_來是空言去絕蹤|無題四首==）' AS locator, '來是空言去絕踪，……更隔蓬山一萬重。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-022-text' AS claim_id, 'source-quantangshi-539' AS source_id, '页面 全唐詩/卷539（锚点 ==隋宮==）' AS locator, '乘興南遊不戒嚴，……半作障泥半作帆。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-024-text' AS claim_id, 'source-quantangshi-539' AS source_id, '页面 全唐詩/卷539（锚点 ==為有==）' AS locator, '爲有雲屏無限嬌，……辜負香衾事早朝。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-025-text' AS claim_id, 'source-quantangshi-539' AS source_id, '页面 全唐詩/卷539（锚点 ==無題_相見時難別亦難|無題==）' AS locator, '相見時難別亦難，……青鳥殷勤爲探看。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-026-text' AS claim_id, 'source-quantangshi-539' AS source_id, '页面 全唐詩/卷539（锚点 ==瑤池==）' AS locator, '瑤池阿母綺窗開，……穆王何事不重來。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-028-text' AS claim_id, 'source-quantangshi-540' AS source_id, '页面 全唐詩/卷540（锚点 ==常娥==）' AS locator, '雲母屏風燭影深，……碧海青天夜夜心。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-029-text' AS claim_id, 'source-quantangshi-540' AS source_id, '页面 全唐詩/卷540（锚点 ==無題二首==）' AS locator, '鳳尾香羅薄幾重，……斷無消息石榴紅。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-031-text' AS claim_id, 'source-quantangshi-540' AS source_id, '页面 全唐詩/卷540（锚点 ==賈生==）' AS locator, '宣室求賢訪逐臣，……不問蒼生問鬼神。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-032-text' AS claim_id, 'source-quantangshi-540' AS source_id, '页面 全唐詩/卷540（锚点 ==涼思==）' AS locator, '客去波平檻，……疑誤有新知。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-036-text' AS claim_id, 'source-quantangshi-697' AS source_id, '页面 全唐詩/卷697（锚点 ===金陵圖===）' AS locator, '誰謂傷心畫不成，……老木寒雲滿故城。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-037-text' AS claim_id, 'source-quantangshi-697' AS source_id, '页面 全唐詩/卷697（锚点 ===台城===）' AS locator, '江雨霏霏江草齊，……依舊煙籠十里堤。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-040-text' AS claim_id, 'source-quantangshi-555' AS source_id, '页面 全唐詩/卷555（锚点 ===灞上秋居===）' AS locator, '灞原風雨定，……何門致此身。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-041-text' AS claim_id, 'source-quantangshi-557' AS source_id, '页面 全唐詩/卷557（锚点 ===馬嵬坡===）' AS locator, '[玄]宗回馬楊妃死，……景陽宮井又何人。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-043-text' AS claim_id, 'source-ws-t300-043' AS source_id, '页面 春怨 (金昌緒)' AS locator, '打起黃鶯兒，……不得到遼西。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-045-text' AS claim_id, 'source-ws-t300-045' AS source_id, '页面 遣悲懷之二' AS locator, '昔日戲言身後意，……貧賤夫妻百事哀。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-047-text' AS claim_id, 'source-ws-t300-047' AS source_id, '页面 行宮' AS locator, '寥落古行宮，……閑坐說玄宗。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-048-text' AS claim_id, 'source-quantangshi-784' AS source_id, '页面 全唐詩/卷784（锚点 ==西鄙人====）' AS locator, '北斗七星高，……不敢過臨洮。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-052-text' AS claim_id, 'source-ws-t300-052' AS source_id, '页面 次北固山下' AS locator, '客路青山外，……歸雁洛陽邊。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-053-text' AS claim_id, 'source-ws-t300-053' AS source_id, '页面 桃花谿' AS locator, '隱隱飛橋隔野煙，……洞在清谿何處邊。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-054-text' AS claim_id, 'source-ws-t300-054' AS source_id, '页面 送別 (下馬飲君酒)' AS locator, '下馬飲君酒，……白雲無盡時。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-056-text' AS claim_id, 'source-ws-t300-056' AS source_id, '页面 青谿' AS locator, '言入黃花川，……垂釣將已矣。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-057-text' AS claim_id, 'source-ws-t300-057' AS source_id, '页面 渭川田家' AS locator, '斜陽照墟落，……悵然吟式微。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-060-text' AS claim_id, 'source-ws-t300-060' AS source_id, '页面 桃源行 (王維)' AS locator, '漁舟逐水愛山春，……不辨仙源何處尋。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-061-text' AS claim_id, 'source-ws-t300-061' AS source_id, '页面 洛陽女兒行' AS locator, '洛陽女兒對門居，……貧賤江頭自浣紗。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-062-text' AS claim_id, 'source-ws-t300-062' AS source_id, '页面 輞川閑居贈裴秀才迪' AS locator, '寒山轉蒼翠，……狂歌五柳前。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-063-text' AS claim_id, 'source-ws-t300-063' AS source_id, '页面 酬張少府' AS locator, '晚年唯好靜，……漁歌入浦深。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-064-text' AS claim_id, 'source-ws-t300-064' AS source_id, '页面 送梓州李使君' AS locator, '萬壑樹參天，……不敢倚先賢。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-074-text' AS claim_id, 'source-quantangshi-523' AS source_id, '页面 全唐詩/卷523（锚点 ===泊秦淮===）' AS locator, '煙籠寒水月籠沙，……隔江猶唱後庭花。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-079-text' AS claim_id, 'source-quantangshi-525' AS source_id, '页面 全唐詩/卷525（锚点 ===金谷園===）' AS locator, '繁華事散逐香塵，……落花猶似墮樓人。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-087-text' AS claim_id, 'source-ws-t300-087' AS source_id, '页面 喜見外弟又言別' AS locator, '十年離亂後，……秋山又幾重。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-097-text' AS claim_id, 'source-ws-t300-097' AS source_id, '页面 新年作 (劉長卿)' AS locator, '鄉心新歲切，……從今又幾年。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-100-text' AS claim_id, 'source-ws-t300-100' AS source_id, '页面 餞別王十一南遊' AS locator, '望君煙水闊，……相思愁白蘋。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-101-text' AS claim_id, 'source-ws-t300-101' AS source_id, '页面 江州重別薛六柳八二員外' AS locator, '生涯豈料承優詔，……媿君猶遣慎風波。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-102-text' AS claim_id, 'source-ws-t300-102' AS source_id, '页面 長沙過賈誼宅' AS locator, '三年謫宦此棲遲，……憐君何事到天涯。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-106-text' AS claim_id, 'source-ws-t300-106' AS source_id, '页面 涼州詞 (葡萄美酒夜光杯)' AS locator, '葡萄美酒夜光杯，……古來征戰幾人回。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-108-text' AS claim_id, 'source-ws-t300-108' AS source_id, '页面 夏日南亭懷辛大' AS locator, '山光忽西落，……中宵勞夢想。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-112-text' AS claim_id, 'source-ws-t300-112' AS source_id, '页面 秦中感秋寄遠上人' AS locator, '一丘常欲臥，……聞蟬但益悲。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-117-text' AS claim_id, 'source-ws-t300-117' AS source_id, '页面 與諸子登峴山' AS locator, '人事有代謝，……讀罷淚沾襟。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-118-text' AS claim_id, 'source-ws-t300-118' AS source_id, '页面 過故人莊' AS locator, '故人具雞黍，……還來就菊花。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-119-text' AS claim_id, 'source-ws-t300-119' AS source_id, '页面 歲暮歸南山' AS locator, '北闕休上書，……松月夜窗虛。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-121-text' AS claim_id, 'source-ws-t300-121' AS source_id, '页面 春曉 (孟浩然)' AS locator, '春眠不覺曉，……花落知多少。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-122-text' AS claim_id, 'source-ws-t300-122' AS source_id, '页面 宿建德江' AS locator, '移舟泊煙渚，……江清月近人。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-131-text' AS claim_id, 'source-ws-t300-131' AS source_id, '页面 晚次鄂州' AS locator, '雲開遠見漢陽城，……更堪江上鼓鼙聲。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-133-text' AS claim_id, 'source-ws-t300-133' AS source_id, '页面 過香積寺' AS locator, '不知香積寺，……安禪制毒龍。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-134-text' AS claim_id, 'source-ws-t300-134' AS source_id, '页面 山居秋暝' AS locator, '空山新雨後，……王孫自可留。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-135-text' AS claim_id, 'source-ws-t300-135' AS source_id, '页面 終南別業' AS locator, '中歲頗好道，……談笑無還期。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-136-text' AS claim_id, 'source-ws-t300-136' AS source_id, '页面 歸嵩山作' AS locator, '清川帶長薄，……歸來且閉關。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-137-text' AS claim_id, 'source-ws-t300-137' AS source_id, '页面 終南山 (王維)' AS locator, '太乙近天都，……隔水問樵夫。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-140-text' AS claim_id, 'source-ws-t300-140' AS source_id, '页面 和賈舍人早朝大明宮之作' AS locator, '絳幘雞人送曉籌，……佩聲歸向鳳池頭。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-142-text' AS claim_id, 'source-ws-t300-142' AS source_id, '页面 積雨輞川莊作' AS locator, '積雨空林煙火遲，……海鷗何事更相疑。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-145-text' AS claim_id, 'source-ws-t300-145' AS source_id, '页面 送別 (山中相送罷)' AS locator, '山中相送罷，……王孫歸不歸。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-146-text' AS claim_id, 'source-ws-t300-146' AS source_id, '页面 雜詩 (君自故鄉來)' AS locator, '君自故鄉來，……寒梅着花未。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-148-text' AS claim_id, 'source-ws-t300-148' AS source_id, '页面 九月九日憶山東兄弟' AS locator, '獨在異鄉爲異客，……遍插茱萸少一人。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-151-text' AS claim_id, 'source-ws-t300-151' AS source_id, '页面 尋西山隱者不遇' AS locator, '絕頂一茅茨，……何必待之子。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-153-text' AS claim_id, 'source-ws-t300-153' AS source_id, '页面 行經華陰' AS locator, '岧嶤太華俯咸京，……無如此處學長生。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-156-text' AS claim_id, 'source-ws-t300-156' AS source_id, '页面 望薊門' AS locator, '燕臺一望客心驚，……論功還欲請長纓。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-157-text' AS claim_id, 'source-ws-t300-157' AS source_id, '页面 終南望餘雪' AS locator, '終南陰嶺秀，……城中增暮寒。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-158-text' AS claim_id, 'source-ws-t300-158' AS source_id, '页面 古從軍行' AS locator, '白日登山望烽火，……空見蒲桃入漢家。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-159-text' AS claim_id, 'source-ws-t300-159' AS source_id, '页面 琴歌 (李頎)' AS locator, '主人有酒歡今夕，……敢告雲山從此始。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-160-text' AS claim_id, 'source-ws-t300-160' AS source_id, '页面 送陳章甫' AS locator, '四月南風大麥黃，……罷官昨日今如何。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-161-text' AS claim_id, 'source-ws-t300-161' AS source_id, '页面 聽安萬善吹觱篥歌' AS locator, '南山截竹爲觱篥，……美酒一杯聲一曲。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-162-text' AS claim_id, 'source-ws-t300-162' AS source_id, '页面 古意 (李頎)' AS locator, '男兒事長征，……使我三軍淚如雨。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-164-text' AS claim_id, 'source-ws-t300-164' AS source_id, '页面 送魏萬之京' AS locator, '朝聞遊子唱離歌，……空令歲月易蹉跎。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-165-text' AS claim_id, 'source-ws-t300-165' AS source_id, '页面 春泛若耶溪' AS locator, '幽意無斷絕，……願爲持竿叟。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-169-text' AS claim_id, 'source-quantangshi-18' AS source_id, '页面 全唐詩/卷018（锚点 ==橫吹曲辭出塞==）' AS locator, '秦時明月漢時關，……不教胡馬度陰山。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-170-text' AS claim_id, 'source-ws-t300-170' AS source_id, '页面 春宮曲' AS locator, '昨夜風開露井桃，……簾外春寒賜錦袍。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-171-text' AS claim_id, 'source-ws-t300-171' AS source_id, '页面 閨怨 (王昌齡)' AS locator, '閨中少婦不曾愁，……悔教夫壻覓封侯。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-173-text' AS claim_id, 'source-ws-t300-173' AS source_id, '页面 宿王昌齡隱居' AS locator, '清溪深不測，……西山鸞鶴羣。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-186-text' AS claim_id, 'source-quantangshi-581' AS source_id, '页面 全唐詩/卷581（锚点 ===送人東===）' AS locator, '荒戍落黃葉，……尊酒慰離顏。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-189-text' AS claim_id, 'source-ws-t300-189' AS source_id, '页面 貧女(秦韜玉)' AS locator, '蓬門未識綺羅香，……爲他人作嫁衣裳。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-193-text' AS claim_id, 'source-quantangshi-511' AS source_id, '页面 全唐詩/卷511（锚点 ===宮詞二首===）' AS locator, '故國三千里，……雙淚落君前。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-197-text' AS claim_id, 'source-quantangshi-511' AS source_id, '页面 全唐詩/卷511（锚点 ===延年不語望三星莫說夫人上涕零爭奈世間惆悵在甘泉宮夜看圖形===）' AS locator, '金陵津渡小山樓，……兩三星火是瓜州。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-198-text' AS claim_id, 'source-quantangshi-514' AS source_id, '页面 全唐詩/卷514（锚点 ===石抱龍堂蘚石乾山遮白日寺門寒長松瀑布饒奇狀曾有僊人駐鶴看===）' AS locator, '寂寂花時閉院門，……鸚鵡前頭不敢言。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-207-text' AS claim_id, 'source-quantangshi-224' AS source_id, '页面 全唐詩/卷224（锚点 ==月夜==）' AS locator, '今夜鄜州月，……雙照淚痕乾。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-208-text' AS claim_id, 'source-quantangshi-224' AS source_id, '页面 全唐詩/卷224（锚点 ==春望==）' AS locator, '國破山河在，……渾欲不勝簪。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-209-text' AS claim_id, 'source-quantangshi-225' AS source_id, '页面 全唐詩/卷225（锚点 ==春宿左省==）' AS locator, '花隱掖垣暮，……數問夜如何。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-210-text' AS claim_id, 'source-quantangshi-225' AS source_id, '页面 全唐詩/卷225（锚点 ==因許八奉寄江甯旻上人==）' AS locator, '此道昔歸順，……駐馬望千門。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-211-text' AS claim_id, 'source-quantangshi-225' AS source_id, '页面 全唐詩/卷225（锚点 ==月夜憶舍弟==）' AS locator, '戍鼓斷人行，……況乃未休兵。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-214-text' AS claim_id, 'source-quantangshi-226' AS source_id, '页面 全唐詩/卷226（锚点 ==客至喜崔明府相過==）' AS locator, '舍南舍北皆春水，……隔籬呼取盡餘桮。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-215-text' AS claim_id, 'source-quantangshi-227' AS source_id, '页面 全唐詩/卷227（锚点 ==野望杜甫|野望==）' AS locator, '西山白雪三奇戍，……不堪人事日蕭條。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-216-text' AS claim_id, 'source-ws-t300-216' AS source_id, '页面 奉濟驛重送嚴公四韻' AS locator, '遠送從此別，……寂寞養殘生。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-217-text' AS claim_id, 'source-ws-t300-217' AS source_id, '页面 聞官軍收河南河北' AS locator, '劒外忽傳收薊北，……便下襄陽向洛陽。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-220-text' AS claim_id, 'source-ws-t300-220' AS source_id, '页面 登樓 (杜甫)' AS locator, '花近高樓傷客心，……日暮聊爲梁甫吟。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-221-text' AS claim_id, 'source-quantangshi-228' AS source_id, '页面 全唐詩/卷228（锚点 ==宿府==）' AS locator, '清秋幕府井梧寒，……強移栖息一枝安。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-231-text' AS claim_id, 'source-ws-t300-231' AS source_id, '页面 登岳陽樓 (杜甫)' AS locator, '昔聞洞庭水，……憑軒涕泗流。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-233-text' AS claim_id, 'source-ws-t300-233' AS source_id, '页面 望月懷遠' AS locator, '海上生明月，……還寢夢佳期。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-234-text' AS claim_id, 'source-ws-t300-234' AS source_id, '页面 題大庾嶺北驛' AS locator, '陽月南飛雁，……應見隴頭梅。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-240-text' AS claim_id, 'source-ws-t300-240' AS source_id, '页面 送李少府貶峽中王少府貶長沙' AS locator, '嗟君此別意何如，……暫時分手莫躊躇。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-248-text' AS claim_id, 'source-quantangshi-218' AS source_id, '页面 全唐詩/卷218（锚点 ==夢李白二首==）' AS locator, '死別已吞聲，……無使蛟龍得。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-252-text' AS claim_id, 'source-quantangshi-220' AS source_id, '页面 全唐詩/卷220（锚点 ==寄韓諫議==）' AS locator, '今我不樂思岳陽，……焉得置之貢玉堂。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-262-text' AS claim_id, 'source-quantangshi-28' AS source_id, '页面 全唐詩/卷028（锚点 ==雜曲歌辭金縷衣==）' AS locator, '勸君莫惜金縷衣，……莫待無花空折枝。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-274-text' AS claim_id, 'source-ws-t300-274' AS source_id, '页面 谷口書齋寄楊補闕' AS locator, '泉壑帶茅茨，……昨與故人期。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-276-text' AS claim_id, 'source-ws-t300-276' AS source_id, '页面 贈闕下裴舍人' AS locator, '二月黃鶯飛上林，……羞將白髮對華簪。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-283-text' AS claim_id, 'source-ws-t300-283' AS source_id, '页面 寒食 (韓翃)' AS locator, '春城無處不飛花，……輕煙散入五侯家。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-284-text' AS claim_id, 'source-ws-t300-284' AS source_id, '页面 寄李儋元錫' AS locator, '去年花裏逢君別，……西樓望月幾廻圓。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-285-text' AS claim_id, 'source-ws-t300-285' AS source_id, '页面 寄全椒山中道士' AS locator, '今朝郡齋冷，……何處尋行跡。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-289-text' AS claim_id, 'source-ws-t300-289' AS source_id, '页面 長安遇馮著' AS locator, '客從東方來，……鬢絲生幾縷。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-290-text' AS claim_id, 'source-ws-t300-290' AS source_id, '页面 夕次盱眙縣' AS locator, '落帆逗淮鎮，……聽鐘未眠客。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-291-text' AS claim_id, 'source-ws-t300-291' AS source_id, '页面 東郊' AS locator, '吏舍跼終年，……慕陶真可庶。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-292-text' AS claim_id, 'source-ws-t300-292' AS source_id, '页面 滁州西澗' AS locator, '獨憐幽草澗邊生，……野渡無人舟自橫。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-296-text' AS claim_id, 'source-ws-t300-296' AS source_id, '页面 輪臺歌奉送封大夫出師西征' AS locator, '輪臺城頭夜吹角，……今見功名勝古人。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-298-text' AS claim_id, 'source-ws-t300-298' AS source_id, '页面 寄左省杜拾遺' AS locator, '聯步趨丹陛，……自覺諫書稀。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-299-text' AS claim_id, 'source-ws-t300-299' AS source_id, '页面 奉和中書舍人賈至早朝大明宮' AS locator, '雞鳴紫陌曙光寒，……陽春一曲和皆難。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-300-text' AS claim_id, 'source-ws-t300-300' AS source_id, '页面 逢入京使' AS locator, '故園東望路漫漫，……憑君傳語報平安。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-308-text' AS claim_id, 'source-ws-t300-308' AS source_id, '页面 玉階怨 (李白)' AS locator, '玉階生白露，……玲瓏望秋月。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-312-text' AS claim_id, 'source-ws-t300-312' AS source_id, '页面 春思 (李白)' AS locator, '燕草如碧絲，……何事入羅幃。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-320-text' AS claim_id, 'source-ws-t300-320' AS source_id, '页面 金陵酒肆留別' AS locator, '風吹柳花滿店香，……別意與之誰短長。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-323-text' AS claim_id, 'source-ws-t300-323' AS source_id, '页面 送友人 (李白)' AS locator, '青山橫北郭，……蕭蕭班馬鳴。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-325-text' AS claim_id, 'source-ws-t300-325' AS source_id, '页面 下終南山過斛斯山人宿置酒' AS locator, '暮從碧山下，……陶然共忘機。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-326-text' AS claim_id, 'source-ws-t300-326' AS source_id, '页面 登金陵鳳凰臺' AS locator, '鳳凰臺上鳳凰遊，……長安不見使人愁。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-328-text' AS claim_id, 'source-ws-t300-328' AS source_id, '页面 夜泊牛渚懷古' AS locator, '牛渚西江夜，……楓葉落紛紛。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-330-text' AS claim_id, 'source-ws-t300-330' AS source_id, '页面 聽蜀僧濬彈琴' AS locator, '蜀僧抱綠綺，……秋雲暗幾重。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-331-text' AS claim_id, 'source-ws-t300-331' AS source_id, '页面 怨情 (美人捲珠簾)' AS locator, '美人捲珠簾，……不知心恨誰。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-334-text' AS claim_id, 'source-ws-t300-334' AS source_id, '页面 初發揚子寄元大校書' AS locator, '悽悽去親愛，……沿洄安得住。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-335-text' AS claim_id, 'source-ws-t300-335' AS source_id, '页面 江南曲 (嫁得瞿塘賈)' AS locator, '嫁得瞿塘賈，……嫁與弄潮兒。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-358-text' AS claim_id, 'source-ws-t300-358' AS source_id, '页面 春思 (皇甫冉)' AS locator, '鶯啼燕語報新年，……何時反斾勒燕然。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-360-text' AS claim_id, 'source-ws-t300-360' AS source_id, '页面 春怨 (劉方平)' AS locator, '紗窗日落漸黃昏，……梨花滿地不開門。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-361-text' AS claim_id, 'source-ws-t300-361' AS source_id, '页面 登鸛雀樓 (王之渙)' AS locator, '白日依山盡，……更上一層樓。' AS evidence_excerpt
UNION ALL
SELECT 'claim-t300-363-text' AS claim_id, 'source-ws-t300-363' AS source_id, '页面 闕題 (劉眘虛)' AS locator, '道由白雲盡，……清輝照衣裳。' AS evidence_excerpt
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_citation x WHERE x.claim_id = t.claim_id AND x.source_id = t.source_id);

INSERT INTO poetry_claim_selection (subject_id, property_key, claim_id)
SELECT * FROM (
SELECT 'work-t300-002' AS subject_id, 'text.body' AS property_key, 'claim-t300-002-text' AS claim_id
UNION ALL
SELECT 'work-t300-002' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-002-author' AS claim_id
UNION ALL
SELECT 'work-t300-005' AS subject_id, 'text.body' AS property_key, 'claim-t300-005-text' AS claim_id
UNION ALL
SELECT 'work-t300-005' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-005-author' AS claim_id
UNION ALL
SELECT 'work-t300-009' AS subject_id, 'text.body' AS property_key, 'claim-t300-009-text' AS claim_id
UNION ALL
SELECT 'work-t300-009' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-009-author' AS claim_id
UNION ALL
SELECT 'work-t300-010' AS subject_id, 'text.body' AS property_key, 'claim-t300-010-text' AS claim_id
UNION ALL
SELECT 'work-t300-010' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-010-author' AS claim_id
UNION ALL
SELECT 'work-t300-011' AS subject_id, 'text.body' AS property_key, 'claim-t300-011-text' AS claim_id
UNION ALL
SELECT 'work-t300-011' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-011-author' AS claim_id
UNION ALL
SELECT 'work-t300-013' AS subject_id, 'text.body' AS property_key, 'claim-t300-013-text' AS claim_id
UNION ALL
SELECT 'work-t300-013' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-013-author' AS claim_id
UNION ALL
SELECT 'work-t300-015' AS subject_id, 'text.body' AS property_key, 'claim-t300-015-text' AS claim_id
UNION ALL
SELECT 'work-t300-015' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-015-author' AS claim_id
UNION ALL
SELECT 'work-t300-016' AS subject_id, 'text.body' AS property_key, 'claim-t300-016-text' AS claim_id
UNION ALL
SELECT 'work-t300-016' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-016-author' AS claim_id
UNION ALL
SELECT 'work-t300-020' AS subject_id, 'text.body' AS property_key, 'claim-t300-020-text' AS claim_id
UNION ALL
SELECT 'work-t300-020' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-020-author' AS claim_id
UNION ALL
SELECT 'work-t300-022' AS subject_id, 'text.body' AS property_key, 'claim-t300-022-text' AS claim_id
UNION ALL
SELECT 'work-t300-022' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-022-author' AS claim_id
UNION ALL
SELECT 'work-t300-024' AS subject_id, 'text.body' AS property_key, 'claim-t300-024-text' AS claim_id
UNION ALL
SELECT 'work-t300-024' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-024-author' AS claim_id
UNION ALL
SELECT 'work-t300-025' AS subject_id, 'text.body' AS property_key, 'claim-t300-025-text' AS claim_id
UNION ALL
SELECT 'work-t300-025' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-025-author' AS claim_id
UNION ALL
SELECT 'work-t300-026' AS subject_id, 'text.body' AS property_key, 'claim-t300-026-text' AS claim_id
UNION ALL
SELECT 'work-t300-026' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-026-author' AS claim_id
UNION ALL
SELECT 'work-t300-028' AS subject_id, 'text.body' AS property_key, 'claim-t300-028-text' AS claim_id
UNION ALL
SELECT 'work-t300-028' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-028-author' AS claim_id
UNION ALL
SELECT 'work-t300-029' AS subject_id, 'text.body' AS property_key, 'claim-t300-029-text' AS claim_id
UNION ALL
SELECT 'work-t300-029' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-029-author' AS claim_id
UNION ALL
SELECT 'work-t300-031' AS subject_id, 'text.body' AS property_key, 'claim-t300-031-text' AS claim_id
UNION ALL
SELECT 'work-t300-031' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-031-author' AS claim_id
UNION ALL
SELECT 'work-t300-032' AS subject_id, 'text.body' AS property_key, 'claim-t300-032-text' AS claim_id
UNION ALL
SELECT 'work-t300-032' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-032-author' AS claim_id
UNION ALL
SELECT 'work-t300-036' AS subject_id, 'text.body' AS property_key, 'claim-t300-036-text' AS claim_id
UNION ALL
SELECT 'work-t300-036' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-036-author' AS claim_id
UNION ALL
SELECT 'work-t300-037' AS subject_id, 'text.body' AS property_key, 'claim-t300-037-text' AS claim_id
UNION ALL
SELECT 'work-t300-037' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-037-author' AS claim_id
UNION ALL
SELECT 'work-t300-040' AS subject_id, 'text.body' AS property_key, 'claim-t300-040-text' AS claim_id
UNION ALL
SELECT 'work-t300-040' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-040-author' AS claim_id
UNION ALL
SELECT 'work-t300-041' AS subject_id, 'text.body' AS property_key, 'claim-t300-041-text' AS claim_id
UNION ALL
SELECT 'work-t300-041' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-041-author' AS claim_id
UNION ALL
SELECT 'work-t300-043' AS subject_id, 'text.body' AS property_key, 'claim-t300-043-text' AS claim_id
UNION ALL
SELECT 'work-t300-043' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-043-author' AS claim_id
UNION ALL
SELECT 'work-t300-045' AS subject_id, 'text.body' AS property_key, 'claim-t300-045-text' AS claim_id
UNION ALL
SELECT 'work-t300-045' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-045-author' AS claim_id
UNION ALL
SELECT 'work-t300-047' AS subject_id, 'text.body' AS property_key, 'claim-t300-047-text' AS claim_id
UNION ALL
SELECT 'work-t300-047' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-047-author' AS claim_id
UNION ALL
SELECT 'work-t300-048' AS subject_id, 'text.body' AS property_key, 'claim-t300-048-text' AS claim_id
UNION ALL
SELECT 'work-t300-048' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-048-author' AS claim_id
UNION ALL
SELECT 'work-t300-052' AS subject_id, 'text.body' AS property_key, 'claim-t300-052-text' AS claim_id
UNION ALL
SELECT 'work-t300-052' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-052-author' AS claim_id
UNION ALL
SELECT 'work-t300-053' AS subject_id, 'text.body' AS property_key, 'claim-t300-053-text' AS claim_id
UNION ALL
SELECT 'work-t300-053' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-053-author' AS claim_id
UNION ALL
SELECT 'work-t300-054' AS subject_id, 'text.body' AS property_key, 'claim-t300-054-text' AS claim_id
UNION ALL
SELECT 'work-t300-054' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-054-author' AS claim_id
UNION ALL
SELECT 'work-t300-056' AS subject_id, 'text.body' AS property_key, 'claim-t300-056-text' AS claim_id
UNION ALL
SELECT 'work-t300-056' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-056-author' AS claim_id
UNION ALL
SELECT 'work-t300-057' AS subject_id, 'text.body' AS property_key, 'claim-t300-057-text' AS claim_id
UNION ALL
SELECT 'work-t300-057' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-057-author' AS claim_id
UNION ALL
SELECT 'work-t300-060' AS subject_id, 'text.body' AS property_key, 'claim-t300-060-text' AS claim_id
UNION ALL
SELECT 'work-t300-060' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-060-author' AS claim_id
UNION ALL
SELECT 'work-t300-061' AS subject_id, 'text.body' AS property_key, 'claim-t300-061-text' AS claim_id
UNION ALL
SELECT 'work-t300-061' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-061-author' AS claim_id
UNION ALL
SELECT 'work-t300-062' AS subject_id, 'text.body' AS property_key, 'claim-t300-062-text' AS claim_id
UNION ALL
SELECT 'work-t300-062' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-062-author' AS claim_id
UNION ALL
SELECT 'work-t300-063' AS subject_id, 'text.body' AS property_key, 'claim-t300-063-text' AS claim_id
UNION ALL
SELECT 'work-t300-063' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-063-author' AS claim_id
UNION ALL
SELECT 'work-t300-064' AS subject_id, 'text.body' AS property_key, 'claim-t300-064-text' AS claim_id
UNION ALL
SELECT 'work-t300-064' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-064-author' AS claim_id
UNION ALL
SELECT 'work-t300-074' AS subject_id, 'text.body' AS property_key, 'claim-t300-074-text' AS claim_id
UNION ALL
SELECT 'work-t300-074' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-074-author' AS claim_id
UNION ALL
SELECT 'work-t300-079' AS subject_id, 'text.body' AS property_key, 'claim-t300-079-text' AS claim_id
UNION ALL
SELECT 'work-t300-079' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-079-author' AS claim_id
UNION ALL
SELECT 'work-t300-087' AS subject_id, 'text.body' AS property_key, 'claim-t300-087-text' AS claim_id
UNION ALL
SELECT 'work-t300-087' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-087-author' AS claim_id
UNION ALL
SELECT 'work-t300-097' AS subject_id, 'text.body' AS property_key, 'claim-t300-097-text' AS claim_id
UNION ALL
SELECT 'work-t300-097' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-097-author' AS claim_id
UNION ALL
SELECT 'work-t300-100' AS subject_id, 'text.body' AS property_key, 'claim-t300-100-text' AS claim_id
UNION ALL
SELECT 'work-t300-100' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-100-author' AS claim_id
UNION ALL
SELECT 'work-t300-101' AS subject_id, 'text.body' AS property_key, 'claim-t300-101-text' AS claim_id
UNION ALL
SELECT 'work-t300-101' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-101-author' AS claim_id
UNION ALL
SELECT 'work-t300-102' AS subject_id, 'text.body' AS property_key, 'claim-t300-102-text' AS claim_id
UNION ALL
SELECT 'work-t300-102' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-102-author' AS claim_id
UNION ALL
SELECT 'work-t300-106' AS subject_id, 'text.body' AS property_key, 'claim-t300-106-text' AS claim_id
UNION ALL
SELECT 'work-t300-106' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-106-author' AS claim_id
UNION ALL
SELECT 'work-t300-108' AS subject_id, 'text.body' AS property_key, 'claim-t300-108-text' AS claim_id
UNION ALL
SELECT 'work-t300-108' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-108-author' AS claim_id
UNION ALL
SELECT 'work-t300-112' AS subject_id, 'text.body' AS property_key, 'claim-t300-112-text' AS claim_id
UNION ALL
SELECT 'work-t300-112' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-112-author' AS claim_id
UNION ALL
SELECT 'work-t300-117' AS subject_id, 'text.body' AS property_key, 'claim-t300-117-text' AS claim_id
UNION ALL
SELECT 'work-t300-117' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-117-author' AS claim_id
UNION ALL
SELECT 'work-t300-118' AS subject_id, 'text.body' AS property_key, 'claim-t300-118-text' AS claim_id
UNION ALL
SELECT 'work-t300-118' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-118-author' AS claim_id
UNION ALL
SELECT 'work-t300-119' AS subject_id, 'text.body' AS property_key, 'claim-t300-119-text' AS claim_id
UNION ALL
SELECT 'work-t300-119' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-119-author' AS claim_id
UNION ALL
SELECT 'work-t300-121' AS subject_id, 'text.body' AS property_key, 'claim-t300-121-text' AS claim_id
UNION ALL
SELECT 'work-t300-121' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-121-author' AS claim_id
UNION ALL
SELECT 'work-t300-122' AS subject_id, 'text.body' AS property_key, 'claim-t300-122-text' AS claim_id
UNION ALL
SELECT 'work-t300-122' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-122-author' AS claim_id
UNION ALL
SELECT 'work-t300-131' AS subject_id, 'text.body' AS property_key, 'claim-t300-131-text' AS claim_id
UNION ALL
SELECT 'work-t300-131' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-131-author' AS claim_id
UNION ALL
SELECT 'work-t300-133' AS subject_id, 'text.body' AS property_key, 'claim-t300-133-text' AS claim_id
UNION ALL
SELECT 'work-t300-133' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-133-author' AS claim_id
UNION ALL
SELECT 'work-t300-134' AS subject_id, 'text.body' AS property_key, 'claim-t300-134-text' AS claim_id
UNION ALL
SELECT 'work-t300-134' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-134-author' AS claim_id
UNION ALL
SELECT 'work-t300-135' AS subject_id, 'text.body' AS property_key, 'claim-t300-135-text' AS claim_id
UNION ALL
SELECT 'work-t300-135' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-135-author' AS claim_id
UNION ALL
SELECT 'work-t300-136' AS subject_id, 'text.body' AS property_key, 'claim-t300-136-text' AS claim_id
UNION ALL
SELECT 'work-t300-136' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-136-author' AS claim_id
UNION ALL
SELECT 'work-t300-137' AS subject_id, 'text.body' AS property_key, 'claim-t300-137-text' AS claim_id
UNION ALL
SELECT 'work-t300-137' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-137-author' AS claim_id
UNION ALL
SELECT 'work-t300-140' AS subject_id, 'text.body' AS property_key, 'claim-t300-140-text' AS claim_id
UNION ALL
SELECT 'work-t300-140' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-140-author' AS claim_id
UNION ALL
SELECT 'work-t300-142' AS subject_id, 'text.body' AS property_key, 'claim-t300-142-text' AS claim_id
UNION ALL
SELECT 'work-t300-142' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-142-author' AS claim_id
UNION ALL
SELECT 'work-t300-145' AS subject_id, 'text.body' AS property_key, 'claim-t300-145-text' AS claim_id
UNION ALL
SELECT 'work-t300-145' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-145-author' AS claim_id
UNION ALL
SELECT 'work-t300-146' AS subject_id, 'text.body' AS property_key, 'claim-t300-146-text' AS claim_id
UNION ALL
SELECT 'work-t300-146' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-146-author' AS claim_id
UNION ALL
SELECT 'work-t300-148' AS subject_id, 'text.body' AS property_key, 'claim-t300-148-text' AS claim_id
UNION ALL
SELECT 'work-t300-148' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-148-author' AS claim_id
UNION ALL
SELECT 'work-t300-151' AS subject_id, 'text.body' AS property_key, 'claim-t300-151-text' AS claim_id
UNION ALL
SELECT 'work-t300-151' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-151-author' AS claim_id
UNION ALL
SELECT 'work-t300-153' AS subject_id, 'text.body' AS property_key, 'claim-t300-153-text' AS claim_id
UNION ALL
SELECT 'work-t300-153' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-153-author' AS claim_id
UNION ALL
SELECT 'work-t300-156' AS subject_id, 'text.body' AS property_key, 'claim-t300-156-text' AS claim_id
UNION ALL
SELECT 'work-t300-156' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-156-author' AS claim_id
UNION ALL
SELECT 'work-t300-157' AS subject_id, 'text.body' AS property_key, 'claim-t300-157-text' AS claim_id
UNION ALL
SELECT 'work-t300-157' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-157-author' AS claim_id
UNION ALL
SELECT 'work-t300-158' AS subject_id, 'text.body' AS property_key, 'claim-t300-158-text' AS claim_id
UNION ALL
SELECT 'work-t300-158' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-158-author' AS claim_id
UNION ALL
SELECT 'work-t300-159' AS subject_id, 'text.body' AS property_key, 'claim-t300-159-text' AS claim_id
UNION ALL
SELECT 'work-t300-159' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-159-author' AS claim_id
UNION ALL
SELECT 'work-t300-160' AS subject_id, 'text.body' AS property_key, 'claim-t300-160-text' AS claim_id
UNION ALL
SELECT 'work-t300-160' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-160-author' AS claim_id
UNION ALL
SELECT 'work-t300-161' AS subject_id, 'text.body' AS property_key, 'claim-t300-161-text' AS claim_id
UNION ALL
SELECT 'work-t300-161' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-161-author' AS claim_id
UNION ALL
SELECT 'work-t300-162' AS subject_id, 'text.body' AS property_key, 'claim-t300-162-text' AS claim_id
UNION ALL
SELECT 'work-t300-162' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-162-author' AS claim_id
UNION ALL
SELECT 'work-t300-164' AS subject_id, 'text.body' AS property_key, 'claim-t300-164-text' AS claim_id
UNION ALL
SELECT 'work-t300-164' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-164-author' AS claim_id
UNION ALL
SELECT 'work-t300-165' AS subject_id, 'text.body' AS property_key, 'claim-t300-165-text' AS claim_id
UNION ALL
SELECT 'work-t300-165' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-165-author' AS claim_id
UNION ALL
SELECT 'work-t300-169' AS subject_id, 'text.body' AS property_key, 'claim-t300-169-text' AS claim_id
UNION ALL
SELECT 'work-t300-169' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-169-author' AS claim_id
UNION ALL
SELECT 'work-t300-170' AS subject_id, 'text.body' AS property_key, 'claim-t300-170-text' AS claim_id
UNION ALL
SELECT 'work-t300-170' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-170-author' AS claim_id
UNION ALL
SELECT 'work-t300-171' AS subject_id, 'text.body' AS property_key, 'claim-t300-171-text' AS claim_id
UNION ALL
SELECT 'work-t300-171' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-171-author' AS claim_id
UNION ALL
SELECT 'work-t300-173' AS subject_id, 'text.body' AS property_key, 'claim-t300-173-text' AS claim_id
UNION ALL
SELECT 'work-t300-173' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-173-author' AS claim_id
UNION ALL
SELECT 'work-t300-186' AS subject_id, 'text.body' AS property_key, 'claim-t300-186-text' AS claim_id
UNION ALL
SELECT 'work-t300-186' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-186-author' AS claim_id
UNION ALL
SELECT 'work-t300-189' AS subject_id, 'text.body' AS property_key, 'claim-t300-189-text' AS claim_id
UNION ALL
SELECT 'work-t300-189' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-189-author' AS claim_id
UNION ALL
SELECT 'work-t300-193' AS subject_id, 'text.body' AS property_key, 'claim-t300-193-text' AS claim_id
UNION ALL
SELECT 'work-t300-193' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-193-author' AS claim_id
UNION ALL
SELECT 'work-t300-197' AS subject_id, 'text.body' AS property_key, 'claim-t300-197-text' AS claim_id
UNION ALL
SELECT 'work-t300-197' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-197-author' AS claim_id
UNION ALL
SELECT 'work-t300-198' AS subject_id, 'text.body' AS property_key, 'claim-t300-198-text' AS claim_id
UNION ALL
SELECT 'work-t300-198' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-198-author' AS claim_id
UNION ALL
SELECT 'work-t300-207' AS subject_id, 'text.body' AS property_key, 'claim-t300-207-text' AS claim_id
UNION ALL
SELECT 'work-t300-207' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-207-author' AS claim_id
UNION ALL
SELECT 'work-chun-wang' AS subject_id, 'text.body' AS property_key, 'claim-t300-208-text' AS claim_id
UNION ALL
SELECT 'work-chun-wang' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-208-author' AS claim_id
UNION ALL
SELECT 'work-t300-209' AS subject_id, 'text.body' AS property_key, 'claim-t300-209-text' AS claim_id
UNION ALL
SELECT 'work-t300-209' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-209-author' AS claim_id
UNION ALL
SELECT 'work-t300-210' AS subject_id, 'text.body' AS property_key, 'claim-t300-210-text' AS claim_id
UNION ALL
SELECT 'work-t300-210' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-210-author' AS claim_id
UNION ALL
SELECT 'work-t300-211' AS subject_id, 'text.body' AS property_key, 'claim-t300-211-text' AS claim_id
UNION ALL
SELECT 'work-t300-211' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-211-author' AS claim_id
UNION ALL
SELECT 'work-t300-214' AS subject_id, 'text.body' AS property_key, 'claim-t300-214-text' AS claim_id
UNION ALL
SELECT 'work-t300-214' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-214-author' AS claim_id
UNION ALL
SELECT 'work-t300-215' AS subject_id, 'text.body' AS property_key, 'claim-t300-215-text' AS claim_id
UNION ALL
SELECT 'work-t300-215' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-215-author' AS claim_id
UNION ALL
SELECT 'work-t300-216' AS subject_id, 'text.body' AS property_key, 'claim-t300-216-text' AS claim_id
UNION ALL
SELECT 'work-t300-216' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-216-author' AS claim_id
UNION ALL
SELECT 'work-t300-217' AS subject_id, 'text.body' AS property_key, 'claim-t300-217-text' AS claim_id
UNION ALL
SELECT 'work-t300-217' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-217-author' AS claim_id
UNION ALL
SELECT 'work-t300-220' AS subject_id, 'text.body' AS property_key, 'claim-t300-220-text' AS claim_id
UNION ALL
SELECT 'work-t300-220' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-220-author' AS claim_id
UNION ALL
SELECT 'work-t300-221' AS subject_id, 'text.body' AS property_key, 'claim-t300-221-text' AS claim_id
UNION ALL
SELECT 'work-t300-221' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-221-author' AS claim_id
UNION ALL
SELECT 'work-t300-231' AS subject_id, 'text.body' AS property_key, 'claim-t300-231-text' AS claim_id
UNION ALL
SELECT 'work-t300-231' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-231-author' AS claim_id
UNION ALL
SELECT 'work-t300-233' AS subject_id, 'text.body' AS property_key, 'claim-t300-233-text' AS claim_id
UNION ALL
SELECT 'work-t300-233' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-233-author' AS claim_id
UNION ALL
SELECT 'work-t300-234' AS subject_id, 'text.body' AS property_key, 'claim-t300-234-text' AS claim_id
UNION ALL
SELECT 'work-t300-234' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-234-author' AS claim_id
UNION ALL
SELECT 'work-t300-240' AS subject_id, 'text.body' AS property_key, 'claim-t300-240-text' AS claim_id
UNION ALL
SELECT 'work-t300-240' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-240-author' AS claim_id
UNION ALL
SELECT 'work-t300-248' AS subject_id, 'text.body' AS property_key, 'claim-t300-248-text' AS claim_id
UNION ALL
SELECT 'work-t300-248' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-248-author' AS claim_id
UNION ALL
SELECT 'work-t300-252' AS subject_id, 'text.body' AS property_key, 'claim-t300-252-text' AS claim_id
UNION ALL
SELECT 'work-t300-252' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-252-author' AS claim_id
UNION ALL
SELECT 'work-t300-262' AS subject_id, 'text.body' AS property_key, 'claim-t300-262-text' AS claim_id
UNION ALL
SELECT 'work-t300-262' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-262-author' AS claim_id
UNION ALL
SELECT 'work-t300-274' AS subject_id, 'text.body' AS property_key, 'claim-t300-274-text' AS claim_id
UNION ALL
SELECT 'work-t300-274' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-274-author' AS claim_id
UNION ALL
SELECT 'work-t300-276' AS subject_id, 'text.body' AS property_key, 'claim-t300-276-text' AS claim_id
UNION ALL
SELECT 'work-t300-276' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-276-author' AS claim_id
UNION ALL
SELECT 'work-t300-283' AS subject_id, 'text.body' AS property_key, 'claim-t300-283-text' AS claim_id
UNION ALL
SELECT 'work-t300-283' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-283-author' AS claim_id
UNION ALL
SELECT 'work-t300-284' AS subject_id, 'text.body' AS property_key, 'claim-t300-284-text' AS claim_id
UNION ALL
SELECT 'work-t300-284' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-284-author' AS claim_id
UNION ALL
SELECT 'work-t300-285' AS subject_id, 'text.body' AS property_key, 'claim-t300-285-text' AS claim_id
UNION ALL
SELECT 'work-t300-285' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-285-author' AS claim_id
UNION ALL
SELECT 'work-t300-289' AS subject_id, 'text.body' AS property_key, 'claim-t300-289-text' AS claim_id
UNION ALL
SELECT 'work-t300-289' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-289-author' AS claim_id
UNION ALL
SELECT 'work-t300-290' AS subject_id, 'text.body' AS property_key, 'claim-t300-290-text' AS claim_id
UNION ALL
SELECT 'work-t300-290' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-290-author' AS claim_id
UNION ALL
SELECT 'work-t300-291' AS subject_id, 'text.body' AS property_key, 'claim-t300-291-text' AS claim_id
UNION ALL
SELECT 'work-t300-291' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-291-author' AS claim_id
UNION ALL
SELECT 'work-t300-292' AS subject_id, 'text.body' AS property_key, 'claim-t300-292-text' AS claim_id
UNION ALL
SELECT 'work-t300-292' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-292-author' AS claim_id
UNION ALL
SELECT 'work-t300-296' AS subject_id, 'text.body' AS property_key, 'claim-t300-296-text' AS claim_id
UNION ALL
SELECT 'work-t300-296' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-296-author' AS claim_id
UNION ALL
SELECT 'work-t300-298' AS subject_id, 'text.body' AS property_key, 'claim-t300-298-text' AS claim_id
UNION ALL
SELECT 'work-t300-298' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-298-author' AS claim_id
UNION ALL
SELECT 'work-t300-299' AS subject_id, 'text.body' AS property_key, 'claim-t300-299-text' AS claim_id
UNION ALL
SELECT 'work-t300-299' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-299-author' AS claim_id
UNION ALL
SELECT 'work-t300-300' AS subject_id, 'text.body' AS property_key, 'claim-t300-300-text' AS claim_id
UNION ALL
SELECT 'work-t300-300' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-300-author' AS claim_id
UNION ALL
SELECT 'work-t300-308' AS subject_id, 'text.body' AS property_key, 'claim-t300-308-text' AS claim_id
UNION ALL
SELECT 'work-t300-308' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-308-author' AS claim_id
UNION ALL
SELECT 'work-t300-312' AS subject_id, 'text.body' AS property_key, 'claim-t300-312-text' AS claim_id
UNION ALL
SELECT 'work-t300-312' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-312-author' AS claim_id
UNION ALL
SELECT 'work-t300-320' AS subject_id, 'text.body' AS property_key, 'claim-t300-320-text' AS claim_id
UNION ALL
SELECT 'work-t300-320' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-320-author' AS claim_id
UNION ALL
SELECT 'work-t300-323' AS subject_id, 'text.body' AS property_key, 'claim-t300-323-text' AS claim_id
UNION ALL
SELECT 'work-t300-323' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-323-author' AS claim_id
UNION ALL
SELECT 'work-t300-325' AS subject_id, 'text.body' AS property_key, 'claim-t300-325-text' AS claim_id
UNION ALL
SELECT 'work-t300-325' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-325-author' AS claim_id
UNION ALL
SELECT 'work-t300-326' AS subject_id, 'text.body' AS property_key, 'claim-t300-326-text' AS claim_id
UNION ALL
SELECT 'work-t300-326' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-326-author' AS claim_id
UNION ALL
SELECT 'work-t300-328' AS subject_id, 'text.body' AS property_key, 'claim-t300-328-text' AS claim_id
UNION ALL
SELECT 'work-t300-328' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-328-author' AS claim_id
UNION ALL
SELECT 'work-t300-330' AS subject_id, 'text.body' AS property_key, 'claim-t300-330-text' AS claim_id
UNION ALL
SELECT 'work-t300-330' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-330-author' AS claim_id
UNION ALL
SELECT 'work-t300-331' AS subject_id, 'text.body' AS property_key, 'claim-t300-331-text' AS claim_id
UNION ALL
SELECT 'work-t300-331' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-331-author' AS claim_id
UNION ALL
SELECT 'work-t300-334' AS subject_id, 'text.body' AS property_key, 'claim-t300-334-text' AS claim_id
UNION ALL
SELECT 'work-t300-334' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-334-author' AS claim_id
UNION ALL
SELECT 'work-t300-335' AS subject_id, 'text.body' AS property_key, 'claim-t300-335-text' AS claim_id
UNION ALL
SELECT 'work-t300-335' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-335-author' AS claim_id
UNION ALL
SELECT 'work-t300-358' AS subject_id, 'text.body' AS property_key, 'claim-t300-358-text' AS claim_id
UNION ALL
SELECT 'work-t300-358' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-358-author' AS claim_id
UNION ALL
SELECT 'work-t300-360' AS subject_id, 'text.body' AS property_key, 'claim-t300-360-text' AS claim_id
UNION ALL
SELECT 'work-t300-360' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-360-author' AS claim_id
UNION ALL
SELECT 'work-t300-361' AS subject_id, 'text.body' AS property_key, 'claim-t300-361-text' AS claim_id
UNION ALL
SELECT 'work-t300-361' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-361-author' AS claim_id
UNION ALL
SELECT 'work-t300-363' AS subject_id, 'text.body' AS property_key, 'claim-t300-363-text' AS claim_id
UNION ALL
SELECT 'work-t300-363' AS subject_id, 'author.attribution' AS property_key, 'claim-t300-363-author' AS claim_id
) AS t WHERE NOT EXISTS (SELECT 1 FROM poetry_claim_selection x WHERE x.subject_id = t.subject_id AND x.property_key = t.property_key);

-- ---------- 6. 清理指引 ----------
-- 精确回滚见 recovery/V018_rollback.sql（按本文件的全部 id 反序删除；不删既有 person 行）。
