import 'dart:convert';

import 'package:http/http.dart' as http;

import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'archivo_binario.dart';
import 'api_response.dart';

class ApiClient {
  final http.Client _client;
  final TokenStorage _tokenStorage;

  ApiClient({http.Client? client, TokenStorage? tokenStorage})
    : _client = client ?? http.Client(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (requiresAuth) {
      final token = await _tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<dynamic> get(String url, {bool requiresAuth = true}) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await _client.get(Uri.parse(url), headers: headers);
      return _processResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> post(
    String url, {
    dynamic body,
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await _client.post(
        Uri.parse(url),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> put(
    String url, {
    dynamic body,
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await _client.put(
        Uri.parse(url),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> patch(
    String url, {
    dynamic body,
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await _client.patch(
        Uri.parse(url),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> delete(String url, {bool requiresAuth = true}) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await _client.delete(Uri.parse(url), headers: headers);
      return _processResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  /// GET que además expone las cabeceras de la respuesta (p. ej. X-Total-Count).
  Future<ApiResponse> getWithHeaders(
    String url, {
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await _client.get(Uri.parse(url), headers: headers);
      return ApiResponse(
        body: _processResponse(response),
        headers: response.headers,
      );
    } catch (e) {
      _handleError(e);
    }
  }

  /// GET de un archivo binario (PDF, XLSX, imagen) con el token Bearer.
  /// Los errores JSON del backend se convierten en [ApiException].
  Future<ArchivoBinario> getBytes(
    String url, {
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      headers['Accept'] = '*/*';
      final response = await _client.get(Uri.parse(url), headers: headers);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _processResponse(response);
      }
      final mime = (response.headers['content-type'] ?? '')
          .split(';')
          .first
          .trim();
      return ArchivoBinario(
        bytes: response.bodyBytes,
        mime: mime.isEmpty ? 'application/octet-stream' : mime,
        nombre: ArchivoBinario.nombreDesdeDisposition(
          response.headers['content-disposition'],
        ),
      );
    } catch (e) {
      _handleError(e);
    }
  }

  /// POST con cuerpo crudo (sin codificar a JSON), p. ej. un CSV `text/csv`.
  Future<dynamic> postRaw(
    String url, {
    required String body,
    String contentType = 'text/plain',
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      headers['Content-Type'] = contentType;
      final response = await _client.post(
        Uri.parse(url),
        headers: headers,
        body: utf8.encode(body),
      );
      return _processResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> postMultipart(
    String url, {
    required List<int> fileBytes,
    required String filename,
    String fieldName = 'file',
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse(url);
      final request = http.MultipartRequest('POST', uri);
      if (requiresAuth) {
        final token = await _tokenStorage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }
      request.files.add(
        http.MultipartFile.fromBytes(fieldName, fileBytes, filename: filename),
      );
      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  /// POST multipart que devuelve un archivo (p. ej. el diagnóstico de una carga).
  Future<ArchivoBinario> postMultipartBytes(
    String url, {
    required List<int> fileBytes,
    required String filename,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      final token = await _tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: filename),
      );
      final response = await http.Response.fromStream(
        await _client.send(request),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _processResponse(response);
      }
      final mime = (response.headers['content-type'] ?? '')
          .split(';')
          .first
          .trim();
      return ArchivoBinario(
        bytes: response.bodyBytes,
        mime: mime.isEmpty ? 'application/octet-stream' : mime,
        nombre: ArchivoBinario.nombreDesdeDisposition(
          response.headers['content-disposition'],
        ),
      );
    } catch (e) {
      _handleError(e);
    }
  }

  dynamic _processResponse(http.Response response) {
    final statusCode = response.statusCode;
    final bodyString = response.body;
    dynamic bodyJson;

    if (bodyString.isNotEmpty) {
      try {
        bodyJson = jsonDecode(bodyString);
      } catch (_) {
        bodyJson = bodyString;
      }
    }

    if (statusCode >= 200 && statusCode < 300) {
      return bodyJson;
    }

    String message = 'Error en el servidor ($statusCode)';
    if (bodyJson is Map && bodyJson.containsKey('mensaje')) {
      message = bodyJson['mensaje'].toString();
    } else if (bodyJson is Map && bodyJson.containsKey('error')) {
      message = bodyJson['error'].toString();
    } else if (bodyJson is Map && bodyJson.containsKey('message')) {
      message = bodyJson['message'].toString();
    }

    if (statusCode == 401 || statusCode == 403) {
      throw AuthException(
        message: message,
        statusCode: statusCode,
        details: bodyJson,
      );
    }

    throw ApiException(
      message: message,
      statusCode: statusCode,
      details: bodyJson,
    );
  }

  Never _handleError(dynamic error) {
    if (error is ApiException) {
      throw error;
    }
    throw NetworkException(
      message: 'No se pudo conectar con el servidor: $error',
    );
  }
}
