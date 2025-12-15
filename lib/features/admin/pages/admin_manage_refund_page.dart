import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  final List<String> _statusOptions = [
    'requested',
    'processing',
    'completed',
    'rejected'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Refunds'),
        elevation: 0,
        backgroundColor: Colors.teal,
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

          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: refunds.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
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
        if (order.items.length > 1) {
          productName += ' and ${order.items.length - 1} more';
        }
      }
    }

    return {'userEmail': userEmail, 'productName': productName};
  }

  Widget _getStatusChip(String status) {
    Color chipColor;
    String statusText = status;
    switch (status.toLowerCase()) {
      case 'requested':
        chipColor = Colors.blue.shade700;
        statusText = 'Requested';
        break;
      case 'processing':
        chipColor = Colors.orange.shade700;
        statusText = 'Processing';
        break;
      case 'completed':
        chipColor = Colors.green.shade700;
        statusText = 'Completed';
        break;
      case 'rejected':
        chipColor = Colors.red.shade700;
        statusText = 'Rejected';
        break;
      default:
        chipColor = Colors.grey.shade700;
    }
    return Chip(
      label: Text(
        statusText,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _getRelatedData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (snapshot.hasError) {
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.red.shade50,
            child: const ListTile(
              title: Text('Error loading related data'),
              leading: Icon(Icons.error, color: Colors.red),
            ),
          );
        }

        final userEmail = snapshot.data?['userEmail'] ?? 'Unknown User';
        final productName =
            snapshot.data?['productName'] ?? 'Unknown Product';

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.person_outline, color: Colors.grey.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        userEmail,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.receipt_long_outlined, color: Colors.grey.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Order: ${refund.orderId}',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, color: Colors.grey.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Requested: ${DateFormat.yMMMd().add_jm().format(refund.createdAt)}',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Refund Amount',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          refund.formattedRefundAmount,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                    _getStatusChip(refund.refundStatus),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Change Status:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                      ),
                      child: DropdownButton<String>(
                        value: refund.refundStatus,
                        underline: const SizedBox(),
                        items: statusOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value[0].toUpperCase() + value.substring(1)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            onStatusChanged(newValue);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
