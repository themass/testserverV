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
> 过渡期公网通路是 **`api.ok123find.top/vvv/api/poetry/v1/**`（带 `/vvv` 前缀，已在网关生效）**；
> 仓库 `snippets-vpn-routes.conf` 里那段**不带** `/vvv` 的别名**尚未放上网关**（实测 404），
> 稳定后随三域落地一并移除。

学生端 PWA（静态）+ 同域 API 反代到 vvv-link（8888，内含 vvv-poetry / vvv-student 模块）。
应用机 nginx 直连 8888 时 API 前缀为后端实测的 `@RequestMapping`，**不带 `/vvv` 前缀、不 rewrite**；
网关那条通路带 `/vvv` 是它自己的 location 形状（`vpn_server` 上游），两回事，别混。

## 域名与拓扑

**应用机是一台机器、两个公网 IP**（`64.32.22.150` 与 `104.160.191.87`——2026-11-24 用户确认；
外部探测指纹完全一致：`:8888` 响应逐字节相同、443 上 `jc.sspacee.com`/`sspacee.com`
两张证书的**序列号都相同**。写文档时不要把两者当成两台机器）。

**DNS 实况（2026-11-24 复查，用户已加记录）**：

| 域 | A 记录 | 网关上现在能给什么 |
|---|---|---|
| `poetry.sspacee.com` | **`8.217.122.83`（网关）** | 80 → 落默认 vhost `404`；443 → **握手失败**（现证书 SAN 只有 `api.ok123find.top / api.ok124find.top / book.ok123find.top / file.ok123find.top`） |
| `api.sspacee.com` | **仍无记录** | — |

⚠ **两个决定要挑明**：

1. `poetry.sspacee.com` 指向了**网关 8.217.122.83**，不是应用机 `64.32.22.150`。
   本仓库 `poetry-sspacee.conf` 是按「应用机 nginx 终结 TLS + 本机反代 8888」写的——
   那个文件在网关上用不了（网关无 `server/*.conf` include、无 `/home/file/poetry` 目录）。
   要么把 A 改指应用机（PWA 与 jar 同机，同域反代最省事），要么在网关上新写一个
   `poetry.sspacee.com` server 块（静态 root 指到网关本地目录 + 反代 `vpn_server`）。
   **不管选哪个，证书都得先把该名加进 SAN**（否则 443 永远红）。
2. `api.sspacee.com` 还没加记录，所以 `certbot.sh` 里已加的该名现在**会 FAIL**——
   先加 A 记录（→ `8.217.122.83`）再跑 certbot。

**证书 SAN 实况（2026-11-24 实测 `openssl s_client -servername …`）**：

现网关证书 SAN = `api.ok123find.top`、`api.ok124find.top`、`book.ok123find.top`、`file.ok123find.top`
——**四个**，而 `deploy/ssl/certbot.sh` 的 `DOMAINS` 只列了两个。两个多出来的名都活着：
`api.ok124find.top`（注意 `124` 是 `123` 的错拼变体）实测 `/vvv/api/version.json` → **200**，
`book.ok123find.top` → 404。也就是说**线上证书比脚本能重建的更宽**：哪天证书由这个脚本重新签发，
`api.ok124find.top` 会静默失效。要么把这两个名补进 `DOMAINS`（前提：它们仍在用），要么确认废弃后
有意识地接受失效——**别在没查清之前重签**。（未改脚本，等你确认这两个名是否还有客户端在用。）

**现网可用通路（2026-11-24 实测）**：

| 通路 | 实测 | 说明 |
|---|---|---|
| `https://api.ok123find.top/vvv/api/poetry/v1/coverage` | `200`，与直连 `:8888` **逐字节一致** | 走网关 `8.217.122.83` → `vpn_server` 上游。**带 `/vvv` 前缀**——这是今天唯一可用的公网 API |
| `https://api.ok123find.top/vvv/api/student/v1/config` | `200` + `errno:10000` | 通路在、模块没装配（`student.enabled` 不在服务器 yml，见下） |
| `http://<任一 IP>:8888/api/poetry/v1/**` | `200` | 直连 jar；无 TLS，只用于验活与 publish |
| `https://api.ok123find.top/api/poetry/v1/**`（不带 `/vvv`） | `404` | 本仓库 `snippets-vpn-routes.conf` 里的过渡别名段**尚未放上网关** |
| `poetry / api-poetry / agent-poetry.sspacee.com` | **无 DNS** | 三域方案已于 2026-11-24 改规划（见下表）：只留 `poetry`，后两个放弃 |

目标态（2026-11-24 规划：Java 只对外**一个** API 域；DNS 与证书未做）：

