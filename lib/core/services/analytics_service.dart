import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: _analytics);

  // Log screen view
  static Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
  }

  // Log user login
  static Future<void> logLogin({required String method}) async {
    await _analytics.logLogin(loginMethod: method);
  }

  // Log user signup
  static Future<void> logSignUp({required String method}) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  // Log product view
  static Future<void> logViewItem({
    required String itemId,
    required String itemName,
    String? itemCategory,
    double? price,
  }) async {
    await _analytics.logViewItem(
      currency: 'IDR',
      value: price,
      items: [
        AnalyticsEventItem(
          itemId: itemId,
          itemName: itemName,
          itemCategory: itemCategory,
          price: price,
        ),
      ],
    );
  }

  // Log add to cart
  static Future<void> logAddToCart({
    required String itemId,
    required String itemName,
    String? itemCategory,
    required double price,
    required int quantity,
  }) async {
    await _analytics.logAddToCart(
      currency: 'IDR',
      value: price * quantity,
      items: [
        AnalyticsEventItem(
          itemId: itemId,
          itemName: itemName,
          itemCategory: itemCategory,
          price: price,
          quantity: quantity,
        ),
      ],
    );
  }

  // Log purchase/checkout
  static Future<void> logPurchase({
    required String transactionId,
    required double value,
    required List<AnalyticsEventItem> items,
  }) async {
    await _analytics.logPurchase(
      currency: 'IDR',
      transactionId: transactionId,
      value: value,
      items: items,
    );
  }

  // Log search
  static Future<void> logSearch({required String searchTerm}) async {
    await _analytics.logSearch(searchTerm: searchTerm);
  }

  // Log custom event
  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await _analytics.logEvent(
      name: name,
      parameters: parameters,
    );
  }

  // Set user properties
  static Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }

  static Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }
}
