with open('android/build.gradle.kts', 'r') as f:
    lines = f.readlines()

# Remove any previous subprojects block appended at the end
clean_lines = []
for line in lines:
    if line.strip() == "subprojects {":
        # Assume my added block is at the end of the file. So we truncate here.
        # But wait, there are multiple subprojects { blocks in the original file.
        # Let's just find where my added block starts.
        pass

# A better way is to just read the original from git, since I haven't committed the bad build.gradle.kts.
import subprocess
subprocess.run(['git', 'checkout', 'android/build.gradle.kts'])

with open('android/build.gradle.kts', 'a', encoding='utf-8') as f:
    f.write('''
subprojects {
    project.tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
    project.plugins.withId("com.android.library") {
        project.extensions.configure<com.android.build.gradle.LibraryExtension>("android") {
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
    }
}
''')
