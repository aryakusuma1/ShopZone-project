import 'package:cloud_firestore/cloud_firestore.dart';

enum RefundStatus {
  ajukan,    // requested - 0
  diproses,  // processing - 1
  selesai,   // completed - 2
  ditolak,   // rejected - 3
}

class Refund {
  final String id;
  final String complaintId;
  final String orderId;
  final String userId;
  final int refundAmount;
  final RefundStatus status;
  final DateTime createdAt;
  final Map<RefundStatus, DateTime> statusTimestamps;

  Refund({
    required this.id,
    required this.complaintId,
    required this.orderId,
    required this.userId,
    required this.refundAmount,
    required this.status,
    required this.createdAt,
    Map<RefundStatus, DateTime>? statusTimestamps,
  }) : statusTimestamps = statusTimestamps ?? {};

  factory Refund.fromJson(Map<String, dynamic> json) {
    // Parse status from old string format or new index format
    RefundStatus parsedStatus = RefundStatus.ajukan;
    if (json['refundStatus'] is int) {
      parsedStatus = RefundStatus.values[json['refundStatus']];
    } else if (json['refundStatus'] is String) {
      final statusStr = json['refundStatus'].toString().toLowerCase();
      if (statusStr == 'processing' || statusStr == 'diproses') {
        parsedStatus = RefundStatus.diproses;
      } else if (statusStr == 'completed' || statusStr == 'selesai') {
        parsedStatus = RefundStatus.selesai;
      } else if (statusStr == 'rejected' || statusStr == 'ditolak') {
        parsedStatus = RefundStatus.ditolak;
      } else {
        parsedStatus = RefundStatus.ajukan;
      }
    }

    // Parse statusTimestamps
    Map<RefundStatus, DateTime> timestamps = {};
    if (json['statusTimestamps'] != null) {
      final timestampsData = json['statusTimestamps'] as Map<String, dynamic>;
      timestampsData.forEach((key, value) {
        final statusIndex = int.parse(key);
        final status = RefundStatus.values[statusIndex];
        // Handle both Timestamp and String formats for backward compatibility
        if (value is Timestamp) {
          timestamps[status] = value.toDate();
        } else if (value is String) {
          timestamps[status] = DateTime.parse(value);
        }
      });
    } else {
      // Backward compatibility: create timestamps from old fields
      timestamps[RefundStatus.ajukan] = (json['createdAt'] as Timestamp).toDate();
      if (json['processedAt'] != null) {
        timestamps[RefundStatus.diproses] = (json['processedAt'] as Timestamp).toDate();
      }
      if (json['completedAt'] != null) {
        timestamps[RefundStatus.selesai] = (json['completedAt'] as Timestamp).toDate();
      }
    }

    return Refund(
      id: json['id'] ?? '',
      complaintId: json['complaintId'] ?? '',
      orderId: json['orderId'] ?? '',
      userId: json['userId'] ?? '',
      refundAmount: json['refundAmount'] ?? 0,
      status: parsedStatus,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      statusTimestamps: timestamps,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'complaintId': complaintId,
      'orderId': orderId,
      'userId': userId,
      'refundAmount': refundAmount,
      'refundStatus': status.index,
      'createdAt': Timestamp.fromDate(createdAt),
      'statusTimestamps': statusTimestamps.map(
        (key, value) => MapEntry(key.index.toString(), Timestamp.fromDate(value)),
      ),
    };
  }

  String get formattedRefundAmount {
    return 'Rp${refundAmount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }

  String get statusText {
    switch (status) {
      case RefundStatus.ajukan:
        return 'Ajukan';
      case RefundStatus.diproses:
        return 'Diproses';
      case RefundStatus.selesai:
        return 'Selesai';
      case RefundStatus.ditolak:
        return 'Ditolak';
    }
  }

  // For backward compatibility with old refundStatus string
  String get refundStatus {
    switch (status) {
      case RefundStatus.ajukan:
        return 'requested';
      case RefundStatus.diproses:
        return 'processing';
      case RefundStatus.selesai:
        return 'completed';
      case RefundStatus.ditolak:
        return 'rejected';
    }
  }
}
