import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scaa_inteligente/backend_client.dart';
import 'package:scaa_inteligente/main.dart';
import 'package:scaa_inteligente/profile.dart';

class FakeStore implements ProfileStore {
  FakeStore([this.current]);
  ProfileData? current;
  bool failSave = false;
  bool failLoad = false;
  int saves = 0;
  @override
  Future<ProfileData?> load() async {
    if (failLoad) throw const ApiException(503, 'Fallo controlado');
    return current;
  }

  @override
  Future<ProfileData> save(ProfileData draft) async {
    saves++;
    if (failSave) throw const ApiException(503, 'No se pudo guardar el perfil');
    current = draft;
    return draft;
  }
}

Future<void> openApp(WidgetTester tester, FakeStore store) async {
  await tester.binding.setSurfaceSize(const Size(1000, 1800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(ScaaApp(key: UniqueKey(), profileStore: store));
  await tester.pumpAndSettle();
}

Future<void> save(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('save-profile')));
  await tester.pumpAndSettle();
}

Future<void> add(
  WidgetTester tester,
  String group,
  int index,
  String value,
) async {
  await tester.ensureVisible(find.byKey(ValueKey('add-$group')));
  await tester.tap(find.byKey(ValueKey('add-$group')));
  await tester.pump();
  await tester.enterText(find.byKey(ValueKey('$group-$index')), value);
  await tester.pump();
}

