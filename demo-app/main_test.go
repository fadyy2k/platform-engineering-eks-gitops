package main

import (
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"
)

func TestVersionHasDefault(t *testing.T) {
	if version == "" {
		t.Fatal("version must not be empty")
	}
}

func TestAppAndMetrics(t *testing.T) {
	requests2xx.Store(0)
	requests5xx.Store(0)
	_ = os.Unsetenv("FAIL_MODE")

	r := httptest.NewRequest(http.MethodGet, "/", nil)
	w := httptest.NewRecorder()
	newMux().ServeHTTP(w, r)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", w.Code)
	}

	mr := httptest.NewRequest(http.MethodGet, "/metrics", nil)
	mw := httptest.NewRecorder()
	newMux().ServeHTTP(mw, mr)
	if !strings.Contains(mw.Body.String(), `platform_demo_http_requests_total{code="2xx"} 1`) {
		t.Fatalf("metrics did not include successful request counter: %s", mw.Body.String())
	}
}

func TestFailureMode(t *testing.T) {
	requests2xx.Store(0)
	requests5xx.Store(0)
	t.Setenv("FAIL_MODE", "true")

	r := httptest.NewRequest(http.MethodGet, "/", nil)
	w := httptest.NewRecorder()
	newMux().ServeHTTP(w, r)
	if w.Code != http.StatusServiceUnavailable {
		t.Fatalf("expected 503, got %d", w.Code)
	}

	mr := httptest.NewRequest(http.MethodGet, "/metrics", nil)
	mw := httptest.NewRecorder()
	newMux().ServeHTTP(mw, mr)
	if !strings.Contains(mw.Body.String(), `platform_demo_http_requests_total{code="5xx"} 1`) {
		t.Fatalf("metrics did not include failed request counter: %s", mw.Body.String())
	}
}
