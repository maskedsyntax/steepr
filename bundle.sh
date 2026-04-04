#!/bin/bash

# 1. Build the app in release mode
swift build -c release --arch arm64 --arch x86_64

# 2. Define paths
APP_NAME="Steepr"
BUNDLE_DIR="${APP_NAME}.app"
CONTENTS_DIR="${BUNDLE_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
BINARY_PATH=".build/apple/Products/Release/${APP_NAME}"

# 3. Create folder structure
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# 4. Copy the binary
cp "${BINARY_PATH}" "${MACOS_DIR}/${APP_NAME}"

# 5. Create and Copy the icon
# We'll use a temporary Swift script to mask the PNG into a squircle and inset it
cat > icon_gen.swift <<EOF
import AppKit

extension NSImage {
    func withRoundedCorners(radius: CGFloat) -> NSImage {
        let destSize = NSSize(width: size.width, height: size.height)
        let newImage = NSImage(size: destSize)
        newImage.lockFocus()
        let rect = NSRect(origin: .zero, size: destSize)
        let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        path.addClip()
        self.draw(in: rect)
        newImage.unlockFocus()
        return newImage
    }
}

if let image = NSImage(contentsOfFile: "steepr-logo.png") {
    let size: CGFloat = 1024
    let inset: CGFloat = size * 0.1 // 10% margin on all sides
    let contentSize: CGFloat = size - (inset * 2)
    let radius: CGFloat = contentSize * 0.225
    
    let resizedImage = NSImage(size: NSSize(width: contentSize, height: contentSize))
    resizedImage.lockFocus()
    image.draw(in: NSRect(origin: .zero, size: NSSize(width: contentSize, height: contentSize)))
    resizedImage.unlockFocus()
    
    let maskedImage = resizedImage.withRoundedCorners(radius: radius)
    
    let finalImage = NSImage(size: NSSize(width: size, height: size))
    finalImage.lockFocus()
    maskedImage.draw(in: NSRect(x: inset, y: inset, width: contentSize, height: contentSize))
    finalImage.unlockFocus()
    
    if let tiffData = finalImage.tiffRepresentation,
       let bitmapData = NSBitmapImageRep(data: tiffData),
       let pngData = bitmapData.representation(using: .png, properties: [:]) {
        try? pngData.write(to: URL(fileURLWithPath: "native-icon.png"))
    }
}
EOF

swift icon_gen.swift
rm icon_gen.swift

if [ ! -f "native-icon.png" ]; then
    echo "❌ Failed to generate native-icon.png"
    exit 1
fi

mkdir -p AppIcon.iconset
sips -z 16 16     native-icon.png --out AppIcon.iconset/icon_16x16.png > /dev/null 2>&1
sips -z 32 32     native-icon.png --out AppIcon.iconset/icon_16x16@2x.png > /dev/null 2>&1
sips -z 32 32     native-icon.png --out AppIcon.iconset/icon_32x32.png > /dev/null 2>&1
sips -z 64 64     native-icon.png --out AppIcon.iconset/icon_32x32@2x.png > /dev/null 2>&1
sips -z 128 128   native-icon.png --out AppIcon.iconset/icon_128x128.png > /dev/null 2>&1
sips -z 256 256   native-icon.png --out AppIcon.iconset/icon_128x128@2x.png > /dev/null 2>&1
sips -z 256 256   native-icon.png --out AppIcon.iconset/icon_256x256.png > /dev/null 2>&1
sips -z 512 512   native-icon.png --out AppIcon.iconset/icon_256x256@2x.png > /dev/null 2>&1
sips -z 512 512   native-icon.png --out AppIcon.iconset/icon_512x512.png > /dev/null 2>&1
sips -z 1024 1024 native-icon.png --out AppIcon.iconset/icon_512x512@2x.png > /dev/null 2>&1

iconutil -c icns AppIcon.iconset -o "${RESOURCES_DIR}/AppIcon.icns"
rm -rf AppIcon.iconset
rm native-icon.png
cp "steepr-logo.png" "${RESOURCES_DIR}/"

# 6. Create Info.plist
cat > "${CONTENTS_DIR}/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.maskedsyntax.steepr</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "✅ ${APP_NAME}.app created successfully!"
