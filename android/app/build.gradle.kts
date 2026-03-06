import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// ✅ Load keystore from local.properties
val keystoreProperties = Properties().apply {
    val keystoreFile = rootProject.file("key.properties")
    if (keystoreFile.exists()) {
        load(keystoreFile.inputStream())
    }
}

android {
    namespace = "com.mk.pz"
    compileSdk = 36
    ndkVersion = "28.0.12674087"

  packaging {
    resources {
        excludes += setOf(
            "AndroidManifest.xml",
            "R.txt",
            "**/R.txt",
            "proguard.txt",
            "**/proguard.txt"
        )
    }

    jniLibs {
        excludes += setOf(
            "**/armeabi-v7a/**",
            "**/x86/**",
            "**/x86_64/**"
        )
    }
}

    defaultConfig {
        applicationId = "com.mk.pz"
        minSdk = 29
        targetSdk = 36
        versionCode = 5
        versionName = "1.1"

    ndk {
    abiFilters.clear()
    abiFilters.add("arm64-v8a")
}
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }
    signingConfigs {
    create("release") {
        storeFile = file(keystoreProperties["KEYSTORE_PATH"]?.toString())
        storePassword = keystoreProperties["KEYSTORE_PASSWORD"]?.toString()
        keyAlias = keystoreProperties["KEY_ALIAS"]?.toString()
        keyPassword = keystoreProperties["KEY_PASSWORD"]?.toString()
    }
}
    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                file("proguard-rules.pro")
            )
            signingConfig = signingConfigs.getByName("release")
        }
    }

}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
        implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("androidx.health.connect:connect-client:1.1.0-alpha06")

}
flutter {
    source = "../.."
}
