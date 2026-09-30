import 'package:equatable/equatable.dart';

import 'geo_models.dart';

/// Espacio físico listo para mostrarse en un selector: código, nombre y
/// ubicación legible (bloque/piso), sin exponer su id interno.
class EspacioOpcion extends Equatable {
  final EspacioModel espacio;
  final String? bloqueNombre;

  const EspacioOpcion({required this.espacio, this.bloqueNombre});

  String get id => espacio.id;
  String get sedeId => espacio.sedeId;

  /// Ubicación legible: "Bloque A, piso 2" (o la torre si no hay bloque).
  String? get ubicacion {
    final partes = <String>[
      if (bloqueNombre != null && bloqueNombre!.isNotEmpty)
        bloqueNombre!
      else if (espacio.torre != null && espacio.torre!.isNotEmpty)
        espacio.torre!,
      if (espacio.piso != null) 'piso ${espacio.piso}',
    ];
    return partes.isEmpty ? null : partes.join(', ');
  }

  /// "A-101 · Aula 101 (Bloque A, piso 1)".
  String get etiqueta {
    final base = [
      espacio.codigo,
      espacio.nombre,
    ].where((t) => t.isNotEmpty).join(' · ');
    final donde = ubicacion;
    return donde == null ? base : '$base ($donde)';
  }

  /// "Aula · Capacidad 40 · En mantenimiento".
  String get detalle => [
    _tipo(espacio.tipo),
    if (espacio.capacidad > 0) 'Capacidad ${espacio.capacidad}',
    if (espacio.estado == 'MANTENIMIENTO') 'En mantenimiento',
  ].where((t) => t.isNotEmpty).join(' · ');

  static String _tipo(String tipo) {
    if (tipo.isEmpty) return '';
    final t = tipo.replaceAll('_', ' ').toLowerCase();
    return t[0].toUpperCase() + t.substring(1);
  }

  @override
  List<Object?> get props => [espacio, bloqueNombre];
}
