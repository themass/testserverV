# 底座 · 应用 · Agent 架构

正式图：`architecture.html`（浏览器直接打开，含读路径 / 写路径 / 自检与守护 三个视角）。
可编辑源：`architecture.json`。

## 图的文字版

```
读路径（学生能看到的一切）
  学生 → 应用层 → 只读 API(/api/poetry/v1) → 内容底座
                                              ↑
                                        发布闸门（人审 + 来源已核查 + 演绎已标识）
                                              ↑
                                        录入与复核 ← 草稿区 ← Agent（未来）
                                              
运维旁路：核查 SQL（106 项）→ 底座：改数据后必须全 0
Agent 另有一条只读边：可读底座作上下文，不可写库

自检与守护（第三个视角）
  只读 API  ← 访问日志 + 每客户端限流（PoetryAccessGuard，进程内）
  自检（PoetrySelfCheck） -.探活.-> 底座        （表不存在 / schema 版本过旧 → 告警，不改数据）
  自检 -.词表比对.-> 核查 SQL                  （Vocabulary.java 与 C7 词表漂移 → 告警）
```

## 三条边界（与图对应）

| 边界 | 含义 | 现在靠什么保证 |
|---|---|---|
| 读边界 | 只有满足发布闸门的内容能被读到；草稿、未核查来源、未标识演绎一律不可见 | `PoetrySql` 每条 SELECT 复查（fail closed，已实测） |
| 写边界 | 人工与 Agent 一律先产 DRAFT，发布必须过人审 + 106 项核查 | 约定 + `audit_integrity_checks.sql`（**尚无代码强制**，见 `code-layers.md` 第 1、7 项） |
| Agent 边界 | Agent 可读不可写；产出必须标注 `DRAMATIZATION` 或 `INTERPRETATION`，不得伪装史实 | 目前只是设计约定，未实现 |

## 为什么 Agent 不能直接写库

产品的核心资产是"有依据的内容"。Agent 一旦直接写入已发布内容，就会出现：无出处的史实、把演绎当事实、把一般时代背景当作确定创作动机。这三条正是项目明确的反目标。因此 Agent 的正确位置是**草稿生产者**，人审是它进入底座的唯一通道。

## 这张图对应到代码（2026-11-06 现状）

| 图中节点 | 现在是什么 | 状态 |
|---|---|---|
| 内容底座 | `db/poetry/V001` + `V003`（26 张表，无外键） | 已在 H2 跑通，未在真 MySQL 执行 |
| 草稿区 | `V002` + `V004`（《春望》最小闭环，全 DRAFT） | 已在库，接口读不到（已实测 SQL 层） |
| 发布闸门 | `PoetrySql` 读侧复查 + `review-checklist.md` 人工步骤 | 读侧强制；写侧仍是人 + SQL |
| 核查 SQL | `audit_integrity_checks.sql` 106 项 | 已实测（草稿全 0；演练库 5 项非 0） |
| 自检与词表 | `PoetrySelfCheck` + `Vocabulary` | 已实现（fail-soft，只告警） |
| 限流与日志 | `PoetryAccessGuard` | 已实现（单实例，非分布式） |
| Agent | 无代码 | 明确未实现；底座已为它留出草稿区与 claim 词表 |
