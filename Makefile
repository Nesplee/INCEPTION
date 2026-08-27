DATA_PATH := $(shell grep '^DATA_PATH=' srcs/.env | cut -d= -f2)

all:
	mkdir -p $(DATA_PATH)/mariadb $(DATA_PATH)/wordpress $(DATA_PATH)/n8n
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
