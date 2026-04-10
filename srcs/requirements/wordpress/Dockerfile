FROM	debian:bullseye

RUN	apt-get update && apt-get install -y \
	php7.4 \
	php7.4-fpm \
	php7.4-mysql \
	wget \
	curl \
	mariadb-client \
	&& rm -rf /var/lib/apt/lists/*

COPY	conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf
COPY	tools/init.sh /init.sh

RUN	chmod +x /init.sh

EXPOSE	9000

CMD	["/init.sh"]

