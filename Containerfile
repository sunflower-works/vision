# Multi-stage Containerfile for sunflower-vision
# Supports building individual binaries via --build-arg BIN=vision-cli (default)
# Optimized for small final image size and reproducible builds.

ARG GO_VERSION=1.24
ARG BIN=vision-cli
ARG TARGETOS=linux
ARG TARGETARCH=amd64
ARG VERSION=dev
ARG BUILD_DATE
ARG GIT_SHA

# Builder stage
FROM golang:${GO_VERSION}-alpine AS builder
RUN apk add --no-cache ca-certificates tzdata build-base git
WORKDIR /src
# Pre-copy go.mod/go.sum for caching
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download
COPY . .
# Build with minimal binary (static when possible)
ENV CGO_ENABLED=0
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -trimpath -ldflags="-s -w -X github.com/sunflower-works/vision/pkg/vision/version.Version=${VERSION}" -o /out/${BIN} ./cmd/${BIN}

# Runtime stage (distroless static base -> use scratch for pure static)
FROM scratch AS runtime
# Certificates & timezone
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
# Binary; normalize to /usr/local/bin/app so entrypoint uniform across BIN variants
ARG BIN=vision-cli
ARG VERSION=dev
ARG BUILD_DATE
ARG GIT_SHA
LABEL org.opencontainers.image.title="sunflower-vision" \
      org.opencontainers.image.description="Composable computer vision toolkit" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${GIT_SHA}" \
      org.opencontainers.image.source="https://github.com/sunflower-works/vision" \
      org.opencontainers.image.licenses="MIT"
COPY --from=builder /out/${BIN} /usr/local/bin/app
ENTRYPOINT ["/usr/local/bin/app"]
CMD []
