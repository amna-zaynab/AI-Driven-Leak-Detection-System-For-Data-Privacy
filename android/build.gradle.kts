import com.android.build.gradle.LibraryExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Ensure older plugin modules that don't declare `namespace` in their Gradle
// files get one inferred from their AndroidManifest package attribute.
subprojects {
    plugins.withId("com.android.library") {
        try {
            extensions.configure(com.android.build.gradle.LibraryExtension::class.java) {
                if (namespace.isNullOrBlank()) {
                    val manifestFile = file("${project.projectDir}/src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        val text = manifestFile.readText()
                        val regex = Regex("package=\"([^\"]+)\"")
                        val match = regex.find(text)
                        if (match != null) {
                            namespace = match.groupValues[1]
                        }
                    }
                }
            }
        } catch (e: Exception) {
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
