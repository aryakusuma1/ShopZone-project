import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../shared/models/order.dart';

class AdminManageOrdersPage extends StatelessWidget {
  const AdminManageOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Manage Pesanan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('orderDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada pesanan',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          final orders = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Order.fromJson(data);
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _OrderCard(order: order);
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _isUpdating = false;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.order.userId)
          .get();

      if (userDoc.exists && mounted) {
        setState(() {
          _userEmail = userDoc.data()?['email'] ?? 'Unknown User';
        });
      }
    } catch (e) {
      debugPrint('Error loading user email: $e');
      if (mounted) {
        setState(() {
          _userEmail = 'Unknown User';
        });
      }
    }
  }

  Future<void> _updateOrderStatus(OrderStatus newStatus) async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      // Create updated statusTimestamps
      final updatedTimestamps = Map<OrderStatus, DateTime>.from(widget.order.statusTimestamps);
      updatedTimestamps[newStatus] = DateTime.now();

      // Update order in Firestore
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.order.id)
          .update({
        'status': newStatus.index,
        'statusTimestamps': updatedTimestamps.map(
          (key, value) => MapEntry(key.index.toString(), value.toIso8601String()),
        ),
      });

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Status pesanan diubah menjadi ${_getStatusText(newStatus)}',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Gagal mengubah status: $e')),
            ],
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.diproses:
        return 'Diproses';
      case OrderStatus.dikirim:
        return 'Dikirim';
      case OrderStatus.diterima:
        return 'Diterima';
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.diproses:
        return Colors.blue;
      case OrderStatus.dikirim:
        return Colors.orange;
      case OrderStatus.diterima:
        return Colors.green;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.diproses:
        return Icons.inventory_2;
      case OrderStatus.dikirim:
        return Icons.local_shipping;
      case OrderStatus.diterima:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = widget.order.statusTimestamps[widget.order.status];
    final formattedDate = timestamp != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(timestamp)
        : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.order.id,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(widget.order.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(widget.order.status),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(widget.order.status),
                            size: 16,
                            color: _getStatusColor(widget.order.status),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getStatusText(widget.order.status),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(widget.order.status),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _userEmail ?? 'Loading...',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Order Items Summary
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.order.items.length} Item',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.order.formattedFinalPrice,
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Status Progress
                _buildStatusProgress(),

                const SizedBox(height: 16),

                // Update Status Buttons
                Text(
                  'Ubah Status:',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _StatusButton(
                        status: OrderStatus.diproses,
                        currentStatus: widget.order.status,
                        isUpdating: _isUpdating,
                        onPressed: () => _updateOrderStatus(OrderStatus.diproses),
                        getStatusText: _getStatusText,
                        getStatusColor: _getStatusColor,
                        getStatusIcon: _getStatusIcon,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatusButton(
                        status: OrderStatus.dikirim,
                        currentStatus: widget.order.status,
                        isUpdating: _isUpdating,
                        onPressed: () => _updateOrderStatus(OrderStatus.dikirim),
                        getStatusText: _getStatusText,
                        getStatusColor: _getStatusColor,
                        getStatusIcon: _getStatusIcon,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatusButton(
                        status: OrderStatus.diterima,
                        currentStatus: widget.order.status,
                        isUpdating: _isUpdating,
                        onPressed: () => _updateOrderStatus(OrderStatus.diterima),
                        getStatusText: _getStatusText,
                        getStatusColor: _getStatusColor,
                        getStatusIcon: _getStatusIcon,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusProgress() {
    return Row(
      children: [
        _buildProgressStep(
          status: OrderStatus.diproses,
          isActive: widget.order.status.index >= OrderStatus.diproses.index,
          isCompleted: widget.order.status.index > OrderStatus.diproses.index,
        ),
        _buildProgressLine(
          isActive: widget.order.status.index > OrderStatus.diproses.index,
        ),
        _buildProgressStep(
          status: OrderStatus.dikirim,
          isActive: widget.order.status.index >= OrderStatus.dikirim.index,
          isCompleted: widget.order.status.index > OrderStatus.dikirim.index,
        ),
        _buildProgressLine(
          isActive: widget.order.status.index > OrderStatus.dikirim.index,
        ),
        _buildProgressStep(
          status: OrderStatus.diterima,
          isActive: widget.order.status.index >= OrderStatus.diterima.index,
          isCompleted: false,
        ),
      ],
    );
  }

  Widget _buildProgressStep({
    required OrderStatus status,
    required bool isActive,
    required bool isCompleted,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive
                ? _getStatusColor(status)
                : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check : _getStatusIcon(status),
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _getStatusText(status),
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? _getStatusColor(status) : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine({required bool isActive}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 30),
        color: isActive ? AppColors.primary : Colors.grey[300],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final OrderStatus status;
  final OrderStatus currentStatus;
  final bool isUpdating;
  final VoidCallback onPressed;
  final String Function(OrderStatus) getStatusText;
  final Color Function(OrderStatus) getStatusColor;
  final IconData Function(OrderStatus) getStatusIcon;

  const _StatusButton({
    required this.status,
    required this.currentStatus,
    required this.isUpdating,
    required this.onPressed,
    required this.getStatusText,
    required this.getStatusColor,
    required this.getStatusIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentStatus = status == currentStatus;
    final color = getStatusColor(status);

    return ElevatedButton(
      onPressed: isUpdating || isCurrentStatus ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isCurrentStatus ? color : Colors.white,
        foregroundColor: isCurrentStatus ? Colors.white : color,
        disabledBackgroundColor: isCurrentStatus ? color : Colors.grey[300],
        disabledForegroundColor: isCurrentStatus ? Colors.white : Colors.grey,
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isCurrentStatus ? color : Colors.grey[300]!,
            width: 1,
          ),
        ),
        elevation: 0,
      ),
      child: Column(
        children: [
          Icon(
            getStatusIcon(status),
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            getStatusText(status),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
