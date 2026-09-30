// solapamientos_cubit.dart — Informe de aulas con polígonos superpuestos (US-GEO-05)
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_error.dart';
import '../../../geo_editor/data/espacio_repository.dart';
import '../../data/solapamientos_remote_datasource.dart';
import '../../domain/solapamiento_model.dart';

enum EstadoSolapamientos { cargando, listo, error }

class SolapamientosState extends Equatable {
  final EstadoSolapamientos estado;
  final List<SolapamientoModel> conflictos;

  /// Nombre de cada sede por id (para no mostrar identificadores).
  final Map<String, String> sedes;
  final String? error;

  const SolapamientosState({
    this.estado = EstadoSolapamientos.cargando,
    this.conflictos = const [],
    this.sedes = const {},
    this.error,
  });

  String nombreSede(String id) => sedes[id] ?? 'Sede';

  @override
  List<Object?> get props => [estado, conflictos, sedes, error];
}

class SolapamientosCubit extends Cubit<SolapamientosState> {
  final SolapamientosRemoteDataSource _remote;
  final EspacioRepository _espacios;

  SolapamientosCubit({
    SolapamientosRemoteDataSource? remote,
    EspacioRepository? espacios,
  })  : _remote = remote ?? SolapamientosRemoteDataSource(),
        _espacios = espacios ?? EspacioRepository(),
        super(const SolapamientosState());

  Future<void> cargar() async {
    emit(const SolapamientosState());
    try {
      final conflictos = await _remote.informe();
      final criticosPrimero = [...conflictos]..sort((a, b) {
          if (a.esCritico != b.esCritico) return a.esCritico ? -1 : 1;
          return b.porcentajeSolapado.compareTo(a.porcentajeSolapado);
        });
      emit(SolapamientosState(
        estado: EstadoSolapamientos.listo,
        conflictos: criticosPrimero,
        sedes: await _nombresSedes(),
      ));
    } catch (e) {
      emit(SolapamientosState(
        estado: EstadoSolapamientos.error,
        error: mensajeDeError(e,
            porDefecto: 'No se pudo consultar el informe de solapamientos.'),
      ));
    }
  }

  Future<Map<String, String>> _nombresSedes() async {
    try {
      final sedes = await _espacios.obtenerSedes();
      return {
        for (final s in sedes) s.id: s.nombre.isNotEmpty ? s.nombre : s.codigo
      };
    } catch (_) {
      return const {};
    }
  }
}
