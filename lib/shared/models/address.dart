import 'package:cloud_firestore/cloud_firestore.dart';

class Address {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String fullAddress;
  final DateTime createdAt;

  Address({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.fullAddress,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'phone': phone,
      'fullAddress': fullAddress,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    DateTime createdAt = DateTime.now();

    if (json['createdAt'] != null) {
      if (json['createdAt'] is Timestamp) {
        // From Firestore Timestamp
        createdAt = (json['createdAt'] as Timestamp).toDate();
      } else if (json['createdAt'] is String) {
        // From ISO8601 string
        createdAt = DateTime.parse(json['createdAt']);
      }
    }

    return Address(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      fullAddress: json['fullAddress'] ?? '',
      createdAt: createdAt,
    );
  }

  Address copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    String? fullAddress,
    DateTime? createdAt,
  }) {
    return Address(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      fullAddress: fullAddress ?? this.fullAddress,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
