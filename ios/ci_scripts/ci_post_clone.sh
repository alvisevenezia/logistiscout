#!/bin/bash

# 🚨 Stop on first error
set -e

# 🏠 Always start from the repo root (important for Xcode Cloud)
cd "$CI_PRIMARY_REPOSITORY_PATH"

echo "📦 Installing Flutter SDK..."
# Clone Flutter stable channel
git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"

echo "⚙️ Running Flutter doctor..."
flutter doctor -v

echo "📲 Pre-caching Flutter iOS artifacts..."
flutter precache --ios

echo "📚 Getting Flutter packages..."
flutter pub get

echo "🍺 Installing CocoaPods..."
HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods || true

echo "📦 Running pod install..."
cd ios

# ✅ Ensure minimum iOS platform (fixes “no platform specified” warning)
if ! grep -q "platform :ios" Podfile 2>/dev/null; then
  echo "platform :ios, '15.0'" | cat - Podfile > temp && mv temp Podfile
fi

pod repo update
pod install

echo "✅ iOS dependencies installed successfully!"
exit 0
