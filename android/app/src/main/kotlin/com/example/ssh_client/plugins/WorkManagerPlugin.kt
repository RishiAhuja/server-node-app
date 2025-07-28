package com.example.ssh_client.plugins

import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.work.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.util.concurrent.TimeUnit

class WorkManagerPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
    private lateinit var channel : MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null
    private var pendingResult: Result? = null
    private val PERMISSION_REQUEST_CODE = 1001

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "work_manager_plugin")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "startPeriodicWork" -> {
                val taskName = call.argument<String>("taskName") ?: "default_task"
                val intervalSeconds = call.argument<Int>("intervalSeconds") ?: 20
                val taskType = call.argument<String>("taskType") ?: "ping"
                startPeriodicWork(taskName, intervalSeconds, taskType)
                result.success("Work started: $taskName")
            }
            "stopWork" -> {
                val taskName = call.argument<String>("taskName") ?: "default_task"
                stopWork(taskName)
                result.success("Work stopped: $taskName")
            }
            "getActiveWorks" -> {
                getActiveWorks(result)
            }
            "getAllWorkStatus" -> {
                getAllWorkStatus(result)
            }
            "cancelAllWork" -> {
                cancelAllWork()
                result.success("All work cancelled")
            }
            "checkNotificationPermission" -> {
                checkNotificationPermission(result)
            }
            "requestNotificationPermission" -> {
                requestNotificationPermission(result)
            }
            "sendTestNotification" -> {
                sendTestNotification(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun startPeriodicWork(taskName: String, intervalSeconds: Int, taskType: String) {
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.NOT_REQUIRED)
            .setRequiresBatteryNotLow(false)
            .setRequiresCharging(false)
            .setRequiresDeviceIdle(false)
            .setRequiresStorageNotLow(false)
            .build()

        val inputData = workDataOf(
            "taskName" to taskName,
            "taskType" to taskType
        )

        val workRequest = PeriodicWorkRequestBuilder<BackgroundWorker>(
            intervalSeconds.toLong(), TimeUnit.SECONDS,
            5, TimeUnit.SECONDS // flex interval
        )
            .setConstraints(constraints)
            .setInputData(inputData)
            .addTag(taskName)
            .addTag("active_work")
            .build()

        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            taskName,
            ExistingPeriodicWorkPolicy.REPLACE,
            workRequest
        )
    }

    private fun stopWork(taskName: String) {
        WorkManager.getInstance(context).cancelUniqueWork(taskName)
    }

    private fun getActiveWorks(result: Result) {
        val workManager = WorkManager.getInstance(context)
        val workInfos = workManager.getWorkInfosByTag("active_work")
        
        try {
            val workInfoList = workInfos.get()
            val activeWorks = workInfoList.map { workInfo ->
                mapOf(
                    "id" to workInfo.id.toString(),
                    "state" to workInfo.state.name,
                    "tags" to workInfo.tags.filter { it != "active_work" },
                    "runAttemptCount" to workInfo.runAttemptCount,
                    "outputData" to workInfo.outputData.keyValueMap,
                    "nextScheduleTimeMillis" to 0L // Default value since this property may not be available
                )
            }
            result.success(activeWorks)
        } catch (e: Exception) {
            result.error("GET_WORKS_ERROR", "Failed to get active works: ${e.message}", null)
        }
    }

    private fun getAllWorkStatus(result: Result) {
        val workManager = WorkManager.getInstance(context)
        val workInfos = workManager.getWorkInfosByTag("active_work")
        
        try {
            val workInfoList = workInfos.get()
            val workStatus = workInfoList.map { workInfo ->
                val taskName = workInfo.tags.firstOrNull { it != "active_work" } ?: "unknown"
                val lastResult = workInfo.outputData.getString("lastResult") ?: "Not started"
                val lastRunTime = workInfo.outputData.getLong("lastRunTime", 0L)
                val successCount = workInfo.outputData.getInt("successCount", 0)
                val failureCount = workInfo.outputData.getInt("failureCount", 0)
                
                mapOf(
                    "taskName" to taskName,
                    "state" to workInfo.state.name,
                    "lastResult" to lastResult,
                    "lastRunTime" to lastRunTime,
                    "successCount" to successCount,
                    "failureCount" to failureCount,
                    "runAttemptCount" to workInfo.runAttemptCount,
                    "nextScheduleTime" to 0L // Default value since this property may not be available
                )
            }
            result.success(workStatus)
        } catch (e: Exception) {
            result.error("GET_STATUS_ERROR", "Failed to get work status: ${e.message}", null)
        }
    }

    private fun cancelAllWork() {
        WorkManager.getInstance(context).cancelAllWorkByTag("active_work")
    }

    private fun checkNotificationPermission(result: Result) {
        try {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val areEnabled = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                notificationManager.areNotificationsEnabled()
            } else {
                true // Pre-N devices don't have this restriction
            }
            result.success(areEnabled)
        } catch (e: Exception) {
            result.error("PERMISSION_CHECK_ERROR", "Failed to check notification permission: ${e.message}", null)
        }
    }

    private fun requestNotificationPermission(result: Result) {
        try {
            // On Android 13+ (API 33), notification permission is required
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                if (activity == null) {
                    result.error("NO_ACTIVITY", "Activity not available for permission request", null)
                    return
                }

                val permission = android.Manifest.permission.POST_NOTIFICATIONS
                if (ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED) {
                    result.success("Permission already granted")
                } else {
                    pendingResult = result
                    ActivityCompat.requestPermissions(activity!!, arrayOf(permission), PERMISSION_REQUEST_CODE)
                }
            } else {
                // For older versions, check if notifications are enabled in settings
                val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    val areEnabled = notificationManager.areNotificationsEnabled()
                    if (!areEnabled) {
                        result.success("Please enable notifications in device settings for this app")
                    } else {
                        result.success("Notifications are already enabled")
                    }
                } else {
                    result.success("Notifications are supported")
                }
            }
        } catch (e: Exception) {
            result.error("PERMISSION_REQUEST_ERROR", "Failed to handle notification permission: ${e.message}", null)
        }
    }

    private fun sendTestNotification(result: Result) {
        try {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            
            // Create notification channel
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    "SSH_CLIENT_WORK_CHANNEL",
                    "SSH Client Background Tasks",
                    NotificationManager.IMPORTANCE_DEFAULT
                ).apply {
                    description = "Test notification channel"
                    enableLights(true)
                    enableVibration(true)
                }
                notificationManager.createNotificationChannel(channel)
            }
            
            val notification = androidx.core.app.NotificationCompat.Builder(context, "SSH_CLIENT_WORK_CHANNEL")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle("SSH Client Test")
                .setContentText("Test notification from WorkManager plugin")
                .setPriority(androidx.core.app.NotificationCompat.PRIORITY_DEFAULT)
                .setAutoCancel(true)
                .setDefaults(androidx.core.app.NotificationCompat.DEFAULT_ALL)
                .build()
            
            notificationManager.notify(9999, notification)
            result.success("Test notification sent")
        } catch (e: Exception) {
            result.error("TEST_NOTIFICATION_ERROR", "Failed to send test notification: ${e.message}", null)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode == PERMISSION_REQUEST_CODE) {
            pendingResult?.let { result ->
                if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    result.success("Permission granted")
                } else {
                    result.success("Permission denied")
                }
                pendingResult = null
            }
            return true
        }
        return false
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        activity = null
        pendingResult = null
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
