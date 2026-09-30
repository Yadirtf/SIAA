// justificacion_repository.dart — Repositorio de justificaciones del docente (EP-07)
import '../../domain/models/justificacion_model.dart';
import '../../domain/models/soporte_adjunto.dart';
import '../datasources/justificacion_remote_datasource.dart';

class JustificacionRepository {
  final JustificacionRemoteDataSource _remote;

  JustificacionRepository({JustificacionRemoteDataSource? remote})
      : _remote = remote ?? JustificacionRemoteDataSource();

  Future<Justificacion> radicar({
    required String sesionId,
    required String tipo,
    required String descripcion,
    required List<SoporteAdjunto> soportes,
  }) {
    return _remote.radicar(
      sesionId: sesionId,
      tipo: tipo,
      descripcion: descripcion,
      soportes: soportes,
    );
  }

  Future<PaginaJustificaciones> listar({
    String? estado,
    int pagina = 1,
    int limite = 20,
  }) {
    return _remote.listar(estado: estado, pagina: pagina, limite: limite);
  }

  Future<Justificacion> obtener(String id) => _remote.obtener(id);
}
