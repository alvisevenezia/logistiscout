import com.android.build.api.dsl.LibraryExtension
import com.android.build.api.dsl.ApplicationExtension

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
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }

                if (namespace == null) {
                    namespace = group.toString()
                }
            }
        }

        if (plugins.hasPlugin("com.android.application")) {
            project.extensions.configure<ApplicationExtension> {
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }

            }
        }
        
        // Force Kotlin JVM target for all subprojects, including Flutter plugins
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
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
