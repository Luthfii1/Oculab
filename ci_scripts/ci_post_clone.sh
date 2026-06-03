#!/bin/sh
set -e

# Xcode Cloud: generate .xcodeproj (not in git) and resolve SPM before xcodebuild.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
export HOMEBREW_NO_AUTO_UPDATE=1

cd "$(dirname "$0")/.." || exit 1
REPO_ROOT="$(pwd)"

install_xcodegen() {
    if command -v xcodegen >/dev/null 2>&1; then
        return 0
    fi

    echo "XcodeGen not found. Installing via Homebrew..."
    if brew install xcodegen; then
        return 0
    fi

    echo "Homebrew install failed. Downloading XcodeGen binary..."
    XCODEGEN_VERSION="2.44.1"
    curl -fsSL \
        "https://github.com/yonaskolb/XcodeGen/releases/download/${XCODEGEN_VERSION}/xcodegen.zip" \
        -o /tmp/xcodegen.zip
    unzip -oq /tmp/xcodegen.zip -d /tmp/xcodegen
    export PATH="/tmp/xcodegen/bin:$PATH"

    if ! command -v xcodegen >/dev/null 2>&1; then
        echo "Failed to install XcodeGen."
        exit 1
    fi
}

install_xcodegen

if [ -z "${DEVELOPMENT_TEAM:-}" ]; then
    export DEVELOPMENT_TEAM="XSHZNN2ULY"
fi

echo "Generating Xcode project (Team: $DEVELOPMENT_TEAM)..."
xcodegen generate

echo "Resolving Swift package dependencies..."
xcodebuild -resolvePackageDependencies \
    -project "$REPO_ROOT/Oculab.xcodeproj" \
    -scheme Oculab

RESOLVED_FILE="$REPO_ROOT/Oculab.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
if [ ! -f "$RESOLVED_FILE" ]; then
    echo "error: Package.resolved was not created at $RESOLVED_FILE"
    exit 1
fi

echo "ci_post_clone completed successfully."
echo "Package.resolved: $RESOLVED_FILE"
