-- 多角色/自定义人设：setting_character 表加归属字段，支持用户上传自己的角色。
-- 本文件未在任何自动化流程中执行，需要手工在目标 MySQL 实例上运行一次。
-- 字段命名延续本库既有约定：MyBatis 未开启 mapUnderscoreToCamelCase，
-- 列名直接按 Java 属性名用驼峰命名。

ALTER TABLE vpn.setting_character
    ADD COLUMN ownerUserId BIGINT   NULL COMMENT '角色所有者用户 id；NULL 表示官方内置角色，所有用户可见',
    ADD COLUMN createdAt   DATETIME NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间，官方角色可为 NULL（历史数据）';
