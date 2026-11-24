# nginx 部署说明

## 文件与服务器路径对应

| 仓库文件 | 服务器路径 |
|---|---|
| `deploy/nginx/vpn.conf` | `/etc/nginx/conf.d/vpn.conf` |
| `deploy/nginx/snippets-vpn-routes.conf` | `/etc/nginx/snippets/vpn-routes.conf` |
| `deploy/nginx/snippets-proxy-common.conf` | `/etc/nginx/snippets/proxy-common.conf` |
| `deploy/nginx/poetry-sspacee.conf` | `/root/local/nginx-1.24.0/conf/server/poetry-sspacee.conf`（应用机）——**备选，未上线** |
| `deploy/nginx/poetry-routes-sspacee.conf` | `/root/local/nginx-1.24.0/conf/server/poetry-routes-sspacee.conf`（应用机）——**备选，未上线** |
| `deploy/nginx/poetry-gateway.conf` | `/etc/nginx/conf.d/poetry-gateway.conf`（网关）——**2026-11-24 定案走这套** |
| `deploy/nginx/snippets-poetry-routes.conf` | `/etc/nginx/snippets/poetry-routes.conf`（网关） |

上游 `vpn_server`、`chat_server`、`chat_server1`、`fetchurl_server`、`book_server` 仍在 `nginx.conf` 的 `http {}` 里定义，这里不重复。

**新增上游 `companion_server`** 也要手动加到 `nginx.conf` 的 `http {}` 里
（`upstream` 只允许出现在 `http {}`，写进 snippet 会让 `nginx -t` 失败）。

⚠ **这不是唐诗的服务**：陪伴产品（companion-agent）的 agent 跑在它自己的进程里，
路由出现在本仓库只因为**网关的 nginx 配置在这仓库里**（共享机，见
[`docs/poetry/network-architecture.md`](../docs/poetry/network-architecture.md)）。
唐诗的架构文档不规定它，改唐诗时也别顺手改它。

状态实测（2026-11-24，只读）：线上生效的是 `ca_api` 上游 + `/v1/**`、`/companion-health`、
`/metrics`（401 / 200 / 403），由 `8a91149c`（2026-11-12「nginx 加陪伴与 agent 路由」）引入的
那套写法；本仓库这两段的 `companion_server` + `/api/agent/v1/**` + `/companion/**`
**没放上网关**（实测返回 nginx 自己的 HTML 404）。**别定义第三个指同一台的上游名**。

`ca_api` 的地址实测是 `104.160.191.87:8081`——本仓库早期把它写成 `127.0.0.1:8081` 是错的
（网关本机无监听），已改：

```nginx
upstream companion_server { server 104.160.191.87:8081 max_fails=3 fail_timeout=10s; keepalive 16; }
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

⚠ **唐诗涉及的是三台机器，不是两台**：除了网关与应用机，内容底座在**第三台**
`47.82.163.162` ← `mysql.sspacee.com:6666/vpn`（`dig @8.8.8.8` + `:6666` 握手横幅实测；
横幅 `server_version=8.0.46-0ubuntu0.24.04.5`）。这一跳此前从没写进唐诗文档，
而迁移执行位置、备份、跨机防火墙都挂在它上面。完整进程/端口/边界见
[`docs/poetry/network-architecture.md`](../docs/poetry/network-architecture.md)。
**最该补的一项**：jar 的 `:8888` 今天在两个公网 IP 上**明文可达、无来源限制**（实测读接口直接 200），
配上 `poetry.reviewToken` 之后写侧也会从这条绕开网关——应把 `:8888` 收成只允许
`8.217.122.83` 与本机回环（安全组或 iptables，你执行）。

**DNS 实况（2026-11-24 二次复查，用户已加记录）**：

| 域 | A 记录 | 网关上现在能给什么 |
|---|---|---|
| `poetry.sspacee.com` | **`8.217.122.83`（网关）** | 80 → 落默认 vhost `404`；443 → **握手失败**（现证书 SAN 只有 `api.ok123find.top / api.ok124find.top / book.ok123find.top / file.ok123find.top`） |
| `api.sspacee.com` | **`8.217.122.83`（网关）** | 同上：80 `404`、443 握手失败（`--resolve` 实测，两个名都一样） |

> 测量口径：`dig @8.8.8.8 / @1.1.1.1 / @223.5.5.5` 三家一致给 `8.217.122.83`；
> **本机 `dig` 那次给过 `64.32.22.150`，是过期缓存**（TTL 未到），别拿本机结果判断线上。
> 早先记录里「`api.sspacee.com` 仍无记录」已被推翻——DNS 这步已经做完了。

⇒ **剩下的两步都在网关上**：(1) 放 `poetry-gateway.conf` + `snippets-poetry-routes.conf`；
(2) 把 `api.sspacee.com`、`poetry.sspacee.com` 加进证书 SAN（`certbot.sh` 的 `DOMAINS` 已含两名）。
顺序必须是**先证书后 server_name**：vhost 先进、SAN 还没换，则这个名的每次握手都失败。
`poetry.sspacee.com` 走的是「**页面与 API 同源**」，所以宿主的通配 CORS 不再是唐诗上线的阻塞项
（仍然要修，见 `docs/poetry/architecture.md`）；`api.sspacee.com` 只给旧 App 与新客户端做 API 入口。

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
| `https://api.ok123find.top/v1/sessions`、`/companion-health` | `401`（agent 自己鉴权）、`200` | **companion-agent 已在线上**（上游 `ca_api` → `104.160.191.87:8081`）；`/metrics` → 403（只对内网，正确） |
| `https://api.ok123find.top/api/agent/v1/health` | `404`，**nginx 自己的 HTML**（不是 agent 的 JSON） | 这是**陪伴产品**的路由，不是唐诗的；记录在此只因为网关配置在本仓库（共享机）。唐诗的架构文档不管它，见 `docs/poetry/network-architecture.md` |
| `poetry / api.sspacee.com` | DNS 已到网关，但 80 `404`、443 握手失败 | vhost 与 SAN 都还没做（见上） |
| `api-poetry / agent-poetry.sspacee.com` | **无 DNS** | 已放弃/暂缓（见下表） |

