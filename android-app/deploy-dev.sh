#!/bin/bash

# Exit on error
set -e

echo "🚀 Starting development deployment..."

# Clean the project
echo "🧹 Cleaning project..."
./gradlew clean

# Build the development APK
echo "🔨 Building development APK..."
./gradlew assembleDevDebug

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    # Install the APK on connected device
    echo "📱 Installing APK..."
    adb install -r app/build/outputs/apk/dev/debug/app-dev-debug.apk
    
    # Launch the app
    echo "🎮 Launching app..."
    adb shell am start -n com.lengleng.dev/com.lengleng.MainActivity
    
    echo "✨ Deployment complete!"
else
    echo "❌ Build failed!"
    exit 1
fi 