-- 使用数据按天汇总：客户端每天上报一次"本机某一天连了多久、用了多少流量、连了几次"。
-- 本文件未在任何自动化流程中执行，需要手工在目标 MySQL 实例上运行一次。
-- 列命名延续本库约定：MyBatis 未开启 mapUnderscoreToCamelCase，列名就是驼峰的 Java 属性名。
--
-- 为什么是按天的行而不是事件流：需要回答的问题只有"留存多少、每天用多久、哪个功能有人碰"，
-- 事件流会写爆表而且客户端离线时无法可靠补传。按天一行，(devId, day) 唯一，重复上报覆盖，
-- 客户端可以随时重发最近 7 天而不产生重复数据。
--
-- 留存不用另外的字段：某设备第一次出现的 day 就是它的安装日，之后有行就是当天回来过，
-- D1 / D7 用一条 SQL 就能算出来。所以这张表只存"行为"，不存推算出来的指标。
--
-- 注意：ip 与 devId 属于设备标识，仅用于排障与地域分布，不做用户画像。

CREATE TABLE IF NOT EXISTS vpn.usage_daily (
    id          BIGINT      NOT NULL AUTO_INCREMENT,
    devId       VARCHAR(64) NOT NULL COMMENT '设备 id（服务端从请求头取）',
    day         DATE        NOT NULL COMMENT '统计的本地日期，客户端时区',
    userId      BIGINT      NULL COMMENT '当天的登录用户，未登录为 NULL',
    userIp      VARCHAR(64) NULL COMMENT '上报时的客户端出口 IP（服务端取）',
    version     VARCHAR(32) NULL COMMENT 'App 版本号',
    platform    VARCHAR(16) NULL COMMENT 'android / ios',
    tzOffsetMin INT         NOT NULL DEFAULT 0 COMMENT '客户端时区相对 UTC 的分钟数，用于校正"哪一天"',
    connectedMs BIGINT      NOT NULL DEFAULT 0 COMMENT '当天 VPN 处于已连接状态的累计毫秒',
    sessions    INT         NOT NULL DEFAULT 0 COMMENT '当天发起的连接次数',
    rxBytes     BIGINT      NOT NULL DEFAULT 0 COMMENT '当天隧道下行字节',
    txBytes     BIGINT      NOT NULL DEFAULT 0 COMMENT '当天隧道上行字节',
    nodes       INT         NOT NULL DEFAULT 0 COMMENT '当天连接过的不同节点数',
    protocols   VARCHAR(128) NULL COMMENT '当天用过的协议，逗号分隔',
    featureMask INT         NOT NULL DEFAULT 0 COMMENT '当天用过哪些功能，见客户端 UsageReport.FEATURE_*',
    createdAt   DATETIME    NOT NULL COMMENT '首次写入时间',
    updatedAt   DATETIME    NOT NULL COMMENT '最后一次覆盖时间',
    PRIMARY KEY (id),
    UNIQUE KEY uk_usage_daily_dev_day (devId, day),
    KEY idx_usage_daily_day (day),
    KEY idx_usage_daily_user (userId, day)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '设备每日使用汇总（留存与时长分析）';
