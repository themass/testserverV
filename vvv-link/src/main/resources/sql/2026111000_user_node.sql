-- 用户自定义节点（VMess / Trojan 分享链接），按用户隔离，换设备后仍可用。
--
-- 每条记录保存用户粘贴的原始链接；协议、地址、端口由服务端解析后冗余存一份，便于列表展示。
-- 所有查询都带 user_name，保证用户之间互相不可见。

CREATE TABLE IF NOT EXISTS vpn.user_node (
    id          VARCHAR(36)  NOT NULL PRIMARY KEY,
    user_name   VARCHAR(64)  NOT NULL,
    name        VARCHAR(128) NOT NULL,
    link        TEXT         NOT NULL,
    protocol    VARCHAR(16)  NOT NULL,
    server      VARCHAR(255) NOT NULL,
    port        INT          NOT NULL,
    updated_at  DATETIME     NOT NULL,
    KEY idx_user_node_user (user_name)
) DEFAULT CHARSET = utf8mb4;
