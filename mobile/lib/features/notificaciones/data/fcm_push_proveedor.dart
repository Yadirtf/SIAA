// fcm_push_proveedor.dart — Implementación de PushProveedor con Firebase Cloud Messaging (US-NOT-01)
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'firebase_config.dart';
import 'push_proveedor.dart';

class FcmPushProveedor implements PushProveedor {
  final FirebaseMessaging _fcm;

  FcmPushProveedor._(this._fcm);

  /// Inicializa Firebase solo si las dart-defines están presentes.
  /// Devuelve null (push deshabilitado) si faltan o si la inicialización falla.
  static Future<FcmPushProveedor?> inicializar() async {
    final opciones = FirebaseConfig.opciones;
    if (opciones == null) return null;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: opciones);
      }
      return FcmPushProveedor._(FirebaseMessaging.instance);
    } catch (e) {
      debugPrint('[SIAA-PUSH] Firebase no disponible: $e');
      return null;
    }
  }

  static MensajePush _convertir(RemoteMessage m) => MensajePush(
        titulo: m.notification?.title,
        cuerpo: m.notification?.body,
        datos: Map<String, dynamic>.from(m.data),
      );

  @override
  Future<bool> solicitarPermiso() async {
    final r = await _fcm.requestPermission();
    return r.authorizationStatus == AuthorizationStatus.authorized ||
        r.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> obtenerToken() => _fcm.getToken();

  @override
  Stream<String> get tokenRenovado => _fcm.onTokenRefresh;

  @override
  Future<void> eliminarTokenLocal() => _fcm.deleteToken();

  @override
  Stream<MensajePush> get mensajesPrimerPlano =>
      FirebaseMessaging.onMessage.map(_convertir);

  @override
  Stream<MensajePush> get aperturas =>
      FirebaseMessaging.onMessageOpenedApp.map(_convertir);

  @override
  Future<MensajePush?> aperturaInicial() async {
    final m = await _fcm.getInitialMessage();
    return m == null ? null : _convertir(m);
  }
}
