import '../../../core/network/archivo_binario.dart';
import '../../academico/data/models/academico_models.dart';
import '../data/models/filtro_reporte_model.dart';
import '../data/models/reporte_cumplimiento_model.dart';

/// Contrato de los reportes de cumplimiento (EP-08).
abstract class ReportesRepository {
  Future<ReporteCumplimientoModel> cumplimiento(FiltroReporteModel filtro);

  /// Archivo `xlsx` o `pdf` con el mismo filtro del reporte.
  Future<ArchivoBinario> exportar(FiltroReporteModel filtro, String formato);

  Future<List<PeriodoModel>> periodos();

  Future<List<FacultadModel>> facultades();

  Future<List<ProgramaModel>> programas({String? facultadId});
}
