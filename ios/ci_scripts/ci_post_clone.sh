#!/bin/bash
# Xcode Cloud post-clone setup script
set -e

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

echo "📚 Running flutter pub get..."
flutter pub get

echo "📲 Pre-caching iOS artifacts..."
flutter precache --ios

echo "🍺 Installing CocoaPods..."
HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods || true

echo "📦 Running pod install..."
cd ios

# Ensure minimum iOS platform is defined
if ! grep -q "platform :ios" Podfile 2>/dev/null; then
  echo "platform :ios, '15.0'" | cat - Podfile > temp && mv temp Podfile
fi

# Run pod install
pod install

echo "✅ iOS setup complete!"
exit 0
