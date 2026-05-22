all:
	mkdir -p /home/dinguyen/data/mariadb /home/dinguyen/data/wordpress /home/dinguyen/data/n8n
	docker compose -f srcs/docker-compose.yml up -d --build

down:
	docker compose -f srcs/docker-compose.yml down

re:
	docker compose -f srcs/docker-compose.yml up -d --build --force-recreate

clean:
	docker compose -f srcs/docker-compose.yml down -v

fclean:	clean
	docker system prune -af

.PHONY: all down re clean fclean
