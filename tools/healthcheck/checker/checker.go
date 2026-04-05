// Package checker implements concurrent HTTP health checking with
// retry logic and configurable timeouts.
package checker

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"sync"
	"time"
)

// Config holds the runtime configuration for health checks.
type Config struct {
	Timeout  time.Duration // per-request HTTP timeout
	Retries  int           // max retry attempts per URL
	Interval time.Duration // wait between retries
	Logger   *slog.Logger
}

// Result holds the outcome of a single endpoint check.
type Result struct {
	URL     string
	Healthy bool
	Latency time.Duration
	Status  int
	Error   error
}

// CheckAll runs health checks for all URLs concurrently and
// returns one Result per URL in the same order as the input slice.
func CheckAll(urls []string, cfg Config) []Result {
	results := make([]Result, len(urls))
	var wg sync.WaitGroup

	for i, url := range urls {
		wg.Add(1)
		go func(idx int, u string) {
			defer wg.Done()
			results[idx] = checkWithRetry(u, cfg)
		}(i, url)
	}

	wg.Wait()
	return results
}

// checkWithRetry attempts an HTTP GET up to cfg.Retries times,
// returning the last result if all attempts fail.
func checkWithRetry(url string, cfg Config) Result {
	var last Result
	for attempt := 1; attempt <= cfg.Retries; attempt++ {
		cfg.Logger.Debug("checking endpoint",
			"url", url,
			"attempt", attempt,
			"max", cfg.Retries,
		)
		last = doCheck(url, cfg.Timeout)
		if last.Healthy {
			return last
		}
		if attempt < cfg.Retries {
			cfg.Logger.Warn("endpoint unhealthy, retrying",
				"url", url,
				"attempt", attempt,
				"wait", cfg.Interval,
			)
			time.Sleep(cfg.Interval)
		}
	}
	return last
}

// doCheck performs a single HTTP GET and returns a Result.
func doCheck(url string, timeout time.Duration) Result {
	client := &http.Client{
		Timeout: timeout,
		// Don't follow redirects — a redirect could mask a 5xx on the real endpoint
		CheckRedirect: func(_ *http.Request, _ []*http.Request) error {
			return http.ErrUseLastResponse
		},
	}

	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return Result{URL: url, Healthy: false, Error: fmt.Errorf("build request: %w", err)}
	}

	start := time.Now()
	resp, err := client.Do(req)
	latency := time.Since(start)

	if err != nil {
		return Result{URL: url, Healthy: false, Latency: latency, Error: err}
	}
	defer resp.Body.Close()

	healthy := resp.StatusCode >= 200 && resp.StatusCode < 300
	var checkErr error
	if !healthy {
		checkErr = fmt.Errorf("non-2xx status: %d", resp.StatusCode)
	}

	return Result{
		URL:     url,
		Healthy: healthy,
		Latency: latency,
		Status:  resp.StatusCode,
		Error:   checkErr,
	}
}
