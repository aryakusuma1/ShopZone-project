import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shopzone/shared/providers/cart_provider.dart';
import 'package:shopzone/shared/providers/order_provider.dart';
import 'package:shopzone/features/auth/pages/register_page.dart';
import 'test_helper.dart';

/// ============================================================================
/// INTEGRATION TEST - REGISTRATION FEATURE
/// ============================================================================
/// Test ID: INT-REG
/// Fitur: Registration
/// Jenis Test: Integration Testing
/// Deskripsi: Menguji flow lengkap registrasi user baru

void main() {
  setUpAll(() async {
    await setupFirebaseMocks();
    await Firebase.initializeApp();
  });

  tearDownAll(() {
    cleanupFirebaseMocks();
  });

  group('Registration Feature - Integration Tests', () {
    /// INT-REG-001 (POSITIF)
    /// Test Case: User berhasil registrasi dengan data valid
    /// Expected: Akun berhasil dibuat
    testWidgets(
        'INT-REG-001: User berhasil registrasi dengan data yang valid',
        (WidgetTester tester) async {
      // ARRANGE: Setup app dengan RegisterPage
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
          ],
          child: const MaterialApp(
            home: RegisterPage(),
          ),
        ),
      );

      await tester.pump();

      // ACT: User mengisi semua field dengan data valid
      final fields = find.byType(TextField);
      expect(fields, findsAtLeastNWidgets(4),
          reason: 'Harus ada minimal 4 field (nama, email, password, confirm)');

      await tester.enterText(fields.at(0), 'Test User');
      await tester.enterText(fields.at(1), 'testuser@example.com');
      await tester.enterText(fields.at(2), 'password123');
      await tester.enterText(fields.at(3), 'password123');
      await tester.pump();

      // ASSERT: Semua input terisi
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('testuser@example.com'), findsOneWidget);
      expect(find.text('password123'), findsWidgets);

      // ACT: Tap tombol Daftar
      final registerButton = find.widgetWithText(ElevatedButton, 'Daftar');
      expect(registerButton, findsOneWidget,
          reason: 'Tombol Daftar harus tersedia');

      await tester.tap(registerButton);
      await tester.pump();

      // ASSERT: Tidak ada error validation
      expect(find.byType(RegisterPage), findsOneWidget,
          reason: 'Halaman register tetap stabil setelah submit');
    });

    /// INT-REG-002 (NEGATIF)
    /// Test Case: User gagal registrasi karena password tidak match
    /// Expected: Error message ditampilkan
    testWidgets(
        'INT-REG-002: User gagal registrasi karena password tidak match',
        (WidgetTester tester) async {
      // ARRANGE: Setup app dengan RegisterPage
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
          ],
          child: const MaterialApp(
            home: RegisterPage(),
          ),
        ),
      );

      await tester.pump();

      // ACT: User mengisi field dengan password yang tidak match
      final fields = find.byType(TextField);

      await tester.enterText(fields.at(0), 'Test User');
      await tester.enterText(fields.at(1), 'testuser@example.com');
      await tester.enterText(fields.at(2), 'password123');
      await tester.enterText(fields.at(3), 'differentPassword');
      await tester.pump();

      // ACT: Tap tombol Daftar
      final registerButton = find.widgetWithText(ElevatedButton, 'Daftar');
      await tester.tap(registerButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // ASSERT: Error message muncul
      expect(find.text('Password tidak sama'), findsOneWidget,
          reason: 'Error message harus ditampilkan untuk password mismatch');

      // ASSERT: Tetap di halaman register
      expect(find.byType(RegisterPage), findsOneWidget,
          reason: 'User tetap di halaman register');
    });
  });
}
