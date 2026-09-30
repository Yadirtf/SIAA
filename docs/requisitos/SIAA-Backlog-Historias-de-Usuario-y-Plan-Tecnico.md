# SIAA — Backlog de Producto y Plan Técnico de Ejecución

**Producto:** Sistema Integrado de Asistencia Académica (SIAA)
**Documento fuente:** SIAA-SRS-001 v1.0 (Jhon Alexander Gómez Ruiz, septiembre 2026)
**Documento:** SIAA-BLG-001 · v1.0
**Elaborado por:** Product Owner + Tech Lead / Arquitecto de Software
**Destinatario:** agentes de desarrollo (backend, móvil, web, QA, DevOps)

---

## 0. Cómo usar este documento

Este documento es la traducción ejecutable del SRS. No repite el SRS: lo convierte en trabajo asignable.

Está organizado en tres capas:

| Capa | Sección | Responsable | Qué contiene |
|---|---|---|---|
| Producto | §3 a §6 | PO | Épicas, historias de usuario, valor, criterios de aceptación, priorización |
| Arquitectura | §7 a §11 | Tech Lead | Decisiones técnicas, estructura de código, contratos, modelo de datos, reglas |
| Ejecución | §12 a §16 | Equipo | Subtareas técnicas por historia, DoR/DoD, pruebas, CI/CD, riesgos |

**Regla de lectura para un agente de desarrollo:** se toma una historia de §6, se lee su bloque de subtareas técnicas en §12 (mismo identificador), se consultan los contratos de §9 y el modelo de datos de §10, y se cierra contra la Definición de Terminado de §13.

### Convenciones de identificadores

| Prefijo | Significado | Ejemplo |
|---|---|---|
| `EP-nn` | Épica | `EP-03` |
| `US-XXX-nn` | Historia de usuario (XXX = módulo del SRS) | `US-MAR-01` |
| `AC-nn` | Criterio de aceptación dentro de la historia | `AC-03` |
| `T-XXX-nn.n` | Subtarea técnica derivada de una historia | `T-MAR-01.4` |
| `RF-XXX-nnn` | Requerimiento funcional del SRS (trazabilidad) | `RF-MAR-003` |
| `RN-nnn` | Regla de negocio del SRS | `RN-001` |
| `ADR-nn` | Decisión de arquitectura registrada | `ADR-04` |

### Escala de estimación

Story points en secuencia Fibonacci (1, 2, 3, 5, 8, 13). Referencia de calibración: `US-AUT-01` (login básico) = 5 puntos. Toda historia con más de 13 puntos debe partirse antes de entrar a sprint.

---

## 1. Visión de producto y métricas de valor

### 1.1 Enunciado de visión

> Para la institución, que necesita evidencia verificable del cumplimiento docente sin instalar hardware ni burocratizar el aula, SIAA es un sistema de asistencia validado por geolocalización que confirma que la persona correcta estuvo en el espacio correcto a la hora correcta, con un solo toque y menos de cinco segundos de fricción para el usuario final.

### 1.2 Principio rector que gobierna toda decisión de alcance

**Minimalismo funcional.** Toda complejidad vive en la administración. Si una historia añade pasos, decisiones o pantallas a la experiencia de marcaje del docente, la historia está mal escrita. Ante duda entre "configurable por el usuario final" y "resuelto por el servidor", siempre gana el servidor.

### 1.3 Métricas de éxito del producto (definen "entregamos valor")

| Métrica | Objetivo | Cómo se mide | Fase |
|---|---|---|---|
| Tasa de falsos rechazos | < 2 % sostenido 2 semanas | Marcajes rechazados por `FUERA_DE_AREA` cuya justificación posterior es aprobada / total marcajes | F2 (criterio de salida del piloto) |
| Tiempo de marcaje | ≤ 2 s p95 | Telemetría cliente: toque → confirmación | F1 |
| Éxito en primer intento sin capacitación | ≥ 90 % | Prueba de usabilidad moderada, n ≥ 10 | F2 |
| Adopción | ≥ 85 % de sesiones programadas con marcaje | Reporte de cumplimiento | F2 |
| Carga administrativa de cartografía | ≤ 4 min por aula levantada en campo | Cronometraje en piloto | F1 |
| Esfuerzo de excepción | ≤ 48 h de resolución de justificación | Flujo JUS | F3 |

### 1.4 Lo que explícitamente NO construimos (v1)

Nómina o descuentos automáticos · reconocimiento facial o biométrico de identidad · integración con torniquetes/RFID · gestión curricular (mallas, notas, matrícula) · rastreo de ubicación continuo o en segundo plano.

Estas exclusiones son contractuales frente al SRS §1.2 y no se negocian dentro de un sprint.

---

## 2. Supuestos de producto sobre las decisiones abiertas del SRS

El SRS §10 deja siete decisiones institucionales sin cerrar. El desarrollo no puede detenerse por ellas, así que el PO fija un **supuesto por defecto** para cada una. Cada supuesto está implementado como *parámetro configurable*, no como código rígido: si la institución decide lo contrario, se cambia configuración, no arquitectura.

| # | Decisión abierta | Supuesto adoptado | Implementado como | Riesgo si cambia |
|---|---|---|---|---|
| D-1 | ¿Validación a nivel de aula o de bloque? | **Nivel de aula con buffer configurable**, más `nivelValidacion` por espacio (`AULA` \| `BLOQUE` \| `ZONA`) que permite degradar a bloque sin redespliegue | Campo en `espacios` + parámetro heredable | Bajo — en base de datos debe ser una entidad la cual contengas el tipo de espacio o area. primordial o objetivo es el aula, no una regla distinta |
| D-2 | ¿Marcaje de salida obligatorio? | **Opcional y desactivado por defecto** (`marcajeSalidaObligatorio = false`) | Parámetro jerárquico | Bajo |
| D-3 | ¿Estudiantes marcan en MVP? | **No.** Estudiante entra en F3. El modelo de datos ya lo soporta (`rolMarcaje`) | Datos preparados, UI diferida | Bajo |
| D-4 | ¿Quién aprueba justificaciones? | **Coordinador de la facultad del docente**, con permiso `justificacion:aprobar` reasignable a cualquier rol | Permiso RBAC, no rol fijo | Nulo |
| D-5 | ¿Integración con sistema académico? | **Carga por archivo CSV/XLSX en MVP.** El endpoint de integración queda especificado pero se implementa en F4 | `RF-ACA-011` en MVP, `RF-ACA-012` en F4 | Medio — puede requerir mapeo de identificadores externos; se mitiga guardando `codigoExterno` en todas las entidades académicas desde el día uno |
| D-6 | Volumetría objetivo | **Dimensionar para 1 sede piloto, 8 bloques, 120 aulas, 400 docentes, 6.000 estudiantes**, con arquitectura probada a 300 req/s | Pruebas de carga de F1 | Medio |
| D-7 | ¿Firma electrónica del reporte? | **No en v1.** Se entrega PDF con sello de fecha, hash SHA-256 del contenido y marca de agua institucional, lo que da integridad verificable sin PKI | `US-REP-03` | Bajo |

> **Acción del PO:** estos supuestos se presentan a la institución en la fase F0. Cada uno tiene una historia de cambio asociada de coste conocido (≤ 3 puntos), salvo D-5 (13 puntos).

---

## 3. Mapa de épicas

Doce épicas, alineadas a los módulos del SRS más dos transversales de plataforma.

| Épica | Nombre | Valor de negocio | RF cubiertos | Fase | Puntos |
|---|---|---|---|---|---|
| EP-00 | Fundaciones de plataforma | Nada se entrega sin esqueleto compilado, CI y observabilidad | RNF-MAN-*, RNF-SEG-* | F1 | 34 |
| EP-01 | Identidad, sesión y dispositivo confiable | Sin identidad verificada no hay evidencia válida | RF-AUT-001..008 | F1/F2 | 47 |
| EP-02 | Roles, permisos y alcance | Un coordinador no puede ver otra facultad; requisito legal y de confianza | RF-ROL-001..006 | F1/F2 | 34 |
| EP-03 | Cartografía GPS de espacios | **Módulo diferenciador.** Sin geocercos no existe validación espacial | RF-GEO-001..016 | F1/F2 | 89 |
| EP-04 | Estructura académica, horarios y sesiones | Define contra qué se marca; sin sesiones no hay sistema | RF-ACA-001..013 | F1/F2 | 76 |
| EP-05 | Parametrización jerárquica | Permite calibrar sin redesplegar; es lo que hace viable el piloto | RF-PAR-001..010 | F1/F2 | 34 |
| EP-06 | Motor de marcaje | **Corazón del producto.** Entrega la promesa central | RF-MAR-001..016, RN-001..005 | F1/F2/F3 | 97 |
| EP-07 | Justificaciones y novedades | Válvula de escape ante falsos rechazos; condiciona la aceptación docente | RF-JUS-001..005 | F3 | 29 |
| EP-08 | Reportes e indicadores | Es el entregable que consume la institución; sin esto el sistema no "sirve para nada" ante rectoría | RF-REP-001..007 | F1/F3 | 42 |
| EP-09 | Auditoría y trazabilidad | Requisito legal y defensa probatoria ante reclamo laboral | RF-AUD-001..005 | F1/F3 | 26 |
| EP-10 | Notificaciones | Reduce olvidos, principal causa de ausencia injustificada | RF-NOT-001..004 | F3 | 21 |
| EP-11 | Privacidad y cumplimiento legal | Bloqueante de publicación en tiendas y de legalidad del tratamiento | RNF-LEG-001..007 | F1/F3 | 21 |

**Total estimado: 550 puntos.** Con un equipo de 4 desarrolladores y velocidad estabilizada de 30–35 puntos/sprint de 2 semanas, el MVP (F1 ≈ 265 puntos) cae en 8–9 sprints, coherente con las 8–10 semanas del SRS §11 solo si el equipo arranca con el stack ya dominado. Si no, planificar 12 semanas.

### 3.1 Dependencias entre épicas

```
EP-00 Fundaciones
   ├──> EP-01 Identidad ──┐
   │                      ├──> EP-02 Roles/alcance ──┐
   │                      │                          │
   ├──> EP-03 Cartografía ┤                          ├──> EP-06 Motor de marcaje ──┬──> EP-07 Justificaciones
   │                      │                          │        (requiere 03+04+05)  ├──> EP-08 Reportes
   ├──> EP-04 Académico ──┤                          │                             └──> EP-10 Notificaciones
   │                      │                          │
   └──> EP-05 Parámetros ─┘                          │
                                                     │
        EP-09 Auditoría  ── transversal, se conecta a 02,03,05,06
        EP-11 Privacidad ── transversal, bloquea publicación en tiendas
```

**Camino crítico:** `EP-00 → EP-03 → EP-04 → EP-05 → EP-06`. Cualquier retraso en cartografía o generación de sesiones retrasa el producto entero. Por eso EP-03 arranca en el sprint 1 en paralelo a EP-01.

---

## 4. Priorización

### 4.1 Método

Se prioriza por **valor entregado / riesgo despejado**, no por comodidad técnica. Se usa MoSCoW ligado a las fases del SRS §11, con un criterio de desempate: *toda historia que despeje un riesgo alto del SRS §10 sube de prioridad*.

| Clasificación | Significado operativo |
|---|---|
| **Must (M)** | Sin esto no existe producto demostrable. Corresponde a prioridad A del SRS y fase F1. |
| **Should (S)** | Necesario para operar en producción a escala. Prioridad B, fases F2–F3. |
| **Could (C)** | Mejora medible pero postergable. Prioridad C, fase F4. |
| **Won't (W)** | Fuera de v1. |

### 4.2 Orden de entrada al flujo de trabajo

El orden no es negociable entre sprints 1 y 3: estos sprints existen para **matar el riesgo R-01/R-02/R-04** (precisión GPS) lo antes posible. Es preferible descubrir en la semana 4 que el GPS no sirve en interiores que en la semana 20.

| Sprint | Objetivo del sprint (meta demostrable) | Historias | Puntos |
|---|---|---|---|
| **S1** | *"El equipo despliega un binario autenticado."* Esqueleto compilado, CI, login, modelo de datos base. | US-PLT-01..04, US-AUT-01, US-AUT-04 | 34 |
| **S2** | *"Un admin camina un aula y queda dibujada en el mapa."* Editor GPS funcionando en campo. | US-GEO-01..04, US-ROL-01 | 34 |
| **S3** | **Spike de campo + validación geométrica.** Se mide precisión real en 10 aulas del bloque piloto. Decisión D-1 se cierra con datos. | US-GEO-05..07, SPIKE-01 | 29 |
| **S4** | *"Existen horarios y sesiones generadas."* | US-ACA-01..04 | 31 |
| **S5** | *"Las sesiones nacen con parámetros congelados."* | US-ACA-05..06, US-PAR-01..03 | 34 |
| **S6** | **Primer marcaje real de punta a punta.** | US-MAR-01..04 | 34 |
| **S7** | *"El marcaje es robusto, idempotente y auditado."* | US-MAR-05..08, US-AUD-01..02 | 34 |
| **S8** | *"La institución ve un reporte y el docente su historial."* | US-MAR-09, US-REP-01..02, US-LEG-01 | 31 |
| **S9** | Endurecimiento: carga masiva, ajustes administrativos, pruebas de carga y seguridad. | US-ACA-07, US-MAR-10, US-PLT-05, US-SEG-01 | 34 |
| **S10+** | Piloto (F2) y consolidación (F3) según §4.3 | — | — |

### 4.3 Contenido de fases posteriores

- **F2 — Piloto (4 semanas):** no se construyen funcionalidades nuevas salvo correcciones. Se calibran buffers aula por aula, se miden falsos rechazos y se ajustan holguras. Se reserva el 40 % de la capacidad del equipo para corrección derivada de campo.
- **F3 — Consolidación:** EP-07 justificaciones, EP-10 notificaciones, marcaje offline (US-MAR-11), marcaje estudiantil (US-MAR-13), auditoría completa, reportes ampliados.
- **F4 — Escalamiento:** integración con sistema académico, verificación complementaria WiFi/BLE/QR en producción, tablero directivo, publicación en tiendas, SSO federado.

### 4.4 Qué entra primero y por qué (justificación del PO)

1. **Cartografía antes que marcaje.** El marcaje es inútil sin geocercos, y los geocercos requieren trabajo de campo que tiene latencia humana. Se arranca primero para que el levantamiento corra en paralelo al desarrollo del resto.
2. **El spike de precisión en el sprint 3, no en el 12.** El riesgo R-01 puede invalidar el enfoque completo. Se mide temprano con un entregable barato.
3. **Parámetros antes que motor de marcaje.** El motor consume parámetros efectivos congelados; construirlo con valores fijos y refactorizar después cuesta el doble.
4. **Auditoría junto al motor, no después.** Añadir bitácora a operaciones ya escritas es retrabajo garantizado; se escribe el decorador de auditoría cuando se escribe el primer caso de uso sensible.
5. **Justificaciones en F3 y no antes.** No se pueden justificar rechazos que aún no ocurren. Su diseño debe alimentarse de los rechazos reales del piloto.
6. **Offline diferido.** Es complejidad alta (conciliación de reloj, fraude por manipulación de hora del dispositivo) con beneficio que solo se comprueba tras medir cobertura real en el campus.
---

## 5. Formato de las historias

Cada historia se documenta así:

```
### US-XXX-nn · Título
Prioridad · Fase · Puntos · Épica · Depende de
Como <rol> quiero <capacidad> para <beneficio>.
VALOR: por qué esto importa para el negocio, en una frase verificable.
CRITERIOS DE ACEPTACIÓN: Gherkin (Dado/Cuando/Entonces), numerados AC-nn.
NOTAS DE PRODUCTO: reglas, casos borde, lo que NO incluye.
TRAZABILIDAD: RF del SRS que satisface.
```

Los criterios de aceptación están escritos para ser convertidos directamente en pruebas automatizadas. Cada `AC-nn` debe tener al menos una prueba que lo referencie por identificador.

---

## 6. Backlog de historias de usuario

---

## EP-00 · Fundaciones de plataforma

> Sin esta épica no hay nada que demostrar. Se entrega en el sprint 1 y su Definición de Terminado es estricta: un binario desplegado y accesible.

### US-PLT-01 · Esqueleto de API compilada y desplegable
**M · F1 · 8 pts · EP-00 · sin dependencias**

**Como** equipo de desarrollo **quiero** un servicio backend compilado a binario único, contenedizado y desplegado con endpoint de salud **para** tener desde el día uno el camino completo de entrega y no descubrir problemas de despliegue al final.

**VALOR:** reduce a cero el riesgo de integración tardía; habilita demostraciones desde el sprint 1.

**Criterios de aceptación**

- **AC-01** — Dado el repositorio en rama principal, cuando se ejecuta la construcción, entonces se produce un binario estático único sin dependencias de runtime interpretado, cumpliendo la restricción de código compilado del SRS §5.1.
- **AC-02** — Dado el servicio en ejecución, cuando se consulta `GET /api/v1/health`, entonces responde 200 con `{status, version, commit, uptimeSegundos, dependencias:{mongo:"ok"}}` en menos de 200 ms.
- **AC-03** — Dado un despliegue, cuando se consulta `GET /api/v1/health/ready`, entonces devuelve 503 mientras la conexión a MongoDB no esté establecida y 200 cuando lo esté.
- **AC-04** — Dada cualquier petición, cuando se procesa, entonces se emite una línea de log estructurado en JSON con `correlationId`, `metodo`, `ruta`, `status`, `duracionMs`, `usuarioId` (si aplica), conforme a RNF-MAN-005.
- **AC-05** — Dado un error no controlado, cuando ocurre, entonces el cliente recibe un cuerpo de error normalizado `{codigo, mensaje, correlationId}` sin trazas de pila ni detalles internos.
- **AC-06** — Dada la API en ejecución, cuando se consulta `/api/v1/openapi.json`, entonces se obtiene una especificación OpenAPI 3.1 generada desde el código (RNF-MAN-002).

**Notas de producto:** la ruta base es `/api/v1` con versionado semántico (RNF-MAN-004). No incluye lógica de negocio.

**Trazabilidad:** RNF-MAN-001..005, §5.1, §5.5.

---

### US-PLT-02 · Integración continua con calidad obligatoria
**M · F1 · 5 pts · EP-00 · US-PLT-01**

**Como** Tech Lead **quiero** que ningún cambio llegue a la rama principal sin análisis estático, pruebas y construcción verde **para** que la calidad sea una propiedad del proceso y no una revisión manual opcional.

**VALOR:** evita la deuda silenciosa; el SRS exige 70 % de cobertura backend y 90 % en el motor de marcaje, y eso solo se sostiene si el pipeline lo bloquea.

**Criterios de aceptación**

- **AC-01** — Dado un pull request, cuando se abre, entonces se ejecutan automáticamente: formateo, linter, análisis estático de seguridad, pruebas unitarias y construcción del artefacto.
- **AC-02** — Dado un pull request cuya cobertura global de backend cae por debajo del 70 %, cuando finaliza el pipeline, entonces la fusión queda bloqueada.
- **AC-03** — Dado un cambio que toca el paquete del motor de validación, cuando su cobertura es inferior al 90 %, entonces la fusión queda bloqueada.
- **AC-04** — Dada una fusión a la rama principal, cuando el pipeline termina en verde, entonces se publica la imagen del contenedor etiquetada con la versión semántica y el hash del commit.
- **AC-05** — Dado un secreto o credencial en el código, cuando el escáner lo detecta, entonces el pipeline falla.

**Trazabilidad:** RNF-MAN-001, RNF-MAN-003.

---

### US-PLT-03 · Esqueleto de aplicación móvil compilada
**M · F1 · 8 pts · EP-00 · sin dependencias**

**Como** equipo móvil **quiero** una app compilada AOT para Android e iOS con navegación base, tema y capa de red configurada **para** tener el armazón sobre el que montar el marcaje sin bloqueos de configuración.

**Criterios de aceptación**

- **AC-01** — Dado el proyecto móvil, cuando se compila en modo release, entonces se generan artefactos AOT nativos para Android (arm64-v8a y armeabi-v7a) e iOS, sin intérprete de JavaScript, conforme a SRS §5.1.
- **AC-02** — Dado el artefacto Android en release, cuando se mide, entonces el paquete de instalación no supera 40 MB (RNF-PER-005).
- **AC-03** — Dado un dispositivo de gama media equivalente a 3 GB de RAM y Android 10, cuando se abre la app en frío, entonces alcanza estado interactivo en ≤ 3 s (RNF-PER-002).
- **AC-04** — Dada la app, cuando el sistema operativo está en tema oscuro, entonces la interfaz adopta el tema oscuro sin pérdida de contraste (RNF-USA-004).
- **AC-05** — Dada la app instalada, cuando se inspecciona el almacenamiento, entonces no existe ningún token ni credencial en preferencias en claro; todo va a Keystore/Keychain (RNF-SEG-003).
- **AC-06** — Dada cualquier petición de la app al backend, cuando el certificado del servidor no coincide con el esperado, entonces la conexión se rechaza (certificate pinning, RNF-SEG-001).
- **AC-07** — Dada la app, cuando se instala en Android 8.0 (API 26) o iOS 14, entonces funciona sin degradación de funciones base (RNF-COM-001, RNF-COM-002).

**Trazabilidad:** §5.2, RNF-PER-002, RNF-PER-005, RNF-COM-001..002, RNF-SEG-001, RNF-SEG-003.

---

### US-PLT-04 · Esqueleto de consola web compilada
**M · F1 · 5 pts · EP-00 · US-PLT-01**

**Como** administrador institucional **quiero** acceder a una consola web que cargue rápido y funcione en los navegadores institucionales **para** operar el sistema desde escritorio.

**Criterios de aceptación**

- **AC-01** — Dada la consola, cuando se construye, entonces se compila a WebAssembly, cumpliendo la restricción de código compilado.
- **AC-02** — Dada la consola, cuando se abre en las dos últimas versiones estables de Chrome, Edge, Firefox y Safari, entonces renderiza y opera correctamente (RNF-COM-003).
- **AC-03** — Dada una ventana de 1280 px de ancho, cuando se navega, entonces no aparece desplazamiento horizontal ni recorte de contenido.
- **AC-04** — Dada la consola, cuando se audita con una herramienta de accesibilidad, entonces cumple contraste ≥ 4.5:1 y objetivos táctiles/clicables ≥ 44 px (RNF-USA-003).

**Trazabilidad:** RNF-COM-003, RNF-USA-002..004.

---

### US-PLT-05 · Observabilidad y prueba de carga del pico horario
**M · F1 · 8 pts · EP-00 · US-MAR-04**

**Como** responsable de operación **quiero** métricas, trazas y una prueba de carga que reproduzca el pico de cambio de hora **para** confirmar antes de producción que el sistema soporta el momento crítico del día.

**VALOR:** el fallo más visible posible es que el sistema caiga a las 7:00 a. m. cuando todos marcan. Esta historia lo previene con evidencia.

**Criterios de aceptación**

- **AC-01** — Dado el backend, cuando se consulta el endpoint de métricas, entonces expone latencia por ruta (p50/p95/p99), tasa de error, saturación de conexiones a base de datos y contadores de resultados de marcaje por tipo.
- **AC-02** — Dada una prueba de carga que simula 300 solicitudes por segundo sostenidas durante 10 minutos sobre `POST /marcajes`, cuando se ejecuta, entonces la latencia p95 se mantiene ≤ 2 s y la tasa de error ≤ 0,1 % (RNF-PER-003, RNF-PER-001).
- **AC-03** — Dada la misma prueba, cuando se revisan los planes de consulta de MongoDB, entonces ninguna consulta geoespacial realiza escaneo de colección (RNF-PER-004).
- **AC-04** — Dado un tablero de observabilidad, cuando ocurre un incidente, entonces es posible reconstruir una petición completa a partir de su `correlationId`.
- **AC-05** — Dada la aplicación móvil, cuando refresca la sesión activa, entonces aplica un desfase aleatorio (jitter) de hasta 20 s para no sincronizar el pico (mitigación R-05).

**Trazabilidad:** RNF-PER-001, RNF-PER-003, RNF-PER-004, R-05.

---

## EP-01 · Identidad, sesión y dispositivo confiable

### US-AUT-01 · Inicio de sesión con correo institucional
**M · F1 · 5 pts · EP-01 · US-PLT-01**

**Como** usuario del sistema **quiero** iniciar sesión con mi correo institucional y contraseña **para** acceder a mis funciones con una identidad verificada.

**VALOR:** la evidencia de asistencia solo tiene validez probatoria si está atada a una identidad autenticada.

**Criterios de aceptación**

- **AC-01** — Dadas credenciales válidas de un usuario activo, cuando se envía `POST /auth/login`, entonces se devuelven un token de acceso de vida corta (≤ 15 min) y un token de refresco de vida larga (≤ 30 días), junto con el perfil del usuario y sus roles.
- **AC-02** — Dadas credenciales inválidas, cuando se intenta ingresar, entonces la respuesta es 401 con un mensaje genérico que no revela si el correo existe.
- **AC-03** — Dado un usuario en estado inactivo o con borrado lógico, cuando intenta ingresar, entonces se rechaza con 403 aunque la contraseña sea correcta.
- **AC-04** — Dadas las contraseñas almacenadas, cuando se inspecciona la base de datos, entonces están cifradas con Argon2id (o bcrypt con coste ≥ 12) y nunca en texto plano ni con hash reversible (RNF-SEG-002).
- **AC-05** — Dado un token de acceso expirado, cuando se envía `POST /auth/refresh` con un token de refresco válido, entonces se emite un nuevo par de tokens y se rota el token de refresco (rotación obligatoria).
- **AC-06** — Dado un token de refresco ya usado, cuando se reutiliza, entonces se revoca toda la familia de tokens del usuario y se registra un evento de seguridad (detección de robo de token).
- **AC-07** — Dado un correo que no pertenece a un dominio institucional autorizado, cuando se intenta registrar o autenticar, entonces se rechaza.

**Notas de producto:** el registro de usuarios no es autoservicio; los usuarios los crea la administración o la carga masiva.

**Trazabilidad:** RF-AUT-001, RNF-SEG-002.

---

### US-AUT-02 · Bloqueo por intentos fallidos y límite de tasa
**M · F1 · 3 pts · EP-01 · US-AUT-01**

**Como** responsable de seguridad **quiero** que la cuenta se bloquee tras varios intentos fallidos y que el acceso esté limitado por tasa **para** impedir ataques de fuerza bruta contra credenciales institucionales.

**Criterios de aceptación**

- **AC-01** — Dados 5 intentos fallidos consecutivos sobre la misma cuenta en 15 minutos, cuando ocurre el sexto, entonces la cuenta queda bloqueada durante 15 minutos y se registra el evento en auditoría.
- **AC-02** — Dada una cuenta bloqueada, cuando un administrador la desbloquea, entonces el usuario puede volver a intentar y la acción queda auditada con el actor.
- **AC-03** — Dado un origen que supera 20 intentos de autenticación por minuto, cuando envía el siguiente, entonces recibe 429 con cabecera `Retry-After` (RNF-SEG-005).
- **AC-04** — Dado cualquier endpoint autenticado, cuando un usuario supera 120 peticiones por minuto, entonces recibe 429 sin afectar a otros usuarios.
- **AC-05** — Dado un intento de bloqueo, cuando se produce, entonces el número de intentos y la duración del bloqueo provienen de parámetros configurables, no de constantes en código.

**Trazabilidad:** RF-AUT-007, RNF-SEG-005.

---

### US-AUT-03 · Vinculación de dispositivo confiable
**M · F1 · 8 pts · EP-01 · US-AUT-01, US-PLT-03**

**Como** institución **quiero** que cada cuenta quede vinculada a un dispositivo identificable y que cambiarlo requiera autorización **para** impedir que un docente marque desde el teléfono de un colega.

**VALOR:** cierra el vector de fraude más simple y probable (prestar credenciales). Sin esto, la geolocalización no prueba nada sobre quién estuvo allí.

**Criterios de aceptación**

