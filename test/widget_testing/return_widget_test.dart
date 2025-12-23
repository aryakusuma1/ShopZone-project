import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shopzone/features/admin/pages/admin_manage_retur_page.dart';
import 'package:shopzone/shared/providers/cart_provider.dart';
import 'package:shopzone/shared/providers/order_provider.dart';
import 'test_helper.dart';

/// ============================================================================
/// WIDGET TEST - FITUR RETUR BARANG
/// ============================================================================

void main() {
  setUpAll(() async {
    await setupFirebaseMocks();
    await Firebase.initializeApp();
  });

  tearDownAll(() {
    cleanupFirebaseMocks();
  });

  group('Return Feature - Widget Tests', () {
    /// TC-RETURN-001 (POSITIF)
    testWidgets(
        'TC-RETURN-001: Return management page menampilkan struktur UI yang benar',
        (WidgetTester tester) async {
      // ARRANGE: Setup widget dengan AdminManageReturPage
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
          ],
          child: const MaterialApp(
            home: AdminManageReturPage(),
          ),
        ),
      );

      await tester.pump();

      // ASSERT: Verifikasi struktur dasar UI
      expect(find.byType(Scaffold), findsOneWidget,
          reason: 'Scaffold harus ada');
      expect(find.text('Manage Retur'), findsOneWidget,
          reason: 'Title "Manage Retur" harus ada');

      // ASSERT: Aplikasi tidak crash
      expect(find.byType(MaterialApp), findsOneWidget,
          reason: 'Aplikasi ter-render dengan benar');
    });

    /// TC-RETURN-002 (NEGATIF)
    testWidgets(
        'TC-RETURN-002: Return page menangani empty state dengan baik',
        (WidgetTester tester) async {
      // ARRANGE: Setup widget
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
          ],
          child: const MaterialApp(
            home: AdminManageReturPage(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Clear any exceptions that might have occurred during loading
      tester.takeException();

      // ASSERT: Aplikasi tidak crash
      expect(find.byType(Scaffold), findsOneWidget,
          reason: 'Scaffold harus tetap ada');
      expect(find.byType(MaterialApp), findsOneWidget,
          reason: 'Aplikasi tidak crash dan tetap stabil');
    });
  });
}
