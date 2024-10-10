#!/bin/bash
# Install XcodeGen if it's not already installed
if ! command -v xcodegen &> /dev/null; then
    echo "XcodeGen not found. Installing..."
    brew install xcodegen
fi

# List the contents of the current directory
ls .

# Change to the parent directory (where the project is located)
cd ..

# Generate the Xcode project using XcodeGen
echo "Generating Xcode project..."
xcodegen

# Check if the .xcodeproj file was generated
echo "Checking for .xcodeproj file..."
ls *.xcodeproj

# Check for the existence of xcshareddata and swiftpm directories, and create if necessary
echo "Checking for xcshareddata directory..."
mkdir -p *.xcodeproj/project.xcworkspace/xcshareddata/swiftpm

## Check for the existence of project.xcworkspace/xcshareddata directory
#echo "Checking for xcshareddata directory..."
#if [ ! -d "*.xcodeproj/project.xcworkspace/xcshareddata" ]; then
#    echo "xcshareddata directory not found, creating it..."
#    mkdir -p *.xcodeproj/project.xcworkspace/xcshareddata
#fi

# Create an empty Package.resolved file to satisfy the resolver if it doesn't exist
if [ ! -f "*.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" ]; then
    echo "Package.resolved not found. Creating an empty file..."
    touch *.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
fi

# Resolve package dependencies
echo "Resolving Swift package dependencies..."
xcodebuild -resolvePackageDependencies -project *.xcodeproj

# Check if Package.resolved was created/updated after resolving dependencies
if [ -f "*.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" ]; then
    echo "Package.resolved generated successfully."
else
    echo "Failed to generate Package.resolved."
    exit 1
fi

echo "Xcode project setup complete."
