// Repositorio de autenticación para la consola web SIAA — T-AUT-01.8
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';

class WebUserInfo {
  final String id;
  final String correo;
  final String nombre;
  final String apellido;
  final List<String> roles;
  final List<String> permisos;

  const WebUserInfo({
    required this.id,
    required this.correo,
    required this.nombre,
    required this.apellido,
    required this.roles,
    required this.permisos,
  });

  factory WebUserInfo.fromJson(Map<String, dynamic> json) => WebUserInfo(
    id: json['id'] as String? ?? '',
    correo: json['correo'] as String? ?? '',
    nombre: json['nombre'] as String? ?? '',
    apellido: json['apellido'] as String? ?? '',
    roles: (json['roles'] as List<dynamic>? ?? []).cast<String>(),
    permisos: (json['permisos'] as List<dynamic>? ?? []).cast<String>(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'correo': correo,
    'nombre': nombre,
    'apellido': apellido,
    'roles': roles,
    'permisos': permisos,
  };
}

class WebAuthRepository {
  final Dio _client;

  WebAuthRepository({Dio? client}) : _client = client ?? WebApiClient.instance;

  Future<WebUserInfo> login({
    required String correo,
    required String password,
  }) async {
    try {
      final response = await _client.post('/auth/login', data: {
        'correo': correo,
        'password': password,
      });

      final data = response.data as Map<String, dynamic>;
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;
      final usuarioMap = data['usuario'] as Map<String, dynamic>;
      final user = WebUserInfo.fromJson(usuarioMap);

      await WebTokenStorage.saveSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        usuario: user.toJson(),
      );

      return user;
    } on DioException catch (e) {
      final mensaje = e.response?.data?['mensaje'] ?? 'Error de autenticación';
      throw Exception(mensaje);
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await WebTokenStorage.getRefreshToken();
      if (refreshToken != null) {
        await _client.post('/auth/logout', data: {'refreshToken': refreshToken});
      }
    } catch (_) {
      // Best effort
    } finally {
      await WebTokenStorage.clearSession();
    }
  }

  Future<WebUserInfo?> checkSession() async {
    final token = await WebTokenStorage.getAccessToken();
    if (token == null) return null;

    final userMap = await WebTokenStorage.getUser();
    if (userMap != null) {
      return WebUserInfo.fromJson(userMap);
    }
    return null;
  }
}
