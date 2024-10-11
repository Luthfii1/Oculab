bash
#!/bin/bash
# Change to the project directory
cd ..

# Remove the existing Package.resolved file if it's corrupted
if [ -f "Oculab.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" ]; then
    echo "Deleting corrupted Package.resolved..."
    rm "Oculab.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
fi

# Resolve Swift package dependencies
echo "Resolving Swift package dependencies..."
xcodebuild -resolvePackageDependencies -project Oculab.xcodeproj
