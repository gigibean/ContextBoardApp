#!/bin/bash
# ContextBoard 릴리스 자동화 스크립트
# 사용법: bash release.sh [버전]
# 예시: bash release.sh 1.1.0
set -e

# 버전 인자 확인
VERSION="${1}"
if [ -z "$VERSION" ]; then
    # 현재 최신 태그에서 패치 버전 자동 증가
    LATEST=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
    LATEST="${LATEST#v}"
    IFS='.' read -r MAJOR MINOR PATCH <<< "$LATEST"
    PATCH=$((PATCH + 1))
    VERSION="${MAJOR}.${MINOR}.${PATCH}"
    echo "📌 버전 자동 감지: ${LATEST} → ${VERSION}"
fi

APP_NAME="ContextBoard"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
TAG="v${VERSION}"

# 이미 같은 태그가 있는지 확인
if git rev-parse "$TAG" >/dev/null 2>&1; then
    echo "❌ 태그 ${TAG}가 이미 존재합니다. 다른 버전을 지정하세요."
    exit 1
fi

# 작업 디렉토리가 깨끗한지 확인
if [ -n "$(git status --porcelain)" ]; then
    echo "⚠️  커밋되지 않은 변경사항이 있습니다. 먼저 커밋하세요."
    git status --short
    exit 1
fi

echo ""
echo "🚀 ContextBoard ${TAG} 릴리스 시작"
echo "=================================="

# 1. create-dmg.sh의 버전 업데이트
echo ""
echo "📝 버전 업데이트 중..."
sed -i '' "s/VERSION=\".*\"/VERSION=\"${VERSION}\"/" create-dmg.sh

# Info.plist 버전도 업데이트
sed -i '' "s/<string>[0-9]*\.[0-9]*\.[0-9]*<\/string>/<string>${VERSION}<\/string>/g" create-dmg.sh

# 2. DMG 빌드
echo ""
bash create-dmg.sh

# DMG 존재 확인
if [ ! -f "dist/${DMG_NAME}" ]; then
    echo "❌ DMG 파일이 생성되지 않았습니다: dist/${DMG_NAME}"
    exit 1
fi

# 3. 버전 변경 커밋 + 태그
echo ""
echo "📦 커밋 & 태그 생성 중..."
git add create-dmg.sh
git commit -m "release: ${TAG}" --allow-empty

git tag -a "$TAG" -m "Release ${TAG}"

# 4. 푸시
echo ""
echo "⬆️  원격 저장소에 푸시 중..."
git push origin main
git push origin "$TAG"

# 5. 체인지로그 생성
echo ""
echo "📋 체인지로그 생성 중..."
PREV_TAG=$(git describe --tags --abbrev=0 HEAD^ 2>/dev/null || echo "")
if [ -n "$PREV_TAG" ]; then
    COMMIT_RANGE="${PREV_TAG}..HEAD"
    COMPARE_URL="https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/compare/${PREV_TAG}...${TAG}"
else
    COMMIT_RANGE="HEAD"
    COMPARE_URL=""
fi

# 커밋 메시지를 카테고리별로 분류
FEATS=""
FIXES=""
REFACTORS=""
DOCS=""
OTHERS=""

while IFS= read -r MSG; do
    [ -z "$MSG" ] && continue
    # release 커밋은 제외
    echo "$MSG" | grep -qiE "^release:" && continue

    if echo "$MSG" | grep -qiE "^feat(\(.*\))?:"; then
        ITEM="$(echo "$MSG" | sed -E 's/^feat(\(.*\))?:\s*//')"
        FEATS="${FEATS}- ${ITEM}\n"
    elif echo "$MSG" | grep -qiE "^fix(\(.*\))?:"; then
        ITEM="$(echo "$MSG" | sed -E 's/^fix(\(.*\))?:\s*//')"
        FIXES="${FIXES}- ${ITEM}\n"
    elif echo "$MSG" | grep -qiE "^refactor(\(.*\))?:"; then
        ITEM="$(echo "$MSG" | sed -E 's/^refactor(\(.*\))?:\s*//')"
        REFACTORS="${REFACTORS}- ${ITEM}\n"
    elif echo "$MSG" | grep -qiE "^docs(\(.*\))?:"; then
        ITEM="$(echo "$MSG" | sed -E 's/^docs(\(.*\))?:\s*//')"
        DOCS="${DOCS}- ${ITEM}\n"
    else
        OTHERS="${OTHERS}- ${MSG}\n"
    fi
done <<< "$(git log --pretty=format:"%s" ${COMMIT_RANGE} --no-merges)"

# 체인지로그 조합
CHANGELOG="## ${APP_NAME} ${TAG}\n"

if [ -n "$FEATS" ]; then
    CHANGELOG="${CHANGELOG}\n### ✨ 새 기능\n${FEATS}"
fi
if [ -n "$FIXES" ]; then
    CHANGELOG="${CHANGELOG}\n### 🐛 버그 수정\n${FIXES}"
fi
if [ -n "$REFACTORS" ]; then
    CHANGELOG="${CHANGELOG}\n### ♻️ 리팩토링\n${REFACTORS}"
fi
if [ -n "$DOCS" ]; then
    CHANGELOG="${CHANGELOG}\n### 📝 문서\n${DOCS}"
fi
if [ -n "$OTHERS" ]; then
    CHANGELOG="${CHANGELOG}\n### 🔧 기타\n${OTHERS}"
fi

if [ -n "$COMPARE_URL" ]; then
    CHANGELOG="${CHANGELOG}\n**Full Changelog**: ${COMPARE_URL}"
fi

CHANGELOG_RENDERED="$(echo -e "$CHANGELOG")"
echo "$CHANGELOG_RENDERED"

# 6. GitHub Release 생성
echo ""
echo "🎉 GitHub Release 생성 중..."
gh release create "$TAG" "dist/${DMG_NAME}" \
    --title "${APP_NAME} ${TAG}" \
    --notes "$CHANGELOG_RENDERED"

echo ""
echo "=================================="
echo "✅ ${TAG} 릴리스 완료!"
echo "   📦 DMG: dist/${DMG_NAME}"
echo "   🔗 $(gh release view "$TAG" --json url -q .url)"
echo ""
