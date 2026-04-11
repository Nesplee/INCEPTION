FROM	debian:bullseye

RUN	apt-get update && apt-get install -y \
	php php-mysqli wget \
	&& rm -rf /var/lib/apt/lists/*

RUN	wget -q https://www.adminer.org/latest.php -O /var/www/html/adminer.php

EXPOSE	8081

CMD	["php", "-S", "0.0.0.0:8081", "-t", "/var/www/html"]
