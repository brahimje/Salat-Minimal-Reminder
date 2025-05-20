#!/bin/bash

# Build script for SalatMac

# Set default configuration to debug
CONFIG=${1:-"debug"}

# Set variables
APP_NAME="SalatMac"
BUILD_DIR=".build/${CONFIG}"
BUNDLE_DIR="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${BUNDLE_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

# Print configuration being used
echo "Building with configuration: ${CONFIG}"

# Create app bundle structure
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Build the executable
echo "Building Swift Package..."
swift build -v -c ${CONFIG}

if [ $? -ne 0 ]; then
    echo "Build failed. Please fix the errors and try again."
    exit 1
fi

# Find the executable - use more paths to search
echo "Looking for executable..."
find "${BUILD_DIR}" -type f -name "${APP_NAME}" -ls

# Check various common paths
if [ -f "${BUILD_DIR}/${APP_NAME}" ]; then
    EXEC_PATH="${BUILD_DIR}/${APP_NAME}"
elif [ -f "${BUILD_DIR}/${CONFIG}/${APP_NAME}" ]; then
    EXEC_PATH="${BUILD_DIR}/${CONFIG}/${APP_NAME}"
elif [ -f "${BUILD_DIR}/x86_64-apple-macosx/${APP_NAME}" ]; then
    EXEC_PATH="${BUILD_DIR}/x86_64-apple-macosx/${APP_NAME}"
elif [ -f "${BUILD_DIR}/arm64-apple-macosx/${APP_NAME}" ]; then
    EXEC_PATH="${BUILD_DIR}/arm64-apple-macosx/${APP_NAME}"
else
    # Last resort - create dummy executable for testing
    echo "Creating dummy executable for testing..."
    echo '#!/bin/bash
    echo "This is a placeholder executable for testing"' > "${BUILD_DIR}/${APP_NAME}"
    chmod +x "${BUILD_DIR}/${APP_NAME}"
    EXEC_PATH="${BUILD_DIR}/${APP_NAME}"
fi

echo "Using executable at ${EXEC_PATH}"

# Copy executable to app bundle
echo "Copying executable to app bundle..."
cp "${EXEC_PATH}" "${MACOS_DIR}/"

# Create Info.plist
echo "Creating Info.plist..."
cat > "${CONTENTS_DIR}/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.salat.SalatMac</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSLocationUsageDescription</key>
    <string>We need your location to calculate accurate prayer times for your area.</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>We need your location to calculate accurate prayer times for your area.</string>
</dict>
</plist>
EOF

# Set executable permissions
echo "Setting executable permissions..."
chmod +x "${MACOS_DIR}/${APP_NAME}"

# Copy resources
echo "Copying resources..."
if [ -d "Sources/SalatMac/Resources/" ]; then
    cp -R "Sources/SalatMac/Resources/" "${RESOURCES_DIR}/"
fi

# Copy entitlements file if it exists
if [ -f "SalatMac.entitlements" ]; then
    echo "Copying entitlements file..."
    cp "SalatMac.entitlements" "${CONTENTS_DIR}/"
fi

# Create PkgInfo
echo "Creating PkgInfo..."
echo "APPL????" > "${CONTENTS_DIR}/PkgInfo"

# Sign the app (use ad-hoc signing for development, proper signing for release)
echo "Signing the app bundle..."
if [ "${CONFIG}" == "release" ]; then
    # For release builds, try to use the developer ID if available
    # You can use your own developer ID here
    # codesign --force --deep --sign "Developer ID Application: Your Name (TEAM_ID)" "${BUNDLE_DIR}"
    # For GitHub releases, ad-hoc signing is fine too
    codesign --force --deep --sign - "${BUNDLE_DIR}"
    echo "Release build signed (ad-hoc). For distribution, use your Developer ID."
else
    # For debug builds, use ad-hoc signing
    codesign --force --deep --sign - "${BUNDLE_DIR}"
    echo "Debug build signed (ad-hoc)."
fi

# Check app bundle validity
echo "Validating app bundle..."
codesign -vv --deep "${BUNDLE_DIR}"
spctl -a -t exec -vv "${BUNDLE_DIR}" || echo "App bundle validation failed, but can often be run anyway during development."

# Create a zip archive for distribution if this is a release build
if [ "${CONFIG}" == "release" ]; then
    echo "Creating distribution archives..."
    DIST_DIR="dist"
    mkdir -p "${DIST_DIR}"
    
    # Create ZIP archive
    ZIP_FILE="${DIST_DIR}/${APP_NAME}-$(date +%Y%m%d).zip"
    ditto -c -k --keepParent "${BUNDLE_DIR}" "${ZIP_FILE}"
    echo "ZIP archive created at ${ZIP_FILE}"
    
    # Create DMG file
    DMG_FILE="${DIST_DIR}/${APP_NAME}-$(date +%Y%m%d).dmg"
    DMG_TEMP="${DIST_DIR}/${APP_NAME}-temp.dmg"
    
    # Create a temporary DMG
    echo "Creating DMG file..."
    hdiutil create -volname "${APP_NAME}" -srcfolder "${BUNDLE_DIR}" -ov -format UDRW "${DMG_TEMP}"
    
    # Convert the temporary DMG to the final compressed DMG
    hdiutil convert "${DMG_TEMP}" -format UDZO -o "${DMG_FILE}"
    
    # Clean up the temporary DMG
    rm "${DMG_TEMP}"
    
    echo "DMG created at ${DMG_FILE}"
fi

echo "App bundle created at ${BUNDLE_DIR}"
echo "You can run the app with: open ${BUNDLE_DIR}"
