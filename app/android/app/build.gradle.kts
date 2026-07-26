plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.arinadi.arinanox"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.arinadi.arinanox"
        minSdk = 28
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ndk {
            abiFilters += listOf("arm64-v8a")
        }
    }

    buildTypes {
        release {
            // Use CI keystore if available (env vars), else fall back to debug
            val envKeystorePath = System.getenv("ARINANOX_KEYSTORE_PATH")
            val envKeystorePass = System.getenv("ARINANOX_KEYSTORE_PASS")
            val envKeyAlias = System.getenv("ARINANOX_KEY_ALIAS")
            val envKeyPass = System.getenv("ARINANOX_KEY_PASS")

            signingConfig = if (envKeystorePath != null && envKeystorePass != null) {
                signingConfigs.create("release") {
                    storeFile = file(envKeystorePath)
                    storePassword = envKeystorePass
                    keyAlias = envKeyAlias ?: "arinanox"
                    keyPassword = envKeyPass ?: envKeystorePass
                }
            } else {
                signingConfigs.getByName("debug")
            }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    lint {
        abortOnError = false
        checkReleaseBuilds = false
    }
}

flutter {
    source = "../.."
}
