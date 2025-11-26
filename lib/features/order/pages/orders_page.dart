import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/providers/order_provider.dart';
import '../../../shared/models/order.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../routes/app_routes.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  @override
  void initState() {
    super.initState();
    // Load orders when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      debugPrint('OrdersPage opened - Current user: ${orderProvider.currentUserId}');
      debugPrint('Current orders count: ${orderProvider.orders.length}');
      orderProvider.reloadOrders();
    });
  }

  Future<void> _refreshOrders() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    await orderProvider.reloadOrders();
  }

  @override
  Widget build(BuildContext context) {
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
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          if (orderProvider.orders.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshOrders,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 100,
                  child: Center(
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
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshOrders,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orderProvider.orders.length,
              itemBuilder: (context, index) {
                final order = orderProvider.orders[index];
                return _OrderCard(order: order);
              },
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
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
          _buildStatusTimeline(),

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
  }

  Widget _buildStatusTimeline() {
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
              color: _isStatusCompleted(statuses[(index + 1) ~/ 2])
                  ? AppColors.secondary
                  : AppColors.border,
            ),
          );
        } else {
          // Status item
          final statusIndex = index ~/ 2;
          final status = statuses[statusIndex];
          return _buildStatusItem(status);
        }
      }),
    );
  }

  Widget _buildStatusItem(OrderStatus status) {
    final isCompleted = _isStatusCompleted(status);
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

  bool _isStatusCompleted(OrderStatus status) {
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
