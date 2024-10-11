##!/bin/bash
## Install XcodeGen if it's not already installed
#if ! command -v xcodegen &> /dev/null; then
#    echo "XcodeGen not found. Installing..."
#    brew install xcodegen
#fi
#
## List the contents of the current directory
#ls .
#
## Change to the parent directory (where the project is located)
#cd ..
#
## Generate the Xcode project using XcodeGen
#echo "Generating Xcode project..."
#xcodegen
#
## Check if the .xcodeproj file was generated
#echo "Checking for .xcodeproj file..."
#ls *.xcodeproj
#
## Check for the existence of xcshareddata and swiftpm directories, and create if necessary
#echo "Checking for xcshareddata directory..."
#mkdir -p *.xcodeproj/project.xcworkspace/xcshareddata/swiftpm
#
### Check for the existence of project.xcworkspace/xcshareddata directory
##echo "Checking for xcshareddata directory..."
##if [ ! -d "*.xcodeproj/project.xcworkspace/xcshareddata" ]; then
##    echo "xcshareddata directory not found, creating it..."
##    mkdir -p *.xcodeproj/project.xcworkspace/xcshareddata
##fi
#
## Create an empty Package.resolved file to satisfy the resolver if it doesn't exist
#if [ ! -f "*.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" ]; then
#    echo "Package.resolved not found. Creating an empty file..."
#    touch *.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
#fi
#
## Resolve package dependencies
#echo "Resolving Swift package dependencies..."
#xcodebuild -resolvePackageDependencies -project *.xcodeproj
#
## Check if Package.resolved was created/updated after resolving dependencies
#if [ -f "*.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" ]; then
#    echo "Package.resolved generated successfully."
#else
#    echo "Failed to generate Package.resolved."
#    exit 1
#fi
#
#echo "Xcode project setup complete."

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

# Resolve package dependencies
echo "Resolving package dependencies..."
xcodebuild -resolvePackageDependencies -project Oculab.xcodeproj -scheme Oculab
## BASED ON MY EXPERIENCE xcshareddata DIRECTORY IS NOT EXIST, YOU NEED TO CREATE THE DIRECTORY
#mkdir Oculab.xcodeproj/project.xcworkspace/xcshareddata
## BASED ON MY EXPERIENCE swiftpm DIRECTORY IS NOT EXIST, YOU NEED TO CREATE THE DIRECTORY
#mkdir Oculab.xcodeproj/project.xcworkspace/xcshareddata/swiftpm
## BASED ON MY EXPERIENCE Package.resolved DIRECTORY IS NOT EXIST, YOU NEED TO CREATE THE DIRECTORY
#touch Oculab.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
#echo "Creating Package.resolved..."
#cat <<EOL > Oculab.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
#{
#  "originHash" : "",
#  "pins" : [
#    {
#      "identity" : "",
#      "kind" : "",
#      "location" : "",
#      "state" : {
#        "revision" : "",
#        "version" : ""
#      }
#    }
#  ],
#  "version" : 3
#}
#EOL
## Resolve package dependencies to generate Package.resolved
#echo "Resolving package dependencies..."
#xcodebuild -resolvePackageDependencies -project Oculab.xcodeproj -scheme Oculab
## Check if Package.resolved was created
#if [ -f "Oculab.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" ]; then
#    echo "Package.resolved generated successfully."
#else
#    echo "Failed to generate Package.resolved."
#    exit 1
#fi

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
    exit 1
fi
