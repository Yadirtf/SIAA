// bandeja_cubit.dart — Bandeja de notificaciones en la app (US-NOT-01/02)
// Funciona aunque no haya FCM: lee GET /me/notificaciones y marca como leídas.
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/notificaciones_remote_datasource.dart';
import '../../domain/models/destino_notificacion.dart';
import '../../domain/models/notificacion_model.dart';
import 'bandeja_state.dart';

class BandejaCubit extends Cubit<BandejaState> {
  final NotificacionesRemoteDataSource _remote;

  BandejaCubit({NotificacionesRemoteDataSource? remote})
      : _remote = remote ?? NotificacionesRemoteDataSource(),
        super(const BandejaState());

  Future<void> cargar() async {
    emit(state.copyWith(cargando: true, limpiarError: true));
    try {
      final items = await _remote.listar();
      emit(state.copyWith(cargando: false, items: items));
    } catch (_) {
      emit(state.copyWith(
        cargando: false,
        error: 'No fue posible cargar sus notificaciones.',
      ));
    }
  }

  /// Marca la notificación como leída y devuelve su destino de navegación.
  Future<DestinoNotificacion?> abrir(NotificacionModel n) async {
    if (!n.leida) {
      emit(state.copyWith(
        items: [
          for (final it in state.items) it.id == n.id ? it.marcarLeida() : it,
        ],
      ));
      try {
        await _remote.marcarLeida(n.id);
      } catch (_) {
        // Se reintentará implícitamente: la próxima carga refleja el estado real.
      }
    }
    return n.destino;
  }

  /// Cierre de sesión: la bandeja es por usuario.
  void reiniciar() => emit(const BandejaState());
}
