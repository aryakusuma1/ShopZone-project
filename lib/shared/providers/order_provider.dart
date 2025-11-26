import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/order.dart';
import '../models/cart_item.dart';

class OrderProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Order> _orders = [];
  int _orderCounter = 277280289; // Starting order number from the screenshot
  String? _currentUserId;

  OrderProvider() {
    // Check if user is already logged in
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      _currentUserId = currentUser.uid;
      _loadOrdersFromFirestore();
    }

    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      if (user != null && user.uid != _currentUserId) {
        // User logged in or switched, load their orders
        _currentUserId = user.uid;
        _loadOrdersFromFirestore();
      } else if (user == null) {
        // User logged out, clear orders
        _currentUserId = null;
        _clearLocalOrders();
      }
    });
  }

  // Getter untuk mendapatkan semua pesanan
  List<Order> get orders => _orders;

  // Getter untuk jumlah pesanan
  int get orderCount => _orders.length;

  // Buat pesanan baru
  String createOrder({
    required List<CartItem> items,
    required int totalPrice,
    required int discountAmount,
    required int finalPrice,
    required String shippingAddress,
  }) {
    if (_currentUserId == null) {
      debugPrint('ERROR: Cannot create order - user not logged in');
      throw Exception('User must be logged in to create an order');
    }

    final orderId = '#${_orderCounter++}';
    final now = DateTime.now();

    final order = Order(
      id: orderId,
      userId: _currentUserId!,
      orderDate: now,
      items: items.map((item) => CartItem(
        product: item.product,
        quantity: item.quantity,
      )).toList(),
      totalPrice: totalPrice,
      discountAmount: discountAmount,
      finalPrice: finalPrice,
      shippingAddress: shippingAddress,
      status: OrderStatus.diproses,
      statusTimestamps: {
        OrderStatus.diproses: now,
      },
    );

    _orders.insert(0, order); // Insert at beginning to show newest first
    debugPrint('Created order $orderId for user $_currentUserId');
    notifyListeners();
    _saveOrderToFirestore(order);

    return orderId;
  }

  // Dapatkan pesanan berdasarkan ID
  Order? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  // Update status pesanan
  void updateOrderStatus(String orderId, OrderStatus newStatus) {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index >= 0) {
      final order = _orders[index];
      final updatedTimestamps = Map<OrderStatus, DateTime>.from(order.statusTimestamps);
      updatedTimestamps[newStatus] = DateTime.now();

      _orders[index] = Order(
        id: order.id,
        userId: order.userId,
        orderDate: order.orderDate,
        items: order.items,
        totalPrice: order.totalPrice,
        discountAmount: order.discountAmount,
        finalPrice: order.finalPrice,
        shippingAddress: order.shippingAddress,
        status: newStatus,
        statusTimestamps: updatedTimestamps,
      );

      notifyListeners();
      _saveOrderToFirestore(_orders[index]);
    }
  }

  // Dapatkan pesanan berdasarkan status
  List<Order> getOrdersByStatus(OrderStatus status) {
    return _orders.where((order) => order.status == status).toList();
  }

  // Hapus pesanan (untuk testing)
  void removeOrder(String orderId) {
    _orders.removeWhere((order) => order.id == orderId);
    notifyListeners();
  }

  // Clear semua pesanan (untuk testing)
  void clearOrders() {
    _orders.clear();
    notifyListeners();
  }

  // Load orders from Firestore for current user
  Future<void> _loadOrdersFromFirestore() async {
    if (_currentUserId == null) return;

    try {
      QuerySnapshot querySnapshot;

      try {
        // Try to query with orderBy (requires composite index)
        querySnapshot = await _firestore
            .collection('orders')
            .where('userId', isEqualTo: _currentUserId)
            .orderBy('orderDate', descending: true)
            .get();
      } catch (e) {
        // If composite index doesn't exist, fall back to simple query
        debugPrint('Composite index not available, using simple query: $e');
        querySnapshot = await _firestore
            .collection('orders')
            .where('userId', isEqualTo: _currentUserId)
            .get();
      }

      _orders.clear();

      for (var doc in querySnapshot.docs) {
        try {
          final order = Order.fromJson(doc.data() as Map<String, dynamic>);
          _orders.add(order);

          // Update order counter if needed
          final orderNumber = int.tryParse(order.id.replaceAll('#', ''));
          if (orderNumber != null && orderNumber >= _orderCounter) {
            _orderCounter = orderNumber + 1;
          }
        } catch (e) {
          debugPrint('Error parsing order ${doc.id}: $e');
        }
      }

      // Sort orders by date in memory if we couldn't do it in the query
      _orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));

      debugPrint('Loaded ${_orders.length} orders for user $_currentUserId');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading orders from Firestore: $e');
    }
  }

  // Save order to Firestore
  Future<void> _saveOrderToFirestore(Order order) async {
    if (_currentUserId == null) return;

    try {
      final orderData = order.toJson();
      debugPrint('Saving order ${order.id} to Firestore with userId: ${order.userId}');
      await _firestore
          .collection('orders')
          .doc(order.id)
          .set(orderData);
      debugPrint('Order ${order.id} saved successfully');
    } catch (e) {
      debugPrint('Error saving order to Firestore: $e');
    }
  }

  // Clear local orders (when user logs out)
  void _clearLocalOrders() {
    _orders.clear();
    debugPrint('Cleared local orders');
    notifyListeners();
  }

  // Public method to reload orders from Firestore
  Future<void> reloadOrders() async {
    debugPrint('Manually reloading orders for user $_currentUserId');
    await _loadOrdersFromFirestore();
  }

  // Get current user ID for debugging
  String? get currentUserId => _currentUserId;
}
