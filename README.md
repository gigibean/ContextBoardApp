# ContextBoard

> macOS native context-switching mini app for developers

**멀티태스킹할 때 매번 Jira, PR, Figma, IDE를 하나하나 찾아 여는 게 귀찮으셨나요?**

ContextBoard는 티켓별로 관련 리소스를 하나의 스티커로 묶어서, **한 번의 클릭으로 전체 작업 환경을 열고 숨길 수 있는** macOS 메뉴바 앱입니다.

<br/>

## Download

### [ContextBoard-1.0.0.dmg](https://github.com/gigibean/ContextBoardApp/releases/download/v1.0.0/ContextBoard-1.0.0.dmg)

> macOS 14.0 (Sonoma) 이상 필요

<br/>

## Features

| 기능 | 설명 |
|------|------|
| **원클릭 컨텍스트 전환** | 스티커 탭 한 번으로 관련 URL, 앱, 파일 전체 열기/숨기기 |
| **스티커 보드 UI** | 드래그 가능한 스티커를 자유롭게 배치하는 파스텔 톤 보드 |
| **Jira MCP 연동** | Claude CLI를 통해 Jira 티켓 정보 + 관련 링크 자동 수집 |
| **일괄 가져오기** | 나에게 할당된 미완료 티켓을 한번에 가져와 스티커 생성 |
| **앱 + 프로젝트 폴더** | VS Code, IntelliJ 등을 특정 프로젝트 폴더와 함께 실행 |
| **파일 피커** | 앱, 파일, 폴더를 직접 입력 대신 선택 다이얼로그로 추가 |
| **앱 종료 관리** | 우클릭 → 관련 앱 종료로 작업 완전 정리 |
| **메뉴바 상주** | Dock에 안 뜨고 메뉴바 아이콘으로 항상 접근 가능 |

<br/>

## Install

1. 위 링크에서 `ContextBoard-1.0.0.dmg` 다운로드
2. DMG를 열고 `ContextBoard.app`을 **Applications** 폴더로 드래그
3. Applications에서 ContextBoard 실행
4. 메뉴바에 큐브 아이콘이 나타나면 성공!

> **처음 실행 시** "확인되지 않은 개발자" 경고가 뜰 수 있습니다.
> 시스템 설정 → 개인정보 보호 및 보안 → "확인 없이 열기"를 클릭하세요.

<br/>

## Usage

### 기본 사용법

1. **메뉴바 큐브 아이콘** 클릭 → "보드 열기"
2. **`+` 버튼**으로 새 컨텍스트 생성
3. 티켓 키, 제목 입력 → 관련 URL/앱/파일 추가
4. **스티커 탭** → 모든 리소스 열기 → 다시 탭 → 숨기기

### Jira 연동 (선택)

> [Claude CLI](https://docs.anthropic.com/en/docs/claude-code) 설치 필요

1. **설정**(톱니바퀴) → Jira 사이트 URL 입력 (예: `myteam.atlassian.net`)
2. 컨텍스트 편집 → **"Jira에서 가져오기"** → 티켓 번호 입력 → 관련 링크 자동 수집
3. 또는 **다운로드 아이콘** → 나에게 할당된 티켓 일괄 가져오기

### 앱 + 프로젝트 폴더

아이템 타입을 "애플리케이션"으로 설정하면 **프로젝트 폴더**를 함께 지정할 수 있습니다.
스티커를 탭하면 해당 앱이 지정된 프로젝트를 열어줍니다.

예: VS Code + `/Users/me/project` → VS Code가 해당 폴더를 열고 시작

### 컨텍스트 관리

| 동작 | 설명 |
|------|------|
| **탭** | 열기/숨기기 토글 |
| **더블 탭** | 편집 |
| **드래그** | 스티커 위치 이동 |
| **우클릭** | 열기, 편집, 관련 앱 종료, 삭제 |

<br/>

## Tech Stack

- **Swift 5.9** / **SwiftUI** + **AppKit** (NSPanel)
- **SwiftData** — 로컬 데이터 저장
- **NSWorkspace** — 앱/URL 열기, PID 기반 숨기기/종료
- **Claude CLI** — Jira MCP 연동 (Atlassian Rovo)
- **SPM** (Swift Package Manager) 빌드

<br/>

## Build from Source

```bash
git clone https://github.com/gigibean/ContextBoardApp.git
cd ContextBoardApp

# 빌드 & 실행
bash build-run.sh

# DMG 생성
bash create-dmg.sh

# 릴리스 (자동: 빌드 → DMG → 태그 → GitHub Release)
bash release.sh 1.1.0
```

<br/>

## License

MIT
