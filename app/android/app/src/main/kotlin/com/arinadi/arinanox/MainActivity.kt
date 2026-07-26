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
import android.util.Log
import kotlin.concurrent.thread
import java.io.File
import java.net.HttpURLConnection
import java.net.URL

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

                    // ── Script Update ──
                    "updateScripts" -> {
                        thread {
                            val ok = updateScriptsFromGitHub()
                            runOnUiThread { result.success(ok) }
                        }
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

    // ── Script Update (bash scripts from GitHub raw) ──

    private val SCRIPTS_BASE = "https://raw.githubusercontent.com/arinadi/arinanoX/main"

    private val SCRIPT_FILES = listOf(
        "host-setup.sh", "proot-setup.sh", "api-bridge-setup.sh", "xfce-config.sh",
        "launcher-gen.sh", "motd-setup.sh", "patch.sh",
        "seccomp-check.sh", "seccomp-fix.sh", "doctor.sh",
        "manifest-generate.sh", "manifest-apply.sh", "user-snapshot.sh",
        "status.sh", "arinanox"
    )

    private val LAUNCHER_FILES = listOf(
        "start.sh", "stop.sh"
    )

    /**
     * Download latest scripts + launchers from GitHub raw.
     * Streams progress to Flutter via onTerminalOutput callback.
     */
    private fun updateScriptsFromGitHub(): Boolean {
        return try {
            val channel = MethodChannel(
                flutterEngine!!.dartExecutor.binaryMessenger,
                CHANNEL
            )
            val handler = android.os.Handler(android.os.Looper.getMainLooper())

            fun log(msg: String) {
                handler.post {
                    channel.invokeMethod("onTerminalOutput", mapOf("text" to msg))
                }
            }

            val scriptsDir = java.io.File(
                android.os.Environment.getExternalStorageDirectory(),
                "arinanox-scripts"
            )
            // Use Termux home: /data/data/com.termux/files/home/.arinanox/scripts
            val homeScripts = java.io.File("/data/data/com.termux/files/home/.arinanox/scripts")
            val homeLaunchers = java.io.File("/data/data/com.termux/files/home/.arinanox/launchers")
            homeScripts.mkdirs()
            homeLaunchers.mkdirs()

            log(">>> Updating scripts from GitHub...\n")

            // Download scripts
            for (file in SCRIPT_FILES) {
                val url = URL("$SCRIPTS_BASE/scripts/$file")
                val dest = java.io.File(homeScripts, file)
                try {
                    val conn = url.openConnection() as java.net.HttpURLConnection
                    conn.connectTimeout = 10_000
                    conn.readTimeout = 10_000
                    if (conn.responseCode == 200) {
                        dest.outputStream().use { out ->
                            conn.inputStream.copyTo(out)
                        }
                        dest.setExecutable(true)
                        log("  ✓ $file\n")
                    } else {
                        log("  ✗ $file (HTTP ${conn.responseCode})\n")
                    }
                    conn.disconnect()
                } catch (e: Exception) {
                    log("  ✗ $file: ${e.message}\n")
                }
            }

            // Download launchers
            for (file in LAUNCHER_FILES) {
                val url = URL("$SCRIPTS_BASE/launchers/$file")
                val dest = java.io.File(homeLaunchers, file)
                try {
                    val conn = url.openConnection() as java.net.HttpURLConnection
                    conn.connectTimeout = 10_000
                    conn.readTimeout = 10_000
                    if (conn.responseCode == 200) {
                        dest.outputStream().use { out ->
                            conn.inputStream.copyTo(out)
                        }
                        dest.setExecutable(true)
                        log("  ✓ $file\n")
                    }
                    conn.disconnect()
                } catch (e: Exception) {
                    log("  ✗ $file: ${e.message}\n")
                }
            }

            log(">>> Done.\n")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Script update failed", e)
            false
        }
    }
}
