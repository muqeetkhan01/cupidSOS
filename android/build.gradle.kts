import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import org.gradle.api.tasks.compile.JavaCompile
import org.gradle.jvm.toolchain.JavaLanguageVersion
import org.gradle.api.plugins.JavaPlugin
import com.android.build.api.dsl.ApplicationExtension
import com.android.build.api.dsl.LibraryExtension

buildscript {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://raw.githubusercontent.com/LefuHengqi/PPBaseKit-Android/main")
        }
    }
}

/**
 * ✅ SINGLE subprojects block
 * ✅ Java 17 enforced at JAVAC level
 * ✅ Kotlin JVM 17 enforced
 * ✅ Toolchain forced for ALL plugins (including flutter_foreground_task)
 */

subprojects {

    // ✅ Android app modules
    plugins.withId("com.android.application") {
        extensions.configure<ApplicationExtension>("android") {
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
    }

    // ✅ Android library modules (THIS hits audioplayers_android, etc.)
    plugins.withId("com.android.library") {
        extensions.configure<LibraryExtension>("android") {
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
    }

    // ✅ Kotlin compiler → JVM 17
    tasks.withType<KotlinCompile>().configureEach {
        kotlinOptions {
            jvmTarget = "17"
        }
    }

    // ✅ Java compiler tasks → JVM 17
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = "17"
        targetCompatibility = "17"
    }

    // sign_in_with_apple Android module still defaults Java to 1.8 in some setups.
    // Force it to 17 so Android builds do not fail JVM target validation.
    if (name == "sign_in_with_apple") {
        plugins.withId("com.android.library") {
            extensions.configure<LibraryExtension>("android") {
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
            }
        }
        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = "17"
            targetCompatibility = "17"
        }
    }

    // ✅ Toolchain for Java plugin projects (some plugins create pure Java modules)
    plugins.withType<JavaPlugin> {
        the<org.gradle.api.plugins.JavaPluginExtension>().toolchain {
            languageVersion.set(JavaLanguageVersion.of(17))
        }
    }
    afterEvaluate {
        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = "17"
            targetCompatibility = "17"
        }
    }
}

// Flutter build dir fix (KEEP THIS)
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    project.layout.buildDirectory.value(newBuildDir.dir(project.name))
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
