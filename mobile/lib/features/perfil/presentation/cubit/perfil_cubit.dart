// perfil_cubit.dart — Perfil desde GET /me/perfil con respaldo en los datos de la sesión
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_error.dart';
import '../../data/perfil_remote_datasource.dart';
import '../../domain/perfil_model.dart';

class PerfilState extends Equatable {
  final bool cargando;
  final PerfilModel perfil;

  /// ID de instalación de esta app (para marcar "Este dispositivo").
  final String? instalacionActual;

  /// Aviso cuando se muestran los datos de la sesión en lugar de los del servidor.
  final String? aviso;

  const PerfilState({
    required this.perfil,
    this.cargando = true,
    this.instalacionActual,
    this.aviso,
  });

  @override
  List<Object?> get props => [cargando, perfil, instalacionActual, aviso];
}

class PerfilCubit extends Cubit<PerfilState> {
  final PerfilRemoteDataSource _remote;
  final Future<String> Function() _instalacionId;

  PerfilCubit({
    required PerfilModel desdeSesion,
    required Future<String> Function() instalacionId,
    PerfilRemoteDataSource? remote,
  })  : _remote = remote ?? PerfilRemoteDataSource(),
        _instalacionId = instalacionId,
        super(PerfilState(perfil: desdeSesion));

  Future<void> cargar() async {
    String? instalacion;
    try {
      instalacion = await _instalacionId();
    } catch (_) {}
    emit(PerfilState(
        perfil: state.perfil, instalacionActual: instalacion, cargando: true));
    try {
      final perfil = await _remote.obtener();
      emit(PerfilState(
        perfil: perfil ?? state.perfil,
        instalacionActual: instalacion,
        cargando: false,
        aviso: perfil == null
            ? 'El servidor no informa los dispositivos vinculados; se muestran los datos de la sesión.'
            : null,
      ));
    } catch (e) {
      emit(PerfilState(
        perfil: state.perfil,
        instalacionActual: instalacion,
        cargando: false,
        aviso: 'Se muestran los datos de la sesión. ${mensajeDeError(e)}',
      ));
    }
  }
}
