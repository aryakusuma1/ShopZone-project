import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shopzone/features/search/pages/search_page.dart';
import 'package:shopzone/shared/providers/cart_provider.dart';
import 'package:shopzone/shared/providers/order_provider.dart';
import 'test_helper.dart';

/// ============================================================================
/// WIDGET TEST - FITUR FILTER PADA SEARCH RESULT PAGE
/// ============================================================================

void main() {
  setUpAll(() async {
    await setupFirebaseMocks();
    await Firebase.initializeApp();
  });

  tearDownAll(() {
    cleanupFirebaseMocks();
  });

  group('Search Filter Feature - Widget Tests', () {
    /// TC-FILTER-001 (POSITIF)
    testWidgets(
        'TC-FILTER-001: Search page menampilkan search bar dan dapat menerima input',
        (WidgetTester tester) async {
      // ARRANGE: Setup widget dengan SearchPage
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
          ],
          child: const MaterialApp(
            home: SearchPage(),
          ),
        ),
      );

      await tester.pump();

      // ASSERT: Verifikasi search page elements
      expect(find.byType(Scaffold), findsOneWidget,
          reason: 'Scaffold harus ada');
      expect(find.byType(TextField), findsAtLeastNWidgets(1),
          reason: 'TextField untuk search harus ada');

      // ACT: Input keyword pencarian
      await tester.enterText(find.byType(TextField).first, 'Sepatu');
      await tester.pump();

      // ASSERT: Verifikasi input diterima
      expect(find.text('Sepatu'), findsOneWidget,
          reason: 'Keyword yang diinput harus ditampilkan');
    });

    /// TC-FILTER-002 (NEGATIF)
    testWidgets(
        'TC-FILTER-002: Search menangani keyword yang tidak menghasilkan hasil',
        (WidgetTester tester) async {
      // ARRANGE: Setup widget
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
          ],
          child: const MaterialApp(
            home: SearchPage(),
          ),
        ),
      );

      await tester.pump();

      // ACT: Input keyword yang unlikely ada
      final textField = find.byType(TextField).first;
      if (textField.evaluate().isNotEmpty) {
        await tester.enterText(textField, 'xyznonexistentproduct12345');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }

      // ASSERT: Aplikasi tetap stabil
      expect(find.byType(Scaffold), findsOneWidget,
          reason: 'Aplikasi tidak crash meskipun tidak ada hasil');
      expect(find.byType(TextField), findsWidgets,
          reason: 'Search field tetap accessible untuk input ulang');
    });
  });
}
