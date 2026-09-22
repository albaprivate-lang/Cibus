plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.cibus.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = JavaVersion.VERSION_17.toString() }

    defaultConfig {
        applicationId = "com.cibus.app"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Firma de depuración solo para permitir el APK de prueba de la primera versión.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter { source = "../.." }
