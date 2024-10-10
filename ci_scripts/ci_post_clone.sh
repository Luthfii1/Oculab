#!/bin/bash

# Install XcodeGen if it's not already installed
if ! command -v xcodegen &> /dev/null; then
    echo "XcodeGen not found. Installing..."
    brew install xcodegen
fi

# List the contents of the current directory
echo "Current directory contents:"
ls .

# Change to the parent directory (where the project is located)
cd ..

# Generate the Xcode project using XcodeGen
echo "Generating Xcode project..."
xcodegen

# Check for .xcodeproj file
echo "Checking for .xcodeproj file..."
if [ -e "*.xcodeproj" ]; then
    echo ".xcodeproj file found."
else
    echo "Error: .xcodeproj file not found."
    exit 1
fi

# Check for xcworkspace and xcshareddata directories
XCWORKSPACE_PATH="*.xcodeproj/project.xcworkspace"
echo "Checking for xcshareddata directory..."

# Create xcshareddata if it does not exist
if [ ! -d "$XCWORKSPACE_PATH/xcshareddata" ]; then
    echo "xcshareddata directory not found, creating it..."
    mkdir -p "$XCWORKSPACE_PATH/xcshareddata"
else
    echo "xcshareddata directory already exists."
fi

# Create swiftpm directory if it does not exist
if [ ! -d "$XCWORKSPACE_PATH/xcshareddata/swiftpm" ]; then
    echo "swiftpm directory not found, creating it..."
    mkdir -p "$XCWORKSPACE_PATH/xcshareddata/swiftpm"
else
    echo "swiftpm directory already exists."
fi

# Create the Package.resolved file
PACKAGE_RESOLVED_PATH="$XCWORKSPACE_PATH/xcshareddata/swiftpm/Package.resolved"

if [ ! -f "$PACKAGE_RESOLVED_PATH" ]; then
    echo "Creating Package.resolved..."
    touch "$PACKAGE_RESOLVED_PATH"
    
    cat <<EOL > "$PACKAGE_RESOLVED_PATH"
# CREATE YOUR EXAMPLE DEPENDENCY HERE, ONLY FOR CREATING Package.resolved
{
  "originHash" : "",
  "pins" : [
    {
      "identity" : "",
      "kind" : "",
      "location" : "",
      "state" : {
        "revision" : "",
        "version" : ""
      }
    }
  ],
  "version" : 3
}
EOL
else
    echo "Package.resolved already exists."
fi

# Resolve package dependencies to generate Package.resolved
echo "Resolving package dependencies..."
xcodebuild -resolvePackageDependencies -project "*.xcodeproj" -scheme Your-app

# Check if Package.resolved was created
if [ -f "$PACKAGE_RESOLVED_PATH" ]; then
    echo "Package.resolved generated successfully."
else
    echo "Failed to generate Package.resolved."
    exit 1
fi

echo "Xcode project setup complete."
