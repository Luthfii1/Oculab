#bash
#!/bin/bash
# Install XcodeGen if it's not already installed
if ! command -v xcodegen &> /dev/null; then
    echo "XcodeGen not found. Installing..."
    brew install xcodegen
fi
ls .
# Change to the project directory
cd ..
# ALL STEPS AFTER CLONE PROJECT
# Generate the Xcode project using XcodeGen
echo "Generating Xcode project..."
xcodegen
echo "Check file on .xcodeproj"
ls Oculab.xcodeproj
echo "Check file on project.xcworkspace"
# Check if necessary directories exist
echo "Check file on xcshareddata"
if [ ! -d "Oculab.xcodeproj/project.xcworkspace/xcshareddata" ]; then
    mkdir Oculab.xcodeproj/project.xcworkspace/xcshareddata
fi

# Remove any existing Package.resolved to avoid conflicts
echo "Removing old Package.resolved..."
rm -f Oculab.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved

# BASED ON MY EXPERIENCE swiftpm DIRECTORY IS NOT EXIST, YOU NEED TO CREATE THE DIRECTORY
mkdir Oculab.xcodeproj/project.xcworkspace/xcshareddata/swiftpm
# BASED ON MY EXPERIENCE Package.resolved DIRECTORY IS NOT EXIST, YOU NEED TO CREATE THE DIRECTORY
touch Oculab.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
echo "Creating Package.resolved..."
cat <<EOL > Oculab.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
{
  "originHash" : "11b78eba97192d19796cff581fdf69b3e65b441188b1448a1b67e5d7b825a354",
  "pins" : [
    {
      "identity" : "alamofire",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/Alamofire/Alamofire.git",
      "state" : {
        "revision" : "f455c2975872ccd2d9c81594c658af65716e9b9a",
        "version" : "5.9.1"
      }
    }
  ],
  "version" : 3
}

EOL

# Resolve package dependencies to generate Package.resolved
echo "Resolving package dependencies..."
xcodebuild -resolvePackageDependencies -project Oculab.xcodeproj -scheme Oculab

# Check if Package.resolved was successfully generated
if [ -f "Oculab.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" ]; then
    echo "Package.resolved generated successfully."
else
    echo "Failed to generate Package.resolved."
    exit 1
fi

if [ $? -eq 0 ]; then
    echo "Package dependencies resolved successfully."
else
    echo "Failed to resolve package dependencies."
    exit 2
fi
