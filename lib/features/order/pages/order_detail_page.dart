import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:intl/intl.dart';
import '../../../shared/models/order.dart';
import '../../../shared/models/cart_item.dart';
import '../../../shared/models/complaint.dart';
import '../../../shared/models/refund.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/services/notification_service.dart';
import '../../../routes/app_routes.dart';

class OrderDetailPage extends StatelessWidget {
  final Order order;

  const OrderDetailPage({
    super.key,
    required this.order,
  });

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
        title: const Text('Detail Pesanan', style: AppTextStyles.heading2),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(order.id)
            .snapshots(),
        builder: (context, snapshot) {
          // Show loading if waiting
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show error if any
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Get updated order data
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Pesanan tidak ditemukan'));
          }

          final orderData = snapshot.data!.data() as Map<String, dynamic>;
          final currentOrder = Order.fromJson(orderData);

          return _buildOrderContent(context, currentOrder);
        },
      ),
    );
  }

  Widget _buildOrderContent(BuildContext context, Order currentOrder) {
    return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rincian Pembelian Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rincian Pembelian',
                    style: AppTextStyles.heading2,
                  ),
                  const SizedBox(height: 16),

                  // Order Items
                  ...currentOrder.items.map((item) => _buildOrderItem(item)),

                  const SizedBox(height: 24),

                  // Order Summary
                  _buildSummaryRow('Harga', currentOrder.formattedTotalPrice),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Status', currentOrder.statusText),
                ],
              ),
            ),

            const Divider(height: 1),

            // Komplain / Retur Button - Only show if no complaint exists
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('complaints')
                  .where('orderId', isEqualTo: currentOrder.id)
                  .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                // Check if complaint already exists
                final hasComplaint = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: hasComplaint ? null : () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.complaint,
                          arguments: currentOrder,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasComplaint ? Colors.grey : const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: Colors.grey[400],
                        disabledForegroundColor: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            hasComplaint ? Icons.check_circle : Icons.report_problem,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            hasComplaint ? 'Komplain Sudah Diajukan' : 'Komplain / Retur',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Pesanan Diterima Button - Only show if status is dikirim
            if (currentOrder.status == OrderStatus.dikirim)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showConfirmReceivedDialog(context, currentOrder),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.check_circle,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Pesanan Diterima',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (currentOrder.status == OrderStatus.dikirim)
              const SizedBox(height: 16),

            // Check if there's an active complaint/return request
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('complaints')
                  .where('orderId', isEqualTo: currentOrder.id)
                  .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
                  .limit(1)
                  .snapshots(),
              builder: (context, complaintSnapshot) {
                // If there's a complaint
                if (complaintSnapshot.hasData &&
                    complaintSnapshot.data!.docs.isNotEmpty) {

                  final complaintDoc = complaintSnapshot.data!.docs.first;
                  final complaint = Complaint.fromJson(
                    complaintDoc.data() as Map<String, dynamic>
                  );

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Retur Badge
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getComplaintStatusColor(complaint.status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getComplaintStatusColor(complaint.status),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getComplaintStatusIcon(complaint.status),
                                color: _getComplaintStatusColor(complaint.status),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Status Retur dari complaint
                                    Text(
                                      'Status Retur: ${_getReturStatusText(complaint.status)}',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: _getReturStatusColor(complaint.status),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Masalah: ${complaint.issueType}',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Tombol Ajukan Refund - Only show if no refund exists
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('refunds')
                              .where('orderId', isEqualTo: currentOrder.id)
                              .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
                              .limit(1)
                              .snapshots(),
                          builder: (context, refundSnapshot) {
                            // Check if refund already exists
                            final hasRefund = refundSnapshot.hasData &&
                                refundSnapshot.data!.docs.isNotEmpty;

                            if (hasRefund) {
                              // Show refund status instead of button
                              final refundDoc = refundSnapshot.data!.docs.first;
                              final refund = Refund.fromJson(
                                refundDoc.data() as Map<String, dynamic>
                              );

                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _getRefundStatusColor(refund.refundStatus).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _getRefundStatusColor(refund.refundStatus),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.payments,
                                      color: _getRefundStatusColor(refund.refundStatus),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Status Refund: ${_getRefundStatusText(refund.refundStatus)}',
                                            style: AppTextStyles.bodyMedium.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: _getRefundStatusColor(refund.refundStatus),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Jumlah: ${currentOrder.formattedFinalPrice}',
                                            style: AppTextStyles.bodySmall.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.arrow_forward_ios, size: 16),
                                      color: _getRefundStatusColor(refund.refundStatus),
                                      onPressed: () {
                                        Navigator.pushNamed(context, AppRoutes.refund);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }

                            // Show button only if no refund exists
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _showRefundConfirmation(context, currentOrder, complaint);
                                },
                                icon: const Icon(Icons.payments, size: 20),
                                label: const Text(
                                  'Ajukan Pengembalian Dana',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                }

                // Jika belum ada complaint, return empty
                return const SizedBox.shrink();
              },
            ),

            // Complaint / Return Process Section with Real-time Status
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('complaints')
                  .where('orderId', isEqualTo: currentOrder.id)
                  .limit(1)
                  .snapshots(),
              builder: (context, complaintSnapshot) {
                Complaint? complaintData;
                if (complaintSnapshot.hasData && complaintSnapshot.data!.docs.isNotEmpty) {
                  final data = complaintSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                  data['id'] = complaintSnapshot.data!.docs.first.id;
                  complaintData = Complaint.fromJson(data);
                }

                // Get status index for comparison (0=ajukan, 1=diproses, 2=selesai)
                int currentStatusIndex = _getReturStatusIndex(complaintData?.status ?? 'pending');

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Complaint / Return Process',
                        style: AppTextStyles.heading2,
                      ),
                      const SizedBox(height: 16),

                      _buildProcessStepWithStatus(
                        Icons.description_outlined,
                        'Ajukan',
                        'Kirimkan keluhan atau permintaan pengembalian Anda',
                        complaintData != null && currentStatusIndex >= 0,
                        complaintData?.createdAt,
                      ),
                      const SizedBox(height: 16),

                      _buildProcessStepWithStatus(
                        Icons.schedule,
                        'Diproses',
                        'Permintaan Anda sedang diproses oleh tim kami',
                        complaintData != null && currentStatusIndex >= 1,
                        currentStatusIndex >= 1 ? complaintData?.createdAt : null,
                      ),
                      const SizedBox(height: 16),

                      _buildProcessStepWithStatus(
                        Icons.check_circle_outline,
                        'Selesai',
                        'Keluhan atau pengembalian Anda telah terselesaikan',
                        complaintData != null && currentStatusIndex >= 2,
                        currentStatusIndex >= 2 ? complaintData?.createdAt : null,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
    );
  }

  Widget _buildOrderItem(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.product.imageUrl.startsWith('http')
                ? Image.network(
                    item.product.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, color: Colors.grey),
                      );
                    },
                  )
                : Image.asset(
                    item.product.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(width: 12),

          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (item.product.size != null)
                  Text(
                    'Ukuran ${item.product.size}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildProcessStepWithStatus(
    IconData icon,
    String title,
    String description,
    bool isActive,
    DateTime? timestamp,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary.withValues(alpha: 0.1) : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(8),
            border: isActive ? Border.all(color: AppColors.primary, width: 2) : null,
          ),
          child: Icon(
            icon,
            color: isActive ? AppColors.primary : Colors.grey,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
              if (timestamp != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Waktu: ${DateFormat('dd MMM yyyy, HH:mm').format(timestamp)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textHint,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Helper methods untuk complaint status
  Color _getComplaintStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.blue;
      case 'processing':
      case 'processed':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getComplaintStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.description;
      case 'processing':
      case 'processed':
        return Icons.access_time;
      case 'approved':
        return Icons.check_circle_outline;
      case 'resolved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  // Helper methods untuk refund status
  Color _getRefundStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'requested':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getRefundStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'requested':
        return 'Menunggu Proses';
      case 'processing':
        return 'Sedang Diproses';
      case 'completed':
        return 'Selesai';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Unknown';
    }
  }

  // Helper methods for Retur Status (from Complaint)
  String _getReturStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
      case 'processed':
        return 'Diproses';
      case 'resolved':
        return 'Selesai';
      case 'pending':
      default:
        return 'Ajukan';
    }
  }

  Color _getReturStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
      case 'processed':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'pending':
      default:
        return Colors.blue;
    }
  }

  // Get status index for timeline comparison
  int _getReturStatusIndex(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
      case 'processed':
        return 1; // Diproses
      case 'resolved':
        return 2; // Selesai
      case 'pending':
      default:
        return 0; // Ajukan
    }
  }

  // Dialog konfirmasi pesanan diterima
  void _showConfirmReceivedDialog(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            const SizedBox(width: 12),
            const Text('Konfirmasi Penerimaan'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda yakin telah menerima pesanan ini?',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            Text(
              'Setelah dikonfirmasi, status pesanan akan berubah menjadi "Diterima".',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateOrderStatus(context, order);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Ya, Sudah Diterima'),
          ),
        ],
      ),
    );
  }

  // Update status pesanan ke Firestore
  Future<void> _updateOrderStatus(BuildContext context, Order order) async {
    try {
      // Create updated statusTimestamps
      final updatedTimestamps = Map<OrderStatus, DateTime>.from(order.statusTimestamps);
      updatedTimestamps[OrderStatus.diterima] = DateTime.now();

      // Update order in Firestore
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(order.id)
          .update({
        'status': OrderStatus.diterima.index,
        'statusTimestamps': updatedTimestamps.map(
          (key, value) => MapEntry(key.index.toString(), value.toIso8601String()),
        ),
      });

      if (!context.mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Pesanan berhasil dikonfirmasi sebagai diterima'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Navigate back to refresh the list
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;

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
    }
  }

  // Dialog konfirmasi refund
  void _showRefundConfirmation(BuildContext context, Order order, Complaint complaint) {
    showDialog(
      context: context,
      builder: (context) => _RefundConfirmationDialog(
        order: order,
        complaint: complaint,
      ),
    );
  }
}

