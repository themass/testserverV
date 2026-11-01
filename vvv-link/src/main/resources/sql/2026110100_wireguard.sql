-- WireGuard 支持：host_v2 扩展字段 + 设备公钥注册表
-- 本文件未在任何自动化流程中执行，需要手工在目标 MySQL 实例上运行一次。
-- 字段命名延续本库既有约定：MyBatis 未开启 mapUnderscoreToCamelCase，
-- 列名直接按 Java 属性名用驼峰命名（对照 host_v2 现有的 hostId/needPing/showName）。

ALTER TABLE vpn.host_v2
    ADD COLUMN protocols     VARCHAR(64)  NULL COMMENT '支持的协议，逗号分隔，如 ikev2,wireguard；为空表示仅 ikev2',
    ADD COLUMN peerPublicKey VARCHAR(64)  NULL COMMENT 'WireGuard 服务端公钥，Base64',
    ADD COLUMN clientAddress VARCHAR(64)  NULL COMMENT 'WireGuard 分配给客户端的地址，CIDR',
    ADD COLUMN dns           VARCHAR(128) NULL COMMENT 'WireGuard 隧道内 DNS，逗号分隔',
    ADD COLUMN mtu           INT          NULL COMMENT '建议 MTU；NULL 表示由协议默认值决定';

-- 客户端 WireGuard 身份注册表。一台设备一条记录，重复注册覆盖旧公钥
-- （见 WgDeviceKeyMapper.xml 的 upsert 注释，对应客户端重装/重置身份的场景）。
CREATE TABLE IF NOT EXISTS vpn.wg_device_key
(
    id         BIGINT       NOT NULL AUTO_INCREMENT,
    devId      VARCHAR(64)  NOT NULL COMMENT '设备标识，对应 Android 端 DeviceInfoUtils.getDeviceId()',
    publicKey  VARCHAR(64)  NOT NULL COMMENT 'WireGuard 公钥，Base64',
    createdAt  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_devId (devId)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COMMENT ='WireGuard 客户端公钥注册表';
