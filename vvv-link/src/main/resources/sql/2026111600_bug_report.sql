-- 「上报问题」：用户在设置页主动同意后上传的诊断日志（见客户端的 ReportIssueDialog）。
-- 本文件未在任何自动化流程中执行，需要手工在目标 MySQL 实例上运行一次。
-- 列命名延续本库约定：MyBatis 未开启 mapUnderscoreToCamelCase，列名就是驼峰的 Java 属性名。
--
-- 为什么不放对象存储：OssServiceImpl 的上传是 @Async 且异常被吞，调用方拿不到成功与否，
-- 而这条链路必须能如实告诉客户端"存下来了没有"。日志有 512KB 上限、只有用户主动点上报才会写，
-- 量很小，直接入库最简单也最可靠（chat_message 存正文用的也是 MEDIUMTEXT）。

CREATE TABLE IF NOT EXISTS vpn.bug_report (
    id         BIGINT      NOT NULL AUTO_INCREMENT,
    userId     BIGINT      NULL COMMENT '提交时的登录用户，未登录为 NULL',
    devId      VARCHAR(64) NULL COMMENT '设备 id',
    userIp     VARCHAR(64) NULL COMMENT '上报时的客户端出口 IP（服务端取）',
    version    VARCHAR(32) NULL COMMENT 'App 版本号',
    label      VARCHAR(128) NULL COMMENT '用户填的问题描述，可空',
    fileName   VARCHAR(128) NULL COMMENT '原始文件名',
    fileBytes  INT         NOT NULL DEFAULT 0 COMMENT '原始字节数',
    content    MEDIUMTEXT  NULL COMMENT '日志正文；超过上限时只保留最近的尾部',
    truncated  TINYINT     NOT NULL DEFAULT 0 COMMENT '是否因超长被截断',
    createdAt  DATETIME    NOT NULL,
    PRIMARY KEY (id),
    KEY idx_bug_report_time (createdAt),
    KEY idx_bug_report_user (userId, createdAt)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '用户主动上报的问题与诊断日志';
