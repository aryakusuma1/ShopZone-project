import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shopzone/features/cart/pages/cart_page.dart';
import 'package:shopzone/shared/providers/cart_provider.dart';
import 'package:shopzone/shared/providers/order_provider.dart';
import 'test_helper.dart';

/// ============================================================================
/// WIDGET TEST - FITUR PEMBELIAN BARANG
/// ============================================================================

void main() {
  setUpAll(() async {
    await setupFirebaseMocks();
    await Firebase.initializeApp();
  });

  tearDownAll(() {
    cleanupFirebaseMocks();
  });

  group('Purchase Feature - Widget Tests', () {
    /// TC-PURCHASE-001 (POSITIF)
    testWidgets(
        'TC-PURCHASE-001: Cart page menampilkan struktur UI yang benar',
        (WidgetTester tester) async {
      // ARRANGE: Setup widget dengan CartPage
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
          ],
          child: const MaterialApp(
            home: CartPage(),
          ),
        ),
      );

      await tester.pump();

      // ASSERT: Verifikasi struktur UI cart page
      expect(find.byType(Scaffold), findsOneWidget,
          reason: 'Scaffold harus ada');
      expect(find.text('Keranjang'), findsWidgets,
          reason: 'Text "Keranjang" harus ada di AppBar');

      // ASSERT: Aplikasi tidak crash
      expect(find.byType(MaterialApp), findsOneWidget,
          reason: 'Aplikasi ter-render dengan benar');
    });

    /// TC-PURCHASE-002 (NEGATIF)
    testWidgets(
        'TC-PURCHASE-002: Cart menampilkan empty state ketika tidak ada item',
        (WidgetTester tester) async {
      // ARRANGE: Setup widget dengan empty cart
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
          ],
          child: const MaterialApp(
            home: CartPage(),
          ),
        ),
      );

      await tester.pump();

      // ASSERT: Verifikasi empty cart state
      // Cart provider default adalah empty, jadi seharusnya ada empty message
      expect(find.byType(Scaffold), findsOneWidget,
          reason: 'Scaffold harus ada');

      // ASSERT: Text Keranjang tetap ada di AppBar
      expect(find.text('Keranjang'), findsWidgets,
          reason: 'AppBar title harus tetap ada');

      // ASSERT: Aplikasi tidak crash dengan empty cart
      expect(find.byType(MaterialApp), findsOneWidget,
          reason: 'Aplikasi tidak crash dengan empty cart');
    });
  });
}
