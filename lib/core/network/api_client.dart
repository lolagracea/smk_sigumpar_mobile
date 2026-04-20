import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_endpoints.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, String>> _headers() async {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Uri _uri(String path) => Uri.parse('${ApiEndpoints.baseUrl}$path');

  Future<http.Response> get(String path) async {
    return _client.get(_uri(path), headers: await _headers());
  }

  Future<http.Response> post(String path, {Object? body}) async {
    return _client.post(
      _uri(path),
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );
  }

  Future<http.Response> put(String path, {Object? body}) async {
    return _client.put(
      _uri(path),
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );
  }

  Future<http.Response> delete(String path) async {
    return _client.delete(_uri(path), headers: await _headers());
  }
}
