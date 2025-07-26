import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../controllers/work_manager_controller.dart';

class CreateTaskWidget extends StatelessWidget {
  CreateTaskWidget({super.key});

  final TextEditingController taskNameController = TextEditingController();
  final TextEditingController intervalController = TextEditingController(text: '20');
  final RxString selectedTaskType = 'ping'.obs;
  final RxInt intervalSeconds = 20.obs;

  @override
  Widget build(BuildContext context) {
    final WorkManagerController controller = Get.find<WorkManagerController>();

    return Container(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Start Section
            _buildQuickStartSection(controller),
            
            const SizedBox(height: AppConstants.largePadding),
            
            // Custom Task Section
            _buildCustomTaskSection(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStartSection(WorkManagerController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flash_on,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  'Quick Start',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              'Start a common task with default settings (runs every 20 seconds)',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Wrap(
              spacing: AppConstants.smallPadding,
              runSpacing: AppConstants.smallPadding,
              children: controller.taskTypes.map((taskType) {
                return CustomButton(
                  text: _getTaskDisplayName(taskType),
                  icon: controller.getTaskTypeIcon(taskType),
                  onPressed: () => controller.createQuickTask(taskType),
                  type: ButtonType.secondary,
                  fontSize: 12,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.defaultPadding,
                    vertical: AppConstants.smallPadding,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTaskSection(WorkManagerController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tune,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  'Custom Task',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              'Create a task with custom settings',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            // Task Name Input
            CustomTextField(
              label: 'Task Name',
              hint: 'Enter unique task name',
              controller: taskNameController,
              prefixIcon: const Icon(Icons.label),
            ),
            
            const SizedBox(height: AppConstants.defaultPadding),

            // Task Type Selection
            Text(
              'Task Type',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Obx(() => Wrap(
              spacing: AppConstants.smallPadding,
              runSpacing: AppConstants.smallPadding,
              children: controller.taskTypes.map((taskType) {
                final isSelected = selectedTaskType.value == taskType;
                return InkWell(
                  onTap: () => selectedTaskType.value = taskType,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.defaultPadding,
                      vertical: AppConstants.smallPadding,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppColors.primaryColor.withValues(alpha: 0.1)
                          : AppColors.backgroundColor,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      border: Border.all(
                        color: isSelected 
                            ? AppColors.primaryColor
                            : AppColors.borderColor,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          controller.getTaskTypeIcon(taskType),
                          size: 16,
                          color: isSelected 
                              ? AppColors.primaryColor
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppConstants.smallPadding),
                        Text(
                          _getTaskDisplayName(taskType),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            color: isSelected 
                                ? AppColors.primaryColor
                                : AppColors.textPrimary,
                            fontWeight: isSelected 
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            )),

            const SizedBox(height: AppConstants.defaultPadding),

            // Interval Input
            CustomTextField(
              label: 'Interval (seconds)',
              hint: 'Enter interval in seconds',
              controller: intervalController,
              prefixIcon: const Icon(Icons.timer),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final interval = int.tryParse(value);
                if (interval != null && interval > 0) {
                  intervalSeconds.value = interval;
                }
              },
            ),

            const SizedBox(height: AppConstants.smallPadding),

            // Interval Info
            Obx(() => Container(
              padding: const EdgeInsets.all(AppConstants.smallPadding),
              decoration: BoxDecoration(
                color: AppColors.infoColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                border: Border.all(color: AppColors.infoColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.infoColor,
                  ),
                  const SizedBox(width: AppConstants.smallPadding),
                  Expanded(
                    child: Text(
                      'Task will run every ${intervalSeconds.value} seconds. Minimum interval is 15 seconds due to Android WorkManager limitations.',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: AppColors.infoColor,
                      ),
                    ),
                  ),
                ],
              ),
            )),

            const SizedBox(height: AppConstants.defaultPadding),

            // Task Description
            Obx(() => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              decoration: BoxDecoration(
                color: AppColors.backgroundColor,
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getTaskDisplayName(selectedTaskType.value),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getTaskDescription(selectedTaskType.value),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )),

            const SizedBox(height: AppConstants.largePadding),

            // Create Button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Create Task',
                icon: Icons.add_task,
                onPressed: () => _createCustomTask(controller),
                type: ButtonType.primary,
                fontSize: 14,
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.defaultPadding,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTaskDisplayName(String taskType) {
    switch (taskType) {
      case 'ping':
        return 'Network Ping';
      case 'ssh_check':
        return 'SSH Check';
      case 'system_monitor':
        return 'System Monitor';
      case 'file_sync':
        return 'File Sync';
      default:
        return taskType;
    }
  }

  String _getTaskDescription(String taskType) {
    switch (taskType) {
      case 'ping':
        return 'Pings Google to check internet connectivity and network latency.';
      case 'ssh_check':
        return 'Checks SSH connection availability and response time.';
      case 'system_monitor':
        return 'Monitors device memory usage and system performance.';
      case 'file_sync':
        return 'Simulates file synchronization operations with status reporting.';
      default:
        return 'Custom background task with configurable execution.';
    }
  }

  void _createCustomTask(WorkManagerController controller) {
    final taskName = taskNameController.text.trim();
    final interval = int.tryParse(intervalController.text) ?? 20;

    if (taskName.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a task name',
        backgroundColor: AppColors.errorColor.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return;
    }

    if (interval < 15) {
      Get.snackbar(
        'Error',
        'Interval must be at least 15 seconds',
        backgroundColor: AppColors.errorColor.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return;
    }

    controller.startTask(taskName, selectedTaskType.value, interval);
    
    // Clear form
    taskNameController.clear();
    intervalController.text = '20';
    selectedTaskType.value = 'ping';
  }
}
