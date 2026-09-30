// horario_repository.dart - Interfaz de repositorio para Mi Horario (US-ACA-01..09)
import '../../data/models/sesion_horario_model.dart';

abstract class HorarioRepository {
  /// Sesiones de lunes a sábado de la semana que inicia en [lunes], agrupadas por día
  /// (clave = fecha a medianoche) y ordenadas por hora de inicio.
  Future<Map<DateTime, List<SesionHorarioModel>>> obtenerSemana({
    required DateTime lunes,
    String? docenteId,
  });
}
