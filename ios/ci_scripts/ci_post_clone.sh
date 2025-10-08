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

# ✅ Always run pod install from the real iOS directory
IOS_DIR="$CI_PRIMARY_REPOSITORY_PATH/ios"
cd "$IOS_DIR"

# Sanity check: print where we are
echo "🧭 Current directory: $(pwd)"
echo "📂 Contents:"
ls -la Flutter

# Ensure platform line exists
if ! grep -q "platform :ios" Podfile 2>/dev/null; then
  echo "platform :ios, '15.0'" | cat - Podfile > temp && mv temp Podfile
fi

# Clean Pods (optional but safer)
rm -rf Pods Podfile.lock

# Force re-generation of xcconfig if needed
if [ ! -f "Flutter/Generated.xcconfig" ]; then
  echo "⚠️ Generated.xcconfig missing in ios folder — forcing re-generation..."
  cd "$CI_PRIMARY_REPOSITORY_PATH"
  flutter pub get
  cd "$IOS_DIR"
fi

echo "🚀 Running pod install..."
pod repo update
pod install

echo "✅ iOS setup complete!"

