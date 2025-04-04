#!/bin/bash

# Exit on error
set -e

echo "🚀 Starting staging deployment..."

# Check for required environment variables
if [ -z "$KEYSTORE_PASSWORD" ] || [ -z "$KEY_ALIAS" ] || [ -z "$KEY_PASSWORD" ]; then
    echo "❌ Error: Required environment variables are not set!"
    echo "Please set KEYSTORE_PASSWORD, KEY_ALIAS, and KEY_PASSWORD"
    exit 1
fi

# Clean the project
echo "🧹 Cleaning project..."
./gradlew clean

# Build the staging APK
echo "🔨 Building staging APK..."
./gradlew assembleStagingRelease

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    # Create output directory if it doesn't exist
    mkdir -p deploy/staging
    
    # Copy APK to deploy directory
    echo "📦 Copying APK to deploy directory..."
    cp app/build/outputs/apk/staging/release/app-staging-release.apk deploy/staging/
    
    # Generate SHA-256 hash of the APK
    echo "🔒 Generating SHA-256 hash..."
    shasum -a 256 deploy/staging/app-staging-release.apk > deploy/staging/app-staging-release.apk.sha256
    
    echo "✨ Deployment artifacts ready in deploy/staging/"
    echo "📱 APK: deploy/staging/app-staging-release.apk"
    echo "🔒 SHA-256: deploy/staging/app-staging-release.apk.sha256"
else
    echo "❌ Build failed!"
    exit 1
fi 