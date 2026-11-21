# 唐诗产品数据库规则：poetry_* 表**永不使用外键**

本文件（drop 件）就是终态，**没有也不该有「重建外键」的回滚件**。
数据库设计规则（用户 2026-11-22 重申）：poetry_* 表不允许存在外键。

- 历史：远端库（mysql.sspacee.com:6666/vpn）的 poetry_* 表建于 11-06 初版，
  当时 schema 带 42 条外键；V002 起的迁移头注释明文「刻意没有外键」（MySQL 5.6
  备份/恢复约束下的既定设计）。V022 首次在真库执行即触发 ERROR 1452 外键约束失败
  ——库与迁移文件的 schema 漂移。
- 处置：`repair_poetry_drop_foreign_keys.sql` 按迁移设计删除全部残留外键
  （DROP FOREIGN KEY 不删索引、不动数据）。2026-11-22 01:3x 已在目标库执行，
  执行后复核残留外键 = 0。
- **今后任何人（含 AI）给 poetry_* 表加外键都是违规**：文件层完整性由
  audit-migrations.py 把关（引用先于定义、(表,id) 对账），不需要库层约束。

## 验证命令

```bash
source content-agent/pipeline/tools/scene-validator/db-conn.sh
q "SELECT COUNT(*) FROM information_schema.KEY_COLUMN_USAGE
   WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME LIKE 'poetry%'
     AND REFERENCED_TABLE_NAME IS NOT NULL"   # 必须恒为 0
```
