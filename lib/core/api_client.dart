import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient(this.baseUrl, {this.onUnauthorized});

  final String baseUrl;
  final VoidCallback? onUnauthorized;
  String? accessToken;
  String? refreshToken;

  Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };

  Future<Map<String, dynamic>> get(String path, [Map<String, dynamic>? queryParameters]) async {
    final stringQueryParameters = queryParameters?.map((key, value) => MapEntry(key, value.toString()));
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: stringQueryParameters?.isEmpty ?? true ? null : stringQueryParameters,
    );
    
    debugPrint('🌐 API GET: $path');
    
    final response = await http.get(uri, headers: _headers());
    return _decode(response);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    
    debugPrint('🌐 API POST: $path');
    
    final response = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    
    debugPrint('🌐 API PUT: $path');
    
    final response = await http.put(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> uploadFile(
      String path, String fileField, List<int> fileBytes, String filename,
      [Map<String, String>? fields]) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('POST', uri);
    if (accessToken != null) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }
    
    if (fields != null) {
      request.fields.addAll(fields);
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        fileField,
        fileBytes,
        filename: filename,
      ),
    );
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode == 401) {
      onUnauthorized?.call();
      throw UnauthorizedException('Session expired or unauthorized. Please login again.');
    }

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 400) {
        throw Exception(decoded['message'] ?? 'API error ${response.statusCode}');
      }
      return decoded;
    } catch (e) {
      if (e is UnauthorizedException) rethrow;
      if (response.statusCode >= 400) {
        throw Exception('Server Error ${response.statusCode}: Hostinger returned HTML instead of JSON.');
      }
      throw Exception('Failed to decode JSON: $e');
    }
  }
}

