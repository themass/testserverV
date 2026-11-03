-- 找回密码：邮箱验证码
--
-- 只存验证码的 SHA-256 哈希，不存明文。有效期 30 分钟，最多错 5 次，用过即失效。
-- 同一用户只保留最新一条未使用的验证码（新请求会把旧的标记为 used）。

CREATE TABLE IF NOT EXISTS vpn.user_reset_code (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_name   VARCHAR(64) NOT NULL,
    code_hash   CHAR(64)    NOT NULL,
    expire_at   DATETIME    NOT NULL,
    used        TINYINT     NOT NULL DEFAULT 0,
    attempts    INT         NOT NULL DEFAULT 0,
    create_time DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_user_reset_user (user_name, used)
) DEFAULT CHARSET = utf8mb4;
