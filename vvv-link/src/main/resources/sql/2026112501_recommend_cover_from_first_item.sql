-- 2026112501 列表页频道卡缺封面 → 回填该频道第一部电影的封面（手工执行，生产 MySQL 由用户跑）
--
-- 【已取代】③ 的相关子查询+EXISTS 在生产实跑超时被掐（断连＝整事务回滚，库未被改）。
--   执行改用 2026112502_recommend_cover_fast.sql（先建 channel 索引再回填）。
--   本文件保留作口径说明与备份/回滚结构参考；②③ 的过滤口径已按 2026-11-25 二次校对改正
--   （见下「第一部」段——此前写成 != 'movie' 是方向反了，勿照旧版执行）。
--
-- 【重要更正】「列表页」(recommend/movie.json, dataType=5) 的频道卡并不在 vpn.recommend：
--   DataServiceImpl.getRecommendMoviePage → DataVideoServiceImpl.getVideoChannel
--   → VpnRecommandMapper 无关，走 VideoMapper.getChannel：
--     select * from vpn.videochannel_1 where enable=1 and channelType='movie' group by channel order by id desc
--   VO.img = videochannel_1.pic。所以本脚本改 vpn.videochannel_1.pic，不动 vpn.recommend。
--   探针证据（2026-11-25，GET /vvv/api/video/channel.json?channel=movie）：
--   52 行、36 行 img 空（id=122346「其他」param=ddys其他 等 ddys 系）；
--   非空 pic 一律是绝对 URL（如 https://i2.xiaoyakankan.com/9/d0/0mc7.jpg），
--   卡片 pic 服务端直接透传不拼接，所以写入必须是绝对 URL。
--
-- 「第一部」= 频道列表页真实口径（2026-11-25 二次校对，VideoMapper.getChannelItems 是 choose/when）：
--   app 点电影频道卡进列表页 → getOneChannel 命中 videochannel_1 行（channelType='movie'）
--   → 走 when 分支：WHERE channelType='movie' AND channel=? ORDER BY sortType DESC, id DESC。
--   `channelType != 'movie'` 只是频道行查不到时的 otherwise 兜底，不是列表页主路径。
--   （2026-11-22 探针 movie-channel-data-analysis：ddys动作 的 875 条全是 channelType='movie'。）
--   所以取每组 channel 内 channelType='movie'、pic 非空、sortType desc, id desc 的第一条。
--   相对 pic 拼【条目自己的 baseurl】（列表行 VO 的 baseurl 来自 videoitems_1.baseurl），不是频道表的。
--
-- 执行顺序：① 备份表 ② 预览将被改的行 ③ UPDATE ④ 验证。出问题跑最后的回滚段。
--
-- 【风险须先库内核实】线上探针（2026-11-25）里 36 个 ddys 空封面频道中预计只有
--   ddys动作 有条目行（875 条），其余为 0——没条目的频道跑脚本也不会回填（EXISTS 守卫跳过）。
--   执行前先在目标库跑：
--     SELECT channel, COUNT(*) FROM vpn.videoitems_1
--     WHERE channel IN (SELECT channel FROM vpn.videochannel_1
--                       WHERE enable=1 AND channelType='movie' AND (pic IS NULL OR pic=''))
--     GROUP BY channel;
--   （注意 videoitems_1 与 videochannel_1 不保证同库，先例见 2026112100_video_subtitle.sql 注释。）

-- ① 备份（把当前全部空 pic 行落表，回滚就靠它）
CREATE TABLE IF NOT EXISTS vpn.videochannel_1_pic_bak_20261125 (
    id    INT PRIMARY KEY,
    channel VARCHAR(200),
    pic   VARCHAR(500)
);
INSERT INTO vpn.videochannel_1_pic_bak_20261125 (id, channel, pic)
SELECT id, channel, COALESCE(pic, '')
FROM vpn.videochannel_1
WHERE enable = 1 AND channelType = 'movie' AND (pic IS NULL OR pic = '');

-- ② 预览将被改的行与将要写入的封面（先跑这个肉眼确认，再 ③）
SELECT c.id, c.channel, c.name, COALESCE(c.pic,'') AS oldPic,
       (SELECT CASE WHEN i.pic LIKE 'http%' THEN i.pic
                    ELSE CONCAT(COALESCE(i.baseurl,''), i.pic) END
          FROM vpn.videoitems_1 i
         WHERE i.channel = c.channel
           AND i.channelType = 'movie'
           AND COALESCE(i.pic, '') <> ''
         ORDER BY i.sortType DESC, i.id DESC
         LIMIT 1) AS newPic
FROM vpn.videochannel_1 c
WHERE c.enable = 1 AND c.channelType = 'movie' AND (c.pic IS NULL OR c.pic = '')
ORDER BY c.id;

-- ③ 回填：空 pic ← 该频道列表页第一部有封面条目的 pic（相对路径拼条目自己的 baseurl）
-- 慢且已被 2026112502 取代——保留仅供口径参考，别在生产跑这段。
UPDATE vpn.videochannel_1 c
SET c.pic = (
    SELECT CASE WHEN i.pic LIKE 'http%' THEN i.pic
                ELSE CONCAT(COALESCE(i.baseurl,''), i.pic) END
    FROM vpn.videoitems_1 i
    WHERE i.channel = c.channel
      AND i.channelType = 'movie'
      AND COALESCE(i.pic, '') <> ''
    ORDER BY i.sortType DESC, i.id DESC
    LIMIT 1
)
WHERE c.enable = 1 AND c.channelType = 'movie' AND (c.pic IS NULL OR c.pic = '')
  AND EXISTS (
    SELECT 1 FROM vpn.videoitems_1 i
    WHERE i.channel = c.channel
      AND i.channelType = 'movie'
      AND COALESCE(i.pic, '') <> ''
  );

-- ④ 验证：空 pic 应只剩「该频道没有任何带封面条目」的行
SELECT COUNT(*) AS stillEmpty FROM vpn.videochannel_1
WHERE enable = 1 AND channelType = 'movie' AND (pic IS NULL OR pic = '');
-- 接口侧：GET /vvv/api/video/channel.json?channel=movie（同 recommend/movie.json）应看到回填行出图。

-- 回滚（按备份表逐行恢复，含把 NULL 恢复成 NULL）
UPDATE vpn.videochannel_1 c
JOIN vpn.videochannel_1_pic_bak_20261125 b ON b.id = c.id
SET c.pic = NULLIF(b.pic, '');
