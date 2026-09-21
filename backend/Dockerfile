# ─── Stage 1: Build ────────────────────────────────────────────────────────
FROM golang:1.23-alpine AS builder

# Instalar dependencias del sistema
RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /build

# Copiar módulos primero para aprovechar el caché de Docker
COPY go.mod go.sum ./
RUN go mod download

# Copiar el código fuente
COPY . .

# Construir binario estático único (ADR-01, US-PLT-01 AC-01)
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s -X main.Version=${VERSION:-dev} -X main.Commit=${COMMIT:-local}" \
    -o /dist/siaa-api \
    ./cmd/api

# ─── Stage 2: Runtime ──────────────────────────────────────────────────────
# Imagen mínima: solo el binario y certificados CA
FROM scratch

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /dist/siaa-api /siaa-api

EXPOSE 8080

# Usuario no-root por seguridad
USER 65534:65534

ENTRYPOINT ["/siaa-api"]
