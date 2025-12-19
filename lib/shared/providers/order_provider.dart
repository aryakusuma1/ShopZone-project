import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'dart:math';
import '../models/order.dart';
import '../models/cart_item.dart';
import '../../core/services/notification_service.dart';

class OrderProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  final List<Order> _orders = [];
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

  // Generate random alphanumeric string (uppercase letters and numbers only)
  String _generateRandomCode(int length) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Exclude confusing chars like O,0,I,1
    final random = Random.secure();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // Generate unique order ID with format: SZ-YYMMDD-XXXX
  // Example: SZ-251130-K7M9
  Future<String> _generateOrderId() async {
    final now = DateTime.now();

    // Format date part: YYMMDD
    final year = now.year.toString().substring(2); // Last 2 digits of year
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final datePart = '$year$month$day';

    // Try to generate unique ID (max 5 attempts)
    for (int attempt = 0; attempt < 5; attempt++) {
      // Generate random code
      final randomCode = _generateRandomCode(4);
      final orderId = 'SZ-$datePart-$randomCode';

      // Check if this ID already exists in Firestore
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();

      if (!orderDoc.exists) {
        // ID is unique, return it
        return orderId;
      }

      // ID already exists, try again with different random code
      debugPrint('Order ID collision detected: $orderId, retrying...');
    }

    // Fallback: If all attempts failed, use timestamp suffix for guaranteed uniqueness
    final timestamp = now.millisecondsSinceEpoch % 10000; // Last 4 digits
    final orderId = 'SZ-$datePart-$timestamp';
    debugPrint('Using timestamp-based fallback ID: $orderId');
    return orderId;
  }

  // Buat pesanan baru
  Future<String> createOrder({
    required List<CartItem> items,
    required int totalPrice,
    required int discountAmount,
    required int finalPrice,
    required String shippingAddress,
  }) async {
    if (_currentUserId == null) {
      debugPrint('ERROR: Cannot create order - user not logged in');
      throw Exception('User must be logged in to create an order');
    }

    final orderId = await _generateOrderId();
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
    _commitOrderCreation(order);

    // Tampilkan notifikasi pesanan berhasil dibuat
    await _notificationService.showOrderCreatedNotification(orderId: orderId);

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
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
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
      _updateOrderInFirestore(_orders[index]);

      // Tampilkan notifikasi berdasarkan status baru
      switch (newStatus) {
        case OrderStatus.diproses:
          await _notificationService.showOrderProcessingNotification(orderId: orderId);
          break;
        case OrderStatus.dikirim:
          await _notificationService.showOrderShippedNotification(orderId: orderId);
          break;
        case OrderStatus.diterima:
          await _notificationService.showOrderDeliveredNotification(orderId: orderId);
          break;
      }
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
        
        // Update existing order in Firestore (for status updates, etc.)
        Future<void> _updateOrderInFirestore(Order order) async {
          if (_currentUserId == null) return;
      
          try {
            final orderData = order.toJson();
            debugPrint('Updating order ${order.id} in Firestore with userId: ${order.userId}');
            await _firestore
                .collection('orders')
                .doc(order.id)
                .set(orderData); // Use set to fully overwrite or create if not exists
            debugPrint('Order ${order.id} updated successfully');
          } catch (e) {
            debugPrint('Error updating order to Firestore: $e');
          }
        }
        
        // Save order to Firestore and update product sold counts atomically
        Future<void> _commitOrderCreation(Order order) async {
          if (_currentUserId == null) return;
      
          try {
            // Create a new WriteBatch
            final batch = _firestore.batch();
      
            // 1. Add the order to the 'orders' collection
            final orderRef = _firestore.collection('orders').doc(order.id);
            batch.set(orderRef, order.toJson());
            debugPrint('Batch: Added set operation for new order ${order.id}');
      // 2. Update the 'sold' count for each product in the order
      for (final item in order.items) {
        final productRef = _firestore.collection('products').doc(item.product.id);
        final int quantitySold = item.quantity;

        debugPrint('==== UPDATE PRODUK TERJUAL ====');
        debugPrint('Produk ID: ${item.product.id}');
        debugPrint('Nama Produk: ${item.product.name}');
        debugPrint('Jumlah Terjual: $quantitySold');
        debugPrint('===============================');

        // Atomically increment the 'sold' field by the quantity purchased
        batch.update(productRef, {
          'sold': FieldValue.increment(quantitySold),
        });
        debugPrint('Batch: Added update for product ${item.product.id}, incrementing sold by $quantitySold');
      }

      // Commit the batch
      debugPrint('Mencoba melakukan commit batch ke Firestore...');
      await batch.commit();
      debugPrint('Order ${order.id} and product sold counts committed successfully');

    } catch (e) {
      debugPrint('!!!! ERROR saat commit order creation batch: $e !!!!');
      // Optional: Add error handling or retry logic here
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
