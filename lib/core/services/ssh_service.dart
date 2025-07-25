import 'dart:async';
import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';
import '../constants/app_constants.dart';

enum SSHConnectionStatus {
  disconnected,
  connecting,
  connected,
  failed,
  timeout,
}

class SSHConnectionInfo {
  final String host;
  final int port;
  final String username;
  final String? password;
  final String? privateKey;

  SSHConnectionInfo({
    required this.host,
    this.port = AppConstants.defaultSshPort,
    required this.username,
    this.password,
    this.privateKey,
  });

  Map<String, dynamic> toMap() {
    return {
      'host': host,
      'port': port,
      'username': username,
      'ip': host, // For compatibility with storage
    };
  }
}

class CommandResult {
  final String command;
  final String output;
  final String error;
  final int exitCode;
  final DateTime timestamp;

  CommandResult({
    required this.command,
    required this.output,
    required this.error,
    required this.exitCode,
    required this.timestamp,
  });

  bool get isSuccess => exitCode == 0;
  bool get hasError => error.isNotEmpty;
  
  String get formattedOutput {
    if (hasError && output.isEmpty) {
      return error;
    } else if (hasError && output.isNotEmpty) {
      return '$output\n$error';
    }
    return output;
  }
}

class SSHService {
  SSHClient? _client;
  SSHSession? _session;
  SSHConnectionInfo? _connectionInfo;
  SSHConnectionStatus _status = SSHConnectionStatus.disconnected;
  final bool _useInteractiveShell = true;
  
  // Stream subscriptions for managing listeners
  StreamSubscription? _stdoutSubscription;
  StreamSubscription? _stderrSubscription;
  
  final StreamController<SSHConnectionStatus> _statusController = StreamController.broadcast();
  final StreamController<String> _outputController = StreamController.broadcast();
  final StreamController<CommandResult> _commandResultController = StreamController.broadcast();
  
  Stream<SSHConnectionStatus> get statusStream => _statusController.stream;
  Stream<String> get outputStream => _outputController.stream;
  Stream<CommandResult> get commandResultStream => _commandResultController.stream;
  
  SSHConnectionStatus get status => _status;
  bool get isConnected => _status == SSHConnectionStatus.connected;
  SSHConnectionInfo? get connectionInfo => _connectionInfo;

  void _updateStatus(SSHConnectionStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }

  Future<bool> connect(SSHConnectionInfo connectionInfo) async {
    try {
      _updateStatus(SSHConnectionStatus.connecting);
      _connectionInfo = connectionInfo;

      // Create SSH socket
      final socket = await SSHSocket.connect(
        connectionInfo.host,
        connectionInfo.port,
        timeout: const Duration(seconds: AppConstants.connectionTimeout),
      );

      // Create SSH client
      _client = SSHClient(
        socket,
        username: connectionInfo.username,
        onPasswordRequest: () => connectionInfo.password ?? '',
      );

      // Wait for authentication
      await _client!.authenticated;
      
      // Create interactive shell session for persistent state
      if (_useInteractiveShell) {
        _session = await _client!.shell();
        _setupInteractiveShell();
        
        // Send initial command to clear any shell startup messages
        await Future.delayed(const Duration(milliseconds: 200));
        _session!.stdin.add(utf8.encode('echo "SSH_READY"\n'));
        await Future.delayed(const Duration(milliseconds: 300));
      }
      
      _updateStatus(SSHConnectionStatus.connected);
      _outputController.add('Connected to ${connectionInfo.username}@${connectionInfo.host}\n');
      
      return true;
    } catch (e) {
      if (e.toString().contains('timeout') || e.toString().contains('Timeout')) {
        _updateStatus(SSHConnectionStatus.timeout);
        _outputController.add('Connection timeout: $e\n');
      } else {
        _updateStatus(SSHConnectionStatus.failed);
        _outputController.add('Connection error: $e\n');
      }
      return false;
    }
  }

  void _setupInteractiveShell() {
    if (_session == null) return;
    
    // Set up one-time listeners for the interactive shell
    _stdoutSubscription = _session!.stdout.listen((data) {
      final output = utf8.decode(data);
      _outputController.add(output);
    });
    
    _stderrSubscription = _session!.stderr.listen((data) {
      final error = utf8.decode(data);
      _outputController.add(error);
    });
  }

