import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../controllers/work_manager_controller.dart';

class TaskStatsWidget extends StatelessWidget {
  const TaskStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final WorkManagerController controller = Get.find<WorkManagerController>();

    return Container(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() {
        final workStatuses = controller.workStatuses;
        final activeCount = workStatuses.where((w) => w.isActive).length;
        final totalSuccesses = workStatuses.fold<int>(0, (sum, w) => sum + w.successCount);
        final totalFailures = workStatuses.fold<int>(0, (sum, w) => sum + w.failureCount);
        final overallSuccessRate = (totalSuccesses + totalFailures) > 0 
            ? (totalSuccesses / (totalSuccesses + totalFailures)) * 100 
            : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: AppColors.primaryColor,
                  size: 16,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  'Task Statistics',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Active Tasks',
                    activeCount.toString(),
                    Icons.play_circle_filled,
                    AppColors.primaryColor,
                  ),
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  child: _buildStatCard(
                    'Total Tasks',
                    workStatuses.length.toString(),
                    Icons.work,
                    AppColors.infoColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Successes',
                    totalSuccesses.toString(),
                    Icons.check_circle,
                    AppColors.successColor,
                  ),
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  child: _buildStatCard(
                    'Failures',
                    totalFailures.toString(),
                    Icons.error,
                    AppColors.errorColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            // Success Rate Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Success Rate',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${overallSuccessRate.toStringAsFixed(1)}%',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getSuccessRateColor(overallSuccessRate),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.borderColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: overallSuccessRate / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getSuccessRateColor(overallSuccessRate),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.smallPadding),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getSuccessRateColor(double rate) {
    if (rate >= 80) return AppColors.successColor;
    if (rate >= 60) return AppColors.warningColor;
    return AppColors.errorColor;
  }
}
