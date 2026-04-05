package checker_test

import (
	"log/slog"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
	"time"

	"github.com/kumarrajapuvvalla-bit/terraform-aws-eks-platform/tools/healthcheck/checker"
)

var silentLogger = slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelError}))

func cfg(retries int) checker.Config {
	return checker.Config{
		Timeout:  5 * time.Second,
		Retries:  retries,
		Interval: 10 * time.Millisecond,
		Logger:   silentLogger,
	}
}

// ── doCheck via CheckAll (single URL) ─────────────────────────────────

func TestCheckAll_HealthyEndpoint(t *testing.T) {
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))
	defer ts.Close()

	results := checker.CheckAll([]string{ts.URL}, cfg(1))

	if len(results) != 1 {
		t.Fatalf("expected 1 result, got %d", len(results))
	}
	if !results[0].Healthy {
		t.Errorf("expected healthy=true for 200 response")
	}
	if results[0].Error != nil {
		t.Errorf("expected nil error, got %v", results[0].Error)
	}
}

func TestCheckAll_UnhealthyEndpoint_Returns5xx(t *testing.T) {
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusInternalServerError)
	}))
	defer ts.Close()

	results := checker.CheckAll([]string{ts.URL}, cfg(1))

	if results[0].Healthy {
		t.Errorf("expected healthy=false for 500 response")
	}
	if results[0].Status != 500 {
		t.Errorf("expected status 500, got %d", results[0].Status)
	}
}

func TestCheckAll_UnreachableURL(t *testing.T) {
	results := checker.CheckAll([]string{"http://localhost:19999/health"}, cfg(1))

	if results[0].Healthy {
		t.Errorf("expected healthy=false for unreachable URL")
	}
	if results[0].Error == nil {
		t.Errorf("expected non-nil error for unreachable URL")
	}
}

func TestCheckAll_MultipleURLs_ConcurrentResults(t *testing.T) {
	healthy := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))
	defer healthy.Close()

	unhealthy := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusServiceUnavailable)
	}))
	defer unhealthy.Close()

	urls := []string{healthy.URL, unhealthy.URL}
	results := checker.CheckAll(urls, cfg(1))

	if len(results) != 2 {
		t.Fatalf("expected 2 results, got %d", len(results))
	}
	if !results[0].Healthy {
		t.Errorf("first result should be healthy")
	}
	if results[1].Healthy {
		t.Errorf("second result should be unhealthy")
	}
}

func TestCheckAll_RetrySucceedsOnSecondAttempt(t *testing.T) {
	attempt := 0
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		attempt++
		if attempt < 2 {
			w.WriteHeader(http.StatusServiceUnavailable)
		} else {
			w.WriteHeader(http.StatusOK)
		}
	}))
	defer ts.Close()

	results := checker.CheckAll([]string{ts.URL}, cfg(3))

	if !results[0].Healthy {
		t.Errorf("expected healthy=true after retry succeeded")
	}
}

func TestCheckAll_LatencyIsPopulated(t *testing.T) {
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))
	defer ts.Close()

	results := checker.CheckAll([]string{ts.URL}, cfg(1))

	if results[0].Latency == 0 {
		t.Errorf("expected non-zero latency")
	}
}

func TestCheckAll_OrderPreserved(t *testing.T) {
	// Checks that results come back in input order even with concurrent execution
	servers := make([]*httptest.Server, 5)
	urls := make([]string, 5)
	for i := range servers {
		idx := i
		servers[i] = httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
			// Odd-indexed servers return 503, even return 200
			if idx%2 != 0 {
				w.WriteHeader(http.StatusServiceUnavailable)
			} else {
				w.WriteHeader(http.StatusOK)
			}
		}))
		defer servers[i].Close()
		urls[i] = servers[i].URL
	}

	results := checker.CheckAll(urls, cfg(1))

	for i, r := range results {
		wantHealthy := i%2 == 0
		if r.Healthy != wantHealthy {
			t.Errorf("result[%d] healthy=%v, want %v", i, r.Healthy, wantHealthy)
		}
	}
}
