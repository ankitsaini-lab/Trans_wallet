plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.trans.wallet"

    compileSdk = 36   // ✅ required by plugins

    ndkVersion = "29.0.13846066"

    defaultConfig {
        applicationId = "com.trans.wallet"
        minSdk = 29 // Required by DeepID Protect SDK
        targetSdk = 36

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ✅ Java 17 compatibility
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17

        // ⚠️ MUST be inside compileOptions
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("com.google.android.gms:play-services-auth:21.3.0")
}

flutter {
    source = "../.."
}