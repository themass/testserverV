-- ============================================================
-- 节点数据填写模板
-- ============================================================
-- 用法：
--   1. 把下面所有 <尖括号> 占位符替换成真实值
--   2. 先跑「第 0 段」看清现有数据，再决定走「新增」还是「修改」
--   3. 执行完跑「第 4 段」自查，全部字段都有值才算填对
--
-- ⚠️ 本模板只引用 host_v2 上「确定存在」的列：
--     id / hostId / gateway / port / weight / enable / showName /
--     protocols / peerPublicKey / clientAddress / dns / mtu /
--     wireGuardPort / vless* / reality*
--
--    刻意不引用 type 列：生产库的 host_v2 实际没有 type，
--    而代码里的 HostPo.type 只是历史遗留字段（未映射到列时默认 0），
--    不参与业务判定。真正的 VIP 门槛看 location_v2.type。
--
--    如果你要新增的库表结构与我假设的不同，请先跑
--    SHOW CREATE TABLE vpn.host_v2\G 确认列名，再调整本文件。
-- ⚠️ 本模板依据生产库真实结构（2026-11-02 SHOW CREATE TABLE 核对）：
--    host_v2 没有 type 列（HostPo.type 是未映射的历史遗留字段，恒为 0）；
--    有 com / cname / lname / cert / traffic / pay / money 这些必填展示列，
--    新增网关时若不写会因 NOT NULL 无默认值而报错。
--    location_v2 的 category 允许 NULL 但代码里没判空，填 NULL 会让整个
--    节点接口 500 —— 新增地区必须显式给 category。
-- ============================================================


-- ============================================================
-- 第 0 段：先看现状（只读，安全）
-- ============================================================

-- 0.1 现有地区列表。id 就是客户端请求时用的 location 参数值
SELECT id, hostId, name, ename, type, enable, channel, category
FROM vpn.location_v2
ORDER BY id;

-- 0.2 现有网关列表。确认 hostId 和你想改的行
SELECT id, hostId, gateway, port, weight, enable, showName,
       protocols, peerPublicKey, clientAddress, dns, mtu, needPing
FROM vpn.host_v2
ORDER BY hostId, id;


-- ============================================================
-- 第 1 段：只支持 IKEv2 的节点（最省事，什么都不用加）
-- ============================================================
-- 这类节点你不需要动 host_v2 的任何新字段。
-- protocols 留 NULL 或空串，客户端自动按「仅 ikev2」处理。
--
-- 如果你要新增一个纯 IKEv2 节点：
--
-- INSERT INTO vpn.host_v2
--     (hostId, gateway, port, showName, enable, com, cname, cert, weight, needPing)
-- VALUES
--     (<地区id>, '<网关地址或域名>', 500, '<展示名>', 1,
--      '<运营商，可填空串>', '<中文名>', '<证书名，可填空串>', 1, 1);
--
-- ⚠️ com / cname / cert 是 NOT NULL 且没有默认值，漏写会直接报错 1364。
--
-- 注意：gateway 必须是客户端能直接连通的公网地址。
-- 后端有个 HostCheck 定时任务会 ping 所有网关，ping 不通的会被临时
-- 排除出下发列表（日志里会有「异常的服务器」）。
-- 节点若禁 ICMP，见第 2 段末尾的 needPing 说明。


-- ============================================================
-- 第 2 段：加 WireGuard 支持
-- ============================================================
-- 你需要先在服务器上把 WireGuard 跑起来，然后取到服务端公钥：
--
--   # 服务器上，假设配置在 /etc/wireguard/wg0.conf
--   sudo wg show wg0 public-key
--   # 或者从私钥推导：
--   sudo cat /etc/wireguard/privatekey | wg pubkey
--
-- 然后填到对应节点上：
--
-- UPDATE vpn.host_v2
-- SET protocols     = 'ikev2,wireguard',
--     peerPublicKey = '<服务端公钥，44 字符 Base64，等号结尾>',
--     clientAddress = '<分配给客户端的隧道内地址，如 10.8.0.5/32>',
--     dns           = '1.1.1.1',
--     mtu           = 1420,
--     wireGuardPort = 51820,         -- WireGuard 监听端口
--     needPing      = 0              -- 见下方说明，多数情况要设 0
-- WHERE id = <host_v2 的行 id>;
--
-- ✅ 端口已拆开：`port` 继续表示 IKEv2 端口（500/4500），
--    WireGuard 用独立的 `wireGuardPort` 列（2026110500_wireguard_port.sql 加入）。
--    该列留 NULL 时客户端回退到 port，再回退到 51820，所以老数据不用回填。
--
-- ⚠️ needPing 必须关注（最容易误判「接口坏了」）：
--    后端 HostCheck 定时任务会 ping 所有 enable=1 的网关，
--    连续两次不通就临时从下发列表剔除，客户端只会看到
--    "change another route"，看起来像接口报错，实际是节点被判定不可达。
--    WireGuard/VLESS 节点通常只监听 UDP/TCP、不开 ICMP，
--    所以这类节点一律设 needPing=0 跳过检测：
--
--      UPDATE vpn.host_v2 SET needPing = 0 WHERE id = <节点id>;
--
--    （若你的库没有 needPing 列，先 SHOW COLUMNS 确认；
--      没有该列时代码里 HostPo.needPing 默认值为 1，即仍会检测。）
--
-- ⚠️ clientAddress 的坑（最常见的「握手成功但没流量」）：
--    这里填的地址必须和服务端 [Peer] 段里该客户端的 AllowedIPs 完全一致。
--    但客户端公钥是每台设备连上来时才注册的（见第 3 段），
--    所以你没法在数据库里预先知道。
--    正确做法：服务端用「同网段 AllowedIPs」下发，
--    例如 AllowedIPs = 10.8.0.0/24，客户端统一分配 /32 地址。
--    这样所有客户端共享一个网段，服务端不用按设备改配置。


