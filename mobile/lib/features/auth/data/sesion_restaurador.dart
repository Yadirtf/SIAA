// sesion_restaurador.dart — Reconstruye la sesión al reabrir la app (US-AUT-01, RF-ROL-003)
// Antes se emitía una sesión sin roles ni permisos y la navegación quedaba vacía.
// 1) GET /me/perfil (el interceptor renueva el token si expiró) para nombre y roles;
// 2) los permisos y el rol activo salen del access token vigente.
import '../../../core/auth/jwt_claims.dart';
import '../../../core/storage/secure_storage.dart';
import '../../perfil/data/perfil_remote_datasource.dart';
import '../../perfil/domain/perfil_model.dart';

class SesionRestaurada {
  final String usuarioId;
  final String nombre;
  final String correo;
  final List<String> roles;
  final List<String> permisos;
  final String rolActivo;

  const SesionRestaurada({
    required this.usuarioId,
    required this.nombre,
    required this.correo,
    required this.roles,
    required this.permisos,
    required this.rolActivo,
  });
}

class SesionRestaurador {
  final PerfilRemoteDataSource _perfil;
  final Future<String?> Function() _leerToken;

  SesionRestaurador({
    PerfilRemoteDataSource? perfil,
    Future<String?> Function()? leerToken,
  })  : _perfil = perfil ?? PerfilRemoteDataSource(),
        _leerToken = leerToken ?? SecureStorage.getAccessToken;

  /// null si no hay sesión utilizable (sin token o renovación fallida).
  Future<SesionRestaurada?> restaurar() async {
    if (await _leerToken() == null) return null;
    PerfilModel? perfil;
    try {
      perfil = await _perfil.obtener();
    } catch (_) {
      // Sin red o servidor antiguo: se usa solo el token (el marcaje offline sigue disponible).
    }
    // El interceptor pudo renovar (o borrar) el token durante la consulta anterior.
    final token = await _leerToken();
    final claims = token == null ? null : JwtClaims.decodificar(token);
    if (claims == null) return null;
    final roles = perfil?.roles.isNotEmpty == true
        ? perfil!.roles
        : [if (claims.rolActivo.isNotEmpty) claims.rolActivo];
    return SesionRestaurada(
      usuarioId:
          claims.usuarioId.isNotEmpty ? claims.usuarioId : (perfil?.id ?? ''),
      nombre:
          perfil == null ? '' : '${perfil.nombre} ${perfil.apellido}'.trim(),
      correo: perfil?.correo ?? '',
      roles: _activoPrimero(roles, claims.rolActivo),
      permisos: claims.permisos,
      rolActivo: claims.rolActivo,
    );
  }

  /// La navegación arranca en el primer rol: debe ser el rol activo del token.
  static List<String> _activoPrimero(List<String> roles, String activo) {
    if (activo.isEmpty || !roles.contains(activo)) return roles;
    return [activo, ...roles.where((r) => r != activo)];
  }
}
