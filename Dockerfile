FROM nginx:alpine

RUN apk add --no-cache curl unzip gettext bash ca-certificates

RUN ARCH=$(uname -m) && \
    case "$ARCH" in \
        x86_64) XRAY_ARCH="64" ;; \
        aarch64|arm64) XRAY_ARCH="arm64-v8a" ;; \
        *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
    esac && \
    curl -fsSL -o /tmp/pkg.zip "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-${XRAY_ARCH}.zip" && \
    unzip -o /tmp/pkg.zip xray -d /tmp/ && \
    mv /tmp/xray /usr/local/bin/edge-worker && \
    chmod +x /usr/local/bin/edge-worker && \
    rm -f /tmp/pkg.zip

COPY site/ /usr/share/nginx/html/
COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY entrypoint.sh /entrypoint.sh

RUN sed -i "1s/^$(printf '\357\273\277')//" /entrypoint.sh /etc/nginx/nginx.conf.template && \
    sed -i 's/\r$//' /entrypoint.sh /etc/nginx/nginx.conf.template && \
    chmod +x /entrypoint.sh

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]