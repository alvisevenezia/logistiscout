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

# ✅ Ensure Generated.xcconfig exists
if [ ! -f "ios/Flutter/Generated.xcconfig" ]; then
  echo "⚙️ Missing ios/Flutter/Generated.xcconfig — retrying pub get..."
  flutter pub get
fi
if [ ! -f "ios/Flutter/Generated.xcconfig" ]; then
  echo "❌ ios/Flutter/Generated.xcconfig still missing."
  exit 1
fi
echo "✅ Generated.xcconfig found."

echo "🍺 Installing CocoaPods..."
HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods || true

IOS_DIR="$CI_PRIMARY_REPOSITORY_PATH/ios"
cd "$IOS_DIR"

echo "🧭 Current directory: $(pwd)"
echo "📂 Listing ios/Flutter directory:"
ls -la Flutter || echo "⚠️ ios/Flutter not present yet"

# ✅ Ensure platform line is set in Podfile
if ! grep -q "^platform :ios" Podfile 2>/dev/null; then
  echo "platform :ios, '15.0'" | cat - Podfile > Podfile.tmp && mv Podfile.tmp Podfile
fi

# ✅ (Optional) Explicit workspace helps some Cocoapods versions in CI
if ! grep -q "workspace 'Runner.xcworkspace'" Podfile 2>/dev/null; then
  echo "workspace 'Runner.xcworkspace'" >> Podfile
fi

# ✅ Make sure Flutter.podspec exists where CocoaPods expects it
if [ ! -f "Flutter/Flutter.podspec" ]; then
  echo "⚙️ Copying Flutter.podspec into ios/Flutter/…"
  mkdir -p Flutter
  cp "$FLUTTER_ROOT/bin/cache/artifacts/engine/ios/Flutter.podspec" Flutter/ 2>/dev/null || true
  cp "$FLUTTER_ROOT/bin/cache/artifacts/engine/ios-release/Flutter.podspec" Flutter/ 2>/dev/null || true
fi
if [ ! -f "Flutter/Flutter.podspec" ]; then
  echo "❌ Flutter/Flutter.podspec missing."
  exit 1
fi

# ✅ Tell CocoaPods where the Flutter engine lives (device slice)
export FLUTTER_FRAMEWORK_DIR="$FLUTTER_ROOT/bin/cache/artifacts/engine/ios-release"
export FLUTTER_BUILD_MODE=release
echo "🔗 FLUTTER_FRAMEWORK_DIR=$FLUTTER_FRAMEWORK_DIR"

echo "🧹 Cleaning CocoaPods (fresh integration)…"
rm -rf Pods Podfile.lock
pod deintegrate || true
pod repo update

echo "📦 pod install (verbose)…"
pod install --verbose

echo "⚙️ Prebuilding Flutter engine for device (no codesign)…"
cd "$CI_PRIMARY_REPOSITORY_PATH"
# Remove any stale frameworks to avoid mixed slices
rm -rf ios/Flutter/Flutter.framework ios/Flutter/Flutter.xcframework
flutter build ios --release --no-codesign

echo "🔍 Verifying Flutter engine artifacts…"
if [ -d "ios/Flutter/Flutter.xcframework" ] || [ -d "ios/Flutter/Flutter.framework" ]; then
  echo "✅ Flutter engine present."
else
  echo "❌ Flutter engine missing after build."
  exit 1
fi

echo "📄 Ensuring AppFrameworkInfo.plist exists…"
if [ ! -f "ios/Flutter/AppFrameworkInfo.plist" ]; then
  mkdir -p ios/Flutter
  cp "$FLUTTER_ROOT/packages/flutter_tools/bin/templates/app/ios.tmpl/Flutter/AppFrameworkInfo.plist" ios/Flutter/ || true
fi

echo "📂 Final ios/Flutter layout:"
ls -la ios/Flutter || true
find ios/Flutter -maxdepth 2 -name "Flutter.*" -print || true

echo "✅ Xcode Cloud setup completed successfully!"
