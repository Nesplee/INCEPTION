FROM	debian:bullseye

RUN	apt-get update && apt-get install -y \
	nginx \
	openssl \
	&& rm -rf /var/lib/apt/lists/*

RUN	openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-keyout	/etc/ssl/private/nginx.key \
	-out	/etc/ssl/certs/nginx.crt \
	-subj	"/C=CH/ST=Vaud/L=Lausanne/O=42/CN=dinguyen.42.fr"

COPY	conf/nginx.conf /etc/nginx/sites-available/default

EXPOSE	443

CMD	["nginx", "-g", "daemon off;"]
