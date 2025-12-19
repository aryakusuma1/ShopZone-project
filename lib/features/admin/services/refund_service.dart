import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shopzone/shared/models/refund.dart';
import 'package:shopzone/core/services/notification_service.dart';

class RefundService {
  final CollectionReference _refundsCollection =
      FirebaseFirestore.instance.collection('refunds');
  final NotificationService _notificationService = NotificationService();

  Stream<List<Refund>> getRefunds() {
    return _refundsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Refund.fromJson(data);
      }).toList();
    });
  }

  Future<void> updateRefundStatus(String id, String newStatus) async {
    // Prepare updates dengan status dan timestamps
    final updates = <String, dynamic>{'refundStatus': newStatus};

    // Update status timestamps ketika status berubah
    final now = Timestamp.now();
    switch (newStatus.toLowerCase()) {
      case 'processing':
      case 'diproses':
        updates['processedAt'] = now;
        break;
      case 'completed':
      case 'selesai':
        updates['completedAt'] = now;
        break;
      case 'rejected':
      case 'ditolak':
        updates['rejectedAt'] = now;
        break;
    }

    // Update status di Firestore
    await _refundsCollection.doc(id).update(updates);

    // Ambil data refund untuk notifikasi
    final refundDoc = await _refundsCollection.doc(id).get();
    if (refundDoc.exists) {
      final refundData = refundDoc.data() as Map<String, dynamic>;
      final refund = Refund.fromJson({...refundData, 'id': id});

      // Kirim notifikasi berdasarkan status baru
      switch (newStatus.toLowerCase()) {
        case 'processing':
        case 'diproses':
          await _notificationService.showRefundProcessingNotification(
            orderId: refund.orderId,
            amount: refund.refundAmount,
          );
          break;
        case 'completed':
        case 'selesai':
          await _notificationService.showRefundCompletedNotification(
            orderId: refund.orderId,
            amount: refund.refundAmount,
          );
          break;
        case 'rejected':
        case 'ditolak':
          await _notificationService.showRefundRejectedNotification(
            orderId: refund.orderId,
            amount: refund.refundAmount,
          );
          break;
      }
    }
  }
}
