import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scaa_inteligente/backend_client.dart';
import 'package:scaa_inteligente/design/scaa_theme.dart';
import 'package:scaa_inteligente/pictograms/catalog_api.dart';
import 'package:scaa_inteligente/pictograms/pictogram_screen.dart';

final png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAIAAABLbSncAAAAFElEQVR4nGNkYPjPgA0wYRUdtBIAy0MBD1YkjLoAAAAASUVORK5CYII=',
);

class FakeCatalog implements CatalogStore {
  final entries = <Pictogram>[];
  List<Category> groups = [
    const Category(1, 'Higiene'),
    const Category(2, 'Casa'),
  ];
  int saves = 0;
  int searchCalls = 0;
  int? lastFilter;
  bool unavailable = false;
  bool failSave = false;
  bool referenced = false;

  static const candidate = Pictogram(
    externalId: 123,
    label: 'Agua ARASAAC',
    imagePath: '/remote.png',
    attribution: 'Sergio Palao · Gobierno de Aragón · ARASAAC · CC BY-NC-SA',
  );

  @override
  Future<List<Category>> categories() async => [...groups];

  @override
  Future<List<Pictogram>> list({int? categoryId}) async {
    lastFilter = categoryId;
    return entries
        .where(
          (item) => categoryId == null || item.categoryIds.contains(categoryId),
        )
        .toList();
  }

  @override
  Future<CatalogSearch> search(
    String query, {
    int? categoryId,
    bool alternatives = false,
  }) async {
    searchCalls++;
    final local = (await list(categoryId: categoryId))
        .where((item) => item.label.toLowerCase().contains(query.toLowerCase()))
        .toList();
    if (categoryId != null || (local.isNotEmpty && !alternatives)) {
      return CatalogSearch(local, [], 'not_requested');
    }
    return unavailable
        ? CatalogSearch(local, [], 'unavailable')
        : CatalogSearch(local, [candidate], 'available');
  }

  @override
  Uri imageUrl(Pictogram item) =>
      Uri.parse('https://example.invalid${item.imagePath}');
  @override
  Future<Uint8List> preview(Pictogram item) async => png;
  @override
  Future<void> save(
    String label,
    List<int> categories, {
    Pictogram? item,
    Uint8List? image,
  }) async {
    saves++;
    if (failSave) throw const ApiException(503, 'Fallo de almacenamiento.');
    final id = item?.id ?? entries.length + 1;
    entries.removeWhere((value) => value.id == id);
    entries.add(
      Pictogram(
        id: id,
        label: label,
        externalId: item?.externalId,
        categoryIds: categories,
        imagePath: '/$id.png',
        attribution: item?.attribution,
      ),
    );
  }

