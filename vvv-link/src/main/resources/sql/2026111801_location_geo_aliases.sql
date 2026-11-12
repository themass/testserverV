-- 补齐上一轮没匹配上的节点：缩写（HK / NED / TUR）、拼写变体（England / Lsrael）、
-- 以及 GeoCatalog 里没有的国家（Philippines / Moldova / Bulgaria / Ukraine / Finland / Poland）。
--
-- 这些是 2026111800_location_geo.sql 执行后核对出来的剩余节点。第一轮只覆盖了
-- "城市名 + 常见国家全名"，而这张表里大量用的是三字母缩写或中文名，所以漏掉了。
--
-- 注意：这里同样先具体后笼统，避免把 "US-Reality" 之类吞进国家规则。

-- 香港（HK 缩写 + 中文）
UPDATE vpn.location_v2 SET lat = 22.3193, lng = 114.1694 WHERE lat IS NULL AND LOWER(TRIM(CONCAT_WS(' ', cityName, ename, name))) REGEXP '(^| )(hk|hong kong)( |$)';
UPDATE vpn.location_v2 SET lat = 22.3193, lng = 114.1694 WHERE lat IS NULL AND CONCAT_WS(' ', cityName, ename, name) LIKE '%香港%';

-- 荷兰（NED 缩写）
UPDATE vpn.location_v2 SET lat = 52.3676, lng = 4.9041 WHERE lat IS NULL AND (LOWER(TRIM(CONCAT_WS(' ', cityName, ename, name))) REGEXP '(^| )(ned|netherlands|holland)( |$)' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%荷兰%');

-- 英格兰 / 英国（England 与 UK 分开写）
UPDATE vpn.location_v2 SET lat = 51.5074, lng = -0.1278 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%england%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%英国%');

-- 波兰
UPDATE vpn.location_v2 SET lat = 52.2297, lng = 21.0122 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%poland%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%波兰%');

-- 菲律宾
UPDATE vpn.location_v2 SET lat = 14.5995, lng = 120.9842 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%philippines%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%菲律宾%');

-- 摩尔多瓦（基希讷乌是首都，用首都坐标更有意义）
UPDATE vpn.location_v2 SET lat = 47.0105, lng = 28.8638 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%moldova%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%摩尔多瓦%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%基希讷乌%');

-- 保加利亚（索菲亚）
UPDATE vpn.location_v2 SET lat = 42.6977, lng = 23.3219 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%bulgaria%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%保加利亚%');

-- 乌克兰（基辅）
UPDATE vpn.location_v2 SET lat = 50.4501, lng = 30.5234 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%ukraine%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%乌克兰%');

-- 芬兰（赫尔辛基）
UPDATE vpn.location_v2 SET lat = 60.1699, lng = 24.9384 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%finland%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%芬兰%');

-- 土耳其（TUR 缩写）
UPDATE vpn.location_v2 SET lat = 41.0082, lng = 28.9784 WHERE lat IS NULL AND (LOWER(TRIM(CONCAT_WS(' ', cityName, ename, name))) REGEXP '(^| )(tur|turkey)( |$)' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%土耳其%');

-- 立陶宛（"Lietuvos" 是立陶宛语国名，维尔纽斯）
UPDATE vpn.location_v2 SET lat = 54.6872, lng = 25.2797 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%lietuv%' OR LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%lithuania%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%立陶宛%');

-- 以色列（表里拼成了 "Lsrael"，是 eL 被误打成 L 的常见笔误；两种都匹配）
UPDATE vpn.location_v2 SET lat = 31.7683, lng = 35.2137 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%israel%' OR LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%lsrael%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%以色列%');

-- 美国（"US-Reality" 这类带 US 前缀的变体，放最后避免吞掉更具体的地名）
UPDATE vpn.location_v2 SET lat = 37.0902, lng = -95.7129 WHERE lat IS NULL AND LOWER(TRIM(CONCAT_WS(' ', cityName, ename, name))) REGEXP '(^| )(us|usa|u\\.s\\.a?)( |$|-)';

-- 执行后核对（应只剩 id=0 的 Random 占位项）
-- SELECT id, name, ename, cityName FROM vpn.location_v2 WHERE enable = 1 AND (lat IS NULL OR lng IS NULL);
