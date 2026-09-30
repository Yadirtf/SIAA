import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/mensaje_error.dart';
import '../../../academico/data/models/academico_models.dart';
import '../../domain/reportes_repository.dart';

class CatalogoReporteState extends Equatable {
  final List<PeriodoModel> periodos;
  final List<FacultadModel> facultades;
  final List<ProgramaModel> programas;
  final String? error;

  const CatalogoReporteState({
    this.periodos = const [],
    this.facultades = const [],
    this.programas = const [],
    this.error,
  });

  CatalogoReporteState copyWith({
    List<PeriodoModel>? periodos,
    List<FacultadModel>? facultades,
    List<ProgramaModel>? programas,
    String? error,
  }) => CatalogoReporteState(
    periodos: periodos ?? this.periodos,
    facultades: facultades ?? this.facultades,
    programas: programas ?? this.programas,
    error: error,
  );

  @override
  List<Object?> get props => [periodos, facultades, programas, error];
}

/// Opciones de los filtros del reporte: periodos, facultades y programas.
class CatalogoReporteCubit extends Cubit<CatalogoReporteState> {
  final ReportesRepository _repository;

  CatalogoReporteCubit({required ReportesRepository repository})
    : _repository = repository,
      super(const CatalogoReporteState());

  /// Carga periodos y facultades; un fallo parcial no bloquea el resto.
  Future<void> cargar() async {
    final errores = <String>[];
    Future<List<T>> intentar<T>(Future<List<T>> Function() f) async {
      try {
        return await f();
      } catch (e) {
        errores.add(mensajeDeError(e));
        return <T>[];
      }
    }

    final periodos = await intentar(_repository.periodos);
    final facultades = await intentar(_repository.facultades);
    final programas = await intentar(() => _repository.programas());
    if (isClosed) return;
    emit(
      CatalogoReporteState(
        periodos: periodos,
        facultades: facultades,
        programas: programas,
        error: errores.isEmpty ? null : errores.join(' · '),
      ),
    );
  }

  /// Programas de la facultad elegida (todos si es null).
  Future<void> cargarProgramas(String? facultadId) async {
    try {
      final programas = await _repository.programas(facultadId: facultadId);
      if (!isClosed) emit(state.copyWith(programas: programas));
    } catch (e) {
      if (!isClosed) emit(state.copyWith(error: mensajeDeError(e)));
    }
  }
}
