-- WireGuard 端点端口独立成列
--
-- 背景：host_v2.port 原本是 IKEv2 端口（500/4500）。一个节点若同时支持
-- IKEv2 与 WireGuard，两者端口通常不同（51820 vs 500），共用一个列会让
-- 其中一个协议连到错误端口，表现为"握手超时"或"连上无流量"。
--
-- 该列为 NULL 时客户端回退到 host_v2.port，再回退到 51820，
-- 因此对只跑 IKEv2 的既有节点完全无影响，不需要回填。

ALTER TABLE vpn.host_v2
    ADD COLUMN wireGuardPort INT NULL COMMENT 'WireGuard 端点端口；NULL 表示回退到 port 列';
