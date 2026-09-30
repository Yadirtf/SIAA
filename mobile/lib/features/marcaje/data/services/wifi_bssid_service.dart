// wifi_bssid_service.dart — Lectura del BSSID del WiFi actual para verificación complementaria
// Requiere permiso de ubicación concedido (lo solicita LocationService al capturar GPS)
// y ACCESS_WIFI_STATE en Android.
import 'package:network_info_plus/network_info_plus.dart';
import 'selector_verificacion.dart';

class WifiBssidService {
  final NetworkInfo _networkInfo;

  WifiBssidService({NetworkInfo? networkInfo})
      : _networkInfo = networkInfo ?? NetworkInfo();

  /// BSSID del punto de acceso conectado, o null si no se pudo leer.
  Future<String?> leerBssid() async {
    try {
      final bssid = await _networkInfo.getWifiBSSID();
      return SelectorVerificacion.bssidValido(bssid) ? bssid!.trim() : null;
    } catch (_) {
      return null;
    }
  }
}