// Stateful dialog untuk handle refund request
class _RefundConfirmationDialog extends StatefulWidget {
  final Order order;
  final Complaint complaint;

  const _RefundConfirmationDialog({
    required this.order,
    required this.complaint,
  });

  @override
  State<_RefundConfirmationDialog> createState() => _RefundConfirmationDialogState();
}

class _RefundConfirmationDialogState extends State<_RefundConfirmationDialog> {
  bool _isSubmitting = false;

  Future<void> _submitRefundRequest() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Check if refund already exists for this order
      final existingRefund = await FirebaseFirestore.instance
          .collection('refunds')
          .where('orderId', isEqualTo: widget.order.id)
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (existingRefund.docs.isNotEmpty) {
        if (!mounted) return;

        // Close dialog
        Navigator.pop(context);

        // Show message that refund already exists
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Anda sudah pernah mengajukan refund untuk pesanan ini.'),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Generate refund ID
      final refundId = FirebaseFirestore.instance.collection('refunds').doc().id;

      // Create refund object
      final now = DateTime.now();
      final refund = Refund(
        id: refundId,
        complaintId: widget.complaint.id,
        orderId: widget.order.id,
        userId: user.uid,
        refundAmount: widget.order.finalPrice,
        status: RefundStatus.ajukan,
        createdAt: now,
        statusTimestamps: {RefundStatus.ajukan: now},
      );

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('refunds')
          .doc(refundId)
          .set(refund.toJson());

      // Tampilkan notifikasi refund diajukan
      await NotificationService().showRefundRequestedNotification(
        orderId: widget.order.id,
        amount: widget.order.finalPrice,
      );

      if (!mounted) return;

      // Close dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Permintaan refund berhasil diajukan'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Navigate to refund page
      Navigator.pushNamed(context, AppRoutes.refund);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Gagal mengajukan refund: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(Icons.payments, color: Colors.green.shade600),
          const SizedBox(width: 12),
          const Text('Ajukan Refund'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Anda akan mengajukan pengembalian dana untuk pesanan ini.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          const Text(
            'Jumlah yang akan dikembalikan:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.order.formattedFinalPrice,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                  color: Colors.blue.shade700,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dana akan dikembalikan dalam 3-7 hari kerja',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitRefundRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            disabledBackgroundColor: Colors.grey,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Ajukan Refund'),
        ),
      ],
    );
  }
}
