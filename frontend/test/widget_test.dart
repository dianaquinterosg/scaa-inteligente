import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scaa_inteligente/main.dart';

void main() {
  testWidgets('Muestra carga y confirma la conexión', (tester) async {
    final result = Completer<void>();
    await tester.pumpWidget(ScaaApp(checkConnection: () => result.future));
    expect(find.text('Comprobando conexión…'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    result.complete();
    await tester.pumpAndSettle();
    expect(find.text('Servidor disponible'), findsOneWidget);
  });

  testWidgets('Un fallo permite reintentar y recuperar la conexión', (
    tester,
  ) async {
    var attempts = 0;
    Future<void> check() async {
      if (++attempts == 1) throw Exception('fallo controlado');
    }

    await tester.pumpWidget(ScaaApp(checkConnection: check));
    await tester.pumpAndSettle();
    expect(find.text('No pudimos conectar con el servidor.'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Servidor disponible'), findsOneWidget);
    expect(attempts, 2);
  });
}
