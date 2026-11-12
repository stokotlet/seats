package httpapi

import (
	"context"
	"net/http"
	"time"
)

type Pinger interface {
	Ping(context.Context) error
}

func NewRouter(pool Pinger) http.Handler {
	mux := http.NewServeMux()

	healthHandler := func(w http.ResponseWriter, req *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("im health"))
	}

	readyHandler := func(w http.ResponseWriter, r *http.Request) {
		timeoutCtx, cancel := context.WithTimeout(r.Context(), time.Millisecond*99)
		defer cancel()
		err := pool.Ping(timeoutCtx)

		if err != nil {
			w.WriteHeader(http.StatusServiceUnavailable)
		} else {
			w.Write([]byte("im ready"))
		}
	}

	mux.HandleFunc("GET /healthz", healthHandler)
	mux.HandleFunc("GET /readyz", readyHandler)

	return mux
}
