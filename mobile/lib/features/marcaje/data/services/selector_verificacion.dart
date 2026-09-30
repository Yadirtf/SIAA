// selector_verificacion.dart — Elige el testigo de verificación complementaria a enviar (RF-GEO-016)
// Prioridad: WIFI (BSSID leído del dispositivo) y, si no se pudo leer, QR tecleado por el docente.
// BLE aún no está soportado por la app, por lo que nunca se envía.
import '../../domain/models/verificacion_complementaria_model.dart';

class SelectorVerificacion {
  const SelectorVerificacion._();

  // Valores que Android/iOS devuelven cuando no hay permiso o no hay WiFi.
  static const _bssidsInvalidos = {'02:00:00:00:00:00', '00:00:00:00:00:00'};

  static bool bssidValido(String? bssid) {
    if (bssid == null) return false;
    final limpio = bssid.trim().toLowerCase();
    return limpio.isNotEmpty && !_bssidsInvalidos.contains(limpio);
  }

  static bool _admite(List<String> metodos, String metodo) =>
      metodos.any((m) => m.toUpperCase() == metodo);

  /// Hay que leer el BSSID del WiFi actual.
  static bool requiereBssid({
    required bool exigida,
    required List<String> metodos,
  }) =>
      exigida && _admite(metodos, VerificacionComplementariaModel.metodoWifi);

  /// Hay que pedir al docente el código del QR del aula.
  static bool requiereCodigoQr({
    required bool exigida,
    required List<String> metodos,
    String? bssid,
  }) {
    if (!exigida ||
        !_admite(metodos, VerificacionComplementariaModel.metodoQr)) {
      return false;
    }
    return !(requiereBssid(exigida: exigida, metodos: metodos) &&
        bssidValido(bssid));
  }

  /// Testigo a enviar, o null si no se exige o no hay ninguno disponible.
  static VerificacionComplementariaModel? seleccionar({
    required bool exigida,
    required List<String> metodos,
    String? bssid,
    String? codigoQr,
  }) {
    if (!exigida) return null;
    if (_admite(metodos, VerificacionComplementariaModel.metodoWifi) &&
        bssidValido(bssid)) {
      return VerificacionComplementariaModel(
        metodo: VerificacionComplementariaModel.metodoWifi,
        valor: bssid!.trim(),
      );
    }
    final qr = codigoQr?.trim() ?? '';
    if (_admite(metodos, VerificacionComplementariaModel.metodoQr) &&
        qr.isNotEmpty) {
      return VerificacionComplementariaModel(
        metodo: VerificacionComplementariaModel.metodoQr,
        valor: qr,
      );
    }
    return null;
  }
}
