import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('App builds basic scaffold', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(appBar: AppBar(title: Text('Future AI')))));
    await tester.pumpAndSettle();
    expect(find.text('Future AI'), findsOneWidget);
  });
}
