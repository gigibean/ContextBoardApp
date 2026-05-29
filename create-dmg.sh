#!/bin/bash
# ContextBoard DMG 배포 패키지 생성 스크립트
set -e

APP_NAME="ContextBoard"
VERSION="1.0.1"
DMG_NAME="${APP_NAME}-${VERSION}"
BUILD_DIR=".build/release"
APP_BUNDLE="dist/${APP_NAME}.app"
DMG_DIR="dist/dmg"
DMG_PATH="dist/${DMG_NAME}.dmg"

echo "🧹 이전 빌드 정리..."
rm -rf dist
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# 1. Release 빌드
echo "🔨 Release 빌드 중..."
swift build -c release 2>&1

# 2. .app 번들 구성
echo "📦 앱 번들 생성 중..."
cp "${BUILD_DIR}/ContextBoard" "${APP_BUNDLE}/Contents/MacOS/"

# 리소스 번들 복사 (있는 경우)
if [ -d "${BUILD_DIR}/ContextBoard_ContextBoard.bundle" ]; then
    cp -r "${BUILD_DIR}/ContextBoard_ContextBoard.bundle" "${APP_BUNDLE}/Contents/Resources/"
fi

# Info.plist
cat > "${APP_BUNDLE}/Contents/Info.plist" << 'PLIST'
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
    <key>CFBundleDisplayName</key>
    <string>ContextBoard</string>
    <key>CFBundleVersion</key>
    <string>1.0.1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.1</string>
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
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
</dict>
</plist>
PLIST

# PkgInfo
echo -n "APPL????" > "${APP_BUNDLE}/Contents/PkgInfo"

# 3. 코드 서명 (ad-hoc, 개인 배포용)
echo "🔏 코드 서명 중..."
# extended attributes 제거 후 서명 (resource fork 에러 방지)
CLEAN_APP="/tmp/${APP_NAME}_clean.app"
rm -rf "${CLEAN_APP}"
mkdir -p "${CLEAN_APP}/Contents/MacOS" "${CLEAN_APP}/Contents/Resources"
cp "${APP_BUNDLE}/Contents/MacOS/ContextBoard" "${CLEAN_APP}/Contents/MacOS/"
cp "${APP_BUNDLE}/Contents/Info.plist" "${CLEAN_APP}/Contents/Info.plist"
cp "${APP_BUNDLE}/Contents/PkgInfo" "${CLEAN_APP}/Contents/PkgInfo"
if [ -d "${APP_BUNDLE}/Contents/Resources/ContextBoard_ContextBoard.bundle" ]; then
    cp -r "${APP_BUNDLE}/Contents/Resources/ContextBoard_ContextBoard.bundle" "${CLEAN_APP}/Contents/Resources/"
fi
rm -rf "${APP_BUNDLE}"
mv "${CLEAN_APP}" "${APP_BUNDLE}"
codesign --force --deep --sign - "${APP_BUNDLE}"

# 4. DMG 생성
echo "💿 DMG 생성 중..."
mkdir -p "${DMG_DIR}"
cp -r "${APP_BUNDLE}" "${DMG_DIR}/"

# Applications 심볼릭 링크 (드래그 앤 드롭 설치용)
ln -sf /Applications "${DMG_DIR}/Applications"

# DMG 생성
hdiutil create -volname "${APP_NAME}" \
    -srcfolder "${DMG_DIR}" \
    -ov -format UDZO \
    "${DMG_PATH}" 2>&1

# 정리
rm -rf "${DMG_DIR}"

echo ""
echo "✅ DMG 생성 완료!"
echo "   📍 ${DMG_PATH}"
echo "   📏 $(du -h "${DMG_PATH}" | cut -f1)"
echo ""
echo "설치 방법: DMG를 열고 ContextBoard.app을 Applications 폴더로 드래그하세요."
