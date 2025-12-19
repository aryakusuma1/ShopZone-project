import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'notification_settings_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final NotificationSettingsService _settingsService =
      NotificationSettingsService();

  bool _initialized = false;

  /// Inisialisasi notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions untuk Android 13+
    await _requestPermissions();

    // Create notification channels
    await _createNotificationChannels();

    _initialized = true;
    debugPrint('NotificationService initialized successfully');
  }

  /// Request permissions untuk notifications (Android 13+)
  Future<void> _requestPermissions() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// Create notification channels untuk Android
  Future<void> _createNotificationChannels() async {
    // Channel untuk order notifications
    const orderChannel = AndroidNotificationChannel(
      'order_channel',
      'Notifikasi Pesanan',
      description: 'Notifikasi untuk status pesanan',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    // Channel untuk retur/complaint notifications
    const returChannel = AndroidNotificationChannel(
      'retur_channel',
      'Notifikasi Retur',
      description: 'Notifikasi untuk status retur/komplain',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    // Channel untuk refund notifications
    const refundChannel = AndroidNotificationChannel(
      'refund_channel',
      'Notifikasi Refund',
      description: 'Notifikasi untuk status pengembalian dana',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    // Channel untuk admin notifications
    const adminChannel = AndroidNotificationChannel(
      'admin_channel',
      'Notifikasi Admin',
      description: 'Notifikasi untuk aktivitas admin',
      importance: Importance.defaultImportance,
      enableVibration: true,
      playSound: true,
    );

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(orderChannel);
      await androidPlugin.createNotificationChannel(returChannel);
      await androidPlugin.createNotificationChannel(refundChannel);
      await androidPlugin.createNotificationChannel(adminChannel);
    }
  }

  /// Handler ketika notification di-tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // TODO: Handle navigation berdasarkan payload jika diperlukan
  }

  // ==================== ORDER NOTIFICATIONS ====================

  /// Notifikasi ketika pesanan berhasil dibuat
  Future<void> showOrderCreatedNotification({
    required String orderId,
  }) async {
    await _showNotification(
      id: orderId.hashCode,
      title: '🛍️ Pesanan Berhasil Dibuat',
      body: 'Pesanan $orderId telah dibuat dan sedang diproses',
      channelId: 'order_channel',
      payload: 'order:$orderId',
    );
  }

  /// Notifikasi ketika pesanan sedang diproses
  Future<void> showOrderProcessingNotification({
    required String orderId,
  }) async {
    await _showNotification(
      id: orderId.hashCode,
      title: '📦 Pesanan Sedang Diproses',
      body: 'Pesanan $orderId sedang diproses oleh admin',
      channelId: 'order_channel',
      payload: 'order:$orderId',
    );
  }

  /// Notifikasi ketika pesanan sedang dikirim
  Future<void> showOrderShippedNotification({
    required String orderId,
  }) async {
    await _showNotification(
      id: orderId.hashCode,
      title: '🚚 Pesanan Sedang Dikirim',
      body: 'Pesanan $orderId sedang dalam perjalanan menuju Anda',
      channelId: 'order_channel',
      payload: 'order:$orderId',
    );
  }

  /// Notifikasi ketika pesanan telah diterima
  Future<void> showOrderDeliveredNotification({
    required String orderId,
  }) async {
    await _showNotification(
      id: orderId.hashCode,
      title: '✅ Pesanan Telah Diterima',
      body: 'Pesanan $orderId telah diterima. Terima kasih!',
      channelId: 'order_channel',
      payload: 'order:$orderId',
    );
  }

  // ==================== COMPLAINT/RETUR NOTIFICATIONS ====================

  /// Notifikasi ketika retur/komplain diajukan
  Future<void> showComplaintSubmittedNotification({
    required String orderId,
    required String issueType,
  }) async {
    await _showNotification(
      id: 'complaint_$orderId'.hashCode,
      title: '📝 Retur Telah Diajukan',
      body: 'Komplain untuk pesanan $orderId ($issueType) telah diajukan',
      channelId: 'retur_channel',
      payload: 'complaint:$orderId',
    );
  }

  /// Notifikasi ketika retur sedang diproses
  Future<void> showComplaintProcessingNotification({
    required String orderId,
  }) async {
    await _showNotification(
      id: 'complaint_$orderId'.hashCode,
      title: '🔄 Retur Sedang Diproses',
      body: 'Komplain pesanan $orderId sedang ditinjau oleh admin',
      channelId: 'retur_channel',
      payload: 'complaint:$orderId',
    );
  }

  /// Notifikasi ketika retur selesai
  Future<void> showComplaintResolvedNotification({
    required String orderId,
  }) async {
    await _showNotification(
      id: 'complaint_$orderId'.hashCode,
      title: '✅ Retur Selesai',
      body: 'Komplain pesanan $orderId telah diselesaikan',
      channelId: 'retur_channel',
      payload: 'complaint:$orderId',
    );
  }

  // ==================== REFUND NOTIFICATIONS ====================

  /// Notifikasi ketika refund diajukan
  Future<void> showRefundRequestedNotification({
    required String orderId,
    required int amount,
  }) async {
    final formattedAmount = _formatCurrency(amount);
    await _showNotification(
      id: 'refund_$orderId'.hashCode,
      title: '💰 Refund Telah Diajukan',
      body: 'Permintaan refund $formattedAmount untuk pesanan $orderId telah diajukan',
      channelId: 'refund_channel',
      payload: 'refund:$orderId',
    );
  }

  /// Notifikasi ketika refund sedang diproses
  Future<void> showRefundProcessingNotification({
    required String orderId,
    required int amount,
  }) async {
    final formattedAmount = _formatCurrency(amount);
    await _showNotification(
      id: 'refund_$orderId'.hashCode,
      title: '🔄 Refund Sedang Diproses',
      body: 'Refund $formattedAmount untuk pesanan $orderId sedang diproses',
      channelId: 'refund_channel',
      payload: 'refund:$orderId',
    );
  }

  /// Notifikasi ketika refund selesai
  Future<void> showRefundCompletedNotification({
    required String orderId,
    required int amount,
  }) async {
    final formattedAmount = _formatCurrency(amount);
    await _showNotification(
      id: 'refund_$orderId'.hashCode,
      title: '✅ Refund Telah Selesai',
      body: 'Refund $formattedAmount untuk pesanan $orderId telah dikembalikan',
      channelId: 'refund_channel',
      payload: 'refund:$orderId',
    );
  }

  /// Notifikasi ketika refund ditolak
  Future<void> showRefundRejectedNotification({
    required String orderId,
    required int amount,
  }) async {
    final formattedAmount = _formatCurrency(amount);
    await _showNotification(
      id: 'refund_$orderId'.hashCode,
      title: '❌ Refund Ditolak',
      body: 'Refund $formattedAmount untuk pesanan $orderId ditolak',
      channelId: 'refund_channel',
      payload: 'refund:$orderId',
    );
  }

  // ==================== ADMIN NOTIFICATIONS ====================

  /// Notifikasi untuk admin ketika ada order baru
  Future<void> showAdminNewOrderNotification({
    required String orderId,
    required String customerEmail,
  }) async {
    await _showNotification(
      id: 'admin_order_$orderId'.hashCode,
      title: '🔔 Pesanan Baru',
      body: 'Pesanan baru $orderId dari $customerEmail',
      channelId: 'admin_channel',
      payload: 'admin_order:$orderId',
    );
  }

  /// Notifikasi untuk admin ketika ada complaint baru
  Future<void> showAdminNewComplaintNotification({
    required String orderId,
    required String issueType,
  }) async {
    await _showNotification(
      id: 'admin_complaint_$orderId'.hashCode,
      title: '🔔 Komplain Baru',
      body: 'Komplain baru untuk pesanan $orderId: $issueType',
      channelId: 'admin_channel',
      payload: 'admin_complaint:$orderId',
    );
  }

  /// Notifikasi untuk admin ketika ada refund request baru
  Future<void> showAdminNewRefundNotification({
    required String orderId,
    required int amount,
  }) async {
    final formattedAmount = _formatCurrency(amount);
    await _showNotification(
      id: 'admin_refund_$orderId'.hashCode,
      title: '🔔 Permintaan Refund Baru',
      body: 'Permintaan refund $formattedAmount untuk pesanan $orderId',
      channelId: 'admin_channel',
      payload: 'admin_refund:$orderId',
    );
  }

  // ==================== HELPER METHODS ====================

  /// Method umum untuk menampilkan notifikasi
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    required String channelId,
    String? payload,
  }) async {
    // Check if notification is enabled
    final isEnabled = await _settingsService.isNotificationEnabled();
    if (!isEnabled) {
      debugPrint('Notification disabled by user, skipping: $title');
      return;
    }

    if (!_initialized) {
      debugPrint('NotificationService not initialized, initializing now...');
      await initialize();
    }

    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default Channel',
      channelDescription: 'Default notification channel',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );

    debugPrint('Notification shown: $title - $body');
  }

  /// Format currency ke Rupiah
  String _formatCurrency(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
