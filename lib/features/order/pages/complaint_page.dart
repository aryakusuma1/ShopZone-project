import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_storage/firebase_storage.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../shared/models/order.dart';
import '../../../shared/models/complaint.dart';

class ComplaintPage extends StatefulWidget {
  final Order order;

  const ComplaintPage({
    super.key,
    required this.order,
  });

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? _selectedIssueType;
  XFile? _selectedImage;
  bool _isSubmitting = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';
  bool _skipPhotoUpload = false; // Flag to skip photo upload

  // Check if form is valid
  bool get _isFormValid {
    return _selectedIssueType != null &&
           _descriptionController.text.trim().isNotEmpty &&
           _descriptionController.text.trim().length >= 10;
  }

  final List<Map<String, dynamic>> _issueTypes = [
    {
      'value': 'Barang tidak lengkap',
      'icon': Icons.inventory_2_outlined,
    },
    {
      'value': 'Barang rusak',
      'icon': Icons.broken_image_outlined,
    },
    {
      'value': 'Barang kadaluarsa',
      'icon': Icons.event_busy_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Add listener to update button state when description changes
    _descriptionController.addListener(() {
      setState(() {});
    });
    // Check if complaint already exists for this order
    _checkExistingComplaint();
  }

  Future<void> _checkExistingComplaint() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final existingComplaint = await _firestore
          .collection('complaints')
          .where('orderId', isEqualTo: widget.order.id)
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (existingComplaint.docs.isNotEmpty && mounted) {
        // Complaint already exists, show message and go back
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Anda sudah pernah mengajukan komplain untuk pesanan ini.'),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.pop(context);
        });
      }
    } catch (e) {
      debugPrint('Error checking existing complaint: $e');
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        // Super aggressive compression to ensure upload success
        maxWidth: 600,   // Very small for guaranteed fast upload
        maxHeight: 600,  // Very small for guaranteed fast upload
        imageQuality: 50, // Lower quality for smallest file size
      );

      if (image != null) {
        // Check file size
        final bytes = await image.readAsBytes();
        final sizeInKB = bytes.length / 1024;
        final sizeInMB = sizeInKB / 1024;
        debugPrint('Selected image size: ${sizeInKB.toStringAsFixed(2)} KB (${sizeInMB.toStringAsFixed(2)} MB)');

        // Reject if file is too large (> 500KB after compression)
        if (sizeInKB > 500) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Foto terlalu besar (${sizeInKB.toStringAsFixed(0)} KB). Maksimal 500 KB. Pilih foto lain.',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return; // Don't set the image
        }

        // Warn if file is moderately large
        if (sizeInKB > 300 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ukuran foto: ${sizeInKB.toStringAsFixed(0)} KB. Upload mungkin memakan waktu...',
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.warning,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih foto: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<String?> _uploadImageWithRetry(String complaintId, {int attempt = 1}) async {
    if (_selectedImage == null) return null;

    const maxAttempts = 2; // Try twice
    UploadTask? uploadTask;

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User tidak terautentikasi');
      }

      debugPrint('Starting image upload... (Attempt $attempt/$maxAttempts)');
      if (mounted) {
        setState(() {
          _uploadStatus = attempt > 1
              ? 'Mencoba ulang upload... ($attempt/$maxAttempts)'
              : 'Mempersiapkan upload...';
        });
      }

      // Create unique filename
      final fileName = 'complaint_${complaintId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('complaints').child(user.uid).child(fileName);

      // Get file bytes
      final bytes = await _selectedImage!.readAsBytes();
      final sizeKB = bytes.length / 1024;
      debugPrint('Image size: ${sizeKB.toStringAsFixed(2)} KB');

      if (mounted) {
        setState(() {
          _uploadStatus = 'Mengupload foto (${sizeKB.toStringAsFixed(0)} KB)...';
        });
      }

      // Upload file
      if (kIsWeb) {
        uploadTask = ref.putData(bytes);
      } else {
        final File file = File(_selectedImage!.path);
        uploadTask = ref.putFile(file);
      }

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        // Check if user clicked skip
        if (_skipPhotoUpload) {
          uploadTask?.cancel();
          return;
        }

        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        if (mounted) {
          setState(() {
            _uploadProgress = progress;
            _uploadStatus = 'Mengupload foto... ${(progress * 100).toInt()}%';
          });
        }
        debugPrint('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });

      // Wait for upload to complete with longer timeout
      TaskSnapshot snapshot;
      try {
        snapshot = await uploadTask.timeout(
          const Duration(seconds: 45), // Increased timeout
          onTimeout: () async {
            // Cancel the upload task
            await uploadTask?.cancel();
            throw Exception('TIMEOUT');
          },
        );

        // Check if user clicked skip during upload
        if (_skipPhotoUpload) {
          await uploadTask.cancel();
          throw Exception('USER_SKIPPED');
        }
      } catch (e) {
        if (_skipPhotoUpload || e.toString().contains('USER_SKIPPED')) {
          throw Exception('Upload dilewati oleh user');
        }
        rethrow;
      }

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('Image uploaded successfully: $downloadUrl');

      if (mounted) {
        setState(() {
          _uploadStatus = 'Upload selesai!';
          _uploadProgress = 1.0;
        });
      }

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image (attempt $attempt): $e');

      // Cancel upload task if it's still running
      try {
        await uploadTask?.cancel();
      } catch (_) {}

      // Retry if this is the first attempt and it's a timeout
      if (attempt < maxAttempts && e.toString().contains('TIMEOUT')) {
        debugPrint('Retrying upload...');
        if (mounted) {
          setState(() {
            _uploadProgress = 0.0;
          });
        }
        // Wait a bit before retrying
        await Future.delayed(const Duration(seconds: 2));
        return _uploadImageWithRetry(complaintId, attempt: attempt + 1);
      }

      // If we've exhausted retries or it's a different error, fail
      if (mounted) {
        setState(() {
          _uploadStatus = 'Upload gagal';
          _uploadProgress = 0.0;
        });
      }

      // Re-throw with better error message
      if (e.toString().contains('TIMEOUT')) {
        throw Exception('Upload foto timeout setelah $maxAttempts kali percobaan. Koneksi internet terlalu lambat.');
      } else if (e.toString().contains('permission') || e.toString().contains('PERMISSION_DENIED')) {
        throw Exception('Akses ditolak. Periksa pengaturan Firebase Storage.');
      } else if (e.toString().contains('network') || e.toString().contains('unavailable')) {
        throw Exception('Tidak ada koneksi internet.');
      } else {
        throw Exception('Upload foto gagal: ${e.toString()}');
      }
    }
  }

  // Wrapper function for backwards compatibility
  Future<String?> _uploadImage(String complaintId) async {
    return _uploadImageWithRetry(complaintId);
  }

  Future<void> _submitComplaint() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedIssueType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pilih jenis masalah terlebih dahulu'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
        _uploadProgress = 0.0;
        _uploadStatus = '';
        _skipPhotoUpload = false; // Reset skip flag
      });

      try {
        debugPrint('Starting complaint submission...');

        final user = _auth.currentUser;
        if (user == null) {
          throw Exception('User not logged in');
        }

        debugPrint('User ID: ${user.uid}');

        // Generate complaint ID
        final complaintId = _firestore.collection('complaints').doc().id;
        debugPrint('Generated complaint ID: $complaintId');

        // Upload image if selected (OPTIONAL - will continue without photo if upload fails)
        String? imageUrl;
        bool photoUploadFailed = false;
        if (_selectedImage != null && !_skipPhotoUpload) {
          try {
            debugPrint('Uploading image...');
            imageUrl = await _uploadImage(complaintId);
            debugPrint('Image uploaded successfully: $imageUrl');
          } catch (uploadError) {
            debugPrint('Photo upload failed: $uploadError');
            photoUploadFailed = true;

            // Ask user if they want to continue without photo
            if (!mounted) rethrow;

            final continueWithoutPhoto = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Upload Foto Gagal'),
                    ),
                  ],
                ),
                content: const Text(
                  'Upload foto gagal karena koneksi lambat atau timeout.\n\nApakah Anda ingin melanjutkan mengirim komplain TANPA foto?',
                  style: TextStyle(height: 1.5),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Batalkan'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Lanjut Tanpa Foto'),
                  ),
                ],
              ),
            );

            if (continueWithoutPhoto != true) {
              throw Exception('User membatalkan pengiriman');
            }

            debugPrint('Continuing without photo as per user choice');
          }
        }

        // Create complaint object
        final complaint = Complaint(
          id: complaintId,
          orderId: widget.order.id,
          userId: user.uid,
          issueType: _selectedIssueType!,
          description: _descriptionController.text.trim(),
          imageUrl: imageUrl,
          createdAt: DateTime.now(),
          status: 'pending',
        );

        debugPrint('Saving to Firestore...');
        debugPrint('Complaint data: ${complaint.toJson()}');

        setState(() {
          _uploadStatus = 'Menyimpan komplain...';
        });

        // Save to Firestore
        try {
          await _firestore
              .collection('complaints')
              .doc(complaintId)
              .set(complaint.toJson())
              .timeout(
                const Duration(seconds: 15),
                onTimeout: () {
                  throw Exception('TIMEOUT: Gagal menyimpan data. Koneksi terlalu lambat.');
                },
              );

          debugPrint('Complaint saved successfully!');
        } catch (firestoreError) {
          debugPrint('Firestore error: $firestoreError');
          // Throw with more specific error
          if (firestoreError.toString().contains('TIMEOUT')) {
            throw Exception('Koneksi terlalu lambat. Periksa koneksi internet Anda.');
          } else if (firestoreError.toString().contains('permission') ||
                     firestoreError.toString().contains('PERMISSION_DENIED')) {
            throw Exception('Akses ditolak. Silakan login ulang.');
          } else if (firestoreError.toString().contains('network') ||
                     firestoreError.toString().contains('unavailable')) {
            throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda.');
          } else {
            throw Exception('Gagal menyimpan komplain. Silakan coba lagi.');
          }
        }

        if (!mounted) return;

        setState(() {
          _isSubmitting = false;
        });

        // Show success dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
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
                    // Success Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: photoUploadFailed ? Colors.orange[50] : Colors.green[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        photoUploadFailed ? Icons.check_circle_outline : Icons.check_circle,
                        color: photoUploadFailed ? Colors.orange[600] : Colors.green[600],
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      photoUploadFailed ? 'Komplain Terkirim (Tanpa Foto)' : 'Komplain Terkirim',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Message
                    Text(
                      photoUploadFailed
                          ? 'Komplain Anda telah dikirim tanpa foto. Tim kami akan segera menghubungi Anda.'
                          : 'Komplain Anda telah dikirim. Tim kami akan segera menghubungi Anda.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // OK Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
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
                          'OK',
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

        // After dialog is closed, navigate back to order detail
        if (!mounted) return;

        Navigator.pop(context); // Go back to order detail
        // User will see the complaint status and refund button in order detail
      } catch (e, stackTrace) {
        debugPrint('Error submitting complaint: $e');
        debugPrint('Stack trace: $stackTrace');

        if (!mounted) return;

        setState(() {
          _isSubmitting = false;
        });

        // Parse error message and provide helpful instructions
        String errorMessage = 'Gagal mengirim komplain';
        String? instruction;

        if (e.toString().contains('timeout') || e.toString().contains('TIMEOUT')) {
          errorMessage = 'Upload foto timeout';
          instruction = 'Koneksi internet terlalu lambat. Coba:\n• Gunakan koneksi WiFi yang lebih cepat\n• Pilih foto yang lebih kecil\n• Coba beberapa saat lagi';
        } else if (e.toString().contains('Upload foto')) {
          errorMessage = e.toString().replaceAll('Exception: ', '');
          instruction = 'Periksa koneksi internet Anda dan coba lagi';
        } else if (e.toString().contains('permission') || e.toString().contains('PERMISSION_DENIED')) {
          errorMessage = 'Akses ditolak';
          instruction = 'Tidak memiliki izin untuk mengupload foto. Hubungi administrator.';
        } else if (e.toString().contains('network') || e.toString().contains('unavailable')) {
          errorMessage = 'Tidak ada koneksi internet';
          instruction = 'Pastikan Anda terhubung ke internet dan coba lagi.';
        } else {
          errorMessage = 'Gagal mengirim komplain';
          instruction = e.toString().replaceAll('Exception: ', '');
        }

        // Show error dialog instead of snackbar for better visibility
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
                const Expanded(
                  child: Text(
                    'Gagal Mengirim',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  errorMessage,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if (instruction != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    instruction,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ajukan Komplain atau Retur Barang',
          style: AppTextStyles.heading3,
        ),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Issue Type Dropdown
                  const Text(
                    'Pilih Jenis Masalah',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Custom Dropdown with better styling
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedIssueType,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      hint: Text(
                        'Pilih Jenis Masalah',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 15,
                        ),
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary,
                      ),
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      elevation: 8,
                      borderRadius: BorderRadius.circular(12),
                      menuMaxHeight: 300,
                      items: _issueTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type['value'],
                          child: Row(
                            children: [
                              Icon(
                                type['icon'],
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                type['value'],
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedIssueType = newValue;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description Field
                  const Text(
                    'Deskripsi Masalah',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: 'Jelaskan masalah yang Anda alami...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Deskripsi masalah harus diisi';
                      }
                      if (value.trim().length < 10) {
                        return 'Deskripsi minimal 10 karakter';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Upload Photo Section
                  const Text(
                    'Upload Foto Barang (Opsional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Photo Upload Area - Improved Layout
                  if (_selectedImage == null)
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[50],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 40,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Tambahkan Foto',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Unggah foto barang yang bermasalah untuk\nmempercepat proses komplain/retur.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: const Text(
                                'Pilih Foto',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    // Selected Image Preview - Improved Layout
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[200]!),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image Preview - Support both web and mobile
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: kIsWeb
                                ? FutureBuilder<Uint8List>(
                                    future: _selectedImage!.readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        return Image.memory(
                                          snapshot.data!,
                                          height: 200,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        );
                                      }
                                      return Container(
                                        height: 200,
                                        width: double.infinity,
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    },
                                  )
                                : Image.file(
                                    File(_selectedImage!.path),
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          const SizedBox(height: 12),
                          // Image name
                          Row(
                            children: [
                              Icon(Icons.image, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedImage!.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Remove Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _removeImage,
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text('Hapus Foto'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red[700],
                                side: BorderSide(color: Colors.red[200]!),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isSubmitting || !_isFormValid) ? null : _submitComplaint,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: AppColors.textHint,
                        disabledForegroundColor: Colors.white,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Kirim Komplain/Retur',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Loading overlay with progress
          if (_isSubmitting)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Mengirim Komplain',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Show upload progress if uploading image
                      if (_selectedImage != null && _uploadProgress > 0 && !_uploadStatus.contains('Menyimpan')) ...[
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _uploadProgress,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.secondary,
                            ),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Progress text
                        Text(
                          _uploadStatus,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: _uploadStatus.contains('Mencoba ulang')
                                ? AppColors.warning
                                : AppColors.textSecondary,
                            fontWeight: _uploadStatus.contains('Mencoba ulang')
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // Skip button if upload is taking too long
                        if (_uploadProgress < 0.5) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _skipPhotoUpload = true;
                              });
                            },
                            child: Text(
                              'Lewati Upload Foto',
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ] else ...[
                        Text(
                          _selectedImage != null && !_uploadStatus.contains('Menyimpan')
                              ? 'Mempersiapkan upload foto...'
                              : 'Menyimpan komplain...',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
