# SPDX-License-Identifier: AGPL-3.0-only
# Prepared only. Resolve and pin the approved image digest before deployment.
FROM nginxinc/nginx-unprivileged:stable-alpine
COPY infra/xcenter/nginx.conf /etc/nginx/conf.d/default.conf
COPY web/dist /usr/share/nginx/html
USER 101:101
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s CMD wget -q -O /dev/null http://127.0.0.1:8080/health || exit 1
