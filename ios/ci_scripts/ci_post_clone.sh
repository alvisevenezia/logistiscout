#!/bin/sh

# Fail this script if any subcommand fails.
set -e

# The default execution directory of this script is the ci_scripts directory.
cd "$CI_PRIMARY_REPOSITORY_PATH" # change working directory to the root of your cloned repo.

# Install Flutter using git.
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# This project's Xcode target isn't migrated to consume Flutter's Swift Package
# Manager integration (no FlutterGeneratedPluginSwiftPackage reference). When SPM
# is enabled, flutter pub get silently excludes any plugin that ships a
# Package.swift (connectivity_plus, device_info_plus, file_picker, etc.) from the
# CocoaPods install, and since Xcode has no SPM package to fall back on, those
# plugins' modules never get built ("Module 'X' not found"). Force CocoaPods for
# all plugins until the project is migrated to SPM.
flutter config --no-enable-swift-package-manager

# Install Flutter artifacts for iOS (--ios), or macOS (--macos) platforms.
flutter precache --ios

# Install Flutter dependencies.
flutter pub get

# Install CocoaPods using Homebrew.
HOMEBREW_NO_AUTO_UPDATE=1 # disable homebrew's automatic updates.
brew install cocoapods

# Install CocoaPods dependencies.
cd ios
pod repo update
pod install --repo-update

exit 0
