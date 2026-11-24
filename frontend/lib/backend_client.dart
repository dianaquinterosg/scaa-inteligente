import 'dart:convert';
import 'dart:io';

/// Comprueba el contrato técnico de salud sin acceder a datos personales.
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

  Future<void> check() async {
    if (!['http', 'https'].contains(baseUri.scheme) || baseUri.host.isEmpty) {
      throw const FormatException('API_BASE_URL debe ser una URL HTTP o HTTPS');
    }
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final request = await client.getUrl(baseUri.resolve('/api/v1/health'));
      final response = await request.close().timeout(
        const Duration(seconds: 5),
      );
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('El servidor no está disponible');
      }
      final body = await utf8.decoder
          .bind(response)
          .join()
          .timeout(const Duration(seconds: 5));
      final data = jsonDecode(body);
      if (data is! Map<String, dynamic> ||
          data['status'] != 'ok' ||
          data['database'] != 'ok') {
        throw const FormatException('Respuesta de salud no válida');
      }
    } finally {
      client.close(force: true);
    }
  }
}
