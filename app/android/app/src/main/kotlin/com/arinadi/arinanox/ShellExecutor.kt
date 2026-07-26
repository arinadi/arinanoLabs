package com.arinadi.arinanox

import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader

/**
 * Shell command executor — runs commands in Termux environment.
 *
 * Uses Termux bash (not Android system sh) with proper PATH and HOME.
 * This ensures curl, proot-distro, and all arinanox scripts work correctly.
 */
class ShellExecutor {

    companion object {
        private val TERMUX_HOME = "/data/data/com.termux/files/home"
        private val TERMUX_PREFIX = "/data/data/com.termux/files/usr"
        private val TERMUX_BASH = "$TERMUX_PREFIX/bin/bash"

        private val ENV = mapOf(
            "HOME" to TERMUX_HOME,
            "PREFIX" to TERMUX_PREFIX,
            "PATH" to "$TERMUX_PREFIX/bin:$TERMUX_PREFIX/bin/applets:/system/bin:/system/xbin",
            "LD_LIBRARY_PATH" to "$TERMUX_PREFIX/lib",
            "TMPDIR" to "$TERMUX_PREFIX/tmp",
            "LANG" to "en_US.UTF-8",
        )
    }

    private var currentProcess: Process? = null

    /**
     * Execute a command in Termux bash and return full output.
     * [onOutput] callback receives each line as it arrives.
     */
    fun executeCommand(command: String, onOutput: ((String) -> Unit)? = null): String {
        val envp = ENV.map { (k, v) -> "$k=$v" }.toTypedArray()
        val workDir = File(TERMUX_HOME)

        val process = Runtime.getRuntime().exec(
            arrayOf(TERMUX_BASH, "-c", command),
            envp,
            workDir
        )
        currentProcess = process

        val stdout = StringBuilder()
        val reader = BufferedReader(InputStreamReader(process.inputStream))
        val errReader = BufferedReader(InputStreamReader(process.errorStream))

        var line: String?
        while (reader.readLine().also { line = it } != null) {
            stdout.appendLine(line)
            onOutput?.invoke(line!! + "\n")
        }

        val stderr = StringBuilder()
        while (errReader.readLine().also { line = it } != null) {
            stderr.appendLine(line)
            onOutput?.invoke(line!! + "\n")
        }

        process.waitFor()
        currentProcess = null

        return stdout.toString().ifEmpty { stderr.toString() }
    }

    /**
     * Quick synchronous command for status checks.
     * No streaming, returns full output directly.
     */
    fun quickExec(command: String): String {
        return try {
            val envp = ENV.map { (k, v) -> "$k=$v" }.toTypedArray()
            val workDir = File(TERMUX_HOME)
            val process = Runtime.getRuntime().exec(
                arrayOf(TERMUX_BASH, "-c", command),
                envp,
                workDir
            )
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            val output = reader.readText()
            process.waitFor()
            output
        } catch (e: Exception) {
            ""
        }
    }

    /**
     * Send SIGINT to currently running command.
     *
     * Uses reflection to access the private pid field because
     * Android's java.lang.Process lacks the Java 9+ pid() method.
     */
    fun interruptCommand() {
        currentProcess?.let { process ->
            try {
                val pidField = process.javaClass.getDeclaredField("pid")
                pidField.isAccessible = true
                val pid = pidField.getInt(process)
                Runtime.getRuntime().exec(arrayOf("kill", "-2", pid.toString()))
            } catch (_: Exception) {
                // Process may have already completed
            }
        }
    }
}
