-- VPN 客户端相关表的基础建库脚本（首次部署在空实例上执行）。
-- 覆盖范围：仅 Android VPN 客户端实际会用到的接口所依赖的表
-- （登录、节点下发、DNS、设备/版本上报、RADIUS 鉴权）。
-- 这个后端仓库（vvv-link）还承载了图片/视频/聊天等其它业务模块的表，
-- 那些与 VPN 客户端无关，不在本脚本范围内。
--
-- 执行顺序：
--   1) 本文件（2026110000_baseline.sql）
--   2) 2026110100_wireguard.sql
--   3) 2026110300_vless_reality.sql
--
-- 列命名延续仓库既有约定：MyBatis 未开启 mapUnderscoreToCamelCase，
-- 列名直接按 Java 属性名用驼峰命名。

CREATE DATABASE IF NOT EXISTS vpn DEFAULT CHARACTER SET utf8mb4;
CREATE DATABASE IF NOT EXISTS radius DEFAULT CHARACTER SET utf8mb4;

-- ========== vpn.user：账号（UserPo / UserMapper.xml） ==========
CREATE TABLE IF NOT EXISTS vpn.user
(
    id            BIGINT       NOT NULL AUTO_INCREMENT,
    name          VARCHAR(64)  NOT NULL COMMENT '登录名/设备名，RADIUS 鉴权也用这个值',
    pwd           VARCHAR(128) NOT NULL,
    sex           VARCHAR(8)   NULL,
    level         INT          NOT NULL DEFAULT 0 COMMENT '0=免费，>=1 为 VIP 等级',
    time          DATETIME     NULL COMMENT '注册时间',
    email         VARCHAR(128) NULL,
    score         BIGINT       NOT NULL DEFAULT 0,
    photo         VARCHAR(255) NULL,
    channel       VARCHAR(32)  NULL COMMENT '渠道标识',
    paidStartTime DATETIME     NULL,
    paidEndTime   DATETIME     NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_name (name)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '用户账号';

-- ========== vpn.host_v2：VPN 节点（HostPo / HostV2Mapper.xml） ==========
-- 这是客户端 /host/server/list.json 实际读取的表。
-- 下面的列定义**严格照抄生产库 SHOW CREATE TABLE 的输出**（2026-11-02 核对），
-- 不再从 Java 代码反推——反推会漏掉 com/cname/lname/cert/traffic/pay/money
-- 这些展示字段，也会凭空造出生产库根本没有的 type 列。
-- 多协议扩展字段由后续三个迁移脚本追加（protocols ... wireGuardPort）。
CREATE TABLE IF NOT EXISTS vpn.host_v2
(
    id       INT          NOT NULL AUTO_INCREMENT,
    hostId   INT          NULL,
    gateway  VARCHAR(45)  NOT NULL,
    port     INT          NOT NULL DEFAULT 4500,
    showName VARCHAR(45)  NOT NULL,
    enable   INT          NOT NULL DEFAULT 1,
    com      VARCHAR(45)  NOT NULL,
    weight   INT          NOT NULL DEFAULT 1,
    cname    VARCHAR(45)  NOT NULL,
    lname    VARCHAR(45)  NULL,
    cert     VARCHAR(8000) NOT NULL,
    traffic  VARCHAR(45)  NOT NULL DEFAULT '不限',
    pay      VARCHAR(45)  NOT NULL DEFAULT '月',
    money    VARCHAR(45)  NULL DEFAULT '3刀',
    needPing INT          NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    KEY index2 (hostId)
) ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin COMMENT = 'VPN 节点（网关）';

-- ========== vpn.location_v2：线路/地区（LocationPo / LocationV2Mapper.xml） ==========
-- 同样照抄生产库 SHOW CREATE TABLE。注意：
--   ⚠️ category 允许 NULL，而 LocationPo.compareTo 直接调用
--      category.compareTo(...) 没有判空，HostIpCacheV2.getLocationList
--      会对结果 Collections.sort(ret)，所以 category 为 NULL 的地区
--      会让整个接口抛 NPE。新增地区务必显式写 category。
CREATE TABLE IF NOT EXISTS vpn.location_v2
(
    id       INT          NOT NULL AUTO_INCREMENT,
    img      VARCHAR(100) NOT NULL,
    name     VARCHAR(45)  NOT NULL,
    ename    VARCHAR(45)  NOT NULL,
    hostId   INT          NULL,
    type     INT          NOT NULL DEFAULT 3,
    cityName VARCHAR(45)  NULL,
    level    INT          NOT NULL DEFAULT 5,
    enable   INT          NOT NULL DEFAULT 1,
    channel  VARCHAR(45)  NULL DEFAULT 'VPN',
    category VARCHAR(45)  NULL COMMENT '不能为 NULL：LocationPo.compareTo 未判空，NULL 会导致接口 500',
    PRIMARY KEY (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin COMMENT = 'VPN 线路/地区';

-- ========== vpn.dns：自定义 DNS 解析（DnsResverPo / DnsMapper.xml） ==========
CREATE TABLE IF NOT EXISTS vpn.dns
(
    id     INT          NOT NULL AUTO_INCREMENT,
    domain VARCHAR(128) NOT NULL,
    ip     VARCHAR(64)  NOT NULL,
    ttl    INT          NOT NULL DEFAULT 300,
    PRIMARY KEY (id),
    KEY idx_domain (domain)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '自定义域名解析（客户端分屏/反代用）';

-- ========== vpn.version：App 版本（AppVersion / VersionMapper.xml） ==========
CREATE TABLE IF NOT EXISTS vpn.version
(
    id       INT          NOT NULL AUTO_INCREMENT,
    version  VARCHAR(32)  NOT NULL,
    minBuild VARCHAR(32)  NULL,
    maxBuild VARCHAR(32)  NULL,
    platform VARCHAR(16)  NOT NULL DEFAULT 'android',
    channel  VARCHAR(32)  NOT NULL DEFAULT 'default',
    content  TEXT         NULL COMMENT '更新日志',
    url      VARCHAR(255) NULL COMMENT '下载地址',
    time     DATETIME     NULL,
    showGdt  TINYINT(1)   NULL,
    PRIMARY KEY (id),
    KEY idx_platform_channel (platform, channel)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = 'App 版本管理';

-- ========== vpn.appinfo：推荐应用/捐赠位（AppInfoPo / AppInfoMapper.xml） ==========
CREATE TABLE IF NOT EXISTS vpn.appinfo
(
    id   INT          NOT NULL AUTO_INCREMENT,
    name VARCHAR(64)  NOT NULL,
    `desc` VARCHAR(255) NULL,
    date VARCHAR(32)  NULL,
    img  VARCHAR(255) NULL,
    url  VARCHAR(255) NULL,
    type VARCHAR(16)  NOT NULL DEFAULT 'APP' COMMENT 'APP=推荐应用，DON=捐赠位',
    PRIMARY KEY (id),
    KEY idx_type (type)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '推荐应用/捐赠信息';

-- ========== vpn.devuseinfo：设备上报（DevUseinfoPo / DevUseinfoMapper.xml） ==========
CREATE TABLE IF NOT EXISTS vpn.devuseinfo
(
    devId      VARCHAR(64)  NOT NULL,
    platform   VARCHAR(16)  NULL,
    version    VARCHAR(32)  NULL,
    creatTime  DATETIME     NULL,
    lastUpdate DATETIME     NULL,
    longitude  VARCHAR(32)  NULL,
    latitude   VARCHAR(32)  NULL,
    userName   VARCHAR(64)  NULL,
    ref        VARCHAR(64)  NULL COMMENT '邀请码/推荐人',
    channel    VARCHAR(32)  NULL,
    ext        VARCHAR(255) NULL,
    uHist      VARCHAR(255) NULL,
    ip         VARCHAR(64)  NULL,
    loc        VARCHAR(64)  NULL,
    PRIMARY KEY (devId),
    KEY idx_userName (userName),
    KEY idx_ref (ref)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '设备使用情况上报';

-- ========== vpn.connlog：连接日志（ConnLogPo / ConnlogMapper.xml） ==========
CREATE TABLE IF NOT EXISTS vpn.connlog
(
    id     BIGINT      NOT NULL AUTO_INCREMENT,
    name   VARCHAR(64) NULL COMMENT '用户/设备标识',
    host   VARCHAR(64) NULL COMMENT '连接的网关',
    userIp VARCHAR(64) NULL COMMENT '客户端出口 IP',
    status INT         NOT NULL DEFAULT 0,
    time   VARCHAR(32) NULL,
    curIp  VARCHAR(64) NULL,
    PRIMARY KEY (id),
    KEY idx_name (name)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = 'VPN 连接事件日志';

-- ========== vpn.fileip：启动时预加载的 IP 名单缓存（FileIpPo / FileIpMapper.xml） ==========
-- 应用启动时 FileIpCache 会无条件 SELECT * FROM vpn.fileip，表不存在会导致启动失败。
CREATE TABLE IF NOT EXISTS vpn.fileip
(
    id    INT         NOT NULL AUTO_INCREMENT,
    type  VARCHAR(32) NULL,
    ip    VARCHAR(64) NULL,
    extra VARCHAR(255) NULL,
    PRIMARY KEY (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '启动时预加载的 IP 名单';

-- ========== vpn.location / vpn.host：旧版（非 v2）节点表 ==========
-- 应用启动时 HostCheck / HostIpCache 这两个缓存仍然查旧表，哪怕客户端已经
-- 全面切到 v2（host_v2 / location_v2）。保留空表只是为了让应用能启动，
-- 不代表旧版线路还在对外提供服务。
CREATE TABLE IF NOT EXISTS vpn.location
(
    id       INT          NOT NULL AUTO_INCREMENT,
    img      VARCHAR(255) NULL,
    name     VARCHAR(64)  NULL,
    ename    VARCHAR(64)  NULL,
    type     INT          NOT NULL DEFAULT 0,
    enable   TINYINT(1)   NOT NULL DEFAULT 0,
    cityName VARCHAR(64)  NULL,
    level    INT          NOT NULL DEFAULT 0,
    showName VARCHAR(64)  NULL,
    category VARCHAR(32)  NOT NULL DEFAULT 'normal',
    channel  VARCHAR(16)  NOT NULL DEFAULT 'VPN',
    PRIMARY KEY (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '旧版线路表，仅为启动兼容保留';

CREATE TABLE IF NOT EXISTS vpn.host
(
    id       INT         NOT NULL AUTO_INCREMENT,
    gateway  VARCHAR(64) NULL,
    port     INT         NOT NULL DEFAULT 500,
    location INT         NOT NULL DEFAULT 0,
    cert     VARCHAR(64) NULL,
    type     INT         NOT NULL DEFAULT 0,
    weight   FLOAT       NOT NULL DEFAULT 1,
    cname    VARCHAR(32) NULL,
    enable   TINYINT(1)  NOT NULL DEFAULT 0,
    PRIMARY KEY (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '旧版网关表，仅为启动兼容保留';

-- ========== vpn.blackdev：设备黑名单（BlackDevPo / BlackDevMapper.xml） ==========
-- 每次请求都会查这张表做设备封禁检查（CommonUtil.isDog），未建表会直接 500。
CREATE TABLE IF NOT EXISTS vpn.blackdev
(
    id    INT         NOT NULL AUTO_INCREMENT,
    devId VARCHAR(64) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_devId (devId)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '设备黑名单';

-- ========== radius.radcheck / radusergroup：FreeRADIUS 标准表结构 ==========
-- getHostInfoV2 每次都会先查/建 RADIUS 用户（RadUserCheckServiceImpl），
-- 这两张表是 FreeRADIUS 官方 schema 的最小子集，字段名与之兼容。
CREATE TABLE IF NOT EXISTS radius.radcheck
(
    id       INT          NOT NULL AUTO_INCREMENT,
    username VARCHAR(64)  NOT NULL DEFAULT '',
    attribute VARCHAR(64) NOT NULL DEFAULT '',
    op       CHAR(2)      NOT NULL DEFAULT '==',
    value    VARCHAR(253) NOT NULL DEFAULT '',
    PRIMARY KEY (id),
    KEY idx_username (username)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = 'RADIUS 用户密钥';

CREATE TABLE IF NOT EXISTS radius.radusergroup
(
    id       INT         NOT NULL AUTO_INCREMENT,
    username VARCHAR(64) NOT NULL DEFAULT '',
    groupname VARCHAR(64) NOT NULL DEFAULT '',
    priority INT         NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    KEY idx_username (username)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = 'RADIUS 用户分组';

-- 请求链路上每次都会查/写 radacct（会话计费、IP 归属回填），
-- 字段集沿用 FreeRADIUS 官方 schema，并追加本项目自用的 fromAddr/toAddr/status。
CREATE TABLE IF NOT EXISTS radius.radacct
(
    radacctid         BIGINT       NOT NULL AUTO_INCREMENT,
    acctsessionid     VARCHAR(64)  NOT NULL DEFAULT '',
    acctuniqueid      VARCHAR(32)  NOT NULL DEFAULT '',
    username          VARCHAR(64)  NOT NULL DEFAULT '',
    nasipaddress      VARCHAR(64)  NOT NULL DEFAULT '',
    callingstationid  VARCHAR(64)  NULL,
    acctstarttime     DATETIME     NULL,
    acctstoptime      DATETIME     NULL,
    acctsessiontime   BIGINT       NULL,
    acctinputoctets   BIGINT       NULL DEFAULT 0,
    acctoutputoctets  BIGINT       NULL DEFAULT 0,
    fromAddr          VARCHAR(64)  NULL COMMENT '本项目自用：IP 归属地回填源地址',
    toAddr            VARCHAR(64)  NULL COMMENT '本项目自用：IP 归属地回填目的地址',
    status            INT          NOT NULL DEFAULT 0 COMMENT '本项目自用：0=待回填，1=已回填',
    PRIMARY KEY (radacctid),
    KEY idx_username (username),
    KEY idx_status (status)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = 'RADIUS 会话计费记录';

CREATE TABLE IF NOT EXISTS radius.radpostauth
(
    id         BIGINT      NOT NULL AUTO_INCREMENT,
    username   VARCHAR(64) NOT NULL DEFAULT '',
    reply      VARCHAR(32) NULL,
    authdate   DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = 'RADIUS 鉴权审计记录';
