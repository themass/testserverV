# 迁移脚本与执行顺序

**真库即线上库**（本机 bootstrap-local/prod.yml 里的同一条 datasource.url，连接串不入库；无建库权限）。

> **2026-11-22 执行记录**：V001/V002 已在线上库 `vpn` 执行，9 张 `game_*` 表落地，schema_version 记到 2，
> `game_season` 种入首季行（season_no=1）。真库实测 `SELECT VERSION()` = **MySQL 8.0.46**——
> 本文档与 data-model.md 里"5.6.40"的说法源自 TS 项目旧情报，已过时；SQL 仍刻意只用 5.6 子集写法（前向兼容，8.0 一次通过）。
> 紧急回退：`recovery/drop_game_objects.sql`（只 DROP `game_*`）。

```
vvv-game/src/main/resources/db/game/
  V001__core.sql               # 7 张表 + schema_version（见 data-model.md）
  V002__shots.sql              # game_shot（回放/反作弊，可后补）
  audit_integrity_checks.sql   # 断言集，应全 0：余额=流水和、孤儿流水、未闭合对局等
  recovery/drop_game_objects.sql  # 紧急回退：DROP 全部 game_* 表（只删 game_ 前缀）
```

执行（一条一条，禁 `--force`）：

```bash
mysql --default-character-set=utf8mb4 < V001__core.sql
mysql --default-character-set=utf8mb4 < V002__shots.sql
mysql --default-character-set=utf8mb4 -N -B < audit_integrity_checks.sql | awk -F'\t' '$2!=0'   # 应无输出
```

规则照抄 poetry / student：DDL 非事务，逐语句执行；每步前后 `SELECT version_no FROM game_schema_version`
核对；迁移脚本永不 `USE`，只碰 `game_*` 前缀。

## 赛季任务（无窗口函数时代的做法）

- 赛季边界：`SEASON_EPOCH_MS = Date.UTC(2026,10,23)`，4 周一季——常量直译 TS `rank.ts`，
  首行由运维 INSERT 进 `game_season`。
- 到期发奖 + 重置：**单线程定时任务**（宿主 `@Scheduled`，多实例用 `game:lock:season:{n}` 抢锁），
  按 `season_no` 分批 UPDATE `game_progress`（LIMIT 500 循环），`granted_at/reset_at` 记录进度可断点续跑。
- 重置逻辑 = TS `resetSeason` 直译：降 1 级满星（元帅→准将满星；列兵原样），MMR 保留，连败清零。
