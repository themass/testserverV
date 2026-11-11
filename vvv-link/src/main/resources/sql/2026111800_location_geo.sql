-- 节点经纬度：让 3D 地球上的节点位置来自服务端，而不是客户端那张硬编码城市表。
-- 本文件未在任何自动化流程中执行，需要手工在目标 MySQL 实例上运行一次。
--
-- 为什么必须搬到服务端：客户端 GeoCatalog 用子串匹配城市名，匹配不上的节点在地球上
-- 直接不显示——真机日志里 14 个节点只有 13 个有坐标，用户看到的是"节点丢了"。
-- 而且新加一个城市就要发一次 App 版本，这不可持续。
--
-- 精度用 DECIMAL(8,4) / DECIMAL(9,4)：4 位小数约 11 米，远超城市级所需，
-- 同时保证「同一城市」的节点能精确同点（DOUBLE 会出现 22.3199999 这类噪声，
-- 而客户端是按小数点后 2 位分组排布的）。
--
-- 允许 NULL：老数据没有坐标时客户端仍走 GeoCatalog 兜底，不会因为这一列没回填就消失。

ALTER TABLE vpn.location_v2
    ADD COLUMN lat DECIMAL(8, 4) NULL COMMENT '纬度，-90~90；NULL 时客户端按城市名兜底',
    ADD COLUMN lng DECIMAL(9, 4) NULL COMMENT '经度，-180~180；NULL 时客户端按城市名兜底';

-- 回填：按 cityName / ename / name 里出现的城市关键字匹配。
-- 顺序很关键——先匹配更具体的城市名（"hong kong"、"los angeles"），再匹配国家名，
-- 否则 "united states" 会把 "los angeles" 也吞掉，所有美国节点都会挤到同一坐标。
--
-- 这张表与客户端 GeoCatalog.CITIES 保持一致；以后新城市直接在服务端加 UPDATE 即可，
-- 不需要再发版本。

-- 亚洲
UPDATE vpn.location_v2 SET lat = 22.3193, lng = 114.1694 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%hong kong%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%香港%');
UPDATE vpn.location_v2 SET lat = 35.6762, lng = 139.6503 WHERE lat IS NULL AND LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%tokyo%';
UPDATE vpn.location_v2 SET lat = 34.6937, lng = 135.5023 WHERE lat IS NULL AND LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%osaka%';
UPDATE vpn.location_v2 SET lat = 35.6762, lng = 139.6503 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%japan%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%日本%');
UPDATE vpn.location_v2 SET lat = 37.5665, lng = 126.9780 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%seoul%' OR LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%korea%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%韩国%');
UPDATE vpn.location_v2 SET lat = 25.0330, lng = 121.5654 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%taipei%' OR LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%taiwan%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%台湾%');
UPDATE vpn.location_v2 SET lat = 1.3521, lng = 103.8198 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%singapore%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%新加坡%');
UPDATE vpn.location_v2 SET lat = 3.1390, lng = 101.6869 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%kuala lumpur%' OR LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%malaysia%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%马来西亚%');
UPDATE vpn.location_v2 SET lat = 13.7563, lng = 100.5018 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%bangkok%' OR LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%thailand%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%泰国%');
UPDATE vpn.location_v2 SET lat = -6.2088, lng = 106.8456 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%jakarta%' OR LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%indonesia%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%印尼%');
UPDATE vpn.location_v2 SET lat = 10.8231, lng = 106.6297 WHERE lat IS NULL AND LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%ho chi minh%';
UPDATE vpn.location_v2 SET lat = 21.0278, lng = 105.8342 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%vietnam%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%越南%');
UPDATE vpn.location_v2 SET lat = 19.0760, lng = 72.8777 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%mumbai%' OR LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%india%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%印度%');

-- 中东 / 欧亚
UPDATE vpn.location_v2 SET lat = 25.2048, lng = 55.2708 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%dubai%' OR LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%uae%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%迪拜%');
UPDATE vpn.location_v2 SET lat = 41.0082, lng = 28.9784 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%istanbul%' OR LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%turkey%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%土耳其%');
UPDATE vpn.location_v2 SET lat = 55.7558, lng = 37.6173 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%moscow%' OR LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%russia%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%俄罗斯%');

