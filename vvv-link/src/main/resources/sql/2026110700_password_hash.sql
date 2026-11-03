-- 登录密码哈希化
--
-- 背景：vpn.user.pwd 原来是明文。新增 pwdHash 保存 PBKDF2-SHA256 哈希。
-- 迁移策略（对旧客户端完全兼容）：
--   1. 旧账号 pwdHash 为 NULL：登录时仍按明文比对，成功后自动写入 pwdHash 并清空 pwd；
--   2. 新注册 / 改密 / 找回密码：直接写 pwdHash，pwd 置空；
--   3. 登录接口的请求与返回格式不变。
-- 注意：pwd 列保留（不删列），以便回滚；待所有账号都迁移后再考虑清理。

ALTER TABLE vpn.user
    ADD COLUMN pwdHash VARCHAR(255) NULL COMMENT 'PBKDF2-SHA256 密码哈希，格式 pbkdf2$iter$salt$hash';
