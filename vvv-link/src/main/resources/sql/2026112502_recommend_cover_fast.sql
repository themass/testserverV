-- 2026112502 列表页封面回填【快速版】——替换 2026112501 的 ③ 段
--
-- 2026112501 慢的根因：③ 用相关子查询 + EXISTS，36 个空封面频道各扫两趟
-- videoitems_1（线上大表）；而线上探针显示这批 ddys 频道在 videoitems_1 里
-- 没有条目行 → 72 趟全表扫描纯空转。连接断开＝语句超时被掐，MySQL 回滚整个
-- 事务，所以数据库没有被改，可以放心重来。
--
-- 正确顺序：先确认有没有 channel 索引（没有就在线加，顺便给线上接口提速）→
-- 再逐频道点查（走索引，毫秒级）→ 最后按主键逐行 UPDATE（每行一个极短事务，
-- 断线也不会回滚掉已改的行）。
--
-- 来源：Android 侧 worktree sql-print/2026112502_recommend_cover_fast.sql（用户实跑踩坑后
-- 由协调会话写就），此处按本线惯例入库；手工执行、不自动跑，生产 MySQL 由用户手跑。

-- ① 有没有索引 / 表多大（先跑这个，只看结果不写数据）
SHOW INDEX FROM vpn.videoitems_1;
SELECT table_name, table_rows, engine
FROM information_schema.tables
WHERE table_schema = 'vpn' AND table_name IN ('videoitems_1', 'videochannel_1');
-- 若 SHOW INDEX 里没有任何以 channel 打头的索引 → 跑 ②；有则直接跳到 ③。

-- ② 在线补索引（InnoDB；INPLACE + LOCK=NONE 不挡读写，只是要跑一会儿）。
-- 这个索引同时给线上「频道列表页」接口提速——items.json 就是按 channel 过滤的。
-- 大表建索引期间别断线：建议在 screen/tmux 里跑，或用客户端后台执行。
-- 注：这是 DDL，属于生产结构变更——按纪律由用户执行，执行前确认表引擎是 InnoDB、
--     且 idx_channel_sort 这个名字不冲突（① 的 SHOW INDEX 已能看到）。
ALTER TABLE vpn.videoitems_1
    ADD INDEX idx_channel_sort (channel, sortType, id),
    ALGORITHM = INPLACE, LOCK = NONE;

-- ③ 备份（照 2026112501 的 ①，很轻，只落空 pic 行）
CREATE TABLE IF NOT EXISTS vpn.videochannel_1_pic_bak_20261125 (
    id      INT PRIMARY KEY,
    channel VARCHAR(200),
    pic     VARCHAR(500)
);
INSERT INTO vpn.videochannel_1_pic_bak_20261125 (id, channel, pic)
SELECT id, channel, COALESCE(pic, '')
FROM vpn.videochannel_1
WHERE enable = 1 AND channelType = 'movie' AND (pic IS NULL OR pic = '');

-- ④ 逐频道点查封面（走 ② 的索引，每频道一次 LIMIT 1；先看结果）
-- 口径与列表页一致：VideoMapper.getChannelItems = order by sortType desc, id desc，
-- 且 channelType='movie' 的条目在列表页查不到，所以不能拿它当封面。
SELECT c.id, c.channel, c.name, COALESCE(c.baseurl, '') AS baseurl,
       (SELECT i.pic
          FROM vpn.videoitems_1 i
         WHERE i.channel = c.channel
           AND (i.channelType IS NULL OR i.channelType != 'movie')
           AND COALESCE(i.pic, '') <> ''
         ORDER BY i.sortType DESC, i.id DESC
         LIMIT 1) AS firstPic
FROM vpn.videochannel_1 c
WHERE c.enable = 1 AND c.channelType = 'movie' AND (c.pic IS NULL OR c.pic = '')
ORDER BY c.id;
-- firstPic 为 NULL 的频道＝该频道确实没有带封面的条目（ddys 系大概率如此），
-- 这些频道跑脚本也不会有封面，属于数据事实，不是脚本漏了。

-- ⑤ 回填（有 ② 的索引后，36 次点查是毫秒级；守卫保证「没有带封面条目」的频道不被改）
-- 绝对 URL 直接用、相对路径拼频道 baseurl。
UPDATE vpn.videochannel_1 c
SET c.pic = CONCAT(
        CASE WHEN (SELECT i.pic FROM vpn.videoitems_1 i
                    WHERE i.channel = c.channel
                      AND (i.channelType IS NULL OR i.channelType != 'movie')
                      AND COALESCE(i.pic, '') <> ''
                    ORDER BY i.sortType DESC, i.id DESC LIMIT 1) LIKE 'http%'
             THEN '' ELSE COALESCE(c.baseurl, '') END,
        (SELECT i.pic FROM vpn.videoitems_1 i
          WHERE i.channel = c.channel
            AND (i.channelType IS NULL OR i.channelType != 'movie')
            AND COALESCE(i.pic, '') <> ''
          ORDER BY i.sortType DESC, i.id DESC LIMIT 1))
WHERE c.enable = 1 AND c.channelType = 'movie' AND (c.pic IS NULL OR c.pic = '')
  AND EXISTS (SELECT 1 FROM vpn.videoitems_1 i
               WHERE i.channel = c.channel AND COALESCE(i.pic, '') <> '' LIMIT 1);
-- 守卫必须带 COALESCE(i.pic,'') <> ''：只查「有没有条目」的话，
-- 「有条目但全没封面」的频道会把 pic 从 '' 写成 NULL（语义仍空，但白改一行、
-- 且备份回滚后原值是 ''）。带上后走索引 channel 前缀，代价仍是毫秒级。
--
-- 想更保守就按主键逐行跑：把最后一行换成 `AND c.id = <④里 firstPic 非空的 c.id>`，
-- 一条一个极短事务，中途断线也不会回滚掉已改的行。

-- ⑥ 验证
SELECT COUNT(*) AS stillEmpty FROM vpn.videochannel_1
WHERE enable = 1 AND channelType = 'movie' AND (pic IS NULL OR pic = '');
SELECT id, channel, pic FROM vpn.videochannel_1
WHERE enable = 1 AND channelType = 'movie' AND pic <> '' ORDER BY id DESC LIMIT 10;
-- 接口侧：GET /vvv/api/video/channel.json?channel=movie 应看到回填的行出图。

-- 回滚（照 2026112501）
UPDATE vpn.videochannel_1 c
JOIN vpn.videochannel_1_pic_bak_20261125 b ON b.id = c.id
SET c.pic = NULLIF(b.pic, '');
-- ② 加的索引不用删：它是线上接口本来就该有的。
