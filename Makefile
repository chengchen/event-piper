POSTGRES_IMAGE = postgres:10.6
SERVICE_IMAGE  = local/event-piper:latest

all: build clean

build:
	docker run -d --name=postgresql -e POSTGRES_USER=event_piper -e POSTGRES_PASSWORD=event_piper -e POSTGRES_DB=event_piper \
		-v=${PWD}/postgresql:/docker-entrypoint-initdb.d:ro -p 5432:5432 $(POSTGRES_IMAGE)
	docker build --network=container:postgresql -t $(SERVICE_IMAGE) .

clean:
	docker rm -f postgresql

run:
	docker network create event_piper_network || true
	docker network connect event_piper_network postgresql || true
	docker run --network=event_piper_network --name=event-piper -p 4000:4000 local/event-piper:latest
