import 'models/parametro_model.dart';

/// Contrato del repositorio de parametrización para la consola web.
/// US-PAR-01: guardar parámetros por ámbito.
/// US-PAR-03: consultar parámetros efectivos con origen.
abstract class ParametrosRepository {
  /// Obtiene los parámetros efectivos resueltos para el ámbito indicado.
  Future<ParametrosSnapshot> obtenerEfectivos({
    String? sedeId,
    String? facultadId,
    String? bloqueId,
    String? espacioId,
    String? asignacionId,
  });

  /// Inserta o actualiza un parámetro para el ámbito indicado (US-PAR-01 AC-03).
  Future<void> guardarParametro(GuardarParametroRequest request);
}
