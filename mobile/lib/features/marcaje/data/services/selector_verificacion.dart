// selector_verificacion.dart — Elige el testigo de verificación complementaria a enviar (RF-GEO-016)
// Prioridad: WIFI (BSSID leído del dispositivo), BLE (UUID de la baliza detectada) y,
// si ninguno se pudo obtener, QR escaneado (o tecleado) por el docente.
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

  static bool _valido(String? valor) => (valor?.trim() ?? '').isNotEmpty;

  static bool _admite(List<String> metodos, String metodo) =>
      metodos.any((m) => m.toUpperCase() == metodo);

  /// Hay que leer el BSSID del WiFi actual.
  static bool requiereBssid({
    required bool exigida,
    required List<String> metodos,
  }) =>
      exigida && _admite(metodos, VerificacionComplementariaModel.metodoWifi);

  /// Hay que buscar la baliza BLE: el aula la admite y el WiFi no resolvió.
  static bool requiereBle({
    required bool exigida,
    required List<String> metodos,
    String? bssid,
  }) {
    if (!exigida ||
        !_admite(metodos, VerificacionComplementariaModel.metodoBle)) {
      return false;
    }
    return !(requiereBssid(exigida: exigida, metodos: metodos) &&
        bssidValido(bssid));
  }

  /// Hay que pedir al docente el código del QR del aula.
  static bool requiereCodigoQr({
    required bool exigida,
    required List<String> metodos,
    String? bssid,
    String? uuidBle,
  }) {
    if (!exigida ||
        !_admite(metodos, VerificacionComplementariaModel.metodoQr)) {
      return false;
    }
    final wifiOk =
        requiereBssid(exigida: exigida, metodos: metodos) && bssidValido(bssid);
    final bleOk = _admite(metodos, VerificacionComplementariaModel.metodoBle) &&
        _valido(uuidBle);
    return !wifiOk && !bleOk;
  }

  /// Testigo a enviar, o null si no se exige o no hay ninguno disponible.
  static VerificacionComplementariaModel? seleccionar({
    required bool exigida,
    required List<String> metodos,
    String? bssid,
    String? uuidBle,
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
    if (_admite(metodos, VerificacionComplementariaModel.metodoBle) &&
        _valido(uuidBle)) {
      return VerificacionComplementariaModel(
        metodo: VerificacionComplementariaModel.metodoBle,
        valor: uuidBle!.trim().toLowerCase(),
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
