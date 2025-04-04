#!/bin/bash

# Exit on error
set -e

echo "🚀 Starting production deployment..."

# Check for required environment variables
if [ -z "$KEYSTORE_PASSWORD" ] || [ -z "$KEY_ALIAS" ] || [ -z "$KEY_PASSWORD" ]; then
    echo "❌ Error: Required environment variables are not set!"
    echo "Please set KEYSTORE_PASSWORD, KEY_ALIAS, and KEY_PASSWORD"
    exit 1
fi

# Clean the project
echo "🧹 Cleaning project..."
./gradlew clean

# Build the production APK and AAB
echo "🔨 Building production artifacts..."
./gradlew assembleProdRelease bundleProdRelease

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    # Create output directory if it doesn't exist
    mkdir -p deploy/prod
    
    # Copy APK and AAB to deploy directory
    echo "📦 Copying artifacts to deploy directory..."
    cp app/build/outputs/apk/prod/release/app-prod-release.apk deploy/prod/
    cp app/build/outputs/bundle/prodRelease/app-prod-release.aab deploy/prod/
    
    # Generate SHA-256 hashes
    echo "🔒 Generating SHA-256 hashes..."
    shasum -a 256 deploy/prod/app-prod-release.apk > deploy/prod/app-prod-release.apk.sha256
    shasum -a 256 deploy/prod/app-prod-release.aab > deploy/prod/app-prod-release.aab.sha256
    
    # Generate version info
    echo "📝 Generating version info..."
    echo "Version: $(cat app/build.gradle.kts | grep versionName | cut -d'"' -f2)" > deploy/prod/version.txt
    echo "Version Code: $(cat app/build.gradle.kts | grep versionCode | cut -d'=' -f2 | tr -d ' ')" >> deploy/prod/version.txt
    echo "Build Time: $(date)" >> deploy/prod/version.txt
    
    echo "✨ Deployment artifacts ready in deploy/prod/"
    echo "📱 APK: deploy/prod/app-prod-release.apk"
    echo "📦 AAB: deploy/prod/app-prod-release.aab"
    echo "🔒 SHA-256: deploy/prod/*.sha256"
    echo "📝 Version Info: deploy/prod/version.txt"
    
    # Upload to Google Play Console (optional)
    if [ "$1" == "--upload" ]; then
        echo "📤 Uploading to Google Play Console..."
        # Add your Google Play Console upload command here
        # Example: bundle tool upload deploy/prod/app-prod-release.aab
    fi
else
    echo "❌ Build failed!"
    exit 1
fi 