-include .env
export

.PHONY: run
run:
	go run ./cmd/booking-api

.PHONY: dev
dev:
	air

.PHONY: seed
seed:
	docker compose exec -T postgres psql "$(DATABASE_URL)" -X -q -1 -v ON_ERROR_STOP=1 < seeds/dev.sql
