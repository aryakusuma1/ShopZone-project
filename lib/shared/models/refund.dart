import 'package:cloud_firestore/cloud_firestore.dart';

class Refund {
  final String id;
  final String complaintId;
  final String orderId;
  final String userId;
  final int refundAmount;
  final String refundStatus;
  final DateTime createdAt;
  final DateTime? processedAt;
  final DateTime? completedAt;

  Refund({
    required this.id,
    required this.complaintId,
    required this.orderId,
    required this.userId,
    required this.refundAmount,
    required this.refundStatus,
    required this.createdAt,
    this.processedAt,
    this.completedAt,
  });

  factory Refund.fromJson(Map<String, dynamic> json) {
    return Refund(
      id: json['id'] ?? '',
      complaintId: json['complaintId'] ?? '',
      orderId: json['orderId'] ?? '',
      userId: json['userId'] ?? '',
      refundAmount: json['refundAmount'] ?? 0,
      refundStatus: json['refundStatus'] ?? 'requested',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      processedAt: json['processedAt'] != null
          ? (json['processedAt'] as Timestamp).toDate()
          : null,
      completedAt: json['completedAt'] != null
          ? (json['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'complaintId': complaintId,
      'orderId': orderId,
      'userId': userId,
      'refundAmount': refundAmount,
      'refundStatus': refundStatus,
      'createdAt': createdAt,
      'processedAt': processedAt,
      'completedAt': completedAt,
    };
  }

    String get formattedRefundAmount {
    return 'Rp${refundAmount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }

  String get statusText {
    switch (refundStatus.toLowerCase()) {
      case 'requested':
        return 'Diajukan';
      case 'processing':
        return 'Diproses';
      case 'completed':
        return 'Selesai';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Unknown';
    }
  }
}
