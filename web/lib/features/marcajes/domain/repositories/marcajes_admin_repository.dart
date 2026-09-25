// marcajes_admin_repository.dart — Contrato del repositorio administrativo de marcajes
import '../models/marcaje_admin_model.dart';

abstract class MarcajesAdminRepository {
  Future<MarcajeAdminPageModel> listarMarcajes({
    FiltrosMarcajeAdmin filtros = const FiltrosMarcajeAdmin(),
    int pagina = 1,
    int limite = 20,
  });

  Future<MarcajeAdminModel> ajustarMarcaje({
    required String marcajeId,
    required String accion, // ANULAR | AJUSTAR
    String? nuevoResultado,
    required bool anulado,
    required String motivo,
  });

  Future<MarcajeAdminModel> crearMarcajeManual({
    required String sesionId,
    required String usuarioId,
    required String tipo,
    required String resultado,
    required String motivo,
  });
}