- **AC-01** — Dado un usuario que inicia sesión por primera vez en una instalación, cuando se completa el login, entonces la app envía `POST /auth/devices` con un identificador de instalación estable, modelo, sistema operativo y versión de app, y el dispositivo queda vinculado como confiable.
- **AC-02** — Dado un usuario con un dispositivo vinculado, cuando intenta marcar desde otra instalación, entonces el marcaje se rechaza con `RECHAZADO_INTEGRIDAD` y se registra el intento en auditoría.
- **AC-03** — Dado un usuario que cambió de teléfono, cuando solicita revinculación desde la app, entonces se genera una solicitud que un administrador debe aprobar desde la consola web, y solo tras la aprobación el nuevo dispositivo queda activo.
- **AC-04** — Dado un mismo identificador de dispositivo usado por dos usuarios distintos en un plazo de 24 horas, cuando ocurre el segundo marcaje, entonces se genera una alerta de anomalía visible en auditoría (mitigación R-03).
- **AC-05** — Dada la desinstalación y reinstalación de la app por el mismo usuario, cuando vuelve a iniciar sesión, entonces el sistema lo trata como cambio de dispositivo y aplica AC-03.
- **AC-06** — Dado un administrador en la consola, cuando consulta un usuario, entonces ve el historial de dispositivos vinculados con fechas, y puede revocar cualquiera.

**Notas de producto:** el identificador de instalación **no** es el IMEI ni un identificador publicitario; es un UUID generado en el primer arranque y guardado en almacenamiento seguro. Esta decisión es de cumplimiento, no técnica.

**Trazabilidad:** RF-AUT-004, R-03.

---

### US-AUT-04 · Recuperación de contraseña
**M · F1 · 3 pts · EP-01 · US-AUT-01**

**Como** usuario **quiero** recuperar el acceso si olvido mi contraseña **para** no depender de soporte y no perder la posibilidad de marcar asistencia.

**Criterios de aceptación**

- **AC-01** — Dado un correo registrado, cuando se solicita recuperación, entonces se envía un enlace de un solo uso con expiración ≤ 30 minutos.
- **AC-02** — Dado un correo no registrado, cuando se solicita recuperación, entonces la respuesta es idéntica a la del caso registrado (no se filtra la existencia de cuentas).
- **AC-03** — Dado un enlace ya usado o expirado, cuando se intenta usar, entonces se rechaza con mensaje claro y opción de solicitar uno nuevo.
- **AC-04** — Dado un cambio de contraseña exitoso, cuando se completa, entonces se revocan todas las sesiones activas del usuario y se registra el evento en auditoría.
- **AC-05** — Dada una contraseña nueva, cuando no cumple la política mínima (longitud ≥ 12, no estar en listas de contraseñas comunes), entonces se rechaza indicando qué falta.

**Trazabilidad:** RF-AUT-002.

---

### US-AUT-05 · Segundo factor obligatorio para roles administrativos
**S · F2 · 8 pts · EP-01 · US-AUT-01**

**Como** superadministrador **quiero** exigir segundo factor TOTP a los roles administrativos **para** que una credencial comprometida no permita alterar geocercos, parámetros ni marcajes.

**Criterios de aceptación**

- **AC-01** — Dado un usuario con rol administrativo sin TOTP configurado, cuando inicia sesión, entonces se le obliga a configurarlo antes de acceder a cualquier funcionalidad.
- **AC-02** — Dado un usuario con TOTP activo, cuando inicia sesión, entonces debe presentar un código válido de 6 dígitos con ventana de tolerancia de ±1 intervalo.
- **AC-03** — Dado el proceso de activación, cuando se completa, entonces se entregan 8 códigos de respaldo de un solo uso.
- **AC-04** — Dados 5 códigos TOTP incorrectos consecutivos, cuando ocurre el sexto, entonces la cuenta se bloquea conforme a US-AUT-02.
- **AC-05** — Dado un rol operativo (docente, estudiante), cuando inicia sesión, entonces no se le exige TOTP salvo que el parámetro de ámbito lo active.

**Trazabilidad:** RF-AUT-003.

---

### US-AUT-06 · Reapertura de sesión con biometría local
**S · F2 · 5 pts · EP-01 · US-AUT-03**

**Como** docente **quiero** reabrir la app con huella o reconocimiento facial **para** poder marcar sin escribir mi contraseña en el pasillo antes de clase.

**VALOR:** ataca directamente la métrica de "marcaje en menos de 5 segundos"; escribir una contraseña institucional consume más tiempo que todo el resto del flujo.

**Criterios de aceptación**

- **AC-01** — Dado un usuario con sesión previa y biometría disponible, cuando abre la app, entonces se le solicita verificación biométrica local y, al superarla, recupera el token de refresco del almacenamiento seguro sin reescribir credenciales.
- **AC-02** — Dado un dispositivo sin biometría configurada, cuando se abre la app, entonces se ofrece PIN local o credenciales, sin bloquear el uso.
- **AC-03** — Dada una verificación biométrica fallida 3 veces, cuando ocurre, entonces se exige contraseña completa.
- **AC-04** — Dada la verificación biométrica, cuando se realiza, entonces ocurre exclusivamente en el dispositivo; ningún dato biométrico se transmite ni almacena en el servidor.

**Trazabilidad:** RF-AUT-005, RNF-USA-001.

---

### US-AUT-07 · Cierre de sesión remoto y revocación
**S · F2 · 5 pts · EP-01 · US-AUT-01, US-ROL-01**

**Como** administrador **quiero** cerrar sesiones y revocar tokens de cualquier usuario desde la consola **para** responder de inmediato ante pérdida de dispositivo o desvinculación laboral.

**Criterios de aceptación**

- **AC-01** — Dado un administrador con permiso, cuando revoca las sesiones de un usuario, entonces todos los tokens de refresco de ese usuario quedan invalidados de inmediato.
- **AC-02** — Dado un token de acceso aún no expirado tras la revocación, cuando se usa, entonces se rechaza con 401 en un plazo no mayor a 60 segundos (lista de revocación consultada por el middleware).
- **AC-03** — Dada una revocación, cuando se ejecuta, entonces queda auditada con actor, usuario afectado, motivo y timestamp.

**Trazabilidad:** RF-AUT-006.

---

### US-AUT-08 · Inicio de sesión federado con el directorio institucional
**C · F4 · 8 pts · EP-01 · US-AUT-01**

**Como** institución **quiero** que los usuarios ingresen con el proveedor de identidad institucional **para** eliminar una contraseña más y centralizar altas y bajas.

**Criterios de aceptación**

- **AC-01** — Dado un proveedor OIDC configurado, cuando el usuario elige ingreso institucional, entonces se completa el flujo de código de autorización con PKCE y se emiten tokens de SIAA.
- **AC-02** — Dado un usuario que existe en el proveedor pero no en SIAA, cuando ingresa, entonces se aprovisiona automáticamente con el rol por defecto configurado y sin permisos administrativos.
- **AC-03** — Dado un usuario deshabilitado en el proveedor, cuando intenta ingresar, entonces se rechaza y su cuenta SIAA se marca inactiva.

**Trazabilidad:** RF-AUT-008.

---

## EP-02 · Roles, permisos y alcance

### US-ROL-01 · Control de acceso por permisos granulares
**M · F1 · 8 pts · EP-02 · US-AUT-01**

**Como** institución **quiero** que cada operación esté protegida por un permiso con formato `recurso:acción` **para** que ningún usuario pueda ejecutar acciones fuera de su función, y que los roles sean auditables.

**VALOR:** es el fundamento de la confianza del sistema; un docente que pudiera editar un geocerco anularía toda la evidencia.

**Criterios de aceptación**

- **AC-01** — Dado el sistema inicializado, cuando se consultan los roles, entonces existen los roles predefinidos Superadministrador, Administrador institucional, Coordinador, Docente, Estudiante, Monitor y Auditor, con la matriz de permisos del SRS §3.2 exactamente aplicada.
- **AC-02** — Dado un usuario sin el permiso requerido, cuando invoca un endpoint protegido, entonces recibe 403 y el intento queda auditado.
- **AC-03** — Dado un endpoint nuevo añadido al sistema, cuando se despliega sin declarar el permiso que exige, entonces el servicio falla al arrancar (permiso obligatorio por diseño, no por olvido).
- **AC-04** — Dado un docente, cuando intenta `marcaje:anular`, `aula:editar-geometria` o `parametro:editar`, entonces siempre recibe 403 sin importar el ámbito.
- **AC-05** — Dado un auditor, cuando consulta marcajes y auditoría, entonces puede leer y exportar pero cualquier operación de escritura sobre datos operativos devuelve 403.
- **AC-06** — Dada la interfaz, cuando un usuario no tiene un permiso, entonces la opción no se muestra; pero la ausencia visual **nunca** es el único control: el backend rechaza igualmente.

**Trazabilidad:** RF-ROL-001, RF-ROL-005, matriz §3.2, RNF-SEG-009.

---

### US-ROL-02 · Alcance por atributos (ABAC)
**M · F1 · 8 pts · EP-02 · US-ROL-01, US-ACA-01**

**Como** coordinador de facultad **quiero** ver y operar únicamente sobre mi facultad y sede **para** cumplir el principio de mínimo privilegio y proteger datos personales de docentes ajenos a mi ámbito.

**Criterios de aceptación**

- **AC-01** — Dado un coordinador con ámbito Facultad de Ingeniería, cuando consulta `GET /reportes/cumplimiento`, entonces el resultado incluye exclusivamente docentes y sesiones de esa facultad, aunque no envíe filtro alguno.
- **AC-02** — Dado el mismo coordinador, cuando solicita explícitamente un recurso identificado de otra facultad, entonces recibe 403 y el intento se registra en auditoría (CA-010 del SRS).
- **AC-03** — Dado un filtro de ámbito, cuando se evalúa, entonces ocurre en el backend como condición de consulta, nunca como filtrado en el cliente.
- **AC-04** — Dado un usuario con ámbito sobre una sede, cuando lista espacios, entonces solo obtiene espacios de esa sede.
- **AC-05** — Dado un docente, cuando consulta marcajes, entonces solo obtiene los propios, incluso solicitando el identificador de otro usuario.
- **AC-06** — Dado un superadministrador, cuando consulta cualquier recurso, entonces no se aplica restricción de ámbito.

**Notas de producto:** el ámbito se modela como lista de pares `{tipo: SEDE|FACULTAD|BLOQUE, id}` asociada a la asignación de rol del usuario. Un usuario puede tener ámbito múltiple.

**Trazabilidad:** RF-ROL-003, CA-010, RNF-SEG-009.

---

### US-ROL-03 · Roles personalizados
**S · F2 · 5 pts · EP-02 · US-ROL-01**

**Como** superadministrador **quiero** crear roles combinando permisos existentes **para** adaptar el sistema a estructuras institucionales que no encajan en los roles predefinidos.

**Criterios de aceptación**

- **AC-01** — Dado un superadministrador, cuando crea un rol con un subconjunto de permisos del catálogo, entonces el rol queda disponible para asignación.
- **AC-02** — Dado un rol personalizado, cuando se intenta incluir un permiso inexistente, entonces se rechaza con error de validación.
- **AC-03** — Dado un rol predefinido del sistema, cuando se intenta eliminarlo o alterar sus permisos base, entonces se impide.
- **AC-04** — Dado un rol en uso por al menos un usuario, cuando se intenta eliminar, entonces se bloquea indicando cuántos usuarios lo tienen.
- **AC-05** — Dada la creación, modificación o eliminación de un rol, cuando ocurre, entonces se audita con los permisos anteriores y nuevos.

**Trazabilidad:** RF-ROL-002, RF-ROL-005.

---

### US-ROL-04 · Múltiples roles y cambio de contexto
**S · F2 · 5 pts · EP-02 · US-ROL-01**

**Como** usuario que es docente y coordinador **quiero** alternar el contexto activo **para** no mezclar mis funciones ni ver datos de gestión mientras solo quiero marcar mi clase.

**Criterios de aceptación**

- **AC-01** — Dado un usuario con dos o más roles, cuando inicia sesión, entonces la app y la consola le permiten seleccionar el contexto activo.
- **AC-02** — Dado un contexto activo, cuando se ejecuta cualquier operación, entonces los permisos aplicados son los del contexto activo, y el rol activo se registra en cada entrada de auditoría (RF-AUD-002).
- **AC-03** — Dado un usuario en contexto Docente, cuando intenta una operación de coordinación, entonces recibe 403 aunque posea el rol, hasta que cambie de contexto.
- **AC-04** — Dado un cambio de contexto, cuando se realiza, entonces se emite un token nuevo con el rol activo reflejado.

**Trazabilidad:** RF-ROL-004, RF-AUD-002.

---

### US-ROL-05 · Vigencia temporal de roles
**C · F4 · 3 pts · EP-02 · US-ROL-01**

**Como** administrador **quiero** asignar roles con fecha de inicio y fin **para** gestionar encargos y suplencias sin depender de recordar revocarlos.

**Criterios de aceptación**

- **AC-01** — Dada una asignación de rol con vigencia, cuando la fecha actual queda fuera del rango, entonces los permisos de ese rol no se aplican, sin intervención manual.
- **AC-02** — Dado un rol próximo a vencer (3 días), cuando se ejecuta el proceso programado, entonces se notifica al administrador responsable.
- **AC-03** — Dada una sesión activa cuyo rol venció, cuando se emite el próximo token, entonces ya no incluye ese rol.

**Trazabilidad:** RF-ROL-006.

---

## EP-03 · Cartografía GPS de espacios

> Módulo diferenciador y camino crítico. Su objetivo es que **un administrador con un teléfono levante un aula en menos de cuatro minutos, sin planos ni software SIG.**

### US-GEO-01 · Jerarquía física de espacios
**M · F1 · 5 pts · EP-03 · US-ROL-01**

**Como** administrador institucional **quiero** crear y gestionar la jerarquía Sede → Torre → Bloque → Piso → Aula **para** organizar el inventario físico sobre el cual se validará la asistencia.

**Criterios de aceptación**

- **AC-01** — Dado un administrador, cuando crea una sede, un bloque y un aula, entonces la jerarquía queda persistida y navegable desde móvil y web.
- **AC-02** — Dada la jerarquía, cuando se crea un espacio, entonces sede y espacio son obligatorios y torre, bloque y piso son opcionales (RF-GEO-001).
- **AC-03** — Dado un código de espacio ya existente, cuando se intenta reutilizar, entonces se rechaza por unicidad.
- **AC-04** — Dado un espacio, cuando se crea o edita, entonces admite nombre, código, capacidad, tipo (aula, laboratorio, auditorio, taller), facultad responsable y estado (activo, inactivo, mantenimiento).
- **AC-05** — Dado un espacio con sesiones futuras asociadas, cuando se intenta pasar a estado inactivo o mantenimiento, entonces el sistema advierte cuántas sesiones se verán afectadas y exige confirmación.
- **AC-06** — Dado un espacio eliminado, cuando se consulta la base de datos, entonces se aplicó borrado lógico y el registro conserva su historia (RF-AUD-005).

**Trazabilidad:** RF-GEO-001, RF-GEO-014, RF-AUD-005.

---

### US-GEO-02 · Captura de polígono por recorrido perimetral
**M · F1 · 13 pts · EP-03 · US-GEO-01, US-PLT-03**

**Como** administrador en campo **quiero** caminar el perímetro del aula capturando un vértice en cada esquina **para** levantar el geocerco real sin planos ni herramientas especializadas.

**VALOR:** es la capacidad que hace viable todo el proyecto sin presupuesto de levantamiento topográfico. Cada aula levantada correctamente es una unidad de valor entregada.

**Criterios de aceptación**

- **AC-01** — Dado un administrador en el editor GPS, cuando pulsa "Capturar vértice", entonces el sistema toma N lecturas GPS consecutivas (N parametrizable, por defecto 5), descarta las que excedan la precisión máxima configurada y promedia las restantes para producir un vértice único.
- **AC-02** — Dada una captura donde todas las lecturas superan el umbral de precisión, cuando finaliza, entonces no se registra vértice y se informa al usuario que se acerque a una zona de mejor señal.
- **AC-03** — Dada la pantalla del editor, cuando está activa, entonces muestra en tiempo real la precisión GPS actual con semáforo de color y el contador de vértices capturados (RF-GEO-012).
- **AC-04** — Dada una precisión actual peor que el umbral configurado, cuando el usuario intenta capturar, entonces el botón está deshabilitado con el motivo visible.
- **AC-05** — Dado un conjunto de vértices, cuando el usuario pulsa "Deshacer", entonces se elimina el último vértice capturado; la acción es repetible hasta vaciar la lista.
- **AC-06** — Dados al menos 3 vértices, cuando el usuario pulsa "Cerrar polígono", entonces se cierra el anillo repitiendo el primer vértice al final y se muestra la previsualización del área con su superficie en metros cuadrados.
- **AC-07** — Dado un polígono cerrado, cuando se guarda, entonces se persiste como GeoJSON Polygon con coordenadas en orden **[longitud, latitud]**, junto con centroide, área en m², precisión promedio de las lecturas y método de captura `RECORRIDO_PERIMETRAL`.
- **AC-08** — Dado un levantamiento típico de un aula rectangular de 4 esquinas, cuando se cronometra, entonces el proceso completo se realiza en ≤ 4 minutos.

**Notas de producto:** el orden `[longitud, latitud]` es la fuente de error más común de este tipo de sistemas (SRS §6.2). Debe haber una prueba automatizada dedicada exclusivamente a este invariante.

**Trazabilidad:** RF-GEO-002, RF-GEO-003, RF-GEO-012, CA-007.

---

### US-GEO-03 · Captura alternativa por toque sobre mapa satelital
**M · F1 · 5 pts · EP-03 · US-GEO-02**

**Como** administrador **quiero** dibujar el polígono tocando sobre una imagen satelital **para** levantar espacios inaccesibles, muy grandes, o cuando la señal GPS interior es inutilizable.

**Criterios de aceptación**

- **AC-01** — Dado el editor en modo mapa, cuando el usuario toca sobre la imagen satelital, entonces se añade un vértice en esa coordenada.
- **AC-02** — Dado un polígono dibujado por toque, cuando se guarda, entonces el método de captura se registra como `TOQUE_MAPA` y no se registra precisión GPS promedio.
- **AC-03** — Dado un polígono, cuando se alterna entre modo recorrido y modo mapa, entonces los vértices ya capturados se conservan y pueden combinarse ambos métodos, registrándose el método como `MIXTO`.
- **AC-04** — Dada la ausencia de conexión, cuando se abre el modo mapa, entonces se usan las teselas almacenadas en caché si existen y se informa la limitación si no.

**Trazabilidad:** RF-GEO-004.

---

### US-GEO-04 · Validación geométrica del polígono
**M · F1 · 8 pts · EP-03 · US-GEO-02**

**Como** institución **quiero** que ningún polígono inválido entre al sistema **para** evitar que un geocerco mal formado produzca rechazos injustos a un docente.

**VALOR:** previene el fallo más costoso en reputación: rechazar a alguien que sí estaba en el aula.

**Criterios de aceptación**

- **AC-01** — Dado un polígono con menos de 3 vértices distintos, cuando se valida, entonces se rechaza con motivo `VERTICES_INSUFICIENTES`.
- **AC-02** — Dado un polígono cuyos lados se auto-intersectan, cuando se valida, entonces se rechaza con motivo `POLIGONO_NO_SIMPLE` y se señalan los segmentos que cruzan.
- **AC-03** — Dado un polígono no cerrado, cuando se valida, entonces el sistema lo cierra automáticamente o lo rechaza según configuración, informando la acción tomada.
- **AC-04** — Dado un polígono cuya área calculada queda fuera del rango configurable (por defecto 6 m² a 5.000 m²), cuando se valida, entonces se rechaza con el área calculada informada.
- **AC-05** — Dado un polígono, cuando se envía a `POST /espacios/validar-geometria`, entonces se obtiene el resultado de validación, el área, el centroide y las advertencias, **sin persistir nada**.
- **AC-06** — Dado un polígono válido, cuando se guarda, entonces se calcula y almacena también `geometriaBuffer`, el polígono expandido según el buffer en metros del espacio.

**Trazabilidad:** RF-GEO-006, RF-GEO-010, §6.4.

---

### US-GEO-05 · Detección de solapamientos
**M · F1 · 5 pts · EP-03 · US-GEO-04**

**Como** administrador **quiero** que el sistema me advierta si el aula que acabo de levantar se solapa con otra del mismo piso y bloque **para** no crear geocercos ambiguos que acepten marcajes de la clase equivocada.

**Criterios de aceptación**

- **AC-01** — Dado un polígono nuevo que intersecta el de otro espacio activo del mismo piso y bloque, cuando se guarda, entonces se muestra una advertencia con el nombre del espacio en conflicto y el porcentaje de área solapada.
- **AC-02** — Dada la advertencia, cuando el administrador confirma explícitamente, entonces el polígono se guarda y la decisión queda auditada con el actor y el motivo.
- **AC-03** — Dado un solapamiento superior al 50 % del área, cuando se intenta guardar, entonces se bloquea el guardado (no es advertencia, es error).
- **AC-04** — Dado un administrador, cuando consulta `GET /espacios/solapamientos`, entonces obtiene el informe completo de conflictos por sede y bloque, útil para depurar un levantamiento masivo.
- **AC-05** — Dados dos espacios en pisos distintos de la misma torre, cuando se comparan, entonces **no** se reporta solapamiento, dado que comparten huella horizontal por diseño (riesgo R-01).

**Trazabilidad:** RF-GEO-007, CA-007, R-01.

---

### US-GEO-06 · Versionado de geometría
**M · F1 · 5 pts · EP-03 · US-GEO-04**

**Como** auditor **quiero** que cada modificación de un geocerco conserve la versión anterior **para** poder evaluar un marcaje histórico contra la geometría que estaba vigente en ese momento y sostener la evidencia ante un reclamo.

**VALOR:** sin esto, un cambio administrativo posterior podría invalidar retroactivamente la evidencia de meses, destruyendo su valor probatorio.

**Criterios de aceptación**

- **AC-01** — Dada una modificación de geometría vía `PUT /espacios/{id}/geometria`, cuando se aplica, entonces la versión anterior se archiva en el histórico con fecha, autor y número de versión, y el contador de versión del espacio se incrementa.
- **AC-02** — Dada una sesión ya generada, cuando se consulta, entonces conserva congelada la versión de geometría con la que fue creada.
- **AC-03** — Dado un marcaje histórico, cuando se reevalúa o audita, entonces se compara contra la versión de geometría vigente en la fecha de la sesión, no contra la actual.
- **AC-04** — Dado un administrador, cuando consulta el histórico de un espacio, entonces ve la lista de versiones con autor, fecha, área y puede visualizar cada una sobre el mapa.
- **AC-05** — Dada una versión histórica, cuando se intenta editar o eliminar, entonces se rechaza: el histórico es inmutable.

**Trazabilidad:** RF-GEO-009, §6.2 (sesiones.espacioVersionGeometria).

---

### US-GEO-07 · Edición de vértices individuales
**M · F1 · 5 pts · EP-03 · US-GEO-06**

**Como** administrador **quiero** mover, insertar o eliminar vértices de un polígono ya guardado **para** corregir una esquina mal capturada sin repetir todo el recorrido.

**Criterios de aceptación**

- **AC-01** — Dado un polígono existente, cuando el administrador arrastra un vértice en móvil o web, entonces la nueva posición se refleja y el área se recalcula en vivo.
- **AC-02** — Dado un lado del polígono, cuando el administrador toca sobre él, entonces se inserta un vértice nuevo en ese punto.
- **AC-03** — Dado un polígono con más de 3 vértices, cuando se elimina uno, entonces se aplica; con exactamente 3, la eliminación se impide.
- **AC-04** — Dada una edición guardada, cuando se persiste, entonces se aplican todas las validaciones de US-GEO-04 y se crea una versión nueva conforme a US-GEO-06.
- **AC-05** — Dada una edición abandonada sin guardar, cuando el usuario sale, entonces se pide confirmación y no se altera nada.

**Trazabilidad:** RF-GEO-008.

---

### US-GEO-08 · Buffer perimetral por espacio
**M · F1 · 3 pts · EP-03 · US-GEO-04, US-PAR-01**

**Como** administrador **quiero** definir un margen en metros alrededor del polígono **para** absorber el error natural del GPS en interiores y reducir falsos rechazos sin rehacer la cartografía.

**Criterios de aceptación**

- **AC-01** — Dado un espacio, cuando se define un buffer en metros (rango 0–50, por defecto 10), entonces se recalcula y persiste `geometriaBuffer`.
- **AC-02** — Dado un cambio de buffer, cuando se guarda, entonces se recalcula el polígono expandido sin necesidad de recapturar vértices.
- **AC-03** — Dada una validación de marcaje, cuando se evalúa la contención, entonces se usa `geometriaBuffer` precalculada y no se computa la expansión en tiempo de solicitud (SRS §6.4).
- **AC-04** — Dado un espacio sin buffer propio, cuando se resuelve su valor, entonces se hereda del nivel superior según la cascada de parámetros.

**Trazabilidad:** RF-GEO-010, RF-PAR-006, §6.4.

---

### US-GEO-09 · Modo simplificado centroide + radio
**S · F2 · 3 pts · EP-03 · US-GEO-04**

**Como** administrador **quiero** definir un espacio con un punto central y un radio **para** levantar rápidamente espacios abiertos o de forma irregular donde el recorrido perimetral no aporta precisión.

**Criterios de aceptación**

- **AC-01** — Dado un punto y un radio en metros, cuando se confirma, entonces se genera un polígono circular aproximado de al menos 16 vértices.
- **AC-02** — Dado un polígono generado así, cuando se guarda, entonces el método de captura se registra como `CENTROIDE_RADIO`.
- **AC-03** — Dado un polígono circular, cuando se edita posteriormente, entonces admite edición de vértices como cualquier otro.

**Trazabilidad:** RF-GEO-005.

---

### US-GEO-10 · Captura offline de cartografía
**S · F2 · 8 pts · EP-03 · US-GEO-02**

**Como** administrador levantando un sótano sin señal **quiero** capturar geometrías sin conexión y sincronizarlas al salir **para** no perder el trabajo de campo.

**Criterios de aceptación**

- **AC-01** — Dado un dispositivo sin conectividad, cuando el administrador captura vértices y cierra un polígono, entonces la geometría se guarda localmente cifrada y con estado `PENDIENTE_SINCRONIZACION`.
- **AC-02** — Dada la recuperación de conexión, cuando la app detecta red, entonces sincroniza automáticamente las geometrías pendientes y muestra el resultado de cada una.
- **AC-03** — Dada una geometría sincronizada que falla validación en el servidor, cuando se informa, entonces queda accesible localmente para corrección, sin pérdida de vértices.
- **AC-04** — Dado un conflicto (el espacio fue modificado en el servidor mientras tanto), cuando se sincroniza, entonces se presenta el conflicto al usuario para que decida, sin sobrescribir en silencio.

**Trazabilidad:** RF-GEO-013.

---

### US-GEO-11 · Importación y exportación GeoJSON/KML
**S · F2 · 5 pts · EP-03 · US-GEO-04**

**Como** administrador **quiero** importar y exportar la cartografía en formatos estándar **para** aprovechar levantamientos previos y poder auditar la geometría en herramientas externas.

**Criterios de aceptación**

- **AC-01** — Dado un archivo GeoJSON o KML válido, cuando se importa, entonces se previsualizan los espacios detectados y se reportan errores por elemento antes de confirmar.
- **AC-02** — Dada una importación confirmada, cuando se ejecuta, entonces cada geometría pasa por las mismas validaciones de US-GEO-04 y US-GEO-05.
- **AC-03** — Dada una selección de espacios, cuando se exporta, entonces se descarga un archivo con geometría, código, nombre y metadatos.
- **AC-04** — Dado un archivo con coordenadas en orden invertido (latitud primero), cuando se importa, entonces el sistema detecta la anomalía por rango de valores y advierte antes de persistir.

