// Basic smoke test for IT Helper.
//
// Makes sure the app boots and shows the home screen without throwing,
// and that the bottom navigation is present.

import 'package:flutter_test/flutter_test.dart';

import 'package:it_helper/main.dart';

void main() {
  testWidgets('App launches and shows home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ItHelperApp());
    await tester.pumpAndSettle();

    // App title / header text on the home page.
    expect(find.text('IT Helper'), findsWidgets);

    // Bottom navigation destinations.
    expect(find.text('خانه'), findsOneWidget);
    expect(find.text('ابزارها'), findsOneWidget);
    expect(find.text('تاریخچه'), findsOneWidget);
    expect(find.text('پروفایل'), findsOneWidget);
  });

  testWidgets('Tapping a scenario opens the troubleshoot flow', (WidgetTester tester) async {
    await tester.pumpWidget(const ItHelperApp());
    await tester.pumpAndSettle();

    // Tap the first scenario card ("اینترنت وصل نیست").
    await tester.tap(find.text('اینترنت وصل نیست').first);
    await tester.pumpAndSettle();

    expect(find.text('اتصال شبکه را بررسی کن'), findsOneWidget);
  });
}
