package com.arinadi.arinanox

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Build
import android.os.PowerManager
import android.content.Context
import android.net.Uri
import android.provider.Settings
import android.content.Intent
import kotlin.concurrent.thread

/**
 * Main Flutter activity for arinanoX.
 *
 * ATM from DroidDesk's MainActivity. Heavily simplified:
 * - No chroot/root detection (proot-only)
 * - No DE installation or bootstrapping (handled by arinanoX scripts)
 * - No X11 compositor (Phase 1 — uses external Termux:X11 APK)
 * - Focus: command execution, device info, status checks
 */
class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.arinadi.arinanox/shell"
        private const val TAG = "ArinanoxMain"
    }

    private val shellExecutor = ShellExecutor()
    private val deviceInfo = DeviceInfoHelper()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    // ── Runtime Status ──
                    "getRuntimeStatus" -> {
                        thread {
                            try {
                                val isInstalled = shellExecutor.quickExec(
                                    "test -d \$HOME/.arinanox && echo YES || echo NO"
                                ).trim() == "YES"

                                val isRunning = shellExecutor.quickExec(
                                    "pgrep -f \"xfce4-session\" > /dev/null 2>&1 && echo YES || echo NO"
                                ).trim() == "YES"

                                val version = shellExecutor.quickExec(
                                    "cat \$HOME/.arinanox/VERSION 2>/dev/null"
                                ).trim().ifEmpty { "unknown" }

                                runOnUiThread {
                                    result.success(mapOf(
                                        "isInstalled" to isInstalled,
                                        "isRunning" to isRunning,
                                        "version" to version
                                    ))
                                }
                            } catch (e: Exception) {
                                runOnUiThread {
                                    result.success(mapOf(
                                        "isInstalled" to false,
                                        "isRunning" to false,
                                        "version" to "error"
                                    ))
                                }
                            }
                        }
                    }

                    // ── Device Info ──
                    "getDeviceInfo" -> {
                        result.success(mapOf(
                            "model" to Build.MODEL,
                            "brand" to Build.BRAND,
                            "androidVersion" to Build.VERSION.RELEASE,
                            "sdkVersion" to Build.VERSION.SDK_INT,
                            "cpuAbi" to (Build.SUPPORTED_ABIS.firstOrNull() ?: "unknown"),
                            "gpuVendor" to deviceInfo.getGpuVendor(),
                            "graphicsMode" to deviceInfo.getGraphicsMode(),
                            "totalRamMB" to deviceInfo.getTotalRam(this),
                            "availableStorageMB" to deviceInfo.getAvailableStorage(this)
                        ))
                    }

                    // ── Command Execution ──
                    "executeCommand" -> {
                        val command = call.argument<String>("command") ?: ""
                        Thread {
                            val output = shellExecutor.executeCommand(command) { chunk ->
                                android.os.Handler(android.os.Looper.getMainLooper()).post {
                                    flutterEngine.dartExecutor.binaryMessenger.let { messenger ->
                                        MethodChannel(messenger, CHANNEL).invokeMethod(
                                            "onTerminalOutput",
                                            mapOf("text" to chunk)
                                        )
                                    }
                                }
                            }
                            android.os.Handler(android.os.Looper.getMainLooper()).post {
                                result.success(output)
                            }
                        }.start()
                    }

                    "interruptCommand" -> {
                        shellExecutor.interruptCommand()
                        result.success(true)
                    }

                    // ── Battery Optimization ──
                    "requestBatteryOptimization" -> {
                        requestIgnoreBatteryOptimization()
                        result.success(true)
                    }

                    "isBatteryOptimized" -> {
                        result.success(isBatteryOptimized())
                    }

                    else -> result.notImplemented()
                }
            }
    }

    // ── Battery Optimization ──

    private fun isBatteryOptimized(): Boolean {
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        return !pm.isIgnoringBatteryOptimizations(packageName)
    }

    private fun requestIgnoreBatteryOptimization() {
        if (isBatteryOptimized()) {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:$packageName")
            }
            startActivity(intent)
        }
    }
}
