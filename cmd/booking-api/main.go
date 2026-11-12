package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"os"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stokotlet/seats/internal/httpapi"
)

func main() {
	ctx := context.Background()
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	err := run(ctx, logger)

	if err != nil {
		logger.Error("run failed", "err", err)
		os.Exit(1)
	}
}

func run(ctx context.Context, logger *slog.Logger) error {
	timeoutCtx, cancel := context.WithTimeout(ctx, time.Second*5)
	defer cancel()

	dbUrl := os.Getenv("DATABASE_URL")
	addr := os.Getenv("HTTP_ADDR")

	if addr == "" {
		addr = ":8080"

	}

	if dbUrl == "" {
		return errors.New("DATABASE_URL is not found")
	}

	pool, err := pgxpool.New(timeoutCtx, dbUrl)

	if err != nil {
		return fmt.Errorf("create pool: %w", err)
	}

	defer pool.Close()

	err = pool.Ping(timeoutCtx)

	if err != nil {
		return fmt.Errorf("check pool connection: %w", err)
	}

	mux := httpapi.NewRouter(pool)

	srv := http.Server{
		Addr:              addr,
		Handler:           mux,
		ReadHeaderTimeout: time.Second * 3,
		ReadTimeout:       time.Second * 15,
		WriteTimeout:      time.Second * 30,
		IdleTimeout:       time.Second * 30,
	}

	l, err := net.Listen("tcp", addr)

	if err != nil {
		return fmt.Errorf("port listen: %w", err)
	}

	logger.Info("server started", "addr", addr)

	err = srv.Serve(l)

	if err != nil {
		return fmt.Errorf("server init: %w", err)
	}

	return nil
}
