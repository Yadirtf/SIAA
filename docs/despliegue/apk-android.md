# Generar la app Android (APK) e instalarla en tu celular

La app lee la dirección del backend al compilar, con `--dart-define`. Por eso el APK
se genera **después** de tener la URL del API desplegado
([guía del backend](backend-render.md)).

> Android nunca se ha compilado en el entorno de desarrollo del asistente: esta es
> la primera compilación y puede pedir instalar componentes del SDK. Si falla,
> copia el error completo y lo revisamos.

## Requisitos en tu computador

1. **Flutter** 3.22 o superior: `flutter --version`.
2. **Android Studio** con el Android SDK. En *SDK Manager* instala:
   - *SDK Platforms*: **Android API 37** (el proyecto usa `compileSdk = 37`).
   - *SDK Tools*: *Android SDK Build-Tools*, *Command-line Tools* y *Platform-Tools*.
3. **JDK 17** (Android Studio ya trae uno).
4. Comprueba todo con `flutter doctor` y acepta las licencias con
   `flutter doctor --android-licenses`.

`mobile/android/local.properties` ya no está en el repositorio: Flutter lo crea
solo con las rutas de tu SDK la primera vez que compilas.

## Compilar el APK de pruebas

Desde la carpeta `mobile/` (reemplaza la URL por la que te dio Render y conserva
`/api/v1` al final):

```bash
cd mobile
flutter pub get
flutter build apk --debug --dart-define=API_BASE_URL=https://siaa-api.onrender.com/api/v1
```

El APK queda en `mobile/build/app/outputs/flutter-apk/app-debug.apk`.

Si compilas sin `--dart-define=API_BASE_URL` (por ejemplo con el botón *Run* del
IDE), la app usa `https://siaa-api.onrender.com/api/v1` por defecto. El APK que
publica el CI (artefacto `siaa-mobile-apk`) también apunta ahí; para cambiarlo,
define la variable de repositorio `API_BASE_URL` en GitHub. Nunca uses `localhost`
en un celular: ahí `localhost` es el propio teléfono y la app mostrará "No se pudo
conectar al servidor". Para probar contra tu backend local desde el celular usa la
IP de tu computador en la red WiFi (`http://192.168.x.x:8080/api/v1`) o, en el
emulador de Android, `http://10.0.2.2:8080/api/v1`.

### ¿Por qué `--debug` y no `--release`?

La app trae *certificate pinning* (US-PLT-03): en modo release solo acepta el
certificado de `api.siaa.edu.co` con huellas SHA-256 fijas en
`mobile/lib/core/network/certificate_pinning.dart`, y esas huellas todavía son de
ejemplo. Un APK release rechazaría el certificado de Render y ninguna petición
funcionaría. En modo debug el pinning se omite a propósito, así que el APK debug es
el que sirve para probar contra Render. Es más pesado y algo más lento, pero la
funcionalidad es la misma.

Para un APK release hace falta configurar el host y las huellas reales del
servidor definitivo (o permitir configurarlos al compilar).

### Variables opcionales

Se agregan al mismo comando, cada una con su `--dart-define=CLAVE=valor`:

- Notificaciones push: `FIREBASE_API_KEY`, `FIREBASE_APP_ID`,
  `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_PROJECT_ID`.
- Play Integrity: `PLAY_INTEGRITY_CLOUD_PROJECT`. Solo es necesario si activas el
  parámetro `exigir_attestation` (viene desactivado).

## Instalar en el celular

**Opción A — cable USB (recomendada)**

1. En el celular: *Ajustes → Acerca del teléfono* → toca 7 veces *Número de
   compilación* para activar las opciones de desarrollador.
2. *Opciones de desarrollador* → activa **Depuración por USB**.
3. Conecta el celular, acepta el aviso de confianza y ejecuta:

   ```bash
   adb install -r build/app/outputs/flutter-apk/app-debug.apk
   ```

   (O directamente `flutter install --debug` con el celular conectado.)

**Opción B — pasar el archivo**

1. Copia `app-debug.apk` al celular (Drive, WhatsApp, cable).
2. Ábrelo desde el administrador de archivos y permite **instalar apps de fuentes
   desconocidas** cuando Android lo pida.

## Al abrir la app

- Acepta el permiso de **ubicación precisa**: el marcaje depende del GPS.
- Si el backend de Render estaba dormido, el primer inicio de sesión puede fallar
  por tiempo de espera (la app espera 15 s para conectar). Abre antes
  `…/api/v1/health` en el navegador del celular para despertarlo y vuelve a intentar.
- Para marcar asistencia necesitas en el backend: una sede con bloque y
  coordenadas reales cerca de donde estés, una asignatura, un grupo, un horario
  activo a la hora de la prueba y tu usuario inscrito.
