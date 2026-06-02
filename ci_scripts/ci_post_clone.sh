#!/bin/sh

# Install XcodeGen if it's not already installed
if ! command -v xcodegen >/dev/null 2>&1; then
    echo "XcodeGen not found. Installing..."
    brew install xcodegen
fi

# Always run from the repo root (works with: sh ci_scripts/ci_post_clone.sh)
cd "$(dirname "$0")/.." || exit 1

if [ -z "$DEVELOPMENT_TEAM" ]; then
    export DEVELOPMENT_TEAM="XSHZNN2ULY"
fi

echo "Generating Xcode project with Team ID: $DEVELOPMENT_TEAM"
xcodegen

echo "Resolving package dependencies..."
xcodebuild -resolvePackageDependencies -project Oculab.xcodeproj -scheme Oculab

if [ $? -eq 0 ]; then
    echo "Project generated and dependencies resolved successfully."
    open Oculab.xcodeproj
else
    echo "Failed to resolve package dependencies."
    exit 1
fi
