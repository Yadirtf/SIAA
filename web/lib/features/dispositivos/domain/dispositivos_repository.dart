import 'models/dispositivo_model.dart';

/// Contrato del repositorio para gestión administrativa de dispositivos (US-AUT-03).
abstract class DispositivosRepository {
  /// Lista los dispositivos móviles vinculados al usuario indicado (AC-06).
  Future<List<DispositivoModel>> obtenerDispositivosUsuario(String usuarioId);

  /// Aprueba un dispositivo móvil en estado pendiente (AC-03).
  Future<void> aprobarDispositivo(String dispositivoId);

  /// Revoca el acceso de un dispositivo móvil (AC-06).
  Future<void> revocarDispositivo(String dispositivoId, {String? motivo});
}
