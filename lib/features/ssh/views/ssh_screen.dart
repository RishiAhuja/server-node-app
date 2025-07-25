import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../controllers/ssh_controller.dart';
import '../widgets/connection_form.dart';
import '../widgets/terminal_widget.dart';
import '../widgets/saved_connections.dart';

class SSHScreen extends StatelessWidget {
  const SSHScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the SSH controller
    Get.put(SSHController());

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.terminal,
              color: Colors.white,
            ),
            const SizedBox(width: AppConstants.smallPadding),
            const Text('SSH Terminal'),
          ],
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 1200) {
            // Desktop layout - 3 columns
            return _buildDesktopLayout();
          } else if (constraints.maxWidth > 800) {
            // Tablet layout - 2 columns
            return _buildTabletLayout();
          } else {
            // Mobile layout - single column with tabs
            return _buildMobileLayout();
          }
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.smallPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left panel - Connection form and saved connections
          Expanded(
            flex: 1,
            child: Column(
              children: [
                const ConnectionForm(),
                const SizedBox(height: AppConstants.smallPadding),
                Expanded(
                  child: const SavedConnections(),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.smallPadding),
          
          // Right panel - Terminal
          Expanded(
            flex: 2,
            child: const TerminalWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.smallPadding),
      child: Column(
        children: [
          // Top - Connection form
          const ConnectionForm(),
          const SizedBox(height: AppConstants.smallPadding),
          
          // Bottom - Terminal and saved connections
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: const TerminalWidget(),
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  flex: 1,
                  child: const SavedConnections(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Theme.of(Get.context!).primaryColor,
            child: const TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(
                  icon: Icon(Icons.settings_ethernet),
                  text: 'Connect',
                ),
                Tab(
                  icon: Icon(Icons.terminal),
                  text: 'Terminal',
                ),
                Tab(
                  icon: Icon(Icons.bookmark),
                  text: 'Saved',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Connection tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.smallPadding),
                  child: const ConnectionForm(),
                ),
                
                // Terminal tab
                Padding(
                  padding: const EdgeInsets.all(AppConstants.smallPadding),
                  child: const TerminalWidget(),
                ),
                
                // Saved connections tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.smallPadding),
                  child: const SavedConnections(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.terminal,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: AppConstants.smallPadding),
              const Text('SSH Terminal'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'A modern SSH client for Flutter that allows you to connect to remote servers and execute commands in real-time.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              const Text(
                'Features:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppConstants.smallPadding),
              _buildFeatureItem('🔐 Secure SSH connections'),
              _buildFeatureItem('💻 Real-time command execution'),
              _buildFeatureItem('📱 Responsive design'),
              _buildFeatureItem('💾 Save connections for quick access'),
              _buildFeatureItem('🎨 Modern terminal interface'),
              _buildFeatureItem('⚡ Fast and lightweight'),
              const SizedBox(height: AppConstants.defaultPadding),
              Text(
                'Version: ${AppConstants.appVersion}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text('• $text'),
    );
  }
}
