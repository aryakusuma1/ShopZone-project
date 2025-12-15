import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shopzone/features/admin/services/refund_service.dart';
import 'package:shopzone/shared/models/order.dart' as order_model;
import 'package:shopzone/shared/models/refund.dart';

class AdminManageRefundPage extends StatefulWidget {
  const AdminManageRefundPage({Key? key}) : super(key: key);

  @override
  _AdminManageRefundPageState createState() => _AdminManageRefundPageState();
}

class _AdminManageRefundPageState extends State<AdminManageRefundPage> {
  final RefundService _refundService = RefundService();
  final List<String> _statusOptions = ['requested', 'processing', 'completed', 'rejected'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Refunds'),
      ),
      body: StreamBuilder<List<Refund>>(
        stream: _refundService.getRefunds(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No refund requests.'));
          }

          final refunds = snapshot.data!;

          return ListView.builder(
            itemCount: refunds.length,
            itemBuilder: (context, index) {
              final refund = refunds[index];
              return RefundCard(
                refund: refund,
                statusOptions: _statusOptions,
                onStatusChanged: (newStatus) {
                  _refundService.updateRefundStatus(refund.id, newStatus);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class RefundCard extends StatelessWidget {
  final Refund refund;
  final List<String> statusOptions;
  final ValueChanged<String> onStatusChanged;

  const RefundCard({
    Key? key,
    required this.refund,
    required this.statusOptions,
    required this.onStatusChanged,
  }) : super(key: key);

  // This is inefficient as it runs a query for each item in the list.
  // For a production app, it would be better to denormalize the data
  // or fetch all users and orders once.
  Future<Map<String, String>> _getRelatedData() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(refund.userId)
        .get();
    final orderDoc = await FirebaseFirestore.instance
        .collection('orders')
        .doc(refund.orderId)
        .get();

    String userEmail = 'Unknown User';
    if (userDoc.exists && userDoc.data()!.containsKey('email')) {
      userEmail = userDoc.data()!['email'];
    }

    String productName = 'Unknown Product';
    if (orderDoc.exists) {
      final order = order_model.Order.fromJson(orderDoc.data()!);
      if (order.items.isNotEmpty) {
        productName = order.items.first.product.name;
      }
    }

    return {'userEmail': userEmail, 'productName': productName};
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _getRelatedData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            margin: EdgeInsets.all(8.0),
            child: ListTile(
              title: Text('Loading...'),
              subtitle: Text('...'),
            ),
          );
        }
        if (snapshot.hasError) {
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: const Text('Error loading data'),
              subtitle: Text(snapshot.error.toString()),
            ),
          );
        }

        final userEmail = snapshot.data?['userEmail'] ?? 'Unknown User';
        final productName = snapshot.data?['productName'] ?? 'Unknown Product';

        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            title: Text(productName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order ID: ${refund.orderId}'),
                Text('User: $userEmail'),
                Text('Price: ${refund.formattedRefundAmount}'),
              ],
            ),
            trailing: DropdownButton<String>(
              value: refund.refundStatus,
              items: statusOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  onStatusChanged(newValue);
                }
              },
            ),
          ),
        );
      },
    );
  }
}
