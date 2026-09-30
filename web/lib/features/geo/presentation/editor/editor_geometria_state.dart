import 'package:equatable/equatable.dart';

import '../../data/models/geo_models.dart';

/// Estado del editor de polígono de un aula.
class EditorGeometriaState extends Equatable {
  /// Vértices `[longitud, latitud]` en el orden en que se tocaron.
  final List<List<double>> vertices;
  final bool guardando;
  final String? error;

  /// Aviso de solapamiento que el backend pide confirmar antes de guardar.
  final String? solapamiento;

  /// Espacio devuelto por el backend tras guardar con éxito.
  final EspacioModel? guardado;

  const EditorGeometriaState({
    this.vertices = const [],
    this.guardando = false,
    this.error,
    this.solapamiento,
    this.guardado,
  });

  bool get puedeGuardar => vertices.length >= 3 && !guardando;

  EditorGeometriaState copyWith({
    List<List<double>>? vertices,
    bool? guardando,
    String? error,
    String? solapamiento,
    EspacioModel? guardado,
  }) {
    return EditorGeometriaState(
      vertices: vertices ?? this.vertices,
      guardando: guardando ?? this.guardando,
      error: error,
      solapamiento: solapamiento,
      guardado: guardado ?? this.guardado,
    );
  }

  @override
  List<Object?> get props => [
    vertices,
    guardando,
    error,
    solapamiento,
    guardado,
  ];
}
