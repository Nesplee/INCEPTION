FROM	debian:bullseye

RUN	apt-get update && apt-get install -y redis && rm -rf /var/lib/apt/lists/*

COPY	tools/redis.conf /etc/redis/redis.conf

EXPOSE	6379

CMD	["redis-server", "/etc/redis/redis.conf"]


