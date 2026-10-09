// escaner_ble.dart — Contrato del escaneo BLE en primer plano (US-GEO-13)
// Aísla el plugin Bluetooth para que la lógica y las pantallas se prueben con dobles.
import '../../domain/models/lectura_baliza.dart';

abstract class EscanerBle {
  /// Escanea durante como máximo [duracion] y devuelve los anuncios observados.
  /// Lanza [FallaEscanerBle] si el dispositivo no puede escanear.
  Future<List<AnuncioBle>> escanear(Duration duracion);
}

class FallaEscanerBle implements Exception {
  final MotivoSinBaliza motivo;

  const FallaEscanerBle(this.motivo);

  @override
  String toString() => 'FallaEscanerBle($motivo)';
}
