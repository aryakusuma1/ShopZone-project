import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../shared/models/address.dart';

class AddEditAddressPage extends StatefulWidget {
  final bool isMainAddress; // true = edit alamat utama (profil), false = tambah/edit alamat tambahan
  final Address? existingAddress; // untuk edit alamat tambahan

  const AddEditAddressPage({
    super.key,
    this.isMainAddress = false,
    this.existingAddress,
  });

  @override
  State<AddEditAddressPage> createState() => _AddEditAddressPageState();
}

class _AddEditAddressPageState extends State<AddEditAddressPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;
  bool get isEditMode => widget.existingAddress != null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      if (widget.isMainAddress) {
        // Load dari profil user
        final docSnapshot = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data()!;
          setState(() {
            _nameController.text = data['name'] ?? currentUser.displayName ?? '';
            _phoneController.text = data['phone'] ?? '';
            _addressController.text = data['address'] ?? '';
            isLoading = false;
          });
        } else {
          setState(() {
            _nameController.text = currentUser.displayName ?? '';
            isLoading = false;
          });
        }
      } else if (widget.existingAddress != null) {
        // Load dari existing address (edit mode)
        setState(() {
          _nameController.text = widget.existingAddress!.name;
          _phoneController.text = widget.existingAddress!.phone;
          _addressController.text = widget.existingAddress!.fullAddress;
          isLoading = false;
        });
      } else {
        // Mode tambah alamat baru
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    setState(() {
      isSaving = true;
    });

    try {
      if (widget.isMainAddress) {
        // Update alamat utama di profil
        await _firestore.collection('users').doc(currentUser.uid).set({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'email': currentUser.email,
        }, SetOptions(merge: true));

        // Update Firebase Auth displayName
        await currentUser.updateDisplayName(_nameController.text.trim());
      } else {
        // Simpan ke collection addresses
        if (isEditMode) {
          // Update existing address
          await _firestore
              .collection('addresses')
              .doc(widget.existingAddress!.id)
              .update({
            'name': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'fullAddress': _addressController.text.trim(),
          });
        } else {
          // Create new address
          final docRef = _firestore.collection('addresses').doc();
          await docRef.set({
            'id': docRef.id,
            'userId': currentUser.uid,
            'name': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'fullAddress': _addressController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      setState(() {
        isSaving = false;
      });

      if (mounted) {
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
                const Expanded(
                  child: Text(
                    'Alamat berhasil disimpan',
                    style: TextStyle(fontSize: 14),
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

        // Return true to indicate success
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Gagal menyimpan alamat: $e',
                    style: const TextStyle(fontSize: 14),
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
      }
    }
  }

  Future<void> _deleteAddress() async {
    // Tidak bisa hapus alamat utama
    if (widget.isMainAddress || widget.existingAddress == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Hapus Alamat'),
        content: const Text('Apakah Anda yakin ingin menghapus alamat ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      isSaving = true;
    });

    try {
      await _firestore
          .collection('addresses')
          .doc(widget.existingAddress!.id)
          .delete();

      setState(() {
        isSaving = false;
      });

      if (mounted) {
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
                const Expanded(
                  child: Text(
                    'Alamat berhasil dihapus',
                    style: TextStyle(fontSize: 14),
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

        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Gagal menghapus alamat: $e',
                    style: const TextStyle(fontSize: 14),
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.isMainAddress
        ? 'Edit Alamat Utama'
        : (isEditMode ? 'Edit Alamat' : 'Tambah Alamat Baru');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: AppTextStyles.heading2,
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // Name field
                      const Text(
                        'Nama Lengkap',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Masukkan nama lengkap',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.all(16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.error,
                              width: 1,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.error,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Phone field
                      const Text(
                        'Nomor Telepon',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: 'Contoh: +6281234567890',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.all(16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.error,
                              width: 1,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.error,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nomor telepon tidak boleh kosong';
                          }
                          if (!RegExp(r'^[0-9+]+$').hasMatch(value)) {
                            return 'Nomor telepon tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Address field
                      const Text(
                        'Alamat Lengkap',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _addressController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Masukkan alamat lengkap (Jalan, RT/RW, Kelurahan, Kecamatan, Kota, Provinsi, Kode Pos)',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.all(16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.error,
                              width: 1,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.error,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Alamat tidak boleh kosong';
                          }
                          if (value.trim().length < 10) {
                            return 'Alamat terlalu pendek';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : _saveAddress,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            disabledBackgroundColor: Colors.grey[300],
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Simpan Alamat',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      // Delete button (hanya untuk alamat tambahan yang sudah ada)
                      if (!widget.isMainAddress && isEditMode) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: isSaving ? null : _deleteAddress,
                            icon: const Icon(Icons.delete_outline, size: 20),
                            label: const Text(
                              'Hapus Alamat',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(
                                color: AppColors.error,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
