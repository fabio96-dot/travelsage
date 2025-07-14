plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics") version "2.9.9"
}

android {
    namespace = "com.example.travel_sage" // Deve matchare con AndroidManifest.xml
    compileSdk = 34 // Usa valore fisso invece di flutter.compileSdkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.travel_sage" // Deve matchare con Firebase
        minSdk = 21 // Android 5.0 (Lollipop)
        targetSdk = 34
        versionCode = 1 // Valori fissi invece di flutter.versionCode
        versionName = "1.0.0" // Valori fissi invece di flutter.versionName
        multiDexEnabled = true // Richiesto per alcuni plugin Firebase
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            isDebuggable = true
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:32.8.1")) // Versione più recente
    implementation("com.google.firebase:firebase-analytics-ktx")
    implementation("com.google.firebase:firebase-auth-ktx")
    implementation("com.google.firebase:firebase-firestore-ktx")
    implementation("androidx.multidex:multidex:2.0.1") // Necessario per minSdk < 21
}