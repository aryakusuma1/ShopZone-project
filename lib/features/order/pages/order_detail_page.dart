import 'package:flutter/material.dart';
import '../../../shared/models/order.dart';
import '../../../shared/models/cart_item.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';

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
      body: SingleChildScrollView(
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
                  ...order.items.map((item) => _buildOrderItem(item)),

                  const SizedBox(height: 24),

                  // Order Summary
                  _buildSummaryRow('Harga', order.formattedTotalPrice),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Status', order.statusText),
                ],
              ),
            ),

            const Divider(height: 1),

            // Komplain / Retur Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _showComplaintDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Komplain / Retur',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // Complaint / Return Process Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Complaint / Return Process',
                    style: AppTextStyles.heading2,
                  ),
                  const SizedBox(height: 16),

                  _buildProcessStep(
                    Icons.description_outlined,
                    'Ajukan',
                    'Kirimkan keluhan atau permintaan pengembalian Anda',
                  ),
                  const SizedBox(height: 16),

                  _buildProcessStep(
                    Icons.schedule,
                    'Diproses',
                    'Permintaan Anda sedang diproses oleh tim kami',
                  ),
                  const SizedBox(height: 16),

                  _buildProcessStep(
                    Icons.check_circle_outline,
                    'Selesai',
                    'Keluhan atau pengembalian Anda telah terselesaikan',
                  ),
                ],
              ),
            ),
          ],
        ),
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

  Widget _buildProcessStep(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showComplaintDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Komplain / Retur'),
          content: const Text(
            'Fitur komplain dan retur sedang dalam pengembangan. Untuk sementara, silakan hubungi customer service kami.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.secondary,
              ),
              child: const Text('Mengerti'),
            ),
          ],
        );
      },
    );
  }
}
