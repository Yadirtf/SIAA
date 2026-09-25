import 'dart:convert';

import 'package:http/http.dart' as http;

import '../storage/token_storage.dart';
import 'api_exception.dart';

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
