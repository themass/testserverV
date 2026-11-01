-- VLESS+Reality 支持：host_v2 扩展字段
-- 本文件未在任何自动化流程中执行，需要手工在目标 MySQL 实例上运行一次。
-- 字段命名延续本库既有约定（驼峰列名，MyBatis 未开启 mapUnderscoreToCamelCase）。
-- 依赖 2026110100_wireguard.sql 已先执行（protocols 列由该脚本创建，"vless-reality"
-- 是 protocols 里追加的一个值，与 "wireguard"、"ikev2" 并列，不冲突）。

ALTER TABLE vpn.host_v2
    ADD COLUMN vlessUuid          VARCHAR(64)  NULL COMMENT 'VLESS 用户 UUID',
    ADD COLUMN vlessFlow          VARCHAR(32)  NULL COMMENT 'VLESS 流控，如 xtls-rprx-vision',
    ADD COLUMN realityServerName  VARCHAR(128) NULL COMMENT 'Reality 握手用的借用域名（SNI）',
    ADD COLUMN realityPublicKey   VARCHAR(64)  NULL COMMENT 'Reality 服务端公钥，Base64',
    ADD COLUMN realityShortId     VARCHAR(32)  NULL COMMENT 'Reality short ID',
    ADD COLUMN realityFingerprint VARCHAR(32)  NULL COMMENT 'Reality TLS 指纹伪装，如 chrome';
