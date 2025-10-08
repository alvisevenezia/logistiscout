#!/bin/bash

# 🚨 Stop immediately if a command fails
set -e

# 🏠 Always start from the repo root (important for Xcode Cloud)
cd "$CI_PRIMARY_REPOSITORY_PATH"

echo "📦 Installing Flutter SDK (cached if available)..."
# ✅ Only clone Flutter if not already cached by Xcode Cloud
if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
else
  echo "Flutter already installed, skipping clone ✅"
fi
export PATH="$PATH:$HOME/flutter/bin"

echo "⚙️ Checking Flutter environment..."
flutter doctor -v

echo "📲 Pre-caching Flutter iOS artifacts..."
flutter precache --ios

echo "📚 Getting Flutter dependencies..."
flutter pub get

echo "🍺 Installing CocoaPods (via Homebrew)..."
HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods || true

echo "📦 Running pod install..."
cd ios

# ✅ Ensure minimum iOS platform is defined (avoids “no platform specified” warning)
if ! grep -q "platform :ios" Podfile 2>/dev/null; then
  echo "platform :ios, '15.0'" | cat - Podfile > temp && mv temp Podfile
fi

# ✅ Update repos & install Pods
pod repo update
pod install

# ✅ Fix file permissions for custom scripts (important for build signing)
if [ -f "sign_frameworks.sh" ]; then
  chmod +x sign_frameworks.sh
fi

echo "✅ iOS dependencies installed successfully!"

exit 0
