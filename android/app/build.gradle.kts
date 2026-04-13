
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.pzplayer.co.pzplayer"
    // Usamos el SDK 35/36 según lo que Flutter detecte como compatible
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // Mantiene la salida del APK donde Flutter lo espera
    layout.buildDirectory.set(layout.projectDirectory.dir("../../build/app"))

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.pzplayer.co.pzplayer"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            // Firmando con debug para pruebas rápidas en tus dispositivos vivo
            signingConfig = signingConfigs.getByName("debug")

            // --- SOLUCIÓN AL ERROR DE R8 / MISSING CLASSES ---
            isMinifyEnabled = true
            isShrinkResources = true

            // Vinculamos el archivo .pro que creaste
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

// Configuración global de Java 17 para evitar errores de "Cannot find Java installation"
kotlin {
    jvmToolchain(17)
}

flutter {
    source = "../.."
}