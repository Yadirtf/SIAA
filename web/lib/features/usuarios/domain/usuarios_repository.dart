import '../data/models/ambito_model.dart';
import '../data/models/catalogo_usuarios_model.dart';
import '../data/models/importacion_usuarios_model.dart';
import '../data/models/rol_asignado_model.dart';
import '../data/models/usuario_model.dart';
import '../data/models/usuario_requests.dart';
import '../data/models/usuarios_pagina_model.dart';

/// Contrato de la administración de usuarios (US-ROL-01..05, US-AUT-02).
abstract class UsuariosRepository {
  Future<UsuariosPaginaModel> listar({
    String? texto,
    String? rol,
    bool? activo,
    int pagina = 1,
    int limite = 50,
  });

  Future<UsuarioModel> obtener(String id);

  Future<UsuarioCreadoResult> crear(CrearUsuarioRequest request);

  Future<UsuarioModel> actualizar(String id, ActualizarUsuarioRequest request);

  Future<UsuarioModel> activar(String id);

  Future<UsuarioModel> desactivar(String id, String motivo);

  Future<UsuarioModel> asignarRoles(String id, List<RolAsignadoModel> roles);

  Future<UsuarioModel> asignarAmbitos(String id, List<AmbitoModel> ambitos);

  Future<void> desbloquear(String id);

  Future<void> revocarSesiones(String id, String motivo);

  /// Valida (confirmar=false) o crea (confirmar=true) usuarios desde un CSV.
  Future<ImportacionUsuariosModel> importarCsv(
    String csv, {
    required bool confirmar,
  });

  /// Roles, sedes, facultades y bloques para los selectores.
  Future<CatalogoUsuariosModel> cargarCatalogo();
}
