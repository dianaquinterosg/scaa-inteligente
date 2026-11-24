import 'dart:convert';
import 'dart:io';

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message, {this.detail});
  final int statusCode;
  final String message;
  final Map<String, dynamic>? detail;
  @override
  String toString() => message;
}

class BackendClient {
  BackendClient({String? baseUrl})
    : baseUri = Uri.parse(
        baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://localhost:8000',
            ),
      );
  final Uri baseUri;

  Future<Object?> requestJson(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Duration responseTimeout = const Duration(seconds: 5),
  }) async {
    if (!['http', 'https'].contains(baseUri.scheme) || baseUri.host.isEmpty) {
      throw const FormatException('API_BASE_URL debe ser una URL HTTP o HTTPS');
    }
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final request = await client.openUrl(method, baseUri.resolve(path));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }
      final response = await request.close().timeout(responseTimeout);
      final text = await utf8.decoder
          .bind(response)
          .join()
          .timeout(responseTimeout);
      if (response.statusCode == HttpStatus.noContent) return null;
      final data = jsonDecode(text);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail = data is Map<String, dynamic> ? data['detail'] : null;
        final message = detail is String
            ? detail
            : detail is Map<String, dynamic> && detail['message'] is String
            ? detail['message'] as String
            : detail is List
            ? detail
                  .map(
                    (item) => item is Map
                        ? item['msg'].toString()
                        : 'Entrada no válida',
                  )
                  .join('. ')
            : 'No se pudo completar la solicitud';
        throw ApiException(
          response.statusCode,
          message,
          detail: detail is Map<String, dynamic> ? detail : null,
        );
      }
      return data;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> check() async {
    final data = await requestJson('GET', '/api/v1/health');
    if (data is! Map<String, dynamic> ||
        data['status'] != 'ok' ||
        data['database'] != 'ok') {
      throw const FormatException('Respuesta de salud no válida');
    }
  }
}
