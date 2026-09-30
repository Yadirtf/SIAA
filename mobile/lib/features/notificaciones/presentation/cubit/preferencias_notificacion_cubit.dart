// preferencias_notificacion_cubit.dart — Preferencias por tipo de notificación (US-NOT-02)
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/notificaciones_remote_datasource.dart';
import '../../domain/models/preferencias_notificacion.dart';

class PreferenciasNotificacionState extends Equatable {
  final bool cargando;
  final bool guardando;
  final PreferenciasNotificacion? preferencias;
  final String? error;

  const PreferenciasNotificacionState({
    this.cargando = false,
    this.guardando = false,
    this.preferencias,
    this.error,
  });

  @override
  List<Object?> get props => [cargando, guardando, preferencias, error];
}

class PreferenciasNotificacionCubit
    extends Cubit<PreferenciasNotificacionState> {
  final NotificacionesRemoteDataSource _remote;

  PreferenciasNotificacionCubit({NotificacionesRemoteDataSource? remote})
      : _remote = remote ?? NotificacionesRemoteDataSource(),
        super(const PreferenciasNotificacionState());

  Future<void> cargar() async {
    emit(const PreferenciasNotificacionState(cargando: true));
    try {
      final p = await _remote.obtenerPreferencias();
      emit(PreferenciasNotificacionState(preferencias: p));
    } catch (_) {
      emit(const PreferenciasNotificacionState(
        error: 'No fue posible cargar sus preferencias.',
      ));
    }
  }

  /// Cambia una preferencia y la guarda; las obligatorias se ignoran.
  Future<void> cambiar(String clave, bool activo) async {
    final actual = state.preferencias;
    if (actual == null || actual.esObligatoria(clave) || state.guardando) {
      return;
    }
    final nueva = actual.con(clave, activo);
    emit(PreferenciasNotificacionState(preferencias: nueva, guardando: true));
    try {
      final guardada = await _remote.guardarPreferencias(nueva);
      emit(PreferenciasNotificacionState(preferencias: guardada));
    } catch (_) {
      emit(PreferenciasNotificacionState(
        preferencias: actual,
        error: 'No se pudo guardar el cambio. Inténtelo de nuevo.',
      ));
    }
  }
}
