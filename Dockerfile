FROM elmlang/elm:0.19.1 as builder

WORKDIR /app

COPY elm.json ./
COPY src ./src/
COPY public ./public/

RUN elm make src/Main.elm --output=public/elm.js

FROM nginx:1.27-alpine

RUN apk add --no-cache gettext

COPY nginx.conf.template /etc/nginx/

COPY --from=builder /app/public /usr/share/nginx/html

CMD ["/bin/sh", "-c", "envsubst < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf && nginx -g 'daemon off;'"]