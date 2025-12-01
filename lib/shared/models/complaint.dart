import 'package:cloud_firestore/cloud_firestore.dart';

class Complaint {
  final String id;
  final String orderId;
  final String userId;
  final String issueType;
  final String description;
  final String? imageUrl;
  final DateTime createdAt;
  final String status; // pending, processed, resolved

  Complaint({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.issueType,
    required this.description,
    this.imageUrl,
    required this.createdAt,
    this.status = 'pending',
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'userId': userId,
      'issueType': issueType,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }

  // Create from Firestore JSON
  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      userId: json['userId'] as String,
      issueType: json['issueType'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      status: json['status'] as String? ?? 'pending',
    );
  }
}