-- ============================================================
-- 第 3 段：加 VLESS+Reality 支持
-- ============================================================
-- 你说已经有稳定的 Reality 服务器了。参数从服务端 Xray 配置里取：
--
--   服务端 config.json 里：
--     inbounds[].settings.clients[].id          → vlessUuid
--     inbounds[].settings.clients[].flow        → vlessFlow
--     inbounds[].streamSettings.realitySettings.serverNames[0] → realityServerName
--     inbounds[].streamSettings.realitySettings.shortIds[0]   → realityShortId
--     inbounds[].streamSettings.realitySettings.privateKey     → 这是私钥，别填！
--
--   公钥要单独算（服务器上执行）：
--     xray x25519 -i <你的 privateKey>
--     # 输出里的 "Public key: xxxxx" 就是 realityPublicKey
--
--   或者更简单——如果你手上有现成的 vless:// 分享链接，
--   里面的参数直接对应：
--     vless://<uuid>@<host>:<port>?security=reality&sni=<serverName>
--           &pbk=<publicKey>&sid=<shortId>&flow=<flow>&fp=<fingerprint>#备注
--
-- UPDATE vpn.host_v2
-- SET protocols          = 'ikev2,wireguard,vless-reality',
--     vlessUuid          = '<uuid，形如 xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx>',
--     vlessFlow          = 'xtls-rprx-vision',
--     realityServerName  = '<借用的真实域名，如 www.microsoft.com>',
--     realityPublicKey   = '<Reality 公钥，Base64>',
--     realityShortId     = '<shortId，通常 8~16 位 hex，可能为空串>',
--     realityFingerprint = 'chrome',
--     port               = 443,
--     needPing           = 0
-- WHERE id = <host_v2 的行 id>;
--
-- ⚠️ Reality 的 gate 是「参数齐不齐」，客户端 HostVo.isVlessRealityReady()
--    要求 vlessUuid / realityPublicKey / realityServerName 三个都非空。
--    缺任何一个，该节点不会被当作 VLESS 候选，会静默回退 IKEv2。
--    （刻意设计的降级行为，不报错，所以填错很容易被忽略。）
--
-- ⚠️ VLESS 与 WireGuard 共用同一个 port 语义冲突问题：
--    Reality 用 TCP 443，WireGuard 用 UDP 51820，IKEv2 用 UDP 500。
--    port 列表示「主端口」（IKEv2/VLESS），wireGuardPort 单独给 WireGuard。
--    若同一节点既要 Reality(443) 又要 IKEv2(500)，就无法共用——此时
--    建议拆成两个 host_v2 行（各自 protocols 不同），或单独跟我说要再加列。


-- ============================================================
-- 第 4 段：填完自查（重要，别跳过）
-- ============================================================

-- 4.1 声明支持 WireGuard 但参数不全的节点 —— 结果应该为空
SELECT id, hostId, gateway, protocols, peerPublicKey, clientAddress
FROM vpn.host_v2
WHERE enable = 1
  AND protocols LIKE '%wireguard%'
  AND (peerPublicKey IS NULL OR peerPublicKey = ''
       OR clientAddress IS NULL OR clientAddress = '');
-- 有结果说明这些节点会被客户端降级成 IKEv2，WireGuard 不生效

-- 4.2 声明支持 VLESS 但参数不全的节点 —— 结果应该为空
SELECT id, hostId, gateway, protocols,
       vlessUuid, realityServerName, realityPublicKey
FROM vpn.host_v2
WHERE enable = 1
  AND protocols LIKE '%vless%'
  AND (vlessUuid IS NULL OR vlessUuid = ''
       OR realityServerName IS NULL OR realityServerName = ''
       OR realityPublicKey IS NULL OR realityPublicKey = '');
-- 同上，有结果说明 VLESS 不会生效

-- 4.3 检查外键关联是否断掉 —— 结果应该为空
SELECT h.id, h.hostId, h.gateway
FROM vpn.host_v2 h
LEFT JOIN vpn.location_v2 l ON l.hostId = h.hostId AND l.enable = 1
WHERE h.enable = 1 AND l.id IS NULL;
-- 有结果说明这些网关挂在一个没有启用地区下面，客户端永远看不到它

-- 4.4 最终确认：模拟客户端实际会拿到什么
SELECT l.id AS locationId, l.name AS locationName, l.type AS locationType,
       h.gateway, h.port, h.protocols, h.mtu
FROM vpn.location_v2 l
JOIN vpn.host_v2 h ON h.hostId = l.hostId AND h.enable = 1
WHERE l.enable = 1 AND l.channel = 'VPN'
ORDER BY l.id, h.id;
-- 这份结果就是客户端能看到的全部节点。
-- 注意 channel='VPN' 这个过滤条件——如果地区表里 channel 填的是别的值
-- （VPNB/VPND），这里查不出来，客户端也看不到。
