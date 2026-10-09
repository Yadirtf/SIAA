import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/mensaje_error.dart';
import '../../data/derechos_remote_datasource.dart';
import '../../data/models/solicitud_derecho_model.dart';

/// Estado de la bandeja de solicitudes de titulares.
class SolicitudesDerechosState {
  final bool cargando;
  final bool soloAbiertas;
  final List<SolicitudDerechoModel> solicitudes;
  final String? error;
  final String? mensaje;

  const SolicitudesDerechosState({
    this.cargando = false,
    this.soloAbiertas = true,
    this.solicitudes = const [],
    this.error,
    this.mensaje,
  });
}

/// Atiende las solicitudes de copia, rectificación y supresión (US-LEG-02 AC-02, AC-03).
class SolicitudesDerechosCubit extends Cubit<SolicitudesDerechosState> {
  final DerechosRemoteDataSource _remote;

  SolicitudesDerechosCubit({DerechosRemoteDataSource? remote})
    : _remote = remote ?? DerechosRemoteDataSource(),
      super(const SolicitudesDerechosState());

  Future<void> cargar({bool? soloAbiertas}) async {
    final abiertas = soloAbiertas ?? state.soloAbiertas;
    emit(
      SolicitudesDerechosState(
        cargando: true,
        soloAbiertas: abiertas,
        solicitudes: state.solicitudes,
      ),
    );
    try {
      final lista = await _remote.listar(soloAbiertas: abiertas);
      emit(
        SolicitudesDerechosState(soloAbiertas: abiertas, solicitudes: lista),
      );
    } catch (e) {
      emit(
        SolicitudesDerechosState(
          soloAbiertas: abiertas,
          solicitudes: state.solicitudes,
          error: mensajeDeError(e),
        ),
      );
    }
  }

  Future<void> asumir(String id) =>
      _operar(() => _remote.asumir(id), 'Solicitud asumida: queda a su cargo.');

  Future<void> resolver(
    String id, {
    required bool atendida,
    required String respuesta,
  }) => _operar(
    () => _remote.resolver(id, atendida: atendida, respuesta: respuesta),
    atendida
        ? 'Solicitud atendida y aplicada; el titular fue notificado.'
        : 'Solicitud denegada; el titular fue notificado.',
  );

  Future<void> _operar(Future<void> Function() accion, String exito) async {
    try {
      await accion();
      await cargar();
      emit(
        SolicitudesDerechosState(
          soloAbiertas: state.soloAbiertas,
          solicitudes: state.solicitudes,
          mensaje: exito,
        ),
      );
    } catch (e) {
      emit(
        SolicitudesDerechosState(
          soloAbiertas: state.soloAbiertas,
          solicitudes: state.solicitudes,
          error: mensajeDeError(e),
        ),
      );
    }
  }
}