**Trazabilidad:** RF-GEO-011.

---

### US-GEO-12 · Clonar geometría entre pisos
**S · F2 · 3 pts · EP-03 · US-GEO-06**

**Como** administrador **quiero** copiar la planta de un piso a otro de la misma torre **para** no recorrer 8 veces la misma huella en un edificio de plantas idénticas.

**Criterios de aceptación**

- **AC-01** — Dado un piso con espacios levantados, cuando se clona a otro piso de la misma torre, entonces se crean espacios nuevos con idéntica geometría y el atributo piso ajustado.
- **AC-02** — Dada la clonación, cuando se ejecuta, entonces los códigos de espacio se generan según una plantilla configurable y se rechaza si alguno colisiona.
- **AC-03** — Dada la clonación, cuando se completa, entonces **no** se reporta solapamiento entre pisos distintos y se recuerda al administrador la limitación del riesgo R-01.

**Trazabilidad:** RF-GEO-015, R-01.

---

### US-GEO-13 · Verificación complementaria por espacio
**S · F2 · 8 pts · EP-03 · US-GEO-01, US-MAR-04**

**Como** institución con torres de alta ocupación **quiero** registrar BSSID de WiFi, UUID de baliza BLE o un código QR fijo por aula **para** desambiguar el piso, que el GPS no puede distinguir.

**VALOR:** es la mitigación directa del riesgo principal del proyecto (R-01). Sin ella, en edificios verticales la validación solo puede llegar a nivel de bloque.

**Criterios de aceptación**

- **AC-01** — Dado un espacio, cuando el administrador lo configura, entonces puede registrar una lista de BSSID WiFi, un UUID de baliza BLE y un código QR fijo.
- **AC-02** — Dado un espacio con verificación complementaria marcada como exigida, cuando un usuario marca sin aportarla, entonces el marcaje se rechaza con `RECHAZADO_VERIFICACION`.
- **AC-03** — Dado un marcaje con verificación aportada que no coincide con ninguno de los valores registrados, cuando se evalúa, entonces se rechaza con `RECHAZADO_VERIFICACION` y se informa el método esperado.
- **AC-04** — Dada la exigencia de verificación complementaria, cuando se configura, entonces es un parámetro por ámbito y puede activarse solo en los bloques que lo necesiten.
- **AC-05** — Dado un aula con QR fijo, cuando el docente escanea el código desde la app, entonces el valor se adjunta al marcaje automáticamente sin pasos adicionales.

**Notas de producto:** el QR fijo es falsificable por fotografía; su valor es desambiguar piso, no prevenir fraude. Debe combinarse con la validación geoespacial, nunca sustituirla. El QR debe rotar su valor periódicamente si se decide usarlo como control antifraude (fuera de v1).

**Trazabilidad:** RF-GEO-016, R-01, R-04.
---

## EP-04 · Estructura académica, horarios y sesiones

### US-ACA-01 · Periodos y estructura académica
**M · F1 · 8 pts · EP-04 · US-ROL-01**

**Como** administrador institucional **quiero** gestionar periodos académicos, facultades, programas, asignaturas y grupos **para** que exista el marco organizativo contra el cual se definen horarios y asignaciones.

**Criterios de aceptación**

- **AC-01** — Dado un administrador, cuando crea un periodo con fecha de inicio, fin y estado (planeación, activo, cerrado), entonces queda disponible para asignaciones.
- **AC-02** — Dado un periodo en estado cerrado, cuando se intenta crear o modificar asignaciones sobre él, entonces se rechaza.
- **AC-03** — Dado un periodo activo, cuando se intenta activar un segundo periodo con fechas solapadas para la misma sede, entonces se advierte y se exige confirmación.
- **AC-04** — Dadas facultades, programas, asignaturas y grupos, cuando se crean, entonces respetan la jerarquía Facultad → Programa → Asignatura → Grupo y todos admiten un `codigoExterno` para futura conciliación con el sistema académico.
- **AC-05** — Dada una entidad académica con dependencias, cuando se intenta eliminar, entonces se aplica borrado lógico y se informa el impacto.

**Notas de producto:** `codigoExterno` es obligatorio conceptualmente aunque acepte nulo; sin él, la integración de F4 (decisión D-5) se vuelve un proyecto de migración de datos.

**Trazabilidad:** RF-ACA-001, RF-ACA-002.

---

### US-ACA-02 · Franjas horarias recurrentes
**M · F1 · 5 pts · EP-04 · US-ACA-01**

**Como** coordinador **quiero** definir franjas horarias recurrentes por día de semana **para** expresar el horario real de clases sin capturar fecha por fecha.

**Criterios de aceptación**

- **AC-01** — Dada una franja, cuando se crea con día de semana, hora de inicio y hora de fin, entonces queda asociada al grupo correspondiente.
- **AC-02** — Dada una franja cuya hora de fin es anterior o igual a la de inicio, cuando se guarda, entonces se rechaza.
- **AC-03** — Dada una franja, cuando se interpreta temporalmente, entonces se resuelve en la zona horaria institucional configurada (`America/Bogota` por defecto) y se almacena de forma no ambigua.
- **AC-04** — Dada una franja cuya duración es inferior a 15 minutos o superior a 8 horas, cuando se guarda, entonces se advierte.

**Trazabilidad:** RF-ACA-003.

---

### US-ACA-03 · Asignaciones docente–grupo–aula–franja
**M · F1 · 8 pts · EP-04 · US-ACA-02, US-GEO-01**

**Como** coordinador **quiero** vincular a un docente con un grupo, un aula y una franja horaria dentro de un periodo **para** establecer la autorización que habilitará su marcaje.

**VALOR:** la asignación es la fuente de autoridad de todo el sistema: sin ella no hay marcaje posible, y con ella el docente no necesita elegir nada.

**Criterios de aceptación**

- **AC-01** — Dado un coordinador, cuando crea una asignación con docente, grupo/asignatura, espacio, franja y periodo, entonces queda persistida en estado activa con su rango de vigencia.
- **AC-02** — Dado un docente con una asignación vigente en una franja, cuando se intenta crear otra asignación que se solapa temporalmente para él, entonces se rechaza indicando el conflicto (RF-ACA-005).
- **AC-03** — Dado un aula ocupada en una franja, cuando se intenta asignar otro grupo en la misma franja y periodo, entonces se rechaza indicando el conflicto.
- **AC-04** — Dada una asignación sobre un espacio sin geometría capturada, cuando se guarda, entonces se permite pero se marca con advertencia visible: las sesiones generadas no podrán validarse espacialmente hasta levantar el geocerco.
- **AC-05** — Dada una asignación, cuando se crea, entonces admite `parametrosOverride` propios que prevalecen sobre la cascada de parámetros.
- **AC-06** — Dada una asignación con modalidad virtual o no presencial, cuando se crea, entonces se marca como exenta de validación geoespacial.
- **AC-07** — Dado un coordinador, cuando crea una asignación fuera de su facultad, entonces recibe 403 (alcance ABAC).

**Trazabilidad:** RF-ACA-004, RF-ACA-005, RF-ACA-013, RF-ROL-003.

---

### US-ACA-04 · Calendario de excepciones
**M · F1 · 5 pts · EP-04 · US-ACA-01**

**Como** administrador **quiero** registrar festivos, recesos, jornadas institucionales y paros **para** que no se generen sesiones en fechas no lectivas y nadie sea reportado ausente por un día festivo.

**VALOR:** evita el escenario que destruiría la confianza en el sistema más rápido que cualquier bug: reportar ausente a todo el campus un lunes festivo.

**Criterios de aceptación**

- **AC-01** — Dado un administrador, cuando registra una excepción con rango de fechas, tipo y ámbito (global, sede o facultad), entonces queda vigente.
- **AC-02** — Dada la generación de sesiones, cuando una fecha cae dentro de una excepción aplicable, entonces no se genera sesión para esa fecha.
- **AC-03** — Dada una excepción creada **después** de generar sesiones, cuando se aplica, entonces las sesiones afectadas pasan a estado `CANCELADA` con motivo, y los marcajes ya realizados se conservan sin alterarse.
- **AC-04** — Dada una excepción, cuando se elimina, entonces se ofrece regenerar las sesiones de las fechas liberadas, sin hacerlo automáticamente.
- **AC-05** — Dada una excepción con ámbito de facultad, cuando se evalúa, entonces solo afecta a sesiones de esa facultad.

**Trazabilidad:** RF-ACA-008.

---

### US-ACA-05 · Generación automática de sesiones
**M · F1 · 13 pts · EP-04 · US-ACA-03, US-ACA-04, US-PAR-02**

**Como** administrador **quiero** que al activar un periodo se generen automáticamente todas las sesiones de clase expandiendo las franjas contra el calendario **para** disponer de las instancias concretas contra las que se marca, sin captura manual.

**VALOR:** la sesión es la unidad del sistema. Esta historia convierte un horario abstracto en miles de objetos verificables.

**Criterios de aceptación**

- **AC-01** — Dado un periodo con asignaciones, cuando se invoca `POST /periodos/{id}/generar-sesiones`, entonces se crea una sesión por cada ocurrencia de cada franja dentro del rango del periodo, excluyendo las fechas del calendario de excepciones.
- **AC-02** — Dada cada sesión generada, cuando se persiste, entonces incluye congelados: los parámetros efectivos resueltos por la cascada y la versión de geometría vigente del espacio (RN-002).
- **AC-03** — Dada una generación ya ejecutada, cuando se vuelve a invocar, entonces es idempotente: no duplica sesiones existentes y reporta cuántas creó, omitió y actualizó.
- **AC-04** — Dado un periodo de 16 semanas con 2.000 asignaciones, cuando se genera, entonces el proceso completa en ≤ 5 minutos ejecutándose de forma asíncrona, con estado consultable y sin bloquear la API.
- **AC-05** — Dada una generación, cuando finaliza, entonces produce un informe con total de sesiones creadas, fechas excluidas por excepción y asignaciones omitidas con su motivo.
- **AC-06** — Dado un cambio posterior en los parámetros de una sede, cuando se aplica, entonces las sesiones ya generadas conservan sus parámetros congelados salvo regeneración explícita (CA-008).
- **AC-07** — Dada una sesión generada, cuando se consulta, entonces su estado inicial es `PROGRAMADA`.

**Trazabilidad:** RF-ACA-007, RN-002, CA-008.

---

### US-ACA-06 · Cambios puntuales de sesión
**M · F1 · 5 pts · EP-04 · US-ACA-05**

**Como** coordinador **quiero** reprogramar, cambiar de aula o cancelar una sesión concreta **para** reflejar la realidad operativa sin alterar el horario base del periodo.

**Criterios de aceptación**

- **AC-01** — Dada una sesión futura, cuando se reprograma su fecha u hora, entonces se actualiza con motivo obligatorio y responsable, y queda auditada con valores anterior y nuevo.
- **AC-02** — Dada una sesión cuya aula cambia, cuando se guarda, entonces se actualiza el espacio y se congela la versión de geometría del nuevo espacio.
- **AC-03** — Dada una sesión cancelada, cuando el proceso de generación de ausencias se ejecuta, entonces no genera ausencia para ella.
- **AC-04** — Dada una sesión ya iniciada o con marcajes registrados, cuando se intenta modificar, entonces se exige confirmación explícita y se advierte el impacto sobre los marcajes existentes, que no se borran.
- **AC-05** — Dado un cambio de sesión, cuando se aplica, entonces se notifica al docente afectado (si EP-10 está activa).

**Trazabilidad:** RF-ACA-009.

---

### US-ACA-07 · Carga masiva de estructura y horarios
**M · F1 · 8 pts · EP-04 · US-ACA-03**

**Como** administrador **quiero** cargar la estructura académica y los horarios desde CSV o XLSX con validación previa **para** poner en marcha un periodo completo sin captura manual de miles de registros.

**VALOR:** es la única vía realista de arranque dado que la integración con el sistema académico se difiere a F4 (decisión D-5).

**Criterios de aceptación**

- **AC-01** — Dado un archivo CSV o XLSX conforme a la plantilla publicada, cuando se carga, entonces el sistema ejecuta una validación completa **sin persistir** y devuelve un informe por fila con errores y advertencias.
- **AC-02** — Dado un informe con errores, cuando el administrador lo descarga, entonces obtiene el mismo archivo con una columna adicional de diagnóstico por fila.
- **AC-03** — Dada una carga confirmada, cuando se ejecuta, entonces es transaccional por lote: si más del umbral configurado de filas falla, no se aplica nada.
- **AC-04** — Dada una carga con filas que referencian entidades inexistentes (docente, aula, asignatura), cuando se valida, entonces se identifica la entidad faltante y la fila exacta.
- **AC-05** — Dada una carga que produciría colisiones de horario, cuando se valida, entonces se reportan todas las colisiones antes de aplicar, no una por una.
- **AC-06** — Dada una carga aplicada, cuando finaliza, entonces queda auditada con el archivo original almacenado, el actor y el resumen de resultados.

**Trazabilidad:** RF-ACA-011.

---

### US-ACA-08 · Codocencia
**S · F2 · 3 pts · EP-04 · US-ACA-03**

**Como** coordinador **quiero** asignar más de un docente a la misma franja y aula **para** reflejar asignaturas con docencia compartida.

**Criterios de aceptación**

- **AC-01** — Dada una asignación con varios docentes, cuando se crea, entonces todos quedan autorizados a marcar en las sesiones derivadas.
- **AC-02** — Dada una sesión con codocencia, cuando cada docente marca, entonces se registran marcajes independientes sin colisión de idempotencia.
- **AC-03** — Dado el reporte de cumplimiento, cuando se calcula, entonces atribuye la sesión a cada docente conforme a su propio marcaje.
- **AC-04** — Dada una asignación con codocencia, cuando se valida colisión de horario, entonces el solapamiento entre esos docentes no se considera conflicto.

**Trazabilidad:** RF-ACA-006.

---

### US-ACA-09 · Reemplazo docente en sesión específica
**S · F2 · 5 pts · EP-04 · US-ACA-06**

**Como** coordinador **quiero** designar un docente suplente para una sesión puntual **para** que quien realmente dicta la clase pueda marcar y el titular no quede como ausente injustificado.

**Criterios de aceptación**

- **AC-01** — Dada una sesión, cuando se designa un suplente, entonces la autorización de marcaje se transfiere a él para esa sesión únicamente.
- **AC-02** — Dado un suplente designado, cuando el titular intenta marcar, entonces se rechaza con `RECHAZADO_SIN_ASIGNACION` salvo que la configuración permita ambos.
- **AC-03** — Dado un reporte de cumplimiento, cuando incluye una sesión con suplencia, entonces la sesión no se contabiliza como ausencia del titular y se identifica al suplente.
- **AC-04** — Dada una designación de suplencia, cuando se realiza, entonces queda auditada con motivo y responsable.

**Trazabilidad:** RF-ACA-010.

---

### US-ACA-10 · Integración con el sistema académico
**C · F4 · 13 pts · EP-04 · US-ACA-07**

**Como** institución **quiero** sincronizar horarios, docentes y grupos desde el sistema académico vía API **para** eliminar la doble captura y la deriva entre sistemas.

**Criterios de aceptación**

- **AC-01** — Dado un proceso de sincronización, cuando se ejecuta, entonces concilia por `codigoExterno` y reporta altas, bajas, modificaciones y conflictos sin aplicar cambios destructivos automáticamente.
- **AC-02** — Dada una diferencia detectada entre ambos sistemas, cuando se reporta, entonces se indica el campo, el valor en cada sistema y la fecha de última modificación.
- **AC-03** — Dada una sincronización que eliminaría asignaciones con marcajes históricos, cuando se evalúa, entonces se bloquea y se reporta (los datos probatorios nunca se destruyen).
- **AC-04** — Dada una sincronización, cuando falla parcialmente, entonces el sistema queda en estado consistente y el informe indica exactamente qué se aplicó.

**Trazabilidad:** RF-ACA-012, R-09.

---

## EP-05 · Parametrización jerárquica

### US-PAR-01 · Parámetros de holgura, tardanza y GPS
**M · F1 · 8 pts · EP-05 · US-ROL-01**

**Como** administrador **quiero** configurar holguras, umbral de tardanza, precisión GPS máxima y buffer **para** calibrar el sistema a la realidad de cada sede sin redesplegar código.

**VALOR:** es la palanca que permitirá reducir los falsos rechazos por debajo del 2 % durante el piloto. Sin parámetros, cada ajuste sería una nueva versión de la app.

**Criterios de aceptación**

- **AC-01** — Dado el sistema inicializado, cuando se consultan los parámetros globales, entonces existen con los valores por defecto del SRS §3.5: holgura entrada antes 15, holgura entrada después 15, umbral tardanza 10, holgura salida antes 10, holgura salida después 20, precisión GPS máxima 35 m, buffer perimetral 10 m, salida obligatoria falso, offline permitido verdadero, bloqueo de mock location verdadero, promedio de lecturas por vértice 5.
- **AC-02** — Dado un valor fuera del rango admitido de su parámetro, cuando se intenta guardar, entonces se rechaza indicando el rango válido.
- **AC-03** — Dado un cambio de parámetro, cuando se guarda, entonces se registra valor anterior, valor nuevo, autor, fecha y la fecha desde la cual aplica (RF-PAR-009).
- **AC-04** — Dado el parámetro de marcaje de salida, cuando se configura, entonces admite obligatorio, opcional o desactivado.
- **AC-05** — Dados los interruptores de marcaje offline, detección de mock location, bloqueo de dispositivo rooteado y exigencia de verificación complementaria, cuando se configuran por ámbito, entonces se aplican en la evaluación de marcaje sin redespliegue.

**Trazabilidad:** RF-PAR-001..003, RF-PAR-005..007, RF-PAR-009.

---

### US-PAR-02 · Herencia jerárquica de parámetros
**M · F1 · 8 pts · EP-05 · US-PAR-01**

**Como** institución **quiero** que los parámetros se hereden Global → Sede → Facultad → Bloque → Aula → Asignación con precedencia del más específico **para** configurar una vez a nivel general y afinar solo donde hace falta.

**Criterios de aceptación**

- **AC-01** — Dada una clave de parámetro definida en varios niveles, cuando se resuelve para una asignación concreta, entonces prevalece el valor del nivel más específico que la defina.
- **AC-02** — Dada una clave no definida en ningún nivel intermedio, cuando se resuelve, entonces se obtiene el valor global.
- **AC-03** — Dada la resolución, cuando se ejecuta, entonces es por clave individual, no por bloque completo: un nivel puede sobreescribir solo una clave sin arrastrar las demás.
- **AC-04** — Dada la resolución de parámetros, cuando se prueba, entonces existe una batería de pruebas unitarias que cubre cada nivel de la cascada y sus combinaciones.
- **AC-05** — Dada la generación de una sesión, cuando ocurre, entonces invoca esta resolución y congela el resultado en la sesión (RN-002).

**Trazabilidad:** RF-PAR-004, RN-002.

---

### US-PAR-03 · Consulta del parámetro efectivo y su origen
**S · F2 · 5 pts · EP-05 · US-PAR-02**

**Como** administrador **quiero** ver, para cualquier asignación, qué valor está aplicando cada parámetro y de qué nivel proviene **para** diagnosticar comportamientos inesperados sin revisar seis pantallas.

**VALOR:** durante el piloto, la pregunta "¿por qué este docente fue rechazado?" debe responderse en menos de un minuto. Esta pantalla es la herramienta de esa respuesta.

**Criterios de aceptación**

- **AC-01** — Dado un ámbito o asignación, cuando se consulta `GET /parametros/efectivos`, entonces se devuelve cada clave con su valor resuelto y el nivel de origen (global, sede, facultad, bloque, aula o asignación) con su identificador.
- **AC-02** — Dada la consola web, cuando se abre la vista de herencia, entonces se representa visualmente la cascada indicando qué nivel gana cada clave.
- **AC-03** — Dada una sesión ya generada, cuando se consulta, entonces se muestran sus parámetros congelados y se señala si difieren de los efectivos actuales.

**Trazabilidad:** RF-PAR-010.

---

### US-PAR-04 · Parámetros de alerta de asistencia
**S · F3 · 3 pts · EP-05 · US-PAR-01**

**Como** coordinador **quiero** configurar el porcentaje mínimo de asistencia y el número de inasistencias consecutivas que dispara una alerta **para** intervenir temprano en lugar de descubrir el problema al cierre del periodo.

**Criterios de aceptación**

- **AC-01** — Dado el parámetro de porcentaje mínimo, cuando se configura por ámbito, entonces los reportes lo usan como umbral de alerta.
- **AC-02** — Dado el umbral de inasistencias consecutivas, cuando un docente lo alcanza, entonces se genera una alerta dirigida al coordinador de su facultad.
- **AC-03** — Dada una alerta ya emitida para un caso, cuando el conteo sigue creciendo, entonces no se duplica la notificación por cada nueva ausencia; se agrupa.

**Trazabilidad:** RF-PAR-008, RF-NOT-004.

---

## EP-06 · Motor de marcaje

> El corazón del producto. Toda la lógica de decisión vive en el servidor, como función pura y probable sin base de datos ni red (SRS §5.5).

### US-MAR-01 · Pantalla de marcaje de un solo toque
**M · F1 · 8 pts · EP-06 · US-ACA-05, US-PLT-03**

**Como** docente **quiero** abrir la app y ver únicamente mi sesión marcable con un botón grande **para** registrar asistencia en menos de cinco segundos sin navegar ni elegir nada.

**VALOR:** es la promesa central del producto ante el usuario final y el principal factor de adopción. Cada paso añadido aquí reduce la adopción medible.

**Criterios de aceptación**

- **AC-01** — Dado un docente con una sesión dentro de su ventana de holgura, cuando abre la app, entonces la pantalla principal muestra una tarjeta única con asignatura, aula, horario, cuenta regresiva de la ventana y un botón de marcaje prominente.
- **AC-02** — Dado un docente sin sesión marcable en este momento, cuando abre la app, entonces se le informa cuándo abre su próxima ventana, con el botón deshabilitado y el texto correspondiente.
- **AC-03** — Dada la pantalla principal, cuando se cuentan las interacciones necesarias para marcar, entonces es exactamente una: un toque, sin navegación intermedia (RNF-USA-001).
- **AC-04** — Dado el estado del GPS, cuando la app está en la pantalla principal, entonces se muestra un semáforo de precisión con los estados definidos en SRS §9.1: fuera de ventana, buscando GPS, precisión insuficiente, listo, fuera del aula y registrado.
- **AC-05** — Dada la app, cuando no existe ninguna sesión asignada, entonces **no** existe forma alguna de seleccionar un aula manualmente (RF-MAR-002, CA-003).
- **AC-06** — Dado un docente con dos sesiones consecutivas cuyas ventanas se solapan, cuando abre la app, entonces se muestra la sesión cuyo inicio está más próximo a la hora actual, con la posibilidad de ver la otra sin poder inventar una tercera.
- **AC-07** — Dada la consulta de sesión activa, cuando se ejecuta, entonces usa `GET /me/sesiones/activa` y recibe también los parámetros efectivos y la geometría necesaria para el prechequeo local.

**Trazabilidad:** RF-MAR-001, RF-MAR-002, RNF-USA-001, §9.1, CA-003.

---

### US-MAR-02 · Captura de ubicación puntual y señales de integridad
**M · F1 · 8 pts · EP-06 · US-MAR-01**

**Como** institución **quiero** que la app capture la ubicación únicamente en el instante del marcaje, junto con señales de integridad del dispositivo **para** tener evidencia fiable sin rastrear a nadie.

**VALOR:** satisface simultáneamente el requisito probatorio y el compromiso de privacidad que sostiene la aceptación docente (riesgo R-06).

**Criterios de aceptación**

- **AC-01** — Dada la app, cuando solicita permisos de ubicación, entonces pide exclusivamente el permiso "mientras se usa la aplicación"; **nunca** ubicación en segundo plano (RN-005, RF-MAR-016).
- **AC-02** — Dado el toque de marcaje, cuando se ejecuta, entonces se obtiene una lectura de ubicación mediante el proveedor fusionado (GPS + WiFi + red móvil) con tiempo límite configurable, y se descartan lecturas con antigüedad superior a 30 segundos.
- **AC-03** — Dada la lectura, cuando se envía, entonces incluye latitud, longitud, precisión en metros, timestamp del dispositivo, identificador de dispositivo, versión de app y banderas de integridad.
- **AC-04** — Dado un dispositivo con ubicación simulada activa, cuando se detecta, entonces la bandera `mockLocation` se envía en verdadero (RNF-SEG-004).
- **AC-05** — Dado un dispositivo con root, jailbreak o ejecutándose en emulador, cuando se detecta, entonces se reportan las banderas correspondientes.
- **AC-06** — Dada la precisión reportada peor que el umbral configurado, cuando ocurre, entonces la app informa "Señal débil" y ofrece reintento guiado **sin** enviar el marcaje.
- **AC-07** — Dado el usuario que deniega el permiso de ubicación, cuando intenta marcar, entonces se muestra una explicación accionable de por qué es necesario y cómo reactivarlo en los ajustes del sistema (mitigación R-10).
- **AC-08** — Dada la app en cualquier estado, cuando se inspecciona, entonces no existe ningún servicio de ubicación en segundo plano ni suscripción continua a cambios de posición.

**Trazabilidad:** RF-MAR-006, RF-MAR-016, RNF-SEG-004, RNF-LEG-002, RN-005, R-10.

---

### US-MAR-03 · Motor de validación en servidor
**M · F1 · 13 pts · EP-06 · US-MAR-02, US-GEO-08, US-PAR-02**

**Como** institución **quiero** que la decisión de aceptar o rechazar un marcaje se tome exclusivamente en el servidor siguiendo un algoritmo determinista **para** que el resultado sea confiable, reproducible y no manipulable desde el cliente.

**VALOR:** es la regla de negocio central (RN-001). Su corrección determina el valor probatorio de todo el sistema.

**Criterios de aceptación**

- **AC-01** — Dado un marcaje recibido, cuando se evalúa, entonces se ejecutan los 11 pasos de RN-001 **en orden**, deteniéndose en el primer fallo, y el resultado incluye el paso que falló.
- **AC-02** — Dado un usuario sin token válido, sin usuario activo o sin permiso `marcaje:crear`, cuando marca, entonces recibe 401 o 403 según corresponda (paso 1).
- **AC-03** — Dado un dispositivo que no coincide con el vinculado al usuario, cuando marca, entonces el resultado es `RECHAZADO_INTEGRIDAD` (paso 2).
- **AC-04** — Dada la atestación de app activada y no válida, cuando se marca, entonces el resultado es `RECHAZADO_INTEGRIDAD` (paso 3).
- **AC-05** — Dada la inexistencia de una sesión del usuario en la ventana temporal actual, cuando marca, entonces el resultado es `RECHAZADO_SIN_ASIGNACION` (paso 4).
- **AC-06** — Dada la hora de servidor fuera del intervalo [inicio − holguraAntes, inicio + holguraDespués], cuando se evalúa, entonces el resultado es `RECHAZADO_FUERA_DE_HORARIO` con los minutos de desviación informados (paso 5).
- **AC-07** — Dada una precisión reportada mayor que el máximo configurado, cuando se evalúa, entonces el resultado es `PRECISION_INSUFICIENTE`, que **permite reintento** y no consume idempotencia (paso 6).
- **AC-08** — Dada la bandera de ubicación simulada en verdadero con el bloqueo activo, cuando se evalúa, entonces el resultado es `RECHAZADO_INTEGRIDAD` y se registra en auditoría (paso 7, CA-006).
- **AC-09** — Dado un punto que no intersecta la geometría con buffer del espacio de la sesión, cuando se evalúa, entonces el resultado es `RECHAZADO_FUERA_DE_AREA` y se informa la distancia en metros al espacio (paso 8, CA-002).
- **AC-10** — Dada una verificación complementaria exigida y no coincidente, cuando se evalúa, entonces el resultado es `RECHAZADO_VERIFICACION` (paso 9).
- **AC-11** — Dado un marcaje previo del mismo tipo para la misma sesión y usuario, cuando llega otro, entonces se devuelve el marcaje existente sin crear uno nuevo (paso 10, idempotencia).
- **AC-12** — Dados minutos respecto al inicio menores o iguales al umbral de tardanza, cuando se clasifica, entonces el resultado es `PRESENTE`; en caso contrario `TARDANZA` (paso 11, CA-005).
- **AC-13** — Dado el motor de validación, cuando se implementa, entonces reside en la capa de dominio como **función pura**, sin dependencias de base de datos ni de red, y es probable de forma aislada (SRS §5.5).
- **AC-14** — Dado el motor de validación, cuando se mide su cobertura de pruebas, entonces es ≥ 90 % (RNF-MAN-001).
- **AC-15** — Dada una sesión de modalidad virtual, cuando se evalúa, entonces los pasos geoespaciales se omiten y el marcaje se clasifica solo por tiempo.
- **AC-16** — Dada la evaluación completa, cuando se cronometra en condiciones de carga objetivo, entonces se resuelve en ≤ 2 s p95 desde el toque hasta la confirmación (RNF-PER-001, CA-001).

