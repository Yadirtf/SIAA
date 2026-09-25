// marcajes_admin_repository_impl.dart — Implementación del repositorio administrativo de marcajes
import '../../domain/models/marcaje_admin_model.dart';
import '../../domain/repositories/marcajes_admin_repository.dart';
import '../datasources/marcajes_admin_remote_datasource.dart';

class MarcajesAdminRepositoryImpl implements MarcajesAdminRepository {
  final MarcajesAdminRemoteDataSource _remoteDataSource;

  MarcajesAdminRepositoryImpl({MarcajesAdminRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? MarcajesAdminRemoteDataSource();

  @override
  Future<MarcajeAdminPageModel> listarMarcajes({
    FiltrosMarcajeAdmin filtros = const FiltrosMarcajeAdmin(),
    int pagina = 1,
    int limite = 20,
  }) {
    return _remoteDataSource.listarMarcajes(
      filtros: filtros,
      pagina: pagina,
      limite: limite,
    );
  }

  @override
  Future<MarcajeAdminModel> ajustarMarcaje({
    required String marcajeId,
    required String accion,
    String? nuevoResultado,
    required bool anulado,
    required String motivo,
  }) {
    return _remoteDataSource.ajustarMarcaje(
      marcajeId: marcajeId,
      accion: accion,
      nuevoResultado: nuevoResultado,
      anulado: anulado,
      motivo: motivo,
    );
  }

  @override
  Future<MarcajeAdminModel> crearMarcajeManual({
    required String sesionId,
    required String usuarioId,
    required String tipo,
    required String resultado,
    required String motivo,
  }) {
    return _remoteDataSource.crearMarcajeManual(
      sesionId: sesionId,
      usuarioId: usuarioId,
      tipo: tipo,
      resultado: resultado,
      motivo: motivo,
    );
  }
}
