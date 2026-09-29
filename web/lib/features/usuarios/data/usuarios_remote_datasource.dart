import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'models/ambito_model.dart';
import 'models/importacion_usuarios_model.dart';
import 'models/rol_asignado_model.dart';
import 'models/usuario_model.dart';
import 'models/usuario_requests.dart';
import 'models/usuarios_pagina_model.dart';

/// Acceso HTTP a la gestión de usuarios (/api/v1/usuarios).
class UsuariosRemoteDataSource {
  final ApiClient _client;

  UsuariosRemoteDataSource({ApiClient? client})
    : _client = client ?? ApiClient();

  /// GET /usuarios?q=&rol=&activo=&pagina=&limite= (total en X-Total-Count).
  Future<UsuariosPaginaModel> listar({
    String? texto,
    String? rol,
    bool? activo,
    int pagina = 1,
    int limite = 50,
  }) async {
    final query = <String, String>{
      if (texto != null && texto.isNotEmpty) 'q': texto,
      if (rol != null && rol.isNotEmpty) 'rol': rol,
      if (activo != null) 'activo': activo.toString(),
      'pagina': '$pagina',
      'limite': '$limite',
    };
    final uri = Uri.parse(ApiConstants.usuarios)
        .replace(queryParameters: query);
    final respuesta = await _client.getWithHeaders(uri.toString());
    final usuarios = respuesta.body is List
        ? (respuesta.body as List)
              .whereType<Map>()
              .map((e) => UsuarioModel.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : <UsuarioModel>[];
    return UsuariosPaginaModel(
      usuarios: usuarios,
      total: respuesta.intHeader('X-Total-Count'),
      pagina: pagina,
      limite: limite,
    );
  }

  Future<UsuarioModel> obtener(String id) async {
    return _usuario(await _client.get(ApiConstants.usuario(id)));
  }

  /// POST /usuarios → {usuario, invitacionEnviada}.
  Future<UsuarioCreadoResult> crear(CrearUsuarioRequest request) async {
    final resp = await _client.post(
      ApiConstants.usuarios,
      body: request.toJson(),
    );
    final mapa = resp is Map ? Map<String, dynamic>.from(resp) : {};
    final usuario = mapa['usuario'] is Map
        ? UsuarioModel.fromJson(Map<String, dynamic>.from(mapa['usuario']))
        : null;
    return UsuarioCreadoResult(
      usuarioId: usuario?.id ?? '',
      correo: usuario?.correo ?? request.correo,
      invitacionEnviada: mapa['invitacionEnviada'] == true,
    );
  }

  Future<UsuarioModel> actualizar(
    String id,
    ActualizarUsuarioRequest request,
  ) async {
    final resp = await _client.put(
      ApiConstants.usuario(id),
      body: request.toJson(),
    );
    return _usuario(resp);
  }

  Future<UsuarioModel> activar(String id) async {
    return _usuario(await _client.post(ApiConstants.activarUsuario(id)));
  }

  Future<UsuarioModel> desactivar(String id, String motivo) async {
    final resp = await _client.post(
      ApiConstants.desactivarUsuario(id),
      body: {'motivo': motivo},
    );
    return _usuario(resp);
  }

  Future<UsuarioModel> asignarRoles(
    String id,
    List<RolAsignadoModel> roles,
  ) async {
    final resp = await _client.put(
      ApiConstants.rolesUsuario(id),
      body: {'roles': roles.map((r) => r.toJson()).toList()},
    );
    return _usuario(resp);
  }

  Future<UsuarioModel> asignarAmbitos(
    String id,
    List<AmbitoModel> ambitos,
  ) async {
    final resp = await _client.put(
      ApiConstants.ambitosUsuario(id),
      body: {'ambitos': ambitos.map((a) => a.toJson()).toList()},
    );
    return _usuario(resp);
  }

  Future<void> desbloquear(String id) async {
    await _client.post(ApiConstants.desbloquearUsuario(id));
  }

  Future<void> revocarSesiones(String id, String motivo) async {
    await _client.post(
      ApiConstants.revocarSesionesUsuario(id),
      body: {'motivo': motivo},
    );
  }

  /// POST /usuarios/importar?confirmar= con el CSV crudo (text/csv).
  Future<ImportacionUsuariosModel> importar(
    String csv, {
    required bool confirmar,
  }) async {
    final resp = await _client.postRaw(
      '${ApiConstants.usuariosImportar}?confirmar=$confirmar',
      body: csv,
      contentType: 'text/csv; charset=utf-8',
    );
    return ImportacionUsuariosModel.fromJson(
      resp is Map ? Map<String, dynamic>.from(resp) : <String, dynamic>{},
    );
  }

  UsuarioModel _usuario(dynamic resp) => UsuarioModel.fromJson(
    resp is Map ? Map<String, dynamic>.from(resp) : <String, dynamic>{},
  );
}
