package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"sync/atomic"
	"time"
)

var version = "dev"

var (
	requests2xx atomic.Uint64
	requests5xx atomic.Uint64
	startedAt   = time.Now()
)

type response struct {
	Service string `json:"service"`
	Version string `json:"version"`
	Status  string `json:"status"`
}

func appHandler(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if os.Getenv("FAIL_MODE") == "true" {
		requests5xx.Add(1)
		w.WriteHeader(http.StatusServiceUnavailable)
		_ = json.NewEncoder(w).Encode(response{
			Service: "platform-demo",
			Version: version,
			Status:  "degraded",
		})
		return
	}

	requests2xx.Add(1)
	_ = json.NewEncoder(w).Encode(response{
		Service: "platform-demo",
		Version: version,
		Status:  "ok",
	})
}

func metricsHandler(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "text/plain; version=0.0.4; charset=utf-8")
	_, _ = fmt.Fprintf(w, `# HELP platform_demo_http_requests_total HTTP requests served by outcome class.
# TYPE platform_demo_http_requests_total counter
platform_demo_http_requests_total{code="2xx"} %d
platform_demo_http_requests_total{code="5xx"} %d
# HELP platform_demo_build_info Static build information for the running service.
# TYPE platform_demo_build_info gauge
platform_demo_build_info{version=%s} 1
# HELP platform_demo_process_uptime_seconds Process uptime in seconds.
# TYPE platform_demo_process_uptime_seconds gauge
platform_demo_process_uptime_seconds %.0f
`, requests2xx.Load(), requests5xx.Load(), strconv.Quote(version), time.Since(startedAt).Seconds())
}

func healthHandler(body string) http.HandlerFunc {
	return func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(body + "\n"))
	}
}

func newMux() *http.ServeMux {
	mux := http.NewServeMux()
	mux.HandleFunc("/", appHandler)
	mux.HandleFunc("/healthz", healthHandler("ok"))
	mux.HandleFunc("/readyz", healthHandler("ready"))
	mux.HandleFunc("/metrics", metricsHandler)
	return mux
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	server := &http.Server{
		Addr:              ":" + port,
		Handler:           newMux(),
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      10 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	log.Printf("platform-demo version=%s listening on :%s", version, port)
	if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Fatal(err)
	}
}
