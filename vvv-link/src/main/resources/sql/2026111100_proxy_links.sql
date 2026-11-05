-- 通用代理节点：host_v2 增加 proxyLinks 列（JSON：协议名 -> 分享链接）。
-- 本文件未在任何自动化流程中执行，需要手工在目标 MySQL 实例上运行一次。
-- 依赖 2026110100_wireguard.sql 已先执行（protocols 列由该脚本创建）。
--
-- 为什么用一列 JSON 而不是每个协议一组列：
--   trojan / hysteria2 / vmess / shadowsocks 各自字段不同，逐个加列会让表越来越宽；
--   而分享链接本身已经包含全部连接参数，客户端对它的解析与连接逻辑和「用户自己的节点」完全相同。
--
-- 用法（链接来自服务器上 `bash vpn.sh singbox links` 的输出）：
--
-- UPDATE vpn.host_v2
-- SET protocols  = 'trojan,hysteria2',           -- 纯代理节点：不要写 ikev2，见下方说明
--     proxyLinks = '{"trojan":"trojan://...","hysteria2":"hysteria2://..."}',
--     needPing   = 0                              -- 这些节点不开 ICMP，见 2026110400_node_data_template.sql
-- WHERE id = <host_v2 的行 id>;
--
-- protocols 里可用的名字：trojan, hysteria2, vmess, shadowsocks（与 proxyLinks 的键一致）。
--
-- ⚠️ 客户端只有在节点【不支持 IKEv2】时才会使用 proxyLinks（先试原生 VLESS，再按
--    trojan > vmess > shadowsocks > hysteria2 的顺序取第一个能解析的链接）。
--    protocols 里同时写了 ikev2 的节点，客户端仍按原来的 WireGuard / IKEv2 规则连接，
--    proxyLinks 不会被用到。所以代理协议要放在单独的节点行上，不要和 IKEv2 混写。
--    客户端只取第一个，连接失败不会自动换下一个协议。
-- 链接里的地址和端口就是客户端要连的地址，host_v2.gateway 与它不必相同。
--
-- ⚠️ 链接里含密码，和 vlessUuid 一样会下发给所有登录用户。这与现有 VLESS 节点的风险相同；
--    要做到每个用户独立凭证，需要按用户生成密码并同步到服务器，不在本次范围内。

ALTER TABLE vpn.host_v2
    ADD COLUMN proxyLinks TEXT NULL COMMENT '各协议分享链接，JSON：协议名 -> 链接';
