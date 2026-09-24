// Smoke test — verifies the app boots without crashing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fishing_voyage_manag_sys/main.dart';

void main() {
  testWidgets('App boots without crashing', (WidgetTester tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MyApp(navigatorKey: navigatorKey));
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
