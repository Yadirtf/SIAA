// bandeja_state.dart — Estado de la bandeja de notificaciones (US-NOT-01/02)
import 'package:equatable/equatable.dart';
import '../../domain/models/notificacion_model.dart';

class BandejaState extends Equatable {
  final bool cargando;
  final List<NotificacionModel> items;
  final String? error;

  const BandejaState({
    this.cargando = false,
    this.items = const [],
    this.error,
  });

  int get noLeidas => items.where((n) => !n.leida).length;

  BandejaState copyWith({
    bool? cargando,
    List<NotificacionModel>? items,
    String? error,
    bool limpiarError = false,
  }) {
    return BandejaState(
      cargando: cargando ?? this.cargando,
      items: items ?? this.items,
      error: limpiarError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [cargando, items, error];
}
