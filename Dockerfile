FROM node:18-alpine AS builder

# Install Elm
RUN npm install -g elm

WORKDIR /app

# Copy Elm files
COPY elm.json ./
COPY src/ ./src/

# Build Elm app to root directory first
RUN elm make src/Main.elm --output=elm.js --optimize

# Copy static files
COPY public/ ./public/
COPY index.html ./

# Production server
FROM nginx:alpine

# Copy the built Elm JS file
COPY --from=builder /app/elm.js /usr/share/nginx/html/

# Copy static files
COPY --from=builder /app/public/ /usr/share/nginx/html/
COPY --from=builder /app/index.html /usr/share/nginx/html/

# Simple nginx config
RUN echo 'events { worker_connections 1024; } \
http { \
    include /etc/nginx/mime.types; \
    default_type application/octet-stream; \
    server { \
        listen 80; \
        root /usr/share/nginx/html; \
        index index.html; \
        location / { \
            try_files $uri $uri/ /index.html; \
        } \
    } \
}' > /etc/nginx/nginx.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]