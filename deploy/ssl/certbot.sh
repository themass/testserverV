#!/usr/bin/env bash
# Let's Encrypt 正式证书（免费，Android 与 AdMob 都信任）。
#
# 前提：
#   1. 下面 DOMAINS 里每个名的 A 记录都指向本服务器（网关 8.217.122.83）：
#      api.ok123find.top 与 file.ok123find.top 是旧名；api.sspacee.com 是 Java 后端的新名
#      （与旧名同一路由别名）；poetry.sspacee.com 是唐诗 PWA，2026-11-24 定案**也在网关上**
#      （deploy/nginx/poetry-gateway.conf），所以它进这张 SAN，不再用
#      certbot-poetry-sspacee.sh 每域一张那一套（那个脚本留着只服务「改回应用机」的备选）。
#      ⚠ 现网这张证书的 SAN 比本脚本还多两个名：api.ok124find.top（实测 200，仍活着）、
#      book.ok123find.top（实测 404）。没查清是否还有客户端在用之前，**别用本脚本重签**——
#      重签会让那两个名静默失效。查清后要么补进 DOMAINS，要么有意识地接受失效。
#   2. 服务器 80 端口可以从公网访问（Let's Encrypt 通过它校验域名）。
#
# 用法（root 执行）：
#   bash certbot.sh 你的邮箱@example.com
set -euo pipefail

EMAIL="${1:?用法: $0 你的邮箱}"
DOMAINS=(api.ok123find.top file.ok123find.top api.sspacee.com poetry.sspacee.com)
WEBROOT=/var/www/letsencrypt
SSL_DIR=/etc/nginx/ssl
LIVE_DIR="/etc/letsencrypt/live/${DOMAINS[0]}"

if [[ $EUID -ne 0 ]]; then
    echo "请用 root 执行" >&2
    exit 1
fi

# 安装 certbot（CentOS / Alibaba Cloud Linux 用 yum，Debian/Ubuntu 用 apt）
if ! command -v certbot >/dev/null 2>&1; then
    if command -v yum >/dev/null 2>&1; then
        yum install -y epel-release || true
        yum install -y certbot
    else
        apt-get update && apt-get install -y certbot
    fi
fi

mkdir -p "$WEBROOT" "$SSL_DIR"

# 申请证书（webroot 方式：不会中断 nginx）
ARGS=()
for d in "${DOMAINS[@]}"; do ARGS+=(-d "$d"); done
certbot certonly --webroot -w "$WEBROOT" "${ARGS[@]}" \
    -m "$EMAIL" --agree-tos --non-interactive

# 复制到 nginx 使用的固定路径
cp -L "$LIVE_DIR/fullchain.pem" "$SSL_DIR/fullchain.pem"
cp -L "$LIVE_DIR/privkey.pem" "$SSL_DIR/privkey.pem"
chmod 600 "$SSL_DIR/privkey.pem"

# 续期后自动复制并重载 nginx
HOOK_DIR=/etc/letsencrypt/renewal-hooks/deploy
mkdir -p "$HOOK_DIR"
cat > "$HOOK_DIR/nginx-reload.sh" <<HOOK
#!/usr/bin/env bash
cp -L "$LIVE_DIR/fullchain.pem" "$SSL_DIR/fullchain.pem"
cp -L "$LIVE_DIR/privkey.pem" "$SSL_DIR/privkey.pem"
systemctl reload nginx
HOOK
chmod +x "$HOOK_DIR/nginx-reload.sh"

nginx -t && systemctl reload nginx
echo "证书已就绪。测试续期：certbot renew --dry-run"
echo "验证：curl -I https://${DOMAINS[0]}/vvv/api/version.json"
