import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scaa_inteligente/main.dart';
import 'package:scaa_inteligente/pictograms/catalog_api.dart';
import 'package:scaa_inteligente/pictograms/pictogram_image.dart';
import 'package:scaa_inteligente/routines/routine_api.dart';
import 'package:scaa_inteligente/routines/routine_editor.dart';
import 'package:scaa_inteligente/routines/routine_viewer.dart';

import 'pictogram_test.dart' show FakeCatalog;
import 'profile_test.dart' show FakeStore, enterAdministration;
import 'routine_test.dart' show FakeRoutines, savedPicture;

RoutineData routine(int count) => RoutineData(
  id: count,
  name: 'Rutina de $count',
  steps: [
    for (var i = 1; i <= count; i++)
      RoutineStep(label: 'Acción $i', pictogram: savedPicture, approved: true),
  ],
);

class SlowRoutines extends FakeRoutines {
  final detail = Completer<RoutineData>();

  @override
  Future<RoutineData> get(int id) => detail.future;
}

Future<void> press(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Primer inicio: acceso deliberado, salida y nuevo inicio en visualización',
    (tester) async {
      final profile = FakeStore();
      final catalog = FakeCatalog();
      final routines = FakeRoutines();
      Widget app() => ScaaApp(
        key: UniqueKey(),
        profileStore: profile,
        catalogStore: catalog,
        routineStore: routines,
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('Modo visualización'), findsOneWidget);
      expect(find.text('Configurar perfil'), findsNothing);
      await press(tester, 'Acceso de administración');
      await press(tester, 'Cancelar');
      expect(find.text('Modo visualización'), findsOneWidget);
      await enterAdministration(tester);
      expect(find.text('Configurar perfil'), findsOneWidget);
      await press(tester, 'Cancelar');
      expect(find.text('Modo administración'), findsOneWidget);
      await press(tester, 'Volver a visualización');
      expect(find.text('Configurar perfil'), findsNothing);
      await enterAdministration(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('Modo visualización'), findsOneWidget);
      expect(profile.saves, 0);
    },
  );

  testWidgets(
    'Catálogo reutilizado en ambos modos con filtrado y controles solo administrativos',
    (tester) async {
      final catalog = FakeCatalog()
        ..entries.addAll([
          const Pictogram(
            id: 11,
            label: 'Jabón',
            imagePath: '/soap.png',
            categoryIds: [1],
          ),
          const Pictogram(
            id: 12,
            label: 'Mesa',
            imagePath: '/table.png',
            categoryIds: [2],
          ),
        ]);
      await tester.pumpWidget(
        ScaaApp(
          profileStore: FakeStore(),
          catalogStore: catalog,
          routineStore: FakeRoutines(),
        ),
      );
      await tester.pumpAndSettle();
      await press(tester, 'Pictogramas');
      expect(find.text('Jabón'), findsOneWidget);
      expect(find.text('Mesa'), findsOneWidget);
      expect(find.text('Abrir'), findsNothing);
      expect(find.text('Importar imagen'), findsNothing);
      expect(find.text('Administrar categorías'), findsNothing);
      await press(tester, 'Higiene');
      expect(catalog.lastFilter, 1);
      expect(find.text('Jabón'), findsOneWidget);
      expect(find.text('Mesa'), findsNothing);
      expect(catalog.searchCalls, 0);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await enterAdministration(tester);
      await press(tester, 'Cancelar');
      await press(tester, 'Pictogramas');
      expect(find.text('Abrir'), findsWidgets);
      expect(find.text('Importar imagen'), findsOneWidget);
      expect(find.text('Administrar categorías'), findsOneWidget);
      await tester.tap(find.byTooltip('Volver a visualización'));
      await tester.pumpAndSettle();
      expect(find.text('Modo visualización'), findsOneWidget);
    },
  );

  for (final size in [const Size(820, 1180), const Size(1180, 820)]) {
    for (final count in [1, maxRoutineSteps]) {
      testWidgets(
        'Visor de $count pasos en $size conserva orden y solo lectura',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(() async {
            tester.platformDispatcher.clearTextScaleFactorTestValue();
            await tester.binding.setSurfaceSize(null);
          });
          final routines = FakeRoutines()..saved.add(routine(count));
          await tester.pumpWidget(
            ScaaApp(
              profileStore: FakeStore(),
              catalogStore: FakeCatalog(),
              routineStore: routines,
            ),
          );
          await tester.pumpAndSettle();
          await press(tester, 'Rutinas');
          expect(find.text('Crear rutina'), findsNothing);
          await press(tester, 'Rutina de $count');
          expect(find.byType(RoutineViewer), findsOneWidget);
          expect(find.byType(RoutineEditor), findsNothing);
          expect(find.text('Guardar rutina'), findsNothing);
          final sequence = find.byKey(const ValueKey('routine-sequence'));
          final scroll = tester.widget<SingleChildScrollView>(sequence);
          expect(scroll.scrollDirection, Axis.horizontal);
          expect(find.byType(PictogramImage), findsNWidgets(count));
          final x = [
            for (var i = 1; i <= count; i++)
              tester.getCenter(find.text('Acción $i')).dx,
          ];
          expect(x, orderedEquals([...x]..sort()));
          expect(x.toSet(), hasLength(count));
          if (count == maxRoutineSteps) {
            expect(scroll.controller!.position.maxScrollExtent, greaterThan(0));
            await tester.drag(sequence, const Offset(-5000, 0));
            await tester.pumpAndSettle();
            final last = tester.getCenter(find.text('Acción $count'));
            expect(last.dx, inInclusiveRange(0, size.width));
          } else {
            expect(scroll.controller!.position.maxScrollExtent, 0);
          }
          expect(tester.takeException(), isNull);
          expect(
            routines.generateCalls + routines.saveCalls + routines.deleted,
            0,
          );
        },
      );
    }
  }

  testWidgets(
    'Una carga administrativa demorada no puede abrir el editor después de salir',
    (tester) async {
      final routines = SlowRoutines()..saved.add(routine(1));
      await tester.pumpWidget(
        ScaaApp(
          profileStore: FakeStore(),
          catalogStore: FakeCatalog(),
          routineStore: routines,
        ),
      );
      await tester.pumpAndSettle();
      await enterAdministration(tester);
      await press(tester, 'Cancelar');
      await press(tester, 'Rutinas');
      await tester.tap(find.text('Rutina de 1'));
      await tester.pump();
      await tester.tap(find.byTooltip('Volver a visualización'));
      routines.detail.complete(routine(1));
      await tester.pumpAndSettle();
      expect(find.text('Modo visualización'), findsOneWidget);
      expect(find.byType(RoutineEditor), findsNothing);
      expect(find.byType(RoutineViewer), findsNothing);
    },
  );
}
