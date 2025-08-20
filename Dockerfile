FROM node:18-alpine AS builder

RUN npm install -g elm

WORKDIR /app

COPY . .
RUN elm make src/Main.elm --output=public/elm.js


FROM nginx:1.27-alpine

RUN apk add --no-cache gettext

COPY --from=builder /app/public/ /usr/share/nginx/html/

COPY nginx.conf.template /etc/nginx/

CMD ["/bin/sh", "-c", "envsubst < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf && nginx -g 'daemon off;'"]