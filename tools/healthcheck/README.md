# EKS Service Healthcheck Tool

A lightweight Go CLI that polls one or more Kubernetes service endpoints
concurrently and reports their health status. Designed for use as a
post-deployment validation step in CI/CD pipelines or as a Kubernetes Job
after an ArgoCD sync.

## Why Go?

Go is the language of the Kubernetes ecosystem — `kubectl`, `helm`,
`ArgoCD`, and the Kubernetes API server are all written in Go. A Go-based
operational tool signals familiarity with the cloud-native toolchain.

## Build

```bash
cd tools/healthcheck
go build -o healthcheck .
```

Or as a minimal scratch container:

```bash
docker build -f tools/healthcheck/Dockerfile -t eks-healthcheck:latest .
```

## Usage

```bash
# Check a single endpoint
./healthcheck --url http://app-svc.app-dev.svc.cluster.local/health

# Check multiple endpoints concurrently
./healthcheck \
  --url http://app-svc.app-dev.svc.cluster.local/health \
  --url http://app-svc.app-prod.svc.cluster.local/health \
  --timeout 30s \
  --retries 5 \
  --interval 5s

# Verbose mode (debug logging)
./healthcheck --url http://my-service/health --verbose
```

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | All endpoints returned 2xx |
| `1` | One or more endpoints failed or were unreachable |

## Use in CI/CD (GitHub Actions)

```yaml
- name: Post-deploy health check
  run: |
    go run ./tools/healthcheck/... \
      --url ${{ env.APP_DEV_URL }}/health \
      --retries 10 \
      --interval 10s
```

## Use as a Kubernetes Job

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: post-deploy-healthcheck
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: healthcheck
          image: your-ecr/eks-healthcheck:latest
          args:
            - --url
            - http://app-svc.app-prod.svc.cluster.local/health
            - --retries
            - "10"
            - --interval
            - "10s"
```

## Run Tests

```bash
cd tools/healthcheck
go test ./... -v -race
```
