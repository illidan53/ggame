# syntax=docker/dockerfile:1

FROM nginx:alpine

COPY deploy/nginx.conf /etc/nginx/nginx.conf
COPY build/web /usr/share/nginx/html

EXPOSE 3000

CMD ["nginx", "-g", "daemon off;"]
