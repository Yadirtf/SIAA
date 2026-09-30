import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/mensaje_error.dart';
import '../../data/models/politica_privacidad_model.dart';
import '../../data/privacidad_remote_datasource.dart';

class PoliticaPrivacidadState extends Equatable {
  final bool cargando;
  final PoliticaPrivacidadModel? politica;
  final String? error;

  const PoliticaPrivacidadState({
    this.cargando = false,
    this.politica,
    this.error,
  });

  @override
  List<Object?> get props => [cargando, politica, error];
}

/// Carga el aviso de privacidad vigente desde el backend.
class PoliticaPrivacidadCubit extends Cubit<PoliticaPrivacidadState> {
  final PrivacidadRemoteDataSource _dataSource;

  PoliticaPrivacidadCubit({required PrivacidadRemoteDataSource dataSource})
    : _dataSource = dataSource,
      super(const PoliticaPrivacidadState(cargando: true));

  Future<void> cargar() async {
    emit(const PoliticaPrivacidadState(cargando: true));
    try {
      final politica = await _dataSource.obtenerPolitica();
      if (!isClosed) emit(PoliticaPrivacidadState(politica: politica));
    } catch (e) {
      if (!isClosed) emit(PoliticaPrivacidadState(error: mensajeDeError(e)));
    }
  }
}
