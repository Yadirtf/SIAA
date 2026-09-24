# Prompt técnico — Navegación por rol en la app móvil (SIAA)

## Contexto para el agente

Estás trabajando sobre el proyecto SIAA (Sistema Integrado de Asistencia
Académica). El backend ya expone autenticación con RBAC/ABAC (roles y
permisos con formato `recurso:accion`, ver módulo ROL del documento base
de requerimientos). Actualmente, después de iniciar sesión, la app móvil
redirige a una sola pantalla fija (ej. "Espacios / jerarquía física y
cartográfica"), sin importar el rol del usuario.

## Objetivo

Reemplazar esa redirección fija por una estructura de navegación que se
arma dinámicamente según el rol (o roles) del usuario autenticado, con
dos niveles:

1. **Barra inferior (bottom navigation)** — accesos rápidos, máximo 4
   ítems, cada uno con su ícono correspondiente a la pantalla.
2. **Menú lateral (drawer / sidebar)** — el resto de las opciones a las
   que el rol tiene acceso, abierto mediante un botón de hamburguesa en
   la esquina superior izquierda del AppBar.

Si un rol tiene 4 o menos opciones en total, todas van en la barra
inferior y el drawer solo contiene los ítems comunes (Perfil, Privacidad,
Cerrar sesión). Si tiene más de 4, las 3-4 más usadas van abajo y el
resto al drawer.

## Paso 1 — Analizar roles y permisos antes de tocar código

Antes de implementar nada, el agente debe extraer del documento base
(secciones 2.3 "Actores del sistema" y 3.2 "Módulo ROL — Matriz de
permisos base") lo siguiente, y dejarlo documentado en un archivo de
configuración (no hardcodeado dentro de los widgets):

- Lista de roles que operan desde el canal móvil.
- Para cada rol, qué permisos tiene (formato `recurso:accion`).
- Para cada permiso, a qué pantalla/función corresponde.
- Qué pasa cuando un usuario tiene más de un rol simultáneo (RF-ROL-004).

### Roles con canal móvil (según sección 2.3 del documento)

| Rol | Canal | Notas |
|---|---|---|
| Docente | Móvil | Uso diario, es el actor principal del marcaje |
| Estudiante | Móvil | Mismas pantallas que docente, si el marcaje estudiantil está activo (RF-MAR-012) |
| Administrador institucional | Móvil + Web | En móvil, principalmente para el editor GPS en campo |
| Monitor / Auxiliar | Móvil (opcional) | Apoya el marcaje grupal de estudiantes |
| Coordinador / Decano | Web (por defecto) | Solo aparece en móvil si el usuario combina roles (RF-ROL-004) |

### Matriz pantalla ↔ permiso (derivada de la sección 3.2)

| Pantalla | Permiso requerido | Roles que lo tienen |
|---|---|---|
| Inicio (marcar asistencia) | `marcaje:crear` | Docente, Estudiante |
| Historial de marcajes propios | `marcaje:leer` (alcance propio) | Docente, Estudiante |
| Mi horario | — (lectura propia, sin permiso especial) | Docente, Estudiante |
| Justificaciones (radicar) | `justificacion:crear` | Docente, Estudiante |
| Justificaciones (aprobar) | `justificacion:aprobar` | Coordinador, Admin |
| Espacios (ver jerarquía) | `aula:leer` | Superadmin, Admin |
| Editor GPS (crear/editar geometría) | `aula:editar-geometria` | Superadmin, Admin |
| Marcajes (ajustar/anular) | `marcaje:anular` / `marcaje:ajustar` | Superadmin, Admin, Coordinador (su ámbito) |
| Reportes | `reporte:exportar` | Superadmin, Admin, Coordinador, Auditor |
| Marcaje grupal de estudiantes | `marcaje:crear` (contexto monitor) | Monitor/Auxiliar |

> **Importante para el agente:** esta tabla es la referencia de UX —
> decide qué botón se muestra. La autorización real de cada acción se
> valida siempre en el backend (RF-ROL-003: "El alcance se evalúa en el
> backend, nunca solo en la interfaz"). No se debe implementar ninguna
> lógica de negocio basada en el rol dentro del cliente — el cliente solo
> pregunta "¿tengo este permiso?" y muestra u oculta el botón.

## Paso 2 — Requisitos funcionales

1. Al iniciar sesión, el cliente debe recibir (o consultar) el rol activo
   del usuario y su conjunto de permisos resueltos — no calcularlos a
   partir del nombre del rol.
2. Construir dinámicamente la barra inferior y el drawer filtrando por
   permiso, según la matriz del Paso 1.
3. Si el usuario tiene más de un rol (RF-ROL-004), debe existir un
   selector de "contexto activo" accesible desde el drawer, que al
   cambiar de rol reconstruya la barra inferior y el drawer sin cerrar
   sesión.
4. Cada ítem de navegación debe tener: etiqueta corta, ícono, ruta de
   destino y permiso requerido (o ninguno, si es de acceso libre para
   cualquier usuario autenticado).
5. Los ítems comunes a todos los roles (Perfil, Aviso de privacidad,
   Cerrar sesión) siempre van en el drawer, nunca en la barra inferior.
6. Si una ruta configurada aún no tiene pantalla implementada, el
   sistema debe mostrar un estado vacío informativo en vez de fallar —
   el proyecto está en desarrollo incremental hasta el módulo de
   horarios, y esto se seguirá extendiendo.

## Paso 3 — Requisitos técnicos / restricciones

- La configuración de navegación por rol debe vivir en un único lugar
  (archivo o servicio de configuración), separado de los widgets de UI,
  para que agregar una pantalla nueva no implique tocar la lógica del
  shell de navegación.
- El botón de hamburguesa debe ser el mecanismo nativo de apertura del
  menú lateral del framework usado (no un botón custom que dispare un
  overlay manual).
- La barra inferior no debe superar 4 ítems por rol; si la matriz de
  permisos de un rol arroja más de 4 pantallas de acceso frecuente,
  el agente debe priorizar según frecuencia de uso esperada (ej. para
  Docente: Inicio > Horario > Historial > Justificar) y mover el resto
  al drawer.
- No se debe duplicar la matriz de permisos del backend en el cliente
  como fuente de verdad — el cliente consume el resultado, no lo recalcula.
- Mantener este comportamiento aislado a la aplicación móvil. La consola
  web no usa este patrón de barra inferior + drawer (su navegación es de
  escritorio, con sidebar fijo).

## Paso 4 — Criterios de aceptación

- [ ] Un docente que inicia sesión ve Inicio, Horario, Historial y
      Justificar en la barra inferior, y Perfil/Privacidad/Cerrar sesión
      en el drawer.
- [ ] Un administrador que inicia sesión ve Espacios, Editor GPS y
      Marcajes en la barra inferior (no una redirección directa a una
      sola pantalla), y Solapamientos/Reportes/Perfil en el drawer.
- [ ] Un usuario con dos roles ve un selector de contexto en el drawer y,
      al cambiar de rol, la barra inferior y el drawer se actualizan sin
      relogueo.
- [ ] Ningún ítem de navegación se muestra si el usuario no tiene el
      permiso correspondiente, y ocultar un ítem en el cliente **no** es
      tratado como control de seguridad — toda acción sensible sigue
      validándose en el backend.
- [ ] Agregar una pantalla nueva a un rol existente no requiere modificar
      el widget del shell de navegación, solo el archivo de configuración
      de roles.

## Fuera de alcance de este prompt

- Diseño visual/estético de las pantallas individuales (Inicio, Horario,
  etc.) — este prompt cubre solo la estructura de navegación.
- Lógica de negocio de marcaje, geolocalización o validación de
  polígonos — eso pertenece al backend (RN-001, motor de validación).
- Navegación de la consola web administrativa.
