FROM node:18-alpine AS builder

# Install Elm
RUN npm install -g elm

WORKDIR /app

# Copy everything first
COPY . .

# Build exactly like your local command (without optimize for now)
RUN elm make src/Main.elm --output=public/elm.js

# Production server
FROM nginx:alpine

# Copy the entire public directory (which contains elm.js, index.html, and styles.css)
COPY --from=builder /app/public/ /usr/share/nginx/html/

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