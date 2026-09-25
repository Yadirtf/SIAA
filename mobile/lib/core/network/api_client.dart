// Capa de red — T-PLT-03.4
// Cliente HTTP con interceptor de autenticación, renovación automática de token,
// reintentos con backoff exponencial y correlationId.
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../storage/secure_storage.dart';

/// ApiClient configura y proporciona el cliente HTTP de la aplicación.
class ApiClient {
  static Dio? _instance;

  /// Base URL por entorno. Se inyecta desde la configuración de entorno.
  static String baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );

  static Dio get instance {
    _instance ??= _create();
    return _instance!;
  }

  static Dio _create() {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // ─── Certificate Pinning — T-PLT-03.5 ───────────────────
    // En producción se configuran los hashes SHA-256 del certificado del servidor.
    // En desarrollo (debug) se permite cualquier certificado para facilitar el trabajo local.
    if (!_isDebug()) {
      (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) {
          // Verificar el hash del certificado contra los hashes clavados.
          // TODO: Implementar verificación real de hash en producción.
          // Por ahora rechaza todo certificado inválido.
          return false;
        };
        return client;
      };
    }

    // ─── Interceptores ───────────────────────────────────────
    dio.interceptors.addAll([
      _CorrelationIdInterceptor(),
      _AuthInterceptor(dio),
      _RetryInterceptor(dio),
      if (_isDebug())
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => print('[SIAA-HTTP] $obj'),
        ),
    ]);

    return dio;
  }

  static bool _isDebug() {
    bool debug = false;
    assert(debug = true); // solo en debug
    return debug;
  }
}

// ─── Interceptor de CorrelationId ──────────────────────────────────────────

class _CorrelationIdInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final correlationId = _generateCorrelationId();
    options.headers['X-Correlation-Id'] = correlationId;
    handler.next(options);
  }

  String _generateCorrelationId() {
    // UUID v4 simplificado
    final timestamp = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    return '${timestamp}-mobile';
  }
}

// ─── Interceptor de Autenticación ───────────────────────────────────────────

class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  bool _isRefreshing = false;

  _AuthInterceptor(this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Rutas públicas — no requieren token
    final publicPaths = ['/auth/login', '/auth/refresh', '/auth/recuperar'];
    if (publicPaths.any((p) => options.path.contains(p))) {
      return handler.next(options);
    }

    try {
      final token = await SecureStorage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // Ignorar para evitar abortar la petición si hay fallos en storage
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      final errorCode = err.response?.data?['codigo'];
      if (errorCode == 'AUTH_TOKEN_EXPIRADO') {
        _isRefreshing = true;
        try {
          await _refreshTokens();
          // Reintentar la petición original con el nuevo token
          final token = await SecureStorage.getAccessToken();
          if (token != null) {
            err.requestOptions.headers['Authorization'] = 'Bearer $token';
          }
          final response = await _dio.fetch(err.requestOptions);
          handler.resolve(response);
          return;
        } catch (_) {
          // Renovación fallida: limpiar sesión y redirigir a login
          await SecureStorage.clearSession();
          // TODO: Emitir evento de sesión expirada via BLoC
        } finally {
          _isRefreshing = false;
        }
      }
    }
    handler.next(err);
  }

  Future<void> _refreshTokens() async {
    final refreshToken = await SecureStorage.getRefreshToken();
    if (refreshToken == null) throw Exception('No hay refresh token');

    final response = await _dio.post('/auth/refresh', data: {
      'refreshToken': refreshToken,
    });

    final data = response.data as Map<String, dynamic>;
    await SecureStorage.saveSession(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
  }
}

// ─── Interceptor de Reintentos ───────────────────────────────────────────────

class _RetryInterceptor extends Interceptor {
  final Dio _dio;
  static const int _maxRetries = 3;

  _RetryInterceptor(this._dio);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;

    // Reintentar en errores de red (no en errores HTTP de negocio)
    if (_shouldRetry(err) && retryCount < _maxRetries) {
      err.requestOptions.extra['retryCount'] = retryCount + 1;

      // Backoff exponencial: 500ms, 1s, 2s
      final delay = Duration(milliseconds: 500 * (1 << retryCount));
      await Future.delayed(delay);

      try {
        final response = await _dio.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (e) {
        // Continuar con el error original
      }
    }
    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;
  }
}
