import 'package:flutter_test/flutter_test.dart';
import 'package:scaa_inteligente/backend_client.dart';
import 'package:scaa_inteligente/pictograms/catalog_api.dart';
import 'package:scaa_inteligente/pictograms/pictogram_editor.dart';

import 'pictogram_test.dart' show FakeCatalog, open, openPreview, tap;

const message =
    'Retira este pictograma de las rutinas que lo usan antes de eliminarlo.';
const picture = Pictogram(id: 2, label: 'Agua', imagePath: '/agua.png');

class ConflictClient extends BackendClient {
  @override
  Future<Object?> requestJson(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Duration responseTimeout = const Duration(seconds: 5),
  }) async {
    expect(method, 'DELETE');
    expect(path, '/api/v1/pictograms/2');
    throw const ApiException(
      409,
      message,
      detail: {
        'code': 'pictogram_in_use',
        'message': message,
        'routines': [
          {'id': 8, 'name': 'Preparar mochila'},
          {'id': 12, 'name': 'Ir al colegio'},
        ],
      },
    );
  }
}

class ConflictCatalog extends FakeCatalog {
  @override
  Future<void> delete(int id) => CatalogApi(ConflictClient()).delete(id);
}

void main() {
  testWidgets(
    'El editor muestra las rutinas del conflicto estructurado y conserva la edición',
    (tester) async {
      final catalog = ConflictCatalog()..entries.add(picture);
      await open(tester, catalog);
      await openPreview(tester, 'Abrir');
      await tap(tester, 'Eliminar pictograma');
      await tap(tester, 'Eliminar');
      expect(find.text(message), findsOneWidget);
      expect(find.text('Preparar mochila'), findsOneWidget);
      expect(find.text('Rutina #8'), findsOneWidget);
      expect(find.text('Ir al colegio'), findsOneWidget);
      expect(find.text('Rutina #12'), findsOneWidget);
      expect(catalog.entries, [picture]);
      expect(find.byType(PictogramEditor), findsOneWidget);
    },
  );
}
