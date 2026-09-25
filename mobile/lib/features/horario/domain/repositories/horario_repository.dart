// horario_repository.dart - Interfaz de repositorio para Mi Horario (US-ACA-01..09)
import '../../data/models/sesion_horario_model.dart';

abstract class HorarioRepository {
  /// Obtiene las sesiones del usuario para una fecha dada (o semana).
  Future<List<SesionHorarioModel>> obtenerHorario({
    String? docenteId,
    DateTime? fecha,
  });
}
