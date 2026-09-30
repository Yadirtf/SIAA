import 'dart:convert';

import '../../../core/storage/token_storage.dart';
import '../data/auth_remote_datasource.dart';
import '../data/models/login_response_model.dart';
import '../data/models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> login({required String correo, required String password});
  Future<UserModel?> checkAuthStatus();
  Future<void> logout();
  Future<void> recuperarPassword({required String correo});
  Future<void> confirmarRecuperacion({
    required String token,
    required String newPassword,
  });
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final TokenStorage _tokenStorage;

  AuthRepositoryImpl({
    AuthRemoteDataSource? remoteDataSource,
    TokenStorage? tokenStorage,
  }) : _remoteDataSource = remoteDataSource ?? AuthRemoteDataSource(),
       _tokenStorage = tokenStorage ?? TokenStorage();

  @override
  Future<UserModel> login({
    required String correo,
    required String password,
  }) async {
    final LoginResponseModel response = await _remoteDataSource.login(
      correo: correo,
      password: password,
    );

    await _tokenStorage.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );

    await _tokenStorage.saveUserData(jsonEncode(response.usuario.toJson()));

    return response.usuario;
  }

  @override
  Future<UserModel?> checkAuthStatus() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    final userDataStr = await _tokenStorage.getUserData();
    if (userDataStr != null && userDataStr.isNotEmpty) {
      try {
        final Map<String, dynamic> json = jsonDecode(userDataStr);
        return UserModel.fromJson(json);
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  @override
  Future<void> logout() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _remoteDataSource.logout(refreshToken: refreshToken);
      } catch (_) {
        // Non-blocking logout error
      }
    }
    await _tokenStorage.clear();
  }

  @override
  Future<void> recuperarPassword({required String correo}) async {
    await _remoteDataSource.recuperarPassword(correo: correo);
  }

  @override
  Future<void> confirmarRecuperacion({
    required String token,
    required String newPassword,
  }) async {
    await _remoteDataSource.confirmarRecuperacion(
      token: token,
      newPassword: newPassword,
    );
  }
}
