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
            val keystorePath = System.getenv("ARINANOX_KEYSTORE_PATH")
            val keystorePass = System.getenv("ARINANOX_KEYSTORE_PASS")
            val keyAlias = System.getenv("ARINANOX_KEY_ALIAS")
            val keyPass = System.getenv("ARINANOX_KEY_PASS")

            signingConfig = if (keystorePath != null && keystorePass != null) {
                signingConfigs.create("release") {
                    storeFile = file(keystorePath)
                    storePassword = keystorePass
                    keyAlias = keyAlias ?: "arinanox"
                    keyPassword = keyPass ?: keystorePass
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
