import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  // Controllers untuk TextField
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  User? get currentUser => _auth.currentUser;
  String userName = '';
  String userEmail = '';
  String userPhone = '';
  String userAddress = '';
  bool isLoading = true;
  bool isEditMode = false; // Mode Edit atau View
  bool isSaving = false; // Loading saat save

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (currentUser == null) return;

    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        setState(() {
          userName = data['name'] ?? currentUser!.displayName ?? 'User';
          userEmail = data['email'] ?? currentUser!.email ?? '';
          userPhone = data['phone'] ?? '';
          userAddress = data['address'] ?? '';

          // Set controllers
          _nameController.text = userName;
          _phoneController.text = userPhone;
          _addressController.text = userAddress;

          isLoading = false;
        });
      } else {
        setState(() {
          userName = currentUser!.displayName ?? 'User';
          userEmail = currentUser!.email ?? '';

          _nameController.text = userName;

          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        userName = currentUser!.displayName ?? 'User';
        userEmail = currentUser!.email ?? '';

        _nameController.text = userName;

        isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async{
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isSaving = true;
    });

    try {
      // Update Firestore
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
      });

      // Update Firebase Auth displayName
      await currentUser!.updateDisplayName(_nameController.text.trim());

      // Update local state
      setState(() {
        userName = _nameController.text.trim();
        userPhone = _phoneController.text.trim();
        userAddress = _addressController.text.trim();
        isEditMode = false;
        isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui profil: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      // Reset controllers ke nilai asli
      _nameController.text = userName;
      _phoneController.text = userPhone;
      _addressController.text = userAddress;
      isEditMode = false;
    });
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'Akun',
          style: AppTextStyles.heading2,
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Profile Photo
                      Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _getInitials(userName),
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // User Name (centered) - hanya tampil di view mode
                      if (!isEditMode)
                        Text(
                          userName,
                          style: AppTextStyles.heading2,
                          textAlign: TextAlign.center,
                        ),
                      if (!isEditMode) const SizedBox(height: 32),

                      // Nama Field (editable di edit mode)
                      if (isEditMode) ...[
                        const SizedBox(height: 16),
                        _buildEditableField(
                          icon: Icons.person_outline,
                          label: 'Nama',
                          controller: _nameController,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nama tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Email (Read-only)
                      _buildReadOnlyField(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: userEmail,
                        onTap: isEditMode
                            ? null
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Email tidak dapat diubah'),
                                    backgroundColor: AppColors.textSecondary,
                                  ),
                                );
                              },
                      ),
                      const SizedBox(height: 16),

                      // Phone Number
                      if (isEditMode)
                        _buildEditableField(
                          icon: Icons.phone_outlined,
                          label: 'No HP',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (!RegExp(r'^[0-9+]+$').hasMatch(value)) {
                                return 'Nomor HP tidak valid';
                              }
                            }
                            return null;
                          },
                        )
                      else
                        _buildReadOnlyField(
                          icon: Icons.phone_outlined,
                          label: 'No HP',
                          value: userPhone.isEmpty
                              ? 'Tambahkan nomor HP'
                              : userPhone,
                          isEmpty: userPhone.isEmpty,
                        ),
                      const SizedBox(height: 16),

                      // Address
                      if (isEditMode)
                        _buildEditableField(
                          icon: Icons.location_on_outlined,
                          label: 'Alamat',
                          controller: _addressController,
                          maxLines: 3,
                        )
                      else
                        _buildReadOnlyField(
                          icon: Icons.location_on_outlined,
                          label: 'Alamat',
                          value: userAddress.isEmpty
                              ? 'Tambahkan alamat'
                              : userAddress,
                          isEmpty: userAddress.isEmpty,
                        ),
                      const SizedBox(height: 32),

                      // Buttons
                      if (!isEditMode)
                        // Edit Profile Button (View Mode)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                isEditMode = true;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Edit Profil',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      else
                        // Batal & Simpan Buttons (Edit Mode)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isSaving ? null : _cancelEdit,
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  side: const BorderSide(
                                      color: AppColors.textSecondary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Batal',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isSaving ? null : _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Simpan',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
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
            ),
    );
  }

  Widget _buildReadOnlyField({
    required IconData icon,
    required String label,
    required String value,
    bool isEmpty = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isEmpty
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: controller,
                  validator: validator,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  style: AppTextStyles.bodyMedium,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: 'Masukkan data',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