  @override
  Future<void> delete(int id) async {
    if (referenced) {
      throw const ApiException(409, 'Una rutina usa este pictograma.');
    }
    entries.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> saveCategory(String name, {int? id}) async {
    if (groups.any(
      (group) =>
          group.id != id && group.name.toLowerCase() == name.toLowerCase(),
    )) {
      throw const ApiException(409, 'Ya existe una categoría con ese nombre.');
    }
    final identifier = id ?? groups.length + 1;
    groups = [
      ...groups.where((group) => group.id != identifier),
      Category(identifier, name),
    ];
  }

  @override
  Future<void> deleteCategory(int id) async {
    groups = groups.where((group) => group.id != id).toList();
  }
}

Future<void> open(
  WidgetTester tester,
  FakeCatalog store, {
  Size size = const Size(820, 1180),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: ScaaTheme.light,
      home: PictogramScreen(
        store: store,
        administration: true,
        chooseFile: () async => png,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, String text) async {
  final target = find.text(text).last;
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> openPreview(WidgetTester tester, String action) async {
  final target = find.text(action).last;
  await tester.ensureVisible(target);
  await tester.tap(target);
  final preview = find.byWidgetPredicate(
    (widget) =>
        widget is Image &&
        widget.semanticLabel == 'Vista previa del pictograma',
  );
  // La decodificación usa el motor. Solo se espera esa parte con el reloj real.
  await tester.runAsync(() async {
    for (var i = 0; i < 100 && preview.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });
  await tester.pumpAndSettle();
  expect(preview, findsOneWidget);
}

void main() {
  testWidgets(
    'CU02 busca primero en catálogo, ofrece ARASAAC y rechaza sin guardar',
    (tester) async {
      final store = FakeCatalog();
      await store.save('Agua local', [1], image: png);
      await open(tester, store);
      await tap(tester, 'Buscar');
      expect(find.text('Ingresa una descripción.'), findsOneWidget);
      expect(store.searchCalls, 0);
      await tester.enterText(find.byType(TextFormField), 'Agua');
      await tap(tester, 'Buscar');
      expect(find.text('Agua local'), findsOneWidget);
      expect(find.text('Alternativas de ARASAAC'), findsNothing);
      await tap(tester, 'Buscar alternativas en ARASAAC');
      expect(find.text('Agua ARASAAC'), findsOneWidget);
      await openPreview(tester, 'Revisar');
      expect(find.text('Vista previa'), findsOneWidget);
      expect(
        find.text('Sergio Palao · Gobierno de Aragón · ARASAAC · CC BY-NC-SA'),
        findsOneWidget,
      );
      await tap(tester, 'Rechazar');
      expect(store.saves, 1);
      expect(store.entries.single.label, 'Agua local');
    },
  );

  testWidgets(
    'CU02 importa durante fallo remoto, valida, conserva borrador y confirma',
    (tester) async {
      final store = FakeCatalog()..unavailable = true;
      await open(tester, store);
      await tester.enterText(find.byType(TextFormField), 'Agua');
      await tap(tester, 'Buscar');
      expect(find.textContaining('ARASAAC no está disponible'), findsOneWidget);
      expect(find.text('Reintentar ARASAAC'), findsOneWidget);
      await openPreview(tester, 'Importar imagen');
      expect(find.text('Imagen propia'), findsOneWidget);
      await tap(tester, 'Aprobar y guardar');
      expect(find.text('Ingresa una etiqueta.'), findsOneWidget);
      expect(store.saves, 0);
      await tester.enterText(find.byType(TextFormField), '  Beber agua  ');
      await tap(tester, 'Higiene');
      await tap(tester, 'Casa');
      store.failSave = true;
      await tap(tester, 'Aprobar y guardar');
      expect(find.text('Fallo de almacenamiento.'), findsOneWidget);
      expect(find.text('  Beber agua  '), findsOneWidget);
      expect(store.entries, isEmpty);
      store.failSave = false;
      await tap(tester, 'Aprobar y guardar');
      expect(store.entries.single.label, 'Beber agua');
      expect(store.entries.single.categoryIds, [1, 2]);
      expect(find.text('Pictograma guardado.'), findsOneWidget);
    },
  );

  testWidgets(
    'CU02 permite filtrar, editar asociaciones y eliminar con confirmación',
    (tester) async {
      final store = FakeCatalog();
      await store.save('Agua local', [1], image: png);
      await open(tester, store);
      await tap(tester, 'Casa');
      expect(store.lastFilter, 2);
      expect(find.text('Agua local'), findsNothing);
      await tap(tester, 'Higiene');
      expect(find.text('Agua local'), findsOneWidget);
      await openPreview(tester, 'Abrir');
      await tap(tester, 'Higiene');
      await tap(tester, 'Guardar cambios');
      expect(store.entries.single.categoryIds, isEmpty);
      await openPreview(tester, 'Abrir');
      await tap(tester, 'Eliminar pictograma');
      await tap(tester, 'Cancelar');
      expect(store.entries, hasLength(1));
      store.referenced = true;
      await tap(tester, 'Eliminar pictograma');
      await tap(tester, 'Eliminar');
      expect(find.text('Una rutina usa este pictograma.'), findsOneWidget);
      store.referenced = false;
      await tap(tester, 'Eliminar pictograma');
      await tap(tester, 'Eliminar');
      expect(store.entries, isEmpty);
    },
  );

  testWidgets(
    'CU02 crea, valida, renombra y confirma eliminación de categoría',
    (tester) async {
      final store = FakeCatalog();
      await open(tester, store, size: const Size(1180, 820));
      await tap(tester, 'Administrar categorías');
      await tap(tester, 'Guardar categoría');
      expect(find.text('Ingresa un nombre.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'higiene');
      await tap(tester, 'Guardar categoría');
      expect(
        find.text('Ya existe una categoría con ese nombre.'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextFormField), 'Colegio');
      await tap(tester, 'Guardar categoría');
      expect(store.groups.last.name, 'Colegio');
      await tester.tap(find.byTooltip('Renombrar Colegio'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Escuela');
      await tap(tester, 'Guardar categoría');
      expect(store.groups.last.name, 'Escuela');
      await tester.tap(find.byTooltip('Eliminar Escuela'));
      await tester.pumpAndSettle();
      await tap(tester, 'Eliminar');
      expect(store.groups.map((group) => group.name), ['Higiene', 'Casa']);
    },
  );
}