**Trazabilidad:** RN-001, RF-MAR-003..005, RF-MAR-007, RNF-PER-001, RNF-MAN-001, CA-001..006.

---

### US-MAR-04 · Registro del marcaje con evidencia completa
**M · F1 · 5 pts · EP-06 · US-MAR-03**

**Como** auditor **quiero** que cada marcaje conserve toda la evidencia técnica de su evaluación **para** poder reconstruir y defender la decisión meses después.

**Criterios de aceptación**

- **AC-01** — Dado un marcaje evaluado, cuando se persiste, entonces almacena: sesión, usuario, rol de marcaje, tipo, resultado, motivo de rechazo, ubicación como punto GeoJSON, precisión, distancia al centroide, indicador de contención, timestamps de servidor y dispositivo, desfase de reloj en segundos, minutos respecto al inicio, identificador de dispositivo, versión de app, banderas de integridad, verificación complementaria y origen.
- **AC-02** — Dado un desfase entre la hora del dispositivo y la del servidor superior al umbral configurado, cuando se registra, entonces se marca como anomalía y queda visible para revisión (RF-MAR-005).
- **AC-03** — Dado un marcaje rechazado, cuando se procesa, entonces **también se persiste**; los rechazos no se descartan (RF-AUD-004).
- **AC-04** — Dada la colección de marcajes, cuando se inspecciona, entonces existe un índice único sobre sesión + usuario + tipo que garantiza la idempotencia a nivel de base de datos (CA-012).
- **AC-05** — Dado un marcaje registrado, cuando el docente consulta su historial, entonces aparece de inmediato (CA-001).

**Trazabilidad:** RF-MAR-006, RF-MAR-005, RF-AUD-004, §6.2, §6.3, CA-001, CA-012.

---

### US-MAR-05 · Idempotencia del marcaje
**M · F1 · 5 pts · EP-06 · US-MAR-04**

**Como** docente **quiero** que un doble toque accidental no genere dos registros **para** no aparecer con marcajes duplicados ni provocar una inconsistencia en mi reporte.

**Criterios de aceptación**

- **AC-01** — Dados dos toques en menos de un segundo, cuando ambas peticiones llegan al servidor, entonces se registra exactamente un marcaje y ambas respuestas devuelven el mismo identificador (CA-012).
- **AC-02** — Dada una petición con `idempotencyKey` ya procesada, cuando se recibe de nuevo, entonces se devuelve la respuesta original sin reevaluar.
- **AC-03** — Dado el índice único de base de datos, cuando se produce una condición de carrera, entonces el error de clave duplicada se traduce en la devolución del registro existente, nunca en un error 500.
- **AC-04** — Dada la app, cuando se pulsa el botón, entonces se deshabilita de inmediato hasta recibir respuesta o expirar el tiempo límite.
- **AC-05** — Dado un resultado `PRECISION_INSUFICIENTE`, cuando el usuario reintenta, entonces el reintento sí se procesa: ese resultado no consume la idempotencia.

**Trazabilidad:** RF-MAR-008, CA-012, §6.3.

---

### US-MAR-06 · Mensajes de rechazo accionables
**M · F1 · 5 pts · EP-06 · US-MAR-03**

**Como** docente rechazado **quiero** entender exactamente por qué y qué hacer **para** resolverlo en el momento en lugar de quedarme sin registro y sin explicación.

**VALOR:** un rechazo incomprensible genera una queja formal; un rechazo explicado genera una corrección en 20 segundos. Impacto directo sobre el riesgo R-06.

**Criterios de aceptación**

- **AC-01** — Dado un rechazo por área, cuando se muestra, entonces el mensaje indica la distancia concreta y el aula esperada, por ejemplo "Estás a 48 m del aula A-301" (SRS §9.1, CA-002).
- **AC-02** — Dado un rechazo por horario, cuando se muestra, entonces indica los minutos fuera de la ventana y a qué hora se cerró o abrirá.
- **AC-03** — Dado un rechazo por precisión, cuando se muestra, entonces indica la precisión actual, la requerida y sugiere una acción concreta (acercarse a una ventana, esperar unos segundos).
- **AC-04** — Dado un rechazo por integridad, cuando se muestra, entonces se comunica sin acusar, indicando el motivo técnico y el canal para reportar si el usuario considera que es un error.
- **AC-05** — Dado cualquier mensaje de error del sistema, cuando se redacta, entonces responde a qué pasó, por qué y qué hacer (RNF-USA-005).
- **AC-06** — Dado cualquier rechazo, cuando se muestra, entonces se ofrece el acceso directo a radicar una justificación (cuando EP-07 esté disponible).

**Trazabilidad:** RF-MAR-009, RNF-USA-005, §9.1, CA-002.

---

### US-MAR-07 · Generación automática de ausencias
**M · F1 · 5 pts · EP-06 · US-MAR-04**

**Como** coordinador **quiero** que las sesiones cuya ventana expiró sin marcaje válido queden registradas como ausencia automáticamente **para** que el reporte refleje la realidad sin intervención manual.

**Criterios de aceptación**

- **AC-01** — Dado un proceso programado que se ejecuta cada 15 minutos, cuando encuentra sesiones cuya ventana de entrada expiró sin marcaje válido, entonces las marca como `AUSENTE` (RN-003).
- **AC-02** — Dada una sesión cancelada o de fecha excluida por el calendario, cuando se evalúa, entonces **no** se genera ausencia.
- **AC-03** — Dada una sesión con suplente designado, cuando se evalúa, entonces la ausencia se atribuye conforme a la regla de suplencia y no al titular.
- **AC-04** — Dado el proceso, cuando se ejecuta dos veces sobre la misma sesión, entonces es idempotente y no duplica registros.
- **AC-05** — Dado un marcaje offline que llega después de generada la ausencia, cuando se sincroniza y resulta válido, entonces la ausencia se revierte y el cambio queda auditado.
- **AC-06** — Dado el proceso, cuando falla, entonces se registra el error, se alerta y el siguiente ciclo reintenta sin pérdida de sesiones.

**Trazabilidad:** RF-MAR-011, RN-003.

---

### US-MAR-08 · Historial propio del usuario
**M · F1 · 5 pts · EP-06 · US-MAR-04**

**Como** docente **quiero** ver mi historial de marcajes con su estado **para** verificar mi propio registro y detectar errores antes de que lleguen a un reporte institucional.

**VALOR:** la transparencia del docente sobre su propio dato es una mitigación explícita del riesgo R-06 y un derecho del titular bajo la Ley 1581.

**Criterios de aceptación**

- **AC-01** — Dado un docente, cuando consulta `GET /me/historial`, entonces obtiene sus marcajes paginados en orden cronológico inverso, con filtro por mes.
- **AC-02** — Dada la lista, cuando se presenta, entonces cada entrada muestra estado codificado por color usando exclusivamente los colores semánticos verde, ámbar y rojo (SRS §9.3).
- **AC-03** — Dado un marcaje rechazado en el historial, cuando se abre, entonces se muestra el motivo y la evidencia relevante (distancia, minutos, precisión).
- **AC-04** — Dado un usuario, cuando intenta consultar el historial de otro, entonces recibe 403.
- **AC-05** — Dado un historial de un periodo completo, cuando se carga, entonces responde en ≤ 1 s para 500 registros usando el índice de usuario y fecha.

**Trazabilidad:** RF-MAR-006, §9.1, RNF-LEG-004.

---

### US-MAR-09 · Ajuste administrativo de marcajes
**M · F1 · 5 pts · EP-06 · US-MAR-04, US-AUD-01**

**Como** administrador **quiero** anular, ajustar o crear un marcaje manualmente con motivo obligatorio **para** corregir fallas técnicas comprobadas sin destruir la trazabilidad.

**Criterios de aceptación**

- **AC-01** — Dado un administrador con permiso `marcaje:ajustar`, cuando modifica un marcaje, entonces se exige motivo textual obligatorio de al menos 20 caracteres.
- **AC-02** — Dado un ajuste, cuando se aplica, entonces el registro original se conserva y el marcaje refleja quién lo ajustó, cuándo y por qué (`ajustadoPor`).
- **AC-03** — Dada una anulación, cuando se ejecuta, entonces el marcaje pasa a estado anulado sin borrarse físicamente.
- **AC-04** — Dado un marcaje creado manualmente, cuando se registra, entonces su origen se marca como `MANUAL` y se distingue visiblemente en reportes e historial.
- **AC-05** — Dado un docente o coordinador sin el permiso, cuando intenta ajustar, entonces recibe 403.
- **AC-06** — Dado cualquier ajuste, cuando ocurre, entonces genera una entrada de auditoría con valores anterior y nuevo completos.

**Trazabilidad:** RF-MAR-014, RF-AUD-001, RF-AUD-002.

---

### US-MAR-10 · Bloqueo por integridad y atestación de aplicación
**M · F1 · 8 pts · EP-06 · US-MAR-03, US-AUT-03**

**Como** institución **quiero** rechazar marcajes provenientes de ubicaciones falsificadas o instalaciones no legítimas **para** que la evidencia no pueda fabricarse con una app de GPS falso.

**VALOR:** mitiga el riesgo R-03. Sin esto, todo el sistema es un formulario de honor con pasos adicionales.

**Criterios de aceptación**

- **AC-01** — Dada la bandera de ubicación simulada en verdadero y el bloqueo activo para el ámbito, cuando se marca, entonces se rechaza con `RECHAZADO_INTEGRIDAD` y se registra el evento en auditoría (CA-006).
- **AC-02** — Dada la atestación de aplicación activada, cuando la petición no proviene de una instalación legítima verificada por el servicio de la plataforma, entonces se rechaza (RNF-SEG-006).
- **AC-03** — Dado un dispositivo con root o jailbreak y el bloqueo activo, cuando se marca, entonces se rechaza; con el bloqueo inactivo, se acepta pero se registra la bandera.
- **AC-04** — Dados dos marcajes del mismo usuario cuya distancia geográfica es imposible de recorrer en el tiempo transcurrido, cuando se evalúa, entonces se genera una alerta de anomalía revisable (análisis de saltos imposibles, R-03).
- **AC-05** — Dado un mismo identificador de dispositivo usado por múltiples usuarios, cuando se detecta, entonces se genera alerta de anomalía.
- **AC-06** — Dado el bloqueo por integridad, cuando se configura, entonces es un parámetro por ámbito y puede desactivarse sin redespliegue si genera falsos positivos en el piloto.

**Trazabilidad:** RF-MAR-007, RNF-SEG-004, RNF-SEG-006, R-03, CA-006.

---

### US-MAR-11 · Marcaje sin conexión
**S · F3 · 13 pts · EP-06 · US-MAR-03**

**Como** docente en un aula sin cobertura **quiero** que mi marcaje se encole y se sincronice al recuperar señal **para** no quedar ausente por una limitación de la red institucional.

**Criterios de aceptación**

- **AC-01** — Dado un dispositivo sin conectividad y el marcaje offline permitido, cuando el docente marca, entonces el intento se encola localmente cifrado, con timestamp de dispositivo, coordenadas e identificador único, y la interfaz confirma "pendiente de sincronización".
- **AC-02** — Dada la recuperación de conexión, cuando la app detecta red, entonces envía la cola mediante `POST /marcajes/sync` en lote.
- **AC-03** — Dado un marcaje sincronizado, cuando el servidor lo evalúa, entonces reevalúa la ventana temporal usando el timestamp del dispositivo, pero registra el origen como `OFFLINE` (RN-004).
- **AC-04** — Dado un desfase de reloj del dispositivo superior al umbral configurado, cuando se sincroniza, entonces el marcaje se somete a revisión y no se acepta automáticamente.
- **AC-05** — Dado un marcaje offline sincronizado 40 minutos después, cuando se procesa, entonces conserva la hora original, se registra como offline y queda visible para revisión (CA-009).
- **AC-06** — Dada una cola con varios elementos, cuando se sincroniza, entonces cada uno se resuelve de forma independiente y un fallo no bloquea a los demás.
- **AC-07** — Dado el marcaje offline desactivado para el ámbito, cuando el docente marca sin conexión, entonces se le informa que debe conectarse, sin encolar.

**Notas de producto:** esta historia es el principal vector de fraude residual (manipular la hora del dispositivo). La revisión por desfase de reloj no es opcional.

**Trazabilidad:** RF-MAR-010, RN-004, CA-009, RNF-DIS-002.

---

### US-MAR-12 · Aviso de cierre inminente de ventana
**S · F3 · 3 pts · EP-06 · US-MAR-01, US-NOT-01**

**Como** docente **quiero** recibir un aviso antes de que se cierre mi ventana de marcaje **para** no perder el registro de una clase que sí estoy dictando.

**Criterios de aceptación**

- **AC-01** — Dado un docente con una sesión sin marcaje y una ventana que cierra en N minutos (configurable, por defecto 5), cuando se alcanza ese momento, entonces se envía notificación push.
- **AC-02** — Dado un docente que ya marcó, cuando se evalúa el envío, entonces no se le notifica.
- **AC-03** — Dada la notificación, cuando se toca, entonces abre directamente la pantalla de marcaje con la sesión cargada.

**Trazabilidad:** RF-MAR-015, RF-NOT-002.

---

### US-MAR-13 · Marcaje estudiantil
**S · F3 · 13 pts · EP-06 · US-MAR-03**

**Como** docente **quiero** abrir y cerrar una ventana de marcaje para mis estudiantes dentro de la sesión **para** registrar asistencia del grupo bajo las mismas garantías de ubicación y tiempo.

**Criterios de aceptación**

- **AC-01** — Dada una sesión activa, cuando el docente abre la ventana estudiantil, entonces los estudiantes del grupo pueden marcar durante el intervalo definido.
- **AC-02** — Dado un estudiante, cuando marca, entonces se aplican exactamente las mismas reglas del motor de validación con `rolMarcaje = ESTUDIANTE`.
- **AC-03** — Dado un estudiante que no pertenece al grupo, cuando intenta marcar, entonces se rechaza con `RECHAZADO_SIN_ASIGNACION`.
- **AC-04** — Dada la ventana estudiantil cerrada, cuando un estudiante intenta marcar, entonces se rechaza por horario.
- **AC-05** — Dado un estudiante, cuando consulta su perfil, entonces ve su porcentaje de asistencia acumulado por asignatura.
- **AC-06** — Dado el pico de 40 estudiantes marcando en el mismo minuto y aula, cuando ocurre, entonces el sistema mantiene la latencia objetivo.

**Trazabilidad:** RF-MAR-012, RF-REP-003.

---

### US-MAR-14 · Lista de asistencia manual como respaldo
**S · F3 · 5 pts · EP-06 · US-MAR-13**

**Como** docente **quiero** disponer de una lista manual del grupo cuando la tecnología falla **para** no perder el registro de la clase, aceptando que su uso quede auditado.

**Criterios de aceptación**

- **AC-01** — Dada una sesión activa, cuando el docente abre la lista manual, entonces ve a los estudiantes del grupo y puede marcarlos presentes o ausentes.
- **AC-02** — Dado un registro por lista manual, cuando se guarda, entonces su origen es `MANUAL_DOCENTE` y se distingue en todos los reportes.
- **AC-03** — Dado el uso de la lista manual, cuando ocurre, entonces se exige motivo y queda auditado con el actor.
- **AC-04** — Dado un estudiante que ya marcó por geolocalización, cuando el docente usa la lista manual, entonces el marcaje geolocalizado prevalece y no se sobrescribe.

**Trazabilidad:** RF-MAR-013.

---

### US-MAR-15 · Marcaje de salida
**S · F3 · 5 pts · EP-06 · US-MAR-03, US-PAR-01**

**Como** institución **quiero** poder exigir, permitir o desactivar el marcaje de salida **para** adaptar el control a la política que se adopte sin cambiar el producto.

**Criterios de aceptación**

- **AC-01** — Dado el parámetro de salida en obligatorio, cuando la sesión termina sin marcaje de salida, entonces se registra la novedad correspondiente en el reporte.
- **AC-02** — Dado el parámetro en opcional, cuando el docente marca salida, entonces se registra y se calcula la permanencia efectiva.
- **AC-03** — Dado el parámetro desactivado, cuando el docente abre la app tras la clase, entonces no se le ofrece marcar salida.
- **AC-04** — Dado un marcaje de salida, cuando se evalúa, entonces se aplican las holguras de salida configuradas y las mismas validaciones espaciales y de integridad.

**Trazabilidad:** RF-PAR-002, RF-MAR-007.
---

## EP-07 · Justificaciones y novedades

### US-JUS-01 · Radicación de justificación con evidencia
**S · F3 · 8 pts · EP-07 · US-MAR-08**

**Como** docente **quiero** radicar una justificación sobre una sesión ausente o rechazada adjuntando evidencia **para** que mi situación real quede registrada y no quede como incumplimiento.

**VALOR:** es la válvula de escape del sistema. Sin un canal ágil de excepción, cada falso rechazo se convierte en un conflicto laboral. Mitigación directa de R-06.

**Criterios de aceptación**

- **AC-01** — Dada una sesión con resultado ausente o rechazado, cuando el docente radica una justificación, entonces selecciona un tipo de novedad (incapacidad, comisión, permiso, falla técnica, calamidad), escribe una descripción y adjunta evidencia en imagen o PDF.
- **AC-02** — Dado un adjunto, cuando se sube, entonces se valida tipo y tamaño (≤ 10 MB), se almacena cifrado y no es accesible sin autorización.
- **AC-03** — Dada una justificación radicada, cuando se guarda, entonces queda en estado `RADICADA` con fecha, autor y sesión asociada.
- **AC-04** — Dada una sesión que ya tiene una justificación en curso, cuando se intenta radicar otra, entonces se impide y se muestra la existente.
- **AC-05** — Dado un plazo máximo configurable para radicar (por defecto 5 días hábiles tras la sesión), cuando se excede, entonces se impide la radicación ordinaria y se informa el canal alterno.

**Trazabilidad:** RF-JUS-001, RF-JUS-003.

---

### US-JUS-02 · Flujo de aprobación de justificaciones
**S · F3 · 8 pts · EP-07 · US-JUS-01, US-ROL-02**

**Como** coordinador **quiero** revisar, aprobar o rechazar justificaciones de mi facultad con observaciones **para** resolver excepciones con trazabilidad y criterio documentado.

**Criterios de aceptación**

- **AC-01** — Dada una justificación radicada, cuando el revisor la toma, entonces pasa a `EN_REVISION` con responsable asignado.
- **AC-02** — Dada una justificación en revisión, cuando el revisor decide, entonces pasa a `APROBADA` o `RECHAZADA` con observaciones obligatorias en caso de rechazo.
- **AC-03** — Dado un usuario sin permiso `justificacion:aprobar`, cuando intenta decidir, entonces recibe 403.
- **AC-04** — Dado un coordinador, cuando consulta la bandeja, entonces solo ve justificaciones de docentes de su ámbito (ABAC).
- **AC-05** — Dada una justificación de un docente, cuando el mismo docente intenta aprobarla, entonces se impide aunque tenga el permiso (separación de funciones).
- **AC-06** — Dado cada cambio de estado, cuando ocurre, entonces queda auditado con actor, estado anterior, estado nuevo y observaciones.

**Trazabilidad:** RF-JUS-002.

---

### US-JUS-03 · Efecto de la justificación aprobada en el reporte
**S · F3 · 5 pts · EP-07 · US-JUS-02, US-REP-01**

**Como** institución **quiero** que una justificación aprobada se refleje en el reporte sin borrar el evento original **para** conservar la integridad probatoria del registro.

**Criterios de aceptación**

- **AC-01** — Dada una justificación aprobada sobre una ausencia, cuando se genera el reporte, entonces la sesión aparece como `AUSENCIA_JUSTIFICADA` y el marcaje o ausencia original permanece intacto en la base de datos.
- **AC-02** — Dado el reporte de cumplimiento, cuando se calcula, entonces distingue ausencias justificadas de injustificadas en columnas separadas.
- **AC-03** — Dada una justificación aprobada por falla técnica del sistema, cuando se agrega, entonces alimenta el indicador de falsos rechazos usado como criterio de salida del piloto.
- **AC-04** — Dada una justificación rechazada, cuando se procesa, entonces el estado del evento original no cambia.

**Trazabilidad:** RF-JUS-004, métrica de falsos rechazos.

---

### US-JUS-04 · Notificación del resultado de la justificación
**S · F3 · 3 pts · EP-07 · US-JUS-02, US-NOT-01**

**Como** docente **quiero** enterarme del resultado de mi justificación sin tener que consultar **para** cerrar el asunto sin seguimiento manual.

**Criterios de aceptación**

- **AC-01** — Dada una justificación resuelta, cuando cambia a aprobada o rechazada, entonces se notifica al solicitante por push y correo con el resultado y las observaciones.
- **AC-02** — Dada una justificación sin resolver tras el plazo configurado (por defecto 48 h), cuando se cumple, entonces se recuerda al revisor asignado.

**Trazabilidad:** RF-JUS-005, RF-NOT-002.

---

## EP-08 · Reportes e indicadores

### US-REP-01 · Reporte de cumplimiento docente
**M · F1 · 8 pts · EP-08 · US-MAR-07, US-ROL-02**

**Como** coordinador o talento humano **quiero** un reporte de cumplimiento por docente con horas programadas, dictadas, tardanzas y ausencias **para** disponer de la evidencia consolidada que justifica la existencia del sistema.

**VALOR:** este reporte **es** el entregable que consume la institución. Sin él, todo lo demás es infraestructura sin resultado visible.

**Criterios de aceptación**

- **AC-01** — Dado un periodo y un ámbito, cuando se consulta el reporte, entonces se obtiene por docente: horas programadas, horas dictadas, sesiones presentes, tardanzas, ausencias justificadas, ausencias injustificadas y porcentaje de cumplimiento.
- **AC-02** — Dado un coordinador, cuando consulta, entonces solo obtiene datos de su ámbito y cualquier intento de ampliarlo devuelve 403 auditado (CA-010).
- **AC-03** — Dado un filtro por periodo, facultad, programa, docente o rango de fechas, cuando se aplica, entonces el resultado se restringe correctamente.
- **AC-04** — Dado un reporte sobre un periodo completo de una facultad con 200 docentes, cuando se genera, entonces responde en ≤ 5 s o se entrega de forma asíncrona con notificación.
- **AC-05** — Dado un marcaje ajustado manualmente, cuando aparece en el reporte, entonces se identifica como tal.
- **AC-06** — Dadas las cifras del reporte, cuando se recalculan, entonces son deterministas y reproducibles para el mismo rango de fechas.

**Trazabilidad:** RF-REP-001, RF-ROL-003, CA-010.

---

### US-REP-02 · Exportación a XLSX y PDF
**M · F1 · 5 pts · EP-08 · US-REP-01**

**Como** talento humano **quiero** exportar cualquier reporte a XLSX y PDF con sello institucional **para** anexarlo a procesos administrativos formales.

**Criterios de aceptación**

- **AC-01** — Dado un reporte en pantalla, cuando se exporta a XLSX, entonces el archivo conserva los mismos filtros, columnas y totales, con datos tipados correctamente (fechas como fecha, números como número).
- **AC-02** — Dado un reporte exportado a PDF, cuando se genera, entonces incluye marca de agua institucional, sello de fecha y hora de generación, usuario que lo generó y el rango consultado.
- **AC-03** — Dado un PDF generado, cuando se verifica, entonces incluye el hash SHA-256 de su contenido de datos, permitiendo comprobar que no fue alterado (decisión D-7).
- **AC-04** — Dada una exportación, cuando se ejecuta, entonces queda registrada en auditoría con el usuario, el filtro aplicado y el número de registros exportados.
- **AC-05** — Dado un usuario sin permiso `reporte:exportar`, cuando lo intenta, entonces recibe 403.

**Trazabilidad:** RF-REP-004, D-7.

---

### US-REP-03 · Tablero de indicadores en vivo
**S · F3 · 8 pts · EP-08 · US-REP-01**

**Como** directivo **quiero** un tablero con el pulso del día **para** detectar problemas mientras aún puedo actuar sobre ellos.

**Criterios de aceptación**

- **AC-01** — Dado el tablero, cuando se abre, entonces muestra sesiones del día, marcajes efectuados, sesiones en curso sin marcaje y alertas activas, respetando el ámbito del usuario.
- **AC-02** — Dado el tablero abierto, cuando transcurre el tiempo, entonces se actualiza con desfase aleatorio para no contribuir al pico de carga.
- **AC-03** — Dada una sesión en curso sin marcaje, cuando aparece en el tablero, entonces permite ver el detalle de docente, aula y hora.
- **AC-04** — Dado el tablero, cuando se consulta, entonces sus consultas usan agregaciones precalculadas y no escanean la colección de marcajes completa.

**Trazabilidad:** RF-REP-005.

---

### US-REP-04 · Reporte de ocupación de espacios
**S · F3 · 5 pts · EP-08 · US-REP-01**

**Como** administrador de planta física **quiero** conocer el uso real de aulas, bloques y sedes **para** tomar decisiones de asignación de espacios con datos.

**Criterios de aceptación**

- **AC-01** — Dado un rango de fechas, cuando se consulta, entonces se obtiene por espacio: horas programadas, horas con asistencia confirmada y porcentaje de utilización.
- **AC-02** — Dada la agregación, cuando se presenta, entonces puede verse por aula, bloque o sede.
- **AC-03** — Dado el reporte, cuando se exporta, entonces aplica US-REP-02.

**Trazabilidad:** RF-REP-002.

---

### US-REP-05 · Reporte de asistencia estudiantil
**S · F3 · 5 pts · EP-08 · US-MAR-13**

**Como** docente o coordinador **quiero** el porcentaje de asistencia por grupo y por estudiante **para** aplicar las reglas de permanencia académica con evidencia.

**Criterios de aceptación**

- **AC-01** — Dado un grupo y un periodo, cuando se consulta, entonces se obtiene el porcentaje acumulado por estudiante y el promedio del grupo.
- **AC-02** — Dado un estudiante bajo el umbral mínimo configurado, cuando aparece en el reporte, entonces se destaca visualmente.
- **AC-03** — Dado un estudiante, cuando consulta su propio porcentaje en la app, entonces coincide exactamente con el del reporte del docente.

**Trazabilidad:** RF-REP-003, RF-PAR-008.

---

### US-REP-06 · Mapa de calor de rechazos por aula
**C · F4 · 5 pts · EP-08 · US-MAR-04**

**Como** administrador **quiero** ver qué aulas concentran marcajes rechazados por área **para** identificar geocercos mal calibrados y corregirlos con datos en lugar de por queja.

**VALOR:** convierte la calibración del piloto de un proceso reactivo a uno dirigido. Herramienta directa para alcanzar el criterio de falsos rechazos < 2 %.

**Criterios de aceptación**

