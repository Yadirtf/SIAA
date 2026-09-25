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
| Métricas | http://localhost:8080/metrics | Métricas Prometheus (latencia, throughput) |
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

## Estado de Implementación y Progreso del Proyecto

### Resumen General de Épicas

| Épica | Descripción | Cobertura | Estado |
|---|---|---|---|
| **EP-00** | Fundaciones de plataforma, observabilidad y pipeline CI/CD | 100% | ✅ Completo |
| **EP-01** | Identidad, autenticación robusta, sesión y dispositivo confiable | 100% | ✅ Completo |
| **EP-02** | Roles, permisos granulares y control de acceso (RBAC / ABAC) | 100% | ✅ Completo |
| **EP-03** | Cartografía GPS de espacios, buffers geodésicos y topología | 100% | ✅ Completo |
| **EP-04** | Estructura académica, motor de sesiones recurrentes y excepciones | 100% | ✅ Completo |
| **EP-05** | Parametrización jerárquica institucional y alertas automáticas | 100% | ✅ Completo |
| **EP-06** | Marcaje de asistencia, telemetría y geocercas activas | 100% | ✅ Completo |
| **EP-07** | Justificaciones, permisos y circuito de aprobaciones | — | ⏳ Backlog |
| **EP-08** | Reportes institucionales, analítica y notificaciones | — | ⏳ Backlog |

### Detalle de Historias de Usuario Implementadas (EP-00 a EP-05)

#### EP-00 — Fundaciones de Plataforma
| Historia | Descripción | Estado |
|---|---|---|
| US-PLT-01 | Esqueleto API Go con arquitectura hexagonal y endpoints health check | ✅ Completo |
| US-PLT-02 | Pipeline CI/CD con ejecución automatizada de pruebas y quality gates | ✅ Completo |
| US-PLT-03 | Esqueleto Flutter móvil (Clean Architecture, BLoC, temas y Certificate Pinning) | ✅ Completo |
| US-PLT-04 | Esqueleto Flutter web (consola administrativa SPA/WASM) | ✅ Completo |
| US-PLT-05 | Observabilidad con endpoint Prometheus (`/metrics`) y tracking de latencia p95/p99 | ✅ Completo |
| US-PLT-06 | Pruebas de carga y capacidad de concurrencia bajo picos de marcaje | ✅ Completo |

#### EP-01 — Identidad, Sesión y Dispositivo Confiable
| Historia | Descripción | Estado |
|---|---|---|
| US-AUT-01 | Login JWT institucional con rotación de par de tokens (Access + Refresh) | ✅ Completo |
| US-AUT-02 | Bloqueo progresivo y límite de tasa por IP/cuenta para protección contra fuerza bruta | ✅ Completo |
| US-AUT-03 | Registro, aprobación y vinculación estricta de dispositivo móvil confiable | ✅ Completo |
| US-AUT-04 | Recuperación segura de contraseña con token criptográfico HMAC-SHA256 | ✅ Completo |
| US-AUT-05 | Conmutación de contexto multi-rol con revocación y reemisión de tokens | ✅ Completo |
| US-AUT-06 | Revocación global de sesiones activas y rotación forzada de credenciales | ✅ Completo |
| US-AUT-07 | Segundo factor de autenticación TOTP (RFC 6238) con códigos de respaldo | ✅ Completo |

#### EP-02 — Roles, Permisos y Alcance Institucional
| Historia | Descripción | Estado |
|---|---|---|
| US-ROL-01 | Matriz RBAC con permisos atómicos granulares (`recurso:accion`) | ✅ Completo |
| US-ROL-02 | Creación, edición y personalización dinámica de roles institucionales | ✅ Completo |
| US-ROL-03 | Control de acceso basado en atributos (ABAC contextual y jerarquía institucional) | ✅ Completo |
| US-ROL-04 | Registro de auditoría y trazabilidad inmutable de asignación de roles y permisos | ✅ Completo |

