import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:royal_airlines/core/config/app_config.dart';
import 'package:royal_airlines/services/session_storage.dart';

/// ApiClient
/// ---------
/// Client base para todas las llamadas al backend. Mantiene un único
/// punto de entrada para endpoints, parsing y manejo de errores, de modo
/// que la UI y los servicios no tengan logica de red mezclada.
///
/// Toda petición real (GET/POST/PUT) pasa por [_send], que aplica un
/// timeout y traduce errores de bajo nivel (sin internet, DNS,
/// conexión rechazada, timeout) a un [ApiException] con un mensaje que
/// la UI puede mostrar directamente, en vez de dejar que la excepción
/// cruda (`SocketException`, `TimeoutException`, etc.) llegue sin
/// envolver hasta la pantalla.
class ApiClient {
  ApiClient({String? baseUrl})
      : _baseUrl =
            (baseUrl ?? AppConfig.baseUrl).replaceAll(RegExp(r'/+$'), '');

  final String _baseUrl;

  static const Duration _timeout = Duration(seconds: 12);

  Uri _uri(String path, [Map<String, String>? queryParameters]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$_baseUrl$normalizedPath');
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }
    return uri.replace(queryParameters: queryParameters);
  }

  Future<Map<String, String>> _defaultHeaders({
    Map<String, String>? headers,
  }) async {
    final token = await SessionStorage().loadToken();
    return <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      ...?headers,
    };
  }

  /// Ejecuta [request] con timeout y traduce cualquier error de red de
  /// bajo nivel a [ApiException], para que quien llame (controllers)
  /// solo tenga que capturar un único tipo de excepción conocido.
  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(_timeout);
    } on TimeoutException {
      throw const ApiException(
        'El servidor tardó demasiado en responder. Intenta de nuevo.',
      );
    } on SocketException {
      throw const ApiException(
        'No hay conexión a internet. Verifica tu red e intenta de nuevo.',
      );
    } on HttpException {
      throw const ApiException(
        'No se pudo conectar con el servidor. Intenta más tarde.',
      );
    } on http.ClientException {
      throw const ApiException(
        'No se pudo conectar con el servidor. Intenta más tarde.',
      );
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException('Ocurrió un error inesperado: $error');
    }
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    if (AppConfig.useMockApi) {
      return _mockResponse('GET', path,
          queryParameters: queryParameters, headers: headers);
    }

    final response = await _send(() async => http.get(
          _uri(path, queryParameters),
          headers: await _defaultHeaders(headers: headers),
        ));
    return _decodeResponse(response, path: path, method: 'GET');
  }

  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    if (AppConfig.useMockApi) {
      return _mockResponse('POST', path, body: body, headers: headers);
    }

    final response = await _send(() async => http.post(
          _uri(path),
          headers: await _defaultHeaders(headers: headers),
          body: jsonEncode(body),
        ));
    return _decodeResponse(response, path: path, method: 'POST');
  }

  Future<Map<String, dynamic>> put(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    if (AppConfig.useMockApi) {
      return _mockResponse('PUT', path, body: body, headers: headers);
    }

    final response = await _send(() async => http.put(
          _uri(path),
          headers: await _defaultHeaders(headers: headers),
          body: jsonEncode(body),
        ));
    return _decodeResponse(response, path: path, method: 'PUT');
  }

  Map<String, dynamic> _mockResponse(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) {
    final uri = _uri(path, queryParameters);
    return {
      'success': true,
      'message': 'mock-api-enabled',
      'method': method,
      'url': uri.toString(),
      'headers': headers ?? const <String, String>{},
      'body': body ?? <String, dynamic>{},
      'data': <String, dynamic>{
        'status': 'mock-success',
      },
    };
  }

  Map<String, dynamic> _decodeResponse(
    http.Response response, {
    required String path,
    required String method,
  }) {
    if (response.body.isEmpty) {
      return {'success': true, 'method': method, 'path': path, 'data': null};
    }

    late final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const ApiException(
          'La respuesta del backend no tiene formato JSON válido');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const ApiException(
          'La respuesta del backend no tiene formato JSON válido');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorMessage =
          decoded['message'] ?? 'Error inesperado del servidor';
      throw ApiException(errorMessage, statusCode: response.statusCode);
    }

    return decoded;
  }
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException: $message';
}
