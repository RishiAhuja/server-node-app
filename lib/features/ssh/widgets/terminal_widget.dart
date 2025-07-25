import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/ssh_service.dart';
import '../../../shared/widgets/custom_button.dart';
import '../controllers/ssh_controller.dart';

class TerminalWidget extends StatelessWidget {
  const TerminalWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final SSHController controller = Get.find<SSHController>();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Terminal Header
          Container(
            padding: const EdgeInsets.all(AppConstants.smallPadding),
            decoration: BoxDecoration(
              color: AppColors.terminalBackground,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppConstants.borderRadius),
                topRight: Radius.circular(AppConstants.borderRadius),
              ),
            ),
            child: Row(
              children: [
                // Terminal Traffic Lights
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.errorColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.warningColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.successColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppConstants.smallPadding),
                
                Icon(
                  Icons.terminal,
                  color: AppColors.terminalText,
                  size: 16,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  'Terminal',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.terminalText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                
                Obx(() => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: controller.connectionStatus.value == SSHConnectionStatus.connected
                        ? AppColors.successColor.withValues(alpha: 0.2)
                        : AppColors.errorColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    controller.connectionStatus.value == SSHConnectionStatus.connected
                        ? 'Connected'
                        : 'Disconnected',
                    style: GoogleFonts.jetBrainsMono(
                      color: controller.connectionStatus.value == SSHConnectionStatus.connected
                          ? AppColors.successColor
                          : AppColors.errorColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )),
              ],
            ),
          ),
          
          // Terminal Output
          Expanded(
            child: Container(
              width: double.infinity,
              color: AppColors.terminalBackground,
              child: Obx(() => ListView.builder(
                controller: controller.terminalScrollController,
                padding: const EdgeInsets.all(AppConstants.smallPadding),
                itemCount: controller.terminalOutput.length,
                itemBuilder: (context, index) {
                  final line = controller.terminalOutput[index];
                  return _buildTerminalLine(line);
                },
              )),
            ),
          ),
          
          // Command Input
          Container(
            padding: const EdgeInsets.all(AppConstants.smallPadding),
            decoration: const BoxDecoration(
              color: AppColors.terminalBackground,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AppConstants.borderRadius),
                bottomRight: Radius.circular(AppConstants.borderRadius),
              ),
            ),
            child: Obx(() => Column(
              children: [
                // Connection info row (compact)
                if (controller.connectionStatus.value == SSHConnectionStatus.connected)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.smallPadding,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.terminalPrompt.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Connected: ${controller.currentUsername.value}@${controller.currentHost.value}',
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.terminalPrompt,
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: AppConstants.smallPadding),
                
                // Command input row
                Row(
                  children: [
                    // Simple prompt
                    Text(
                      '\$ ',
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.terminalPrompt,
                        fontSize: AppConstants.terminalFontSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    // Command Input
                    Expanded(
                      child: TextField(
                        controller: controller.commandController,
                        enabled: controller.connectionStatus.value == SSHConnectionStatus.connected,
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.terminalText,
                          fontSize: AppConstants.terminalFontSize,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: controller.connectionStatus.value == SSHConnectionStatus.connected
                              ? 'Enter command...'
                              : 'Connect to server first',
                          hintStyle: GoogleFonts.jetBrainsMono(
                            color: AppColors.terminalText.withValues(alpha: 0.5),
                            fontSize: AppConstants.terminalFontSize,
                          ),
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        onSubmitted: (command) {
                          if (command.trim().isNotEmpty) {
                            controller.executeCommand(command);
                          }
                        },
                      ),
                    ),
                    
                    // Send Button
                    const SizedBox(width: AppConstants.smallPadding),
                    CustomButton(
                      text: 'Send',
                      icon: Icons.send,
                      onPressed: controller.connectionStatus.value == SSHConnectionStatus.connected
                          ? () {
                              final command = controller.commandController.text;
                              if (command.trim().isNotEmpty) {
                                controller.executeCommand(command);
                              }
                            }
                          : null,
                      type: ButtonType.primary,
                      fontSize: 10,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.smallPadding,
                        vertical: 4,
                      ),
                      height: 28,
                    ),
                  ],
                ),
              ],
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalLine(String line) {
    // Parse different types of terminal output
    Color textColor = AppColors.terminalText;
    FontWeight fontWeight = FontWeight.normal;
    
    if (line.startsWith('\$ ')) {
      // Command line
      textColor = AppColors.terminalPrompt;
      fontWeight = FontWeight.w500;
    } else if (line.toLowerCase().contains('error') || 
               line.toLowerCase().contains('failed') ||
               line.toLowerCase().contains('denied')) {
      // Error messages
      textColor = AppColors.terminalError;
    } else if (line.toLowerCase().contains('warning') ||
               line.toLowerCase().contains('warn')) {
      // Warning messages
      textColor = AppColors.terminalWarning;
    } else if (line.toLowerCase().contains('success') ||
               line.toLowerCase().contains('connected') ||
               line.toLowerCase().contains('welcome')) {
      // Success messages
      textColor = AppColors.terminalInfo;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: SelectableText(
        line,
        style: GoogleFonts.jetBrainsMono(
          color: textColor,
          fontSize: AppConstants.terminalFontSize,
          fontWeight: fontWeight,
          height: 1.4,
        ),
      ),
    );
  }
}
