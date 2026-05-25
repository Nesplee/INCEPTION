FROM	debian:bullseye

RUN	apt-get update && apt-get install -y mariadb-server && rm -rf /var/lib/apt/lists/*

RUN	mkdir -p /run/mysqld && chown -R mysql:mysql /run/mysqld /var/lib/mysql

COPY	conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY	tools/init.sh	/init.sh

RUN	chmod +x /init.sh

EXPOSE	3306

CMD	["/init.sh"]

