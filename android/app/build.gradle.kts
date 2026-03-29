import org.gradle.api.JavaVersion

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.pascualbravo.pbshop"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.pascualbravo.pbshop"
        // En .kts se recomienda usar directamente los valores si flutter.targetSdk falla
        minSdk = flutter.minSdkVersion 
        targetSdk = flutter.targetSdkVersion // Nota el 'Version' al final
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        multiDexEnabled = true 
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17 // Cambia 1_8 por 17
        targetCompatibility = JavaVersion.VERSION_17 // Cambia 1_8 por 17
    }

    kotlinOptions {
        jvmTarget = "17" // Cambia "1.8" por "17"
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Nota los paréntesis, son obligatorios en .kts
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}
