# Fijación de certificado (certificate pinning) — US-SEG-01 AC-02

La app móvil fija la **clave pública** (SPKI) del certificado TLS del servidor de la API.
Los pines **no están en el código**: se inyectan al compilar.

## Cómo se configura

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.siaa.edu.co/api/v1 \
  --dart-define=SIAA_CERT_PINS=<pin_activo>,<pin_respaldo>
```

- `SIAA_CERT_PINS`: lista separada por comas de SHA-256 en Base64 del SubjectPublicKeyInfo
  (el mismo formato que `pin-sha256` de HPKP; se acepta el prefijo opcional `sha256/`).
- Los pines solo protegen el host de `API_BASE_URL`; cualquier otro host se rechaza
  en el cliente HTTP de la API.
- Incluya **siempre al menos dos pines**: el de la clave en uso y el de una clave de
  respaldo ya generada (guardada fuera de línea). Así se puede rotar el certificado sin
  publicar una versión nueva de la app.

## Cómo calcular un pin

Desde el servidor en producción (clave del certificado hoja):

```bash
openssl s_client -connect api.siaa.edu.co:443 -servername api.siaa.edu.co </dev/null 2>/dev/null \
  | openssl x509 -pubkey -noout \
  | openssl pkey -pubin -outform der \
  | openssl dgst -sha256 -binary \
  | openssl base64
```

Desde un archivo de certificado (`cert.pem`) o de una clave privada de respaldo (`respaldo.key`):

```bash
openssl x509 -in cert.pem -pubkey -noout | openssl pkey -pubin -outform der \
  | openssl dgst -sha256 -binary | openssl base64

openssl pkey -in respaldo.key -pubout -outform der \
  | openssl dgst -sha256 -binary | openssl base64
```

El resultado tiene 44 caracteres y termina en `=`. Las pruebas
`test/core/network/certificate_pinning_test.dart` comprueban que la app calcula exactamente
el mismo valor que estos comandos.

Si el certificado se renueva **conservando la misma clave**, el pin no cambia. Si se
renueva con una clave nueva, primero publique una versión de la app que incluya el pin
nuevo como respaldo.

## Comportamiento según el modo de compilación

| Modo | Sin `SIAA_CERT_PINS` | Con pines válidos |
|---|---|---|
| debug | Sin pinning (permite servidor local por HTTP o autofirmado). | Sin pinning. |
| profile / release | **Falla cerrada**: la app no hace ninguna petición a la API; muestra "No se pudo verificar la identidad del servidor de SIAA" y escribe el motivo en el log (`[SIAA-SEGURIDAD]`). | Pinning obligatorio; un certificado con otra clave se rechaza. |

También se bloquea una compilación release con un pin mal formado o con `API_BASE_URL`
en `http://`. Se eligió fallar cerrado porque un binario de producción sin pinning
quedaría expuesto a interceptación (MITM) sin que nadie lo note; un binario que no
conecta se detecta en la primera prueba de humo.

En web el navegador gestiona TLS y no hay pinning posible.
