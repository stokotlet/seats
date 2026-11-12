-include .env
export

.PHONY: run
run:
	go run ./cmd/booking-api

.PHONY: dev
dev:
	air
