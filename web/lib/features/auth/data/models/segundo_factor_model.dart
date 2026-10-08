import 'package:equatable/equatable.dart';

import 'user_model.dart';

/// Desafío que entrega /auth/login cuando falta el segundo factor (US-AUT-05).
/// [configurar] indica que el rol administrativo aún no tiene TOTP y debe enrolarlo.
class DesafioTotp extends Equatable {
  final String token;
  final bool configurar;
  final String expiraEn;

  const DesafioTotp({
    required this.token,
    required this.configurar,
    this.expiraEn = '',
  });

  static DesafioTotp? fromJson(Map<String, dynamic> json) {
    final token = json['desafioToken']?.toString() ?? '';
    if (token.isEmpty) return null;
    return DesafioTotp(
      token: token,
      configurar: json['requiereConfigurarTOTP'] == true,
      expiraEn: json['expiraEn']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [token, configurar, expiraEn];
}

/// Clave secreta y códigos de respaldo del enrolamiento TOTP (AC-01, AC-03).
class TotpEnrolamiento extends Equatable {
  final String secreto;
  final List<String> codigosRespaldo;

  const TotpEnrolamiento({
    required this.secreto,
    required this.codigosRespaldo,
  });

  factory TotpEnrolamiento.fromJson(Map<String, dynamic> json) {
    return TotpEnrolamiento(
      secreto: json['secretKey']?.toString() ?? '',
      codigosRespaldo: (json['backupCodes'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  /// URI estándar para que la app autenticadora registre la cuenta.
  String uri(String correo) =>
      'otpauth://totp/SIAA:${Uri.encodeComponent(correo)}'
      '?secret=$secreto&issuer=SIAA&digits=6&period=30';

  @override
  List<Object?> get props => [secreto, codigosRespaldo];
}

/// Resultado del login con contraseña: el usuario autenticado o el desafío pendiente.
class LoginResultado {
  final UserModel? usuario;
  final DesafioTotp? desafio;

  const LoginResultado.autenticado(UserModel this.usuario) : desafio = null;
  const LoginResultado.desafio(DesafioTotp this.desafio) : usuario = null;
}
