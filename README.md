# SIAA — Sistema Integrado de Asistencia Académica

> Plataforma de marcaje de asistencia por geolocalización GPS para entornos universitarios.

## Stack Tecnológico

| Capa | Tecnología | Versión |
|---|---|---|
| Backend API | Go + Echo | 1.23+ |
| Base de datos | MongoDB | 7.0 |
| App Móvil | Flutter (AOT) | 3.22+ |
| Consola Web | Flutter Web (WASM) | 3.22+ |
| Infraestructura | Docker + Traefik | — |
| CI/CD | GitHub Actions | — |

## Estructura del repositorio

```
siaa/
├── backend/              # API Go (hexagonal)
│   ├── cmd/api/          # Binario principal
│   ├── internal/
│   │   ├── domain/       # Dominio puro (sin dependencias externas)
│   │   ├── usecase/      # Casos de uso
│   │   ├── repository/   # Puertos + implementaciones Mongo
│   │   ├── transport/    # HTTP handlers, DTOs, middlewares
│   │   └── platform/     # Config, log, clock
│   ├── test/             # Pruebas unitarias e integración
│   ├── .env.example      # Variables de entorno de referencia
│   └── Dockerfile        # Imagen multietapa scratch
├── mobile/               # Flutter app (Android + iOS)
├── web/                  # Flutter Web consola administrativa
├── contracts/
│   └── openapi.yaml      # Contrato de API (fuente de verdad)
├── infra/docker/         # Traefik + producción
├── docker-compose.yml    # Entorno de desarrollo local
└── .github/workflows/    # CI/CD pipelines
```

## Inicio rápido (desarrollo local)

### Prerrequisitos

- Go 1.23+
- Flutter 3.22+
- Docker y Docker Compose

### 1. Clonar e instalar dependencias

```bash
git clone https://github.com/tu-org/siaa.git
cd siaa
```

### 2. Configurar entorno backend

```bash
cd backend
cp .env.example .env
# Editar .env con tus valores (MONGO_URI y JWT_SECRET son obligatorios)
```

### 3. Levantar servicios con Docker Compose

```bash
# Desde la raíz del proyecto
docker compose up -d mongo mailhog

# El backend en modo desarrollo (sin Docker):
cd backend
go run ./cmd/api
```

### 4. Verificar que el API está funcionando

```bash
curl http://localhost:8080/api/v1/health
# {"status":"ok","version":"0.0.1-dev",...}

curl http://localhost:8080/api/v1/health/ready
# {"status":"ok","dependencias":{"mongo":"ok"},...}
```

### 5. Levantar app móvil

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:8080/api/v1
```

### 6. Levantar consola web

```bash
cd web
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/api/v1
```

## Servicios de desarrollo

| Servicio | URL | Descripción |
|---|---|---|
| API | http://localhost:8080 | Backend principal |
| MongoDB | mongodb://localhost:27017 | Base de datos |
| MailHog UI | http://localhost:8025 | Ver correos de recuperación |
| Mongo Express | http://localhost:8081 | Explorador de MongoDB |

## Ejecutar pruebas

```bash
# Backend — pruebas unitarias
cd backend
go test ./... -v -race

# Con cobertura
go test ./... -coverprofile=coverage.out -covermode=atomic
go tool cover -html=coverage.out -o coverage.html

# Flutter
cd mobile && flutter test
cd web && flutter test
```

## Variables de entorno obligatorias (Backend)

| Variable | Descripción |
|---|---|
| `MONGO_URI` | URI de conexión MongoDB |
| `JWT_SECRET` | Secreto HMAC (mínimo 32 caracteres) |

Ver [`backend/.env.example`](backend/.env.example) para la lista completa.

## ADRs (Decisiones de Arquitectura)

| ADR | Decisión |
|---|---|
| ADR-01 | Stack: Go + Flutter. Separación de frontend por canal (mobile vs web) |
| ADR-02 | Arquitectura hexagonal en backend. `domain` no tiene dependencias externas |
| ADR-03 | El tiempo es una dependencia inyectable (`Clock`). Sin `time.Now()` en dominio |
| ADR-04 | Coordenadas geográficas en formato GeoJSON `[longitud, latitud]` |
| ADR-07 | Idempotencia de marcajes vía índice único parcial (excluye anulados) |

## Sprint 1 — Progreso

| Historia | Estado |
|---|---|
| US-PLT-01 Esqueleto API Go | ✅ Completo |
| US-PLT-02 CI con cobertura | ✅ Completo |
| US-PLT-03 Esqueleto Flutter móvil | ✅ Completo |
| US-PLT-04 Esqueleto Flutter web | ✅ Completo |
| US-AUT-01 Login JWT | ✅ Completo |
| US-AUT-04 Recuperación de contraseña | ✅ Completo |

## Licencia

Propietario — © 2024 SIAA. Todos los derechos reservados.
