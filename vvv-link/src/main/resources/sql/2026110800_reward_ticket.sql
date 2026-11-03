-- 激励视频观看券
--
-- granted=1：发放的观看券（可用于兑换 VIP）；granted=0：审计记录（超过每日上限或冷却中被拒）。
-- transaction_id 来自 AdMob 服务端回调，唯一约束用于防重放。
-- 观看券有效期 7 天（expire_at）。兑换时标记 used=1。

CREATE TABLE IF NOT EXISTS vpn.user_reward_ticket (
    id             BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_name      VARCHAR(64)  NOT NULL,
    transaction_id VARCHAR(128) NOT NULL,
    granted        TINYINT      NOT NULL DEFAULT 0,
    used           TINYINT      NOT NULL DEFAULT 0,
    created_at     DATETIME     NOT NULL,
    expire_at      DATETIME     NOT NULL,
    UNIQUE KEY uk_reward_tx (transaction_id),
    KEY idx_reward_user (user_name, granted, used)
) DEFAULT CHARSET = utf8mb4;
