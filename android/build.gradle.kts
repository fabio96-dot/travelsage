// Top-level build file (Kotlin DSL)
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // NOTA: Qui si usa "classpath" perché siamo nel blocco buildscript
        classpath("com.android.tools.build:gradle:8.0.0")
        classpath("com.google.gms:google-services:4.3.15")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Configurazione personalizzata della cartella build (opzionale)
val newBuildDir = layout.buildDirectory.dir("../../build").get()
layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    layout.buildDirectory.set(newSubprojectBuildDir)
    // Dipendenza dall'app (necessaria solo per alcuni moduli)
    evaluationDependsOn(":app")
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}