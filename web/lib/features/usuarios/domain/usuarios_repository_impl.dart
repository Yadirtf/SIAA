import '../data/models/ambito_model.dart';
import '../data/models/catalogo_usuarios_model.dart';
import '../data/models/importacion_usuarios_model.dart';
import '../data/models/rol_asignado_model.dart';
import '../data/models/usuario_model.dart';
import '../data/models/usuario_requests.dart';
import '../data/models/usuarios_pagina_model.dart';
import '../data/usuarios_catalogo_datasource.dart';
import '../data/usuarios_remote_datasource.dart';
import 'usuarios_repository.dart';

class UsuariosRepositoryImpl implements UsuariosRepository {
  final UsuariosRemoteDataSource _remote;
  final UsuariosCatalogoDataSource _catalogo;

  UsuariosRepositoryImpl({
    UsuariosRemoteDataSource? remoteDataSource,
    UsuariosCatalogoDataSource? catalogoDataSource,
  }) : _remote = remoteDataSource ?? UsuariosRemoteDataSource(),
       _catalogo = catalogoDataSource ?? UsuariosCatalogoDataSource();

  @override
  Future<UsuariosPaginaModel> listar({
    String? texto,
    String? rol,
    bool? activo,
    int pagina = 1,
    int limite = 50,
  }) => _remote.listar(
    texto: texto,
    rol: rol,
    activo: activo,
    pagina: pagina,
    limite: limite,
  );

  @override
  Future<UsuarioModel> obtener(String id) => _remote.obtener(id);

  @override
  Future<UsuarioCreadoResult> crear(CrearUsuarioRequest request) =>
      _remote.crear(request);

  @override
  Future<UsuarioModel> actualizar(
    String id,
    ActualizarUsuarioRequest request,
  ) => _remote.actualizar(id, request);

  @override
  Future<UsuarioModel> activar(String id) => _remote.activar(id);

  @override
  Future<UsuarioModel> desactivar(String id, String motivo) =>
      _remote.desactivar(id, motivo);

  @override
  Future<UsuarioModel> asignarRoles(String id, List<RolAsignadoModel> roles) =>
      _remote.asignarRoles(id, roles);

  @override
  Future<UsuarioModel> asignarAmbitos(String id, List<AmbitoModel> ambitos) =>
      _remote.asignarAmbitos(id, ambitos);

  @override
  Future<void> desbloquear(String id) => _remote.desbloquear(id);

  @override
  Future<void> revocarSesiones(String id, String motivo) =>
      _remote.revocarSesiones(id, motivo);

  @override
  Future<ImportacionUsuariosModel> importarCsv(
    String csv, {
    required bool confirmar,
  }) => _remote.importar(csv, confirmar: confirmar);

  @override
  Future<CatalogoUsuariosModel> cargarCatalogo() => _catalogo.cargar();
}
