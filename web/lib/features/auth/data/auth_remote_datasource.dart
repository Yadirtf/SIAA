import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'models/login_response_model.dart';
import 'models/segundo_factor_model.dart';

class AuthRemoteDataSource {
  final ApiClient _client;

  AuthRemoteDataSource({ApiClient? client}) : _client = client ?? ApiClient();

  Future<LoginResponseModel> login({
    required String correo,
    required String password,
    String? dispositivoId,
  }) async {
    final response = await _client.post(
      ApiConstants.login,
      body: {
        'correo': correo,
        'password': password,
        if (dispositivoId != null) 'dispositivoId': dispositivoId,
      },
      requiresAuth: false,
    );

    return LoginResponseModel.fromJson(response as Map<String, dynamic>);
  }

  /// Inicia la configuración obligatoria del segundo factor (US-AUT-05 AC-01).
  Future<TotpEnrolamiento> enrolarTotp(String desafio) async {
    final response = await _client.post(
      ApiConstants.totpEnrolar,
      body: {'desafioToken': desafio},
      requiresAuth: false,
    );
    return TotpEnrolamiento.fromJson(response as Map<String, dynamic>);
  }

  /// Presenta el código del desafío: confirma el enrolamiento o verifica el TOTP activo.
  Future<LoginResponseModel> completarTotp({
    required DesafioTotp desafio,
    required String codigo,
  }) async {
    final response = await _client.post(
      desafio.configurar
          ? ApiConstants.totpEnrolarConfirmar
          : ApiConstants.totpVerificar,
      body: {'desafioToken': desafio.token, 'codigo': codigo},
      requiresAuth: false,
    );
    return LoginResponseModel.fromJson(response as Map<String, dynamic>);
  }

  Future<LoginResponseModel> refresh({
    required String refreshToken,
    String? dispositivoId,
  }) async {
    final response = await _client.post(
      ApiConstants.refresh,
      body: {
        'refreshToken': refreshToken,
        if (dispositivoId != null) 'dispositivoId': dispositivoId,
      },
      requiresAuth: false,
    );

    return LoginResponseModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> logout({required String refreshToken}) async {
    await _client.post(
      ApiConstants.logout,
      body: {'refreshToken': refreshToken},
      requiresAuth: true,
    );
  }

  Future<void> recuperarPassword({required String correo}) async {
    await _client.post(
      ApiConstants.recuperar,
      body: {'correo': correo},
      requiresAuth: false,
    );
  }

  Future<void> confirmarRecuperacion({
    required String token,
    required String newPassword,
  }) async {
    await _client.post(
      ApiConstants.confirmarRecuperar,
      body: {'token': token, 'password': newPassword},
      requiresAuth: false,
    );
  }
}
