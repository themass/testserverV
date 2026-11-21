-- 通用弹幕：一条弹幕挂在一段时间轴上（namespace/contentId/editionId 三元组定位媒资轴）。
-- 本文件未在任何自动化流程中执行，需要手工在目标 MySQL 实例上运行一次。
-- 列命名延续本库约定：MyBatis 未开启 mapUnderscoreToCamelCase，列名就是驼峰的 Java 属性名。
-- 幂等：clientMsgId 由客户端生成、重试复用，同一用户在同一时间轴上重发只落一条（见 UNIQUE KEY），
--   与 chat_message.clientMsgId 的先例一致。
-- 撤回是软删（deleted=1），另一端刷新窗口时自然不再出现，不需要推送通道。

CREATE TABLE IF NOT EXISTS vpn.danmaku_comment (
    id          BIGINT       NOT NULL AUTO_INCREMENT,
    namespace   VARCHAR(32)  NOT NULL COMMENT '时间轴命名空间，如 local',
    contentId   VARCHAR(128) NOT NULL COMMENT '媒资稳定 id（客户端 key，服务端校验 path 段安全字符）',
    editionId   VARCHAR(32)  NOT NULL DEFAULT 'v1' COMMENT '同一媒资的轴版本，如 v1',
    atMs        BIGINT       NOT NULL COMMENT '弹幕锚点：媒资播放时钟毫秒',
    content     VARCHAR(300) NOT NULL COMMENT '弹幕文本（应用层限 100 码点，utf8mb4 留足字节）',
    userId      BIGINT       NOT NULL COMMENT '发送者 vpn.user.id',
    authorName  VARCHAR(64)  NOT NULL DEFAULT '' COMMENT '发送者昵称快照，渲染不回查用户表',
    clientMsgId VARCHAR(128) NOT NULL COMMENT '客户端幂等 id，重试复用，服务端据此去重',
    deleted     TINYINT      NOT NULL DEFAULT 0 COMMENT '1=作者已撤回，窗口查询不再下发',
    createTime  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_danmaku_comment_idem (namespace, contentId, editionId, userId, clientMsgId),
    KEY idx_danmaku_comment_window (namespace, contentId, editionId, atMs, id),
    KEY idx_danmaku_comment_user_time (userId, createTime)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '通用弹幕';
