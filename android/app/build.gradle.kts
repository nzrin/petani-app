import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

require(keystorePropertiesFile.exists()) {
    "Missing android/key.properties at ${keystorePropertiesFile.absolutePath}"
}

FileInputStream(keystorePropertiesFile).use { input ->
    keystoreProperties.load(input)
}

val appVersionFile = rootProject.file("../app_version.xcconfig")
require(appVersionFile.exists()) {
    "Missing app_version.xcconfig at ${appVersionFile.absolutePath}"
}

val appVersionConfig = appVersionFile
    .readLines()
    .map { it.substringBefore("//").trim() }
    .filter { it.isNotEmpty() && it.contains("=") }
    .associate { line ->
        val parts = line.split("=", limit = 2)
        parts[0].trim() to parts[1].trim()
    }

val appVersionName = requireNotNull(appVersionConfig["APP_VERSION"]) {
    "APP_VERSION is missing from app_version.xcconfig"
}
val appVersionCode = requireNotNull(appVersionConfig["APP_BUILD"]) {
    "APP_BUILD is missing from app_version.xcconfig"
}.toIntOrNull() ?: error("APP_BUILD must be a positive integer")

require(appVersionCode > 0) {
    "APP_BUILD must be a positive integer"
}

android {
    namespace = "com.nazrinapp.petani"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.nazrinapp.petani"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = appVersionCode
        versionName = appVersionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
