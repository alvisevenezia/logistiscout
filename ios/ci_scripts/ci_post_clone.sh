#!/bin/bash
# 🚀 Xcode Cloud post-clone setup script for Flutter iOS
set -e

echo "🏠 Moving to repository root..."
cd "$CI_PRIMARY_REPOSITORY_PATH"

echo "📦 Checking Flutter SDK..."
if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
else
  echo "✅ Flutter SDK already cached"
fi

export FLUTTER_ROOT="$HOME/flutter"
export PATH="$PATH:$FLUTTER_ROOT/bin"
echo "🔧 FLUTTER_ROOT set to: $FLUTTER_ROOT"

echo "🧩 Flutter doctor..."
flutter doctor -v

echo "📲 Pre-caching Flutter iOS artifacts..."
flutter precache --ios

echo "📚 Getting Flutter packages..."
flutter pub get

# ✅ Double-check that iOS build files are generated
if [ ! -f "ios/Flutter/Generated.xcconfig" ]; then
  echo "⚠️ Missing Generated.xcconfig, running flutter build ios to regenerate..."
  flutter build ios --simulator --no-codesign
fi

if [ ! -f "ios/Flutter/Generated.xcconfig" ]; then
  echo "❌ ERROR: ios/Flutter/Generated.xcconfig not found even after build."
  exit 1
else
  echo "✅ Generated.xcconfig found!"
fi

echo "🍺 Installing CocoaPods..."
HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods || true

IOS_DIR="$CI_PRIMARY_REPOSITORY_PATH/ios"
cd "$IOS_DIR"

echo "🧭 Current directory: $(pwd)"
echo "📂 Listing ios/Flutter directory:"
ls -la Flutter || echo "⚠️ No Flutter dir found yet"

# ✅ Ensure the platform line is set
if ! grep -q "platform :ios" Podfile 2>/dev/null; then
  echo "platform :ios, '15.0'" | cat - Podfile > temp && mv temp Podfile
fi

# ✅ Ensure workspace is explicitly defined (avoids xcodebuild confusion)
if ! grep -q "workspace" Podfile 2>/dev/null; then
  echo "workspace 'Runner.xcworkspace'" >> Podfile
fi

echo "🚀 Cleaning and re-installing Pods..."
rm -rf Pods Podfile.lock
pod repo update
pod install --verbose

echo "✅ iOS dependencies installed successfully!"

# ✅ Sanity: check Flutter.framework exists
if [ ! -d "Flutter/Flutter.framework" ]; then
  echo "⚠️ Flutter.framework missing — forcing build to embed engine..."
  cd "$CI_PRIMARY_REPOSITORY_PATH"
  flutter build ios --release --no-codesign
  cd "$IOS_DIR"
fi

if [ -d "Flutter/Flutter.framework" ]; then
  echo "🎯 Flutter.framework found, all good!"
else
  echo "❌ Flutter.framework still missing — build will likely fail."
  exit 1
fi

echo "✅ Xcode Cloud setup completed successfully!"
exit 0