目标态（2026-11-24 定案：Java 只对外**一个** API 域；两个 sspacee 子域都在网关）：

| 域名 | 用途 | 解析到 | 终结方 |
|---|---|---|---|
| `api.sspacee.com` | **Java 后端唯一新名**（poetry/student/game/roles 全部 `/vvv/api/**`，路径形状与旧名完全一致） | 网关 `8.217.122.83` | 网关 nginx（与 `api.ok123find.top` 同一 vhost、同一 SAN 证书） |
| `api.ok123find.top` | 同一个后端的老名，**不动**（已装 App 的用户继续用） | 网关 `8.217.122.83` | 网关 nginx |
| `poetry.sspacee.com` | **唐诗学生端 PWA + 同源 API**（`/api/student/v1/**`、`/api/poetry/v1/**`，以后 `/agent/v1/**`）——前端零改动、不涉及跨域 | 网关 `8.217.122.83` | 网关 nginx（`poetry-gateway.conf`） |
| `file.ok123find.top` | 文件下载（`/file/`、`/image/`、`/soft`） | 网关 `8.217.122.83` | 网关 nginx |

已放弃/暂缓的域名（不再进方案）：

- `api-poetry.sspacee.com` —— 取消。单一 api 域下它是冗余的第二入口，只增加证书与排查面。
- `agent-poetry.sspacee.com` —— **取消（不是暂缓）**。`agent-bff :8100` 今天没有进程只是表层原因；
  真正的原因是内容生产 agent 不该有公网入口（写边界见 `docs/poetry/architecture.md`），
  远端使用走 SSH 隧道。详见 `docs/poetry/agents.md`。
- `sspcee.com` —— **未注册**（whois `No match for domain "SSPCEE.COM"`，无 NS）。你的域是
  `sspacee.com`（dnspod：`f1g1ns1/2.dnspod.net`）。若确实想要 sspcee 那个拼法，先注册再规划。

> CORS 仍然是一个要修的缺口，但**不再是唐诗上线的阻塞项**：定案后 PWA 与 API 同源，
> 浏览器根本不触发跨域。留着的害处是别处——`vvv-link` 宿主的 `MyCorsFilter` 现在是
> `addAllowedOriginPattern("*")` + `allowCredentials(true)` 注册在 `/**`（实测任意 Origin
> 都反射回 `Access-Control-Allow-Origin` + `Allow-Credentials: true`），旧业务的写侧也在
> 范围内，靠的只是 token 头不是 CORS。修法见 `docs/poetry/architecture.md`「一个已知缺口」。

要点：网关上两个 sspacee 名进的是 `certbot.sh` **同一张** SAN 证书（不是每域一张）；
应用机自己的 `sspacee.com`/`jc`/`gpt` 仍是每域一张，两套惯例别混。`jc.sspacee.com` 上
**没有** poetry 路由（实测 404，那是简历产品的 vhost，JC 的 agent 内嵌在它自己的 API 进程里），
不要拿它验唐诗 API。

