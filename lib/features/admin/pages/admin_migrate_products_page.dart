import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/colors.dart';
import '../../../features/home/data/dummy_products.dart';

class AdminMigrateProductsPage extends StatefulWidget {
  const AdminMigrateProductsPage({super.key});

  @override
  State<AdminMigrateProductsPage> createState() =>
      _AdminMigrateProductsPageState();
}

class _AdminMigrateProductsPageState extends State<AdminMigrateProductsPage> {
  bool _isMigrating = false;
  String _status = '';
  int _migrated = 0;
  int _total = 0;

  Future<void> _migrateProducts() async {
    setState(() {
      _isMigrating = true;
      _status = 'Memulai migrasi...';
      _migrated = 0;
    });

    try {
      // Get all dummy products
      final products = DummyProducts.getAllProductsWithExtra();
      _total = products.length;

      setState(() {
        _status = 'Mengambil $_total produk...';
      });

      await Future.delayed(const Duration(seconds: 1));

      // Migrate each product to Firestore
      for (var i = 0; i < products.length; i++) {
        final product = products[i];

        setState(() {
          _status = 'Migrasi produk ${i + 1}/$_total: ${product.name}';
        });

        // Create document with custom ID
        await FirebaseFirestore.instance
            .collection('products')
            .doc(product.id)
            .set({
          'id': product.id,
          'name': product.name,
          'price': product.price,
          'imageUrl': product.imageUrl,
          'category': product.category,
          'condition': product.condition,
          'size': product.size,
          'color': product.color,
          'material': product.material,
          'description': product.description,
          'rating': product.rating,
          'verified': product.verified,
          'stock': 100, // Default stock
          'createdAt': DateTime.now().toIso8601String(),
        });

        setState(() {
          _migrated = i + 1;
        });

        await Future.delayed(const Duration(milliseconds: 300));
      }

      setState(() {
        _isMigrating = false;
        _status = 'Selesai! $_migrated produk berhasil dimigrasi ke Firestore.';
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 28),
                const SizedBox(width: 12),
                const Text('Berhasil!'),
              ],
            ),
            content: Text(
              '$_migrated produk berhasil dimigrasi ke Firestore.\n\nSekarang Anda bisa mengelola produk dari Admin Dashboard.',
              style: const TextStyle(height: 1.5),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isMigrating = false;
        _status = 'Error: $e';
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.error, size: 28),
                const SizedBox(width: 12),
                const Text('Gagal'),
              ],
            ),
            content: Text(
              'Terjadi kesalahan saat migrasi:\n\n$e',
              style: const TextStyle(height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

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
          'Migrasi Produk Dummy',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.cloud_upload,
              size: 80,
              color: AppColors.primary,
            ),
            const SizedBox(height: 24),
            const Text(
              'Migrasi Produk ke Firestore',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Ini akan memindahkan semua produk dummy ke Firestore agar bisa dikelola oleh admin.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Catatan Penting:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Proses ini hanya dilakukan SEKALI saja\n'
                    '• Total 9 produk akan dimigrasi\n'
                    '• Setelah migrasi, produk bisa diedit/hapus dari Admin Dashboard',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[900],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (_isMigrating) ...[
              Column(
                children: [
                  const CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _status,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_total > 0) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _migrated / _total,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_migrated / $_total produk',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ] else if (_status.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _status.contains('Selesai')
                      ? Colors.green[50]
                      : Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _status.contains('Selesai')
                        ? Colors.green[200]!
                        : Colors.red[200]!,
                  ),
                ),
                child: Text(
                  _status,
                  style: TextStyle(
                    fontSize: 14,
                    color: _status.contains('Selesai')
                        ? Colors.green[900]
                        : Colors.red[900],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: _migrateProducts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Mulai Migrasi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
