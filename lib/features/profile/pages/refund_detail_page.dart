import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../shared/models/refund.dart';
import 'package:intl/intl.dart';

class RefundDetailPage extends StatelessWidget {
  final Refund refund;

  const RefundDetailPage({
    super.key,
    required this.refund,
  });

  int _getCurrentStep(RefundStatus status) {
    switch (status) {
      case RefundStatus.ajukan:
        return 0; // Diajukan
      case RefundStatus.diproses:
        return 1; // Diproses
      case RefundStatus.selesai:
        return 2; // Selesai
      case RefundStatus.ditolak:
        return -1; // Ditolak (special case)
    }
  }

  String _getEstimatedCompletion(RefundStatus status) {
    switch (status) {
      case RefundStatus.ajukan:
        return 'Perkiraan selesai 2-3 hari lagi';
      case RefundStatus.diproses:
        return 'Perkiraan selesai 1 hari lagi';
      case RefundStatus.selesai:
        return 'Refund telah selesai';
      case RefundStatus.ditolak:
        return 'Permintaan refund ditolak';
    }
  }

  bool _isRejected(RefundStatus status) {
    return status == RefundStatus.ditolak;
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _getCurrentStep(refund.status);
    final dateFormatter = DateFormat('dd-MM-yyyy, HH:mm');
    final isRejected = _isRejected(refund.status);

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
          'Detail Refund',
          style: AppTextStyles.heading2,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show rejected status card OR progress stepper
              if (isRejected)
                _buildRejectedStatusCard()
              else
                _buildProgressStepper(currentStep),
              const SizedBox(height: 12),

              // Estimasi selesai
              Center(
                child: Text(
                  _getEstimatedCompletion(refund.status),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isRejected ? AppColors.error : AppColors.textSecondary,
                    fontWeight: isRejected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Pembaruan Refund Section
              Text(
                'Pembaruan Refund',
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: 16),

              // Timeline
              _buildTimeline(refund, dateFormatter),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRejectedStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Refund Ditolak',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Permintaan pengembalian dana Anda telah ditolak',
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

  Widget _buildProgressStepper(int currentStep) {
    final steps = ['Diajukan', 'Diproses', 'Selesai'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step labels
        Row(
          children: List.generate(steps.length, (index) {
            final isActive = index <= currentStep;
            final isLast = index == steps.length - 1;

            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      steps[index],
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isActive
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                      textAlign: index == 0 ? TextAlign.left : (isLast ? TextAlign.right : TextAlign.center),
                    ),
                  ),
                  if (!isLast) const Spacer(),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        // Progress bar
        Stack(
          children: [
            // Background bar (inactive)
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // Active bar (filled based on current step)
            FractionallySizedBox(
              widthFactor: (currentStep + 1) / steps.length,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeline(Refund refund, DateFormat dateFormatter) {
    // Create timeline based on status
    final List<Map<String, dynamic>> timeline = [];
    final isRejected = _isRejected(refund.status);

    // Always add initial submission
    timeline.add({
      'message': 'Permintaan refund diajukan',
      'timestamp': refund.createdAt,
      'isRejected': false,
    });

    // If rejected, add rejection message
    if (isRejected) {
      timeline.add({
        'message': 'Permintaan refund ditolak oleh admin',
        'timestamp': refund.statusTimestamps[RefundStatus.ditolak] ??
                     refund.createdAt.add(const Duration(hours: 4)),
        'isRejected': true,
      });
    } else {
      // Add processing if status is diproses or selesai
      if (refund.status == RefundStatus.diproses ||
          refund.status == RefundStatus.selesai) {
        timeline.add({
          'message': 'Refund sedang diproses',
          'timestamp': refund.statusTimestamps[RefundStatus.diproses] ??
                       refund.createdAt.add(const Duration(hours: 2)),
          'isRejected': false,
        });
      }

      // Add completed if status is selesai
      if (refund.status == RefundStatus.selesai) {
        timeline.add({
          'message': 'Dana telah dikembalikan',
          'timestamp': refund.statusTimestamps[RefundStatus.selesai] ??
                       refund.createdAt.add(const Duration(days: 1)),
          'isRejected': false,
        });
      }
    }

    return Column(
      children: List.generate(timeline.length, (index) {
        final item = timeline[index];
        final isLast = index == timeline.length - 1;

        return _buildTimelineItem(
          message: item['message'],
          timestamp: dateFormatter.format(item['timestamp']),
          isLast: isLast,
          isRejected: item['isRejected'] ?? false,
        );
      }),
    );
  }

  Widget _buildTimelineItem({
    required String message,
    required String timestamp,
    required bool isLast,
    required bool isRejected,
  }) {
    final iconColor = isRejected ? AppColors.error : AppColors.primary;
    final iconBackgroundColor = isRejected
        ? AppColors.error.withValues(alpha: 0.1)
        : AppColors.primary.withValues(alpha: 0.1);
    final icon = isRejected ? Icons.close : Icons.notifications_outlined;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconBackgroundColor,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isRejected ? AppColors.error.withValues(alpha: 0.3) : Colors.grey[300],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isRejected ? AppColors.error : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timestamp,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
