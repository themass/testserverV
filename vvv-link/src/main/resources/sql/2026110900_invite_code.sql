-- 邀请码：每个用户一个，注册时填写他人的邀请码即可双方各得 1 张观看券。
--
-- 发券记录仍写在 user_reward_ticket（granted=1，transaction_id 唯一），
-- 所以同一个被邀请人只能被发一次券，重复注册或重复提交不会重复发放。

CREATE TABLE IF NOT EXISTS vpn.user_invite (
    user_name  VARCHAR(64) NOT NULL PRIMARY KEY,
    code       VARCHAR(16) NOT NULL,
    created_at DATETIME    NOT NULL,
    UNIQUE KEY uk_invite_code (code)
) DEFAULT CHARSET = utf8mb4;
