import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/models/product.dart';

class AdminAddEditProductPage extends StatefulWidget {
  const AdminAddEditProductPage({super.key});

  @override
  State<AdminAddEditProductPage> createState() =>
      _AdminAddEditProductPageState();
}

class _AdminAddEditProductPageState extends State<AdminAddEditProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stockController = TextEditingController();
  final _sizeController = TextEditingController();
  final _colorController = TextEditingController();
  final _materialController = TextEditingController();
  final _userPhoto1Controller = TextEditingController();
  final _userPhoto2Controller = TextEditingController();
  final _userPhoto3Controller = TextEditingController();
  final _ratingController = TextEditingController();

  String? _selectedCategory;
  String? _selectedCondition = 'baru';
  bool _selectedVerified = true;
  bool _isLoading = false;
  bool _isEditMode = false;
  String? _productId;
  bool _hasInitialized = false;

  final List<String> _categories = [
    'Sepatu',
    'Pakaian',
    'Aksesoris',
    'Elektronik',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    // Reset initialization flag when widget is created
    _hasInitialized = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only initialize once
    if (_hasInitialized) return;

    // Check if we're in edit mode
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null && args.containsKey('product')) {
      _isEditMode = true;
      _productId = args['productId'] as String?;
      final product = args['product'] as Product;

      _nameController.text = product.name;
      _priceController.text = product.price.toString();
      _imageUrlController.text = product.imageUrl;
      _descriptionController.text = product.description;
      _stockController.text = product.stock.toString();
      _sizeController.text = product.size ?? '';
      _colorController.text = product.color ?? '';
      _materialController.text = product.material ?? '';
      _ratingController.text = product.rating.toString();
      _selectedCategory = product.category;
      _selectedCondition = product.condition;
      _selectedVerified = product.verified;

      // Load user photos
      if (product.userPhotos != null && product.userPhotos!.isNotEmpty) {
        if (product.userPhotos!.isNotEmpty) {
          _userPhoto1Controller.text = product.userPhotos![0];
        }
        if (product.userPhotos!.length > 1) {
          _userPhoto2Controller.text = product.userPhotos![1];
        }
        if (product.userPhotos!.length > 2) {
          _userPhoto3Controller.text = product.userPhotos![2];
        }
      }

      _hasInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    _sizeController.dispose();
    _colorController.dispose();
    _materialController.dispose();
    _userPhoto1Controller.dispose();
    _userPhoto2Controller.dispose();
    _userPhoto3Controller.dispose();
    _ratingController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pilih kategori produk'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final imageUrl = _imageUrlController.text.trim();

        // Build user photos array from controllers
        List<String> userPhotos = [];
        if (_userPhoto1Controller.text.trim().isNotEmpty) {
          userPhotos.add(_userPhoto1Controller.text.trim());
        }
        if (_userPhoto2Controller.text.trim().isNotEmpty) {
          userPhotos.add(_userPhoto2Controller.text.trim());
        }
        if (_userPhoto3Controller.text.trim().isNotEmpty) {
          userPhotos.add(_userPhoto3Controller.text.trim());
        }

        final productData = {
          'name': _nameController.text.trim(),
          'price': int.parse(_priceController.text),
          'imageUrl': imageUrl,
          'category': _selectedCategory,
          'condition': _selectedCondition ?? 'baru',
          'description': _descriptionController.text.trim(),
          'stock': int.parse(_stockController.text),
          'size': _sizeController.text.trim().isNotEmpty ? _sizeController.text.trim() : null,
          'color': _colorController.text.trim().isNotEmpty ? _colorController.text.trim() : null,
          'material': _materialController.text.trim().isNotEmpty ? _materialController.text.trim() : null,
          'rating': _ratingController.text.trim().isNotEmpty
              ? double.parse(_ratingController.text.trim())
              : 4.5,
          'verified': _selectedVerified,
          'userPhotos': userPhotos,
        };

        if (_isEditMode && _productId != null) {
          // Update existing product
          await FirebaseFirestore.instance
              .collection('products')
              .doc(_productId)
              .update(productData);

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Produk berhasil diupdate'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          // Create new product
          final docRef = FirebaseFirestore.instance.collection('products').doc();

          productData['id'] = docRef.id;
          productData['createdAt'] = DateTime.now().toIso8601String();

          await docRef.set(productData);

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Produk berhasil ditambahkan'),
              backgroundColor: AppColors.success,
            ),
          );
        }

        if (!mounted) return;
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan produk: $e'),
            backgroundColor: AppColors.error,
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
        title: Text(
          _isEditMode ? 'Edit Produk' : 'Tambah Produk',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Produk *',
                  hintText: 'Masukkan nama produk',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama produk harus diisi';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Price Field
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Harga *',
                  hintText: 'Masukkan harga',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Harga harus diisi';
                  }
                  final price = int.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Harga harus lebih dari 0';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Stock Field
              TextFormField(
                controller: _stockController,
                decoration: InputDecoration(
                  labelText: 'Stok *',
                  hintText: 'Masukkan jumlah stok',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Stok harus diisi';
                  }
                  final stock = int.tryParse(value);
                  if (stock == null || stock < 0) {
                    return 'Stok tidak valid';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Kategori *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Kategori harus dipilih';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Condition Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCondition,
                decoration: InputDecoration(
                  labelText: 'Kondisi *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'baru', child: Text('Baru')),
                  DropdownMenuItem(value: 'bekas', child: Text('Bekas')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCondition = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Size Field
              TextFormField(
                controller: _sizeController,
                decoration: InputDecoration(
                  labelText: 'Ukuran (Size)',
                  hintText: 'Contoh: 41, M, L, XL',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Color Field
              TextFormField(
                controller: _colorController,
                decoration: InputDecoration(
                  labelText: 'Warna (Color)',
                  hintText: 'Contoh: Hitam, Putih, Biru',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Material Field
              TextFormField(
                controller: _materialController,
                decoration: InputDecoration(
                  labelText: 'Material/Bahan',
                  hintText: 'Contoh: Leather, Suede, Denim',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Image URL Field
              TextFormField(
                controller: _imageUrlController,
                decoration: InputDecoration(
                  labelText: 'URL Gambar *',
                  hintText: 'https://example.com/image.jpg',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'URL gambar harus diisi';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Rating Field
              TextFormField(
                controller: _ratingController,
                decoration: InputDecoration(
                  labelText: 'Rating',
                  hintText: 'Contoh: 4.5 (0.0 - 5.0)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Verified Dropdown
              DropdownButtonFormField<bool>(
                initialValue: _selectedVerified,
                decoration: InputDecoration(
                  labelText: 'Terverifikasi *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: true, child: Text('Ya')),
                  DropdownMenuItem(value: false, child: Text('Tidak')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedVerified = value ?? true;
                  });
                },
              ),
              const SizedBox(height: 16),

              // User Photo 1
              TextFormField(
                controller: _userPhoto1Controller,
                decoration: InputDecoration(
                  labelText: 'Foto Pengguna 1 (Opsional)',
                  hintText: 'https://example.com/user-photo-1.jpg',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // User Photo 2
              TextFormField(
                controller: _userPhoto2Controller,
                decoration: InputDecoration(
                  labelText: 'Foto Pengguna 2 (Opsional)',
                  hintText: 'https://example.com/user-photo-2.jpg',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // User Photo 3
              TextFormField(
                controller: _userPhoto3Controller,
                decoration: InputDecoration(
                  labelText: 'Foto Pengguna 3 (Opsional)',
                  hintText: 'https://example.com/user-photo-3.jpg',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Deskripsi',
                  hintText: 'Masukkan deskripsi produk',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 4,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _isEditMode ? 'Update Produk' : 'Tambah Produk',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
