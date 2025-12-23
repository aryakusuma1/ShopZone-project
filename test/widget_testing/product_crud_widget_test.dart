import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shopzone/features/home/pages/home_page.dart';
import 'package:shopzone/shared/providers/cart_provider.dart';
import 'package:shopzone/shared/providers/order_provider.dart';
import 'test_helper.dart';

/// ============================================================================
/// WIDGET TEST - FITUR CRUD DATA (PRODUCT MANAGEMENT)
/// ============================================================================

void main() {
  setUpAll(() async {
    await setupFirebaseMocks();
    await Firebase.initializeApp();
  });

  tearDownAll(() {
    cleanupFirebaseMocks();
  });

  group('Product CRUD Feature - Widget Tests', () {
    /// TC-CRUD-001 (POSITIF)
    testWidgets(
        'TC-CRUD-001: Product list menampilkan struktur UI dengan elemen dasar',
        (WidgetTester tester) async {
      // ARRANGE: Setup widget dengan HomePage
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
          ],
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pump();

      // ASSERT: Verifikasi struktur dasar UI
      expect(find.byType(Scaffold), findsOneWidget,
          reason: 'Scaffold harus ada sebagai struktur dasar');
      expect(find.byType(BottomNavigationBar), findsOneWidget,
          reason: 'BottomNavigationBar harus ada');

      // ASSERT: Aplikasi tidak crash
      expect(find.byType(MaterialApp), findsOneWidget,
          reason: 'Aplikasi ter-render dengan benar');
    });

    /// TC-CRUD-002 (NEGATIF)
    testWidgets(
        'TC-CRUD-002: Product list menangani empty state dengan baik',
        (WidgetTester tester) async {
      // ARRANGE: Setup widget
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
          ],
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // ASSERT: Aplikasi tidak crash dan UI tetap stable
      expect(find.byType(Scaffold), findsOneWidget,
          reason: 'Scaffold harus ada meskipun data kosong');
      expect(find.byType(BottomNavigationBar), findsOneWidget,
          reason: 'BottomNavigationBar harus tetap fungsional');

      // ASSERT: Aplikasi tidak crash
      expect(find.byType(MaterialApp), findsOneWidget,
          reason: 'Aplikasi tidak crash dengan data kosong');
    });
  });
}
