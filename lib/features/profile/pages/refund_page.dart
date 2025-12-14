import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../shared/models/refund.dart';
import '../../../shared/models/order.dart' as order_model;
import '../../../routes/app_routes.dart';

class RefundPage extends StatelessWidget {
  const RefundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Refund Saya',
            style: AppTextStyles.heading2,
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: Text('Silakan login terlebih dahulu'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Refund Saya',
          style: AppTextStyles.heading2,
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('refunds')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 60,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Terjadi kesalahan',
                      style: AppTextStyles.heading3,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            );
          }

          final refundDocs = snapshot.data?.docs ?? [];

          if (refundDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada refund',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          // Convert to Refund objects and sort by date (newest first)
          final refunds = refundDocs.map((doc) {
            return Refund.fromJson(doc.data() as Map<String, dynamic>);
          }).toList();

          // Sort in client side to avoid needing Firestore index
          refunds.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: refunds.length,
            itemBuilder: (context, index) {
              return _RefundCard(
                refund: refunds[index],
                userId: user.uid,
              );
            },
          );
        },
      ),
    );
  }
}

class _RefundCard extends StatelessWidget {
  final Refund refund;
  final String userId;

  const _RefundCard({
    required this.refund,
    required this.userId,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'requested':
        return AppColors.warning;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('orders')
          .doc(refund.orderId)
          .get(),
      builder: (context, snapshot) {
        // Show loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            ),
          );
        }

        // Default values if order not found
        String productName = 'Order ${refund.orderId}';
        String productImage = '';

        // Get order data if available
        if (snapshot.hasData && snapshot.data!.exists) {
          final orderData = snapshot.data!.data() as Map<String, dynamic>;
          final order = order_model.Order.fromJson(orderData);

          // Get first product from order
          if (order.items.isNotEmpty) {
            final firstItem = order.items.first;
            productName = firstItem.product.name;
            productImage = firstItem.product.imageUrl;
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header dengan gambar dan info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gambar produk
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[100],
                        image: productImage.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(productImage),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: productImage.isEmpty
                          ? Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.grey[400],
                              size: 30,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    // Info produk
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productName,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            refund.formattedRefundAmount,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(refund.refundStatus).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        refund.statusText,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: _getStatusColor(refund.refundStatus),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Deskripsi Refund
                Text(
                  'Detail Refund',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Refund Anda telah diajukan. Klik lihat untuk detail Refund.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // Button Lihat Detail
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.refundDetail,
                        arguments: refund,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Lihat Detail',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
