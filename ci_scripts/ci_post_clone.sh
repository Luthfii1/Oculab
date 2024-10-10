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

# Check for the existence of project.xcworkspace/xcshareddata directory
echo "Checking for xcshareddata directory..."
if [ ! -d "*.xcodeproj/project.xcworkspace/xcshareddata" ]; then
    echo "xcshareddata directory not found, creating it..."
    mkdir -p *.xcodeproj/project.xcworkspace/xcshareddata
fi

# Resolve package dependencies
echo "Resolving Swift package dependencies..."
xcodebuild -resolvePackageDependencies -project *.xcodeproj

# Final check to confirm package resolution
echo "Checking for Package.resolved..."
if [ ! -f "*.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" ]; then
    echo "Package.resolved not found. Creating it..."
    touch *.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
fi

echo "Xcode project setup complete."
