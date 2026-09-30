import '../../../core/models/pagina.dart';
import '../../../core/network/archivo_binario.dart';
import '../data/models/entrada_auditoria_model.dart';
import '../data/models/filtro_auditoria_model.dart';

/// Contrato de consulta de la bitácora (solo lectura).
abstract class AuditoriaRepository {
  Future<Pagina<EntradaAuditoriaModel>> consultar(FiltroAuditoriaModel filtro);

  Future<ArchivoBinario> exportar(FiltroAuditoriaModel filtro, String formato);
}
