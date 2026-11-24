-- 外键全量盘点（只读）。项目规则：库内不允许外键（MySQL 5.6 口径，poetry V001 头注同款约定）。
-- 仓库侧 2026-11-24 静态盘点结论：vvv-link / vvv-student / vvv-game / poetry 的全部 DDL 迁移
-- 都不含 FOREIGN KEY 子句；历史上唯一存在过外键的是 poetry 早期库，已由
-- vvv-poetry/src/main/resources/db/poetry/recovery/repair_poetry_drop_foreign_keys.sql 清理。
-- 本文件用来在线上实证「还剩几个」，任何一行输出都是违规，需要照 repair 脚本的样式 DROP。

-- ① 全库（不限 vpn）外键清单：表名、约束名、引用目标
SELECT k.TABLE_SCHEMA, k.TABLE_NAME, k.CONSTRAINT_NAME,
       k.COLUMN_NAME, k.REFERENCED_TABLE_SCHEMA, k.REFERENCED_TABLE_NAME, k.REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE k
WHERE k.CONSTRAINT_TYPE = 'FOREIGN KEY'
ORDER BY k.TABLE_SCHEMA, k.TABLE_NAME, k.CONSTRAINT_NAME;

-- ② 按库计数（快查）
SELECT TABLE_SCHEMA, COUNT(*) AS fk_count
FROM information_schema.TABLE_CONSTRAINTS
WHERE CONSTRAINT_TYPE = 'FOREIGN KEY'
GROUP BY TABLE_SCHEMA;

-- ③ 逐表生成 DROP 语句（复制输出手跑；DROP FOREIGN KEY 不删索引、不动数据）
SELECT CONCAT('ALTER TABLE `', k.TABLE_SCHEMA, '`.`', k.TABLE_NAME,
              '` DROP FOREIGN KEY `', k.CONSTRAINT_NAME, '`;') AS drop_stmt
FROM information_schema.KEY_COLUMN_USAGE k
WHERE k.CONSTRAINT_TYPE = 'FOREIGN KEY'
GROUP BY k.TABLE_SCHEMA, k.TABLE_NAME, k.CONSTRAINT_NAME;
