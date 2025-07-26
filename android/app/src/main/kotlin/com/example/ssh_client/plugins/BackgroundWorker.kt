package com.example.ssh_client.plugins

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.work.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.*

class BackgroundWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {

    companion object {
        private const val TAG = "BackgroundWorker"
        private const val NOTIFICATION_CHANNEL_ID = "SSH_CLIENT_WORK_CHANNEL"
        private const val NOTIFICATION_CHANNEL_NAME = "SSH Client Background Tasks"
    }

    override suspend fun doWork(): Result {
        val taskName = inputData.getString("taskName") ?: "Unknown Task"
        val taskType = inputData.getString("taskType") ?: "ping"
        
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Starting background work: $taskName")
                
                // Create notification channel if needed
                createNotificationChannel()
                
                // Execute the task based on type
                val taskResult = when (taskType) {
                    "ping" -> performPingTask()
                    "ssh_check" -> performSSHCheck()
                    "system_monitor" -> performSystemMonitor()
                    "file_sync" -> performFileSync()
                    else -> performDefaultTask()
                }
                
                // Update counters
                val previousSuccess = inputData.getInt("successCount", 0)
                val previousFailure = inputData.getInt("failureCount", 0)
                
                val outputData = if (taskResult.success) {
                    workDataOf(
                        "lastResult" to "SUCCESS: ${taskResult.message}",
                        "lastRunTime" to System.currentTimeMillis(),
                        "successCount" to (previousSuccess + 1),
                        "failureCount" to previousFailure,
                        "taskName" to taskName
                    )
                } else {
                    workDataOf(
                        "lastResult" to "FAILED: ${taskResult.message}",
                        "lastRunTime" to System.currentTimeMillis(),
                        "successCount" to previousSuccess,
                        "failureCount" to (previousFailure + 1),
                        "taskName" to taskName
                    )
                }
                
                // Send notification
                sendNotification(taskName, taskResult.success, taskResult.message)
                
                Log.d(TAG, "Background work completed: $taskName - ${if (taskResult.success) "SUCCESS" else "FAILED"}")
                
                Result.success(outputData)
                
            } catch (e: Exception) {
                Log.e(TAG, "Background work failed: $taskName", e)
                
                val outputData = workDataOf(
                    "lastResult" to "ERROR: ${e.message}",
                    "lastRunTime" to System.currentTimeMillis(),
                    "successCount" to inputData.getInt("successCount", 0),
                    "failureCount" to (inputData.getInt("failureCount", 0) + 1),
                    "taskName" to taskName
                )
                
                sendNotification(taskName, false, "Error: ${e.message}")
                
                Result.success(outputData) // Return success to keep the periodic work running
            }
        }
    }

    private fun performPingTask(): TaskResult {
        return try {
            val url = URL("https://www.google.com")
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "HEAD"
            connection.connectTimeout = 5000
            connection.readTimeout = 5000
            
            val responseCode = connection.responseCode
            connection.disconnect()
            
            if (responseCode == 200) {
                TaskResult(true, "Ping successful (${responseCode})")
            } else {
                TaskResult(false, "Ping failed with code: $responseCode")
            }
        } catch (e: Exception) {
            TaskResult(false, "Ping failed: ${e.message}")
        }
    }

    private fun performSSHCheck(): TaskResult {
        // Simulate SSH connection check
        return try {
            // This is a mock implementation - you can integrate with your SSH service
            Thread.sleep(2000) // Simulate network call
            val random = Random()
            val success = random.nextBoolean()
            
            if (success) {
                TaskResult(true, "SSH connection check passed")
            } else {
                TaskResult(false, "SSH connection unavailable")
            }
        } catch (e: Exception) {
            TaskResult(false, "SSH check error: ${e.message}")
        }
    }

    private fun performSystemMonitor(): TaskResult {
        return try {
            // Get system information
            val runtime = Runtime.getRuntime()
            val maxMemory = runtime.maxMemory() / (1024 * 1024) // MB
            val totalMemory = runtime.totalMemory() / (1024 * 1024) // MB
            val freeMemory = runtime.freeMemory() / (1024 * 1024) // MB
            val usedMemory = totalMemory - freeMemory
            
            TaskResult(true, "Memory: ${usedMemory}MB used of ${maxMemory}MB max")
        } catch (e: Exception) {
            TaskResult(false, "System monitor error: ${e.message}")
        }
    }

    private fun performFileSync(): TaskResult {
        return try {
            // Simulate file sync operation
            Thread.sleep(1000)
            val filesProcessed = Random().nextInt(10) + 1
            TaskResult(true, "Synced $filesProcessed files")
        } catch (e: Exception) {
            TaskResult(false, "File sync error: ${e.message}")
        }
    }

    private fun performDefaultTask(): TaskResult {
        return try {
            val timestamp = SimpleDateFormat("HH:mm:ss", Locale.getDefault()).format(Date())
            TaskResult(true, "Default task completed at $timestamp")
        } catch (e: Exception) {
            TaskResult(false, "Default task error: ${e.message}")
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                NOTIFICATION_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notifications for SSH Client background tasks"
                enableLights(false)
                enableVibration(false)
            }

            val notificationManager = applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun sendNotification(taskName: String, success: Boolean, message: String) {
        val notificationManager = applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        val timestamp = SimpleDateFormat("HH:mm:ss", Locale.getDefault()).format(Date())
        val title = if (success) "✅ $taskName" else "❌ $taskName"
        val content = "$message at $timestamp"
        
        val notification = NotificationCompat.Builder(applicationContext, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(content)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setAutoCancel(true)
            .build()

        // Use a unique notification ID based on task name
        val notificationId = taskName.hashCode()
        notificationManager.notify(notificationId, notification)
    }

    data class TaskResult(val success: Boolean, val message: String)
}
