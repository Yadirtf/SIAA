// Capa de red para la consola web administrativa SIAA — T-PLT-01.8
// Compatible con Flutter Web (CORS, tokens en SharedPreferences, auto-refresh)
import 'package:dio/dio.dart';
import '../storage/token_storage.dart';

class WebApiClient {
  static Dio? _instance;

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

    dio.interceptors.addAll([
      _WebCorrelationIdInterceptor(),
      _WebAuthInterceptor(dio),
    ]);

    return dio;
  }
}

class _WebCorrelationIdInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    options.headers['X-Correlation-Id'] = '$timestamp-web';
    handler.next(options);
  }
}

class _WebAuthInterceptor extends Interceptor {
  final Dio _dio;
  bool _isRefreshing = false;

  _WebAuthInterceptor(this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final publicPaths = ['/auth/login', '/auth/refresh', '/auth/recuperar'];
    if (publicPaths.any((p) => options.path.contains(p))) {
      return handler.next(options);
    }

    final token = await WebTokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
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
          final refreshToken = await WebTokenStorage.getRefreshToken();
          if (refreshToken != null) {
            final response = await _dio.post('/auth/refresh', data: {
              'refreshToken': refreshToken,
            });
            final data = response.data as Map<String, dynamic>;
            await WebTokenStorage.saveSession(
              accessToken: data['accessToken'] as String,
              refreshToken: data['refreshToken'] as String,
            );

            final newToken = await WebTokenStorage.getAccessToken();
            if (newToken != null) {
              err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            }
            final retryResponse = await _dio.fetch(err.requestOptions);
            handler.resolve(retryResponse);
            return;
          }
        } catch (_) {
          await WebTokenStorage.clearSession();
        } finally {
          _isRefreshing = false;
        }
      }
    }
    handler.next(err);
  }
}
