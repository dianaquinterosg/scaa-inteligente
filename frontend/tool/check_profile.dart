import 'dart:convert';
import 'dart:io';

import 'package:scaa_inteligente/backend_client.dart';
import 'package:scaa_inteligente/profile.dart';

/// Sonda destructiva solo sobre el backend de prueba aislado del ejecutor Python.
Future<void> main(List<String> args) async {
  final results = <Map<String, String>>[];
  void check(bool condition, String id) {
    if (!condition) throw StateError('Falló $id');
    results.add({'id': id, 'result': 'passed'});
  }

  try {
    if (args.length != 1) {
      throw ArgumentError('Se requiere la URL del backend de prueba aislado');
    }
    final api = ProfileApi(client: BackendClient(baseUrl: args.single));
    check(await api.load() == null, 'I1-LIVE-01-perfil-ausente');
    final saved = await api.save(
      ProfileData(
        alias: '  Perfil de prueba  ',
        interests: [' Agua ', 'Música'],
        activities: ['Agua'],
        frequentRoutines: [' Lectura '],
      ),
    );
    check(
      saved.alias == 'Perfil de prueba' &&
          saved.interests.first == 'Agua' &&
          saved.activities.single == 'Agua' &&
          saved.frequentRoutines.single == 'Lectura',
      'I1-LIVE-02-creacion-normalizada',
    );
    check(
      jsonEncode((await api.load())!.toJson()) == jsonEncode(saved.toJson()),
      'I1-LIVE-03-recuperacion',
    );
    final edited = await api.save(
      ProfileData(alias: 'Perfil editado', interests: ['Pintura']),
    );
    check(
      edited.interests.single == 'Pintura' &&
          edited.activities.isEmpty &&
          edited.frequentRoutines.isEmpty,
      'I1-LIVE-04-edicion-eliminacion',
    );
    var rejected = false;
    try {
      await api.save(
        ProfileData(alias: 'No confirmado', interests: ['Agua', ' agua ']),
      );
    } on ApiException catch (error) {
      rejected = error.statusCode == 422;
    }
    check(rejected, 'I1-LIVE-05-rechazo-duplicados');
    check(
      jsonEncode((await api.load())!.toJson()) == jsonEncode(edited.toJson()),
      'I1-LIVE-06-estado-confirmado-intacto',
    );
    final reopened = ProfileApi(client: BackendClient(baseUrl: args.single));
    check(
      (await reopened.load())!.alias == 'Perfil editado',
      'I1-LIVE-07-cliente-nuevo',
    );
    stdout.writeln(jsonEncode({'status': 'passed', 'tests': results}));
  } catch (error) {
    stdout.writeln(
      jsonEncode({
        'status': 'failed',
        'tests': results,
        'error': error.toString(),
      }),
    );
    exitCode = 1;
  }
}
