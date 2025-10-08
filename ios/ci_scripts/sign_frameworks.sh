#!/bin/bash
set -e
echo "🔏 Signing embedded frameworks..."
APP_PATH="${TARGET_BUILD_DIR}/${WRAPPER_NAME}"

find "$APP_PATH/Frameworks" -type d -name "*.framework" | while read -r FRAMEWORK
do
  echo "Signing: $FRAMEWORK"
  /usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" --preserve-metadata=identifier,entitlements "$FRAMEWORK"
done
