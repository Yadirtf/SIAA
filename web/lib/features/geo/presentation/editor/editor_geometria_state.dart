import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/geo_models.dart';
import '../../domain/geometria_poligono.dart';

/// Modo del editor: dibujar agrega esquinas al final; editar mueve, inserta
/// y elimina vértices de un polígono existente (US-GEO-07).
enum ModoEditor { dibujar, editar }

/// Estado del editor de polígono de un aula.
class EditorGeometriaState extends Equatable {
  /// Vértices `[longitud, latitud]` en orden perimetral.
  final List<List<double>> vertices;

  /// Vértices guardados en el backend al abrir el editor; sirven para saber
  /// si hay cambios sin guardar (US-GEO-07 AC-05).
  final List<List<double>> original;
  final ModoEditor modo;

  /// Vértice seleccionado en modo edición (para eliminarlo).
  final int? seleccionado;
  final bool guardando;
  final String? error;

  /// Aviso de solapamiento que el backend pide confirmar antes de guardar.
  final String? solapamiento;

  /// Espacio devuelto por el backend tras guardar con éxito.
  final EspacioModel? guardado;

  const EditorGeometriaState({
    this.vertices = const [],
    this.original = const [],
    this.modo = ModoEditor.dibujar,
    this.seleccionado,
    this.guardando = false,
    this.error,
    this.solapamiento,
    this.guardado,
  });

  bool get puedeGuardar => vertices.length >= 3 && !guardando && modificado;

  /// Hay cambios respecto de la geometría guardada.
  bool get modificado => !listEquals(
    vertices.map((v) => '${v[0]},${v[1]}').toList(),
    original.map((v) => '${v[0]},${v[1]}').toList(),
  );

  /// Área en vivo con la fórmula geodésica del backend (US-GEO-07 AC-01).
  double get areaM2 => areaGeodesicaM2(vertices);

  /// Con exactamente 3 vértices no se permite eliminar (US-GEO-07 AC-03).
  bool get puedeEliminarVertice => seleccionado != null && vertices.length > 3;

  EditorGeometriaState copyWith({
    List<List<double>>? vertices,
    ModoEditor? modo,
    int? Function()? seleccionado,
    bool? guardando,
    String? error,
    String? solapamiento,
    EspacioModel? guardado,
  }) {
    return EditorGeometriaState(
      vertices: vertices ?? this.vertices,
      original: original,
      modo: modo ?? this.modo,
      seleccionado: seleccionado != null ? seleccionado() : this.seleccionado,
      guardando: guardando ?? this.guardando,
      error: error,
      solapamiento: solapamiento,
      guardado: guardado ?? this.guardado,
    );
  }

  @override
  List<Object?> get props => [
    vertices,
    original,
    modo,
    seleccionado,
    guardando,
    error,
    solapamiento,
    guardado,
  ];
}
