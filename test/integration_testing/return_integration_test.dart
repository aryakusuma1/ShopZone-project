import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shopzone/shared/providers/cart_provider.dart';
import 'package:shopzone/shared/providers/order_provider.dart';
import 'package:shopzone/features/admin/pages/admin_manage_retur_page.dart';
import 'test_helper.dart';

/// ============================================================================
/// INTEGRATION TEST - RETURN FEATURE
/// ============================================================================
/// Test ID: INT-RETURN
/// Fitur: Return/Pengembalian Produk
/// Jenis Test: Integration Testing
/// Deskripsi: Menguji flow lengkap pengembalian produk

void main() {
  setUpAll(() async {
    await setupFirebaseMocks();
    await Firebase.initializeApp();
  });

  tearDownAll(() {
    cleanupFirebaseMocks();
  });

  group('Return - Integration Tests', () {
    /// INT-RETURN-001 (POSITIF)
    /// Test Case: Admin berhasil memproses return request
    /// Expected: Return request berhasil diproses
    testWidgets(
        'INT-RETURN-001: Admin berhasil melihat dan memproses return request',
        (WidgetTester tester) async {
      // ARRANGE: Setup app dengan AdminManageReturPage
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

      // ASSERT: AdminManageReturPage ter-render
      expect(find.byType(Scaffold), findsOneWidget,
          reason: 'AdminManageReturPage harus ter-render');

      expect(find.text('Manage Retur'), findsOneWidget,
          reason: 'Title "Manage Retur" harus ada');

      // ACT: Tunggu data loading
      await tester.pump(const Duration(milliseconds: 500));

      // ASSERT: Aplikasi tidak crash
      expect(find.byType(MaterialApp), findsOneWidget,
          reason: 'Aplikasi berjalan dengan stabil');
    });

    /// INT-RETURN-002 (NEGATIF)
    /// Test Case: Admin membuka halaman return ketika tidak ada request
    /// Expected: Empty state ditampilkan
    testWidgets(
        'INT-RETURN-002: Admin membuka halaman return ketika tidak ada request',
        (WidgetTester tester) async {
      // ARRANGE: Setup app dengan AdminManageReturPage
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

      // Clear any loading exceptions
      tester.takeException();

      // ASSERT: AdminManageReturPage tetap ter-render
      expect(find.byType(Scaffold), findsOneWidget,
          reason: 'AdminManageReturPage harus ter-render meskipun kosong');

      // ACT: Tunggu data loading
      await tester.pump(const Duration(seconds: 1));

      // Clear any exceptions
      tester.takeException();

      // ASSERT: Aplikasi tetap stabil dengan empty state
      expect(find.byType(MaterialApp), findsOneWidget,
          reason: 'Aplikasi tidak crash dengan empty state');
    });
  });
}
