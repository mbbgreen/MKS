FROM nginx:alpine

RUN apk add --no-cache curl unzip gettext bash ca-certificates

COPY site/ /usr/share/nginx/html/
COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY entrypoint.sh /entrypoint.sh

RUN sed -i "1s/^$(printf '\357\273\277')//" /entrypoint.sh /etc/nginx/nginx.conf.template && \
    sed -i 's/\r$//' /entrypoint.sh /etc/nginx/nginx.conf.template && \
    chmod +x /entrypoint.sh

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]