  Future<CommandResult> executeCommand(String command) async {
    if (!isConnected || _client == null) {
      final result = CommandResult(
        command: command,
        output: '',
        error: 'Not connected to server',
        exitCode: -1,
        timestamp: DateTime.now(),
      );
      _commandResultController.add(result);
      return result;
    }

    try {
      _outputController.add('\$ $command\n');
      
      if (_useInteractiveShell && _session != null) {
        // Use interactive shell for persistent state (cd, environment variables, etc.)
        return await _executeInInteractiveShell(command);
      } else {
        // Fallback to individual command execution
        return await _executeIndividualCommand(command);
      }
    } catch (e) {
      final result = CommandResult(
        command: command,
        output: '',
        error: 'Command execution failed: $e',
        exitCode: -1,
        timestamp: DateTime.now(),
      );
      
      _outputController.add('Error: $e\n');
      _commandResultController.add(result);
      return result;
    }
  }

  Future<CommandResult> _executeInInteractiveShell(String command) async {
    if (_session == null) {
      return CommandResult(
        command: command,
        output: '',
        error: 'Interactive shell not available',
        exitCode: -1,
        timestamp: DateTime.now(),
      );
    }

    // Simply send the command to the interactive shell
    // The output will be handled by the existing stream listeners
    _session!.stdin.add(utf8.encode('$command\n'));
    
    // Wait a moment for command to execute
    await Future.delayed(const Duration(milliseconds: 800));
    
    // For cd commands, also run pwd to show current directory
    if (command.trim().startsWith('cd ')) {
      await Future.delayed(const Duration(milliseconds: 200));
      _session!.stdin.add(utf8.encode('pwd\n'));
      await Future.delayed(const Duration(milliseconds: 300));
    }

    final result = CommandResult(
      command: command,
      output: 'Command sent to interactive shell',
      error: '',
      exitCode: 0,
      timestamp: DateTime.now(),
    );
    
    _commandResultController.add(result);
    return result;
  }

  Future<CommandResult> _executeIndividualCommand(String command) async {
    final session = await _client!.execute(command);
    
    // Read output and error streams
    final outputFuture = utf8.decoder.bind(session.stdout).join();
    final errorFuture = utf8.decoder.bind(session.stderr).join();
    
    // Wait for streams to complete
    final output = await outputFuture;
    final error = await errorFuture;
    
    // Wait for session to complete
    await session.done;
    
    // Get exit code from session (may be null)
    int exitCode = 0;
    try {
      exitCode = session.exitCode ?? 0;
    } catch (e) {
      // If we can't get exit code, assume success if no error
      exitCode = error.isEmpty ? 0 : 1;
    }
    
    final result = CommandResult(
      command: command,
      output: output,
      error: error,
      exitCode: exitCode,
      timestamp: DateTime.now(),
    );
    
    // Send output to stream
    if (output.isNotEmpty) {
      _outputController.add(output);
    }
    if (error.isNotEmpty) {
      _outputController.add(error);
    }
    
    _commandResultController.add(result);
    return result;
  }

  Future<SSHSession?> createInteractiveSession() async {
    if (!isConnected || _client == null) {
      return null;
    }

    try {
      _session = await _client!.shell();
      return _session;
    } catch (e) {
      _outputController.add('Failed to create interactive session: $e\n');
      return null;
    }
  }

  Future<void> writeToSession(String input) async {
    if (_session != null) {
      _session!.stdin.add(utf8.encode(input));
    }
  }

  Stream<String>? getSessionOutput() {
    if (_session != null) {
      return utf8.decoder.bind(_session!.stdout);
    }
    return null;
  }

  Stream<String>? getSessionError() {
    if (_session != null) {
      return utf8.decoder.bind(_session!.stderr);
    }
    return null;
  }

  Future<void> disconnect() async {
    try {
      // Cancel stream subscriptions first
      _stdoutSubscription?.cancel();
      _stderrSubscription?.cancel();
      
      _session?.close();
      _client?.close();
      
      _session = null;
      _client = null;
      _connectionInfo = null;
      _stdoutSubscription = null;
      _stderrSubscription = null;
      
      _updateStatus(SSHConnectionStatus.disconnected);
      _outputController.add('Disconnected from server\n');
    } catch (e) {
      _outputController.add('Error during disconnect: $e\n');
    }
  }

  Future<bool> testConnection(SSHConnectionInfo connectionInfo) async {
    try {
      final socket = await SSHSocket.connect(
        connectionInfo.host,
        connectionInfo.port,
        timeout: const Duration(seconds: 10),
      );

      final client = SSHClient(
        socket,
        username: connectionInfo.username,
        onPasswordRequest: () => connectionInfo.password ?? '',
      );

      await client.authenticated;
      client.close();
      
      return true;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _stdoutSubscription?.cancel();
    _stderrSubscription?.cancel();
    _statusController.close();
    _outputController.close();
    _commandResultController.close();
    disconnect();
  }
}
