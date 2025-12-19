import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsService {
  static final NotificationSettingsService _instance =
      NotificationSettingsService._internal();
  factory NotificationSettingsService() => _instance;
  NotificationSettingsService._internal();

  static const String _notificationKey = 'notification_enabled';

  /// Get notification enabled status
  Future<bool> isNotificationEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Default to true if not set
      return prefs.getBool(_notificationKey) ?? true;
    } catch (e) {
      return true; // Default to enabled if error
    }
  }

  /// Set notification enabled status
  Future<void> setNotificationEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationKey, enabled);
    } catch (e) {
      // Silently fail, tidak perlu crash app
    }
  }
}
