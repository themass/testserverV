# nginx 部署说明

## 文件与服务器路径对应

| 仓库文件 | 服务器路径 |
|---|---|
| `deploy/nginx/vpn.conf` | `/etc/nginx/conf.d/vpn.conf` |
| `deploy/nginx/snippets-vpn-routes.conf` | `/etc/nginx/snippets/vpn-routes.conf` |
| `deploy/nginx/snippets-proxy-common.conf` | `/etc/nginx/snippets/proxy-common.conf` |
| `deploy/nginx/poetry-sspacee.conf` | `/root/local/nginx-1.24.0/conf/server/poetry-sspacee.conf`（应用机） |
| `deploy/nginx/poetry-routes-sspacee.conf` | `/root/local/nginx-1.24.0/conf/server/poetry-routes-sspacee.conf`（应用机） |

上游 `vpn_server`、`chat_server`、`chat_server1`、`fetchurl_server`、`book_server` 仍在 `nginx.conf` 的 `http {}` 里定义，这里不重复。

**新增上游 `companion_server`**（陪伴 / agent 服务）也要手动加到 `nginx.conf` 的 `http {}` 里
（`upstream` 只允许出现在 `http {}`，写进 snippet 会让 `nginx -t` 失败）：

```nginx
upstream companion_server { server 127.0.0.1:8081; keepalive 16; }
```

## 步骤

1. 备份：`cp /etc/nginx/conf.d/vpn.conf /etc/nginx/conf.d/vpn.conf.bak`
2. 复制上表的文件，`mkdir -p /etc/nginx/snippets`
3. 申请证书（二选一）：
   - 正式：`bash deploy/ssl/certbot.sh 你的邮箱`
   - 测试：`bash deploy/ssl/self-signed.sh`（只用于测试，App 与 AdMob 不信任）
4. `nginx -t` 通过后 `systemctl reload nginx`
5. 验证：`curl -I https://api.ok123find.top/vvv/api/version.json`，返回 200 且没有 SSL 错误。
6. App 切到 HTTPS、确认用户都已更新后，打开 `vpn.conf` 里 80 端口的 301 跳转注释。

---

# 唐诗产品上线（poetry.sspacee.com）

> **2026-11-22 域名定版**：唐诗产品线一律使用 **sspacee.com** 系域名（用户拍板）。
> 旧的 `poetry.ok123find.top` 方案文件已删除（`git rm`，见 fd945d6 历史）。
> `api.ok123find.top` 的 `/api/poetry/v1/**` 反代作为过渡期保留（已就地内联进
> `snippets-vpn-routes.conf`），稳定后移除。

学生端 PWA（静态）+ 同域 API 反代到 vvv-link（8888，内含 vvv-poetry / vvv-student 模块）。
API 前缀为后端实测的 `@RequestMapping`，**不带 `/vvv` 前缀、不 rewrite**。

## 域名与拓扑

| 域名 | 用途 | 解析到 | 终结方 |
|---|---|---|---|
| `poetry.sspacee.com` | **学生端 PWA + 同域 API**（对用户只暴露这一个） | 应用机 `64.32.22.150` | 应用机 nginx（`/root/local/nginx-1.24.0`） |
| `api-poetry.sspacee.com` | **后端接口**（Studio / 命令行 / 跨域调用 `/api/poetry/v1/**`） | 应用机 `64.32.22.150` | 应用机 nginx |
| `agent-poetry.sspacee.com` | **agent BFF 入口**（:8100，仅运营侧；上线时加 IP 白名单） | 应用机 `64.32.22.150` | 应用机 nginx |
| `api.ok123find.top` | （过渡别名）同 api-poetry；mcp/worker 无公网域名 | 网关 `8.217.122.83` | 网关 nginx |

要点：sspacee.com 系**不经网关**，DNS A → 应用机直连（与 `sspacee.com`/`jc`/`gpt` 同款）；
证书为**每域一张** certbot（与 `jc.sspacee.com` 惯例一致），**不是**网关那张 ok123find SAN 证书。

## 步骤

1. DNS：三个域各加 A 记录 → `64.32.22.150`。
2. 证书：应用机 root 执行 `bash deploy/ssl/certbot-poetry-sspacee.sh 你的邮箱`
   （先加 DNS，否则 webroot 校验失败）。
3. 放文件：`poetry-sspacee.conf`、`poetry-routes-sspacee.conf`
   → `/root/local/nginx-1.24.0/conf/server/`（该机 nginx 用 `include server/*.conf`，无 snippets 目录）。
4. 前端产物落位（见下「前端上线要求」）。
5. `nginx -t && nginx -s reload`（二进制在 `/root/local/nginx-1.24.0/sbin/nginx`，不在 PATH）。
6. 验证：
   - `curl -I https://poetry.sspacee.com/` → 200（index.html，`Cache-Control: no-cache`）
   - `curl -I https://poetry.sspacee.com/sw.js` → `Cache-Control: no-store`
   - `curl -s https://poetry.sspacee.com/api/student/v1/...` → JSON（须 vvv-link 已起）
   - `curl -s https://api-poetry.sspacee.com/api/poetry/v1/content` → JSON

## 前端上线要求（构建与目录约定）

发布目录用 releases + current 软链，回滚只翻软链，nginx 不动：

```
/home/file/poetry/
├── releases/
│   ├── 20261122T010000/     # 每次发布一个不可变目录，内含 dist/
│   └── 20261123T090000/
└── current -> releases/20261123T090000   # nginx root 恒指 current/dist
```

产物要求：
1. 构建：`cd student-app/frontend && npm run build`（`build.mjs` → `dist/`）。
2. `dist/` 根部必须有 `index.html`、`sw.js`、`manifest.webmanifest`；带哈希的资源在 `assets/`
   （路由据此给一年 immutable 缓存）。若构建不产出内容哈希，**改 `poetry-routes-sspacee.conf`
   的 `/assets/` 缓存策略再上线**，否则发版看不到更新。
3. PWA 更新链路依赖 `sw.js` 永不缓存——路由已对 `/sw.js` 强制 `no-store`，别在别处覆盖。
4. 前端 API 基址走同源（`/api/student/v1`、`/api/poetry/v1`），不要在前端写死域名。

> 上线时 nginx root 指向 `current/dist`，与 `poetry-routes-sspacee.conf` 内写死的路径一致。
