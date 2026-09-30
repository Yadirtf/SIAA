// marcajes_admin_state.dart — Estado del listado administrativo de marcajes (US-MAR-09)
import 'package:equatable/equatable.dart';

import '../../../marcaje/domain/models/marcaje_historial_model.dart';
import '../../domain/filtro_marcajes.dart';

enum EstadoMarcajesAdmin { cargando, listo, error }

class MarcajesAdminState extends Equatable {
  final EstadoMarcajesAdmin estado;
  final FiltroMarcajes filtro;
  final List<MarcajeHistorialItem> items;
  final int total;
  final bool hayMas;
  final bool cargandoMas;
  final String? error;

  const MarcajesAdminState({
    this.estado = EstadoMarcajesAdmin.cargando,
    this.filtro = const FiltroMarcajes(),
    this.items = const [],
    this.total = 0,
    this.hayMas = false,
    this.cargandoMas = false,
    this.error,
  });

  MarcajesAdminState copyWith({
    EstadoMarcajesAdmin? estado,
    FiltroMarcajes? filtro,
    List<MarcajeHistorialItem>? items,
    int? total,
    bool? hayMas,
    bool? cargandoMas,
    String? error,
  }) {
    return MarcajesAdminState(
      estado: estado ?? this.estado,
      filtro: filtro ?? this.filtro,
      items: items ?? this.items,
      total: total ?? this.total,
      hayMas: hayMas ?? this.hayMas,
      cargandoMas: cargandoMas ?? this.cargandoMas,
      error: error,
    );
  }

  @override
  List<Object?> get props =>
      [estado, filtro, items, total, hayMas, cargandoMas, error];
}
