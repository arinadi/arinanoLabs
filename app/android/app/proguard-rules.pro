# ProGuard rules for arinanoX

# Flutter
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**

# Kotlin
-keep class kotlin.** { *; }
-dontwarn kotlin.**

# Keep MethodChannel names
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