#### EP-03 — Cartografía GPS de Espacios Académicos
| Historia | Descripción | Estado |
|---|---|---|
| US-GEO-01 | Gestión de jerarquía física institucional (Sede → Bloque → Aula) | ✅ Completo |
| US-GEO-02 | Captura de polígono perimetral por recorrido continuo con filtro de precisión GPS | ✅ Completo |
| US-GEO-03 | Captura alternativa por digitalización táctil sobre cartografía satelital | ✅ Completo |
| US-GEO-04 | Validación topológica y geométrica estricta de polígonos (GeoJSON RFC 7946) | ✅ Completo |
| US-GEO-05 | Detección y gestión de solapamientos entre espacios con justificación auditada | ✅ Completo |
| US-GEO-06 | Versionado e historial completo de geometrías de espacios físicos | ✅ Completo |
| US-GEO-07 | Edición interactiva de vértices individuales y recálculo de área en vivo | ✅ Completo |
| US-GEO-08 | Clonación rápida de geometrías entre niveles y pisos de edificios | ✅ Completo |
| US-GEO-09 | Importación masiva de espacios y perímetros mediante FeatureCollection GeoJSON | ✅ Completo |

#### EP-04 — Estructura Académica, Horarios y Sesiones
| Historia | Descripción | Estado |
|---|---|---|
| US-ACA-01 | Periodos y estructura curricular (Facultades, Programas, Asignaturas, Grupos) | ✅ Completo |
| US-ACA-02 | Configuración de franjas horarias recurrentes y validaciones temporales | ✅ Completo |
| US-ACA-03 | Asignaciones docente-grupo-aula y detección de colisiones de horario (409) | ✅ Completo |
| US-ACA-04 | Calendario de excepciones y días no hábiles (ámbitos global, sede, facultad) | ✅ Completo |
| US-ACA-05 | Generación automática idempotente de sesiones con congelamiento de parámetros | ✅ Completo |
| US-ACA-06 | Cambios puntuales de sesión (reasignación de aula y cancelación con motivo auditado) | ✅ Completo |
| US-ACA-07 | Carga masiva de programación académica vía CSV con preview y confirmación | ✅ Completo |
| US-ACA-08 | Soporte para codocencia (múltiples docentes titulares por sesión) | ✅ Completo |
| US-ACA-09 | Designación de docente de reemplazo / suplente para sesión específica | ✅ Completo |
| US-ACA-10 | Integración con sistema externo (SIS) | ⏳ Diferida (Fase 4) |

#### EP-05 — Parametrización Jerárquica Institucional
| Historia | Descripción | Estado |
|---|---|---|
| US-PAR-01 | Configuración de parámetros institucionales (tolerancia, buffers, umbrales GPS) | ✅ Completo |
| US-PAR-02 | Herencia y sobreescritura jerárquica de políticas (Institución → Facultad → Programa) | ✅ Completo |
| US-PAR-03 | Detección proactiva y alertas de desvíos en configuración de parámetros institucionales | ✅ Completo |

#### EP-06 — Motor de Marcaje y Asistencia
| Historia | Descripción | Estado |
|---|---|---|
| US-MAR-01 | Pantalla de un solo toque con semáforo reactivo de 6 estados (SRS §9.1) | ✅ Completo |
| US-MAR-02 | Captura puntual de GPS de alta precisión con descarte de lecturas obsoletas | ✅ Completo |
| US-MAR-03 | Motor determinista puro de validación en 11 pasos (RN-001) | ✅ Completo |
| US-MAR-04 | Registro y persistencia inmutable de evidencia técnica geolocalizada | ✅ Completo |
| US-MAR-05 | Idempotencia multinivel (UI debounce, UUID Idempotency-Key, BD unique index) | ✅ Completo |
| US-MAR-06 | Mensajes accionables estructurados (qué pasó, por qué y cómo resolverlo) | ✅ Completo |
| US-MAR-07 | Worker en segundo plano para generación automatizada de ausencias | ✅ Completo |
| US-MAR-08 | Historial cronológico propio con filtrado mensual y evidencia técnica | ✅ Completo |
| US-MAR-09 | Ajustes y anulaciones administrativas con motivo obligatorio auditado (≥ 20 chars) | ✅ Completo |
| US-MAR-10 | Integridad y atestación de dispositivo (detección de mock GPS, root, saltos) | ✅ Completo |
| US-MAR-11 | Marcaje offline cifrado en cola local con sincronización por lotes tolerante | ✅ Completo |
| US-MAR-12 | Avisos y alertas de cierre de ventana temporal de marcaje | ✅ Completo |
| US-MAR-13 | Apertura y control de ventana de marcaje para estudiantes del grupo | ✅ Completo |
| US-MAR-14 | Pase de lista manual de respaldo docente (`MANUAL_DOCENTE`) auditado | ✅ Completo |
| US-MAR-15 | Soporte para marcaje de salida configurable (obligatorio, opcional, desactivado) | ✅ Completo |

## Licencia

Propietario — © 2024 SIAA. Todos los derechos reservados.
