package com.example.ssh_client.plugins

import android.content.Context
import androidx.annotation.NonNull
import androidx.work.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.TimeUnit

class WorkManagerPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel : MethodChannel
    private lateinit var context: Context

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

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
