import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../shared/models/complaint.dart';

// Enum untuk status retur/complaint
enum ReturStatus {
  ajukan,    // pending - 0
  diproses,  // processing - 1
  selesai,   // resolved - 2
}

class AdminManageReturPage extends StatelessWidget {
  const AdminManageReturPage({super.key});

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
          'Manage Retur',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('complaints')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_return_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada pengajuan retur',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          final complaints = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return Complaint.fromJson(data);
          }).toList();

          // Sort by createdAt descending (newest first)
          complaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final complaint = complaints[index];
              return _ReturCard(complaint: complaint);
            },
          );
        },
      ),
    );
  }
}

class _ReturCard extends StatefulWidget {
  final Complaint complaint;

  const _ReturCard({required this.complaint});

  @override
  State<_ReturCard> createState() => _ReturCardState();
}

class _ReturCardState extends State<_ReturCard> {
  bool _isUpdating = false;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadReturDetails();
  }

  Future<void> _loadReturDetails() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.complaint.userId)
          .get();

      if (userDoc.exists && mounted) {
        setState(() {
          _userEmail = userDoc.data()?['email'] ?? 'Unknown User';
        });
      }
    } catch (e) {
      debugPrint('Error loading retur details: $e');
      if (mounted) {
        setState(() {
          _userEmail = 'Unknown User';
        });
      }
    }
  }

  // Convert complaint status string to ReturStatus enum
  ReturStatus _getReturStatusFromComplaint(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
      case 'processed':
        return ReturStatus.diproses;
      case 'resolved':
        return ReturStatus.selesai;
      case 'pending':
      default:
        return ReturStatus.ajukan;
    }
  }

  // Convert ReturStatus enum to complaint status string
  String _getComplaintStatusFromReturStatus(ReturStatus status) {
    switch (status) {
      case ReturStatus.ajukan:
        return 'pending';
      case ReturStatus.diproses:
        return 'processing';
      case ReturStatus.selesai:
        return 'resolved';
    }
  }

  Future<void> _updateReturStatus(ReturStatus newStatus) async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      // Convert ReturStatus to complaint status string
      final newComplaintStatus = _getComplaintStatusFromReturStatus(newStatus);

      // Update complaint in Firestore
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(widget.complaint.id)
          .update({
        'status': newComplaintStatus,
      });

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Status retur diubah menjadi ${_getStatusText(newStatus)}',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

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
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  String _getStatusText(ReturStatus status) {
    switch (status) {
      case ReturStatus.ajukan:
        return 'Ajukan';
      case ReturStatus.diproses:
        return 'Diproses';
      case ReturStatus.selesai:
        return 'Selesai';
    }
  }

  Color _getStatusColor(ReturStatus status) {
    switch (status) {
      case ReturStatus.ajukan:
        return Colors.blue;
      case ReturStatus.diproses:
        return Colors.orange;
      case ReturStatus.selesai:
        return Colors.green;
    }
  }

  IconData _getStatusIcon(ReturStatus status) {
    switch (status) {
      case ReturStatus.ajukan:
        return Icons.description;
      case ReturStatus.diproses:
        return Icons.access_time;
      case ReturStatus.selesai:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStatus = _getReturStatusFromComplaint(widget.complaint.status);
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(widget.complaint.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Retur #${widget.complaint.id.substring(0, 8)}',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(currentStatus).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(currentStatus),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(currentStatus),
                            size: 16,
                            color: _getStatusColor(currentStatus),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getStatusText(currentStatus),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(currentStatus),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _userEmail ?? 'Loading...',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Order: ${widget.complaint.orderId}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Complaint Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Masalah',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.complaint.issueType,
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Deskripsi',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.complaint.description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                // Status Progress
                _buildStatusProgress(currentStatus),

                const SizedBox(height: 16),

                // Update Status Buttons
                Text(
                  'Ubah Status:',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _StatusButton(
                        status: ReturStatus.ajukan,
                        currentStatus: currentStatus,
                        isUpdating: _isUpdating,
                        onPressed: () => _updateReturStatus(ReturStatus.ajukan),
                        getStatusText: _getStatusText,
                        getStatusColor: _getStatusColor,
                        getStatusIcon: _getStatusIcon,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatusButton(
                        status: ReturStatus.diproses,
                        currentStatus: currentStatus,
                        isUpdating: _isUpdating,
                        onPressed: () => _updateReturStatus(ReturStatus.diproses),
                        getStatusText: _getStatusText,
                        getStatusColor: _getStatusColor,
                        getStatusIcon: _getStatusIcon,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatusButton(
                        status: ReturStatus.selesai,
                        currentStatus: currentStatus,
                        isUpdating: _isUpdating,
                        onPressed: () => _updateReturStatus(ReturStatus.selesai),
                        getStatusText: _getStatusText,
                        getStatusColor: _getStatusColor,
                        getStatusIcon: _getStatusIcon,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusProgress(ReturStatus currentStatus) {
    return Row(
      children: [
        _buildProgressStep(
          status: ReturStatus.ajukan,
          isActive: currentStatus.index >= ReturStatus.ajukan.index,
          isCompleted: currentStatus.index > ReturStatus.ajukan.index,
        ),
        _buildProgressLine(
          isActive: currentStatus.index > ReturStatus.ajukan.index,
        ),
        _buildProgressStep(
          status: ReturStatus.diproses,
          isActive: currentStatus.index >= ReturStatus.diproses.index,
          isCompleted: currentStatus.index > ReturStatus.diproses.index,
        ),
        _buildProgressLine(
          isActive: currentStatus.index > ReturStatus.diproses.index,
        ),
        _buildProgressStep(
          status: ReturStatus.selesai,
          isActive: currentStatus.index >= ReturStatus.selesai.index,
          isCompleted: false,
        ),
      ],
    );
  }

  Widget _buildProgressStep({
    required ReturStatus status,
    required bool isActive,
    required bool isCompleted,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive
                ? _getStatusColor(status)
                : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check : _getStatusIcon(status),
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _getStatusText(status),
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? _getStatusColor(status) : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine({required bool isActive}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 30),
        color: isActive ? AppColors.primary : Colors.grey[300],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final ReturStatus status;
  final ReturStatus currentStatus;
  final bool isUpdating;
  final VoidCallback onPressed;
  final String Function(ReturStatus) getStatusText;
  final Color Function(ReturStatus) getStatusColor;
  final IconData Function(ReturStatus) getStatusIcon;

  const _StatusButton({
    required this.status,
    required this.currentStatus,
    required this.isUpdating,
    required this.onPressed,
    required this.getStatusText,
    required this.getStatusColor,
    required this.getStatusIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentStatus = status == currentStatus;
    final color = getStatusColor(status);

    return ElevatedButton(
      onPressed: isUpdating || isCurrentStatus ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isCurrentStatus ? color : Colors.white,
        foregroundColor: isCurrentStatus ? Colors.white : color,
        disabledBackgroundColor: isCurrentStatus ? color : Colors.grey[300],
        disabledForegroundColor: isCurrentStatus ? Colors.white : Colors.grey,
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isCurrentStatus ? color : Colors.grey[300]!,
            width: 1,
          ),
        ),
        elevation: 0,
      ),
      child: Column(
        children: [
          Icon(
            getStatusIcon(status),
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            getStatusText(status),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
