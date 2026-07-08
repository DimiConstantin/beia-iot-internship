PROJECT_DIR := $(shell pwd)

.PHONY: help up down restart logs ps deploy anchor verify services stop-services status clean

help:
	@echo "Available commands:"
	@echo "  make up              Start Docker services"
	@echo "  make down            Stop Docker services"
	@echo "  make restart         Restart Docker services"
	@echo "  make logs            Show Docker logs"
	@echo "  make ps              Show Docker containers"
	@echo "  make deploy          Deploy blockchain smart contract"
	@echo "  make anchor          Run blockchain anchoring script manually"
	@echo "  make verify          Verify blockchain batch 0"
	@echo "  make services        Start systemd project services"
	@echo "  make stop-services   Stop systemd project services"
	@echo "  make status          Show systemd service status"
	@echo "  make clean           Remove local generated state files"

up:
	docker compose up -d

down:
	docker compose down

restart:
	docker compose down
	docker compose up -d

logs:
	docker compose logs -f

ps:
	docker compose ps

deploy:
	cd blockchain && python3 deploy.py

anchor:
	cd blockchain && python3 anchor.py

verify:
	cd blockchain && python3 verify.py 0

services:
	sudo systemctl start iot-sync.service
	sudo systemctl start iot-anchor.service
	sudo systemctl start iot-provider.service

stop-services:
	sudo systemctl stop iot-sync.service || true
	sudo systemctl stop iot-anchor.service || true
	sudo systemctl stop iot-provider.service || true

status:
	systemctl status iot-sync.service --no-pager || true
	systemctl status iot-anchor.service --no-pager || true
	systemctl status iot-provider.service --no-pager || true

clean:
	rm -f local-sync/.sync-state
	rm -f blockchain/.anchor-state
	rm -f blockchain/deployed.json