- **AC-01** — Dado un rango de fechas, cuando se consulta el mapa de calor, entonces se muestran los espacios coloreados por tasa de rechazo por área.
- **AC-02** — Dado un espacio con tasa de rechazo superior al umbral, cuando se selecciona, entonces se visualizan los puntos de los marcajes rechazados sobre el polígono, revelando si el error es sistemático y en qué dirección.
- **AC-03** — Dada esa vista, cuando el administrador ajusta el buffer, entonces puede previsualizar cuántos de los rechazos históricos habrían sido aceptados con el nuevo valor.

**Trazabilidad:** RF-REP-006, R-02.

---

### US-REP-07 · Envío programado de reportes
**C · F4 · 3 pts · EP-08 · US-REP-02**

**Como** talento humano **quiero** recibir reportes por correo con la periodicidad que defina **para** no depender de entrar a consultarlos.

**Criterios de aceptación**

- **AC-01** — Dada una programación con destinatarios, filtro y periodicidad, cuando llega el momento, entonces se genera y envía el reporte adjunto.
- **AC-02** — Dado un envío, cuando se ejecuta, entonces respeta el ámbito del destinatario: nunca se envía información fuera de su alcance.
- **AC-03** — Dado un fallo de envío, cuando ocurre, entonces se reintenta y se registra.

**Trazabilidad:** RF-REP-007.

---

## EP-09 · Auditoría y trazabilidad

### US-AUD-01 · Bitácora inmutable de operaciones sensibles
**M · F1 · 8 pts · EP-09 · US-PLT-01**

**Como** auditor **quiero** que toda creación, modificación o eliminación sobre entidades sensibles quede registrada de forma inalterable **para** sostener la validez probatoria del sistema ante cualquier reclamo.

**VALOR:** requisito legal y condición para que el sistema sea usable como instrumento de control laboral (RNF-LEG-007).

**Criterios de aceptación**

- **AC-01** — Dada una operación sobre marcajes, asignaciones, geometrías, parámetros o roles, cuando se ejecuta, entonces se genera automáticamente una entrada de auditoría.
- **AC-02** — Dada una entrada de auditoría, cuando se crea, entonces contiene actor, rol activo, acción, entidad, identificador, valor anterior, valor nuevo, dirección IP, agente de usuario y timestamp de servidor (RF-AUD-002).
- **AC-03** — Dada la bitácora, cuando se intenta editar o eliminar una entrada desde la aplicación, entonces se impide por diseño: no existe endpoint de escritura ni de borrado sobre auditoría.
- **AC-04** — Dado el mecanismo de auditoría, cuando se implementa, entonces opera como decorador o middleware transversal, no como llamadas dispersas en cada caso de uso.
- **AC-05** — Dado un fallo al escribir la auditoría de una operación sensible, cuando ocurre, entonces la operación de negocio se revierte: no hay escritura sensible sin rastro.
- **AC-06** — Dadas las entidades operativas, cuando se eliminan, entonces se aplica borrado lógico (RF-AUD-005).

**Trazabilidad:** RF-AUD-001, RF-AUD-002, RF-AUD-003, RF-AUD-005.

---

### US-AUD-02 · Registro de intentos rechazados
**M · F1 · 3 pts · EP-09 · US-AUD-01, US-MAR-04**

**Como** auditor **quiero** que los intentos de marcaje rechazados también queden registrados **para** detectar patrones de fraude y geocercos mal calibrados.

**Criterios de aceptación**

- **AC-01** — Dado un marcaje rechazado por cualquier motivo, cuando se procesa, entonces se persiste el intento con su resultado y evidencia completa.
- **AC-02** — Dado un rechazo por integridad, cuando ocurre, entonces adicionalmente se registra un evento de seguridad en la bitácora de auditoría.
- **AC-03** — Dados los intentos rechazados, cuando se consultan, entonces pueden filtrarse por motivo, usuario, espacio y rango de fechas.

**Trazabilidad:** RF-AUD-004.

---

### US-AUD-03 · Consulta y exportación de la bitácora
**S · F3 · 5 pts · EP-09 · US-AUD-01**

**Como** auditor **quiero** consultar y exportar la bitácora con filtros **para** producir evidencia en una investigación concreta.

**Criterios de aceptación**

- **AC-01** — Dado un auditor, cuando consulta la bitácora, entonces puede filtrar por entidad, identificador, actor, acción y rango de fechas, con resultados paginados.
- **AC-02** — Dada una consulta, cuando se ejecuta, entonces usa el índice compuesto de entidad, identificador y fecha, sin escaneo de colección.
- **AC-03** — Dada una exportación de bitácora, cuando se realiza, entonces ella misma queda auditada.
- **AC-04** — Dado un usuario sin permiso `auditoria:leer`, cuando lo intenta, entonces recibe 403.

**Trazabilidad:** RF-AUD-003.

---

### US-AUD-04 · Retención y política de datos
**S · F3 · 5 pts · EP-09 · US-AUD-01**

**Como** oficial de protección de datos **quiero** que los datos se retengan y luego se anonimicen conforme a la política institucional **para** cumplir el principio de finalidad de la Ley 1581.

**Criterios de aceptación**

- **AC-01** — Dada una política de retención configurada, cuando un dato de marcaje excede el plazo, entonces se anonimiza o elimina según lo definido, conservando agregados estadísticos no identificables.
- **AC-02** — Dado un proceso de anonimización, cuando se ejecuta, entonces queda registrado con el volumen afectado y el criterio aplicado.
- **AC-03** — Dada una investigación en curso marcada sobre un registro, cuando llega su plazo de retención, entonces se suspende la eliminación y se notifica.

**Trazabilidad:** RNF-LEG-006.

---

## EP-10 · Notificaciones

### US-NOT-01 · Infraestructura de notificaciones push
**S · F3 · 8 pts · EP-10 · US-AUT-03**

**Como** sistema **quiero** una capa de envío push multiplataforma con registro de tokens **para** poder comunicarme con los usuarios de forma fiable.

**Criterios de aceptación**

- **AC-01** — Dada la app instalada y con sesión, cuando arranca, entonces registra su token de notificaciones asociado al usuario y dispositivo.
- **AC-02** — Dado un envío, cuando se ejecuta, entonces llega a Android e iOS mediante los servicios correspondientes de cada plataforma.
- **AC-03** — Dado un token inválido o caducado, cuando el servicio lo reporta, entonces se purga automáticamente.
- **AC-04** — Dado un usuario con sesión cerrada o dispositivo revocado, cuando se evalúa el envío, entonces no se le notifica.
- **AC-05** — Dado un envío masivo, cuando se ejecuta, entonces se procesa de forma asíncrona en cola sin afectar la latencia de la API.

**Trazabilidad:** RF-NOT-001.

---

### US-NOT-02 · Catálogo de notificaciones y preferencias
**S · F3 · 5 pts · EP-10 · US-NOT-01**

**Como** usuario **quiero** recibir avisos relevantes y decidir cuáles **para** que el sistema me ayude sin volverse ruido que termine silenciando.

**Criterios de aceptación**

- **AC-01** — Dado el catálogo, cuando se configura, entonces incluye recordatorio de sesión próxima, cierre inminente de ventana, resultado de justificación y cambios en el horario.
- **AC-02** — Dado un usuario, cuando entra a preferencias, entonces puede activar o desactivar cada tipo salvo los marcados como institucionales obligatorios.
- **AC-03** — Dada una notificación, cuando se toca, entonces navega directamente a la pantalla correspondiente.
- **AC-04** — Dado un usuario, cuando se evalúan envíos en horario nocturno, entonces se respeta la franja de silencio configurada institucionalmente.

**Trazabilidad:** RF-NOT-002, RF-NOT-003.

---

### US-NOT-03 · Alerta de inasistencias consecutivas
**C · F4 · 3 pts · EP-10 · US-NOT-01, US-PAR-04**

**Como** coordinador **quiero** ser alertado cuando un docente acumula N inasistencias consecutivas **para** intervenir a tiempo.

**Criterios de aceptación**

- **AC-01** — Dado un docente que alcanza el umbral configurado de inasistencias consecutivas injustificadas, cuando se evalúa, entonces se alerta al coordinador de su facultad.
- **AC-02** — Dada una ausencia posteriormente justificada, cuando se aprueba, entonces el contador se recalcula.
- **AC-03** — Dada una alerta emitida, cuando el patrón continúa, entonces se agrupa en un resumen en lugar de enviar una por cada ausencia.

**Trazabilidad:** RF-NOT-004, RF-PAR-008.

---

## EP-11 · Privacidad y cumplimiento legal

### US-LEG-01 · Consentimiento informado de tratamiento de geolocalización
**M · F1 · 5 pts · EP-11 · US-PLT-03**

**Como** titular de datos personales **quiero** conocer y autorizar expresamente el tratamiento de mi ubicación antes de que se solicite el permiso **para** ejercer mi derecho bajo la Ley 1581 de 2012.

**VALOR:** bloqueante legal y de publicación en tiendas. Sin esto el sistema no puede operar legalmente ni distribuirse.

**Criterios de aceptación**

- **AC-01** — Dado un usuario que instala la app por primera vez, cuando la abre, entonces se muestra el aviso de privacidad y se exige aceptación explícita **antes** de solicitar el permiso de ubicación (CA-011).
- **AC-02** — Dada la aceptación, cuando se registra, entonces se almacena con fecha, hora, versión de la política y usuario.
- **AC-03** — Dada una nueva versión de la política, cuando el usuario abre la app, entonces se le solicita aceptar la versión actualizada.
- **AC-04** — Dado el aviso, cuando se redacta, entonces declara explícitamente que la ubicación se captura únicamente en el instante del marcaje y que **no existe rastreo continuo ni en segundo plano** (RNF-LEG-002).
- **AC-05** — Dado un usuario que rechaza la política, cuando decide, entonces no puede marcar pero conserva acceso a consultar su horario, y se le indica el canal institucional para su caso.
- **AC-06** — Dada la política de tratamiento y el aviso de privacidad, cuando se buscan, entonces son accesibles en todo momento desde la app y la consola web.

**Trazabilidad:** RNF-LEG-001, RNF-LEG-002, RNF-LEG-003, CA-011.

---

### US-LEG-02 · Ejercicio de derechos del titular
**S · F3 · 8 pts · EP-11 · US-LEG-01**

**Como** docente **quiero** consultar, actualizar, rectificar y solicitar supresión de mis datos **para** ejercer los derechos que me reconoce la ley.

**Criterios de aceptación**

- **AC-01** — Dado un usuario, cuando solicita una copia de sus datos, entonces recibe un archivo estructurado con sus datos personales, marcajes, justificaciones y consentimientos, dentro del plazo configurado.
- **AC-02** — Dada una solicitud de rectificación, cuando se radica, entonces genera un caso con responsable y plazo, y su resolución queda auditada.
- **AC-03** — Dada una solicitud de supresión, cuando se evalúa, entonces el sistema informa qué datos pueden eliminarse y cuáles deben conservarse por obligación legal o contractual, con fundamento.
- **AC-04** — Dado el canal de derechos, cuando se consulta, entonces está publicado con los plazos legales aplicables.

**Trazabilidad:** RNF-LEG-004.

---

### US-SEG-01 · Endurecimiento y verificación de seguridad previa a producción
**M · F1 · 8 pts · EP-11 · todas las de F1**

**Como** responsable de seguridad **quiero** una verificación formal contra OWASP antes del despliegue productivo **para** no exponer datos personales de todo el cuerpo docente por un fallo evitable.

**Criterios de aceptación**

- **AC-01** — Dado el sistema completo, cuando se ejecuta el análisis dinámico automatizado y la revisión contra el estándar de verificación de seguridad móvil, entonces no existen hallazgos críticos ni altos abiertos.
- **AC-02** — Dado todo el tráfico, cuando se inspecciona, entonces usa TLS 1.3 y la app aplica fijación de certificado (RNF-SEG-001).
- **AC-03** — Dados los datos, cuando se revisan, entonces están cifrados en reposo y en tránsito (RNF-SEG-007).
- **AC-04** — Dadas todas las entradas de la API, cuando se validan, entonces se rechaza cualquier estructura, tipo o rango no esperado, y existen límites de tasa por usuario e IP (RNF-SEG-005).
- **AC-05** — Dadas las credenciales de infraestructura, cuando se revisan, entonces aplican mínimo privilegio y ninguna está en el repositorio (RNF-SEG-009).
- **AC-06** — Dado el respaldo de base de datos, cuando se verifica, entonces es diario, con retención de 30 días, y existe evidencia de una prueba de restauración exitosa (RNF-DIS-003, RNF-DIS-004).

**Trazabilidad:** RNF-SEG-001..009, RNF-DIS-003, RNF-DIS-004.

---

### US-LEG-03 · Documentación de transferencia internacional de datos
**S · F3 · 3 pts · EP-11 · US-SEG-01**

**Como** institución **quiero** documentar la transferencia internacional derivada del alojamiento en la nube **para** cumplir el régimen colombiano de protección de datos.

**Criterios de aceptación**

- **AC-01** — Dada la infraestructura de base de datos, cuando se configura, entonces se selecciona la región disponible más cercana y se documenta la decisión.
- **AC-02** — Dada la relación con el encargado del tratamiento, cuando se formaliza, entonces existen las cláusulas contractuales correspondientes referenciadas en la política de tratamiento.
- **AC-03** — Dada la política publicada, cuando se lee, entonces informa al titular sobre la transferencia internacional.

**Trazabilidad:** RNF-LEG-005, R-07.

---

## SPIKE-01 · Medición de precisión GPS en el bloque piloto
**M · F1 · 5 pts · Sprint 3 · investigación con resultado obligatorio**

**Objetivo:** cerrar la decisión D-1 con datos reales, no con supuestos.

**Protocolo:**
1. Levantar el geocerco de 10 aulas del bloque piloto, en al menos 3 pisos distintos.
2. Registrar 30 lecturas de ubicación en el centro de cada aula, en tres momentos del día, con dos modelos de dispositivo (gama media y gama alta).
3. Medir: precisión reportada, error horizontal respecto al centroide real, tasa de contención dentro del polígono sin buffer y con buffer de 5, 10, 15 y 20 m.
4. Repetir 10 lecturas desde el pasillo adyacente para medir falsos positivos.

**Entregables obligatorios:**
- Tabla de resultados por aula y piso.
- Recomendación fundamentada de buffer por defecto.
- Respuesta a D-1: ¿validación a nivel de aula es viable, o se degrada a bloque?
- Respuesta a R-04: ¿existen aulas donde el error GPS supera el tamaño del aula? ¿Cuántas y qué se hace con ellas?
- Decisión sobre si se activa la verificación complementaria (US-GEO-13) en F1 en lugar de F2.

**Criterio de éxito del spike:** el equipo puede responder las cinco preguntas con evidencia numérica. Si el resultado es adverso, se convoca replanificación inmediata: es más barato cambiar el enfoque en el sprint 3 que en el 12.

---

## 6.99 Tabla resumen del backlog

| ID | Historia | Épica | Prio | Fase | Pts | Depende de |
|---|---|---|---|---|---|---|
| US-PLT-01 | Esqueleto API compilada | EP-00 | M | F1 | 8 | — |
| US-PLT-02 | CI con calidad obligatoria | EP-00 | M | F1 | 5 | PLT-01 |
| US-PLT-03 | Esqueleto app móvil | EP-00 | M | F1 | 8 | — |
| US-PLT-04 | Esqueleto consola web | EP-00 | M | F1 | 5 | PLT-01 |
| US-PLT-05 | Observabilidad y carga | EP-00 | M | F1 | 8 | MAR-04 |
| US-AUT-01 | Login institucional | EP-01 | M | F1 | 5 | PLT-01 |
| US-AUT-02 | Bloqueo y rate limit | EP-01 | M | F1 | 3 | AUT-01 |
| US-AUT-03 | Dispositivo confiable | EP-01 | M | F1 | 8 | AUT-01, PLT-03 |
| US-AUT-04 | Recuperar contraseña | EP-01 | M | F1 | 3 | AUT-01 |
| US-AUT-05 | TOTP administrativo | EP-01 | S | F2 | 8 | AUT-01 |
| US-AUT-06 | Biometría local | EP-01 | S | F2 | 5 | AUT-03 |
| US-AUT-07 | Revocación remota | EP-01 | S | F2 | 5 | AUT-01 |
| US-AUT-08 | SSO federado | EP-01 | C | F4 | 8 | AUT-01 |
| US-ROL-01 | Permisos granulares | EP-02 | M | F1 | 8 | AUT-01 |
| US-ROL-02 | Alcance ABAC | EP-02 | M | F1 | 8 | ROL-01, ACA-01 |
| US-ROL-03 | Roles personalizados | EP-02 | S | F2 | 5 | ROL-01 |
| US-ROL-04 | Multi-rol y contexto | EP-02 | S | F2 | 5 | ROL-01 |
| US-ROL-05 | Vigencia de roles | EP-02 | C | F4 | 3 | ROL-01 |
| US-GEO-01 | Jerarquía física | EP-03 | M | F1 | 5 | ROL-01 |
| US-GEO-02 | Captura perimetral | EP-03 | M | F1 | 13 | GEO-01, PLT-03 |
| US-GEO-03 | Captura por mapa | EP-03 | M | F1 | 5 | GEO-02 |
| US-GEO-04 | Validación geométrica | EP-03 | M | F1 | 8 | GEO-02 |
| US-GEO-05 | Solapamientos | EP-03 | M | F1 | 5 | GEO-04 |
| US-GEO-06 | Versionado geometría | EP-03 | M | F1 | 5 | GEO-04 |
| US-GEO-07 | Edición de vértices | EP-03 | M | F1 | 5 | GEO-06 |
| US-GEO-08 | Buffer perimetral | EP-03 | M | F1 | 3 | GEO-04, PAR-01 |
| US-GEO-09 | Centroide + radio | EP-03 | S | F2 | 3 | GEO-04 |
| US-GEO-10 | Captura offline | EP-03 | S | F2 | 8 | GEO-02 |
| US-GEO-11 | GeoJSON/KML | EP-03 | S | F2 | 5 | GEO-04 |
| US-GEO-12 | Clonar entre pisos | EP-03 | S | F2 | 3 | GEO-06 |
| US-GEO-13 | Verificación complementaria | EP-03 | S | F2 | 8 | GEO-01, MAR-04 |
| US-ACA-01 | Periodos y estructura | EP-04 | M | F1 | 8 | ROL-01 |
| US-ACA-02 | Franjas horarias | EP-04 | M | F1 | 5 | ACA-01 |
| US-ACA-03 | Asignaciones | EP-04 | M | F1 | 8 | ACA-02, GEO-01 |
| US-ACA-04 | Calendario excepciones | EP-04 | M | F1 | 5 | ACA-01 |
| US-ACA-05 | Generación de sesiones | EP-04 | M | F1 | 13 | ACA-03, ACA-04, PAR-02 |
| US-ACA-06 | Cambios de sesión | EP-04 | M | F1 | 5 | ACA-05 |
| US-ACA-07 | Carga masiva | EP-04 | M | F1 | 8 | ACA-03 |
| US-ACA-08 | Codocencia | EP-04 | S | F2 | 3 | ACA-03 |
| US-ACA-09 | Reemplazo docente | EP-04 | S | F2 | 5 | ACA-06 |
| US-ACA-10 | Integración académica | EP-04 | C | F4 | 13 | ACA-07 |
| US-PAR-01 | Parámetros base | EP-05 | M | F1 | 8 | ROL-01 |
| US-PAR-02 | Herencia jerárquica | EP-05 | M | F1 | 8 | PAR-01 |
| US-PAR-03 | Parámetro efectivo | EP-05 | S | F2 | 5 | PAR-02 |
| US-PAR-04 | Parámetros de alerta | EP-05 | S | F3 | 3 | PAR-01 |
| US-MAR-01 | Pantalla de un toque | EP-06 | M | F1 | 8 | ACA-05, PLT-03 |
| US-MAR-02 | Captura de ubicación | EP-06 | M | F1 | 8 | MAR-01 |
| US-MAR-03 | Motor de validación | EP-06 | M | F1 | 13 | MAR-02, GEO-08, PAR-02 |
| US-MAR-04 | Registro de evidencia | EP-06 | M | F1 | 5 | MAR-03 |
| US-MAR-05 | Idempotencia | EP-06 | M | F1 | 5 | MAR-04 |
| US-MAR-06 | Mensajes accionables | EP-06 | M | F1 | 5 | MAR-03 |
| US-MAR-07 | Ausencias automáticas | EP-06 | M | F1 | 5 | MAR-04 |
| US-MAR-08 | Historial propio | EP-06 | M | F1 | 5 | MAR-04 |
| US-MAR-09 | Ajuste administrativo | EP-06 | M | F1 | 5 | MAR-04, AUD-01 |
| US-MAR-10 | Integridad y atestación | EP-06 | M | F1 | 8 | MAR-03, AUT-03 |
| US-MAR-11 | Marcaje offline | EP-06 | S | F3 | 13 | MAR-03 |
| US-MAR-12 | Aviso de cierre | EP-06 | S | F3 | 3 | MAR-01, NOT-01 |
| US-MAR-13 | Marcaje estudiantil | EP-06 | S | F3 | 13 | MAR-03 |
| US-MAR-14 | Lista manual | EP-06 | S | F3 | 5 | MAR-13 |
| US-MAR-15 | Marcaje de salida | EP-06 | S | F3 | 5 | MAR-03, PAR-01 |
| US-JUS-01 | Radicar justificación | EP-07 | S | F3 | 8 | MAR-08 |
| US-JUS-02 | Flujo de aprobación | EP-07 | S | F3 | 8 | JUS-01, ROL-02 |
| US-JUS-03 | Efecto en reporte | EP-07 | S | F3 | 5 | JUS-02, REP-01 |
| US-JUS-04 | Notificar resultado | EP-07 | S | F3 | 3 | JUS-02, NOT-01 |
| US-REP-01 | Cumplimiento docente | EP-08 | M | F1 | 8 | MAR-07, ROL-02 |
| US-REP-02 | Exportación XLSX/PDF | EP-08 | M | F1 | 5 | REP-01 |
| US-REP-03 | Tablero en vivo | EP-08 | S | F3 | 8 | REP-01 |
| US-REP-04 | Ocupación de espacios | EP-08 | S | F3 | 5 | REP-01 |
| US-REP-05 | Asistencia estudiantil | EP-08 | S | F3 | 5 | MAR-13 |
| US-REP-06 | Mapa de calor rechazos | EP-08 | C | F4 | 5 | MAR-04 |
| US-REP-07 | Envío programado | EP-08 | C | F4 | 3 | REP-02 |
| US-AUD-01 | Bitácora inmutable | EP-09 | M | F1 | 8 | PLT-01 |
| US-AUD-02 | Intentos rechazados | EP-09 | M | F1 | 3 | AUD-01, MAR-04 |
| US-AUD-03 | Consulta y exportación | EP-09 | S | F3 | 5 | AUD-01 |
| US-AUD-04 | Retención de datos | EP-09 | S | F3 | 5 | AUD-01 |
| US-NOT-01 | Infraestructura push | EP-10 | S | F3 | 8 | AUT-03 |
| US-NOT-02 | Catálogo y preferencias | EP-10 | S | F3 | 5 | NOT-01 |
| US-NOT-03 | Alerta inasistencias | EP-10 | C | F4 | 3 | NOT-01, PAR-04 |
| US-LEG-01 | Consentimiento informado | EP-11 | M | F1 | 5 | PLT-03 |
| US-LEG-02 | Derechos del titular | EP-11 | S | F3 | 8 | LEG-01 |
| US-LEG-03 | Transferencia internacional | EP-11 | S | F3 | 3 | SEG-01 |
| US-SEG-01 | Verificación de seguridad | EP-11 | M | F1 | 8 | F1 completa |
| SPIKE-01 | Precisión GPS en campo | — | M | F1 | 5 | GEO-04 |
---

# PARTE II — ARQUITECTURA Y ESPECIFICACIÓN TÉCNICA
*(Tech Lead / Arquitecto de Software)*

---

## 7. Decisiones de arquitectura (ADR)

### ADR-01 · Stack: Opción A del SRS
**Decisión:** Flutter 3.x (Dart, compilación AOT) para móvil y consola web (dart2wasm); Go 1.23+ con Echo para el backend; MongoDB Atlas; MapLibre GL; Docker + Traefik sobre VPS con Cloudflare al frente.

**Razón:** cumple la restricción de código compilado en todas las capas (SRS §5.1), un solo lenguaje de UI para móvil y web, concurrencia de Go adecuada al pico de cambio de hora, soporte nativo de GeoJSON y `2dsphere` en MongoDB.

**Consecuencia:** el equipo necesita competencia en Dart y Go. Si no la tiene, la Opción B (Kotlin Multiplatform + Ktor/.NET) es válida y **todo este documento sigue siendo aplicable**: las historias, criterios de aceptación, contratos y modelo de datos son independientes del lenguaje. Solo cambia el nombre de las bibliotecas en las subtareas.

### ADR-02 · Arquitectura hexagonal con dominio puro
**Decisión:** el backend se organiza en `domain` (entidades y reglas puras, cero dependencias externas), `usecase` (orquestación), `repository` (interfaces + implementación MongoDB), `transport` (HTTP, DTO, middlewares) y `platform` (configuración, logging, telemetría, reloj inyectable).

**Razón:** el motor de validación de marcaje debe ser probable sin base de datos ni red (SRS §5.5) y necesita ≥ 90 % de cobertura. Eso solo es sostenible si es una función pura.

**Regla no negociable:** `domain` no importa nada de `mongo`, `http`, ni de `time.Now()`. El tiempo se inyecta.

### ADR-03 · El reloj es una dependencia inyectable
**Decisión:** ninguna regla de negocio llama al reloj del sistema directamente. Existe una interfaz `Clock` con implementación real y falsa.

**Razón:** todo el motor gira alrededor de ventanas temporales. Sin reloj inyectable, las pruebas serían no deterministas o dependerían de esperas.

### ADR-04 · Coordenadas siempre en orden [longitud, latitud]
**Decisión:** un único tipo `GeoPoint` y un único tipo `GeoPolygon` en el dominio, con constructores que solo aceptan el orden GeoJSON. Ningún `float64` suelto cruza una frontera de capa.

**Razón:** el SRS §6.2 identifica este como el error más común de este tipo de sistema. Se elimina por tipos, no por disciplina.

**Verificación obligatoria:** prueba unitaria dedicada que falla si se invierte el orden, y validación de rango en toda entrada (latitud ∈ [−90, 90], longitud ∈ [−180, 180]; para Colombia se añade una validación de plausibilidad configurable).

### ADR-05 · Parámetros y geometría congelados en la sesión
**Decisión:** al generar cada sesión se resuelve la cascada de parámetros y se almacena el resultado, junto con la versión de geometría del espacio.

**Razón:** impide que un cambio administrativo altere retroactivamente evaluaciones ya realizadas (SRS §6.2, CA-008). Es el fundamento del valor probatorio.

**Consecuencia:** aplicar un cambio de parámetro a sesiones ya generadas requiere una operación explícita de regeneración, que debe existir y estar auditada.

### ADR-06 · Buffer precalculado, no computado en tiempo de petición
**Decisión:** se almacena `geometriaBuffer` como polígono expandido, con índice `2dsphere`, y la validación de contención se hace con `$geoIntersects` sobre ese campo.

**Razón:** expandir un polígono en cada una de 300 peticiones por segundo es desperdicio. El recálculo ocurre solo al cambiar la geometría o el buffer.

### ADR-07 · Idempotencia garantizada por la base de datos
**Decisión:** índice único sobre `{sesionId, usuarioId, tipo}` en `marcajes`, más una clave de idempotencia de cliente. El error de clave duplicada se traduce a "devolver el registro existente".

**Razón:** en un pico de carga, la idempotencia basada solo en lógica de aplicación pierde ante condiciones de carrera.

### ADR-08 · Auditoría como decorador transversal
**Decisión:** los casos de uso sensibles se envuelven en un decorador que emite la entrada de auditoría dentro de la misma unidad de trabajo. No hay llamadas manuales a auditoría dispersas.

