import com.android.build.api.dsl.LibraryExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    afterEvaluate {
        // check only for "com.android.library" to not modify
        // your "app" subproject. All plugins will have "com.android.library" plugin, and only your app "com.android.application"
        // Change your application's namespace in main build.gradle and in main android block.

        if (plugins.hasPlugin("com.android.library")) {
            project.extensions.configure<LibraryExtension> {
                if (namespace == null) {
                    namespace = group.toString()
                }
            }
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
