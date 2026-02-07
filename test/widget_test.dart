// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tfg/app/app.dart';

void main() {
  testWidgets(
    'App builds without crashing',
    (WidgetTester tester) async {
      // Este test se omite porque la app inicializa Firebase en `main()`.
      // Para habilitarlo, configura Firebase emulado o mocks en tests.
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      expect(find.byType(MaterialApp), findsWidgets);
    },
    skip: true,
  );
}