void main() {
  testWidgets(
    'Un fallo de guardado queda visible al editar desde el final del formulario',
    (tester) async {
      final store = FakeStore(
        ProfileData(alias: 'Ana', frequentRoutines: ['Lectura']),
      )..failSave = true;
      await openApp(tester, store);
      await tester.binding.setSurfaceSize(const Size(800, 500));
      await tester.tap(find.byKey(const ValueKey('edit-profile')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('add-frequent_routines')),
        200,
        scrollable: find
            .descendant(
              of: find.byType(Form),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await save(tester);
      final error = find.byKey(const ValueKey('save-error'));
      expect(error, findsOneWidget);
      expect(tester.getTopLeft(error).dy, greaterThanOrEqualTo(0));
      expect(tester.getBottomRight(error).dy, lessThan(500));
      expect(store.current!.alias, 'Ana');
    },
  );
  for (final kind in ContextKind.values) {
    testWidgets(
      'CA01.3: editar y eliminar ${kind.field} preserva los otros tipos',
      (tester) async {
        final store = FakeStore(
          ProfileData(
            alias: 'Ana',
            interests: ['Original'],
            activities: ['Original'],
            frequentRoutines: ['Original'],
          ),
        );
        await openApp(tester, store);
        await tester.tap(find.byKey(const ValueKey('edit-profile')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(ValueKey('${kind.field}-0')),
          'Editado',
        );
        await save(tester);
        expect(store.current!.values(kind), ['Editado']);
        for (final other in ContextKind.values.where((item) => item != kind)) {
          expect(store.current!.values(other), ['Original']);
        }
        await tester.tap(find.byKey(const ValueKey('edit-profile')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('remove-${kind.field}-0')));
        await tester.pump();
        await save(tester);
        expect(store.current!.values(kind), isEmpty);
        for (final other in ContextKind.values.where((item) => item != kind)) {
          expect(store.current!.values(other), ['Original']);
        }
      },
    );
  }
  testWidgets('CA01.1/4/6: alias obligatorio normalizado y contexto opcional', (
    tester,
  ) async {
    final store = FakeStore();
    await openApp(tester, store);
    expect(find.text('Configurar perfil'), findsOneWidget);
    expect(find.text('Cancelar'), findsNothing);
    await save(tester);
    expect(find.text('Ingresa un alias.'), findsOneWidget);
    expect(store.saves, 0);
    await tester.enterText(find.byKey(const ValueKey('alias')), '  Ana  ');
    await save(tester);
    expect(store.current!.alias, 'Ana');
    expect(store.current!.interests, isEmpty);
    expect(find.text('Hola, Ana'), findsOneWidget);
    expect(find.text('Perfil guardado'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets(
    'CA01.2/3/6/8: añadir, editar, eliminar y recuperar los tres tipos',
    (tester) async {
      final store = FakeStore();
      await openApp(tester, store);
      await tester.enterText(find.byKey(const ValueKey('alias')), 'Ana');
      await add(tester, 'interests', 0, ' Agua ');
      await add(tester, 'interests', 1, 'Pintura');
      await add(tester, 'activities', 0, ' Caminar ');
      await add(tester, 'frequent_routines', 0, ' Lectura ');
      await tester.enterText(
        find.byKey(const ValueKey('interests-0')),
        ' Música ',
      );
      await tester.tap(find.byKey(const ValueKey('remove-interests-1')));
      await tester.pump();
      await save(tester);
      expect(store.current!.interests, ['Música']);
      expect(store.current!.activities, ['Caminar']);
      expect(store.current!.frequentRoutines, ['Lectura']);
      await tester.tap(find.byKey(const ValueKey('edit-profile')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'Música'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('remove-interests-0')));
      await tester.pump();
      await save(tester);
      expect(store.current!.interests, isEmpty);
      await tester.pumpWidget(ScaaApp(key: UniqueKey(), profileStore: store));
      await tester.pumpAndSettle();
      expect(find.text('Caminar'), findsOneWidget);
      expect(find.text('Lectura'), findsOneWidget);
    },
  );

  for (final group in ['interests', 'activities', 'frequent_routines']) {
    testWidgets('CA01.5: vacíos y duplicados normalizados en $group', (
      tester,
    ) async {
      final store = FakeStore();
      await openApp(tester, store);
      await tester.enterText(find.byKey(const ValueKey('alias')), 'Ana');
      await add(tester, group, 0, '   ');
      await save(tester);
      expect(store.saves, 0);
      await tester.ensureVisible(find.byKey(ValueKey('$group-0')));
      await tester.enterText(find.byKey(ValueKey('$group-0')), 'Agua');
      await add(tester, group, 1, ' aGUA ');
      await save(tester);
      expect(store.saves, 0);
      await tester.ensureVisible(find.byKey(ValueKey('remove-$group-1')));
      await tester.tap(find.byKey(ValueKey('remove-$group-1')));
      await tester.pump();
      await save(tester);
      expect(store.saves, 1);
    });
  }

  testWidgets('CA01.7: límite 50 para alias y cada tipo, con Unicode', (
    tester,
  ) async {
    final store = FakeStore();
    await openApp(tester, store);
    await tester.enterText(find.byKey(const ValueKey('alias')), 'a' * 51);
    await save(tester);
    expect(store.saves, 0);
    await tester.enterText(find.byKey(const ValueKey('alias')), 'ñ' * 50);
    for (final group in ['interests', 'activities', 'frequent_routines']) {
      await add(tester, group, 0, 'a' * 51);
      await save(tester);
      expect(store.saves, 0);
      await tester.ensureVisible(find.byKey(ValueKey('$group-0')));
      await tester.enterText(find.byKey(ValueKey('$group-0')), '😀' * 50);
    }
    await save(tester);
    expect(store.saves, 1);
    expect(store.current!.alias.runes.length, 50);
  });

  testWidgets(
    'CA01.9: fallo conserva borrador y datos confirmados, permite reintentar',
    (tester) async {
      final store = FakeStore(
        ProfileData(alias: 'Guardado', interests: ['Confirmado']),
      )..failSave = true;
      await openApp(tester, store);
      await tester.tap(find.byKey(const ValueKey('edit-profile')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('alias')), 'Borrador');
      await save(tester);
      expect(find.text('No se pudo guardar el perfil'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Borrador'), findsOneWidget);
      expect(store.current!.alias, 'Guardado');
      store.failSave = false;
      await save(tester);
      expect(find.text('Hola, Borrador'), findsOneWidget);
    },
  );

  testWidgets('CA01.10: cancelar descarta cambios no confirmados', (
    tester,
  ) async {
    final store = FakeStore(
      ProfileData(alias: 'Guardado', interests: ['Confirmado']),
    );
    await openApp(tester, store);
    await tester.tap(find.byKey(const ValueKey('edit-profile')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('alias')),
      'No confirmado',
    );
    await tester.enterText(
      find.byKey(const ValueKey('interests-0')),
      'Otro contexto',
    );
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Hola, Guardado'), findsOneWidget);
    expect(find.text('Confirmado'), findsOneWidget);
    expect(store.saves, 0);
    await tester.tap(find.byKey(const ValueKey('edit-profile')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'Guardado'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Confirmado'), findsOneWidget);
  });

  testWidgets('Un fallo de lectura no permite confundirlo con primer uso', (
    tester,
  ) async {
    final store = FakeStore(ProfileData(alias: 'Ana'))..failLoad = true;
    await openApp(tester, store);
    expect(find.text('No pudimos cargar tu perfil.'), findsOneWidget);
    expect(find.text('Configurar perfil'), findsNothing);
    store.failLoad = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Hola, Ana'), findsOneWidget);
  });
}
