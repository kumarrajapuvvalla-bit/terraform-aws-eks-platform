// healthcheck - EKS Service Health Check CLI
//
// A lightweight Go CLI tool that polls one or more Kubernetes service
// endpoints and reports their health status. Designed to run as a
// post-deployment validation step in CI/CD pipelines or as a Kubernetes
// Job after ArgoCD syncs.
//
// Usage:
//
//	./healthcheck --url http://app-svc.app-dev.svc.cluster.local/health \
//	              --url http://app-svc.app-prod.svc.cluster.local/health \
//	              --timeout 30s \
//	              --retries 5 \
//	              --interval 5s
//
// Exit codes:
//
//	0  all endpoints healthy
//	1  one or more endpoints unhealthy or unreachable
package main

import (
	"flag"
	"fmt"
	"log/slog"
	"os"
	"time"

	"github.com/kumarrajapuvvalla-bit/terraform-aws-eks-platform/tools/healthcheck/checker"
)

// multiFlag allows --url to be specified multiple times
type multiFlag []string

func (m *multiFlag) String() string  { return fmt.Sprintf("%v", *m) }
func (m *multiFlag) Set(v string) error { *m = append(*m, v); return nil }

func main() {
	var urls multiFlag
	timeout := flag.Duration("timeout", 30*time.Second, "per-request HTTP timeout")
	retries := flag.Int("retries", 3, "number of retry attempts per URL")
	interval := flag.Duration("interval", 5*time.Second, "wait between retries")
	verbose := flag.Bool("verbose", false, "enable verbose logging")
	flag.Var(&urls, "url", "endpoint to check (repeatable)")
	flag.Parse()

	if len(urls) == 0 {
		fmt.Fprintln(os.Stderr, "error: at least one --url is required")
		flag.Usage()
		os.Exit(1)
	}

	level := slog.LevelInfo
	if *verbose {
		level = slog.LevelDebug
	}
	logger := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{Level: level}))

	cfg := checker.Config{
		Timeout:  *timeout,
		Retries:  *retries,
		Interval: *interval,
		Logger:   logger,
	}

	results := checker.CheckAll(urls, cfg)

	allHealthy := true
	fmt.Println("\n=== Health Check Report ===")
	for _, r := range results {
		status := "OK   "
		if !r.Healthy {
			status = "FAIL "
			allHealthy = false
		}
		fmt.Printf("  [%s] %s  (latency: %s)\n", status, r.URL, r.Latency.Round(time.Millisecond))
		if r.Error != nil {
			fmt.Printf("         error: %v\n", r.Error)
		}
	}
	fmt.Println()

	if !allHealthy {
		logger.Error("one or more endpoints are unhealthy")
		os.Exit(1)
	}
	logger.Info("all endpoints healthy")
}
