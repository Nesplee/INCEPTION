FROM	debian:bullseye

RUN	apt-get update && apt-get install -y nginx && rm -rf /var/lib/apt/lists/*

COPY	tools/index.html /var/www/html/index.html

EXPOSE	8080

CMD	["nginx", "-g", "daemon off;"]
