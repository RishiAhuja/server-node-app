import 'package:flutter/services.dart';

class WorkManagerService {
  static const MethodChannel _channel = MethodChannel('work_manager_plugin');
  
  static WorkManagerService? _instance;
  
  static WorkManagerService getInstance() {
    _instance ??= WorkManagerService._internal();
    return _instance!;
  }
  
  WorkManagerService._internal();

  /// Start a periodic background task
  Future<String?> startPeriodicWork({
    required String taskName,
    int intervalSeconds = 20,
    String taskType = 'ping',
  }) async {
    try {
      final result = await _channel.invokeMethod('startPeriodicWork', {
        'taskName': taskName,
        'intervalSeconds': intervalSeconds,
        'taskType': taskType,
      });
      return result as String?;
    } on PlatformException catch (e) {
      throw WorkManagerException('Failed to start work: ${e.message}');
    }
  }

  /// Stop a specific background task
  Future<String?> stopWork(String taskName) async {
    try {
      final result = await _channel.invokeMethod('stopWork', {
        'taskName': taskName,
      });
      return result as String?;
    } on PlatformException catch (e) {
      throw WorkManagerException('Failed to stop work: ${e.message}');
    }
  }

  /// Get list of active background tasks
  Future<List<WorkInfo>> getActiveWorks() async {
    try {
      final result = await _channel.invokeMethod('getActiveWorks');
      final List<dynamic> workList = result as List<dynamic>;
      
      return workList.map((work) => WorkInfo.fromMap(Map<String, dynamic>.from(work))).toList();
    } on PlatformException catch (e) {
      throw WorkManagerException('Failed to get active works: ${e.message}');
    }
  }

  /// Get detailed status of all background tasks
  Future<List<WorkStatus>> getAllWorkStatus() async {
    try {
      final result = await _channel.invokeMethod('getAllWorkStatus');
      final List<dynamic> statusList = result as List<dynamic>;
      
      return statusList.map((status) => WorkStatus.fromMap(Map<String, dynamic>.from(status))).toList();
    } on PlatformException catch (e) {
      throw WorkManagerException('Failed to get work status: ${e.message}');
    }
  }

  /// Cancel all background tasks
  Future<String?> cancelAllWork() async {
    try {
      final result = await _channel.invokeMethod('cancelAllWork');
      return result as String?;
    } on PlatformException catch (e) {
      throw WorkManagerException('Failed to cancel all work: ${e.message}');
    }
  }

  /// Check if notification permission is granted
  Future<bool> checkNotificationPermission() async {
    try {
      final result = await _channel.invokeMethod('checkNotificationPermission');
      return result as bool;
    } on PlatformException catch (e) {
      throw WorkManagerException('Failed to check notification permission: ${e.message}');
    }
  }

  /// Request notification permission
  Future<String?> requestNotificationPermission() async {
    try {
      final result = await _channel.invokeMethod('requestNotificationPermission');
      return result as String?;
    } on PlatformException catch (e) {
      throw WorkManagerException('Failed to request notification permission: ${e.message}');
    }
  }

  /// Send a test notification
  Future<String?> sendTestNotification() async {
    try {
      final result = await _channel.invokeMethod('sendTestNotification');
      return result as String?;
    } on PlatformException catch (e) {
      throw WorkManagerException('Failed to send test notification: ${e.message}');
    }
  }
}

class WorkInfo {
  final String id;
  final String state;
  final List<String> tags;
  final int runAttemptCount;
  final Map<String, dynamic> outputData;
  final int nextScheduleTimeMillis;

  WorkInfo({
    required this.id,
    required this.state,
    required this.tags,
    required this.runAttemptCount,
    required this.outputData,
    required this.nextScheduleTimeMillis,
  });

  factory WorkInfo.fromMap(Map<String, dynamic> map) {
    return WorkInfo(
      id: map['id'] as String,
      state: map['state'] as String,
      tags: List<String>.from(map['tags'] as List),
      runAttemptCount: map['runAttemptCount'] as int,
      outputData: Map<String, dynamic>.from(map['outputData'] as Map),
      nextScheduleTimeMillis: map['nextScheduleTimeMillis'] as int,
    );
  }

  bool get isRunning => state == 'RUNNING';
  bool get isEnqueued => state == 'ENQUEUED';
  bool get isSucceeded => state == 'SUCCEEDED';
  bool get isFailed => state == 'FAILED';
  bool get isCancelled => state == 'CANCELLED';
}

class WorkStatus {
  final String taskName;
  final String state;
  final String lastResult;
  final int lastRunTime;
  final int successCount;
  final int failureCount;
  final int runAttemptCount;
  final int nextScheduleTime;

  WorkStatus({
    required this.taskName,
    required this.state,
    required this.lastResult,
    required this.lastRunTime,
    required this.successCount,
    required this.failureCount,
    required this.runAttemptCount,
    required this.nextScheduleTime,
  });

  factory WorkStatus.fromMap(Map<String, dynamic> map) {
    return WorkStatus(
      taskName: map['taskName'] as String,
      state: map['state'] as String,
      lastResult: map['lastResult'] as String,
      lastRunTime: map['lastRunTime'] as int,
      successCount: map['successCount'] as int,
      failureCount: map['failureCount'] as int,
      runAttemptCount: map['runAttemptCount'] as int,
      nextScheduleTime: map['nextScheduleTime'] as int,
    );
  }

  DateTime? get lastRunDateTime {
    if (lastRunTime == 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(lastRunTime);
  }

  DateTime? get nextScheduleDateTime {
    if (nextScheduleTime == 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(nextScheduleTime);
  }

  bool get isRunning => state == 'RUNNING';
  bool get isActive => state == 'ENQUEUED' || state == 'RUNNING';
  double get successRate {
    final total = successCount + failureCount;
    if (total == 0) return 0.0;
    return successCount / total;
  }
}

class WorkManagerException implements Exception {
  final String message;
  
  WorkManagerException(this.message);
  
  @override
  String toString() => 'WorkManagerException: $message';
}
