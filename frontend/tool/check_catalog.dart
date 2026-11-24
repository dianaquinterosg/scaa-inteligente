import 'dart:convert';
import 'dart:io';

import 'package:scaa_inteligente/backend_client.dart';
import 'package:scaa_inteligente/pictograms/catalog_api.dart';

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    throw ArgumentError('Indica la URL del servidor de prueba');
  }
  final client = BackendClient(baseUrl: args.single);
  final api = CatalogApi(client);
  final tests = <String>[];
  final health = await client.requestJson('GET', '/api/v1/health') as Map;
  check(
    health['environment'] == 'test' && (await api.list()).isEmpty,
    'Se requiere una base de prueba vacía',
  );
  await api.saveCategory('Higiene');
  await api.saveCategory('Casa');
  final groups = await api.categories();
  final selected = groups.map((group) => group.id).toList();
  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAIAAABLbSncAAAAFElEQVR4nGNkYPjPgA0wYRUdtBIAy0MBD1YkjLoAAAAASUVORK5CYII=',
  );
  await api.save('Agua local', selected, image: png);
  final local = await api.search('agua');
  check(
    local.local.length == 1 && local.remoteStatus == 'not_requested',
    'No se priorizó el catálogo local',
  );
  final own = local.local.single;
  check(
    (await api.preview(own)).length == png.length,
    'La imagen propia no fue recuperada',
  );
  check(
    (await api.list(categoryId: selected.first)).single.id == own.id,
    'Falló el filtro de categoría',
  );
  tests.add('I2-HTTP-01-importacion-filtro-local');
  final alternatives = await api.search('agua', alternatives: true);
  check(
    alternatives.remoteStatus == 'available' && alternatives.remote.isNotEmpty,
    'No se obtuvieron alternativas reales de ARASAAC',
  );
  final candidate = alternatives.remote.first;
  final preview = await api.preview(candidate);
  check(
    preview.isNotEmpty && candidate.attribution!.contains('CC BY-NC-SA'),
    'Falta imagen o atribución de ARASAAC',
  );
  check(
    (await api.list()).length == 1,
    'La consulta incorporó un candidato sin aprobación',
  );
  tests.add('I2-HTTP-02-arasaac-real-vista-previa');
  await api.save(candidate.label, selected, item: candidate);
  final reopened = CatalogApi(BackendClient(baseUrl: args.single));
  final remote = (await reopened.list()).singleWhere(
    (item) => item.externalId == candidate.externalId,
  );
  check(
    (await reopened.preview(remote)).length == preview.length &&
        remote.categoryIds.length == 2,
    'No se recuperó el candidato confirmado',
  );
  try {
    await api.save(candidate.label, [], item: candidate);
    throw StateError('Se permitió duplicar la referencia');
  } on ApiException catch (error) {
    check(error.statusCode == 409, 'La respuesta de duplicado fue inesperada');
  }
  tests.add('I2-HTTP-03-confirmacion-recuperacion-duplicado');
  await api.save('Agua aprobada', selected, item: remote);
  await api.saveCategory('Aseo', id: selected.last);
  await api.deleteCategory(selected.first);
  final filtered = await api.list(categoryId: selected.last);
  check(
    filtered.length == 2 &&
        filtered.every((item) => item.categoryIds.length == 1),
    'Eliminar una categoría modificó otros recursos',
  );
  check(
    (await api.categories()).single.name == 'Aseo',
    'La categoría no se renombró',
  );
  await api.delete(own.id!);
  check(
    (await api.list()).single.label == 'Agua aprobada',
    'El borrado afectó otro pictograma',
  );
  tests.add('I2-HTTP-04-edicion-y-eliminacion');
  stdout.writeln(
    jsonEncode({
      'status': 'passed',
      'tests': [
        for (final id in tests) {'id': id, 'result': 'passed'},
      ],
      'arasaac': {
        'query': 'agua',
        'candidate_count': alternatives.remote.length,
        'sample_id': candidate.externalId,
        'image_bytes': preview.length,
      },
    }),
  );
}
