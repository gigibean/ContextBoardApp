#!/bin/bash
# ContextBoard 빌드 & 실행 스크립트
set -e

APP_PATH="$HOME/Applications/ContextBoard.app"

# 기존 프로세스 종료
pkill -f "ContextBoard.app" 2>/dev/null || true
sleep 1

# 빌드
echo "🔨 Building..."
swift build 2>&1

# 앱 번들 업데이트
mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources"
cp .build/arm64-apple-macosx/debug/ContextBoard "$APP_PATH/Contents/MacOS/"
cp -r .build/arm64-apple-macosx/debug/ContextBoard_ContextBoard.bundle "$APP_PATH/Contents/Resources/" 2>/dev/null

# Info.plist (없으면 생성)
if [ ! -f "$APP_PATH/Contents/Info.plist" ]; then
cat > "$APP_PATH/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>ContextBoard</string>
    <key>CFBundleIdentifier</key>
    <string>com.contextboard.app</string>
    <key>CFBundleName</key>
    <string>ContextBoard</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticTermination</key>
    <false/>
</dict>
</plist>
PLIST
fi

# 서명 & 실행
codesign --force --sign - "$APP_PATH" 2>/dev/null
echo "🚀 Launching..."
open "$APP_PATH"
