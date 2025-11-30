import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/providers/cart_provider.dart';
import '../../../shared/providers/order_provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../routes/app_routes.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Reload user address and set initial address value
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cart = Provider.of<CartProvider>(context, listen: false);
      // Reload address from user profile to get latest data
      await cart.reloadUserAddress();
      _addressController.text = cart.shippingAddress;
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _navigateToSelectAddress(BuildContext context) async {
    final result = await Navigator.pushNamed(context, AppRoutes.selectAddress);
    if (result != null && result is String) {
      final cart = Provider.of<CartProvider>(context, listen: false);
      cart.updateAddress(result);
      setState(() {
        _addressController.text = result;
      });
    }
  }

  void _showDiscountDialog(BuildContext context, CartProvider cart) {
    final availableDiscounts = cart.availableDiscounts;

    if (availableDiscounts.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 350),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.grey[700],
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                const Text(
                  'Diskon Tidak Tersedia',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Message
                Text(
                  'Belanja lebih banyak untuk mendapatkan diskon menarik!',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Mengerti',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pilih Diskon',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Discount options
              ...availableDiscounts.map((discount) {
                final isSelected = cart.selectedDiscount == discount['id'];
                return GestureDetector(
                  onTap: () {
                    cart.applyDiscount(discount['id'], discount['amount']);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${discount['name']} diterapkan!',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.green[600],
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(milliseconds: 2000),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.grey[100] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.grey[200]!,
                        width: isSelected ? 2 : 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Checkmark circle
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.grey[400]!,
                              width: 2,
                            ),
                            color: isSelected ? AppColors.primary : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),

                        // Discount info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${discount['percentage']}% OFF',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? AppColors.primary : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                discount['description'],
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Savings amount
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '-${_formatPrice(discount['amount'])}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // Remove discount button
              if (cart.selectedDiscount.isNotEmpty) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      cart.removeDiscount();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.info_outline,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Diskon dihapus',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.grey[700],
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: const EdgeInsets.all(16),
                          duration: const Duration(milliseconds: 2000),
                        ),
                      );
                    },
                    icon: const Icon(Icons.remove_circle_outline, size: 18),
                    label: const Text('Hapus Diskon'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red[700],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrice(int price) {
    return 'Rp${price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
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
        title: const Text(
          'Keranjang',
          style: AppTextStyles.heading2,
        ),
        centerTitle: true,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 100,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Keranjang Anda kosong',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Yuk mulai belanja!',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // List produk di keranjang
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cart.items.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          return _buildCartItem(context, item, cart);
                        },
                      ),

                      const SizedBox(height: 24),

                      // Diskon section
                      InkWell(
                        onTap: () => _showDiscountDialog(context, cart),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: cart.selectedDiscount.isNotEmpty
                                      ? Colors.green[50]
                                      : cart.availableDiscounts.isNotEmpty
                                          ? AppColors.primary.withValues(alpha: 0.1)
                                          : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  cart.selectedDiscount.isNotEmpty
                                      ? Icons.discount
                                      : Icons.local_offer,
                                  color: cart.selectedDiscount.isNotEmpty
                                      ? Colors.green[700]
                                      : cart.availableDiscounts.isNotEmpty
                                          ? AppColors.primary
                                          : Colors.grey[400],
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Diskon',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    if (cart.selectedDiscount.isNotEmpty)
                                      Text(
                                        'Diskon aktif',
                                        style: TextStyle(
                                          color: Colors.green[700],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    else if (cart.availableDiscounts.isNotEmpty)
                                      Text(
                                        '${cart.availableDiscounts.length} diskon tersedia',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 12,
                                        ),
                                      )
                                    else
                                      Text(
                                        'Tidak ada diskon tersedia',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Ringkasan Pembelian
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ringkasan Pembelian',
                              style: AppTextStyles.heading3,
                            ),
                            const SizedBox(height: 16),

                            // Detail setiap item
                            ...cart.items.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.product.name,
                                            style: AppTextStyles.bodyMedium,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '${item.quantity}x ${item.product.formattedPrice}',
                                            style: AppTextStyles.bodySmall.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      item.formattedTotalPrice,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),

                            const Divider(height: 24),

                            // Subtotal
                            _buildSummaryRow('Subtotal', cart.formattedTotalPrice),
                            const SizedBox(height: 8),

                            // Diskon
                            _buildSummaryRow(
                              'Diskon',
                              cart.discountAmount > 0
                                  ? '-${cart.formattedDiscountAmount}'
                                  : cart.formattedDiscountAmount,
                              color: cart.discountAmount > 0 ? Colors.green : null,
                            ),

                            const Divider(height: 24),

                            // Total
                            _buildSummaryRow(
                              'Total',
                              cart.formattedFinalPrice,
                              isBold: true,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Alamat
                      InkWell(
                        onTap: () => _navigateToSelectAddress(context),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: AppColors.secondary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Alamat Pengiriman',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      cart.shippingAddress.isEmpty
                                          ? 'Pilih alamat pengiriman'
                                          : cart.shippingAddress,
                                      style: TextStyle(
                                        color: cart.shippingAddress.isEmpty
                                            ? AppColors.error
                                            : Colors.grey[600],
                                        fontSize: 12,
                                        fontStyle: cart.shippingAddress.isEmpty
                                            ? FontStyle.italic
                                            : FontStyle.normal,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),

              // Bottom button
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Validate if address is selected
                      if (cart.shippingAddress.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.white, size: 20),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Pilih alamat pengiriman terlebih dahulu',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.all(16),
                            duration: const Duration(milliseconds: 2000),
                          ),
                        );
                        return;
                      }

                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 400),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Icon
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.shopping_bag_outlined,
                                    color: AppColors.secondary,
                                    size: 40,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Title
                                const Text(
                                  'Konfirmasi Pesanan',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),

                                // Order details
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      // Total payment
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Total Pembayaran',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            cart.formattedFinalPrice,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: AppColors.secondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      // Address
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: 18,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Alamat Pengiriman',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  cart.shippingAddress,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: Colors.grey[100],
                                          foregroundColor: Colors.grey[700],
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          side: BorderSide(color: Colors.grey[300]!),
                                        ),
                                        child: const Text(
                                          'Batal',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          // Get providers
                                          final cart = Provider.of<CartProvider>(context, listen: false);
                                          final orderProvider = Provider.of<OrderProvider>(context, listen: false);

                                          // Create order
                                          final orderId = orderProvider.createOrder(
                                            items: cart.items,
                                            totalPrice: cart.totalPrice,
                                            discountAmount: cart.discountAmount,
                                            finalPrice: cart.finalPrice,
                                            shippingAddress: cart.shippingAddress,
                                          );

                                          // Get the created order
                                          final order = orderProvider.getOrderById(orderId);

                                          // Clear cart
                                          cart.clearCart();

                                          // Close dialog
                                          Navigator.pop(context);

                                          // Navigate to order detail
                                          if (order != null) {
                                            Navigator.pushReplacementNamed(
                                              context,
                                              AppRoutes.orderDetail,
                                              arguments: order,
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.secondary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: const Text(
                                          'Lanjutkan',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Beli',
                      style: AppTextStyles.button,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // Keranjang index
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: Colors.white,
        elevation: 8,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Pesanan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Keranjang',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, AppRoutes.orders);
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, AppRoutes.account);
          }
        },
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, item, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.product.imageUrl.startsWith('http')
                ? Image.network(
                    item.product.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    item.product.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
          ),

          const SizedBox(width: 12),

          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: AppTextStyles.bodyLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Size ${item.product.size ?? '-'} - ${item.product.color ?? '-'}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.product.formattedPrice,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Quantity controls
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => cart.decreaseQuantity(item.product.id),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.remove,
                      size: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '${item.quantity}',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
                InkWell(
                  onTap: () => cart.increaseQuantity(item.product.id),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.add,
                      size: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold
              ? AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)
              : AppTextStyles.bodyMedium,
        ),
        Text(
          value,
          style: isBold
              ? AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)
              : AppTextStyles.bodyMedium.copyWith(color: color),
        ),
      ],
    );
  }
}
