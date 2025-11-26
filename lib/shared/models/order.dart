import 'cart_item.dart';

enum OrderStatus {
  diproses,
  dikirim,
  diterima,
}

class Order {
  final String id;
  final String userId;
  final DateTime orderDate;
  final List<CartItem> items;
  final int totalPrice;
  final int discountAmount;
  final int finalPrice;
  final String shippingAddress;
  final OrderStatus status;
  final Map<OrderStatus, DateTime> statusTimestamps;

  Order({
    required this.id,
    required this.userId,
    required this.orderDate,
    required this.items,
    required this.totalPrice,
    required this.discountAmount,
    required this.finalPrice,
    required this.shippingAddress,
    required this.status,
    required this.statusTimestamps,
  });

  String get formattedTotalPrice {
    return 'Rp${totalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  String get formattedDiscountAmount {
    if (discountAmount == 0) return '-';
    return 'Rp${discountAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  String get formattedFinalPrice {
    return 'Rp${finalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  String get statusText {
    switch (status) {
      case OrderStatus.diproses:
        return 'Diproses';
      case OrderStatus.dikirim:
        return 'Dikirim';
      case OrderStatus.diterima:
        return 'Diterima';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'orderDate': orderDate.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'totalPrice': totalPrice,
      'discountAmount': discountAmount,
      'finalPrice': finalPrice,
      'shippingAddress': shippingAddress,
      'status': status.index,
      'statusTimestamps': statusTimestamps.map(
        (key, value) => MapEntry(key.index.toString(), value.toIso8601String()),
      ),
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    // Parse statusTimestamps
    final Map<OrderStatus, DateTime> timestamps = {};
    if (json['statusTimestamps'] != null) {
      final Map<String, dynamic> timestampsMap = json['statusTimestamps'];
      timestampsMap.forEach((key, value) {
        final statusIndex = int.parse(key);
        timestamps[OrderStatus.values[statusIndex]] = DateTime.parse(value);
      });
    }

    return Order(
      id: json['id'],
      userId: json['userId'] ?? '',
      orderDate: DateTime.parse(json['orderDate']),
      items: (json['items'] as List)
          .map((item) => CartItem.fromJson(item))
          .toList(),
      totalPrice: json['totalPrice'],
      discountAmount: json['discountAmount'],
      finalPrice: json['finalPrice'],
      shippingAddress: json['shippingAddress'],
      status: OrderStatus.values[json['status']],
      statusTimestamps: timestamps,
    );
  }
}
