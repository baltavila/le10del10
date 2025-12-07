plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.le10del10"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.le10del10"
        // Aseguramos minSdk >= 21 (requisito de Facebook SDK)
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// Workaround: ensure Flutter can find APKs under project build dir
// Copies the generated APKs into `<project>/build/app/outputs/flutter-apk/`
val copyDebugApk by tasks.register<Copy>("copyDebugApk") {
    from("$buildDir/outputs/flutter-apk/app-debug.apk")
    into("${rootProject.projectDir}/../build/app/outputs/flutter-apk")
    doFirst {
        file("${rootProject.projectDir}/../build/app/outputs/flutter-apk").mkdirs()
    }
}

val copyReleaseApk by tasks.register<Copy>("copyReleaseApk") {
    from("$buildDir/outputs/flutter-apk/app-release.apk")
    into("${rootProject.projectDir}/../build/app/outputs/flutter-apk")
    doFirst {
        file("${rootProject.projectDir}/../build/app/outputs/flutter-apk").mkdirs()
    }
}

tasks.matching { it.name == "assembleDebug" }.configureEach {
    finalizedBy(copyDebugApk)
}

tasks.matching { it.name == "assembleRelease" }.configureEach {
    finalizedBy(copyReleaseApk)
}
