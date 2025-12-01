import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register with email and password
  Future<String?> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Create user in Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(name);

      // Save additional user data to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': name,
        'email': email,
        'role': 'customer', // Default role untuk registrasi normal
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // Success, no error
    } on FirebaseAuthException catch (e) {
      // Return error message based on error code
      switch (e.code) {
        case 'weak-password':
          return 'Password terlalu lemah. Minimal 6 karakter.';
        case 'email-already-in-use':
          return 'Email sudah terdaftar. Silakan login.';
        case 'invalid-email':
          return 'Format email tidak valid.';
        case 'operation-not-allowed':
          return 'Operasi tidak diizinkan. Hubungi admin.';
        default:
          return 'Terjadi kesalahan: ${e.message}';
      }
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    }
  }

  // Sign in with email and password
  Future<String?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // Success, no error
    } on FirebaseAuthException catch (e) {
      // Return error message based on error code
      switch (e.code) {
        case 'user-not-found':
          return 'Email tidak terdaftar. Silakan daftar terlebih dahulu.';
        case 'wrong-password':
          return 'Password salah. Silakan coba lagi.';
        case 'invalid-email':
          return 'Format email tidak valid.';
        case 'user-disabled':
          return 'Akun ini telah dinonaktifkan.';
        case 'invalid-credential':
          return 'Email atau password salah.';
        default:
          return 'Terjadi kesalahan: ${e.message}';
      }
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset password
  Future<String?> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Success, no error
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'Email tidak terdaftar.';
        case 'invalid-email':
          return 'Format email tidak valid.';
        default:
          return 'Terjadi kesalahan: ${e.message}';
      }
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    }
  }
}
