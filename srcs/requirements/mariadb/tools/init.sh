#!/bin/bash

if [ ! -f /var/lib/mysql/.inception_initialized ]; then
	mkdir -p /run/mysqld
	chown -R mysql:mysql /run/mysqld /var/lib/mysql

	mysql_install_db --user=mysql --datadir=/var/lib/mysql

	cat > /tmp/init.sql <<EOF

USE mysql;
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

	/usr/sbin/mysqld --user=mysql --bootstrap < /tmp/init.sql
	rm /tmp/init.sql
	touch /var/lib/mysql/.inception_initialized
fi

exec /usr/sbin/mysqld --user=mysql --console 
