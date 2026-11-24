import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scaa_inteligente/backend_client.dart';
import 'package:scaa_inteligente/design/scaa_theme.dart';
import 'package:scaa_inteligente/pictograms/catalog_api.dart';
import 'package:scaa_inteligente/routines/routine_api.dart';
import 'package:scaa_inteligente/routines/routine_editor.dart';
import 'package:scaa_inteligente/routines/routines_screen.dart';

import 'pictogram_test.dart' show FakeCatalog;

const savedPicture = Pictogram(
  id: 1,
  label: 'Agua local',
  imagePath: '/agua.png',
);
const externalPicture = Pictogram(
  externalId: 42,
  label: 'Toalla ARASAAC',
  imagePath: '/remote.png',
  attribution: 'ARASAAC',
);

class FakeRoutines implements RoutineStore {
  final List<RoutineData> saved = [];
  final Completer<RoutineData> generation = Completer();
  int generateCalls = 0;
  int saveCalls = 0;
  int deleted = 0;
  bool failSave = false;

  @override
  Future<List<RoutineData>> list() async => [...saved];
  @override
  Future<RoutineData> get(int id) async =>
      saved.singleWhere((item) => item.id == id);
  @override
  Future<RoutineData> generate(String description) {
    generateCalls++;
    return generation.future;
  }

  @override
  Future<RoutineData> save(RoutineData routine) async {
    saveCalls++;
    if (failSave) {
      throw const ApiException(503, 'Falló el almacenamiento. Reintenta.');
    }
    final copy = RoutineData(
      id: routine.id ?? 1,
      name: routine.name.trim(),
      description: routine.description,
      steps: routine.steps.map((step) => step.copy()).toList(),
    );
    saved.removeWhere((item) => item.id == copy.id);
    saved.add(copy);
    return copy;
  }

  @override
  Future<void> delete(int id) async {
    deleted++;
    saved.removeWhere((item) => item.id == id);
  }
}

FakeCatalog catalog() => FakeCatalog()..entries.add(savedPicture);

Future<void> showScreen(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(1000, 1700),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(theme: ScaaTheme.light, home: child));
  await tester.pumpAndSettle();
}

