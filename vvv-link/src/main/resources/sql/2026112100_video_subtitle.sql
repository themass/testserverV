-- 视频字幕：一份 SRT/VTT 文本挂在一条视频上。
-- 本文件未在任何自动化流程中执行，需要手工在目标 MySQL 实例上运行一次。
-- videoId 指向生产库遗留表 vpn.videoitems_1.id，本表只存引用，不建外键（两张表不同机器上不保证同库）。
-- 列命名延续本库约定：MyBatis 未开启 mapUnderscoreToCamelCase，列名就是驼峰的 Java 属性名。
-- content 只在 /api/video/subtitle/item.json 单条查询里下发，列表查询不取这一列，见 SubtitleMapper.xml。

CREATE TABLE IF NOT EXISTS vpn.video_subtitle (
    id         BIGINT       NOT NULL AUTO_INCREMENT,
    videoId    BIGINT       NOT NULL COMMENT ' vpn.videoitems_1.id ',
    title      VARCHAR(255) NOT NULL DEFAULT '' COMMENT '字幕名，如「简体中文」',
    lang       VARCHAR(16)  NOT NULL DEFAULT '' COMMENT '语言标记，如 zh / en',
    format     VARCHAR(16)  NOT NULL DEFAULT 'srt' COMMENT 'srt / vtt',
    size       BIGINT       NOT NULL DEFAULT 0 COMMENT 'content 字节数，供客户端估算下载量',
    content    MEDIUMTEXT   NOT NULL COMMENT '整份字幕文本，JSON 信封下发（客户端 AES 链路只覆盖 JsonResult）',
    enabled    TINYINT      NOT NULL DEFAULT 1,
    createTime TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updateTime TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_video_subtitle_video (videoId, enabled, id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '视频字幕';
