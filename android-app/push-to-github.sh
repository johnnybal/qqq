#!/bin/bash

# Exit on error
set -e

echo "🚀 Starting GitHub push process..."

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "❌ Git is not installed!"
    exit 1
fi

# Check if repository is initialized
if [ ! -d ".git" ]; then
    echo "📦 Initializing Git repository..."
    git init
fi

# Add all files
echo "📝 Adding files to Git..."
git add .

# Check if there are changes to commit
if git diff --cached --quiet; then
    echo "ℹ️ No changes to commit."
    exit 0
fi

# Commit changes
echo "💾 Committing changes..."
git commit -m "Update Android app: $(date +'%Y-%m-%d %H:%M:%S')"

# Check if remote exists
if ! git remote get-url origin &> /dev/null; then
    echo "❌ No remote repository configured!"
    echo "Please add a remote repository using:"
    echo "git remote add origin <repository-url>"
    exit 1
fi

# Push to remote
echo "📤 Pushing to GitHub..."
git push origin main

echo "✨ Push complete!" 