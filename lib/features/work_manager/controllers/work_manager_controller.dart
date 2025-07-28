import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/services/work_manager_service.dart';
import '../../../core/services/log_service.dart';

class WorkManagerController extends GetxController {
  final WorkManagerService _workManagerService = WorkManagerService.getInstance();
  final LogService _logService = LogService.getInstance();

  // Observables
  final RxList<WorkStatus> workStatuses = <WorkStatus>[].obs;
  final RxList<WorkInfo> activeWorks = <WorkInfo>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Available task types
  final List<String> taskTypes = ['ping', 'ssh_check', 'system_monitor', 'file_sync'];

  @override
  void onInit() {
    super.onInit();
    _logService.info('WorkManager Controller initialized');
    _checkNotificationPermission();
    refreshWorkStatus();
    // Auto-refresh every 10 seconds
    _startAutoRefresh();
  }

  Future<void> _checkNotificationPermission() async {
    try {
      final status = await Permission.notification.status;
      if (status.isDenied || status.isPermanentlyDenied) {
        _logService.warning('Notification permission not granted: $status');
        _showNotificationPermissionDialog();
      } else {
        _logService.info('Notification permission granted: $status');
      }
    } catch (e) {
      _logService.error('Error checking notification permission', e);
    }
  }

  void _showNotificationPermissionDialog() {
    Get.dialog(
      AlertDialog(
        title: Text(
          'Enable Notifications',
          style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'To see background task notifications, please enable notifications for this app.',
          style: GoogleFonts.jetBrainsMono(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Maybe Later'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              try {
                final status = await Permission.notification.request();
                if (status.isGranted) {
                  Get.snackbar(
                    'Success',
                    'Notification permission granted!',
                    backgroundColor: Colors.green.withValues(alpha: 0.8),
                    colorText: Colors.white,
                  );
                } else if (status.isPermanentlyDenied) {
                  Get.snackbar(
                    'Permission Required',
                    'Please enable notifications in app settings',
                    backgroundColor: Colors.orange.withValues(alpha: 0.8),
                    colorText: Colors.white,
                    mainButton: TextButton(
                      onPressed: () => openAppSettings(),
                      child: const Text('Settings', style: TextStyle(color: Colors.white)),
                    ),
                  );
                } else {
                  Get.snackbar(
                    'Permission Denied',
                    'Notifications won\'t be shown for background tasks',
                    backgroundColor: Colors.red.withValues(alpha: 0.8),
                    colorText: Colors.white,
                  );
                }
              } catch (e) {
                _showError('Failed to request permission: $e');
              }
            },
            child: const Text('Enable'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _startAutoRefresh() {
    Future.delayed(const Duration(seconds: 10), () async {
      if (!isClosed) {
        await refreshWorkStatus();
        _startAutoRefresh();
      }
    });
  }

  Future<void> refreshWorkStatus() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final statuses = await _workManagerService.getAllWorkStatus();
      final works = await _workManagerService.getActiveWorks();

      workStatuses.assignAll(statuses);
      activeWorks.assignAll(works);

      _logService.info('Refreshed work status: ${statuses.length} tasks');
    } catch (e) {
      errorMessage.value = 'Failed to refresh work status: $e';
      _logService.error('Error refreshing work status', e);
      _showError('Failed to refresh work status: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> startTask(String taskName, String taskType, int intervalSeconds) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _workManagerService.startPeriodicWork(
        taskName: taskName,
        intervalSeconds: intervalSeconds,
        taskType: taskType,
      );

      _logService.info('Started task: $taskName ($taskType) - $result');
      _showSuccess('Task started: $taskName');
      
      // Refresh the status after starting
      await Future.delayed(const Duration(milliseconds: 500));
      await refreshWorkStatus();
    } catch (e) {
      errorMessage.value = 'Failed to start task: $e';
      _logService.error('Error starting task: $taskName', e);
      _showError('Failed to start task: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> stopTask(String taskName) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _workManagerService.stopWork(taskName);

      _logService.info('Stopped task: $taskName - $result');
      _showSuccess('Task stopped: $taskName');
      
      // Refresh the status after stopping
      await Future.delayed(const Duration(milliseconds: 500));
      await refreshWorkStatus();
    } catch (e) {
      errorMessage.value = 'Failed to stop task: $e';
      _logService.error('Error stopping task: $taskName', e);
      _showError('Failed to stop task: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> cancelAllTasks() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _workManagerService.cancelAllWork();

      _logService.info('Cancelled all tasks - $result');
      _showSuccess('All tasks cancelled');
      
      // Refresh the status after cancelling
      await Future.delayed(const Duration(milliseconds: 500));
      await refreshWorkStatus();
    } catch (e) {
      errorMessage.value = 'Failed to cancel all tasks: $e';
      _logService.error('Error cancelling all tasks', e);
      _showError('Failed to cancel all tasks: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> sendTestNotification() async {
    try {
      final result = await _workManagerService.sendTestNotification();
      _logService.info('Test notification sent - $result');
      return result;
    } catch (e) {
      _logService.error('Error sending test notification', e);
      throw e;
    }
  }

  Future<void> createQuickTask(String type) async {
    final taskName = '${type}_${DateTime.now().millisecondsSinceEpoch}';
    await startTask(taskName, type, 20);
  }

  void _showSuccess(String message) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: Colors.green.withValues(alpha: 0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red.withValues(alpha: 0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Never';
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String formatNextSchedule(DateTime? dateTime) {
    if (dateTime == null) return 'Not scheduled';
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.isNegative) return 'Overdue';
    
    if (difference.inSeconds < 60) {
      return 'in ${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return 'in ${difference.inMinutes}m';
    } else {
      return 'in ${difference.inHours}h';
    }
  }

  Color getStatusColor(String state) {
    switch (state.toUpperCase()) {
      case 'RUNNING':
        return Colors.blue;
      case 'ENQUEUED':
        return Colors.orange;
      case 'SUCCEEDED':
        return Colors.green;
      case 'FAILED':
        return Colors.red;
      case 'CANCELLED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData getTaskTypeIcon(String taskType) {
    switch (taskType) {
      case 'ping':
        return Icons.network_ping;
      case 'ssh_check':
        return Icons.terminal;
      case 'system_monitor':
        return Icons.monitor;
      case 'file_sync':
        return Icons.sync;
      default:
        return Icons.work;
    }
  }

  @override
  void onClose() {
    _logService.info('WorkManager Controller disposed');
    super.onClose();
  }
}
