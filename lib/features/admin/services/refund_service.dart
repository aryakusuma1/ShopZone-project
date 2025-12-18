import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shopzone/shared/models/refund.dart';

class RefundService {
  final CollectionReference _refundsCollection =
      FirebaseFirestore.instance.collection('refunds');

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

  Future<void> updateRefundStatus(String id, String newStatus) {
    final updates = <String, dynamic>{'refundStatus': newStatus};

    // Update status timestamps when status changes
    final now = Timestamp.now();
    switch (newStatus.toLowerCase()) {
      case 'processing':
      case 'diproses':
        updates['statusTimestamps.1'] = now; // RefundStatus.diproses index = 1
        break;
      case 'completed':
      case 'selesai':
        updates['statusTimestamps.2'] = now; // RefundStatus.selesai index = 2
        break;
      case 'rejected':
      case 'ditolak':
        updates['statusTimestamps.3'] = now; // RefundStatus.ditolak index = 3
        break;
    }

    return _refundsCollection.doc(id).update(updates);
  }
}
