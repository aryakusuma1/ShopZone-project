import 'package:cloud_firestore/cloud_firestore.dart';

class Refund {
  final String id;
  final String complaintId; // Link ke complaint
  final String orderId;
  final String userId;
  final int refundAmount;
  final String refundStatus; // requested, processing, completed
  final DateTime createdAt;
  final DateTime? processedAt;
  final DateTime? completedAt;

  Refund({
    required this.id,
    required this.complaintId,
    required this.orderId,
    required this.userId,
    required this.refundAmount,
    this.refundStatus = 'requested',
    required this.createdAt,
    this.processedAt,
    this.completedAt,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'complaintId': complaintId,
      'orderId': orderId,
      'userId': userId,
      'refundAmount': refundAmount,
      'refundStatus': refundStatus,
      'createdAt': Timestamp.fromDate(createdAt),
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  // Create from Firestore JSON
  factory Refund.fromJson(Map<String, dynamic> json) {
    return Refund(
      id: json['id'] as String,
      complaintId: json['complaintId'] as String,
      orderId: json['orderId'] as String,
      userId: json['userId'] as String,
      refundAmount: json['refundAmount'] as int,
      refundStatus: json['refundStatus'] as String? ?? 'requested',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      processedAt: json['processedAt'] != null
          ? (json['processedAt'] as Timestamp).toDate()
          : null,
      completedAt: json['completedAt'] != null
          ? (json['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Format refund amount to currency
  String get formattedRefundAmount {
    return 'Rp ${refundAmount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  // Get status text in Indonesian
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
        return 'Diajukan';
    }
  }
}
