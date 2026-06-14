#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

APP_NAME="HomeTutor"
APP_BUNDLE="${APP_NAME}.app"
BINARY_PATH=".build/release/${APP_NAME}"

echo "🔨 Building ${APP_NAME} in Release mode..."
swift build -c release

echo "📦 Creating macOS App Bundle..."
# Recreate the structure
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy binary
cp "${BINARY_PATH}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

# Copy Info.plist
cp Info.plist "${APP_BUNDLE}/Contents/Info.plist"

# Add an icon if we have one (optional, we can add later)
# If no icon, macOS will show a default executable icon, which is fine for now

echo "✍️  Ad-hoc Code Signing App Bundle..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "✅ App bundle created: ${APP_BUNDLE}"

# Check for "run" argument
if [ "$1" == "run" ]; then
    echo "🚀 Launching ${APP_NAME}..."
    open "${APP_BUNDLE}"
fi
