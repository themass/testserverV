-- 隧道 MTU 统计：客户端每次连接结束后上报一次，用于按节点 / 运营商 / 国家调整默认 MTU（见 doc/MTU-DESIGN.md 3.7）。
-- 本文件未在任何自动化流程中执行，需要手工在目标 MySQL 实例上运行一次。
-- 列命名延续本库约定：MyBatis 未开启 mapUnderscoreToCamelCase，列名就是驼峰的 Java 属性名。
-- 国家不在写入时查（不对每个请求调外部 IP 库），用 userIp 离线归属。

CREATE TABLE IF NOT EXISTS vpn.mtu_log (
    id         BIGINT      NOT NULL AUTO_INCREMENT,
    devId      VARCHAR(64) NULL COMMENT '设备 id',
    userIp     VARCHAR(64) NULL COMMENT '上报时的客户端出口 IP（服务端取，用于离线判断国家）',
    node       VARCHAR(96) NULL COMMENT '节点地址 host:port',
    protocol   VARCHAR(16) NULL COMMENT 'IKEV2 / WIREGUARD / UDP_RELAY / STREAM',
    netType    VARCHAR(8)  NULL COMMENT 'wifi / cell / eth / other',
    carrier    VARCHAR(16) NULL COMMENT '蜂窝运营商 MCC-MNC，Wi-Fi 时为空',
    linkMtu    INT         NOT NULL DEFAULT 0 COMMENT '底层链路 MTU，0=未知',
    mtu        INT         NOT NULL DEFAULT 0 COMMENT '本次实际使用的隧道 MTU',
    probe      VARCHAR(16) NULL COMMENT 'OK / UNREACHABLE / MTU_SUSPECT',
    retried    TINYINT     NOT NULL DEFAULT 0 COMMENT '是否为 1280 降级重连那一次',
    createdAt  DATETIME    NOT NULL,
    PRIMARY KEY (id),
    KEY idx_mtu_log_time (createdAt),
    KEY idx_mtu_log_node (node, probe)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '隧道 MTU 探测结果';
