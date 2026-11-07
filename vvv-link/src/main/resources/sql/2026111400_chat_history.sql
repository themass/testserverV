-- 对话历史改由服务端持有：会话表 + 消息表。
-- 本文件未在任何自动化流程中执行，需要手工在目标 MySQL 实例上运行一次。
-- 不迁移旧 Redis 数据 chat_record_{userId}（老数据直接放弃）。
-- 列命名延续本库约定：MyBatis 未开启 mapUnderscoreToCamelCase，列名就是驼峰的 Java 属性名。

CREATE TABLE IF NOT EXISTS vpn.chat_session (
    id          BIGINT       NOT NULL AUTO_INCREMENT,
    userId      BIGINT       NOT NULL,
    name        VARCHAR(128) NOT NULL,
    characterId INT          NULL COMMENT '会话人设：setting_character.id',
    roleId      VARCHAR(128) NULL COMMENT '会话人设：角色目录里的角色 id',
    createdAt   DATETIME     NOT NULL,
    updatedAt   DATETIME     NOT NULL,
    deleted     TINYINT      NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    KEY idx_chat_session_user (userId, deleted, updatedAt)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '对话会话';

CREATE TABLE IF NOT EXISTS vpn.chat_message (
    id          BIGINT      NOT NULL AUTO_INCREMENT,
    sessionId   BIGINT      NOT NULL,
    userId      BIGINT      NOT NULL,
    `role`      VARCHAR(16) NOT NULL COMMENT 'user / assistant',
    content     MEDIUMTEXT  NOT NULL,
    `type`      INT         NOT NULL DEFAULT 0 COMMENT '0 文本 1 语音 2 图片 3 视频 4 文件，与客户端 MessageType 一致',
    clientMsgId VARCHAR(64) NULL COMMENT '客户端为用户消息生成的 id，同会话内重发时用于幂等',
    createdAt   DATETIME    NOT NULL,
    deleted     TINYINT     NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    KEY idx_chat_message_session (sessionId, deleted, id),
    KEY idx_chat_message_client (sessionId, clientMsgId)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '对话消息';
