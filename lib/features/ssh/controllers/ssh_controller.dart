import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../core/services/ssh_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/log_service.dart';
import '../../../core/constants/app_constants.dart';

class SSHController extends GetxController {
  // Services
  final SSHService _sshService = SSHService();
  final LogService _logService = LogService.getInstance();
  StorageService? _storageService;

  // Observables
  final RxString currentHost = ''.obs;
  final RxString currentUsername = ''.obs;
  final RxString currentPassword = ''.obs;
  final RxInt currentPort = AppConstants.defaultSshPort.obs;
  final Rx<SSHConnectionStatus> connectionStatus = SSHConnectionStatus.disconnected.obs;
  final RxList<String> terminalOutput = <String>[].obs;
  final RxList<CommandResult> commandHistory = <CommandResult>[].obs;
  final RxList<Map<String, dynamic>> savedConnections = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Text controllers
  final TextEditingController hostController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController portController = TextEditingController();
  final TextEditingController commandController = TextEditingController();
  final ScrollController terminalScrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    _setupListeners();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      _storageService = await StorageService.getInstance();
      _logService.info('SSH Controller initialized successfully');
      _loadSavedData();
    } catch (e) {
      _logService.error('Failed to initialize SSH Controller', e);
    }
  }

  void _setupListeners() {
    // Listen to SSH service status changes
    _sshService.statusStream.listen((status) {
      connectionStatus.value = status;
    });

    // Listen to SSH service output
    _sshService.outputStream.listen((output) {
      _addToTerminal(output);
    });

    // Listen to command results
    _sshService.commandResultStream.listen((result) {
      commandHistory.add(result);
      // Keep only last 100 commands
      if (commandHistory.length > 100) {
        commandHistory.removeAt(0);
      }
    });

    // Bind text controllers to observables
    hostController.addListener(() => currentHost.value = hostController.text);
    usernameController.addListener(() => currentUsername.value = usernameController.text);
    passwordController.addListener(() => currentPassword.value = passwordController.text);
    portController.addListener(() {
      int? port = int.tryParse(portController.text);
      if (port != null && port > 0 && port <= 65535) {
        currentPort.value = port;
      }
    });
  }

  void _loadSavedData() {
    if (_storageService == null) return;
    
    // Load last connection details
    final lastIp = _storageService!.getLastIp();
    final lastUsername = _storageService!.getLastUsername();

    if (lastIp != null) {
      hostController.text = lastIp;
      currentHost.value = lastIp;
    }

    if (lastUsername != null) {
      usernameController.text = lastUsername;
      currentUsername.value = lastUsername;
    }

    portController.text = AppConstants.defaultSshPort.toString();

    // Load saved connections
    _loadSavedConnections();
  }

  void _loadSavedConnections() {
    if (_storageService == null) return;
    
    final connections = _storageService!.getSavedConnectionsAsMap();
    savedConnections.assignAll(connections);
  }

  Future<void> connect() async {
    if (currentHost.isEmpty || currentUsername.isEmpty) {
      _showError('Please enter host and username');
      return;
    }

    if (currentPassword.isEmpty) {
      _showError('Please enter password');
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      _logService.info('Attempting to connect to ${currentUsername.value}@${currentHost.value}:${currentPort.value}');
      
      final connectionInfo = SSHConnectionInfo(
        host: currentHost.value,
        port: currentPort.value,
        username: currentUsername.value,
        password: currentPassword.value,
      );

      final success = await _sshService.connect(connectionInfo);

      if (success) {
        _addToTerminal(AppConstants.terminalWelcomeMessage);
        _saveConnectionDetails();
        _logService.info('Successfully connected to ${currentUsername.value}@${currentHost.value}');
        Get.snackbar(
          'Connected',
          'Successfully connected to ${currentUsername.value}@${currentHost.value}',
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      } else {
        _logService.error('Failed to connect to ${currentUsername.value}@${currentHost.value}');
        _showError('Failed to connect. Please check your credentials and try again.');
      }
    } catch (e) {
      _logService.error('Connection error', e);
      _showError('Connection error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> disconnect() async {
    isLoading.value = true;
    try {
      await _sshService.disconnect();
      _clearTerminal();
      Get.snackbar(
        'Disconnected',
        'Successfully disconnected from server',
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      _showError('Disconnect error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> executeCommand(String command) async {
    if (command.trim().isEmpty) return;

    if (!_sshService.isConnected) {
      _showError('Not connected to server');
      return;
    }

    try {
      _logService.info('Executing command: $command');
      await _sshService.executeCommand(command.trim());
      commandController.clear();
      _scrollToBottom();
    } catch (e) {
      _logService.error('Command execution error', e);
      _showError('Command execution error: $e');
    }
  }

  void loadConnection(Map<String, dynamic> connection) {
    hostController.text = connection['ip'] ?? connection['host'] ?? '';
    usernameController.text = connection['username'] ?? '';
    portController.text = (connection['port'] ?? AppConstants.defaultSshPort).toString();
    
    currentHost.value = hostController.text;
    currentUsername.value = usernameController.text;
    currentPort.value = int.tryParse(portController.text) ?? AppConstants.defaultSshPort;
  }

  Future<void> saveCurrentConnection() async {
    if (currentHost.isEmpty || currentUsername.isEmpty || _storageService == null) return;

    final connection = {
      'ip': currentHost.value,
      'host': currentHost.value,
      'username': currentUsername.value,
      'port': currentPort.value,
      'savedAt': DateTime.now().toIso8601String(),
    };

    await _storageService!.saveConnection(connection);
    _loadSavedConnections();
  }

  Future<void> removeConnection(Map<String, dynamic> connection) async {
    if (_storageService == null) return;
    
    await _storageService!.removeConnection(
      connection['ip'] ?? connection['host'] ?? '',
      connection['username'] ?? '',
    );
    _loadSavedConnections();
  }

  void _saveConnectionDetails() {
    if (_storageService == null) return;
    
    _storageService!.saveLastIp(currentHost.value);
    _storageService!.saveLastUsername(currentUsername.value);
    saveCurrentConnection();
  }

  void _addToTerminal(String text) {
    terminalOutput.add(text);
    // Keep only last 1000 lines
    if (terminalOutput.length > AppConstants.maxTerminalHistory) {
      terminalOutput.removeRange(0, terminalOutput.length - AppConstants.maxTerminalHistory);
    }
    _scrollToBottom();
  }

  void _clearTerminal() {
    terminalOutput.clear();
  }

  void clearTerminalOutput() {
    terminalOutput.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (terminalScrollController.hasClients) {
        terminalScrollController.animateTo(
          terminalScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    errorMessage.value = message;
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red.withValues(alpha: 0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  bool validateHost(String host) {
    if (host.isEmpty) return false;
    
    // Check if it's an IP address
    RegExp ipRegex = RegExp(AppConstants.ipAddressPattern);
    if (ipRegex.hasMatch(host)) return true;
    
    // Check if it's a hostname
    RegExp hostnameRegex = RegExp(AppConstants.hostNamePattern);
    return hostnameRegex.hasMatch(host);
  }

  bool validatePort(String port) {
    int? portNum = int.tryParse(port);
    return portNum != null && portNum > 0 && portNum <= 65535;
  }

  String get connectionStatusText {
    switch (connectionStatus.value) {
      case SSHConnectionStatus.disconnected:
        return 'Disconnected';
      case SSHConnectionStatus.connecting:
        return 'Connecting...';
      case SSHConnectionStatus.connected:
        return 'Connected';
      case SSHConnectionStatus.failed:
        return 'Connection Failed';
      case SSHConnectionStatus.timeout:
        return 'Connection Timeout';
    }
  }

  Color get connectionStatusColor {
    switch (connectionStatus.value) {
      case SSHConnectionStatus.disconnected:
        return Colors.grey;
      case SSHConnectionStatus.connecting:
        return Colors.orange;
      case SSHConnectionStatus.connected:
        return Colors.green;
      case SSHConnectionStatus.failed:
      case SSHConnectionStatus.timeout:
        return Colors.red;
    }
  }

  @override
  void onClose() {
    _sshService.dispose();
    hostController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    portController.dispose();
    commandController.dispose();
    terminalScrollController.dispose();
    super.onClose();
  }
}
