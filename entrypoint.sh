#!/bin/bash
set -e

export PORT="${PORT:-8080}"

if [ -z "$UUID" ]; then
  UUID=$(xray uuid)
  echo "WARNING: UUID variable is not set. Temporary UUID generated: $UUID"
fi

SECRET_PATH="${SECRET_PATH:-/api/v2/telemetry/}"
case "$SECRET_PATH" in
  /*) ;;
  *) SECRET_PATH="/$SECRET_PATH" ;;
esac
case "$SECRET_PATH" in
  */) ;;
  *) SECRET_PATH="$SECRET_PATH/" ;;
esac
export SECRET_PATH

mkdir -p /etc/xray

cat <<EOF > /etc/xray/config.json
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 10002,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${UUID}"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "xhttp",
        "security": "none",
        "xhttpSettings": {
          "path": "${SECRET_PATH}",
          "mode": "auto",
          "xPaddingBytes": "100-1000"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls", "quic"]
      }
    }
  ],
  "outbounds": [
    {
      "tag": "direct",
      "protocol": "freedom"
    },
    {
      "tag": "block",
      "protocol": "blackhole"
    }
  ],
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [
      {
        "type": "field",
        "ip": [
          "127.0.0.0/8",
          "10.0.0.0/8",
          "172.16.0.0/12",
          "192.168.0.0/16",
          "::1/128",
          "fc00::/7"
        ],
        "outboundTag": "block"
      }
    ]
  }
}
EOF

envsubst '${PORT} ${SECRET_PATH}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

xray run -test -config /etc/xray/config.json
nginx -t

xray run -config /etc/xray/config.json &
XRAY_PID=$!

nginx -g "daemon off;" &
NGINX_PID=$!

wait -n $XRAY_PID $NGINX_PID
exit $?