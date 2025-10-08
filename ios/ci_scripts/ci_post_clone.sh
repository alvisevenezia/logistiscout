#!/bin/bash
# Xcode Cloud post-clone setup script (for ios/ci_scripts/)
set -e

echo "🏠 Moving to repository root..."
cd "$CI_PRIMARY_REPOSITORY_PATH"

echo "📦 Checking Flutter SDK..."
if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
else
  echo "✅ Flutter SDK already cached"
fi
export PATH="$PATH:$HOME/flutter/bin"

echo "🧩 Flutter doctor..."
flutter doctor -v

echo "📲 Pre-caching iOS artifacts..."
flutter precache --ios

echo "📚 Running flutter pub get..."
# ✅ Ensure this runs from project root
flutter pub get

# ✅ Verify Generated.xcconfig exists before proceeding
if [ ! -f "ios/Flutter/Generated.xcconfig" ]; then
  echo "⚠️ Generated.xcconfig not found yet, retrying..."
  sleep 5
  flutter pub get
fi

if [ ! -f "ios/Flutter/Generated.xcconfig" ]; then
  echo "❌ ERROR: Generated.xcconfig still missing after flutter pub get"
  exit 1
else
  echo "✅ Generated.xcconfig found!"
fi

echo "🍺 Installing CocoaPods..."
HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods || true

echo "📦 Running pod install..."
# ✅ go to ios folder (not ci_scripts)
cd ios

# Ensure minimum iOS platform is defined
if ! grep -q "platform :ios" Podfile 2>/dev/null; then
  echo "platform :ios, '15.0'" | cat - Podfile > temp && mv temp Podfile
fi

# Clean any old pods
rm -rf Pods Podfile.lock

pod repo update
pod install

echo "✅ iOS setup complete!"
exit 0
