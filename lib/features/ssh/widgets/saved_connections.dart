import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/storage_service.dart';
import '../../../shared/widgets/custom_button.dart';
import '../controllers/ssh_controller.dart';

class SavedConnections extends StatelessWidget {
  const SavedConnections({super.key});

  @override
  Widget build(BuildContext context) {
    final SSHController controller = Get.find<SSHController>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.smallPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bookmark,
                  color: Theme.of(context).primaryColor,
                  size: 18,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  'Saved Connections',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                CustomButton(
                  text: 'Clear All',
                  icon: Icons.clear_all,
                  onPressed: () => _showClearAllDialog(context, controller),
                  type: ButtonType.text,
                  fontSize: 12,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            
            Obx(() {
              if (controller.savedConnections.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppConstants.largePadding),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.bookmark_border,
                        size: 48,
                        color: Theme.of(context).dividerColor,
                      ),
                      const SizedBox(height: AppConstants.smallPadding),
                      Text(
                        'No saved connections',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(height: AppConstants.smallPadding),
                      Text(
                        'Save connections for quick access',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.savedConnections.length,
                separatorBuilder: (context, index) => 
                    const SizedBox(height: AppConstants.smallPadding),
                itemBuilder: (context, index) {
                  final connection = controller.savedConnections[index];
                  return _buildConnectionCard(context, controller, connection);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionCard(
    BuildContext context,
    SSHController controller,
    Map<String, dynamic> connection,
  ) {
    final String host = connection['ip'] ?? connection['host'] ?? 'Unknown';
    final String username = connection['username'] ?? 'Unknown';
    final int port = connection['port'] ?? 22;
    final String? savedAt = connection['savedAt'];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppConstants.borderRadius / 2),
          ),
          child: Icon(
            Icons.computer,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                '$username@$host',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (port != 22) ...[
              const SizedBox(width: AppConstants.smallPadding),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.smallPadding,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius / 3),
                ),
                child: Text(
                  ':$port',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: savedAt != null
            ? Text(
                'Saved ${_formatDate(savedAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomButton(
              text: 'Load',
              icon: Icons.launch,
              onPressed: () => controller.loadConnection(connection),
              type: ButtonType.outline,
              fontSize: 12,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
                vertical: AppConstants.smallPadding,
              ),
              height: 32,
            ),
            const SizedBox(width: AppConstants.smallPadding),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
                size: 20,
              ),
              onPressed: () => _showDeleteDialog(context, controller, connection),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      final Duration difference = DateTime.now().difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  void _showDeleteDialog(
    BuildContext context,
    SSHController controller,
    Map<String, dynamic> connection,
  ) {
    final String host = connection['ip'] ?? connection['host'] ?? 'Unknown';
    final String username = connection['username'] ?? 'Unknown';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Connection'),
          content: Text(
            'Are you sure you want to delete the saved connection to $username@$host?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                controller.removeConnection(connection);
                Navigator.of(context).pop();
                Get.snackbar(
                  'Deleted',
                  'Connection removed from saved list',
                  backgroundColor: Colors.orange.withValues(alpha: 0.8),
                  colorText: Colors.white,
                );
              },
              child: Text(
                'Delete',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showClearAllDialog(BuildContext context, SSHController controller) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Connections'),
          content: const Text(
            'Are you sure you want to delete all saved connections? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final storageService = await StorageService.getInstance();
                await storageService.clearAllConnections();
                controller.savedConnections.clear();
                Get.snackbar(
                  'Cleared',
                  'All saved connections have been removed',
                  backgroundColor: Colors.orange.withValues(alpha: 0.8),
                  colorText: Colors.white,
                );
              },
              child: Text(
                'Clear All',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
