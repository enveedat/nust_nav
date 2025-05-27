buildscript {
    val kotlinVersion = "1.7.10"

    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
        classpath("com.google.gms:google-services:4.3.15")
        // Add Flutter Gradle plugin classpath if needed
        // classpath("dev.flutter:flutter-gradle-plugin:<version>")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Redirect build directories outside the project folder for cleaner structure
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

// Ensure app module is evaluated first for dependency resolution
subprojects {
    project.evaluationDependsOn(":app")
}

// Clean task to delete build directories
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
