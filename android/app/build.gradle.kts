import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.trans.wallet"

    compileSdk = 36   // ✅ required by plugins

    ndkVersion = "29.0.13846066"

    defaultConfig {
        applicationId = "com.trans.wallet"
        minSdk = flutter.minSdkVersion
        targetSdk = 36

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val isReleaseTask = gradle.startParameter.taskNames.any {
                it.contains("release", ignoreCase = true) ||
                it.contains("bundle", ignoreCase = true) ||
                it.contains("assemble", ignoreCase = true)
            }

            if (!keystorePropertiesFile.exists()) {
                if (isReleaseTask) {
                    throw GradleException("Release build failed: 'key.properties' file not found at ${keystorePropertiesFile.absolutePath}")
                }
            } else {
                val keyAliasProp = keystoreProperties.getProperty("keyAlias")
                val keyPasswordProp = keystoreProperties.getProperty("keyPassword")
                val storeFileProp = keystoreProperties.getProperty("storeFile")
                val storePasswordProp = keystoreProperties.getProperty("storePassword")

                if (keyAliasProp.isNullOrBlank()) {
                    throw GradleException("Release build failed: 'keyAlias' property is missing or blank in key.properties")
                }
                if (keyPasswordProp.isNullOrBlank()) {
                    throw GradleException("Release build failed: 'keyPassword' property is missing or blank in key.properties")
                }
                if (storePasswordProp.isNullOrBlank()) {
                    throw GradleException("Release build failed: 'storePassword' property is missing or blank in key.properties")
                }
                if (storeFileProp.isNullOrBlank()) {
                    throw GradleException("Release build failed: 'storeFile' property is missing or blank in key.properties")
                }

                val keystoreFile = file(storeFileProp)
                if (!keystoreFile.exists()) {
                    throw GradleException("Release build failed: Keystore file does not exist at ${keystoreFile.absolutePath}")
                }

                keyAlias = keyAliasProp
                keyPassword = keyPasswordProp
                storeFile = keystoreFile
                storePassword = storePasswordProp
            }
        }
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
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("com.google.android.gms:play-services-auth-api-phone:18.1.0")
}

flutter {
    source = "../.."
}