**Razón:** RF-AUD-001 exige cobertura total; la disciplina manual falla. Si la auditoría falla, la operación se revierte.

### ADR-09 · Procesos programados en un worker separado
**Decisión:** un contenedor `siaa-worker` independiente ejecuta la generación de sesiones, la generación de ausencias (cada 15 min), los reportes pesados y los envíos de notificación.

**Razón:** aísla la carga de fondo de la latencia crítica del marcaje. Un reporte pesado nunca debe degradar el pico de las 7:00 a. m.

**Consecuencia:** el worker necesita bloqueo distribuido para no ejecutar el mismo trabajo dos veces si escala.

### ADR-10 · El cliente nunca decide; solo anticipa
**Decisión:** la app puede prechequear localmente (precisión, ventana, contención aproximada) exclusivamente para mostrar el estado del botón y ahorrar peticiones inútiles. El resultado oficial siempre proviene del servidor.

**Razón:** RF-MAR-004. Cualquier decisión del cliente es falsificable.

### ADR-11 · Zona horaria explícita en todo el sistema
**Decisión:** todo instante se almacena en UTC. Las franjas horarias se almacenan como hora local más la zona institucional, y se resuelven a instantes en el momento de generar sesiones.

**Razón:** una franja "08:00 los martes" no es un instante; convertirla prematuramente produce errores en cambios de calendario y en despliegues multi-sede.

---

## 8. Estructura del repositorio

Monorepo con tres artefactos y contratos compartidos.

```
siaa/
├── backend/
│   ├── cmd/
│   │   ├── api/main.go               # binario del API
│   │   └── worker/main.go            # binario de procesos programados
│   ├── internal/
│   │   ├── domain/
│   │   │   ├── geo/                  # GeoPoint, GeoPolygon, área, centroide, contención, simplicidad
│   │   │   ├── marcaje/              # ⭐ motor de validación (función pura) + tipos de resultado
│   │   │   ├── parametro/            # cascada de herencia (función pura)
│   │   │   ├── sesion/               # expansión de franjas a sesiones (función pura)
│   │   │   ├── rbac/                 # permisos, evaluación de ámbito
│   │   │   └── shared/               # errores de dominio, Clock, identificadores
│   │   ├── usecase/
│   │   │   ├── auth/  espacio/  academico/  marcaje/  justificacion/
│   │   │   ├── parametro/  reporte/  auditoria/  notificacion/
│   │   ├── repository/
│   │   │   ├── ports.go              # interfaces consumidas por usecase
│   │   │   └── mongo/                # implementación, índices, migraciones
│   │   ├── transport/
│   │   │   ├── http/handler/         # handlers por módulo
│   │   │   ├── http/dto/             # DTO de entrada y salida, validación
│   │   │   ├── http/middleware/      # auth, rbac, abac, ratelimit, correlationId, recover, audit
│   │   │   └── http/router.go
│   │   └── platform/
│   │       ├── config/  log/  metrics/  clock/  storage/  push/  mail/
│   ├── migrations/                   # creación de índices y datos semilla
│   └── test/
│       ├── unit/  integration/  load/
├── mobile/                           # Flutter: app docente/estudiante/admin
│   └── lib/
│       ├── core/          # red, almacenamiento seguro, tema, i18n, errores
│       ├── features/
│       │   ├── auth/  marcaje/  historial/  horario/
│       │   ├── geo_editor/           # ⭐ editor GPS
│       │   └── justificacion/  perfil/
│       └── shared/        # modelos generados desde OpenAPI, widgets, tokens de diseño
├── web/                              # Flutter Web (WASM): consola administrativa
├── contracts/
│   └── openapi.yaml                  # fuente de verdad del contrato
├── docs/
│   ├── adr/  runbooks/  plantillas-carga/
└── infra/
    ├── docker/  traefik/  observabilidad/  scripts/
```

**Regla de dependencia:** las flechas de importación solo apuntan hacia adentro. `transport → usecase → domain`. `repository` implementa interfaces definidas en `usecase`. Una violación rompe el pipeline mediante análisis estático de capas.

---

## 9. Contratos de API

Base: `https://api.siaa.<dominio>/api/v1` · Autenticación: `Authorization: Bearer <jwt>`

### 9.1 Convenciones obligatorias

| Aspecto | Regla |
|---|---|
| Formato | JSON, `Content-Type: application/json; charset=utf-8` |
| Fechas | ISO 8601 en UTC con sufijo `Z` |
| Paginación | `?page=1&limit=50`, respuesta `{datos:[], meta:{page,limit,total,totalPaginas}}`, límite máximo 200 |
| Errores | `{codigo, mensaje, detalles:[{campo,error}], correlationId}` |
| Correlación | Cabecera `X-Correlation-Id` aceptada y devuelta; generada si no viene |
| Idempotencia | Cabecera `Idempotency-Key` en todo POST que crea recursos |
| Versionado | `/api/v1`, semántico, compatibilidad hacia atrás (RNF-MAN-004) |
| Documentación | OpenAPI 3.1 generado desde el código, publicado en `/api/v1/openapi.json` |

### 9.2 Catálogo de códigos de error

| Código | HTTP | Significado |
|---|---|---|
| `AUTH_CREDENCIALES_INVALIDAS` | 401 | Usuario o contraseña incorrectos |
| `AUTH_TOKEN_EXPIRADO` | 401 | Token de acceso vencido |
| `AUTH_TOKEN_REVOCADO` | 401 | Token en lista de revocación |
| `AUTH_CUENTA_BLOQUEADA` | 423 | Bloqueo por intentos fallidos |
| `AUTH_2FA_REQUERIDO` | 401 | Falta segundo factor |
| `PERM_DENEGADO` | 403 | Falta el permiso requerido |
| `AMBITO_DENEGADO` | 403 | Recurso fuera del ámbito del usuario |
| `VALIDACION` | 422 | Entrada inválida, con detalles por campo |
| `RECURSO_NO_ENCONTRADO` | 404 | — |
| `CONFLICTO_HORARIO` | 409 | Colisión docente o aula |
| `CONFLICTO_UNICIDAD` | 409 | Código duplicado |
| `GEOMETRIA_INVALIDA` | 422 | Con subcódigo: `VERTICES_INSUFICIENTES`, `POLIGONO_NO_SIMPLE`, `AREA_FUERA_DE_RANGO`, `NO_CERRADO` |
| `GEOMETRIA_SOLAPADA` | 409 | Solapamiento > 50 % |
| `LIMITE_TASA` | 429 | Con `Retry-After` |
| `ERROR_INTERNO` | 500 | Sin detalles internos expuestos |

> Los resultados de marcaje (`PRESENTE`, `TARDANZA`, `RECHAZADO_*`) **no son errores HTTP**: se devuelven con HTTP 201 o 200 y el resultado en el cuerpo. Un rechazo de negocio es una evaluación exitosa, y debe persistirse.

### 9.3 Endpoints

| Método | Ruta | Descripción | Permiso |
|---|---|---|---|
| POST | `/auth/login` | Inicio de sesión | Público |
| POST | `/auth/refresh` | Renovar par de tokens (con rotación) | Público con token válido |
| POST | `/auth/logout` | Cerrar sesión propia | Autenticado |
| POST | `/auth/recuperar` | Solicitar enlace de recuperación | Público |
| POST | `/auth/recuperar/confirmar` | Establecer nueva contraseña | Público con token |
| POST | `/auth/2fa/activar` · `/auth/2fa/verificar` | Segundo factor | Autenticado |
| POST | `/auth/devices` | Registrar dispositivo | Autenticado |
| GET | `/auth/devices` | Listar dispositivos propios | Autenticado |
| POST | `/auth/devices/{id}/solicitar-cambio` | Solicitar revinculación | Autenticado |
| PATCH | `/usuarios/{id}/dispositivos/{did}` | Aprobar o revocar dispositivo | `usuario:editar` |
| POST | `/usuarios/{id}/revocar-sesiones` | Revocación remota | `usuario:editar` |
| GET | `/me` | Perfil, roles, permisos y ámbito | Autenticado |
| POST | `/me/contexto` | Cambiar rol activo | Autenticado |
| GET | `/me/sesiones/hoy` | Sesiones del día | `marcaje:crear` |
| GET | `/me/sesiones/activa` | Sesión marcable ahora + parámetros + geometría | `marcaje:crear` |
| GET | `/me/historial` | Historial propio paginado | `marcaje:leer` |
| POST | `/marcajes` | Registrar marcaje | `marcaje:crear` |
| POST | `/marcajes/sync` | Sincronizar cola offline (lote ≤ 50) | `marcaje:crear` |
| GET | `/marcajes` | Consulta con filtros y ámbito | `marcaje:leer` |
| PATCH | `/marcajes/{id}` | Ajustar o anular con motivo | `marcaje:ajustar` |
| POST | `/marcajes/manual` | Crear marcaje manual | `marcaje:ajustar` |
| GET/POST | `/sedes` · `/bloques` | Jerarquía superior | `sede:*`, `bloque:*` |
| GET/POST/PATCH/DELETE | `/espacios` | CRUD de espacios | `aula:leer` / `aula:crear` |
| PUT | `/espacios/{id}/geometria` | Actualizar polígono (crea versión) | `aula:editar-geometria` |
| GET | `/espacios/{id}/geometria/versiones` | Histórico de geometría | `aula:leer` |
| POST | `/espacios/validar-geometria` | Validar sin persistir | `aula:crear` |
| GET | `/espacios/solapamientos` | Informe de conflictos | `aula:leer` |
| POST | `/espacios/importar` · `GET /espacios/exportar` | GeoJSON/KML | `aula:crear` |
| POST | `/espacios/clonar-piso` | Clonar planta | `aula:crear` |
| GET/POST | `/periodos` · `/facultades` · `/programas` · `/asignaturas` · `/grupos` | Estructura académica | `horario:crear` |
| POST | `/periodos/{id}/generar-sesiones` | Expandir franjas (asíncrono) | `horario:crear` |
| GET | `/trabajos/{id}` | Estado de proceso asíncrono | Autenticado |
| GET/POST/PATCH | `/asignaciones` | Gestión de asignaciones | `asignacion:crear` |
| GET/PATCH | `/sesiones/{id}` | Consulta y cambios puntuales | `horario:crear` |
| POST | `/sesiones/{id}/suplente` | Designar reemplazo | `asignacion:crear` |
| GET/POST | `/calendario-excepciones` | Fechas no lectivas | `horario:crear` |
| POST | `/cargas/validar` · `/cargas/aplicar` | Carga masiva CSV/XLSX | `horario:crear` |
| GET/PUT | `/parametros` | Parámetros por ámbito | `parametro:editar` |
| GET | `/parametros/efectivos` | Resolución con origen | `parametro:editar` |
| GET/POST | `/justificaciones` | Radicar y listar | `justificacion:crear` |
| PATCH | `/justificaciones/{id}` | Aprobar o rechazar | `justificacion:aprobar` |
| GET | `/reportes/cumplimiento` · `/reportes/ocupacion` · `/reportes/asistencia-grupo` | Reportes | `reporte:exportar` |
| POST | `/reportes/{tipo}/exportar` | Exportación XLSX/PDF | `reporte:exportar` |
| GET | `/tablero` | Indicadores en vivo | `reporte:exportar` |
| GET | `/auditoria` | Consulta de bitácora | `auditoria:leer` |
| GET | `/health` · `/health/ready` · `/metrics` | Operación | Interno |

### 9.4 Contrato del marcaje (el más crítico)

**Petición**

```jsonc
POST /api/v1/marcajes
Idempotency-Key: 7c9e6679-7425-40de-944b-e07fc1f90ae7
{
  "sesionId": "66f0a1b2c3d4e5f60718293a",
  "tipo": "ENTRADA",                       // ENTRADA | SALIDA
  "latitud": 1.14771,
  "longitud": -76.65112,
  "precisionMetros": 8.2,
  "timestampDispositivo": "2026-09-08T13:04:11Z",
  "dispositivoId": "b7c1-...",
  "versionApp": "1.0.3",
  "integridad": { "mockLocation": false, "rooteado": false, "emulador": false, "attestationToken": "..." },
  "verificacionComplementaria": { "metodo": "WIFI", "valor": "a4:2b:8c:11:02:9f" },
  "idempotencyKey": "7c9e6679-7425-40de-944b-e07fc1f90ae7"
}
```

**Respuesta aceptada (201)**

```jsonc
{
  "marcajeId": "66f1...",
  "resultado": "PRESENTE",                 // o TARDANZA
  "mensaje": "Asistencia registrada a las 8:04 a. m.",
  "distanciaMetros": 4.1,
  "minutosRespectoInicio": 4,
  "timestampServidor": "2026-09-08T13:04:12Z"
}
```

**Respuesta rechazada (201 — la evaluación fue exitosa, el resultado es negativo)**

```jsonc
{
  "marcajeId": "66f1...",
  "resultado": "RECHAZADO_FUERA_DE_AREA",
  "motivoRechazo": "FUERA_DE_AREA",
  "mensaje": "Estás a 48 m del aula A-301.",
  "distanciaMetros": 48.3,
  "pasoFallido": 8,
  "permiteReintento": false,
  "puedeJustificar": true
}
```

**Respuesta con reintento permitido (200)**

```jsonc
{
  "resultado": "PRECISION_INSUFICIENTE",
  "mensaje": "Señal débil. Acércate a una ventana e inténtalo de nuevo.",
  "precisionRecibida": 62.0,
  "precisionRequerida": 35.0,
  "permiteReintento": true
}
```

> `PRECISION_INSUFICIENTE` **no crea marcaje** y **no consume idempotencia**. Es la única salida del motor con esa propiedad.

### 9.5 Contrato de sesión activa

```jsonc
GET /api/v1/me/sesiones/activa
{
  "sesion": {
    "id": "66f0...",
    "asignatura": "Cálculo Diferencial",
    "grupo": "ING-CD-02",
    "espacio": { "id": "...", "codigo": "A-301", "nombre": "Aula 301" },
    "inicioProgramado": "2026-09-08T13:00:00Z",
    "finProgramado": "2026-09-08T15:00:00Z",
    "modalidad": "PRESENCIAL"
  },
  "ventana": {
    "abreEn": "2026-09-08T12:45:00Z",
    "cierraEn": "2026-09-08T13:15:00Z",
    "estado": "ABIERTA"                    // NO_ABIERTA | ABIERTA | CERRADA
  },
  "parametros": { "precisionGpsMaxMetros": 35, "umbralTardanzaMin": 10 },
  "geometriaBuffer": { "type": "Polygon", "coordinates": [[[...]]] },
  "verificacionComplementariaExigida": false,
  "marcajeExistente": null,
  "horaServidor": "2026-09-08T12:58:03Z"
}
```

La `geometriaBuffer` y `horaServidor` se envían **solo** para el prechequeo visual del cliente (ADR-10). El cliente nunca decide.

---

## 10. Modelo de datos

Se adopta íntegramente el modelo del SRS §6, con las precisiones siguientes.

### 10.1 Colecciones

`usuarios` · `roles` · `sedes` · `bloques` · `espacios` · `espacios_geometria_hist` · `periodos` · `facultades` · `programas` · `asignaturas` · `grupos` · `asignaciones` · `sesiones` · `marcajes` · `parametros` · `justificaciones` · `dispositivos` · `auditoria` · `calendario_excepciones` · `trabajos` (procesos asíncronos) · `consentimientos` · `notificaciones_tokens`

### 10.2 Campos añadidos respecto al SRS

Estos campos no están en el SRS pero son necesarios para satisfacer criterios de aceptación acordados. Están justificados uno a uno.

| Colección | Campo | Tipo | Justificación |
|---|---|---|---|
| `espacios` | `geometriaBuffer` | GeoJSON Polygon | ADR-06, §6.4 del SRS lo recomienda. Índice `2dsphere`. |
| `espacios` | `nivelValidacion` | `AULA\|BLOQUE\|ZONA` | Decisión D-1 sin cerrar; permite degradar sin redespliegue |
| `espacios` | `zonaMarcajeId` | ObjectId, nulo | Agrupación de aulas contiguas (mitigación R-04) |
| `espacios` | `verificacionExigida` | bool | Distingue "tiene métodos registrados" de "son obligatorios" |
| todas las académicas | `codigoExterno` | string, nulo, indexado | Conciliación futura con el sistema académico (D-5) |
| `sesiones` | `ventanaEntradaAbre` / `ventanaEntradaCierra` | ISODate | Precalculadas al generar; evitan aritmética en cada consulta y permiten indexar la búsqueda de sesión activa |
| `sesiones` | `ventanaEstudiantilAbierta` | bool | US-MAR-13 |
| `marcajes` | `idempotencyKey` | string, indexado | ADR-07 |
| `marcajes` | `anulado`, `motivoAjuste` | bool, string | US-MAR-09 |
| `marcajes` | `anomalias` | array de string | Saltos imposibles, desfase de reloj, dispositivo compartido (R-03) |
| `consentimientos` | `usuarioId`, `versionPolitica`, `aceptadoEn`, `ip` | — | CA-011, RNF-LEG-001 |
| `trabajos` | `tipo`, `estado`, `progreso`, `resultado`, `creadoPor` | — | Procesos asíncronos (US-ACA-05, US-REP-01) |
| `usuarios` | `ambitos` | array `{tipo,id}` | ABAC (US-ROL-02) |

### 10.3 Índices obligatorios

| Colección | Índice | Tipo | Propósito |
|---|---|---|---|
| `espacios` | `geometria` | 2dsphere | Consultas cartográficas |
| `espacios` | `geometriaBuffer` | 2dsphere | **Validación de contención del marcaje** |
| `espacios` | `{sedeId:1, bloqueId:1, piso:1}` | compuesto | Solapamientos y navegación |
| `espacios` | `{codigo:1}` | único | Unicidad de código |
| `sesiones` | `{docenteIds:1, ventanaEntradaAbre:1, ventanaEntradaCierra:1}` | compuesto | **Búsqueda de sesión activa** — ruta crítica |
| `sesiones` | `{espacioId:1, inicioProgramado:1}` | compuesto | Ocupación y colisiones |
| `sesiones` | `{fecha:1, estado:1}` | compuesto | Proceso de ausencias y tablero |
| `marcajes` | `{sesionId:1, usuarioId:1, tipo:1}` | **único parcial** (`anulado:false`) | Idempotencia (ADR-07) |
| `marcajes` | `{usuarioId:1, creadoEn:-1}` | compuesto | Historial |
| `marcajes` | `{resultado:1, espacioId:1, creadoEn:-1}` | compuesto | Mapa de calor de rechazos |
| `marcajes` | `ubicacion` | 2dsphere | Análisis geoespacial posterior |
| `asignaciones` | `{periodoId:1, docenteIds:1}` | compuesto | Consulta de asignaciones |
| `asignaciones` | `{periodoId:1, espacioId:1, "franja.diaSemana":1}` | compuesto | Detección de colisión de aula |
| `usuarios` | `{correo:1}` | único | Autenticación |
| `auditoria` | `{entidad:1, entidadId:1, creadoEn:-1}` | compuesto | Consulta de bitácora |
| `auditoria` | `{actorId:1, creadoEn:-1}` | compuesto | Investigación por actor |
| `parametros` | `{ambito:1, ambitoId:1, vigenteDesde:-1}` | compuesto | Resolución de cascada |

> **RNF-PER-004:** ninguna consulta geoespacial puede hacer escaneo de colección. Se verifica con planes de ejecución en las pruebas de integración, no por inspección manual.

### 10.4 Nota crítica sobre el índice de idempotencia

El índice único debe ser **parcial**, excluyendo los marcajes anulados. De lo contrario, tras anular un marcaje erróneo sería imposible registrar el correcto para la misma sesión, tipo y usuario.

---

## 11. Especificación del motor de validación (RN-001)

Esta es la pieza de software más importante del sistema. Se implementa como función pura en `domain/marcaje`.

### 11.1 Firma

```
EvaluarMarcaje(entrada SolicitudMarcaje, contexto ContextoSesion, ahora Instante) Resultado
```

`contexto` contiene todo lo necesario ya resuelto por el caso de uso: la sesión con sus parámetros congelados, la geometría con buffer del espacio, el dispositivo vinculado del usuario, el marcaje previo si existe y la configuración de verificación complementaria. **La función no consulta nada.**

### 11.2 Algoritmo

```
1. AUTORIZACIÓN
   si !usuario.activo  ->  401
   si !usuario.tienePermiso("marcaje:crear")  ->  403

2. DISPOSITIVO
   si contexto.dispositivoVinculado != entrada.dispositivoId
      -> RECHAZADO_INTEGRIDAD, motivo=DISPOSITIVO_NO_VINCULADO

3. ATESTACIÓN
   si parametros.exigirAttestation && !entrada.integridad.attestationOk
      -> RECHAZADO_INTEGRIDAD, motivo=ATTESTATION_FALLIDA

4. ASIGNACIÓN
   si contexto.sesion == nulo
      -> RECHAZADO_SIN_ASIGNACION
   si usuario ∉ (sesion.docenteIds ∪ {sesion.suplenteId} ∪ estudiantesDelGrupo)
      -> RECHAZADO_SIN_ASIGNACION

5. VENTANA TEMPORAL   (referencia: ahora = hora de servidor)
   ventanaAbre  = sesion.inicioProgramado − p.holguraEntradaAntesMin
   ventanaCierra = sesion.inicioProgramado + p.holguraEntradaDespuesMin
   si ahora ∉ [ventanaAbre, ventanaCierra]
      -> RECHAZADO_FUERA_DE_HORARIO, minutosDesviacion = ...
   (para tipo=SALIDA se usan las holguras de salida sobre finProgramado)

6. PRECISIÓN
   si entrada.precisionMetros > p.precisionGpsMaxMetros
      -> PRECISION_INSUFICIENTE  [permiteReintento=true, NO persiste marcaje]

7. INTEGRIDAD DE UBICACIÓN
   si p.bloquearMockLocation && entrada.integridad.mockLocation
      -> RECHAZADO_INTEGRIDAD, motivo=MOCK_LOCATION
   si p.bloquearRooteado && entrada.integridad.rooteado
      -> RECHAZADO_INTEGRIDAD, motivo=DISPOSITIVO_COMPROMETIDO

8. CONTENCIÓN GEOESPACIAL
   si sesion.modalidad == VIRTUAL  ->  saltar a 10
   punto = GeoPoint(entrada.longitud, entrada.latitud)     // ⚠ orden lon,lat
   si !Contiene(contexto.geometriaBuffer, punto)
      distancia = DistanciaAlPoligono(contexto.geometria, punto)
      -> RECHAZADO_FUERA_DE_AREA, distanciaMetros = distancia

9. VERIFICACIÓN COMPLEMENTARIA
   si espacio.verificacionExigida
      si entrada.verificacionComplementaria ∉ espacio.valoresRegistrados
         -> RECHAZADO_VERIFICACION

10. IDEMPOTENCIA
    si contexto.marcajePrevio != nulo && !contexto.marcajePrevio.anulado
       -> devolver contexto.marcajePrevio  (sin crear nada)

11. CLASIFICACIÓN
    minutosRespectoInicio = ahora − sesion.inicioProgramado
    si minutosRespectoInicio <= p.umbralTardanzaMin  ->  PRESENTE
    en caso contrario                                ->  TARDANZA
```

### 11.3 Invariantes verificables

1. La función es determinista: misma entrada, mismo resultado, siempre.
2. No accede a red, base de datos ni al reloj del sistema.
3. Se detiene en el primer fallo y reporta el número de paso.
4. `PRECISION_INSUFICIENTE` es la única salida que no persiste ni consume idempotencia.
5. Todo rechazo distinto del anterior **sí se persiste** (RF-AUD-004).
6. El orden de coordenadas es siempre `[longitud, latitud]`.

### 11.4 Batería mínima de pruebas (cada una mapeada a un criterio)

| Caso | Entrada | Resultado esperado | Trazabilidad |
|---|---|---|---|
| Feliz | Dentro del aula, minuto 4, holgura 15, tardanza 10 | `PRESENTE` | CA-001 |
| Tardanza | Minuto 12, holgura 15, tardanza 10 | `TARDANZA` | CA-005 |
| Fuera de horario | Minuto 25, holgura 15 | `RECHAZADO_FUERA_DE_HORARIO` | CA-004 |
| Fuera de área | 40 m del aula, buffer 10 | `RECHAZADO_FUERA_DE_AREA`, distancia informada | CA-002 |
| Borde exacto | Punto exactamente sobre el vértice del buffer | Definido explícitamente como **dentro** | — |
| Sin asignación | Sesión de otro docente | `RECHAZADO_SIN_ASIGNACION` | CA-003 |
| Mock location | Bandera activa, bloqueo activo | `RECHAZADO_INTEGRIDAD` | CA-006 |
| Mock location permitido | Bandera activa, bloqueo desactivado | Continúa evaluación | RF-PAR-007 |
| Precisión mala | 62 m con máximo 35 | `PRECISION_INSUFICIENTE`, sin persistir | Paso 6 |
| Doble toque | Dos peticiones simultáneas | Un solo marcaje, mismo id | CA-012 |
| Dispositivo ajeno | dispositivoId distinto | `RECHAZADO_INTEGRIDAD` | RF-AUT-004 |
| Virtual | Modalidad virtual, coordenadas nulas | Clasifica solo por tiempo | RF-ACA-013 |
| Coordenadas invertidas | lat y lon intercambiadas | Rechazo por validación de rango | ADR-04 |
| Apertura exacta | `ahora == ventanaAbre` | Aceptado (intervalo cerrado) | — |
| Cierre exacto | `ahora == ventanaCierra` | Aceptado (intervalo cerrado) | — |
| Suplente | Suplente designado marca | Aceptado | RF-ACA-010 |
| Titular con suplente | Titular marca habiendo suplente | `RECHAZADO_SIN_ASIGNACION` | US-ACA-09 |

**Cobertura exigida en este paquete: ≥ 90 %** (RNF-MAN-001). El pipeline bloquea por debajo.
---

## 12. Desglose técnico: subtareas por historia

Convenciones de esta sección:

- **Capa:** `BE` backend · `DB` base de datos · `MOV` app móvil · `WEB` consola web · `INF` infraestructura · `QA` pruebas · `DOC` documentación.
- **Est.:** estimación en horas de trabajo efectivo de un desarrollador competente en el stack.
- Toda subtarea termina con sus pruebas incluidas. "Terminado" no significa "compila".
- Cada historia incluye una fila de pruebas explícita; esa fila **no es opcional ni recortable**.

---

### US-PLT-01 · Esqueleto de API compilada

| ID | Capa | Subtarea | Est. |
|---|---|---|---|
| T-PLT-01.1 | BE | Inicializar módulo Go, estructura de carpetas de ADR-02, `cmd/api/main.go` con arranque y apagado ordenado (graceful shutdown con drenaje de 15 s) | 3 |
| T-PLT-01.2 | BE | Configuración por variables de entorno con validación al arranque; el servicio **no arranca** si falta una variable obligatoria | 2 |
| T-PLT-01.3 | BE | Enrutador HTTP con grupo `/api/v1`, middlewares base: recuperación de pánico, `correlationId`, CORS restringido, tiempo límite de petición | 3 |
| T-PLT-01.4 | BE | Registro estructurado JSON con nivel configurable y correlación por petición (RNF-MAN-005) | 2 |
| T-PLT-01.5 | BE | Manejador de errores central: mapeo de errores de dominio a códigos del catálogo §9.2, sin filtrar internos | 3 |
| T-PLT-01.6 | DB | Conexión a MongoDB con reserva de conexiones, reintentos y verificación de salud | 2 |
| T-PLT-01.7 | DB | Sistema de migraciones: creación idempotente de todos los índices de §10.3 y datos semilla (roles y parámetros globales) | 5 |
| T-PLT-01.8 | BE | Endpoints `/health` y `/health/ready` con verificación de dependencias | 2 |
| T-PLT-01.9 | BE | Generación de OpenAPI 3.1 desde anotaciones del código, publicada en `/openapi.json` | 3 |
| T-PLT-01.10 | INF | Dockerfile multietapa produciendo imagen mínima con binario estático; configuración de Traefik y despliegue en entorno de desarrollo | 4 |
| T-PLT-01.11 | QA | Pruebas de integración del arranque, salud, formato de error y correlación | 3 |

