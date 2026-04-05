# Build stage
FROM golang:1.22-alpine AS builder

WORKDIR /build

COPY tools/healthcheck/go.mod ./
RUN go mod download

COPY tools/healthcheck/ ./

# Build a fully static binary — no libc dependency
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-s -w" -trimpath -o healthcheck .


# Runtime stage — scratch image, absolute minimum attack surface
FROM scratch

# Copy CA certificates for HTTPS calls
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy the static binary
COPY --from=builder /build/healthcheck /healthcheck

ENTRYPOINT ["/healthcheck"]
