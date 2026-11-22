# 部署实况（2026-11-23 加固上线后）

## 0. 进程守护（本轮新增）

jar 与 nginx 均已交 systemd 托管（`enabled + active`，崩溃 5s 自拉起、开机自启）：

```bash
systemctl status vvv-link        # jar：User=web，JDK=/home/web/local/jdk-21.0.3，日志 journalctl -u vvv-link -f
systemctl status nginx           # 二进制沿用 /root/local/nginx-1.24.0（非 apt 包），Type=forking 跟 /var/run/nginx.pid
```

**改配置/换包一律走 systemctl**（`systemctl restart vvv-link` / `nginx -t && systemctl reload nginx`），别再手工 `java -jar` / `./nginx` 起——手起进程 systemd 会视为孤儿并可能重复拉起。

## 1. 后端 jar（✅ 2026-11-23 加固版已上线）

本轮上线内容（commit 0cffb626，vvv-game 376/376 + vvv-link 107/107 绿）：

- **Web 登录接口** `POST /api/game/v1/login`：`{"name","pwd"}` → `{errno,data:{token,name},error}`；
  token 与 App 的 login.json 同体系（cacheService.putUser），Redis 键带 `token_` 前缀，
  GameTokenResolver 已兼容裸串/带前缀两种形态。
- **WS 发送装饰器**：`ConcurrentWebSocketSessionDecorator(5s, 512KB)`，防 tick/请求线程并发撕裂；
  慢客户端缓冲溢出即断开（走正常重连恢复）。
- **WS 心跳**：独立线程 `game-ws-ping`，`game.ws.pingMs=25000`（0=关，不建议），半开连接自动回收。
- **token 滑动续期**：游戏侧鉴权成功即 EXPIRE 重置 24h（活跃不掉线，闲置 24h 过期回登录页）。
- **allowed-origins**（bootstrap.yml）：`https://api.ok123find.top,https://localhost,https://game.ok123find.top`。

jar 在 `/home/web/work/testserverV/vvv-link/target/`（旧包备份 `.bak-20261123`）。换包流程：

```bash
# 本地：mvn package -DskipTests → scp 到 /home/web/work/testserverV/vvv-link-new.jar
# 服务器：mv 换名（保备份）→ chown web:web → systemctl restart vvv-link
curl -s https://api.ok123find.top/vvv/api/game/v1/health   # 期望 {"module":true,"mysql":true,"redis":true}
```

## 2. H5 前端（✅ 玩家入口 = 独立页面域名）

**正式入口：`https://game.ok123find.top/`**（页面域名，与 api 接口域名职责分离；
token 不进 URL，玩家先见登录页）。api.ok123find.top 上的 `/plane/` 已下线（404）。

- DNS：`game` A → 8.217.122.83（dnsowl 面板维护）。
- 证书：Let's Encrypt（certbot webroot，cron 自动续期，deploy hook
  `/etc/letsencrypt/renewal-hooks/deploy/game-ok123.sh` 同步到 `/root/local/nginx/conf/ssl/game-*.pem` 并重载）。
- nginx：`conf/server/game.conf` —— 静态站 root `/home/web/webroot/plane-duel`（try_files → /index.html）+
  `/vvv/api/game/ws`（Upgrade）与 `/vvv/api/game/v1/`（rewrite）反代 `vpn_server`，形状与 api 域一致 →
  页面同源调接口，客户端基址零配置。
- 发布：`/root/work/deploy-plane-h5.sh`（git pull → pnpm test → build:h5 → rsync → chown web:web → curl 自检；
  `--skip-test` 跳测试）。
- 源码构建环境：`/usr/local/node20`（unofficial-builds glibc-217 版，Ubuntu 18.04 唯一可行）+
  corepack pnpm 9；构建命令前必须 `export PATH=/usr/local/node20/bin:$PATH`。

登录链路：登录页 → `POST /vvv/api/game/v1/login`（game 域反代）→ token 存 localStorage →
WS 握手时代码拼 `?vpnToken=`（浏览器 WS 无法设 header 的固有限制，URL 栏不可见；
access log 会含该参数，脱敏属网关层后续项）。会话闲置 24h 过期后，客户端在第 3 次重连失败时
自动回登录页（此前无 profile.now 成功经历才判定，避免误踢对局中玩家）。

入口：`https://api.ok123find.top/plane/?vpnToken=<平台token>`。

以下为原方案记录（已按上面执行，保留备查）：

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
