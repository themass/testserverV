# 部署交接（2026-11-22 收口）

本轮改动全部本地验证完毕，剩两步需要服务器权限的操作（jar 替换 + H5 上传）。照单执行即可。

## 1. 后端 jar（必做——capacity 字段和 game_shot 落表都等它）

线上 jar 早于两处改动：**matches/recent 的 capacity 字段**（缺它档案页显示"对决undefined人"→"对决2人"）与 **game_shot 逐发落表**。

```bash
# 本地产物：/Users/gqli/work/testserverV/vvv-link/target/vvv-link-1.0.0-SNAPSHOT.jar（本轮已构建，369/369 测试绿）
scp vvv-link/target/vvv-link-1.0.0-SNAPSHOT.jar <server>:/opt/vvv/vvv-link-new.jar
```

服务器上（沿用现有部署方式替换 + 重启）。**注意**：本轮 `bootstrap.yml` 把
`game.ws.allowed-origins` 从 `*` 收紧为 `"https://api.ok123find.top,https://localhost"`
——如果服务器上手工改过 yml，合并时别把收紧覆盖回 `*`。

重启后自检：

```bash
curl -s https://api.ok123find.top/vvv/api/game/v1/health   # 期望 {"module":true,"mysql":true,"redis":true}
```

## 2. H5 前端（浏览器玩家入口）

产物：`plane-duel/apps/client/dist/`（本轮 `pnpm build:h5` 构建，gzip 后 JS 47.6 kB）。
打包件：`/Users/gqli/work/deepagents/docs/myproject/plane-duel/plane-duel-h5-dist.tar.gz`（未入库的构建产物）。

```bash
# 本地重打包（如需）：cd plane-duel/apps/client && pnpm build:h5 && tar -czf ../plane-duel-h5-dist.tar.gz -C dist .
scp /Users/gqli/work/deepagents/docs/myproject/plane-duel/plane-duel-h5-dist.tar.gz <server>:/tmp/
```

服务器上解压到静态目录（例 `/var/www/plane-duel/`），nginx 加一个 server 或 location：

```nginx
# 方案 A（推荐）：H5 挂在 api.ok123find.top 自己的子路径下 —— 同源，客户端零配置
# （http.ts 浏览器侧默认基址就是同源的 /vvv/api/game/v1，WS 默认 wss://api.ok123find.top/vvv/api/game/ws；
#  客户端默认 WS 域名写死为 api.ok123find.top，同源部署正好对上）
location /plane/ {
    alias /var/www/plane-duel/;
    try_files $uri $uri/ /plane/index.html;
}
```

方案 B（独立子域 app.ok123find.top）：跨域会被 `Vpn-Token` 自定义头的 CORS 预检挡住，
需要 nginx 给 `/vvv/api/game/**` 加 OPTIONS 预检放行 + `Access-Control-Allow-Headers: Vpn-Token`，
并把 `allowed-origins` 追加 `https://app.ok123find.top`。同源方案 A 没这些坑，建议 A。

入口带 token：`https://api.ok123find.top/plane/?vpnToken=<平台token>`（token 也可先进 localStorage `plane-duel:vpnToken`）。
## 3. 部署后验收（5 分钟）

1. 健康三项 true（上面 curl）。
2. 浏览器开 H5 入口 → 大厅显示昵称/金币 → 开档案页 → 近期战绩显示"对决2人 · 入门"（capacity 生效）。
3. 跑一局人机练习 → 结算页 → 库里核对（token 即铸即用，db1 会逐出空闲键）：
   ```sql
   SELECT COUNT(*) FROM game_shot WHERE match_id LIKE '<新局id>%';  -- >0 即逐发落表上线
   ```
4. 回归审计 `db/game/audit_integrity_checks.sql` 六项全 0。

## 4. Android 真机

Capacitor 壳在 `plane-duel/apps/client/android/`；`npx cap sync && ./gradlew assembleDebug`。
WebView origin 是 `https://localhost`，已在 allowed-origins 白名单里，无需改配置。
