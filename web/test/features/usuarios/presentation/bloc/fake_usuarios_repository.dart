import 'package:siaa_web/core/network/api_exception.dart';
import 'package:siaa_web/features/usuarios/data/models/ambito_model.dart';
import 'package:siaa_web/features/usuarios/data/models/catalogo_usuarios_model.dart';
import 'package:siaa_web/features/usuarios/data/models/importacion_usuarios_model.dart';
import 'package:siaa_web/features/usuarios/data/models/rol_asignado_model.dart';
import 'package:siaa_web/features/usuarios/data/models/usuario_model.dart';
import 'package:siaa_web/features/usuarios/data/models/usuario_requests.dart';
import 'package:siaa_web/features/usuarios/data/models/usuarios_pagina_model.dart';
import 'package:siaa_web/features/usuarios/domain/usuarios_repository.dart';

/// Repositorio en memoria para probar los BLoC sin red.
class FakeUsuariosRepository implements UsuariosRepository {
  List<UsuarioModel> usuarios = [];
  ApiException? error;
  final List<String> llamadas = [];
  Map<String, dynamic>? ultimoFiltro;
  String? ultimoCsv;

  void _fallarSiCorresponde() {
    if (error != null) throw error!;
  }

  UsuarioModel _buscar(String id) => usuarios.firstWhere((u) => u.id == id);

  UsuarioModel _reemplazar(String id, UsuarioModel Function(UsuarioModel) f) {
    final i = usuarios.indexWhere((u) => u.id == id);
    usuarios[i] = f(usuarios[i]);
    return usuarios[i];
  }

  @override
  Future<UsuariosPaginaModel> listar({
    String? texto,
    String? rol,
    bool? activo,
    int pagina = 1,
    int limite = 50,
  }) async {
    llamadas.add('listar');
    ultimoFiltro = {'texto': texto, 'rol': rol, 'activo': activo};
    _fallarSiCorresponde();
    final lista = usuarios
        .where((u) => activo == null || u.activo == activo)
        .toList();
    return UsuariosPaginaModel(
      usuarios: lista,
      total: lista.length,
      pagina: pagina,
      limite: limite,
    );
  }

  @override
  Future<UsuarioModel> obtener(String id) async => _buscar(id);

  @override
  Future<UsuarioCreadoResult> crear(CrearUsuarioRequest request) async {
    llamadas.add('crear');
    _fallarSiCorresponde();
    final u = UsuarioModel(
      id: 'nuevo',
      correo: request.correo,
      nombre: request.nombre,
      apellido: request.apellido,
      activo: true,
      roles: request.roles,
    );
    usuarios.add(u);
    return UsuarioCreadoResult(
      usuarioId: u.id,
      correo: u.correo,
      invitacionEnviada: request.password == null || request.password!.isEmpty,
    );
  }

  @override
  Future<UsuarioModel> actualizar(String id, ActualizarUsuarioRequest r) async {
    llamadas.add('actualizar');
    _fallarSiCorresponde();
    return _buscar(id);
  }

  UsuarioModel _conActivo(UsuarioModel u, bool activo) => UsuarioModel(
    id: u.id,
    correo: u.correo,
    nombre: u.nombre,
    apellido: u.apellido,
    activo: activo,
    roles: u.roles,
  );

  @override
  Future<UsuarioModel> activar(String id) async {
    llamadas.add('activar');
    _fallarSiCorresponde();
    return _reemplazar(id, (u) => _conActivo(u, true));
  }

  @override
  Future<UsuarioModel> desactivar(String id, String motivo) async {
    llamadas.add('desactivar:$motivo');
    _fallarSiCorresponde();
    return _reemplazar(id, (u) => _conActivo(u, false));
  }

  @override
  Future<UsuarioModel> asignarRoles(String id, List<RolAsignadoModel> r) async {
    llamadas.add('roles:${r.map((e) => e.nombre).join('|')}');
    _fallarSiCorresponde();
    return _buscar(id);
  }

  @override
  Future<UsuarioModel> asignarAmbitos(String id, List<AmbitoModel> a) async {
    llamadas.add('ambitos:${a.length}');
    _fallarSiCorresponde();
    return _buscar(id);
  }

  @override
  Future<void> desbloquear(String id) async => llamadas.add('desbloquear');

  @override
  Future<void> revocarSesiones(String id, String motivo) async =>
      llamadas.add('revocar:$motivo');

  @override
  Future<ImportacionUsuariosModel> importarCsv(
    String csv, {
    required bool confirmar,
  }) async {
    llamadas.add('importar:$confirmar');
    ultimoCsv = csv;
    _fallarSiCorresponde();
    return ImportacionUsuariosModel(
      confirmado: confirmar,
      total: 2,
      validas: 1,
      creados: confirmar ? 1 : 0,
      filas: const [],
    );
  }

  @override
  Future<CatalogoUsuariosModel> cargarCatalogo() async =>
      const CatalogoUsuariosModel();
}
