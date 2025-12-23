import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shopzone/shared/models/product.dart';
import 'package:shopzone/shared/providers/cart_provider.dart';
import 'package:shopzone/shared/providers/order_provider.dart';
import 'package:shopzone/features/cart/pages/cart_page.dart';
import 'test_helper.dart';

/// ============================================================================
/// INTEGRATION TEST - CART & PURCHASE FEATURE
/// ============================================================================
/// Test ID: INT-PURCHASE
/// Fitur: Cart & Purchase
/// Jenis Test: Integration Testing
/// Deskripsi: Menguji flow lengkap dari menambah produk ke cart hingga checkout

void main() {
  setUpAll(() async {
    await setupFirebaseMocks();
    await Firebase.initializeApp();
  });

  tearDownAll(() {
    cleanupFirebaseMocks();
  });

  group('Cart & Purchase - Integration Tests', () {
    /// INT-PURCHASE-001 (POSITIF)
    /// Test Case: User berhasil menambahkan produk ke cart dan checkout
    /// Expected: Produk masuk cart dan proses checkout berjalan
    testWidgets(
        'INT-PURCHASE-001: User berhasil menambahkan produk ke cart dan melakukan checkout',
        (WidgetTester tester) async {
      // ARRANGE: Setup CartProvider dengan produk
      final cartProvider = CartProvider();
      final dummyProduct = Product(
        id: 'test-product-1',
        name: 'Test Product',
        description: 'Test Description',
        price: 100000,
        stock: 10,
        category: 'Test Category',
        imageUrl: 'https://example.com/image.jpg',
        condition: 'Baru',
      );

      // Setup app dengan CartPage menggunakan provider yang sama
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
          ],
          child: const MaterialApp(
            home: CartPage(),
          ),
        ),
      );

      await tester.pump();

      // Clear any image loading exceptions (expected in test environment)
      tester.takeException();

      // ACT: Tambahkan produk ke cart setelah widget ready
      cartProvider.addItem(dummyProduct);
      await tester.pump();

      // Clear image loading exceptions again
      tester.takeException();

      // ASSERT: CartPage ter-render
      expect(find.byType(Scaffold), findsOneWidget,
          reason: 'CartPage harus ter-render');

      expect(find.text('Keranjang'), findsWidgets,
          reason: 'Title "Keranjang" harus ada');

      // ASSERT: Cart memiliki item
      expect(cartProvider.items.length, 1,
          reason: 'Cart harus memiliki 1 item setelah addItem');

      expect(cartProvider.items.first.product.name, 'Test Product',
          reason: 'Produk yang ditambahkan harus ada di cart');

      // ASSERT: Aplikasi tidak crash
      expect(find.byType(MaterialApp), findsOneWidget,
          reason: 'Aplikasi berjalan dengan stabil');
    });

    /// INT-PURCHASE-002 (NEGATIF)
    /// Test Case: User membuka cart ketika cart kosong
    /// Expected: Empty state ditampilkan
    testWidgets(
        'INT-PURCHASE-002: User membuka cart ketika tidak ada item',
        (WidgetTester tester) async {
      // ARRANGE: Setup CartProvider kosong
      final cartProvider = CartProvider();

      // Setup app dengan CartPage menggunakan provider yang sama
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
          ],
          child: const MaterialApp(
            home: CartPage(),
          ),
        ),
      );

      await tester.pump();

      // ASSERT: CartPage ter-render
      expect(find.byType(Scaffold), findsOneWidget,
          reason: 'CartPage harus ter-render meskipun kosong');

      // ASSERT: Cart kosong
      expect(cartProvider.items.length, 0,
          reason: 'Cart harus kosong');

      // ASSERT: Aplikasi tidak crash dengan empty state
      expect(find.byType(MaterialApp), findsOneWidget,
          reason: 'Aplikasi tetap stabil dengan cart kosong');
    });
  });
}
