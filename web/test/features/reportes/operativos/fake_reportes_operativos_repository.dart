import 'dart:typed_data';

import 'package:siaa_web/core/network/api_exception.dart';
import 'package:siaa_web/core/network/archivo_binario.dart';
import 'package:siaa_web/features/academico/data/models/academico_models.dart';
import 'package:siaa_web/features/reportes/data/models/asistencia_grupo_model.dart';
import 'package:siaa_web/features/reportes/data/models/ocupacion_model.dart';
import 'package:siaa_web/features/reportes/data/models/tablero_model.dart';
import 'package:siaa_web/features/reportes/domain/reportes_operativos_repository.dart';

/// Repositorio en memoria para probar los reportes operativos.
class FakeReportesOperativosRepository implements ReportesOperativosRepository {
  TableroModel tableroRespuesta = const TableroModel();
  ReporteOcupacionModel ocupacionRespuesta = const ReporteOcupacionModel();
  ReporteAsistenciaGrupoModel asistencia = const ReporteAsistenciaGrupoModel(
    grupoId: 'g1',
  );
  List<GrupoReporteModel> gruposRespuesta = const [
    GrupoReporteModel(grupoId: 'g1', grupo: '01', asignatura: 'Cálculo'),
  ];
  ApiException? error;
  final List<String> llamadas = [];
  FiltroOcupacionModel? ultimoFiltro;

  @override
  Future<TableroModel> tablero() async {
    llamadas.add('tablero');
    if (error != null) throw error!;
    return tableroRespuesta;
  }

  @override
  Future<ReporteOcupacionModel> ocupacion(FiltroOcupacionModel f) async {
    llamadas.add('ocupacion:${f.agrupacion}');
    ultimoFiltro = f;
    if (error != null) throw error!;
    return ocupacionRespuesta;
  }

  @override
  Future<ArchivoBinario> exportarOcupacion(
    FiltroOcupacionModel f,
    String formato,
  ) async {
    llamadas.add('exportar:$formato');
    if (error != null) throw error!;
    return ArchivoBinario(
      bytes: Uint8List.fromList([80, 75]),
      mime: 'application/octet-stream',
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
  Future<List<GrupoReporteModel>> grupos(String periodoId) async {
    llamadas.add('grupos:$periodoId');
    return gruposRespuesta;
  }

  @override
  Future<ReporteAsistenciaGrupoModel> asistenciaGrupo(String grupoId) async {
    llamadas.add('asistencia:$grupoId');
    if (error != null) throw error!;
    return asistencia;
  }
}