**Riesgo:** ninguno. **Criterio de cierre:** un agente externo puede consultar `/health` del entorno de desarrollo desplegado.

---

### US-PLT-02 · Integración continua

| ID | Capa | Subtarea | Est. |
|---|---|---|---|
| T-PLT-02.1 | INF | Flujo de CI: formateo, linter, análisis estático de seguridad, pruebas, construcción | 4 |
| T-PLT-02.2 | INF | Puerta de cobertura: 70 % global y 90 % en `domain/marcaje`, con fallo del pipeline | 3 |
| T-PLT-02.3 | INF | Análisis de dependencias de capa: falla si `domain` importa infraestructura (ADR-02) | 2 |
| T-PLT-02.4 | INF | Escaneo de secretos y de vulnerabilidades de dependencias | 2 |
| T-PLT-02.5 | INF | Publicación de imagen etiquetada con versión semántica y hash de commit; construcción de artefactos móviles | 4 |
| T-PLT-02.6 | DOC | Documento de contribución: ramas, mensajes de commit, política de revisión | 2 |

---

### US-PLT-03 · Esqueleto móvil

| ID | Capa | Subtarea | Est. |
|---|---|---|---|
| T-PLT-03.1 | MOV | Proyecto Flutter con perfiles de entorno (desarrollo, pruebas, producción) y compilación AOT verificada para arm64-v8a y armeabi-v7a e iOS | 4 |
| T-PLT-03.2 | MOV | Sistema de diseño: retícula de 8 px, tipografía única con 4 escalas, paleta neutra + acento + semánticos reservados a estados de asistencia (SRS §9.3) | 6 |
| T-PLT-03.3 | MOV | Tema claro y oscuro con verificación de contraste ≥ 4.5:1 (RNF-USA-003, RNF-USA-004) | 3 |
| T-PLT-03.4 | MOV | Capa de red: cliente HTTP, interceptor de autenticación, renovación automática de token, reintentos con retroceso exponencial, `correlationId` | 5 |
| T-PLT-03.5 | MOV | Fijación de certificado y verificación de que falla ante certificado distinto (RNF-SEG-001) | 3 |
| T-PLT-03.6 | MOV | Almacenamiento seguro sobre Keystore/Keychain para tokens y cola local (RNF-SEG-003) | 3 |
| T-PLT-03.7 | MOV | Generación de modelos y cliente a partir de `contracts/openapi.yaml` | 3 |
| T-PLT-03.8 | MOV | Internacionalización con español como idioma base y arquitectura lista para otros (RNF-USA-006) | 3 |
| T-PLT-03.9 | MOV | Navegación base y manejo global de errores con mensajes accionables | 3 |
| T-PLT-03.10 | QA | Medición y ajuste de tamaño de paquete (< 40 MB) y arranque en frío (< 3 s) en dispositivo de gama media real | 4 |

**Riesgo:** el objetivo de 40 MB obliga a vigilar dependencias de mapas desde el inicio. Medir en cada versión, no al final.

---

### US-PLT-04 · Esqueleto web

| ID | Capa | Subtarea | Est. |
|---|---|---|---|
| T-PLT-04.1 | WEB | Proyecto Flutter Web con compilación a WebAssembly y verificación en los cuatro navegadores objetivo | 4 |
| T-PLT-04.2 | WEB | Reutilización del sistema de diseño y de los modelos generados desde OpenAPI | 3 |
| T-PLT-04.3 | WEB | Estructura de navegación de la consola: panel, espacios, académico, parámetros, usuarios, marcajes, justificaciones, reportes, bitácora | 5 |
| T-PLT-04.4 | WEB | Diseño responsivo desde 1280 px y auditoría de accesibilidad | 3 |
| T-PLT-04.5 | INF | Contenedor estático servido tras Traefik con cabeceras de seguridad | 2 |

---

### US-PLT-05 · Observabilidad y prueba de carga

| ID | Capa | Subtarea | Est. |
|---|---|---|---|
| T-PLT-05.1 | BE | Métricas: histograma de latencia por ruta, contadores de resultado de marcaje, saturación de la reserva de conexiones | 4 |
| T-PLT-05.2 | INF | Despliegue de Prometheus, Grafana y Loki; tableros de latencia, errores y resultados de marcaje | 5 |
| T-PLT-05.3 | INF | Alertas: p95 por encima del objetivo, tasa de error, worker detenido, conexiones agotadas | 3 |
| T-PLT-05.4 | QA | Guion de prueba de carga que reproduce el pico: 300 req/s sostenidas 10 min sobre `POST /marcajes` con datos realistas | 6 |
| T-PLT-05.5 | QA | Verificación de planes de ejecución: ninguna consulta geoespacial hace escaneo de colección | 3 |
| T-PLT-05.6 | MOV | Desfase aleatorio de hasta 20 s en el refresco de sesión activa (mitigación R-05) | 2 |
| T-PLT-05.7 | DOC | Informe de capacidad con el dimensionamiento resultante y el punto de saturación encontrado | 3 |

---

### US-AUT-01 · Login institucional

| ID | Capa | Subtarea | Est. |
|---|---|---|---|
| T-AUT-01.1 | DB | Colección `usuarios` con índice único de correo, estado, roles y ámbitos | 2 |
| T-AUT-01.2 | BE | Hash de contraseña con Argon2id y parámetros calibrados al hardware objetivo | 3 |
| T-AUT-01.3 | BE | Caso de uso de autenticación con validación de estado y dominio institucional permitido | 3 |
| T-AUT-01.4 | BE | Emisión de JWT: acceso ≤ 15 min con claims de usuario, rol activo, permisos y ámbito; refresco ≤ 30 días almacenado con hash | 4 |
| T-AUT-01.5 | BE | Renovación con **rotación obligatoria** y detección de reutilización que revoca la familia completa | 5 |
| T-AUT-01.6 | BE | Middleware de autenticación: verificación de firma, expiración y lista de revocación | 3 |
| T-AUT-01.7 | MOV | Pantalla de inicio de sesión y persistencia segura de tokens | 4 |
| T-AUT-01.8 | WEB | Pantalla de inicio de sesión de la consola | 3 |
| T-AUT-01.9 | QA | Pruebas: credenciales válidas e inválidas, usuario inactivo, rotación, reutilización de refresco, dominio no permitido | 4 |

---

### US-AUT-02 · Bloqueo y límite de tasa

| ID | Capa | Subtarea | Est. |
|---|---|---|---|
| T-AUT-02.1 | BE | Contador de intentos fallidos por cuenta con ventana deslizante y bloqueo temporal parametrizado | 3 |
| T-AUT-02.2 | BE | Limitador de tasa por IP y por usuario, con `Retry-After`, apoyado en almacenamiento compartido para funcionar con varias instancias | 5 |
| T-AUT-02.3 | BE | Desbloqueo administrativo auditado | 2 |
| T-AUT-02.4 | INF | Límite perimetral en Cloudflare como primera línea | 2 |
| T-AUT-02.5 | QA | Pruebas de bloqueo, expiración de bloqueo y respuesta 429 | 3 |

---

### US-AUT-03 · Dispositivo confiable

| ID | Capa | Subtarea | Est. |
|---|---|---|---|
| T-AUT-03.1 | DB | Colección `dispositivos`: usuario, identificador de instalación, modelo, sistema, versión de app, estado, fechas | 2 |
| T-AUT-03.2 | MOV | Generación de UUID de instalación en el primer arranque, guardado en almacenamiento seguro; **no** usar identificadores de hardware ni publicitarios | 3 |
| T-AUT-03.3 | BE | Registro y vinculación de dispositivo en el primer inicio de sesión de una instalación | 3 |
| T-AUT-03.4 | BE | Validación de dispositivo en el paso 2 del motor de marcaje | 2 |
| T-AUT-03.5 | BE | Flujo de solicitud de cambio de dispositivo y aprobación administrativa, con auditoría | 5 |
| T-AUT-03.6 | WEB | Pantalla de gestión de dispositivos por usuario: historial, aprobación, revocación | 4 |
| T-AUT-03.7 | BE | Detección de anomalía: mismo dispositivo usado por varios usuarios en 24 h (R-03) | 4 |
| T-AUT-03.8 | MOV | Pantalla de solicitud de revinculación con explicación clara del motivo | 3 |
| T-AUT-03.9 | QA | Pruebas: primer registro, dispositivo ajeno, reinstalación, aprobación, anomalía de dispositivo compartido | 4 |

---

### US-AUT-04 · Recuperación de contraseña

| ID | Capa | Subtarea | Est. |
|---|---|---|---|
| T-AUT-04.1 | BE | Generación de token de un solo uso con expiración de 30 min, almacenado con hash | 3 |
| T-AUT-04.2 | BE | Integración de envío de correo con plantilla institucional | 3 |
| T-AUT-04.3 | BE | Confirmación con política de contraseña, revocación de todas las sesiones y auditoría | 3 |
| T-AUT-04.4 | MOV/WEB | Pantallas de solicitud y de establecimiento de nueva contraseña | 4 |
| T-AUT-04.5 | QA | Pruebas: token usado, expirado, correo inexistente con respuesta indistinguible | 3 |

---

### US-ROL-01 · Permisos granulares

| ID | Capa | Subtarea | Est. |
|---|---|---|---|
| T-ROL-01.1 | BE | Catálogo de permisos como constantes tipadas; **prohibido** usar literales de cadena en los handlers | 3 |
| T-ROL-01.2 | DB | Colección `roles` y datos semilla con la matriz exacta del SRS §3.2 | 3 |
| T-ROL-01.3 | BE | Middleware de autorización que exige la declaración explícita del permiso por ruta | 4 |
| T-ROL-01.4 | BE | Verificación al arranque: toda ruta registrada declara permiso o se marca pública; en caso contrario el servicio **no arranca** | 3 |
| T-ROL-01.5 | BE | Evaluación de permisos en `domain/rbac` como función pura | 3 |
| T-ROL-01.6 | BE | Auditoría de intentos denegados | 2 |
| T-ROL-01.7 | MOV/WEB | Ocultamiento de acciones sin permiso, entendido como comodidad visual y nunca como control | 4 |
| T-ROL-01.8 | QA | Matriz de pruebas rol × endpoint que verifica la tabla del SRS §3.2 completa | 6 |

**Nota del Tech Lead:** T-ROL-01.8 es una prueba generada por tabla, no 40 pruebas escritas a mano. Si la matriz del SRS cambia, cambia el dato, no el código de prueba.

---

### US-ROL-02 · Alcance ABAC

| ID | Capa | Subtarea | Est. |
|---|---|---|---|
| T-ROL-02.1 | BE | Modelo de ámbito `{tipo, id}` múltiple por usuario y su propagación en el token | 3 |
| T-ROL-02.2 | BE | Resolución del ámbito a condición de consulta reutilizable por todos los repositorios | 6 |
| T-ROL-02.3 | BE | Aplicación en cada repositorio de lectura: espacios, asignaciones, sesiones, marcajes, justificaciones, reportes | 6 |
| T-ROL-02.4 | BE | Verificación de ámbito en acceso por identificador directo, con 403 auditado | 3 |
| T-ROL-02.5 | QA | Pruebas de fuga de ámbito: para cada recurso, un usuario de otro ámbito debe recibir 403 o resultado vacío, nunca datos ajenos | 6 |

**Nota del Tech Lead:** T-ROL-02.5 es la prueba de seguridad más importante del sistema después del motor de marcaje. Una fuga aquí es una violación de datos personales.

---

### US-GEO-01 · Jerarquía física

| ID | Capa | Subtarea | Est. |
|---|---|---|---|
| T-GEO-01.1 | DB | Colecciones `sedes`, `bloques`, `espacios` con sus índices | 3 |
| T-GEO-01.2 | BE | CRUD con validación de jerarquía, unicidad de código y borrado lógico | 6 |
| T-GEO-01.3 | BE | Verificación de impacto al inactivar un espacio con sesiones futuras | 3 |
| T-GEO-01.4 | WEB | Listado jerárquico navegable y formularios de metadatos | 6 |
| T-GEO-01.5 | MOV | Listado jerárquico para el rol administrador | 4 |
| T-GEO-01.6 | QA | Pruebas de CRUD, unicidad, jerarquía y borrado lógico | 3 |

---

### US-GEO-02 · Captura perimetral ⭐

| ID | Capa | Subtarea | Est. |
|---|---|---|---|
| T-GEO-02.1 | BE | Tipos `GeoPoint` y `GeoPolygon` en `domain/geo` con constructores que imponen el orden `[lon, lat]` y validan rangos (ADR-04) | 4 |
| T-GEO-02.2 | BE | Cálculo de área geodésica, centroide y perímetro sobre el esferoide, con precisión verificada contra valores conocidos | 6 |
| T-GEO-02.3 | MOV | Servicio de ubicación con proveedor fusionado, flujo de precisión en vivo y gestión de permisos | 6 |
| T-GEO-02.4 | MOV | Algoritmo de captura de vértice: N lecturas consecutivas, descarte por umbral de precisión, promedio de las válidas (RF-GEO-003) | 6 |
| T-GEO-02.5 | MOV | Pantalla del editor GPS a pantalla completa: mapa, indicador de precisión con semáforo, botón capturar, contador de vértices, deshacer, cerrar polígono, previsualización del área (SRS §9.1) | 12 |
| T-GEO-02.6 | MOV | Bloqueo del botón de captura cuando la precisión supera el umbral, con motivo visible | 2 |
| T-GEO-02.7 | BE | Persistencia de geometría con método de captura, precisión promedio, área y centroide | 4 |
| T-GEO-02.8 | QA | Prueba unitaria dedicada exclusivamente al invariante de orden de coordenadas | 2 |
| T-GEO-02.9 | QA | Prueba de campo cronometrada: levantar un aula real en ≤ 4 min | 3 |

**Riesgo alto:** esta es la historia técnicamente más incierta del MVP. Se recomienda construirla contra un simulador de lecturas GPS con ruido configurable (T-QA-GEO) para poder probar sin salir a campo en cada iteración.

---

### US-GEO-04 · Validación geométrica

| ID | Capa | Subtarea | Est. |
|---|---|---|---|
| T-GEO-04.1 | BE | Validador de simplicidad: detección de auto-intersecciones por barrido de segmentos | 6 |
| T-GEO-04.2 | BE | Validaciones de cierre, número mínimo de vértices y rango de área configurable | 3 |
| T-GEO-04.3 | BE | Endpoint `POST /espacios/validar-geometria` que no persiste | 2 |
| T-GEO-04.4 | BE | Cálculo del polígono expandido por buffer en metros y almacenamiento en `geometriaBuffer` (ADR-06) | 8 |
| T-GEO-04.5 | MOV/WEB | Presentación de errores de validación señalando visualmente los segmentos en conflicto | 5 |
| T-GEO-04.6 | QA | Batería de polígonos patológicos: reloj de arena, vértices duplicados, área diminuta, área enorme, no cerrado, tres puntos colineales | 5 |

**Nota del Tech Lead:** el cálculo de buffer geodésico es más sutil de lo que parece a estas latitudes. Verificar contra una biblioteca geoespacial de referencia antes de dar por bueno el resultado.

---

### US-GEO-05 · Solapamientos

| ID | Capa | Subtarea | Est. |
|---|---|---|---|
| T-GEO-05.1 | BE | Consulta de intersección con `$geoIntersects` restringida a mismo bloque y piso | 4 |
| T-GEO-05.2 | BE | Cálculo del porcentaje de área solapada y regla de advertencia frente a bloqueo | 4 |
| T-GEO-05.3 | BE | Endpoint de informe global de solapamientos por sede | 3 |
| T-GEO-05.4 | MOV/WEB | Diálogo de advertencia con confirmación explícita y auditoría de la decisión | 4 |
| T-GEO-05.5 | QA | Pruebas: solapamiento parcial, total, mismo piso, pisos distintos (no debe reportar) | 3 |

---

### US-GEO-06 · Versionado de geometría

| ID | Capa | Subtarea | Est. |
|---|---|---|---|
| T-GEO-06.1 | DB | Colección `espacios_geometria_hist` de solo escritura | 2 |
| T-GEO-06.2 | BE | `PUT /espacios/{id}/geometria` que archiva la versión anterior e incrementa el contador de forma atómica | 5 |
| T-GEO-06.3 | BE | Recuperación de geometría por versión para reevaluación histórica | 3 |
| T-GEO-06.4 | WEB | Visor de versiones con superposición sobre el mapa | 5 |
| T-GEO-06.5 | QA | Pruebas de inmutabilidad del histórico y de resolución por versión | 3 |

---

### US-GEO-07 · Edición de vértices

| ID | Capa | Subtarea | Est. |
|---|---|---|---|
| T-GEO-07.1 | MOV | Edición táctil: arrastrar vértice, insertar en un lado, eliminar con pulsación larga | 8 |
| T-GEO-07.2 | WEB | Editor equivalente con ratón | 6 |
| T-GEO-07.3 | MOV/WEB | Recálculo de área en vivo durante la edición | 3 |
| T-GEO-07.4 | QA | Pruebas de interacción y de revalidación tras editar | 3 |

---

### US-GEO-08 · Buffer perimetral

| ID | Capa | Subtarea | Est. |
|---|---|---|---|
| T-GEO-08.1 | BE | Campo de buffer por espacio con resolución heredada de la cascada | 2 |
| T-GEO-08.2 | BE | Recálculo de `geometriaBuffer` disparado por cambio de geometría o de buffer | 3 |
| T-GEO-08.3 | WEB | Control de buffer con previsualización del área expandida sobre el mapa | 4 |
| T-GEO-08.4 | QA | Prueba: un punto a 8 m del borde es aceptado con buffer 10 y rechazado con buffer 5 | 2 |

---

### US-ACA-01 a US-ACA-04 · Estructura académica, franjas, asignaciones, calendario

| ID | Capa | Subtarea | Est. |
|---|---|---|---|
| T-ACA-01.1 | DB | Colecciones `periodos`, `facultades`, `programas`, `asignaturas`, `grupos` con `codigoExterno` indexado | 4 |
| T-ACA-01.2 | BE | CRUD con validación de jerarquía, estados de periodo y borrado lógico | 8 |
| T-ACA-01.3 | WEB | Pantallas de gestión académica | 10 |
| T-ACA-02.1 | BE | Modelo de franja con día de semana y horas locales, más zona horaria institucional (ADR-11) | 3 |
| T-ACA-02.2 | BE | Validaciones de coherencia y duración de franja | 2 |
| T-ACA-03.1 | DB | Colección `asignaciones` con índices de colisión | 2 |
| T-ACA-03.2 | BE | Detector de colisiones: solapamiento de docente y ocupación de aula, tolerante a codocencia | 8 |
| T-ACA-03.3 | BE | CRUD de asignaciones con `parametrosOverride`, modalidad y advertencia por espacio sin geometría | 5 |
| T-ACA-03.4 | WEB | Vista de malla de horarios con detección visual de conflictos | 12 |
| T-ACA-04.1 | DB | Colección `calendario_excepciones` con ámbito | 2 |
| T-ACA-04.2 | BE | Resolución de excepciones aplicables a una fecha y ámbito | 4 |
| T-ACA-04.3 | BE | Cancelación de sesiones ya generadas al crear una excepción posterior, con auditoría | 4 |
| T-ACA-04.4 | WEB | Calendario visual de excepciones | 5 |
| T-ACA-0x.QA | QA | Pruebas de colisión (todos los casos borde de solapamiento), excepciones por ámbito y estados de periodo | 8 |

---

### US-ACA-05 · Generación de sesiones ⭐

| ID | Capa | Subtarea | Est. |
|---|---|---|---|
| T-ACA-05.1 | BE | Función pura de expansión: franja recurrente + rango de periodo + excepciones → lista de instantes, con zona horaria explícita | 8 |
| T-ACA-05.2 | BE | Integración con la resolución de parámetros y congelación en la sesión (ADR-05, RN-002) | 4 |
| T-ACA-05.3 | BE | Congelación de la versión de geometría del espacio | 2 |
| T-ACA-05.4 | BE | Precálculo y persistencia de `ventanaEntradaAbre` y `ventanaEntradaCierra` | 3 |
| T-ACA-05.5 | BE | Escritura por lotes con operaciones masivas e idempotencia por asignación y fecha | 6 |
| T-ACA-05.6 | BE | Ejecución asíncrona en el worker con registro en `trabajos`, progreso e informe final | 6 |
| T-ACA-05.7 | BE | Endpoint de disparo y endpoint de consulta de estado del trabajo | 3 |
| T-ACA-05.8 | WEB | Pantalla de generación con progreso e informe de resultados | 5 |
| T-ACA-05.9 | QA | Pruebas: periodo de 16 semanas, excepciones intercaladas, reejecución idempotente, rendimiento con 2.000 asignaciones | 8 |

**Nota del Tech Lead:** esta operación puede crear más de 100.000 documentos. Debe ejecutarse por lotes con control de presión y jamás dentro del ciclo de petición HTTP.

---

### US-ACA-07 · Carga masiva

| ID | Capa | Subtarea | Est. |
|---|---|---|---|
| T-ACA-07.1 | DOC | Plantillas CSV y XLSX publicadas, con diccionario de columnas y ejemplos | 4 |
| T-ACA-07.2 | BE | Lector tolerante de CSV/XLSX con detección de codificación y separador | 5 |
| T-ACA-07.3 | BE | Validador por fila: tipos, referencias existentes, colisiones de horario, duplicados dentro del archivo | 10 |
| T-ACA-07.4 | BE | Modo validación sin persistencia con informe descargable anotado por fila | 5 |
| T-ACA-07.5 | BE | Aplicación transaccional por lote con umbral de fallo configurable | 6 |
| T-ACA-07.6 | BE | Almacenamiento del archivo original y auditoría de la carga | 3 |
| T-ACA-07.7 | WEB | Asistente de carga: subir, previsualizar, revisar errores, confirmar | 8 |
| T-ACA-07.8 | QA | Pruebas con archivos reales sucios: filas vacías, acentos, fechas en varios formatos, referencias inexistentes | 6 |

---

### US-PAR-01 y US-PAR-02 · Parámetros y herencia ⭐

| ID | Capa | Subtarea | Est. |
|---|---|---|---|
| T-PAR-01.1 | BE | Catálogo tipado de parámetros con valor por defecto, rango y tipo, según SRS §3.5 | 4 |
| T-PAR-01.2 | DB | Colección `parametros` por ámbito con vigencia e índice de resolución | 2 |
| T-PAR-01.3 | BE | CRUD con validación de rango y auditoría de valor anterior y nuevo | 4 |
| T-PAR-02.1 | BE | Función pura de resolución de cascada Global → Sede → Facultad → Bloque → Aula → Asignación, clave por clave | 8 |
| T-PAR-02.2 | BE | Caché de resolución con invalidación al modificar parámetros | 4 |
| T-PAR-02.3 | BE | Endpoint `/parametros/efectivos` que devuelve valor y nivel de origen | 3 |
| T-PAR-02.4 | WEB | Pantalla de parámetros con vista de herencia que muestra qué nivel gana cada clave | 8 |
| T-PAR-02.5 | QA | Batería exhaustiva de la cascada: cada nivel individual, combinaciones, huecos, y sobreescritura de clave única | 6 |

---

### US-MAR-01 · Pantalla de marcaje ⭐

| ID | Capa | Subtarea | Est. |
|---|---|---|---|
| T-MAR-01.1 | BE | `GET /me/sesiones/activa`: consulta indexada por docente y ventana, devolviendo parámetros, geometría con buffer y hora de servidor | 6 |
| T-MAR-01.2 | BE | `GET /me/sesiones/hoy` con estado de cada sesión | 3 |
| T-MAR-01.3 | BE | Regla de desempate cuando dos ventanas se solapan: gana el inicio más próximo | 2 |
| T-MAR-01.4 | MOV | Pantalla principal: tarjeta única de sesión, cuenta regresiva, botón prominente de marcaje | 10 |
| T-MAR-01.5 | MOV | Máquina de estados del botón con los seis estados del SRS §9.1, cada uno con su apariencia y texto | 8 |
| T-MAR-01.6 | MOV | Prechequeo local solo para la presentación visual, nunca decisorio (ADR-10) | 4 |
| T-MAR-01.7 | MOV | Estado vacío informativo cuando no hay sesión, con la hora de apertura de la próxima ventana | 3 |
| T-MAR-01.8 | QA | Verificación de que no existe ninguna ruta de interfaz que permita elegir aula manualmente (CA-003) | 2 |
| T-MAR-01.9 | QA | Prueba de usabilidad con docentes sin capacitación, objetivo ≥ 90 % de éxito al primer intento | 6 |

---

### US-MAR-02 · Captura de ubicación e integridad

| ID | Capa | Subtarea | Est. |
|---|---|---|---|
| T-MAR-02.1 | MOV | Solicitud del permiso "mientras se usa" exclusivamente; auditoría del código para garantizar que no existe permiso de segundo plano (RN-005) | 3 |
| T-MAR-02.2 | MOV | Lectura puntual con proveedor fusionado, tiempo límite y descarte de lecturas antiguas | 5 |
| T-MAR-02.3 | MOV | Detección de ubicación simulada en ambas plataformas | 4 |
| T-MAR-02.4 | MOV | Detección de root, jailbreak y emulador | 6 |
| T-MAR-02.5 | MOV | Integración de atestación de aplicación de plataforma y obtención del testigo | 6 |
| T-MAR-02.6 | MOV | Flujo de permiso denegado con explicación accionable y acceso directo a los ajustes del sistema (R-10) | 4 |
| T-MAR-02.7 | MOV | Ensamblado del cuerpo de la petición con todos los campos de evidencia | 3 |
| T-MAR-02.8 | QA | Pruebas con app de ubicación falsa real, dispositivo con root y emulador | 5 |

---

### US-MAR-03 · Motor de validación ⭐⭐

| ID | Capa | Subtarea | Est. |
|---|---|---|---|
| T-MAR-03.1 | BE | Tipos del dominio: `SolicitudMarcaje`, `ContextoSesion`, `Resultado`, `MotivoRechazo`, `Paso` | 4 |
| T-MAR-03.2 | BE | Implementación de los 11 pasos de RN-001 como función pura, con reloj inyectado (ADR-02, ADR-03) | 10 |
| T-MAR-03.3 | BE | Contención punto-en-polígono y distancia geodésica mínima punto-polígono en `domain/geo` | 8 |
| T-MAR-03.4 | BE | Caso de uso que arma el contexto con una sola ronda de consultas y delega la decisión al dominio | 6 |
| T-MAR-03.5 | BE | Optimización de la consulta de contención con `$geoIntersects` sobre `geometriaBuffer` indexada | 4 |
| T-MAR-03.6 | BE | Tratamiento explícito de la modalidad virtual (salto de pasos geoespaciales) | 2 |
| T-MAR-03.7 | BE | Cálculo del desfase de reloj y marcado de anomalía sobre el umbral | 3 |
| T-MAR-03.8 | QA | Implementación completa de la batería de §11.4, incluidos los casos de borde exacto | 12 |
| T-MAR-03.9 | QA | Pruebas basadas en propiedades: para cualquier punto generado dentro del polígono, el resultado nunca es fuera de área | 5 |
| T-MAR-03.10 | QA | Verificación de cobertura ≥ 90 % en el paquete | 2 |

**Nota del Tech Lead:** esta historia no se subdivide entre varios desarrolladores. Un solo responsable, revisión por pares obligatoria y ninguna fusión sin la batería completa en verde. Es el único punto del sistema donde un error silencioso produce injusticia laboral.

---

### US-MAR-04 y US-MAR-05 · Persistencia e idempotencia

