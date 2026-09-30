import 'dart:typed_data';

import 'package:siaa_web/core/network/api_exception.dart';
import 'package:siaa_web/core/network/archivo_binario.dart';
import 'package:siaa_web/features/academico/data/models/academico_models.dart';
import 'package:siaa_web/features/reportes/data/models/filtro_reporte_model.dart';
import 'package:siaa_web/features/reportes/data/models/reporte_cumplimiento_model.dart';
import 'package:siaa_web/features/reportes/domain/reportes_repository.dart';

/// Repositorio en memoria para probar los cubits de reportes.
class FakeReportesRepository implements ReportesRepository {
  ReporteCumplimientoModel reporte = const ReporteCumplimientoModel();
  ApiException? error;
  final List<String> llamadas = [];
  FiltroReporteModel? ultimoFiltro;
  String? nombreServidor;

  @override
  Future<ReporteCumplimientoModel> cumplimiento(FiltroReporteModel f) async {
    llamadas.add('cumplimiento');
    ultimoFiltro = f;
    if (error != null) throw error!;
    return reporte;
  }

  @override
  Future<ArchivoBinario> exportar(FiltroReporteModel f, String formato) async {
    llamadas.add('exportar:$formato');
    if (error != null) throw error!;
    return ArchivoBinario(
      bytes: Uint8List.fromList([80, 75]),
      mime: 'application/octet-stream',
      nombre: nombreServidor,
    );
  }

  @override
  Future<List<PeriodoModel>> periodos() async => const [
    PeriodoModel(
      id: 'p1',
      codigo: '2026-2',
      nombre: 'Periodo 2026-2',
      fechaInicio: '2026-08-01',
      fechaFin: '2026-12-15',
      estado: 'ACTIVO',
    ),
  ];

  @override
  Future<List<FacultadModel>> facultades() async => const [
    FacultadModel(id: 'f1', codigo: 'ING', nombre: 'Ingeniería'),
  ];

  @override
  Future<List<ProgramaModel>> programas({String? facultadId}) async {
    llamadas.add('programas:$facultadId');
    return const [];
  }
}
