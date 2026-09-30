import 'models/parametro_model.dart';

/// Contrato del repositorio de parametrización para mobile.
/// US-PAR-03: visualización del parámetro efectivo y su origen.
/// En mobile solo se requiere lectura (diagnóstico). La edición es responsabilidad de la consola web.
abstract class ParametrosRepository {
  /// Obtiene los parámetros efectivos resueltos para el ámbito indicado.
  /// [sedeId], [facultadId], [bloqueId], [espacioId], [asignacionId] son opcionales.
  Future<ParametrosSnapshot> obtenerEfectivos({
    String? sedeId,
    String? facultadId,
    String? bloqueId,
    String? espacioId,
    String? asignacionId,
  });

  /// Obtiene los parámetros globales (sin override).
  Future<ParametrosSnapshot> obtenerGlobales();
}
