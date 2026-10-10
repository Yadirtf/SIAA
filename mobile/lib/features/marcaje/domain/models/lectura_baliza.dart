// lectura_baliza.dart — Anuncios BLE observados y resultado de buscar la baliza del aula
// (US-GEO-13 AC-01/AC-02). Independiente del plugin Bluetooth para poder probarlo.
import 'package:equatable/equatable.dart';

/// Un anuncio BLE recibido durante el escaneo, reducido a lo que interesa.
class AnuncioBle extends Equatable {
  /// Datos de fabricante: clave = ID de compañía (0x004C es Apple / iBeacon).
  final Map<int, List<int>> datosFabricante;

  /// UUID de servicio anunciados, en texto de 128 bits.
  final List<String> uuidsServicio;
  final int rssi;

  const AnuncioBle({
    this.datosFabricante = const {},
    this.uuidsServicio = const [],
    required this.rssi,
  });

  @override
  List<Object?> get props => [datosFabricante, uuidsServicio, rssi];
}

/// Por qué no se obtuvo un UUID de baliza.
enum MotivoSinBaliza {
  sinSoporte,
  bluetoothApagado,
  sinPermiso,
  ubicacionApagada,
  noEncontrada,
}

class LecturaBaliza extends Equatable {
  /// UUID en minúsculas con guiones (8-4-4-4-12), o null si no se encontró.
  final String? uuid;
  final MotivoSinBaliza? motivo;

  const LecturaBaliza.encontrada(String this.uuid) : motivo = null;
  const LecturaBaliza.fallida(MotivoSinBaliza this.motivo) : uuid = null;

  bool get exitosa => uuid != null;

  @override
  List<Object?> get props => [uuid, motivo];
}
