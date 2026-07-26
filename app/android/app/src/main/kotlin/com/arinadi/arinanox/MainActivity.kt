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
import androidx.core.content.FileProvider
import kotlin.concurrent.thread
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
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

                    // ── App Update ──
                    "checkAppUpdate" -> {
                        thread {
                            val info = checkGitHubRelease()
                            runOnUiThread { result.success(info) }
                        }
                    }

                    "installAppUpdate" -> {
                        val url = call.argument<String>("url") ?: ""
                        thread {
                            val ok = downloadAndInstallApk(url)
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

    // ── App Update (GitHub Releases) ──

    private val GITHUB_API = "https://api.github.com/repos/arinadi/arinanoX/releases/latest"
    private val GITHUB_REPO = "arinadi/arinanoX"

    /**
     * Hit GitHub Releases API, compare with current version.
     * Returns null if up-to-date, or map with version + downloadUrl.
     */
    private fun checkGitHubRelease(): Map<String, Any>? {
        return try {
            val url = URL(GITHUB_API)
            val conn = url.openConnection() as HttpURLConnection
            conn.setRequestProperty("Accept", "application/vnd.github+json")
            conn.setRequestProperty("X-GitHub-Api-Version", "2022-11-28")
            conn.connectTimeout = 10_000
            conn.readTimeout = 10_000

            if (conn.responseCode != 200) return null
            val body = conn.inputStream.bufferedReader().readText()
            conn.disconnect()

            val json = JSONObject(body)
            val tagName = json.getString("tag_name").removePrefix("v")
            val assets = json.getJSONArray("assets")

            // Find the APK asset
            var downloadUrl = ""
            var apkSize = 0L
            for (i in 0 until assets.length()) {
                val asset = assets.getJSONObject(i)
                val name = asset.getString("name")
                if (name.endsWith(".apk")) {
                    downloadUrl = asset.getString("browser_download_url")
                    apkSize = asset.getLong("size")
                    break
                }
            }
            if (downloadUrl.isEmpty()) return null

            // Compare versions (simple string compare — works for semver)
            val currentVersion = packageManager.getPackageInfo(packageName, 0).versionName ?: "0.0.0"
            if (tagName <= currentVersion) return null

            mapOf(
                "version" to tagName,
                "downloadUrl" to downloadUrl,
                "size" to apkSize
            )
        } catch (e: Exception) {
            Log.e(TAG, "GitHub release check failed", e)
            null
        }
    }

    /**
     * Download APK to cache dir, then open Android package installer.
     */
    private fun downloadAndInstallApk(downloadUrl: String): Boolean {
        return try {
            val file = File(cacheDir, "arinanox-update.apk")
            val url = URL(downloadUrl)
            val conn = url.openConnection() as HttpURLConnection
            conn.connectTimeout = 30_000
            conn.readTimeout = 60_000

            if (conn.responseCode != 200) return false
            val input = conn.inputStream
            val output = FileOutputStream(file)
            val buffer = ByteArray(8192)
            var bytesRead: Int
            var total = 0L
            while (input.read(buffer).also { bytesRead = it } != -1) {
                output.write(buffer, 0, bytesRead)
                total += bytesRead
            }
            output.close()
            input.close()
            conn.disconnect()

            // Open installer
            val apkUri = FileProvider.getUriForFile(
                this,
                "$packageName.fileprovider",
                file
            )
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(apkUri, "application/vnd.android.package-archive")
                flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
            true
        } catch (e: Exception) {
            Log.e(TAG, "APK download/install failed", e)
            false
        }
    }
}
