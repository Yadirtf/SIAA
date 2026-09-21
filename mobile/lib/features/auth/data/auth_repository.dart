// Repositorio de autenticación — data layer
// Implementa las llamadas HTTP y transforma los DTO en modelos de dominio.
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

// ─── Modelos de dominio ─────────────────────────────────────────────────────

class TokenPair {
  final String accessToken;
  final String refreshToken;
  final String expiraEn;
  final UsuarioInfo usuario;

  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.expiraEn,
    required this.usuario,
  });

  factory TokenPair.fromJson(Map<String, dynamic> json) => TokenPair(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
    expiraEn: json['expiraEn'] as String,
    usuario: UsuarioInfo.fromJson(json['usuario'] as Map<String, dynamic>),
  );
}

class UsuarioInfo {
  final String id;
  final String correo;
  final String nombre;
  final String apellido;
  final List<String> roles;
  final List<String> permisos;

  const UsuarioInfo({
    required this.id,
    required this.correo,
    required this.nombre,
    required this.apellido,
    required this.roles,
    required this.permisos,
  });

  factory UsuarioInfo.fromJson(Map<String, dynamic> json) => UsuarioInfo(
    id: json['id'] as String? ?? '',
    correo: json['correo'] as String? ?? '',
    nombre: json['nombre'] as String? ?? '',
    apellido: json['apellido'] as String? ?? '',
    roles: (json['roles'] as List<dynamic>? ?? []).cast<String>(),
    permisos: (json['permisos'] as List<dynamic>? ?? []).cast<String>(),
  );
}

/// Excepción tipada de autenticación con código de error del backend.
class AuthException implements Exception {
  final String message;
  final String code;
  const AuthException({required this.message, required this.code});
}

// ─── Repositorio ────────────────────────────────────────────────────────────

class AuthRepository {
  final Dio _client;

  AuthRepository({Dio? client}) : _client = client ?? ApiClient.instance;

  /// Login con correo y contraseña institucional. US-AUT-01.
  Future<TokenPair> login({
    required String correo,
    required String password,
  }) async {
    try {
      final response = await _client.post('/auth/login', data: {
        'correo': correo,
        'password': password,
      });
      return TokenPair.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Renueva el par de tokens con el refresh token. US-AUT-01 AC-05.
  Future<TokenPair> refresh({required String refreshToken}) async {
    try {
      final response = await _client.post('/auth/refresh', data: {
        'refreshToken': refreshToken,
      });
      return TokenPair.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Cierra la sesión revocando el refresh token. US-AUT-01.
  Future<void> logout({required String refreshToken}) async {
    try {
      await _client.post('/auth/logout', data: {'refreshToken': refreshToken});
    } catch (_) {
      // Logout es best-effort: si falla la red, igual limpiamos localmente.
    }
  }

  /// Solicita el envío del enlace de recuperación. US-AUT-04 AC-01.
  Future<void> solicitarRecuperacion({required String correo}) async {
    try {
      await _client.post('/auth/recuperar', data: {'correo': correo});
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Establece la nueva contraseña con el token de recuperación. US-AUT-04.
  Future<void> confirmarRecuperacion({
    required String token,
    required String password,
  }) async {
    try {
      await _client.post('/auth/recuperar/confirmar', data: {
        'token': token,
        'password': password,
      });
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  AuthException _mapDioError(DioException e) {
    final data = e.response?.data as Map<String, dynamic>?;
    final code = data?['codigo'] as String? ?? 'ERROR_DESCONOCIDO';
    final message = data?['mensaje'] as String? ?? _defaultMessage(e);
    return AuthException(message: message, code: code);
  }

  String _defaultMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'La conexión tardó demasiado. Verifica tu internet.';
      case DioExceptionType.connectionError:
        return 'No se pudo conectar al servidor. Verifica tu conexión.';
      default:
        return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
    }
  }
}
