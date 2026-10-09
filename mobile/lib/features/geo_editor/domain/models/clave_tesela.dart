// clave_tesela.dart — Identifica una tesela XYZ de una capa cartográfica (US-GEO-03 AC-04)
import 'package:equatable/equatable.dart';

class ClaveTesela extends Equatable {
  /// Nombre estable de la capa (CapaMapa.name); separa el caché por proveedor.
  final String capa;
  final int z;
  final int x;
  final int y;

  const ClaveTesela({
    required this.capa,
    required this.z,
    required this.x,
    required this.y,
  });

  @override
  List<Object?> get props => [capa, z, x, y];

  @override
  String toString() => '$capa/$z/$x/$y';
}

/// Rectángulo geográfico en grados (sin depender del paquete de mapas).
class AreaGeo extends Equatable {
  final double sur;
  final double oeste;
  final double norte;
  final double este;

  const AreaGeo({
    required this.sur,
    required this.oeste,
    required this.norte,
    required this.este,
  });

  @override
  List<Object?> get props => [sur, oeste, norte, este];
}
