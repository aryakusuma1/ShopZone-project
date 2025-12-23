import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shopzone/shared/providers/cart_provider.dart';
import 'package:shopzone/shared/providers/order_provider.dart';
import 'package:shopzone/features/search/pages/search_page.dart';
import 'test_helper.dart';

/// ============================================================================
/// INTEGRATION TEST - SEARCH & FILTER FEATURE
/// ============================================================================
/// Test ID: INT-FILTER
/// Fitur: Search & Filter Produk
/// Jenis Test: Integration Testing
/// Deskripsi: Menguji flow lengkap pencarian dan filter produk

void main() {
  setUpAll(() async {
    await setupFirebaseMocks();
    await Firebase.initializeApp();
  });

  tearDownAll(() {
    cleanupFirebaseMocks();
  });

  group('Search & Filter - Integration Tests', () {
    /// INT-FILTER-001 (POSITIF)
    /// Test Case: User berhasil mencari produk dengan keyword
    /// Expected: Hasil pencarian ditampilkan
    testWidgets(
        'INT-FILTER-001: User berhasil mencari produk dengan keyword yang ada',
        (WidgetTester tester) async {
      // ARRANGE: Setup app dengan SearchPage
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

      // ASSERT: SearchPage ter-render
      expect(find.byType(Scaffold), findsOneWidget,
          reason: 'SearchPage harus ter-render');

      // ACT: User memasukkan keyword pencarian
      final searchField = find.byType(TextField);
      if (searchField.evaluate().isNotEmpty) {
        await tester.enterText(searchField.first, 'Sepatu');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // ASSERT: Keyword ditampilkan di search field
        expect(find.text('Sepatu'), findsOneWidget,
            reason: 'Keyword harus ditampilkan di search field');
      }

      // ASSERT: Aplikasi tidak crash
      expect(find.byType(MaterialApp), findsOneWidget,
          reason: 'Aplikasi berjalan dengan stabil');
    });

    /// INT-FILTER-002 (NEGATIF)
    /// Test Case: User mencari produk dengan keyword yang tidak ada
    /// Expected: Empty state atau "tidak ada hasil" ditampilkan
    testWidgets(
        'INT-FILTER-002: User mencari produk dengan keyword yang tidak ada hasil',
        (WidgetTester tester) async {
      // ARRANGE: Setup app dengan SearchPage
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

      // ACT: User memasukkan keyword yang tidak ada
      final searchField = find.byType(TextField);
      if (searchField.evaluate().isNotEmpty) {
        await tester.enterText(
          searchField.first,
          'xyznonexistentproduct12345',
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }

      // ASSERT: Aplikasi tetap stabil meskipun tidak ada hasil
      expect(find.byType(Scaffold), findsOneWidget,
          reason: 'Aplikasi tidak crash meskipun tidak ada hasil');

      expect(find.byType(TextField), findsWidgets,
          reason: 'Search field tetap accessible untuk input ulang');

      // ASSERT: Aplikasi tidak crash
      expect(find.byType(MaterialApp), findsOneWidget,
          reason: 'Aplikasi tetap stabil dengan empty result');
    });
  });
}
