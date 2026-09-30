// justificaciones_lista_state.dart — Estado de "Mis justificaciones" (US-JUS-03)
import 'package:equatable/equatable.dart';

import '../../domain/models/catalogo_justificacion.dart';
import '../../domain/models/justificacion_model.dart';

enum CargaLista { inicial, cargando, lista, error }

class JustificacionesListaState extends Equatable {
  final CargaLista carga;
  final List<Justificacion> items;
  final int total;
  final EstadoJustificacion? filtro;
  final bool cargandoMas;
  final String? error;

  const JustificacionesListaState({
    this.carga = CargaLista.inicial,
    this.items = const [],
    this.total = 0,
    this.filtro,
    this.cargandoMas = false,
    this.error,
  });

  bool get hayMas => items.length < total;

  JustificacionesListaState copyWith({
    CargaLista? carga,
    List<Justificacion>? items,
    int? total,
    bool? cargandoMas,
    String? error,
  }) {
    return JustificacionesListaState(
      carga: carga ?? this.carga,
      items: items ?? this.items,
      total: total ?? this.total,
      filtro: filtro,
      cargandoMas: cargandoMas ?? this.cargandoMas,
      error: error,
    );
  }

  @override
  List<Object?> get props => [carga, items, total, filtro, cargandoMas, error];
}
