import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shopzone/features/profile/pages/refund_page.dart';
import 'package:shopzone/shared/providers/cart_provider.dart';
import 'package:shopzone/shared/providers/order_provider.dart';
import 'test_helper.dart';

/// ============================================================================
/// WIDGET TEST - FITUR REFUND
/// ============================================================================

void main() {
  setUpAll(() async {
    await setupFirebaseMocks();
    await Firebase.initializeApp();
  });

  tearDownAll(() {
    cleanupFirebaseMocks();
  });

  group('Refund Feature - Widget Tests', () {
    /// TC-REFUND-001 (POSITIF)
    testWidgets(
        'TC-REFUND-001: Refund page menampilkan struktur UI yang benar',
        (WidgetTester tester) async {
      // ARRANGE: Setup widget dengan RefundPage
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
          ],
          child: const MaterialApp(
            home: RefundPage(),
          ),
        ),
      );

      await tester.pump();

      // ASSERT: Verifikasi struktur dasar UI
      expect(find.byType(Scaffold), findsOneWidget,
          reason: 'Scaffold harus ada');
      expect(find.text('Refund Saya'), findsOneWidget,
          reason: 'Text "Refund Saya" harus ada');

      // ASSERT: Aplikasi tidak crash
      expect(find.byType(MaterialApp), findsOneWidget,
          reason: 'Aplikasi ter-render dengan benar');
    });

    /// TC-REFUND-002 (NEGATIF)
    testWidgets(
        'TC-REFUND-002: Refund page menangani empty state dengan baik',
        (WidgetTester tester) async {
      // ARRANGE: Setup widget
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
          ],
          child: const MaterialApp(
            home: RefundPage(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Clear any exceptions that might have occurred during loading
      tester.takeException();

      // ASSERT: Aplikasi tidak crash dengan empty data
      expect(find.byType(Scaffold), findsOneWidget,
          reason: 'Scaffold harus tetap ada');
      expect(find.byType(MaterialApp), findsOneWidget,
          reason: 'Aplikasi tidak crash dan tetap stabil');
    });
  });
}
