class AuthInterceptor {
  Future<Map<String, String>> injectToken(
    Map<String, String> headers, {
    required String? token,
  }) async {
    if (token == null || token.isEmpty) return headers;
    return {
      ...headers,
      'Authorization': 'Bearer $token',
    };
  }
}
