#!/usr/bin/env bash
# 唐诗产品**静态域**的正式证书（Let's Encrypt，每域一张——与本机
# sspacee.com/jc.sspacee.com/gpt.sspacee.com 的 certbot 惯例一致；**不进**
# certbot.sh 的 SAN 组，那组是网关 8.217.122.83 上的 ok123find/api.sspacee 系，两回事）。
#
# ⚠ **2026-11-24 定案后本脚本不是正路**：`poetry.sspacee.com` 的 A 已在网关
#   8.217.122.83（三家公共 resolver 实测），PWA 走 deploy/nginx/poetry-gateway.conf，
#   证书进 certbot.sh 那张 SAN。**只有在把 A 改回应用机时才用这里**（每域一张 +
#   poetry-sspacee.conf 那一套）。留着是为了那条备选路不用重写脚本，别在网关上跑它
#   ——网关上跑会把 poetry 签成一张独立证书，跟 vpn.conf 用的 /etc/nginx/ssl 那张分家。
#
# 2026-11-24 规划调整：`api-poetry`/`agent-poetry` 两个名已放弃——Java 只对外一个
# API 域（`api.sspacee.com`，走 certbot.sh 那张 SAN 证书），内容生产 agent 永久不给公网
# 入口（见 docs/poetry/agents.md），所以这里只签静态域。
#
# 前提：**先加 DNS A 记录 → 应用机**（一台机两个公网 IP：64.32.22.150 与 104.160.191.87，
# 2026-11-24 确认；两个都通，写哪个都行），80 端口公网可达。
# 在应用机上以 root 执行：
#   bash certbot-poetry-sspacee.sh 你的邮箱@example.com
set -euo pipefail

EMAIL="${1:?用法: $0 你的邮箱}"
DOMAINS=(poetry.sspacee.com)
WEBROOT=/var/www/letsencrypt

if [[ $EUID -ne 0 ]]; then
    echo "请用 root 执行" >&2
    exit 1
fi

if ! command -v certbot >/dev/null 2>&1; then
    if command -v yum >/dev/null 2>&1; then
        yum install -y epel-release || true
        yum install -y certbot
    else
        apt-get update && apt-get install -y certbot
    fi
fi

mkdir -p "$WEBROOT"

for d in "${DOMAINS[@]}"; do
    if certbot certonly --webroot -w "$WEBROOT" -d "$d" \
        -m "$EMAIL" --agree-tos --non-interactive; then
        echo "OK  $d -> /etc/letsencrypt/live/$d/"
    else
        echo "FAIL $d —— DNS 未生效或未指向本机（64.32.22.150 / 104.160.191.87）？" >&2
        exit 1
    fi
done

# 证书落地后：nginx 的 poetry-sspacee.conf 按域引用 /etc/letsencrypt/live/<域>/，
# certbot 自带的 systemd timer 负责续期；reload 目标用绝对路径（该机 nginx 不在 PATH）：
echo "全部签发完成。测试续期：certbot renew --dry-run"
echo "放置 poetry-sspacee.conf / poetry-routes-sspacee.conf 后："
echo "  /root/local/nginx-1.24.0/sbin/nginx -t && /root/local/nginx-1.24.0/sbin/nginx -s reload"
echo "验证：curl -I https://poetry.sspacee.com/"
