import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goodtimes/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Basic smoke test
    expect(find.byType(MaterialApp), findsNothing);
  });
}