| ID | Capa | Subtarea | Est. |
|---|---|---|---|
| T-MAR-04.1 | DB | Colección `marcajes` con todos los campos de evidencia e índices de §10.3 | 3 |
| T-MAR-04.2 | DB | Índice único **parcial** `{sesionId, usuarioId, tipo}` excluyendo anulados (§10.4) | 2 |
| T-MAR-04.3 | BE | Persistencia de marcajes aceptados **y rechazados** (RF-AUD-004) | 3 |
| T-MAR-04.4 | BE | Traducción del error de clave duplicada a devolución del registro existente (ADR-07) | 4 |
| T-MAR-04.5 | BE | Soporte de `Idempotency-Key` con caché de respuesta de corta duración | 4 |
| T-MAR-04.6 | MOV | Deshabilitación inmediata del botón tras el toque y gestión de tiempo límite | 2 |
| T-MAR-04.7 | QA | Prueba de concurrencia: 20 peticiones simultáneas producen exactamente un marcaje | 4 |

---

### US-MAR-06 · Mensajes accionables

| ID | Capa | Subtarea | Est. |
|---|---|---|---|
| T-MAR-06.1 | BE | Catálogo de mensajes por motivo con datos interpolables (distancia, minutos, precisión) | 4 |
| T-MAR-06.2 | MOV | Presentación de cada rechazo con el formato del SRS §9.1 y acción sugerida | 5 |
| T-MAR-06.3 | MOV | Acceso directo desde el rechazo a radicar justificación (cuando EP-07 exista) | 2 |
| T-MAR-06.4 | QA | Revisión de redacción de todos los mensajes contra el criterio "qué pasó, por qué, qué hacer" | 3 |

---

### US-MAR-07 · Ausencias automáticas

| ID | Capa | Subtarea | Est. |
|---|---|---|---|
| T-MAR-07.1 | BE | Trabajo programado cada 15 min en el worker, con bloqueo distribuido (ADR-09, RN-003) | 5 |
| T-MAR-07.2 | BE | Consulta indexada de sesiones con ventana expirada y sin marcaje válido | 4 |
| T-MAR-07.3 | BE | Marcado idempotente por lotes, excluyendo canceladas y con suplencia resuelta | 4 |
| T-MAR-07.4 | BE | Reversión de ausencia cuando llega un marcaje offline válido posterior, con auditoría | 4 |
| T-MAR-07.5 | INF | Alerta si el trabajo no se ejecuta en dos ciclos consecutivos | 2 |
| T-MAR-07.6 | QA | Pruebas con reloj falso: ventana justo expirada, cancelada, con suplente, reejecución | 4 |

---

### US-MAR-08 · Historial propio

| ID | Capa | Subtarea | Est. |
|---|---|---|---|
| T-MAR-08.1 | BE | `GET /me/historial` paginado con filtro por mes, usando el índice de usuario y fecha | 3 |
| T-MAR-08.2 | MOV | Cronología con estados codificados por color semántico y detalle expandible | 6 |
| T-MAR-08.3 | QA | Prueba de que un usuario no puede obtener el historial de otro | 2 |

---

### US-MAR-09 · Ajuste administrativo

| ID | Capa | Subtarea | Est. |
|---|---|---|---|
| T-MAR-09.1 | BE | Endpoints de ajuste, anulación y creación manual con motivo obligatorio | 5 |
| T-MAR-09.2 | BE | Conservación del registro original y marcado de origen manual | 3 |
| T-MAR-09.3 | BE | Auditoría con valores anterior y nuevo completos | 2 |
| T-MAR-09.4 | WEB | Pantalla de marcajes con búsqueda, filtros y flujo de ajuste | 8 |
| T-MAR-09.5 | QA | Pruebas de permisos, motivo obligatorio y trazabilidad | 3 |

---

### US-MAR-10 · Integridad y atestación

| ID | Capa | Subtarea | Est. |
|---|---|---|---|
| T-MAR-10.1 | BE | Verificación del testigo de atestación contra el servicio de la plataforma, con caché de claves | 8 |
| T-MAR-10.2 | BE | Aplicación de los interruptores de integridad por ámbito desde los parámetros | 3 |
| T-MAR-10.3 | BE | Detección de saltos imposibles entre marcajes consecutivos del mismo usuario | 5 |
| T-MAR-10.4 | BE | Registro de anomalías y evento de seguridad en auditoría | 3 |
| T-MAR-10.5 | WEB | Panel de anomalías de integridad para revisión administrativa | 5 |
| T-MAR-10.6 | QA | Pruebas con testigo inválido, ausente y caducado | 4 |

---

### US-AUD-01 y US-AUD-02 · Auditoría

| ID | Capa | Subtarea | Est. |
|---|---|---|---|
| T-AUD-01.1 | DB | Colección `auditoria` sin permisos de actualización ni borrado a nivel de credencial de aplicación | 3 |
| T-AUD-01.2 | BE | Decorador de auditoría aplicable a casos de uso sensibles (ADR-08) | 6 |
| T-AUD-01.3 | BE | Cálculo de diferencia entre valor anterior y nuevo, con enmascaramiento de campos sensibles | 5 |
| T-AUD-01.4 | BE | Captura de IP, agente de usuario, rol activo y correlación | 3 |
| T-AUD-01.5 | BE | Garantía de que el fallo de auditoría revierte la operación de negocio | 4 |
| T-AUD-01.6 | BE | Borrado lógico transversal en entidades operativas | 4 |
| T-AUD-02.1 | BE | Registro de evento de seguridad para rechazos por integridad | 2 |
| T-AUD-0x.QA | QA | Pruebas: toda operación sensible genera entrada; ningún endpoint permite escribir en la bitácora | 5 |

---

### US-REP-01 y US-REP-02 · Reportes y exportación

| ID | Capa | Subtarea | Est. |
|---|---|---|---|
| T-REP-01.1 | BE | Canalización de agregación del reporte de cumplimiento con filtros y ámbito aplicado | 10 |
| T-REP-01.2 | BE | Distinción de ausencias justificadas e injustificadas y de marcajes de origen manual | 4 |
| T-REP-01.3 | BE | Ejecución asíncrona para rangos grandes, con registro en `trabajos` | 5 |
| T-REP-01.4 | WEB | Pantalla de reporte con filtros, tabla y totales | 10 |
| T-REP-02.1 | BE | Exportación XLSX con tipos correctos de fecha y número | 5 |
| T-REP-02.2 | BE | Exportación PDF con marca de agua institucional, sello de generación y hash SHA-256 del contenido | 8 |
| T-REP-02.3 | BE | Auditoría de exportaciones con filtro y volumen | 2 |
| T-REP-0x.QA | QA | Pruebas de determinismo del cálculo, aplicación de ámbito y rendimiento con 200 docentes | 6 |

---

### US-LEG-01 · Consentimiento informado

| ID | Capa | Subtarea | Est. |
|---|---|---|---|
| T-LEG-01.1 | DB | Colección `consentimientos` con versión de política, fecha e IP | 2 |
| T-LEG-01.2 | BE | Endpoints de consulta de la política vigente y de registro de aceptación | 3 |
| T-LEG-01.3 | MOV | Flujo de incorporación: aviso de privacidad, aceptación explícita y **solo después** solicitud del permiso de ubicación | 6 |
| T-LEG-01.4 | MOV | Bloqueo del marcaje sin consentimiento, conservando el acceso a consultar horario | 3 |
| T-LEG-01.5 | MOV/WEB | Acceso permanente a la política desde perfil y consola | 3 |
| T-LEG-01.6 | BE | Reexigencia de aceptación al publicar una versión nueva de la política | 3 |
| T-LEG-01.7 | DOC | Redacción del aviso de privacidad con declaración explícita de ausencia de rastreo continuo | 4 |
| T-LEG-01.8 | QA | Verificación del orden: ninguna solicitud de permiso precede a la aceptación (CA-011) | 2 |

---

### US-SEG-01 · Endurecimiento de seguridad

| ID | Capa | Subtarea | Est. |
|---|---|---|---|
| T-SEG-01.1 | BE | Validación exhaustiva de toda entrada con esquemas, incluidos rangos geográficos | 6 |
| T-SEG-01.2 | INF | TLS 1.3 extremo a extremo, cabeceras de seguridad y configuración de Cloudflare | 4 |
| T-SEG-01.3 | INF | Cifrado en reposo verificado y rotación de credenciales de infraestructura | 3 |
| T-SEG-01.4 | QA | Análisis dinámico automatizado con resolución de hallazgos críticos y altos | 8 |
| T-SEG-01.5 | QA | Revisión móvil contra el estándar de verificación de seguridad de aplicaciones móviles | 8 |
| T-SEG-01.6 | INF | Respaldo diario con retención de 30 días y **prueba de restauración documentada** | 5 |
| T-SEG-01.7 | DOC | Guías de operación: incidente de seguridad, restauración, rotación de secretos | 5 |

---

### Historias de F2 y F3 — desglose resumido

| Historia | Subtareas principales | Est. total |
|---|---|---|
| US-GEO-03 Captura por mapa | Integración de teselas satelitales, captura por toque, modo mixto, caché de teselas | 16 h |
| US-GEO-09 Centroide+radio | Generación de polígono circular, control de radio, registro de método | 10 h |
| US-GEO-10 Captura offline | Cola local cifrada, sincronización, resolución de conflictos, interfaz de pendientes | 28 h |
| US-GEO-11 GeoJSON/KML | Lectores y escritores, previsualización, detección de coordenadas invertidas | 18 h |
| US-GEO-12 Clonar piso | Copia de geometría, plantilla de códigos, validación de colisión | 10 h |
| US-GEO-13 Verificación complementaria | Registro por espacio, lectura de BSSID, escaneo BLE, lector QR, integración con el paso 9 del motor | 30 h |
| US-AUT-05 TOTP | Generación de secreto, verificación, códigos de respaldo, exigencia por rol | 24 h |
| US-AUT-06 Biometría | Autenticación local, recuperación de token seguro, alternativas | 16 h |
| US-AUT-07 Revocación remota | Lista de revocación distribuida, pantalla administrativa, auditoría | 16 h |
| US-ROL-03 Roles personalizados | CRUD de roles, protección de roles del sistema, pantalla de composición | 18 h |
| US-ROL-04 Multi-rol | Contexto activo en el token, selector, propagación a auditoría | 16 h |
| US-PAR-03 Parámetro efectivo | Endpoint con origen, vista de herencia en consola | 16 h |
| US-ACA-08 Codocencia | Ajuste del detector de colisiones, atribución en reportes | 10 h |
| US-ACA-09 Suplencia | Designación, transferencia de autorización, efecto en reportes y ausencias | 18 h |
| US-MAR-11 Offline | Cola local firmada, endpoint de sincronización por lotes, reevaluación con reloj del dispositivo, detección de desfase, revisión manual, reversión de ausencias | 44 h |
| US-MAR-13 Marcaje estudiantil | Ventana estudiantil, autorización por grupo, rendimiento de concurrencia en aula, porcentaje acumulado | 42 h |
| US-MAR-14 Lista manual | Interfaz de lista, reglas de precedencia, auditoría de uso | 18 h |
| US-MAR-15 Marcaje de salida | Holguras de salida, cálculo de permanencia, modos del parámetro | 18 h |
| US-JUS-01 a 04 Justificaciones | Modelo, adjuntos cifrados, flujo de estados, bandeja con ámbito, efecto en reportes, notificaciones | 70 h |
| US-REP-03 Tablero | Agregaciones precalculadas, actualización con desfase, pantalla | 26 h |
| US-REP-04 Ocupación | Agregación por espacio y jerarquía, exportación | 16 h |
| US-REP-05 Asistencia estudiantil | Agregación por grupo y estudiante, vista en app | 18 h |
| US-AUD-03 Consulta bitácora | Filtros indexados, exportación, pantalla | 16 h |
| US-AUD-04 Retención | Trabajo de anonimización, suspensión por investigación | 16 h |
| US-NOT-01 a 03 Notificaciones | Registro de testigos, cola de envío, catálogo, preferencias, alertas | 52 h |
| US-LEG-02 Derechos del titular | Exportación de datos personales, flujo de solicitudes, reglas de conservación | 26 h |
---

## 13. Definición de Listo y Definición de Terminado

### 13.1 Definición de Listo (una historia puede entrar a sprint)

- [ ] Tiene rol, capacidad y beneficio expresados sin ambigüedad.
- [ ] Tiene criterios de aceptación en formato verificable, cada uno convertible en prueba.
- [ ] Tiene trazabilidad a requerimientos del SRS.
- [ ] Sus dependencias están terminadas o planificadas antes en el mismo sprint.
- [ ] Está estimada y no supera 13 puntos.
- [ ] El contrato de API que necesita está definido en `contracts/openapi.yaml`.
- [ ] Si toca interfaz, existe el estado visual definido (incluidos vacío, carga y error).
- [ ] Si toca datos personales, se revisó su impacto de privacidad.

### 13.2 Definición de Terminado (una historia está realmente terminada)

- [ ] Todos los criterios de aceptación pasan, verificados por pruebas automatizadas que los referencian por identificador.
- [ ] Cobertura: ≥ 70 % en el código nuevo de backend; ≥ 90 % si toca `domain/marcaje`.
- [ ] Análisis estático y escaneo de seguridad sin hallazgos nuevos.
- [ ] OpenAPI actualizado y regenerados los modelos de cliente.
- [ ] Operaciones sensibles emiten auditoría, verificado por prueba.
- [ ] Permisos y ámbito verificados con prueba negativa (un usuario sin derecho recibe 403).
- [ ] Sin consultas que escaneen colección en rutas de lectura frecuente, verificado por plan de ejecución.
- [ ] Mensajes de error revisados contra "qué pasó, por qué, qué hacer".
- [ ] Interfaz revisada contra accesibilidad: contraste, área táctil, lector de pantalla.
- [ ] Revisión por pares aprobada.
- [ ] Desplegada en el entorno de pruebas y demostrada al PO.
- [ ] Documentación operativa actualizada si cambia el comportamiento de despliegue.

### 13.3 Reglas de trabajo para agentes de desarrollo

1. **No inventar requisitos.** Si un criterio de aceptación no cubre un caso, se pregunta al PO; no se decide en silencio.
2. **No relajar un criterio para cerrar la historia.** Una historia parcialmente cumplida vuelve al backlog; no se marca terminada.
3. **El dominio no importa infraestructura.** Si para implementar algo hace falta romper esa regla, la solución está mal planteada.
4. **Toda decisión de negocio tomada durante la implementación se documenta** como nota en el pull request y se propone como ADR si es estructural.
5. **Ningún literal de configuración en código.** Umbrales, plazos, holguras y límites van a parámetros.
6. **Coordenadas siempre `[longitud, latitud]`.** Si se escribe `[lat, lon]` en cualquier punto, es un defecto, aunque funcione en la prueba.
7. **Cada rechazo se persiste.** Nunca se descarta un intento fallido.
8. **Nunca se registra la contraseña, el token ni la ubicación exacta en logs.** La ubicación va al documento de marcaje, no a la bitácora de aplicación.

---

## 14. Estrategia de pruebas

| Nivel | Alcance | Responsable | Umbral |
|---|---|---|---|
| Unitarias | Dominio puro: motor de marcaje, geometría, cascada de parámetros, expansión de sesiones, RBAC | Desarrollador | ≥ 70 % global, ≥ 90 % en marcaje |
| Integración | Repositorios contra MongoDB real en contenedor efímero, incluidos índices y planes de ejecución | Desarrollador | Toda consulta crítica |
| Contrato | Verificación de que la implementación cumple `openapi.yaml` y que el cliente generado compila | CI | Bloqueante |
| Seguridad | Matriz rol × endpoint, pruebas de fuga de ámbito, análisis dinámico | QA | Cero hallazgos altos |
| Extremo a extremo | Flujos completos: levantar aula → crear asignación → generar sesiones → marcar → ver reporte | QA | Los 12 criterios del SRS §12 |
| Carga | Pico de cambio de hora: 300 req/s durante 10 min | QA | p95 ≤ 2 s, error ≤ 0,1 % |
| Campo | Levantamiento real, marcaje real, medición de falsos rechazos | Equipo + piloto | < 2 % en dos semanas |
| Usabilidad | Docentes sin capacitación, primer intento | PO + QA | ≥ 90 % de éxito |

### 14.1 Herramienta indispensable: simulador de GPS con ruido

Construir temprano (**T-QA-GEO**, 8 h) un simulador que genere lecturas de ubicación con error configurable alrededor de un punto verdadero, incluyendo deriva, saltos y fallos de fijación. Sin él, cada prueba del editor GPS y del motor requiere salir a un aula, y el ciclo de retroalimentación se vuelve inviable.

### 14.2 Cobertura obligatoria de los criterios del SRS §12

Los doce criterios de aceptación de muestra del SRS son pruebas automatizadas de extremo a extremo con nombre explícito:

| Criterio SRS | Prueba | Historia |
|---|---|---|
| CA-001 | `e2e_marcaje_presente_dentro_ventana` | US-MAR-03 |
| CA-002 | `e2e_marcaje_rechazo_fuera_de_area_con_distancia` | US-MAR-03 |
| CA-003 | `ui_no_existe_seleccion_manual_de_aula` | US-MAR-01 |
| CA-004 | `unit_motor_fuera_de_horario_25min` | US-MAR-03 |
| CA-005 | `unit_motor_tardanza_12min` | US-MAR-03 |
| CA-006 | `e2e_mock_location_rechazo_y_auditoria` | US-MAR-10 |
| CA-007 | `e2e_captura_poligono_5_vertices_con_advertencia_solapamiento` | US-GEO-05 |
| CA-008 | `e2e_cambio_parametro_no_afecta_sesiones_generadas` | US-ACA-05 |
| CA-009 | `e2e_marcaje_offline_sincroniza_conservando_hora` | US-MAR-11 |
| CA-010 | `e2e_coordinador_otra_facultad_403_auditado` | US-ROL-02 |
| CA-011 | `e2e_consentimiento_precede_permiso_ubicacion` | US-LEG-01 |
| CA-012 | `e2e_doble_toque_un_solo_marcaje` | US-MAR-05 |

---

## 15. Entornos y despliegue

| Entorno | Propósito | Datos | Acceso |
|---|---|---|---|
| Desarrollo | Trabajo diario | Semilla sintética | Equipo |
| Pruebas | Verificación de historias y demostraciones al PO | Copia anonimizada de datos piloto | Equipo + PO |
| Piloto | Fase F2 con usuarios reales de una facultad | Reales | Usuarios piloto |
| Producción | Operación institucional | Reales | Todos |

### 15.1 Topología de despliegue

```
Internet → Cloudflare (WAF, TLS, límite perimetral)
              ↓
          VPS · Traefik (proxy inverso, TLS interno)
              ├── siaa-api        (binario compilado, N réplicas)
              ├── siaa-worker     (procesos programados, réplica única con bloqueo)
              ├── siaa-admin-web  (WASM estático)
              └── observabilidad  (Prometheus, Grafana, Loki)
              ↓
          MongoDB Atlas (lista de IP permitidas o emparejamiento de red privada)
```

### 15.2 Reglas operativas

- El worker **nunca** comparte proceso con el API (ADR-09).
- Las migraciones de índices se ejecutan en el arranque de forma idempotente y bloquean el arranque si fallan.
- Todo despliegue es reversible: la versión anterior permanece disponible.
- Objetivos de continuidad: punto de recuperación ≤ 1 h, tiempo de recuperación ≤ 4 h, disponibilidad ≥ 99,5 % en horario académico.
- Ventanas de mantenimiento fuera del horario académico, nunca entre las 6:00 y las 22:00 en días lectivos.

---

## 16. Riesgos técnicos con plan de acción asignado

| ID SRS | Riesgo | Historia o tarea que lo mitiga | Señal de alarma | Plan si se materializa |
|---|---|---|---|---|
| R-01 | GPS no distingue pisos | SPIKE-01, US-GEO-13, campo `nivelValidacion` | El spike muestra contención cruzada entre pisos | Degradar a validación por bloque (cambio de configuración, no de código) y activar verificación complementaria en bloques altos |
| R-02 | Precisión degradada en interiores | US-GEO-08, US-PAR-01, US-REP-06 | Tasa de rechazo por área > 5 % en el piloto | Aumentar buffer por aula guiado por el mapa de calor; recalibrar con datos, no por queja |
| R-03 | Falsificación de ubicación | US-MAR-10, US-AUT-03 | Anomalías de dispositivo compartido o saltos imposibles | Activar atestación obligatoria y bloqueo por integridad; revisar casos concretos |
| R-04 | Aulas menores que el error GPS | SPIKE-01, `zonaMarcajeId` | Aulas con rechazo sistemático pese a buffer alto | Agrupar en zona de marcaje común o exigir verificación complementaria en ellas |
| R-05 | Pico de carga sincronizado | US-PLT-05, T-PLT-05.6, ADR-09 | Latencia p95 creciente en franjas de inicio | Escalar réplicas del API; el worker ya está aislado |
| R-06 | Resistencia docente | US-MAR-08, US-MAR-06, US-JUS-01, US-LEG-01 | Volumen alto de justificaciones por falla técnica | Acelerar F3 de justificaciones; transparencia total del propio registro; socialización |
| R-07 | Transferencia internacional de datos | US-LEG-03 | Observación jurídica institucional | Selección de región más cercana y cláusulas documentadas |
| R-08 | Exigencias de publicación en tienda | US-LEG-01, T-LEG-01.7 | Rechazo de la revisión de la tienda | Declaración precisa del propósito de ubicación; distribución empresarial como alternativa |
| R-09 | Deriva de horarios | US-ACA-07, `codigoExterno`, US-ACA-10 | Sesiones que no corresponden a la realidad | Proceso de conciliación con informe de diferencias |
| R-10 | Permiso denegado por el usuario | T-MAR-02.6 | Usuarios que no logran marcar nunca | Incorporación explicativa y guía de reactivación del permiso |
| **T-01** | *(nuevo)* Cálculo de buffer geodésico incorrecto | T-GEO-04.4 verificado contra biblioteca de referencia | Discrepancia entre área esperada y calculada | Sustituir implementación propia por biblioteca geoespacial probada |
| **T-02** | *(nuevo)* Coordenadas invertidas en algún punto del flujo | ADR-04, T-GEO-02.8 | Marcajes rechazados en masa o aceptados en lugares imposibles | Tipos fuertes y validación de rango en toda frontera |
| **T-03** | *(nuevo)* Manipulación de la hora del dispositivo en modo offline | US-MAR-11 AC-04 | Desfases de reloj recurrentes en un mismo usuario | Someter a revisión manual; desactivar offline por ámbito |
| **T-04** | *(nuevo)* Volumen de sesiones mayor al previsto | T-ACA-05.5 por lotes | Generación que excede 5 min | Particionar por facultad y ejecutar por tandas |

---

## 17. Matriz de trazabilidad SRS → historias

| Módulo SRS | Requerimientos | Historias que los cubren |
|---|---|---|
| AUT | RF-AUT-001..008 | US-AUT-01, 02, 03, 04, 05, 06, 07, 08 |
| ROL | RF-ROL-001..006 | US-ROL-01, 02, 03, 04, 05 |
| GEO | RF-GEO-001..016 | US-GEO-01 a 13 |
| ACA | RF-ACA-001..013 | US-ACA-01 a 10 |
| PAR | RF-PAR-001..010 | US-PAR-01, 02, 03, 04 |
| MAR | RF-MAR-001..016 | US-MAR-01 a 15 |
| JUS | RF-JUS-001..005 | US-JUS-01, 02, 03, 04 |
| REP | RF-REP-001..007 | US-REP-01 a 07 |
| AUD | RF-AUD-001..005 | US-AUD-01, 02, 03; US-GEO-01 (borrado lógico) |
| NOT | RF-NOT-001..004 | US-NOT-01, 02, 03 |
| Rendimiento | RNF-PER-001..005 | US-PLT-03, US-PLT-05, US-MAR-03 |
| Disponibilidad | RNF-DIS-001..004 | US-SEG-01, US-MAR-11, §15 |
| Seguridad | RNF-SEG-001..009 | US-PLT-03, US-AUT-01..03, US-MAR-10, US-SEG-01 |
| Usabilidad | RNF-USA-001..007 | US-PLT-03, US-PLT-04, US-MAR-01, US-MAR-06 |
| Compatibilidad | RNF-COM-001..004 | US-PLT-03, US-PLT-04, US-MAR-02 |
| Mantenibilidad | RNF-MAN-001..005 | US-PLT-01, US-PLT-02 |
| Legales | RNF-LEG-001..007 | US-LEG-01, 02, 03; US-AUD-04; US-MAR-02 |
| Reglas de negocio | RN-001..005 | US-MAR-03 (RN-001), US-ACA-05 (RN-002), US-MAR-07 (RN-003), US-MAR-11 (RN-004), US-MAR-02 (RN-005) |

**Cobertura:** todos los requerimientos funcionales y no funcionales del SRS tienen al menos una historia asignada. Ningún requerimiento queda huérfano.

---

## 18. Preguntas abiertas que el equipo debe elevar al PO

Estas no bloquean el arranque, pero deben resolverse antes del sprint indicado.

| # | Pregunta | Necesaria antes de | Supuesto provisional |
|---|---|---|---|
| Q-1 | ¿Cuál es el dominio de correo institucional autorizado? | S1 | Configurable, lista blanca |
| Q-2 | ¿Zona horaria única o multi-sede? | S4 | `America/Bogota` única |
| Q-3 | ¿Qué define "hora dictada" en el reporte: la duración programada o la efectiva entre entrada y salida? | S8 | Duración programada si no hay marcaje de salida |
| Q-4 | ¿Una tardanza cuenta como sesión dictada para el cumplimiento? | S8 | Sí, se contabiliza como dictada y se reporta aparte |
| Q-5 | ¿Cuánto tiempo se conservan los datos de marcaje? | F3 | 5 años, luego anonimización |
| Q-6 | ¿Quién es el responsable institucional del tratamiento de datos? | F1, para el aviso | Pendiente |
| Q-7 | ¿Existe acto administrativo de adopción del sistema? | Antes del piloto | Pendiente; es bloqueante legal (RNF-LEG-007) |
| Q-8 | ¿El monitor/auxiliar entra en v1? | F3 | No; se difiere |

---

## 19. Checklist de arranque para el equipo

Orden literal de las primeras dos semanas:

1. Leer el SRS completo y este documento. No empezar a escribir código antes.
2. Confirmar el stack (ADR-01) y provisionar el clúster de base de datos y el VPS.
3. `T-PLT-01.1` a `T-PLT-01.11`: esqueleto del API desplegado con salud verde.
4. `T-PLT-02.*`: CI con las puertas de calidad activas desde el primer commit.
5. `T-PLT-03.1` a `T-PLT-03.6`: esqueleto móvil con red segura y almacenamiento seguro.
6. `T-AUT-01.*`: login funcionando de punta a punta.
7. `T-ROL-01.1` a `T-ROL-01.4`: catálogo de permisos y verificación de arranque.
8. `T-QA-GEO`: simulador de GPS con ruido, antes de tocar el editor.
9. Sprint 2: editor GPS.
10. Sprint 3: `SPIKE-01` en campo. **Reunión de decisión obligatoria al cierre del spike** con el PO y la institución para cerrar D-1.

---

## 20. Ficha de control del documento

| Campo | Valor |
|---|---|
| Código | SIAA-BLG-001 |
| Versión | 1.0 |
| Fecha | Septiembre de 2026 |
| Basado en | SIAA-SRS-001 v1.0 |
| Épicas | 12 |
| Historias de usuario | 82 + 1 spike |
| Criterios de aceptación | Más de 380 |
| Subtareas técnicas detalladas | Más de 210 |
| Puntos estimados | 550 (F1 ≈ 265) |
| Estado | Listo para planificación de sprint 1 |

**Condición de revisión:** este documento se actualiza al cierre de `SPIKE-01` y al cierre de las decisiones institucionales pendientes del SRS §10. Ambos eventos pueden alterar la priorización de EP-03 y EP-06.

---

*Fin del documento.*
