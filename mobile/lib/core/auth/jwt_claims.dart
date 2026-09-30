// jwt_claims.dart — Lectura (sin verificar firma) de los claims del access token.
// Solo sirve para reconstruir la navegación al reabrir la app; el backend valida el
// token en cada petición (RF-ROL-003). Claims: uid, rol, perms, exp.
import 'dart:convert';

class JwtClaims {
  final String usuarioId;
  final String rolActivo;
  final List<String> permisos;
  final DateTime? expira;

  const JwtClaims({
    required this.usuarioId,
    required this.rolActivo,
    required this.permisos,
    this.expira,
  });

  bool expiradoEn(DateTime ahora) => expira != null && !ahora.isBefore(expira!);

  /// null si el token no tiene el formato esperado.
  static JwtClaims? decodificar(String token) {
    final partes = token.split('.');
    if (partes.length != 3) return null;
    try {
      final json = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(partes[1]))));
      if (json is! Map<String, dynamic>) return null;
      final exp = json['exp'];
      return JwtClaims(
        usuarioId: (json['uid'] ?? json['sub'] ?? '').toString(),
        rolActivo: (json['rol'] ?? '').toString(),
        permisos: (json['perms'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        expira: exp is num
            ? DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000,
                isUtc: true)
            : null,
      );
    } catch (_) {
      return null;
    }
  }
}
