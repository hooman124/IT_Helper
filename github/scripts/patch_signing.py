"""
Patches the Flutter-generated android/app/build.gradle(.kts) so the
`release` build type is signed using android/key.properties, instead of
Flutter's default debug-signing fallback.

Used only by .github/workflows/build-apk.yml, only when release keystore
secrets are configured in the repository.
"""
import re
import sys

path = sys.argv[1]

with open(path, encoding="utf-8") as f:
    content = f.read()

if "key.properties" in content:
    print("Signing config already present, skipping patch.")
    sys.exit(0)

if path.endswith(".kts"):
    header = (
        "import java.util.Properties\n"
        "import java.io.FileInputStream\n\n"
        "val keystorePropertiesFile = rootProject.file(\"key.properties\")\n"
        "val keystoreProperties = Properties()\n"
        "if (keystorePropertiesFile.exists()) {\n"
        "    keystoreProperties.load(FileInputStream(keystorePropertiesFile))\n"
        "}\n\n"
    )
    content = header + content
    content = content.replace(
        "android {",
        "android {\n"
        "    signingConfigs {\n"
        "        create(\"release\") {\n"
        "            if (keystorePropertiesFile.exists()) {\n"
        "                keyAlias = keystoreProperties[\"keyAlias\"] as String\n"
        "                keyPassword = keystoreProperties[\"keyPassword\"] as String\n"
        "                storeFile = file(keystoreProperties[\"storeFile\"] as String)\n"
        "                storePassword = keystoreProperties[\"storePassword\"] as String\n"
        "            }\n"
        "        }\n"
        "    }\n",
        1,
    )
    content = re.sub(
        r"buildTypes\s*\{\s*release\s*\{",
        "buildTypes {\n        release {\n"
        "            signingConfig = signingConfigs.getByName(\"release\")",
        content,
        count=1,
    )
else:
    header = (
        "def keystorePropertiesFile = rootProject.file(\"key.properties\")\n"
        "def keystoreProperties = new Properties()\n"
        "if (keystorePropertiesFile.exists()) {\n"
        "    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))\n"
        "}\n\n"
    )
    content = header + content
    content = content.replace(
        "android {",
        "android {\n"
        "    signingConfigs {\n"
        "        release {\n"
        "            if (keystorePropertiesFile.exists()) {\n"
        "                keyAlias keystoreProperties['keyAlias']\n"
        "                keyPassword keystoreProperties['keyPassword']\n"
        "                storeFile file(keystoreProperties['storeFile'])\n"
        "                storePassword keystoreProperties['storePassword']\n"
        "            }\n"
        "        }\n"
        "    }\n",
        1,
    )
    content = re.sub(
        r"buildTypes\s*\{\s*release\s*\{",
        "buildTypes {\n        release {\n            signingConfig signingConfigs.release",
        content,
        count=1,
    )

with open(path, "w", encoding="utf-8") as f:
    f.write(content)

print(f"Patched {path} for release signing.")
