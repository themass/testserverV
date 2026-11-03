# nginx 部署说明

## 文件与服务器路径对应

| 仓库文件 | 服务器路径 |
|---|---|
| `deploy/nginx/vpn.conf` | `/etc/nginx/conf.d/vpn.conf` |
| `deploy/nginx/snippets-vpn-routes.conf` | `/etc/nginx/snippets/vpn-routes.conf` |
| `deploy/nginx/snippets-proxy-common.conf` | `/etc/nginx/snippets/proxy-common.conf` |

上游 `vpn_server`、`chat_server`、`chat_server1`、`fetchurl_server`、`book_server` 仍在 `nginx.conf` 的 `http {}` 里定义，这里不重复。

## 步骤

1. 备份：`cp /etc/nginx/conf.d/vpn.conf /etc/nginx/conf.d/vpn.conf.bak`
2. 复制上表的文件，`mkdir -p /etc/nginx/snippets`
3. 申请证书（二选一）：
   - 正式：`bash deploy/ssl/certbot.sh 你的邮箱`
   - 测试：`bash deploy/ssl/self-signed.sh`（只用于测试，App 与 AdMob 不信任）
4. `nginx -t` 通过后 `systemctl reload nginx`
5. 验证：`curl -I https://api.ok123find.top/vvv/api/version.json`，返回 200 且没有 SSL 错误。
6. App 切到 HTTPS、确认用户都已更新后，打开 `vpn.conf` 里 80 端口的 301 跳转注释。
