import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shopzone/features/auth/pages/register_page.dart';
import 'package:shopzone/shared/providers/cart_provider.dart';
import 'package:shopzone/shared/providers/order_provider.dart';
import 'test_helper.dart';

/// ============================================================================
/// WIDGET TEST - FITUR REGISTRASI
/// ============================================================================

void main() {
  setUpAll(() async {
    await setupFirebaseMocks();
    await Firebase.initializeApp();
  });

  tearDownAll(() {
    cleanupFirebaseMocks();
  });

  group('Registration Feature - Widget Tests', () {
    /// TC-REG-001 (POSITIF)
    testWidgets(
        'TC-REG-001: Registration page menampilkan form lengkap dan menerima input valid',
        (WidgetTester tester) async {
      // ARRANGE: Setup widget dengan RegisterPage langsung
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

      // ASSERT: Verifikasi elemen UI registration page
      expect(find.text('ShopZone'), findsOneWidget,
          reason: 'Label "ShopZone" harus ada');
      expect(find.text('Buat akun baru'), findsOneWidget,
          reason: 'Text "Buat akun baru" harus ada');
      expect(find.byType(TextFormField), findsNWidgets(4),
          reason: 'Harus ada 4 TextFormField (Nama, Email, Password, Konfirmasi)');
      expect(find.text('Sudah punya akun? '), findsOneWidget,
          reason: 'Text "Sudah punya akun?" harus ada');
      expect(find.text('Masuk'), findsOneWidget,
          reason: 'Link "Masuk" harus ada');
      expect(find.text('Daftar'), findsOneWidget,
          reason: 'Tombol "Daftar" harus ada');

      // ACT: Input data registrasi valid
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'John Doe');
      await tester.pump();
      await tester.enterText(fields.at(1), 'john@example.com');
      await tester.pump();
      await tester.enterText(fields.at(2), 'password123');
      await tester.pump();
      await tester.enterText(fields.at(3), 'password123');
      await tester.pump();

      // ASSERT: Verifikasi input ditampilkan
      expect(find.text('John Doe'), findsOneWidget,
          reason: 'Nama yang diinput harus ditampilkan');
      expect(find.text('john@example.com'), findsOneWidget,
          reason: 'Email yang diinput harus ditampilkan');
      expect(find.text('password123'), findsNWidgets(2),
          reason: 'Password dan konfirmasi harus sama');
      expect(find.widgetWithText(ElevatedButton, 'Daftar'), findsOneWidget,
          reason: 'Tombol Daftar harus ada');
    });

    /// TC-REG-002 (NEGATIF)
    testWidgets(
        'TC-REG-002: Registration menampilkan error untuk password mismatch dan input invalid',
        (WidgetTester tester) async {
      // ARRANGE: Setup widget
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

      // ACT: Input password yang tidak cocok
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Test User');
      await tester.pump();
      await tester.enterText(fields.at(1), 'test@example.com');
      await tester.pump();
      await tester.enterText(fields.at(2), 'password123');
      await tester.pump();
      await tester.enterText(fields.at(3), 'differentPassword'); // Mismatch!
      await tester.pump();

      // ASSERT: Input ditampilkan
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
      expect(find.text('differentPassword'), findsOneWidget);

      // ACT: Try submit dengan tap tombol Daftar
      final registerButton = find.widgetWithText(ElevatedButton, 'Daftar');
      expect(registerButton, findsOneWidget);
      await tester.tap(registerButton);
      await tester.pump();

      // ASSERT: Error validasi muncul untuk password mismatch
      expect(find.text('Password tidak sama'), findsOneWidget,
          reason: 'Error message untuk password mismatch harus muncul');

      // ACT: Clear dan test password terlalu pendek
      await tester.enterText(fields.at(0), 'AB'); // Nama terlalu pendek
      await tester.pump();
      await tester.enterText(fields.at(1), 'invalid-email'); // Email invalid
      await tester.pump();
      await tester.enterText(fields.at(2), '123'); // Password pendek
      await tester.pump();
      await tester.enterText(fields.at(3), '123');
      await tester.pump();

      await tester.tap(registerButton);
      await tester.pump();

      // ASSERT: Multiple error validasi muncul
      expect(find.text('Nama minimal 3 karakter'), findsOneWidget,
          reason: 'Error message untuk nama pendek harus muncul');
      expect(find.text('Format email tidak valid'), findsOneWidget,
          reason: 'Error message untuk email invalid harus muncul');
      expect(find.text('Password minimal 6 karakter'), findsOneWidget,
          reason: 'Error message untuk password pendek harus muncul');

      // ASSERT: Form fields masih ada (tidak berhasil register)
      expect(find.byType(TextFormField), findsNWidgets(4),
          reason: 'Form fields harus tetap ada karena validasi gagal');
    });
  });
}
