import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// ============================================================================
/// INTEGRATION TEST HELPER - FIREBASE MOCKS
/// ============================================================================
/// File ini berisi setup untuk mock Firebase yang digunakan dalam integration testing.
/// Integration testing menguji flow lengkap dari fitur, termasuk navigasi dan logika bisnis.

Future<void> setupFirebaseMocks() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
}

void setupFirebaseCoreMocks() {
  FirebasePlatform.instance = MockFirebasePlatform();
}

void cleanupFirebaseMocks() {
  // Cleanup if needed
}

class MockFirebasePlatform extends FirebasePlatform with MockPlatformInterfaceMixin {
  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return MockFirebaseAppPlatform();
  }

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return MockFirebaseAppPlatform();
  }

  @override
  List<FirebaseAppPlatform> get apps {
    return [MockFirebaseAppPlatform()];
  }
}

class MockFirebaseAppPlatform extends FirebaseAppPlatform with MockPlatformInterfaceMixin {
  MockFirebaseAppPlatform() : super(defaultFirebaseAppName, const FirebaseOptions(
    apiKey: 'test-api-key',
    appId: 'test-app-id',
    messagingSenderId: 'test-sender-id',
    projectId: 'test-project-id',
  ));

  @override
  String get name => defaultFirebaseAppName;

  @override
  FirebaseOptions get options => const FirebaseOptions(
    apiKey: 'test-api-key',
    appId: 'test-app-id',
    messagingSenderId: 'test-sender-id',
    projectId: 'test-project-id',
  );

  @override
  bool get isAutomaticDataCollectionEnabled => false;

  @override
  Future<void> delete() async {}

  @override
  Future<void> setAutomaticDataCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setAutomaticResourceManagementEnabled(bool enabled) async {}
}
