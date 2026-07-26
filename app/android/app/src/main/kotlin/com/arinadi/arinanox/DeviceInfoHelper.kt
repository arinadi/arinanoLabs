package com.arinadi.arinanox

import android.content.Context
import android.os.Build

/**
 * Gathers device hardware information for display in the dashboard.
 *
 * ATM from DroidDesk's MainActivity.getGpuVendor/getTotalRam/getAvailableStorage.
 */
class DeviceInfoHelper {

    fun getGpuVendor(): String {
        return try {
            val prop = Runtime.getRuntime().exec(arrayOf("getprop", "ro.hardware.egl"))
            val result = prop.inputStream.bufferedReader().readText().trim()
            prop.waitFor()
            if (result.isNotEmpty()) result else "unknown"
        } catch (e: Exception) {
            "unknown"
        }
    }

    fun getGraphicsMode(): String {
        // Check for virglrenderer GPU acceleration tier
        val adrenoPath = "/data/data/com.termux/files/usr/opt/virglrenderer-mesa-android"
        val anglePath = "/data/data/com.termux/files/usr/opt/angle-android"
        return when {
            // Adreno direct path
            Build.HARDWARE?.contains("adreno", true) == true -> "virgl (adreno)"
            // ANGLE path (Vulkan-backed)
            java.io.File(anglePath).exists() -> "virgl (angle-vulkan)"
            // Software fallback
            else -> "virgl (llvmpipe)"
        }
    }

    fun getTotalRam(context: Context): Long {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
        val memInfo = android.app.ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memInfo)
        return memInfo.totalMem / (1024 * 1024)
    }

    fun getAvailableStorage(context: Context): Long {
        val stat = android.os.StatFs(context.filesDir.absolutePath)
        return stat.availableBytes / (1024 * 1024)
    }
}
