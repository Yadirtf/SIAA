# Despliegue de pruebas del backend en Render + MongoDB Atlas

Esta guía publica el backend en internet **solo para pruebas**, desde la carpeta
`backend/` de este mismo repositorio (no hace falta un repositorio aparte). La
configuración vive en [`render.yaml`](../../render.yaml), en la raíz.

| Pieza | Dónde | Costo |
|---|---|---|
| API (`siaa-api`) | Render, servicio web | Gratis (se duerme tras 15 min sin uso; la primera petición tarda ~1 min en despertarlo) |
| Worker (`siaa-worker`) | Render, background worker | Plan Starter (de pago, Render no tiene workers gratuitos) |
| Base de datos | MongoDB Atlas M0 | Gratis |

> El worker genera las ausencias automáticas, programa los avisos y anonimiza
> coordenadas antiguas. Sin él el API funciona (login, marcajes, reportes), pero no
> aparecen ausencias automáticas ni avisos. Si no quieres pagar, bórralo del
> Blueprint en el paso 3 y agrégalo después.

## 1. Crear la base de datos en MongoDB Atlas

1. Crea una cuenta en <https://www.mongodb.com/cloud/atlas/register>.
2. **Create a cluster** → plan **M0 (Free)** → proveedor **AWS**, región
   **N. Virginia (us-east-1)** (la misma zona que Render `virginia`).
3. **Database Access** → *Add New Database User* → usuario y contraseña (guárdalos).
   Rol: *Read and write to any database*.
4. **Network Access** → *Add IP Address* → **Allow access from anywhere**
   (`0.0.0.0/0`). Render no tiene IP fija en el plan gratuito.
5. **Connect** → *Drivers* → copia la cadena. Queda así (reemplaza usuario y
   contraseña; si la contraseña tiene símbolos, codifícalos para URL):

   ```
   mongodb+srv://USUARIO:CONTRASEÑA@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority
   ```

No hace falta crear la base ni las colecciones: el API crea la base `siaa_pruebas`,
los índices y los datos iniciales al arrancar.

## 2. Conectar Render con GitHub

1. Crea una cuenta en <https://render.com> entrando con GitHub.
2. Autoriza a Render a leer el repositorio `Yadirtf/SIAA`.

## 3. Crear el Blueprint

1. En Render: **New** → **Blueprint** → elige el repositorio `SIAA`.
2. Rama: **develop**. Render lee `render.yaml` y muestra los dos servicios.
3. Render pide los valores marcados como secretos:

   | Variable | Valor |
   |---|---|
   | `MONGO_URI` | La cadena de Atlas del paso 1.5 |
   | `ADMIN_INICIAL_CORREO` | Tu correo de superadministrador, p. ej. `admin@tu-dominio.com` |
   | `ADMIN_INICIAL_PASSWORD` | Contraseña de **mínimo 12 caracteres** |

4. **Apply**. Render construye la imagen Docker (tarda unos minutos la primera vez).

Variables que el Blueprint ya deja puestas: `APP_ENV=production` (desactiva los
usuarios demo, cuyas contraseñas son públicas en el código), `MONGO_DB=siaa_pruebas`,
`JWT_SECRET` aleatorio compartido por API y worker, `CORS_ALLOWED_ORIGINS=*` y
`WORKER_INTERVALO_MIN=1`. `PORT` lo asigna Render y el API lo lee solo.

Opcionales (se agregan en *Environment* del servicio, todas descritas en
[`backend/.env.example`](../../backend/.env.example)):

- Correo de recuperación de contraseña: `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`,
  `SMTP_PASS`, `SMTP_FROM`, `RECOVERY_URL`. Sin ellas no se envían correos.
- Push de Firebase (solo en el worker): `FCM_PROJECT_ID`, `FCM_CREDENTIALS`.
  Sin ellas los avisos quedan en la bandeja de la app.
- Aviso de privacidad: `INSTITUCION_NOMBRE`, `PRIVACIDAD_CONTACTO`.

## 4. Comprobar que funciona

Render muestra la URL del API, del estilo `https://siaa-api.onrender.com`
(puede llevar un sufijo si el nombre está ocupado). Pruébala en el navegador:

```
https://siaa-api.onrender.com/api/v1/health         → {"status":"ok",...}
https://siaa-api.onrender.com/api/v1/health/ready   → comprueba MongoDB
```

Luego entra con `ADMIN_INICIAL_CORREO` y `ADMIN_INICIAL_PASSWORD` desde la app o
la consola web y crea los usuarios, sedes, bloques y horarios de prueba.

En el servicio `siaa-worker`, la pestaña **Logs** debe mostrar los ciclos del
worker cada minuto.

## 5. Actualizaciones

Cada push a `develop` que toque `backend/` vuelve a desplegar ambos servicios.
Cambios en `web/`, `mobile/` o `docs/` no disparan despliegues.

## Probar la misma imagen en local

```bash
docker build -t siaa-api backend
docker compose up -d          # API, worker, Mongo, MailHog y Mongo Express
```
