import 'dart:convert';
import 'dart:io';

import 'package:scaa_inteligente/backend_client.dart';
import 'package:scaa_inteligente/pictograms/catalog_api.dart';
import 'package:scaa_inteligente/profile.dart';
import 'package:scaa_inteligente/routines/routine_api.dart';

Future<void> main(List<String> args) async {
  final events = <Map<String, String>>[];
  final proposals = <Map<String, Object?>>[];

  void check(bool ok, String id) {
    if (!ok) throw StateError(id);
    events.add({'id': id, 'result': 'passed'});
  }

  try {
    if (args.length != 1) {
      throw ArgumentError('Indica la URL del backend aislado');
    }
    final client = BackendClient(baseUrl: args.single);
    final health = await client.requestJson('GET', '/api/v1/health') as Map;
    final routines = RoutineApi(client);
    final profile = ProfileApi(client: client);
    final catalog = CatalogApi(client);
    if (health['environment'] != 'test' ||
        (await routines.list()).isNotEmpty ||
        await profile.load() != null) {
      throw StateError('Se requiere una base de prueba vacía');
    }
    await profile.save(
      ProfileData(
        alias: 'Perfil sintético',
        activities: ['Mochila azul', 'Pescar'],
        interests: ['Manzana'],
      ),
    );
    final descriptions = [
      'Lavarse las manos',
      'Preparar la mochila para el colegio',
      'Preparar una colación de manzana y agua',
    ];
    final candidates = <Pictogram>[];
    for (var i = 0; i < descriptions.length; i++) {
      final data = await routines.generate(descriptions[i]);
      final steps = data.steps;
      check(
        data.id == null &&
            steps.isNotEmpty &&
            steps.every((step) => !step.approved),
        'I3-HTTP-Ollama-${i + 1}',
      );
      candidates.addAll([
        for (final step in steps)
          ...step.candidates.where((item) => item.externalId != null),
      ]);
      proposals.add({
        'description': descriptions[i],
        'name': data.name,
        'steps': [
          for (var index = 0; index < steps.length; index++)
            {
              'order': index + 1,
              'label': steps[index].label,
              'search_term': steps[index].searchTerm,
              'association': steps[index].association,
              'candidates': steps[index].candidates.length,
              'proposed_external_id': steps[index].pictogram?.externalId,
              'approved': steps[index].approved,
            },
        ],
      });
    }
    check(
      (await routines.list()).isEmpty && (await catalog.list()).isEmpty,
      'I3-HTTP-propuestas-sin-escrituras',
    );
    check(candidates.isNotEmpty, 'I3-HTTP-ARASAAC-real-en-asociacion');
    final candidate = candidates.first;
    final image = await catalog.preview(candidate);
    check(image.isNotEmpty, 'I3-HTTP-vista-previa-externa');

    final routine = await routines.save(
      RoutineData(
        name: 'Guardar rutina de prueba',
        steps: [
          RoutineStep(
            label: 'Primer paso',
            pictogram: candidate,
            approved: true,
          ),
          RoutineStep(
            label: 'Repetir pictograma',
            pictogram: candidate,
            approved: true,
          ),
        ],
      ),
    );
    final saved = routine.steps.first.pictogram!;
    check(
      saved.id != null &&
          routine.steps.last.pictogram?.id == saved.id &&
          (await catalog.list()).length == 1,
      'I3-HTTP-confirmacion-y-reutilizacion',
    );
    try {
      await catalog.delete(saved.id!);
      throw StateError(
        'El catálogo permitió borrar un pictograma referenciado',
      );
    } on ApiException catch (error) {
      check(error.statusCode == 409, 'I3-HTTP-CA02.12-rutina-real');
    }
    final reopened = RoutineApi(BackendClient(baseUrl: args.single));
    check(
      (await reopened.get(routine.id!)).steps.length == 2,
      'I3-HTTP-recuperacion',
    );
    final edited = await reopened.save(
      RoutineData(
        id: routine.id,
        name: 'Editada',
        steps: [
          RoutineStep(label: 'Paso editado', pictogram: saved, approved: true),
        ],
      ),
    );
    check(
      edited.name == 'Editada' && edited.steps.single.label == 'Paso editado',
      'I3-HTTP-edicion',
    );
    await reopened.delete(routine.id!);
    check(
      (await reopened.list()).isEmpty &&
          (await catalog.list()).single.id == saved.id &&
          (await catalog.preview(saved)).length == image.length,
      'I3-HTTP-borrado-conserva-pictograma',
    );

    stdout.writeln(
      jsonEncode({
        'status': 'passed',
        'tests': events,
        'model_scenarios': proposals,
        'arasaac_sample': {
          'external_id': candidate.externalId,
          'image_bytes': image.length,
        },
      }),
    );
  } catch (error) {
    stdout.writeln(
      jsonEncode({
        'status': 'failed',
        'tests': events,
        'model_scenarios': proposals,
        'error': error.toString(),
      }),
    );
  }
}
