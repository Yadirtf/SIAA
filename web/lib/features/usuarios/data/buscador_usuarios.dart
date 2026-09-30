import 'models/usuario_model.dart';
import 'usuarios_remote_datasource.dart';

/// Búsqueda de usuarios para los selectores (docente, suplente, actor...).
/// La búsqueda de texto la hace el backend (`q` sobre nombre, correo y
/// documento) y aplica el alcance ABAC del usuario que consulta.
abstract class BuscadorUsuarios {
  /// Primeros [limite] usuarios que coinciden con [consulta] (vacía = todos).
  Future<List<UsuarioModel>> buscar(
    String consulta, {
    String? rol,
    bool soloActivos = true,
    int limite = 20,
  });

  /// Usuario por id, o null si no existe o no es visible.
  Future<UsuarioModel?> porId(String id);
}

/// Implementación sobre `GET /usuarios` y `GET /usuarios/:id`.
class BuscadorUsuariosRemoto implements BuscadorUsuarios {
  final UsuariosRemoteDataSource _remote;

  BuscadorUsuariosRemoto({UsuariosRemoteDataSource? remote})
    : _remote = remote ?? UsuariosRemoteDataSource();

  @override
  Future<List<UsuarioModel>> buscar(
    String consulta, {
    String? rol,
    bool soloActivos = true,
    int limite = 20,
  }) async {
    final pagina = await _remote.listar(
      texto: consulta.trim(),
      rol: rol,
      activo: soloActivos ? true : null,
      limite: limite,
    );
    return pagina.usuarios;
  }

  @override
  Future<UsuarioModel?> porId(String id) async {
    try {
      final usuario = await _remote.obtener(id);
      return usuario.id.isEmpty ? null : usuario;
    } catch (_) {
      return null;
    }
  }
}
