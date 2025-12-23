import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shopzone/features/auth/pages/login_page.dart';
import 'package:shopzone/shared/providers/cart_provider.dart';
import 'package:shopzone/shared/providers/order_provider.dart';
import 'test_helper.dart';

/// ============================================================================
/// WIDGET TEST - FITUR LOGIN
/// ============================================================================

void main() {
  setUpAll(() async {
    await setupFirebaseMocks();
    await Firebase.initializeApp();
  });

  tearDownAll(() {
    cleanupFirebaseMocks();
  });

  group('Login Feature - Widget Tests', () {
    /// TC-LOGIN-001 (POSITIF)
    testWidgets(
        'TC-LOGIN-001: Login page menampilkan semua elemen UI dan menerima input valid',
        (WidgetTester tester) async {
      // ARRANGE: Setup widget dengan LoginPage langsung
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
          ],
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      await tester.pump();

      // ASSERT: Verifikasi elemen UI login page
      expect(find.text('ShopZone'), findsOneWidget,
          reason: 'Label "ShopZone" harus ada di halaman login');
      expect(find.text('Selamat datang kembali'), findsOneWidget,
          reason: 'Text sambutan harus ada');
      expect(find.byType(TextFormField), findsNWidgets(2),
          reason: 'Harus ada 2 TextFormField (Email dan Password)');
      expect(find.text('Belum punya akun? '), findsOneWidget,
          reason: 'Text "Belum punya akun?" harus ada');
      expect(find.text('Daftar'), findsOneWidget,
          reason: 'Link "Daftar" harus ada');
      expect(find.text('Masuk'), findsOneWidget,
          reason: 'Tombol "Masuk" harus ada');

      // ACT: Input email dan password
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, 'test@example.com');
      await tester.pump();
      await tester.enterText(fields.last, 'password123');
      await tester.pump();

      // ASSERT: Verifikasi input ditampilkan
      expect(find.text('test@example.com'), findsOneWidget,
          reason: 'Email yang diinput harus ditampilkan');
      expect(find.text('password123'), findsOneWidget,
          reason: 'Password yang diinput harus ditampilkan');
      expect(find.widgetWithText(ElevatedButton, 'Masuk'), findsOneWidget,
          reason: 'Tombol Masuk harus ada');
    });

    /// TC-LOGIN-002 (NEGATIF)
    testWidgets(
        'TC-LOGIN-002: Login page menampilkan error validasi untuk input tidak valid',
        (WidgetTester tester) async {
      // ARRANGE: Setup widget
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
          ],
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      await tester.pump();

      // ACT: Input data invalid
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, 'invalid-email');
      await tester.pump();
      await tester.enterText(fields.last, '123');
      await tester.pump();

      // ASSERT: Input ditampilkan
      expect(find.text('invalid-email'), findsOneWidget,
          reason: 'Email invalid harus ditampilkan di field');
      expect(find.text('123'), findsOneWidget,
          reason: 'Password pendek harus ditampilkan di field');

      // ACT: Try submit dengan tap tombol Masuk
      final loginButton = find.widgetWithText(ElevatedButton, 'Masuk');
      expect(loginButton, findsOneWidget);
      await tester.tap(loginButton);
      await tester.pump();

      // ASSERT: Error validasi muncul
      expect(find.text('Format email tidak valid'), findsOneWidget,
          reason: 'Error message untuk email invalid harus muncul');
      expect(find.text('Password minimal 6 karakter'), findsOneWidget,
          reason: 'Error message untuk password pendek harus muncul');

      // ASSERT: Still has form fields (tidak berhasil login)
      expect(find.byType(TextFormField), findsNWidgets(2),
          reason: 'Form fields harus tetap ada karena validasi gagal');
    });
  });
}
