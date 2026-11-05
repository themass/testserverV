-- WireGuard：每台设备一个唯一的隧道内地址。
-- 本文件未在任何自动化流程中执行，需要手工在目标 MySQL 实例上运行一次，且先于部署新版后端。
-- 依赖 2026110100_wireguard.sql 已先执行（wg_device_key 表）。
--
-- addrIndex 2 ~ 65279 对应 10.66.0.2 ~ 10.66.254.255（见 WgAddress.java）：
--   10.66.0.1       服务端接口地址
--   10.66.255.0/24  保留给运维手工添加的 peer，自动分配不会落进来
--
-- 为什么需要它：此前 host_v2.clientAddress 每个节点一个固定值，所有设备拿到同一个地址，
-- 两台设备同时连同一个节点会冲突。WireGuard 靠 AllowedIPs 把包路由给对应的 peer，每个 peer 必须独占一个 /32。

ALTER TABLE vpn.wg_device_key
    ADD COLUMN addrIndex INT NULL COMMENT '隧道内地址序号，2~65279，对应 10.66.(i/256).(i%256)/32';

-- 已有记录按 id 顺序回填：从 2 开始连续编号。
SET @n := 1;
UPDATE vpn.wg_device_key SET addrIndex = (@n := @n + 1) ORDER BY id;

-- 记录数超过 65278 时上面的回填会越界，先确认：下面应返回空。
SELECT id, addrIndex FROM vpn.wg_device_key WHERE addrIndex > 65279;

ALTER TABLE vpn.wg_device_key
    MODIFY COLUMN addrIndex INT NOT NULL,
    ADD UNIQUE KEY uk_addrIndex (addrIndex);

-- 回填时设备拿到的地址与它此前（共用的）clientAddress 不同。老客户端本地没有保存地址，
-- 会在下次连接时重新注册并拿到自己的地址，不需要用户操作。
