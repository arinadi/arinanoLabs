package com.arinadi.arinanox

import android.content.Context
import android.os.Build
import java.io.File
import java.io.PrintWriter
import java.io.StringWriter
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Global uncaught exception handler.
 *
 * Writes crash logs to a file accessible without ADB:
 *   /sdcard/Android/data/com.arinadi.arinanox/files/crash.log
 *   /sdcard/arinanox-crash.log (fallback, needs storage permission on API < 29)
 *
 * Also dumps device info to help remote diagnosis.
 */
object CrashHandler : Thread.UncaughtExceptionHandler {

    private var originalHandler: Thread.UncaughtExceptionHandler? = null
    private var appContext: Context? = null
    private val dateFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS", Locale.US)

    fun install(context: Context) {
        if (Thread.getDefaultUncaughtExceptionHandler() is CrashHandler) return
        appContext = context.applicationContext
        originalHandler = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler(this)
    }

    override fun uncaughtException(thread: Thread, throwable: Throwable) {
        writeCrashLog(thread, throwable)

        // Forward to original handler (shows system crash dialog or just kills)
        originalHandler?.uncaughtException(thread, throwable)
            ?: Runtime.getRuntime().exit(1)
    }

    private fun writeCrashLog(thread: Thread, throwable: Throwable) {
        try {
            val ctx = appContext ?: return
            val timestamp = dateFormat.format(Date())

            val sw = StringWriter()
            throwable.printStackTrace(PrintWriter(sw))

            val log = buildString {
                appendLine("=== arinanoX Crash Report ===")
                appendLine("Time: $timestamp")
                appendLine("Thread: ${thread.name} (id=${thread.id})")
                appendLine()
                appendLine("=== Stack Trace ===")
                appendLine(sw.toString())
                appendLine()
                appendLine("=== Device Info ===")
                appendLine("Model: ${Build.MODEL}")
                appendLine("Brand: ${Build.BRAND}")
                appendLine("Android: ${Build.VERSION.RELEASE} (SDK ${Build.VERSION.SDK_INT})")
                appendLine("ABIs: ${Build.SUPPORTED_ABIS.joinToString()}")
                appendLine("App Version: ${getAppVersion(ctx)}")
                appendLine()
                appendLine("=== Causes (recursive) ===")
                var cause = throwable.cause
                var depth = 0
                while (cause != null && depth < 5) {
                    appendLine("Cause #${++depth}: ${cause.javaClass.name}: ${cause.message}")
                    cause.printStackTrace(PrintWriter(sw))
                    cause = cause.cause
                }
                appendLine("=== End ===")
            }

            // Primary: app external files (no permission needed)
            val primaryFile = File(ctx.getExternalFilesDir(null), "crash.log")
            primaryFile.parentFile?.mkdirs()
            primaryFile.writeText(log)

            // Fallback: /sdcard root for easy access (may fail on API 29+)
            try {
                val fallback = File("/sdcard/arinanox-crash.log")
                fallback.writeText(log)
            } catch (_: Exception) {
                // Scoped storage — primary file is enough
            }

        } catch (_: Exception) {
            // Don't crash the crash handler
        }
    }

    private fun getAppVersion(context: Context): String {
        return try {
            val pkgInfo = context.packageManager.getPackageInfo(context.packageName, 0)
            "${pkgInfo.versionName} (code ${pkgInfo.versionCode})"
        } catch (_: Exception) {
            "unknown"
        }
    }
}