-- 欧洲
UPDATE vpn.location_v2 SET lat = 51.5074, lng = -0.1278 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%london%' OR LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%united kingdom%' OR LOWER(CONCAT_WS(' ', cityName, ename, name)) = 'uk' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%英国%');
UPDATE vpn.location_v2 SET lat = 48.8566, lng = 2.3522 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%paris%' OR LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%france%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%法国%');
UPDATE vpn.location_v2 SET lat = 50.1109, lng = 8.6821 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%frankfurt%' OR LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%germany%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%德国%');
UPDATE vpn.location_v2 SET lat = 52.5200, lng = 13.4050 WHERE lat IS NULL AND LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%berlin%';
UPDATE vpn.location_v2 SET lat = 52.3676, lng = 4.9041 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%amsterdam%' OR LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%netherlands%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%荷兰%');
UPDATE vpn.location_v2 SET lat = 59.3293, lng = 18.0686 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%stockholm%' OR LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%sweden%');
UPDATE vpn.location_v2 SET lat = 40.4168, lng = -3.7038 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%madrid%' OR LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%spain%');
UPDATE vpn.location_v2 SET lat = 41.9028, lng = 12.4964 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%rome%' OR LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%italy%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%意大利%');

-- 北美
UPDATE vpn.location_v2 SET lat = 34.0522, lng = -118.2437 WHERE lat IS NULL AND LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%los angeles%';
UPDATE vpn.location_v2 SET lat = 37.3382, lng = -121.8863 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%san jose%' OR LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%silicon valley%');
UPDATE vpn.location_v2 SET lat = 47.6062, lng = -122.3321 WHERE lat IS NULL AND LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%seattle%';
UPDATE vpn.location_v2 SET lat = 41.8781, lng = -87.6298 WHERE lat IS NULL AND LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%chicago%';
UPDATE vpn.location_v2 SET lat = 40.7128, lng = -74.0060 WHERE lat IS NULL AND LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%new york%';
UPDATE vpn.location_v2 SET lat = 43.6532, lng = -79.3832 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%toronto%' OR LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%canada%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%加拿大%');
-- 美国整体放最后：前面已经把具体城市挑走了，剩下的才是"只有国家名"的节点（取地理中心）
UPDATE vpn.location_v2 SET lat = 37.0902, lng = -95.7129 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%united states%' OR LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%u.s.%' OR LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%usa%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%美国%');

-- 南美 / 大洋洲
UPDATE vpn.location_v2 SET lat = -23.5505, lng = -46.6333 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%sao paulo%' OR LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%brazil%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%巴西%');
UPDATE vpn.location_v2 SET lat = -33.8688, lng = 151.2093 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%sydney%' OR LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%australia%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%澳大利亚%');

-- 中国城市（放最后，避免被上一条 "china" 的全国规则抢先命中）
UPDATE vpn.location_v2 SET lat = 31.2304, lng = 121.4737 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%shanghai%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%上海%');
UPDATE vpn.location_v2 SET lat = 39.9042, lng = 116.4074 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%beijing%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%北京%');
UPDATE vpn.location_v2 SET lat = 23.1291, lng = 113.2644 WHERE lat IS NULL AND LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%guangzhou%';
UPDATE vpn.location_v2 SET lat = 22.5431, lng = 114.0579 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%shenzhen%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%深圳%');
UPDATE vpn.location_v2 SET lat = 30.2741, lng = 120.1551 WHERE lat IS NULL AND LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%hangzhou%';
UPDATE vpn.location_v2 SET lat = 30.5728, lng = 104.0668 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%chengdu%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%成都%');
UPDATE vpn.location_v2 SET lat = 35.8617, lng = 104.1954 WHERE lat IS NULL AND (LOWER(CONCAT_WS(' ', cityName, ename, name)) LIKE '%china%' OR CONCAT_WS(' ', cityName, ename, name) LIKE '%中国%');

-- 执行后核对：还有哪些节点没有坐标（这些就是需要手工补的城市）
-- SELECT id, name, ename, cityName FROM vpn.location_v2 WHERE enable = 1 AND (lat IS NULL OR lng IS NULL);
