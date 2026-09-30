import 'package:equatable/equatable.dart';

/// Opción genérica de un catálogo (sede, facultad, bloque, aula...) tal como
/// se muestra en un selector: nunca se enseña el [id], solo la [etiqueta].
class OpcionCatalogo extends Equatable {
  final String id;
  final String etiqueta;
  final String? detalle;

  const OpcionCatalogo({
    required this.id,
    required this.etiqueta,
    this.detalle,
  });

  /// Texto sobre el que se filtra localmente.
  String get textoBusqueda => '$etiqueta ${detalle ?? ''}';

  @override
  List<Object?> get props => [id, etiqueta, detalle];
}
