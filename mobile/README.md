# siaa_mobile

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Compilación release de SIAA

Las compilaciones release exigen los pines del certificado del servidor; sin ellos la app
no hace ninguna petición a la API:

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.siaa.edu.co/api/v1 \
  --dart-define=SIAA_CERT_PINS=<pin_activo>,<pin_respaldo>
```

Cómo calcular los pines con openssl y qué pasa en cada modo:
[docs/certificate-pinning.md](docs/certificate-pinning.md).
