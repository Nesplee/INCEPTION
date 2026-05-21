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

RUN	curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x /usr/local/bin/wp

RUN	chmod +x /init.sh

EXPOSE	9000

CMD	["/init.sh"]