| 域名 | 用途 | 解析到 | 终结方 |
|---|---|---|---|
| `api.sspacee.com` | **Java 后端唯一新名**（poetry/student/game/roles 全部 `/vvv/api/**`，路径形状与旧名完全一致） | 网关 `8.217.122.83` | 网关 nginx（与 `api.ok123find.top` 同一 vhost、同一 SAN 证书） |
| `api.ok123find.top` | 同一个后端的老名，**不动**（已装 App 的用户继续用） | 网关 `8.217.122.83` | 网关 nginx |
| `poetry.sspacee.com` | **唐诗学生端 PWA（纯静态）**；API 走 `api.sspacee.com` | 应用机（`64.32.22.150`；同机另有 `104.160.191.87`） | 应用机 nginx（`/root/local/nginx-1.24.0`） |
| `file.ok123find.top` | 文件下载（`/file/`、`/image/`、`/soft`） | 网关 `8.217.122.83` | 网关 nginx |

已放弃/暂缓的域名（不再进方案）：

- `api-poetry.sspacee.com` —— 取消。单一 api 域下它是冗余的第二入口，只增加证书与排查面。
- `agent-poetry.sspacee.com` —— 暂缓。`agent-bff :8100` **今天没有进程**（实测无监听），等有 BFF 再谈。
- `sspcee.com` —— **未注册**（whois `No match for domain "SSPCEE.COM"`，无 NS）。你的域是
  `sspacee.com`（dnspod：`f1g1ns1/2.dnspod.net`）。若确实想要 sspcee 那个拼法，先注册再规划。

> ⚠ 静态与 API 分域 = 跨域。`vvv-link` 宿主的 `MyCorsFilter` 现在是
> `addAllowedOriginPattern("*")` + `allowCredentials(true)` 注册在 `/**`（实测任意 Origin
> 都反射回 `Access-Control-Allow-Origin` + `Allow-Credentials: true`），所以
> `StudentCorsFilter` 的白名单当前**不起决定作用**。分域上线前应先把宿主 CORS 收到旧业务前缀，
> 详见 `docs/poetry/architecture.md`「一个已知缺口」。

要点：sspacee.com 系静态域**不经网关**，DNS A → 应用机直连（与 `sspacee.com`/`jc`/`gpt` 同款），
证书**每域一张** certbot；`api.sspacee.com` 相反——它**就在网关上**，进的是 `certbot.sh` 那张
SAN 组，不是每域一张。`jc.sspacee.com` 上**没有** poetry 路由（实测 404，那是简历产品的 vhost），
不要拿它验唐诗 API。

## 步骤（两条独立线，可分别做）

**A. Java 新名 `api.sspacee.com`（在网关 8.217.122.83 上）**

1. DNS：`api` A → `8.217.122.83`（dnspod 面板）。
2. 证书：网关 root 执行 `bash deploy/ssl/certbot.sh 你的邮箱`（`DOMAINS` 已含三个名；
   **先加 DNS**，否则 webroot 校验失败）。新 SAN 生效前 `server_name` 里加了该名也没事，
   只是 TLS 会警告。
3. 放文件：`vpn.conf`（两处 `server_name` 加 `api.sspacee.com`）、
   `snippets-vpn-routes.conf` → `/etc/nginx/snippets/vpn-routes.conf`。
4. `nginx -t && systemctl reload nginx`。
5. 验证：`curl -s https://api.sspacee.com/vvv/api/poetry/v1/coverage` → 与
   `api.ok123find.top` 同名路径**逐字节一致**。老名一律不动。

**B. 唐诗 PWA 静态域 `poetry.sspacee.com`（在应用机上）**

1. DNS：`poetry` A → `64.32.22.150`。
2. 证书：应用机 root 执行 `bash deploy/ssl/certbot-poetry-sspacee.sh 你的邮箱`
   （每域一张；`DOMAINS` 已收敛到只签 `poetry.sspacee.com`——`api-poetry`/`agent-poetry`
   随规划调整删掉了，别再加回来）。
3. 放文件：`poetry-sspacee.conf`、`poetry-routes-sspacee.conf`
   → `/root/local/nginx-1.24.0/conf/server/`（该机 nginx 用 `include server/*.conf`，无 snippets 目录）。
   ⚠ 走「静态与 API 分域」时，要先把该文件里两段 API 反代去掉（前端改指
   `https://api.sspacee.com/vvv/api/...`），并先收宿主 CORS（见 architecture.md）；
   否则维持「同域反代」这一版，前端不用改。
4. 前端产物落位（见下「前端上线要求」）。
5. `nginx -t && nginx -s reload`（二进制在 `/root/local/nginx-1.24.0/sbin/nginx`，不在 PATH）。
6. 验证：
   - `curl -I https://poetry.sspacee.com/` → 200（index.html，`Cache-Control: no-cache`）
   - `curl -I https://poetry.sspacee.com/sw.js` → `Cache-Control: no-store`
   - 同域版：`curl -s https://poetry.sspacee.com/api/student/v1/config` → JSON（须 vvv-link 已起）
   - 分域版：`curl -s https://api.sspacee.com/vvv/api/student/v1/config` → JSON

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
  cors.allowedOrigins: https://poetry.sspacee.com   # 静态与 API 分域时必须登记；同域版可留默认壳来源
  agentEnabled: false                          # companion agent 通路（:8081）没上线前保持 false
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
