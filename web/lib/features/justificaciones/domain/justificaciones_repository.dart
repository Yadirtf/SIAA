import '../../../core/models/pagina.dart';
import '../../../core/network/archivo_binario.dart';
import '../data/models/justificacion_model.dart';
import '../data/models/justificaciones_filtro.dart';

/// Contrato de la bandeja de revisión de justificaciones (US-JUS-02/03).
abstract class JustificacionesRepository {
  Future<Pagina<JustificacionModel>> listar(JustificacionesFiltro filtro);

  Future<JustificacionModel> obtener(String id);

  /// Cambia el estado a EN_REVISION, APROBADA o RECHAZADA.
  Future<JustificacionModel> revisar(
    String id, {
    required String estado,
    String? observaciones,
  });

  Future<ArchivoBinario> descargarSoporte(String id, String soporteId);

  /// Nombre del usuario, o null si no puede resolverse (p. ej. 403).
  Future<String?> nombreUsuario(String id);
}
