# Contexto de construcción: la carpeta backend/ (incluye contracts/openapi.json).
#   docker build -t siaa-api backend

# ─── Stage 1: Build ────────────────────────────────────────────────────────
FROM golang:1.26-alpine AS builder

# Instalar dependencias del sistema
RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /build

# Copiar módulos primero para aprovechar el caché de Docker
COPY go.mod go.sum ./
RUN go mod download

# Copiar el código fuente
COPY . .

# Construir binario estático único (ADR-01, US-PLT-01 AC-01)
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o /dist/siaa-api ./cmd/api
# Worker de procesos periódicos (ADR-09): misma imagen, otro punto de entrada.
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o /dist/siaa-worker ./cmd/worker

# ─── Stage 2: Runtime ──────────────────────────────────────────────────────
# Imagen mínima: solo el binario, certificados CA, zonas horarias y el contrato OpenAPI
FROM scratch

ARG VERSION=dev
ARG COMMIT=local
ENV APP_VERSION=${VERSION} \
    APP_COMMIT=${COMMIT} \
    OPENAPI_SPEC_PATH=/contracts/openapi.json

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /dist/siaa-api /siaa-api
COPY --from=builder /dist/siaa-worker /siaa-worker
COPY --from=builder /build/contracts/openapi.json /contracts/openapi.json

EXPOSE 8080

# Usuario no-root por seguridad
USER 65534:65534

# CMD (no ENTRYPOINT) para que el worker use la misma imagen cambiando solo el comando:
#   docker run … /siaa-worker   ·   Render: dockerCommand: /siaa-worker
CMD ["/siaa-api"]
