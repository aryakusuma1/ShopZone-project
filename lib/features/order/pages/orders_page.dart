import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../../../shared/models/order.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../routes/app_routes.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Pesanan Saya', style: AppTextStyles.heading2),
        centerTitle: true,
      ),
      body: currentUser == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.login_outlined,
                    size: 80,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Silakan login terlebih dahulu',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('userId', isEqualTo: currentUser.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                // Loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Error state
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 80,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Terjadi kesalahan',
                          style: AppTextStyles.heading3.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            snapshot.error.toString(),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textHint,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Empty state
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 80,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada pesanan',
                          style: AppTextStyles.heading3.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pesanan Anda akan muncul di sini',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Get orders and sort by date (client-side sorting)
                final orders = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  data['id'] = doc.id;
                  return Order.fromJson(data);
                }).toList();

                // Sort by orderDate descending (newest first)
                orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));

                // Get order IDs from sorted orders
                final orderIds = orders.map((order) => order.id).toList();

                // Display orders list
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orderIds.length,
                  itemBuilder: (context, index) {
                    final orderId = orderIds[index];
                    return _OrderCard(
                      key: ValueKey(orderId),
                      orderId: orderId,
                    );
                  },
                );
              },
            ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final String orderId;

  const _OrderCard({
    super.key,
    required this.orderId,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    debugPrint('✅ _OrderCard initState for: ${widget.orderId}');
  }

  @override
  void dispose() {
    debugPrint('🗑️ _OrderCard dispose for: ${widget.orderId}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    debugPrint('🔄 Building _OrderCard for: ${widget.orderId}');

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .snapshots(includeMetadataChanges: true),
      builder: (context, snapshot) {
        // Debug logging
        if (snapshot.hasData) {
          final orderData = snapshot.data!.data() as Map<String, dynamic>?;
          if (orderData != null) {
            debugPrint('📦 Order ${widget.orderId} status: ${orderData['status']}');
          }
        }

        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Error or no data
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          debugPrint('❌ Error or no data for order: ${widget.orderId}');
          return const SizedBox.shrink();
        }

        // Parse order from snapshot
        final orderData = snapshot.data!.data() as Map<String, dynamic>;
        final order = Order.fromJson(orderData);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order ID
              Text(
                order.id,
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: 16),

              // Status Timeline
              _buildStatusTimeline(order),

              const SizedBox(height: 20),

              // Detail Pesanan Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.orderDetail,
                      arguments: order,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Detail Pesanan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusTimeline(Order order) {
    final statuses = [
      OrderStatus.diproses,
      OrderStatus.dikirim,
      OrderStatus.diterima,
    ];

    return Row(
      children: List.generate(statuses.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector line
          return Expanded(
            child: Container(
              height: 2,
              color: _isStatusCompleted(order, statuses[(index + 1) ~/ 2])
                  ? AppColors.secondary
                  : AppColors.border,
            ),
          );
        } else {
          // Status item
          final statusIndex = index ~/ 2;
          final status = statuses[statusIndex];
          return _buildStatusItem(order, status);
        }
      }),
    );
  }

  Widget _buildStatusItem(Order order, OrderStatus status) {
    final isCompleted = _isStatusCompleted(order, status);
    final isCurrent = order.status == status;
    final timestamp = order.statusTimestamps[status];

    String statusLabel;
    IconData statusIcon;

    switch (status) {
      case OrderStatus.diproses:
        statusLabel = 'Diproses';
        statusIcon = Icons.inventory_2_outlined;
        break;
      case OrderStatus.dikirim:
        statusLabel = 'Dikirim';
        statusIcon = Icons.local_shipping_outlined;
        break;
      case OrderStatus.diterima:
        statusLabel = 'Diterima';
        statusIcon = Icons.check_circle_outline;
        break;
    }

    return Column(
      children: [
        // Status Icon
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isCompleted || isCurrent
                ? AppColors.secondary
                : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Icon(
            statusIcon,
            color: isCompleted || isCurrent ? Colors.white : Colors.grey[400],
            size: 24,
          ),
        ),
        const SizedBox(height: 8),

        // Status Label
        Text(
          statusLabel,
          style: AppTextStyles.bodySmall.copyWith(
            color: isCompleted || isCurrent
                ? AppColors.primary
                : AppColors.textSecondary,
            fontWeight: isCompleted || isCurrent
                ? FontWeight.w600
                : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 4),

        // Timestamp
        if (timestamp != null)
          Text(
            _formatDate(timestamp),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textHint,
              fontSize: 10,
              height: 1.2,
            ),
          ),
      ],
    );
  }

  bool _isStatusCompleted(Order order, OrderStatus status) {
    final statusOrder = [
      OrderStatus.diproses,
      OrderStatus.dikirim,
      OrderStatus.diterima,
    ];

    final currentIndex = statusOrder.indexOf(order.status);
    final checkIndex = statusOrder.indexOf(status);

    return checkIndex <= currentIndex;
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day $month\n$hour:$minute';
  }
}
