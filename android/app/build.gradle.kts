plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // MUST match the live app id
    namespace = "com.funasianetwork.radiosangam"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // If you hit a JDK 17 requirement later, change both to JavaVersion.VERSION_17
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // MUST match the live app id
        applicationId = "com.funasianetwork.radiosangam_flutter"

        // Keep Flutter defaults unless we need to raise them later
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        // Bump above your last Play Store versionCode (Expo used 5)
        versionCode = 6            // <-- increment this for every Play update
        versionName = "1.0.4"      // <-- human-readable version
    }

    signingConfigs {
        // We'll point this at your existing RN keystore before release
        // (leave as debug for now so flutter run --release works)
        // create("release") {
        //     storeFile = file("../keystore/radiosangam.keystore")
        //     storePassword = System.getenv("KEYSTORE_PASSWORD") ?: ""
        //     keyAlias = System.getenv("KEY_ALIAS") ?: "radiosangam"
        //     keyPassword = System.getenv("KEY_PASSWORD") ?: ""
        // }
    }

    buildTypes {
        release {
            // TEMP: debug signing so you can run release locally.
            // For Play Store, we will switch to signingConfigs.release.
            signingConfig = signingConfigs.getByName("debug")
            // isMinifyEnabled = false
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        debug {
            // nothing special
        }
    }
}

flutter {
    source = "../.."
}
