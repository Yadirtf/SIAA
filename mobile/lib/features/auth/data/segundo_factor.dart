// Segundo factor TOTP del login (US-AUT-05). El backend entrega un desafío tras validar la
// contraseña de un rol administrativo; sin código válido no hay tokens.

/// Desafío pendiente. [configurar] indica que el usuario aún debe enrolar TOTP.
class DesafioTotp {
  final String token;
  final bool configurar;

  const DesafioTotp({required this.token, required this.configurar});

  static DesafioTotp? fromJson(Map<String, dynamic> json) {
    final token = json['desafioToken'] as String? ?? '';
    if (token.isEmpty) return null;
    return DesafioTotp(
      token: token,
      configurar: json['requiereConfigurarTOTP'] == true,
    );
  }
}

/// Clave secreta y códigos de respaldo de un solo uso (AC-01, AC-03).
class TotpEnrolamiento {
  final String secreto;
  final List<String> codigosRespaldo;

  const TotpEnrolamiento({
    required this.secreto,
    required this.codigosRespaldo,
  });

  factory TotpEnrolamiento.fromJson(Map<String, dynamic> json) =>
      TotpEnrolamiento(
        secreto: json['secretKey'] as String? ?? '',
        codigosRespaldo: (json['backupCodes'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}
