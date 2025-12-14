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

  int _getCurrentStep(String status) {
    switch (status.toLowerCase()) {
      case 'requested':
        return 0; // Diajukan
      case 'processing':
        return 1; // Diproses
      case 'completed':
        return 2; // Selesai
      default:
        return 0;
    }
  }

  String _getEstimatedCompletion(String status) {
    switch (status.toLowerCase()) {
      case 'requested':
        return 'Perkiraan selesai 2-3 hari lagi';
      case 'processing':
        return 'Perkiraan selesai 1 hari lagi';
      case 'completed':
        return 'Refund telah selesai';
      default:
        return 'Perkiraan selesai 2-3 hari lagi';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _getCurrentStep(refund.refundStatus);
    final dateFormatter = DateFormat('dd-MM-yyyy, HH:mm');

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
              // Progress Stepper
              _buildProgressStepper(currentStep),
              const SizedBox(height: 12),

              // Estimasi selesai
              Center(
                child: Text(
                  _getEstimatedCompletion(refund.refundStatus),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
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

    // Always add initial submission
    timeline.add({
      'message': 'Permintaan refund diajukan',
      'timestamp': refund.createdAt,
    });

    // Add processing if status is processing or completed
    if (refund.refundStatus.toLowerCase() == 'processing' ||
        refund.refundStatus.toLowerCase() == 'completed') {
      timeline.add({
        'message': 'Refund sedang diproses',
        'timestamp': refund.processedAt ?? refund.createdAt.add(const Duration(hours: 2)),
      });
    }

    // Add completed if status is completed
    if (refund.refundStatus.toLowerCase() == 'completed') {
      timeline.add({
        'message': 'Dana telah dikembalikan',
        'timestamp': refund.completedAt ?? refund.createdAt.add(const Duration(days: 1)),
      });
    }

    return Column(
      children: List.generate(timeline.length, (index) {
        final item = timeline[index];
        final isLast = index == timeline.length - 1;

        return _buildTimelineItem(
          message: item['message'],
          timestamp: dateFormatter.format(item['timestamp']),
          isLast: isLast,
        );
      }),
    );
  }

  Widget _buildTimelineItem({
    required String message,
    required String timestamp,
    required bool isLast,
  }) {
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
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.grey[300],
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
