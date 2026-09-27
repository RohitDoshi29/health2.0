import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../core/config/api_constants.dart';
import '../../core/utils/token_storage.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiClient {
  static const Duration defaultTimeout = Duration(seconds: 20);
  static const Duration uploadTimeout = Duration(seconds: 60);

  final TokenStorage _tokenStorage;
  final http.Client _client;

  ApiClient({
    TokenStorage? tokenStorage,
    http.Client? client,
  })  : _tokenStorage = tokenStorage ?? TokenStorage(),
        _client = client ?? http.Client();

  Future<Map<String, String>> _getHeaders({bool isJson = true}) async {
    final headers = <String, String>{};
    if (isJson) {
      headers['Content-Type'] = 'application/json';
    }
    try {
      final token = await _tokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {}
    return headers;
  }

  Future<dynamic> get(String endpoint) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final headers = await _getHeaders();
      final response = await _client.get(uri, headers: headers).timeout(defaultTimeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(408, 'Connection timed out. The server is taking too long to respond.');
    } on SocketException {
      throw ApiException(503, 'Network unavailable. Please check your internet connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(500, 'Network request failed: ${e.toString()}');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final headers = await _getHeaders();
      final response = await _client
          .post(
            uri,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(defaultTimeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(408, 'Connection timed out. The server is taking too long to respond.');
    } on SocketException {
      throw ApiException(503, 'Network unavailable. Please check your internet connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(500, 'Network request failed: ${e.toString()}');
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final headers = await _getHeaders();
      final response = await _client
          .put(
            uri,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(defaultTimeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(408, 'Connection timed out. The server is taking too long to respond.');
    } on SocketException {
      throw ApiException(503, 'Network unavailable. Please check your internet connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(500, 'Network request failed: ${e.toString()}');
    }
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final headers = await _getHeaders();
      final response = await _client
          .patch(
            uri,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(defaultTimeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(408, 'Connection timed out. The server is taking too long to respond.');
    } on SocketException {
      throw ApiException(503, 'Network unavailable. Please check your internet connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(500, 'Network request failed: ${e.toString()}');
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final headers = await _getHeaders();
      final response = await _client.delete(uri, headers: headers).timeout(defaultTimeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(408, 'Connection timed out. The server is taking too long to respond.');
    } on SocketException {
      throw ApiException(503, 'Network unavailable. Please check your internet connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(500, 'Network request failed: ${e.toString()}');
    }
  }

  Future<dynamic> postMultipart(
    String endpoint, {
    required List<int> bytes,
    required String filename,
    required String fieldName,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final request = http.MultipartRequest('POST', uri);

      final headers = await _getHeaders(isJson: false);
      request.headers.addAll(headers);

      String extension = filename.split('.').last.toLowerCase();
      MediaType contentType;
      if (extension == 'png') {
        contentType = MediaType('image', 'png');
      } else if (extension == 'webp') {
        contentType = MediaType('image', 'webp');
      } else {
        contentType = MediaType('image', 'jpeg');
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          bytes,
          filename: filename,
          contentType: contentType,
        ),
      );

      final streamedResponse = await _client.send(request).timeout(uploadTimeout);
      final response = await http.Response.fromStream(streamedResponse).timeout(defaultTimeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(408, 'Upload timed out. Food analysis is taking longer than usual.');
    } on SocketException {
      throw ApiException(503, 'Network unavailable. Please check your internet connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(500, 'Upload failed: ${e.toString()}');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 204) {
      return null;
    }

    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      body = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    String errorDetail = 'Something went wrong (${response.statusCode})';
    if (body is Map && body.containsKey('detail')) {
      errorDetail = body['detail'].toString();
    }
    throw ApiException(response.statusCode, errorDetail);
  }
}

