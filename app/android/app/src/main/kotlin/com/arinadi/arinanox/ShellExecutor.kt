package com.arinadi.arinanox

import java.io.BufferedReader
import java.io.InputStreamReader

/**
 * Simple shell command executor with streaming output support.
 *
 * ATM from DroidDesk's LinuxRuntime.executeCommand pattern.
 * Simplified: proot-only, no chroot prefixes needed.
 */
class ShellExecutor {

    private var currentProcess: Process? = null

    /**
     * Execute a command and return full output.
     * [onOutput] callback receives each line as it arrives.
     */
    fun executeCommand(command: String, onOutput: ((String) -> Unit)? = null): String {
        val process = Runtime.getRuntime().exec(
            arrayOf("sh", "-c", command),
            null,
            null // workDir defaults to app home = Termux home
        )
        currentProcess = process

        val stdout = StringBuilder()
        val reader = BufferedReader(InputStreamReader(process.inputStream))
        val errReader = BufferedReader(InputStreamReader(process.errorStream))

        // Read stdout line by line, stream to callback
        var line: String?
        while (reader.readLine().also { line = it } != null) {
            stdout.appendLine(line)
            onOutput?.invoke(line!! + "\n")
        }

        // Read stderr
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
            val process = Runtime.getRuntime().exec(
                arrayOf("sh", "-c", command)
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
     */
    fun interruptCommand() {
        currentProcess?.let { process ->
            try {
                // Send Ctrl+C via signal
                Runtime.getRuntime().exec(arrayOf("kill", "-2", process.pid().toString()))
            } catch (_: Exception) {
                // Process may have already completed
            }
        }
    }
}
