.PHONY: all help install preflight demo verify serve docker-up docker-down observer observer-docker observer-down observer-status

all: help

help:
	@echo "======================================================================"
	@echo "  QUANTUMSHIELD & SOVEREIGN DPI SUITE — HACKATHON COMMANDS"
	@echo "======================================================================"
	@echo "  make preflight       - Run 10-second system and consensus health check"
	@echo "  make demo            - Run live 6-pillar hackathon demonstration"
	@echo "  make observer        - Launch 1-click read-only observer node (:8545)"
	@echo "  make observer-docker - Launch observer node & local explorer in Docker"
	@echo "  make observer-down   - Stop observer node & local explorer"
	@echo "  make observer-status - Check local observer node sync status"
	@echo "  make verify          - Run cryptographic SDK unit tests (Python & JS)"
	@echo "  make serve           - Serve local portals on port 8080"
	@echo "  make docker-up       - Launch local portals & x402 gateway via Docker"
	@echo "  make docker-down     - Stop Docker services"
	@echo "======================================================================"

install:
	pip3 install -r sdk/python/requirements.txt
	cd apps/x402-gateway && npm install

preflight:
	./scripts/hackathon-preflight.sh

demo:
	python3 demo_hackathon_e2e.py

verify:
	python3 sdk/python/test_client.py
	node sdk/js/test.js

bench-stunt:
	python3 /opt/synapticchain/stunt_5wallets_256lanes.py

bench-amdahl:
	python3 /opt/synapticchain/amdahl_law_256lanes_10wallets.py

serve:
	@echo "Serving apps locally on http://localhost:8080..."
	python3 -m http.server 8080 --directory apps

docker-up:
	docker compose up -d

docker-down:
	docker compose down

observer:
	./scripts/run-observer.sh

observer-docker:
	docker compose -f docker-compose.observer.yml up -d

observer-down:
	docker compose -f docker-compose.observer.yml down

observer-status:
	./scripts/run-observer.sh --status
