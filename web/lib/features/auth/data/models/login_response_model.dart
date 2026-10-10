import 'segundo_factor_model.dart';
import 'user_model.dart';

class LoginResponseModel {
  final String accessToken;
  final String refreshToken;
  final String expiraEn;
  final String tipoToken;
  final UserModel usuario;

  /// Presente cuando el login exige segundo factor; en ese caso no hay tokens.
  final DesafioTotp? desafio;

  const LoginResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.expiraEn,
    required this.tipoToken,
    required this.usuario,
    this.desafio,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      expiraEn: json['expiraEn']?.toString() ?? '',
      tipoToken: json['tipoToken']?.toString() ?? 'Bearer',
      usuario: UserModel.fromJson(
        json['usuario'] is Map<String, dynamic>
            ? json['usuario'] as Map<String, dynamic>
            : {},
      ),
      desafio: DesafioTotp.fromJson(json),
    );
  }
}