## 步骤（两条独立线，可分别做）

**A. Java 新名 `api.sspacee.com`（在网关 8.217.122.83 上）**

1. DNS：**已完成**（实测 A → `8.217.122.83`）。
2. 证书：网关 root 执行 `bash deploy/ssl/certbot.sh 你的邮箱`（`DOMAINS` 已含三个名）。
   先看清上面「证书 SAN 实况」那条——现网证书比脚本宽，别贸然重签。
3. 放文件：`vpn.conf`（两处 `server_name` 加 `api.sspacee.com`）、
   `snippets-vpn-routes.conf` → `/etc/nginx/snippets/vpn-routes.conf`。
4. `nginx -t && systemctl reload nginx`。
5. 验证：`curl -s https://api.sspacee.com/vvv/api/poetry/v1/coverage` → 与
   `api.ok123find.top` 同名路径**逐字节一致**。老名一律不动。

**B. 唐诗 PWA `poetry.sspacee.com`（已定：也在网关上）**

DNS 已完成（A → `8.217.122.83`）。剩下的顺序（每一步都不需要停现网）：

1. 放文件：`poetry-gateway.conf`、`snippets-poetry-routes.conf`。放的时候 443 引用的是
   `/etc/nginx/ssl/` 里**已存在**的旧证书，`nginx -t` 能过，只是这个名的 TLS 名字不匹配——
   先放文件是为了 80 端口的 acme-challenge 有个确定的落点（不放，poetry 名的校验请求会
   落进默认 server，成不成看运气）。
   ⚠ 放置路径先跑 `nginx -T | grep -n "include\|vpn.conf"` 核实（两份文档对网关 nginx
   布局记法不一致，见 `poetry-gateway.conf` 文件头）。
2. 证书：网关 root 执行 `bash deploy/ssl/certbot.sh 你的邮箱`——**先确认现网那两个多出来的
   SAN 名（api.ok124find / book.ok123find）怎么处理**（见上），否则别重签。
3. 前端产物落位到**网关**的 `/home/file/poetry/`（见下「前端上线要求」——定案在网关后，
   静态目录也在网关，不再是应用机）。
4. `nginx -t && systemctl reload nginx`。
5. 验证：
   - `curl -I https://poetry.sspacee.com/` → 200（index.html，`Cache-Control: no-cache`）
   - `curl -I https://poetry.sspacee.com/sw.js` → `Cache-Control: no-store`
   - `curl -s https://poetry.sspacee.com/api/student/v1/config` → JSON（同源 API；须 vvv-link 已起）
   - `curl -s https://api.sspacee.com/vvv/api/student/v1/config` → 与旧名同名路径逐字节一致
   - 讲诗 agent（`/agent/v1/**`）**今天没有进程**：那段 location 是注释状态，起进程时再放开
     （上游、鉴权两个坑写在那段注释里）。agent 全家族盘点与入口定案见
     [`docs/poetry/agents.md`](../docs/poetry/agents.md)——内容生产 agent 永久不给公网入口。

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
3. 场景素材（`/assets/`）是**内容寻址**的，走一年 immutable；素材文件在**应用机**
   （jar 的 `student.asset.root`），网关那侧由 `snippets-poetry-routes.conf` 反代过去，
   **不要**在网关上再存一份。前端自身的 `src/`、`public/` 没有内容哈希，由 `location /`
   的 `no-cache` 覆盖——发版不会被缓存黏住。
3. PWA 更新链路依赖 `sw.js` 永不缓存——路由已对 `/sw.js` 强制 `no-store`，别在别处覆盖。
4. 前端 API 基址走同源（`/api/student/v1`、`/api/poetry/v1`），不要在前端写死域名。

> 上线时 nginx root 指向 `current/dist`，与 `snippets-poetry-routes.conf` 内写死的路径一致。
> ⚠ 定案在网关后，`dist/` 落在**网关**；jar 的 `student.app.root` 指的是**应用机**上的同名目录，
> 两处不是同一份。于是 `http://<应用机 IP>:8888/app/` 这条自查通路只在应用机也放了一份 dist 时才有内容
> （下面「最短看到效果」用的就是它）——要留这条通路，就把 dist 同时拷到应用机那份。

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
  app.root: /home/file/poetry/current/dist    # 应用机上那份；网关上的那份 jar 看不见（见上面那条 ⚠）
  asset.root: /home/file/poetry/assets
  cors.allowedOrigins: https://poetry.sspacee.com   # 定案后同源，这里其实用不上；留着是为了以后真分域时不用再查
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
