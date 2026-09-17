ARG TAG=dev

FROM ghcr.io/misau-dis/sis-h-core:${TAG} AS frontend
FROM ghcr.io/misau-dis/sis-h-api:${TAG} AS api

FROM nginx:1.29.0-alpine

ARG CACHEBUST=1

COPY --from=frontend /var/www/html /var/www/html/frontend
COPY --from=api /var/www/html/api /var/www/html/api

COPY nginx.conf /etc/nginx/nginx.conf
