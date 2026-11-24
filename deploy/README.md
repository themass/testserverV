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
1. 构建：`cd student-app/frontend && npm run build:web`（`build.mjs --web` → **`dist/web/`**；
   只跑 `npm run build` 只出 `dist/runtime` + `dist/platform-web`，**不能**直接上线）。
   落位时把 `dist/web/` 的**内容**放进 `releases/<时间戳>/dist/`。
2. 站根必须有 `index.html`、`sw.js`、`manifest.webmanifest`、`icon.svg`——后两个由 `build.mjs --web`
   从 `public/` 拷到站根（2026-11-24 补：此前构建**不产** manifest，nginx 的
   `location = /manifest.webmanifest` 会一直 404）。前端 `index.html` 已带
   `<link rel="manifest" href="/manifest.webmanifest">`。
3. 场景素材（`/assets/`）是**内容寻址**的，走一年 immutable；前端自身的 `src/`、`public/`
   没有内容哈希，由 `location /` 的 `no-cache` 覆盖——发版不会被缓存黏住。
3. PWA 更新链路依赖 `sw.js` 永不缓存——路由已对 `/sw.js` 强制 `no-store`，别在别处覆盖。
4. 前端 API 基址走同源（`/api/student/v1`、`/api/poetry/v1`），不要在前端写死域名。

> 上线时 nginx root 指向 `current/dist`，与 `poetry-routes-sspacee.conf` 内写死的路径一致。

## 最短看到效果（不必等 DNS 与证书）

2026-11-24 实测线上实况（只读探测，未改服务器）：

| 探测 | 结果 | 结论 |
|---|---|---|
| `GET :8888/api/poetry/v1/content` | `errno:0`，`items:[]` | vvv-poetry **已装配**；空列表是发布闸门（127 首全 DRAFT），不是故障 |
| `GET :8888/api/poetry/v1/coverage` | `errno:0`，有 cov-* 行 | V001–V006 的表与种子都在真库 |
| `OPTIONS :8888/api/student/v1/config`（恶意 Origin） | `200`，无我们那 5 个头 | `StudentCorsFilter` **没注册** |
| `GET :8888/api/student/v1/config`、`/app/` | `errno:10000` | vvv-student **整个没装配** |

根因一条：`student.enabled` 此前**不在任何 yml 里**（`bootstrap-prod.yml` 只有 `poetry.enabled`），
`@ConditionalOnProperty` 不满足 → 模块不装配 → 这些路径落到宿主兜底。

**注意**：`bootstrap-prod.yml` 被 `.gitignore` 的 `**/bootstrap-*.yml` 排除（里面有库口令），
所以这个开关**不会随 jar 走**，必须在服务器上手工加。加在 `poetry.enabled` 同层：

```yaml
student:
  enabled: true
  app.root: /home/file/poetry/current/dist    # 8888 的 /app/ 也可达（与 nginx 同一目录）
  asset.root: /home/file/poetry/assets
  cors.allowedOrigins: https://poetry.sspacee.com   # 同域不需要 CORS，登记壳与联调来源
  agentEnabled: false                          # agent-poetry.sspacee.com 上线前保持 false
```

服务器侧顺序（都是你执行；我不碰机器）：

```bash
# 1) 建目录（Java 与 nginx 指同一处；student.app.root 目录不存在时只 warn + 404，不会崩）
mkdir -p /home/file/poetry/releases /home/file/poetry/assets
# 2) 前端产物落位（在源码机 build 后上传 dist/web 的内容）
cd student-app/frontend && npm run build:web     # 产物 dist/web，含 manifest.webmanifest + icon.svg
#    → /home/file/poetry/releases/$(date +%Y%m%dT%H%M%S)/dist
ln -sfn /home/file/poetry/releases/<那个目录> /home/file/poetry/current
# 3) 重启 jar（代码没改，不必重打包；上面那段 student: 是**服务器上**加的）
# 4) 发布至少一首（否则前端只有空壳）：先在 config/poetry-prod.yml 配 poetry.reviewToken
curl -s -X POST -H "X-Poetry-Review-Token: <token>" -H 'Content-Type: application/json' \
  -d '{"reviewer":"<真人姓名>","note":"依据 wikisource 快照，核查 106 项全 0"}' \
  http://127.0.0.1:8888/api/poetry/v1/review/content/work-t300-002/publish
```

第 4 步的**顺序与闸门**以 `docs/poetry/review-checklist.md` 为准（先 `audit` 看 106 项是否全 0，
再 source → text_version → claim → content；审核人名不能是 `DEMO*`/`system`），
一条 publish 只翻一行，**不会级联**——没发布链路时 `works/work-t300-002` 会 404，这是设计。

验证（无需 DNS）：`curl -s http://64.32.22.150:8888/api/student/v1/config` → `errno:0`；
浏览器开 `http://64.32.22.150:8888/app/`。此时 sw.js 不会注册（非安全上下文），
看内容与时间轴够用；正式的 PWA 安装走下面的 DNS + 证书。

**已知构建事实**：`build.mjs` 不产内容哈希（零依赖构建），所以 nginx `/assets/` 的
一年 immutable 只适用于 `student.asset.root` 那类内容寻址素材；前端自身的 `src/`、`public/`
由 `location /` 的 `no-cache` 覆盖，发版不会被缓存黏住。
