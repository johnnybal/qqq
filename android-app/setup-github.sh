#!/bin/bash

# Exit on error
set -e

echo "🚀 Setting up GitHub repository..."

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "❌ Git is not installed!"
    exit 1
fi

# Initialize repository if not already initialized
if [ ! -d ".git" ]; then
    echo "📦 Initializing Git repository..."
    git init
fi

# Check if remote is already configured
if ! git remote get-url origin &> /dev/null; then
    # Prompt for repository URL
    read -p "Enter your GitHub repository URL: " repo_url
    
    if [ -z "$repo_url" ]; then
        echo "❌ Repository URL cannot be empty!"
        exit 1
    fi
    
    echo "🔗 Adding remote repository..."
    git remote add origin "$repo_url"
fi

# Make all scripts executable
echo "🔧 Making scripts executable..."
chmod +x deploy-*.sh push-to-github.sh

# Add all files
echo "📝 Adding files to Git..."
git add .

# Initial commit
echo "💾 Creating initial commit..."
git commit -m "Initial commit: Android app setup"

# Push to GitHub
echo "📤 Pushing to GitHub..."
git push -u origin main

echo "✨ GitHub setup complete!" 