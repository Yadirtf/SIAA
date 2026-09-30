// reportes_cubit.dart — Consulta del reporte de cumplimiento por periodo o rango (RF-REP-001)
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_error.dart';
import '../../data/reportes_remote_datasource.dart';
import '../../domain/reporte_cumplimiento.dart';

enum EstadoReporte { cargando, listo, error }

class ReportesState extends Equatable {
  final EstadoReporte estado;
  final List<PeriodoOpcion> periodos;

  /// Si hay periodo seleccionado se ignora el rango de fechas.
  final PeriodoOpcion? periodo;
  final DateTime desde;
  final DateTime hasta;
  final ReporteCumplimiento? reporte;
  final String? error;

  const ReportesState({
    this.estado = EstadoReporte.cargando,
    this.periodos = const [],
    this.periodo,
    required this.desde,
    required this.hasta,
    this.reporte,
    this.error,
  });

  /// Mes en curso hasta hoy.
  factory ReportesState.inicial(DateTime hoy) => ReportesState(
        desde: DateTime(hoy.year, hoy.month, 1),
        hasta: DateTime(hoy.year, hoy.month, hoy.day),
      );

  ReportesState copyWith({
    EstadoReporte? estado,
    List<PeriodoOpcion>? periodos,
    PeriodoOpcion? periodo,
    bool sinPeriodo = false,
    DateTime? desde,
    DateTime? hasta,
    ReporteCumplimiento? reporte,
    String? error,
  }) {
    return ReportesState(
      estado: estado ?? this.estado,
      periodos: periodos ?? this.periodos,
      periodo: sinPeriodo ? null : (periodo ?? this.periodo),
      desde: desde ?? this.desde,
      hasta: hasta ?? this.hasta,
      reporte: reporte ?? this.reporte,
      error: error,
    );
  }

  @override
  List<Object?> get props =>
      [estado, periodos, periodo, desde, hasta, reporte, error];
}

class ReportesCubit extends Cubit<ReportesState> {
  final ReportesRemoteDataSource _remote;

  ReportesCubit({ReportesRemoteDataSource? remote, DateTime? hoy})
      : _remote = remote ?? ReportesRemoteDataSource(),
        super(ReportesState.inicial(hoy ?? DateTime.now()));

  Future<void> iniciar() async {
    final periodos = await _remote.periodos();
    emit(state.copyWith(periodos: periodos));
    await consultar();
  }

  Future<void> elegirPeriodo(PeriodoOpcion? periodo) async {
    emit(state.copyWith(periodo: periodo, sinPeriodo: periodo == null));
    await consultar();
  }

  Future<void> elegirRango(DateTime desde, DateTime hasta) async {
    emit(state.copyWith(desde: desde, hasta: hasta, sinPeriodo: true));
    await consultar();
  }

  Future<void> consultar() async {
    emit(state.copyWith(estado: EstadoReporte.cargando));
    try {
      final reporte = await _remote.cumplimiento(
        periodoId: state.periodo?.id,
        desde: state.desde,
        hasta: state.hasta,
      );
      emit(state.copyWith(estado: EstadoReporte.listo, reporte: reporte));
    } catch (e) {
      emit(state.copyWith(
        estado: EstadoReporte.error,
        error: mensajeDeError(e, porDefecto: 'No se pudo generar el reporte.'),
      ));
    }
  }
}
