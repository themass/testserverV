-- 声音馆歌词：一份离线 ASR 生成的 SRT 挂在一条声音条目上（契约 docs/design/sound-lyrics-contract-20261124.md §2 Phase 1）。
-- 本文件未在任何自动化流程中执行，需要手工在目标 MySQL 实例上运行一次（开发/测试库先行，生产由运维手跑）。
-- soundItemId 指向 vpn.sounditems.id，本表只存引用，不建外键（同库也不建——沿用 video_subtitle 的口径）。
-- 列命名延续本库约定：MyBatis 未开启 mapUnderscoreToCamelCase，列名就是驼峰的 Java 属性名。
-- content 只在 /api/sound/subtitle/item.json 单条查询里下发，列表查询不取这一列，见 SoundSubtitleMapper.xml。
-- 回滚：DROP TABLE IF EXISTS vpn.sound_subtitle;

CREATE TABLE IF NOT EXISTS vpn.sound_subtitle (
    id             INT          NOT NULL AUTO_INCREMENT,
    soundItemId    INT          NOT NULL COMMENT ' vpn.sounditems.id ',
    title          VARCHAR(200) NOT NULL DEFAULT '' COMMENT '歌词名，如条目标题',
    lang           VARCHAR(10)  NOT NULL DEFAULT 'zh' COMMENT '语言标记，如 zh / en',
    format         VARCHAR(10)  NOT NULL DEFAULT 'srt' COMMENT 'MVP 只产 srt',
    content        MEDIUMTEXT   NOT NULL COMMENT '整份 SRT 正文，JSON 信封下发（客户端 AES 链路只覆盖 JsonResult）',
    sourceFileHash CHAR(64)     NOT NULL COMMENT '生成时音频 URL 的 SHA-256：换文件自动失效',
    genStatus      VARCHAR(10)  NOT NULL DEFAULT 'ready' COMMENT 'pending / running / ready / failed；failed 可重试',
    engine         VARCHAR(40)  NOT NULL DEFAULT '' COMMENT '生成引擎标记，如 deepgram:nova-2-general',
    enabled        TINYINT      NOT NULL DEFAULT 1,
    createTime     BIGINT       NOT NULL COMMENT 'epoch 毫秒',
    PRIMARY KEY (id),
    UNIQUE KEY uniq_sound_item (soundItemId)  -- MVP 一条目一轨；多语言时改 (soundItemId,lang)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '声音馆歌词（离线 ASR 生成，永久缓存）';
