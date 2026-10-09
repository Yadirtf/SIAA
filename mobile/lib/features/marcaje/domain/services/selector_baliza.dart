// selector_baliza.dart — Extrae el UUID de baliza de los anuncios BLE (US-GEO-13 AC-01)
// El cliente no conoce el UUID registrado del aula (el servidor solo publica los métodos):
// envía el de la baliza más cercana y el servidor lo compara con el configurado.
import '../models/lectura_baliza.dart';

class SelectorBaliza {
  const SelectorBaliza._();

  static const idApple = 0x004C;
  static const _sufijoBaseBluetooth = '-0000-1000-8000-00805f9b34fb';

  /// UUID de proximidad de un anuncio iBeacon (0x02 0x15 + 16 bytes), o null.
  static String? uuidIBeacon(Map<int, List<int>> datosFabricante) {
    final d = datosFabricante[idApple];
    if (d == null || d.length < 18 || d[0] != 0x02 || d[1] != 0x15) {
      return null;
    }
    return formatearUuid(d.sublist(2, 18));
  }

  static String formatearUuid(List<int> bytes) {
    final hex =
        bytes.map((b) => (b & 0xFF).toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  /// UUID de servicio propio (128 bits); descarta los estándar del Bluetooth SIG,
  /// que anuncian auriculares, relojes, etc. y nunca identifican un aula.
  static String? uuidServicioPropio(String uuid) {
    final u = uuid.trim().toLowerCase();
    final valido = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');
    if (!valido.hasMatch(u) || u.endsWith(_sufijoBaseBluetooth)) return null;
    return u;
  }

  /// Elige el UUID a enviar: el iBeacon de mejor señal; si no hay ninguno (iOS oculta
  /// los iBeacon a CoreBluetooth), el UUID de servicio propio de mejor señal.
  static String? elegir(List<AnuncioBle> anuncios) {
    String? mejorIBeacon, mejorServicio;
    var rssiIBeacon = -1 << 30, rssiServicio = -1 << 30;
    for (final a in anuncios) {
      final ib = uuidIBeacon(a.datosFabricante);
      if (ib != null && a.rssi > rssiIBeacon) {
        mejorIBeacon = ib;
        rssiIBeacon = a.rssi;
      }
      for (final s in a.uuidsServicio) {
        final propio = uuidServicioPropio(s);
        if (propio != null && a.rssi > rssiServicio) {
          mejorServicio = propio;
          rssiServicio = a.rssi;
        }
      }
    }
    return mejorIBeacon ?? mejorServicio;
  }
}
