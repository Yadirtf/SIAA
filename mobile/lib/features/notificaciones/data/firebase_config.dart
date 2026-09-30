// firebase_config.dart — Opciones de Firebase desde --dart-define (US-NOT-01)
// No se usa google-services.json: si falta alguna variable, el push queda deshabilitado
// y la bandeja en la app sigue funcionando.
import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  FirebaseConfig._();

  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _senderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');

  /// Opciones construidas a partir de los valores dados; null si alguno falta.
  static FirebaseOptions? desde({
    required String apiKey,
    required String appId,
    required String messagingSenderId,
    required String projectId,
  }) {
    final valores = [apiKey, appId, messagingSenderId, projectId];
    if (valores.any((v) => v.trim().isEmpty)) return null;
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
    );
  }

  /// Opciones del build actual (dart-defines); null si el push no está configurado.
  static FirebaseOptions? get opciones => desde(
        apiKey: _apiKey,
        appId: _appId,
        messagingSenderId: _senderId,
        projectId: _projectId,
      );
}
