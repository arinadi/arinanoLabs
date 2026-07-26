package com.arinadi.arinanox

import android.app.Application

/**
 * Custom Application class — installs crash handler early.
 */
class ArinanoxApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        CrashHandler.install(this)
    }
}