Future<void> hit(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find
          .descendant(
            of: find.byType(RoutineEditor),
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.45);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> hitText(WidgetTester tester, String label) {
  final matches = find.text(label);
  return hit(tester, matches.evaluate().length > 1 ? matches.last : matches);
}

Finder stepButton(String name) => find.byWidgetPredicate(
  (widget) => widget is IconButton && widget.tooltip == name,
);

RoutineData proposal() => RoutineData(
  name: 'Lavarse las manos',
  description: 'Higiene',
  steps: [
    RoutineStep(
      label: 'Secar las manos',
      pictogram: externalPicture,
      candidates: [externalPicture],
      association: 'arasaac',
    ),
  ],
);

void main() {
  testWidgets(
    'CU03 valida descripción, muestra generación y cancela propuesta sin guardar',
    (tester) async {
      final store = FakeRoutines();
      await showScreen(
        tester,
        RoutinesScreen(store: store, administration: true, catalog: catalog()),
      );
      await hitText(tester, 'Crear rutina');
      await hitText(tester, 'Generar propuesta');
      expect(find.text('Ingresa una descripción.'), findsOneWidget);
      expect(store.generateCalls, 0);
      await tester.enterText(find.byType(TextFormField), 'Higiene');
      await tester.tap(find.text('Generar propuesta'));
      await tester.pump();
      expect(find.text('Generando propuesta…'), findsOneWidget);
      store.generation.complete(proposal());
      await tester.pumpAndSettle();
      expect(find.text('Candidato pendiente de revisión'), findsOneWidget);
      await hitText(tester, 'Guardar rutina');
      expect(
        find.textContaining('Selecciona y aprueba un pictograma'),
        findsOneWidget,
      );
      expect(store.saveCalls, 0);
      await hitText(tester, 'Cancelar');
      expect(find.text('Generar propuesta'), findsOneWidget);
      expect(store.saved, isEmpty);
    },
  );

  testWidgets(
    'CU03 pasa de un fallo IA al editor manual y confirma con pictograma local',
    (tester) async {
      final store = FakeRoutines();
      await showScreen(
        tester,
        RoutinesScreen(store: store, administration: true, catalog: catalog()),
      );
      await hitText(tester, 'Crear rutina');
      await tester.enterText(find.byType(TextFormField), 'Higiene');
      await tester.tap(find.text('Generar propuesta'));
      await tester.pump();
      store.generation.completeError(
        const ApiException(504, 'La generación tardó demasiado.'),
      );
      await tester.pumpAndSettle();
      expect(find.text('La generación tardó demasiado.'), findsOneWidget);
      await hitText(tester, 'Crear manualmente');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre'),
        'Rutina manual',
      );
      await tester.enterText(
        find.byKey(const ValueKey('routine-step-label-0')),
        'Beber',
      );
      await hitText(tester, 'Elegir pictograma');
      await hitText(tester, 'Usar este pictograma');
      await hitText(tester, 'Guardar rutina');
      expect(find.text('Confirmar rutina'), findsOneWidget);
      expect(store.saved, isEmpty);
      await hitText(tester, 'Confirmar guardado');
      expect(store.saved.single.steps.single.pictogram?.id, 1);
      expect(find.text('Rutina guardada.'), findsOneWidget);
    },
  );

  testWidgets(
    'CU03 edita, reemplaza, reordena y conserva el borrador si falla el guardado',
    (tester) async {
      final store = FakeRoutines()..failSave = true;
      final first = proposal().steps.single;
      final initial = RoutineData(
        name: 'Higiene',
        steps: [
          first,
          RoutineStep(
            label: 'Enjuagar',
            pictogram: savedPicture,
            approved: true,
          ),
        ],
      );
      await showScreen(
        tester,
        RoutineEditor(
          store: store,
          catalog: catalog(),
          initial: initial,
          generated: true,
        ),
      );
      await hit(tester, find.byKey(const ValueKey('routine-picture-0')));
      final localRow = find
          .ancestor(
            of: find.text(savedPicture.label),
            matching: find.byType(Row),
          )
          .first;
      await hit(
        tester,
        find.descendant(
          of: localRow,
          matching: find.text('Usar este pictograma'),
        ),
      );
      await hit(tester, stepButton('Subir paso 2'));
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('routine-step-label-0')),
            )
            .initialValue,
        'Enjuagar',
      );
      await tester.enterText(
        find.byKey(const ValueKey('routine-step-label-0')),
        'Enjuagar manos',
      );
      await hit(
        tester,
        find.byKey(const ValueKey('routine-approve-picture-0')),
      );
      await hitText(tester, 'Agregar paso');
      await hit(tester, stepButton('Eliminar paso 3'));
      expect(find.text('Paso 3'), findsNothing);
      await hitText(tester, 'Guardar rutina');
      expect(find.text('Confirmar rutina'), findsOneWidget);
      await hitText(tester, 'Confirmar guardado');
      expect(find.text('Falló el almacenamiento. Reintenta.'), findsOneWidget);
      expect(store.saved, isEmpty);
      expect(first.pictogram?.externalId, 42);
      store.failSave = false;
      await hitText(tester, 'Guardar rutina');
      await hitText(tester, 'Confirmar guardado');
      expect(store.saved.single.steps.map((step) => step.label), [
        'Enjuagar manos',
        'Secar las manos',
      ]);
      expect(store.saved.single.steps.map((step) => step.pictogram?.id), [
        1,
        1,
      ]);
    },
  );

  testWidgets('CU03 consulta y elimina con confirmación en tablet horizontal', (
    tester,
  ) async {
    final store = FakeRoutines()
      ..saved.add(
        RoutineData(
          id: 3,
          name: 'Rutina guardada de prueba',
          steps: [
            RoutineStep(
              label: 'Beber',
              pictogram: savedPicture,
              approved: true,
            ),
          ],
        ),
      );
    final pictures = catalog();
    await showScreen(
      tester,
      RoutinesScreen(store: store, administration: true, catalog: pictures),
      size: const Size(1180, 820),
    );
    await hitText(tester, 'Rutina guardada de prueba');
    expect(find.text('Editar rutina'), findsOneWidget);
    await hitText(tester, 'Eliminar rutina');
    await hitText(tester, 'Cancelar');
    expect(store.deleted, 0);
    await hitText(tester, 'Eliminar rutina');
    await hitText(tester, 'Eliminar');
    expect(find.text('Rutina eliminada.'), findsOneWidget);
    expect(store.deleted, 1);
    expect(pictures.entries.single.id, 1);
    expect(tester.takeException(), isNull);
  });
}
