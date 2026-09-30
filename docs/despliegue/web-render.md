# Despliegue de pruebas de la consola web en Render

La consola web es Flutter Web compilado a WebAssembly (SRS §5.2). Se publica como
**Static Site** de Render desde la carpeta `web/`, con la configuración del
servicio `siaa-web` en [`render.yaml`](../../render.yaml). Es gratis y, a
diferencia del API, no se duerme.

| Pieza | Valor |
|---|---|
| Servicio | `siaa-web` (Static Site) |
| URL esperada | `https://siaa-web.onrender.com` (Render añade un sufijo si el nombre está ocupado) |
| API al que apunta | `API_BASE_URL=https://siaa-api.onrender.com/api/v1` |
| Flutter usado en el build | 3.47.5 (el build lo descarga; Render no lo trae) |

## 1. Crear el sitio

1. En Render abre el Blueprint de SIAA (el mismo del backend, ver
   [backend-render.md](backend-render.md)).
2. Pulsa **Manual Sync**. Render lee `render.yaml` y agrega `siaa-web`.
3. Espera el primer build: descargar Flutter y compilar tarda varios minutos.
   En **Logs** debe terminar con `✓ Built build/web`.

No hay que escribir ninguna variable: `API_BASE_URL` ya viene en el Blueprint.
Si tu API tiene otra URL, cámbiala en `render.yaml` (o en *Environment* del
sitio) y vuelve a desplegar: la URL queda compilada dentro de la web.

## 2. Comprobar

1. Abre `https://siaa-web.onrender.com`. Debe aparecer el login "SIAA Portal".
2. Entra con `ADMIN_INICIAL_CORREO` y `ADMIN_INICIAL_PASSWORD`.
3. Abajo a la izquierda debe decir **Backend Conectado**.

Si el login tarda cerca de un minuto la primera vez, es el API del plan gratuito
despertando; no es un error de la web.

## 3. Si Render le pone otro nombre al sitio

Si la URL real no es `https://siaa-web.onrender.com`, cambia en `render.yaml` el
valor de `RECOVERY_URL` del servicio `siaa-api` por la URL real. Es el enlace que
llega en los correos de recuperación de contraseña.

## Qué configura el Blueprint y por qué

- **`--wasm`**: compila a WebAssembly y además a JavaScript. Los navegadores sin
  WasmGC (Safari antiguo, todo iOS) usan la copia en JavaScript sin hacer nada.
- **`--no-web-resources-cdn`**: el motor de dibujo se sirve desde el propio sitio
  y no desde un CDN de Google, para que funcione con el aislamiento de origen.
- **`Cross-Origin-Opener-Policy` y `Cross-Origin-Embedder-Policy`**: activan el
  renderizado multihilo de WebAssembly. Sin ellos la web funciona, pero más lenta.
- **`Cache-Control: no-cache`** en los archivos de arranque, para que cada
  despliegue se vea sin borrar la caché del navegador.
- **Rewrite `/*` → `/index.html`**: cualquier ruta abre la aplicación.
- **`CORS_ALLOWED_ORIGINS=*`** en el API: deja entrar a la web. Para producción
  se reemplaza por la URL exacta de la consola.

## Actualizaciones

Cada push a `develop` que toque `web/` vuelve a compilar y publicar la consola.

## Compilar igual en local

```bash
cd web
flutter build web --wasm --release --no-web-resources-cdn \
  --dart-define=API_BASE_URL=https://siaa-api.onrender.com/api/v1
# resultado en web/build/web
```
