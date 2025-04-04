#!/bin/bash

# Exit on error
set -e

# Load environment variables
if [ -f .env ]; then
  export $(cat .env | xargs)
fi

# Function to display usage
usage() {
  echo "Usage: $0 [development|production]"
  exit 1
}

# Check if environment is provided
if [ $# -ne 1 ]; then
  usage
fi

ENV=$1

# Validate environment
if [ "$ENV" != "development" ] && [ "$ENV" != "production" ]; then
  echo "Error: Environment must be either 'development' or 'production'"
  usage
fi

echo "🚀 Starting deployment for $ENV environment..."

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Build the application
echo "🏗️ Building application..."
REACT_APP_ENV=$ENV npm run build

# Deploy based on environment
if [ "$ENV" = "production" ]; then
  echo "🚀 Deploying to production..."
  
  # Check if Firebase CLI is installed
  if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Installing..."
    npm install -g firebase-tools
  fi

  # Deploy to Firebase Hosting
  firebase deploy --only hosting
  
  # Optional: Deploy Firebase Functions if you have them
  # firebase deploy --only functions
  
  echo "✅ Production deployment complete!"
else
  echo "🚀 Starting development server..."
  npm start
fi

echo "✨ Deployment process completed!" 