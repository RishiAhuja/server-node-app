import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../controllers/work_manager_controller.dart';
import '../widgets/task_list_widget.dart';
import '../widgets/create_task_widget.dart';
import '../widgets/task_stats_widget.dart';

class WorkManagerScreen extends StatelessWidget {
  const WorkManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final WorkManagerController controller = Get.put(WorkManagerController());

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.work_history,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  'Background Tasks',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Obx(() => IconButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () => controller.refreshWorkStatus(),
                  icon: controller.isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  color: AppColors.primaryColor,
                )),
                IconButton(
                  onPressed: () => _showCancelAllDialog(controller),
                  icon: const Icon(Icons.clear_all),
                  color: AppColors.errorColor,
                ),
                IconButton(
                  onPressed: () => _sendTestNotification(controller),
                  icon: const Icon(Icons.notifications_active),
                  color: AppColors.infoColor,
                ),
              ],
            ),
          ),

          // Error Message
          Obx(() {
            if (controller.errorMessage.value.isNotEmpty) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.all(AppConstants.smallPadding),
                padding: const EdgeInsets.all(AppConstants.smallPadding),
                decoration: BoxDecoration(
                  color: AppColors.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  border: Border.all(color: AppColors.errorColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppColors.errorColor,
                      size: 16,
                    ),
                    const SizedBox(width: AppConstants.smallPadding),
                    Expanded(
                      child: Text(
                        controller.errorMessage.value,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          color: AppColors.errorColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => controller.errorMessage.value = '',
                      icon: const Icon(Icons.close),
                      iconSize: 16,
                      color: AppColors.errorColor,
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // Stats Overview
          TaskStatsWidget(),

          // Content
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  // Tab Bar
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppConstants.defaultPadding,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceColor,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                    child: TabBar(
                      indicatorColor: AppColors.primaryColor,
                      labelColor: AppColors.primaryColor,
                      unselectedLabelColor: AppColors.textSecondary,
                      labelStyle: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.list, size: 16),
                          text: 'Active Tasks',
                        ),
                        Tab(
                          icon: Icon(Icons.add_task, size: 16),
                          text: 'Create Task',
                        ),
                      ],
                    ),
                  ),

                  // Tab Views
                  Expanded(
                    child: TabBarView(
                      children: [
                        TaskListWidget(),
                        CreateTaskWidget(),
                      ],
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

  void _showCancelAllDialog(WorkManagerController controller) {
    Get.dialog(
      AlertDialog(
        title: Text(
          'Cancel All Tasks',
          style: GoogleFonts.jetBrainsMono(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel all running background tasks?',
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
              controller.cancelAllTasks();
            },
            child: Text(
              'Cancel All',
              style: TextStyle(color: AppColors.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  void _sendTestNotification(WorkManagerController controller) async {
    try {
      final result = await controller.sendTestNotification();
      Get.snackbar(
        'Test Notification',
        result ?? 'Test notification sent',
        backgroundColor: AppColors.successColor.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send test notification: $e',
        backgroundColor: AppColors.errorColor.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }
}
