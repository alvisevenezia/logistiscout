#!/bin/bash
# 🚀 Xcode Cloud post-clone setup script for Flutter iOS (App Store ready)
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

echo "🧩 Running Flutter doctor..."
flutter doctor -v

echo "📲 Pre-caching Flutter iOS artifacts..."
flutter precache --ios

echo "📚 Getting Flutter packages..."
flutter pub get

# ✅ Ensure Flutter build files exist
if [ ! -f "ios/Flutter/Generated.xcconfig" ]; then
  echo "⚙️ Missing Generated.xcconfig — regenerating Flutter iOS files..."
  flutter precache --ios
  flutter pub get
fi

if [ ! -f "ios/Flutter/Generated.xcconfig" ]; then
  echo "❌ ERROR: ios/Flutter/Generated.xcconfig still missing."
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

# ✅ Ensure workspace is defined
if ! grep -q "workspace" Podfile 2>/dev/null; then
  echo "workspace 'Runner.xcworkspace'" >> Podfile
fi

echo "🚀 Cleaning and re-installing Pods..."
rm -rf Pods Podfile.lock
pod repo update
pod install --verbose

echo "✅ CocoaPods integration complete!"

# ⚙️ Prepare Flutter.framework for Xcode Cloud device build (no simulator build)
cd "$CI_PRIMARY_REPOSITORY_PATH"
echo "⚙️ Preparing Flutter iOS engine for device build..."
flutter precache --ios

# ✅ Ensure AppFrameworkInfo.plist exists
if [ ! -f "ios/Flutter/AppFrameworkInfo.plist" ]; then
  echo "📄 Creating AppFrameworkInfo.plist..."
  mkdir -p ios/Flutter
  cp "$FLUTTER_ROOT/packages/flutter_tools/bin/templates/app/ios.tmpl/Flutter/AppFrameworkInfo.plist" ios/Flutter/ || true
fi

cd "$IOS_DIR"

echo "✅ Flutter iOS artifacts ready — Xcode Cloud will now handle code signing and archive."
echo "🎯 Setup completed successfully!"
exit 0
