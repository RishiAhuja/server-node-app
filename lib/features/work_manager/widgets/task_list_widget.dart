import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/work_manager_service.dart';
import '../controllers/work_manager_controller.dart';

class TaskListWidget extends StatelessWidget {
  const TaskListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final WorkManagerController controller = Get.find<WorkManagerController>();

    return Container(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Obx(() {
        if (controller.isLoading.value && controller.workStatuses.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (controller.workStatuses.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: controller.refreshWorkStatus,
          child: ListView.builder(
            itemCount: controller.workStatuses.length,
            itemBuilder: (context, index) {
              final workStatus = controller.workStatuses[index];
              return _buildTaskCard(workStatus, controller);
            },
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.work_off,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Text(
            'No Active Tasks',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            'Create a new task to get started',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(WorkStatus workStatus, WorkManagerController controller) {
    final isActive = workStatus.isActive;
    final successRate = workStatus.successRate * 100;

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Header
            Row(
              children: [
                Icon(
                  controller.getTaskTypeIcon(_getTaskType(workStatus.taskName)),
                  color: controller.getStatusColor(workStatus.state),
                  size: 20,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workStatus.taskName,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _getTaskType(workStatus.taskName).toUpperCase(),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: controller.getStatusColor(workStatus.state).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: controller.getStatusColor(workStatus.state).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    workStatus.state,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: controller.getStatusColor(workStatus.state),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.smallPadding),
            
            // Task Details
            Container(
              padding: const EdgeInsets.all(AppConstants.smallPadding),
              decoration: BoxDecoration(
                color: AppColors.backgroundColor,
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Last Result', workStatus.lastResult),
                  _buildDetailRow('Last Run', controller.formatDateTime(workStatus.lastRunDateTime)),
                  _buildDetailRow('Next Run', controller.formatNextSchedule(workStatus.nextScheduleDateTime)),
                  _buildDetailRow('Attempts', '${workStatus.runAttemptCount}'),
                ],
              ),
            ),
            
            const SizedBox(height: AppConstants.smallPadding),
            
            // Statistics Row
            Row(
              children: [
                Expanded(
                  child: _buildStatChip(
                    'Success',
                    '${workStatus.successCount}',
                    AppColors.successColor,
                  ),
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  child: _buildStatChip(
                    'Failures',
                    '${workStatus.failureCount}',
                    AppColors.errorColor,
                  ),
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  child: _buildStatChip(
                    'Success Rate',
                    '${successRate.toStringAsFixed(0)}%',
                    _getSuccessRateColor(successRate),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.smallPadding),
            
            // Action Buttons
            Row(
              children: [
                if (isActive)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => controller.stopTask(workStatus.taskName),
                      icon: const Icon(Icons.stop, size: 16),
                      label: const Text('Stop'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.errorColor,
                        foregroundColor: Colors.white,
                        textStyle: GoogleFonts.jetBrainsMono(fontSize: 12),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showRestartDialog(workStatus, controller),
                      icon: const Icon(Icons.restart_alt, size: 16),
                      label: const Text('Restart'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        textStyle: GoogleFonts.jetBrainsMono(fontSize: 12),
                      ),
                    ),
                  ),
                const SizedBox(width: AppConstants.smallPadding),
                IconButton(
                  onPressed: () => _showTaskDetails(workStatus),
                  icon: const Icon(Icons.info_outline),
                  color: AppColors.infoColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _getTaskType(String taskName) {
    if (taskName.contains('ping')) return 'ping';
    if (taskName.contains('ssh')) return 'ssh_check';
    if (taskName.contains('monitor')) return 'system_monitor';
    if (taskName.contains('sync')) return 'file_sync';
    return 'ping'; // default
  }

  Color _getSuccessRateColor(double rate) {
    if (rate >= 80) return AppColors.successColor;
    if (rate >= 60) return AppColors.warningColor;
    return AppColors.errorColor;
  }

  void _showRestartDialog(WorkStatus workStatus, WorkManagerController controller) {
    Get.dialog(
      AlertDialog(
        title: Text(
          'Restart Task',
          style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Restart "${workStatus.taskName}" with default settings?',
          style: GoogleFonts.jetBrainsMono(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.startTask(
                workStatus.taskName,
                _getTaskType(workStatus.taskName),
                20, // default interval
              );
            },
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  void _showTaskDetails(WorkStatus workStatus) {
    Get.dialog(
      AlertDialog(
        title: Text(
          workStatus.taskName,
          style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Task Type', _getTaskType(workStatus.taskName).toUpperCase()),
            _buildDetailRow('State', workStatus.state),
            _buildDetailRow('Total Successes', '${workStatus.successCount}'),
            _buildDetailRow('Total Failures', '${workStatus.failureCount}'),
            _buildDetailRow('Run Attempts', '${workStatus.runAttemptCount}'),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'Last Result:',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.backgroundColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                workStatus.lastResult,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
