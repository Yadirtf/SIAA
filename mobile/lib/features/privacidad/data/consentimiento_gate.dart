// consentimiento_gate.dart — Compuerta local del consentimiento informado (US-LEG-01, CA-011)
// Única fuente que consultan los servicios de ubicación y la sincronización antes de
// pedir permisos o enviar marcajes. El backend sigue siendo la autoridad (403).
import 'package:flutter/foundation.dart';
import '../../../core/storage/secure_storage.dart';
import '../domain/models/estado_consentimiento.dart';

enum EstadoGateConsentimiento {
  /// Aún no se ha consultado al servidor ni hay aceptación guardada.
  desconocido,
  otorgado,

  /// Sin decisión sobre la versión vigente: hay que mostrar el aviso.
  pendiente,

  /// El usuario no aceptó la versión vigente.
  rechazado,
}

class ConsentimientoGate {
  static final instance = ConsentimientoGate();

  final Future<String?> Function() _leerVersion;
  final Future<void> Function(String? version) _guardarVersion;
  final ValueNotifier<EstadoGateConsentimiento> _estado =
      ValueNotifier(EstadoGateConsentimiento.desconocido);

  ConsentimientoGate({
    Future<String?> Function()? leerVersion,
    Future<void> Function(String? version)? guardarVersion,
  })  : _leerVersion = leerVersion ?? SecureStorage.getConsentimientoVersion,
        _guardarVersion = guardarVersion ?? _persistir;

  static Future<void> _persistir(String? version) => version == null
      ? SecureStorage.clearConsentimiento()
      : SecureStorage.saveConsentimiento(version);

  EstadoGateConsentimiento get estado => _estado.value;

  /// Notifica cada cambio de estado (p. ej. para recargar la pantalla de marcaje).
  ValueListenable<EstadoGateConsentimiento> get cambios => _estado;

  /// Solo con aceptación vigente se puede solicitar el permiso de ubicación.
  bool get permiteUbicacion => estado == EstadoGateConsentimiento.otorgado;

  /// La cola offline no se envía si se sabe que el servidor la rechazaría.
  bool get permiteSincronizar =>
      estado != EstadoGateConsentimiento.pendiente &&
      estado != EstadoGateConsentimiento.rechazado;

  /// Al arrancar sin red: una aceptación guardada habilita el marcaje offline
  /// hasta que el servidor confirme o invalide la versión.
  Future<void> restaurar() async {
    if (estado != EstadoGateConsentimiento.desconocido) return;
    final version = await _leerVersion();
    if (version != null && version.isNotEmpty) {
      _estado.value = EstadoGateConsentimiento.otorgado;
    }
  }

  /// Aplica la respuesta de GET/POST /me/consentimiento.
  Future<void> aplicar(EstadoConsentimiento c) async {
    if (c.otorgado) {
      _estado.value = EstadoGateConsentimiento.otorgado;
      await _guardarVersion(c.versionVigente);
      return;
    }
    _estado.value = c.rechazadoVigente
        ? EstadoGateConsentimiento.rechazado
        : EstadoGateConsentimiento.pendiente;
    await _guardarVersion(null);
  }

  /// El servidor respondió 403 CONSENTIMIENTO_REQUERIDO.
  Future<void> marcarRequerido() async {
    if (estado != EstadoGateConsentimiento.rechazado) {
      _estado.value = EstadoGateConsentimiento.pendiente;
    }
    await _guardarVersion(null);
  }

  /// Cierre de sesión: la decisión es por usuario, no por dispositivo.
  Future<void> reiniciar() async {
    _estado.value = EstadoGateConsentimiento.desconocido;
    await _guardarVersion(null);
  }
}
