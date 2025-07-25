import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/ssh_service.dart';
import '../controllers/ssh_controller.dart';

class ConnectionForm extends StatelessWidget {
  const ConnectionForm({super.key});

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
                  Icons.settings_ethernet,
                  color: Theme.of(context).primaryColor,
                  size: 18,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  'SSH Connection',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Obx(() => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: controller.connectionStatusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: controller.connectionStatusColor,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: controller.connectionStatusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        controller.connectionStatusText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: controller.connectionStatusColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: CustomTextField(
                    label: 'Host / IP Address',
                    hint: 'Enter IP address or hostname',
                    controller: controller.hostController,
                    keyboardType: TextInputType.text,
                    prefixIcon: const Icon(Icons.computer),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter host address';
                      }
                      if (!controller.validateHost(value)) {
                        return 'Please enter valid IP or hostname';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  flex: 1,
                  child: CustomTextField(
                    label: 'Port',
                    hint: '22',
                    controller: controller.portController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(5),
                    ],
                    prefixIcon: const Icon(Icons.settings_ethernet),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (!controller.validatePort(value)) {
                        return 'Invalid port';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Username',
                    hint: 'Enter username',
                    controller: controller.usernameController,
                    keyboardType: TextInputType.text,
                    prefixIcon: const Icon(Icons.person),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter username';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  child: CustomTextField(
                    label: 'Password',
                    hint: 'Enter password',
                    controller: controller.passwordController,
                    obscureText: true,
                    keyboardType: TextInputType.text,
                    prefixIcon: const Icon(Icons.lock),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter password';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            
            Row(
              children: [
                Obx(() => CustomButton(
                  text: controller.connectionStatus.value == SSHConnectionStatus.connected 
                      ? 'Disconnect' 
                      : 'Connect',
                  icon: controller.connectionStatus.value == SSHConnectionStatus.connected
                      ? Icons.link_off
                      : Icons.link,
                  onPressed: () {
                    if (controller.connectionStatus.value == SSHConnectionStatus.connected) {
                      controller.disconnect();
                    } else {
                      controller.connect();
                    }
                  },
                  isLoading: controller.isLoading.value,
                  type: controller.connectionStatus.value == SSHConnectionStatus.connected
                      ? ButtonType.outline
                      : ButtonType.primary,
                  fontSize: 12,
                  height: 32,
                )),
                const SizedBox(width: AppConstants.smallPadding),
                Obx(() => CustomButton(
                  text: 'Save',
                  icon: Icons.bookmark,
                  onPressed: controller.currentHost.isNotEmpty && 
                           controller.currentUsername.isNotEmpty
                      ? controller.saveCurrentConnection
                      : null,
                  type: ButtonType.secondary,
                  fontSize: 12,
                  height: 32,
                )),
                const Spacer(),
                CustomButton(
                  text: 'Clear Terminal',
                  icon: Icons.clear_all,
                  onPressed: controller.clearTerminalOutput,
                  type: ButtonType.text,
                  fontSize: 11,
                  height: 32,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
