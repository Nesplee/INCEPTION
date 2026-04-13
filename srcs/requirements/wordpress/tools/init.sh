#!/bin/bash

if [ ! -f /usr/local/bin/wp ]; then
	wget		https://wordpress.org/latest.tar.gz -P /var/www/html
	tar -xzf	/var/www/html/latest.tar.gz -C /var/www/html
	rm		/var/www/html/latest.tar.gz

	cp		/var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php

	sed -i		"s|database_name_here|${MYSQL_DATABASE}|" /var/www/html/wordpress/wp-config.php
	sed -i		"s|username_here|${MYSQL_USER}|" /var/www/html/wordpress/wp-config.php
	sed -i		"s|password_here|${MYSQL_PASSWORD}|" /var/www/html/wordpress/wp-config.php
	sed -i		"s|localhost|mariadb|" /var/www/html/wordpress/wp-config.php

	curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
	chmod +x wp-cli.phar
	mv wp-cli.phar /usr/local/bin/wp

	until mysqladmin ping -h mariadb -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent; do
		echo "Waiting for MariaDB to be ready.."
		sleep 2
	done

	cd /var/www/html/wordpress
	wp core install \
		--url="${DOMAIN_NAME}" \
		--title="Inception" \
		--admin_user="${WP_ADMIN_USER}" \
		--admin_password="${WP_ADMIN_PASSWORD}" \
		--admin_email="${WP_ADMIN_EMAIL}" \
		--allow-root

	wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
		--user_pass="${WP_USER_PASSWORD}" \
		--role=author \
		--allow-root

	wp config set WP_REDIS_HOST redis --allow-root
	wp config set WP_REDIS_PORT 6379 --raw --allow-root
	wp plugin install redis-cache --activate --allow-root
	wp redis enable --allow-root

fi

mkdir -p	/run/php

exec /usr/sbin/php-fpm7.4 -F
