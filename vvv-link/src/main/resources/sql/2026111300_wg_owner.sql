-- WireGuard 按线路等级同步：记录每台设备的所属用户名，同步时按用户当前等级过滤。
-- 本文件未在任何自动化流程中执行，需要手工在目标 MySQL 实例上运行一次，且先于部署新版后端。
-- 依赖 2026111200_wg_addr_index.sql。
--
-- 迁移前已注册的设备 userName 为 NULL：它们只会出现在免费线路（等级 0）的名单里，
-- 付费线路的名单不包含它们，直到该设备用所属账号重新注册（客户端在账号变化或首次新版本时会自动重新注册）。

ALTER TABLE vpn.wg_device_key
    ADD COLUMN userName VARCHAR(64) NULL COMMENT '注册该设备的登录用户名，用于按等级同步';

ALTER TABLE vpn.wg_device_key
    ADD KEY idx_userName (userName);
