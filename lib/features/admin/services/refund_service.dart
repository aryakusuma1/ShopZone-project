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
    return _refundsCollection.doc(id).update({'refundStatus': newStatus});
  }
}
