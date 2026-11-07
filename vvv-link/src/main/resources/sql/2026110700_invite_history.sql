-- 邀请码发出记录：用于"10 天内不重复"的判断。
-- 每次发出一个新码就写一行；超过 10 天的记录在下次发码时被覆盖删除。
-- 当前每个用户的码仍在 vpn.user_invite（有效期 5 天由 created_at 判断）。

CREATE TABLE IF NOT EXISTS vpn.invite_code_history (
    code      VARCHAR(8)  NOT NULL PRIMARY KEY,
    user_name VARCHAR(64) NOT NULL,
    issued_at DATETIME    NOT NULL,
    KEY idx_issued_at (issued_at)
) DEFAULT CHARSET = utf8mb4;
