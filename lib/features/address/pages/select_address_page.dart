import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../shared/providers/cart_provider.dart';
import '../../../shared/models/address.dart';

class SelectAddressPage extends StatefulWidget {
  const SelectAddressPage({super.key});

  @override
  State<SelectAddressPage> createState() => _SelectAddressPageState();
}

class _SelectAddressPageState extends State<SelectAddressPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = true;
  String userName = '';
  String userPhone = '';
  String userAddress = '';
  List<Address> additionalAddresses = [];
  String currentSelectedAddress = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });

    final cart = Provider.of<CartProvider>(context, listen: false);
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    // Load alamat utama dari profil
    final name = await cart.getUserProfileName();
    final phone = await cart.getUserProfilePhone();
    final address = await cart.getUserProfileAddress();
    final currentAddress = cart.shippingAddress;

    // Load alamat tambahan dari collection addresses
    List<Address> addresses = [];
    try {
      final snapshot = await _firestore
          .collection('addresses')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      addresses = snapshot.docs.map((doc) {
        return Address.fromJson(doc.data());
      }).toList();

      // Sort by createdAt in client
      addresses.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } catch (e) {
      debugPrint('Error loading addresses: $e');
    }

    setState(() {
      userName = name;
      userPhone = phone;
      userAddress = address;
      additionalAddresses = addresses;
      currentSelectedAddress = currentAddress;
      isLoading = false;
    });
  }

  void _selectAddress(String address) {
    setState(() {
      currentSelectedAddress = address;
    });
  }

  void _saveAndReturn() {
    final cart = Provider.of<CartProvider>(context, listen: false);
    cart.updateAddress(currentSelectedAddress);
    Navigator.pop(context, currentSelectedAddress);
  }

  @override
  Widget build(BuildContext context) {
    final hasAnyAddress = userAddress.isNotEmpty || additionalAddresses.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pilih Alamat',
          style: AppTextStyles.heading2,
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header label
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.grey[100],
                  child: const Text(
                    'Alamat',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // Address list
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Primary address from profile
                        if (userAddress.isNotEmpty)
                          _buildAddressItem(
                            name: userName,
                            phone: userPhone,
                            address: userAddress,
                            isMain: true,
                            isSelected: currentSelectedAddress == userAddress,
                            onTap: () => _selectAddress(userAddress),
                            onEdit: () {
                              // Navigate to edit main address
                              Navigator.pushNamed(
                                context,
                                '/addEditAddress',
                                arguments: {
                                  'isMainAddress': true,
                                  'existingAddress': null,
                                },
                              ).then((result) {
                                if (result == true) {
                                  _loadUserData();
                                }
                              });
                            },
                          ),

                        // Additional addresses
                        ...additionalAddresses.map((addr) {
                          return _buildAddressItem(
                            name: addr.name,
                            phone: addr.phone,
                            address: addr.fullAddress,
                            isMain: false,
                            isSelected: currentSelectedAddress == addr.fullAddress,
                            onTap: () => _selectAddress(addr.fullAddress),
                            onEdit: () {
                              // Navigate to edit additional address
                              Navigator.pushNamed(
                                context,
                                '/addEditAddress',
                                arguments: {
                                  'isMainAddress': false,
                                  'existingAddress': addr,
                                },
                              ).then((result) {
                                if (result == true) {
                                  _loadUserData();
                                }
                              });
                            },
                          );
                        }),

                        // Empty state if no address
                        if (!hasAnyAddress)
                          Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.location_off_outlined,
                                  size: 80,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Belum ada alamat',
                                  style: AppTextStyles.heading3.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tambahkan alamat terlebih dahulu',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textHint,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/addEditAddress',
                                      arguments: {
                                        'isMainAddress': true,
                                        'existingAddress': null,
                                      },
                                    ).then((result) {
                                      if (result == true) {
                                        _loadUserData();
                                      }
                                    });
                                  },
                                  icon: const Icon(Icons.add, size: 20),
                                  label: const Text('Tambah Alamat'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.secondary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Add new address button
                        if (hasAnyAddress)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/addEditAddress',
                                  arguments: {
                                    'isMainAddress': false,
                                    'existingAddress': null,
                                  },
                                ).then((result) {
                                  if (result == true) {
                                    _loadUserData();
                                  }
                                });
                              },
                              icon: const Icon(Icons.add_circle_outline, size: 20),
                              label: const Text('Tambah Alamat Baru'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.secondary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: AppColors.secondary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                minimumSize: const Size(double.infinity, 0),
                              ),
                            ),
                          ),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),

                // Bottom save button
                if (hasAnyAddress)
                  Container(
                    padding: const EdgeInsets.all(16),
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
                        onPressed: currentSelectedAddress.isNotEmpty
                            ? _saveAndReturn
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                        child: const Text(
                          'Gunakan Alamat Ini',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildAddressItem({
    required String name,
    required String phone,
    required String address,
    required bool isMain,
    required bool isSelected,
    required VoidCallback onTap,
    required VoidCallback onEdit,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Radio button
              Container(
                margin: const EdgeInsets.only(top: 2),
                child: Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isSelected ? AppColors.secondary : Colors.grey[400],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Address details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name.isNotEmpty ? name : 'Nama belum diisi',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        if (isMain) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.secondary,
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              'Utama',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Phone
                    if (phone.isNotEmpty)
                      Text(
                        phone,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    const SizedBox(height: 8),

                    // Address
                    Text(
                      address,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Edit button
              TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Ubah',
                  style: TextStyle(
                    fontSize: 13,
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
