import 'dart:io';

import 'package:scaa_inteligente/backend_client.dart';

Future<void> main(List<String> args) async {
  try {
    final client = BackendClient(baseUrl: args.isEmpty ? null : args.first);
    await client.check();
    stdout.writeln('Conexión Dart → FastAPI → SQLite verificada.');
  } catch (error) {
    stderr.writeln('Falló la comprobación: $error');
    exitCode = 1;
  }
}
