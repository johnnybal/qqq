#!/bin/bash

# Exit on error
set -e

# Function to display usage
usage() {
  echo "Usage: $0 [development|staging|production] [simulator|device]"
  exit 1
}

# Check if environment and target are provided
if [ $# -ne 2 ]; then
  usage
fi

ENV=$1
TARGET=$2

# Validate environment
if [ "$ENV" != "development" ] && [ "$ENV" != "staging" ] && [ "$ENV" != "production" ]; then
  echo "Error: Environment must be 'development', 'staging', or 'production'"
  usage
fi

# Validate target
if [ "$TARGET" != "simulator" ] && [ "$TARGET" != "device" ]; then
  echo "Error: Target must be 'simulator' or 'device'"
  usage
fi

echo "🚀 Starting iOS build for $ENV environment on $TARGET..."

# Set build configuration based on environment
case $ENV in
  "development")
    CONFIGURATION="Debug"
    SCHEME="LengLeng-Development"
    ;;
  "staging")
    CONFIGURATION="Staging"
    SCHEME="LengLeng-Staging"
    ;;
  "production")
    CONFIGURATION="Release"
    SCHEME="LengLeng"
    ;;
esac

# Set destination based on target
if [ "$TARGET" = "simulator" ]; then
  DESTINATION="platform=iOS Simulator,name=iPhone 14 Pro,OS=16.4"
else
  DESTINATION="generic/platform=iOS"
fi

# Clean build folder
echo "🧹 Cleaning build folder..."
xcodebuild clean \
  -workspace LengLeng.xcworkspace \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION"

# Build the app
echo "🏗️ Building app..."
xcodebuild build \
  -workspace LengLeng.xcworkspace \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "$DESTINATION" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

# If building for device, create IPA
if [ "$TARGET" = "device" ]; then
  echo "📦 Creating IPA..."
  xcodebuild archive \
    -workspace LengLeng.xcworkspace \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -archivePath "build/LengLeng-$ENV.xcarchive" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

  xcodebuild -exportArchive \
    -archivePath "build/LengLeng-$ENV.xcarchive" \
    -exportOptionsPlist "ExportOptions-$ENV.plist" \
    -exportPath "build"
fi

echo "✨ Build completed successfully!" 