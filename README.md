# ContextBoard

> 작업 컨텍스트 스위칭을 위한 macOS 미니 앱

## 개요

여러 티켓/태스크를 동시에 처리할 때, 컨텍스트 전환 시 관련된 모든 리소스(Jira, PR, Figma, IDE 등)를 수동으로 찾아 여는 번거로움을 해결합니다.

**ContextBoard**는 티켓별로 관련 URL/앱을 그룹화하고, 스티커 보드 UI에서 원클릭으로 전체 작업 컨텍스트를 열고/숨길 수 있는 macOS 네이티브 앱입니다.

## 주요 기능

- **티켓 기반 컨텍스트 관리**: 티켓/태스크별로 관련 URL, 앱, 파일을 그룹화
- **원클릭 컨텍스트 전환**: 스티커 클릭으로 모든 관련 리소스 열기/숨기기
- **MCP 연동**: Claude CLI를 통해 Jira에서 컨텍스트 자동 가져오기
- **카와이 스티커 보드 UI**: 드래그 가능한 스티커, 파스텔 색상, 커스터마이징 가능한 배경
- **메뉴 바 앱**: 항상 접근 가능한 메뉴 바 아이콘 + 플로팅 패널

## 요구사항

- macOS 14.0 (Sonoma) 이상
- Xcode 15+ (빌드용)
- (선택) Claude CLI — MCP 연동에 필요

## 빌드 & 실행

### Xcode에서 열기
```bash
cd ContextBoard
open Package.swift
# Xcode에서 자동으로 SPM 프로젝트로 열림
# Product > Run (Cmd+R)
```

### 명령줄에서 빌드
```bash
cd ContextBoard
swift build
swift run ContextBoard
```

## 프로젝트 구조

```
ContextBoard/
├── App/                    # 앱 진입점, AppDelegate, 핫키 매니저
├── Models/                 # SwiftData 모델 (WorkContext, ContextItem, BoardSettings)
│   └── Enums/             # IconType, ContextItemType, BackgroundStyle
├── Views/
│   ├── Board/             # 메인 스티커 보드 UI
│   ├── ContextEditor/     # 컨텍스트 생성/편집 폼
│   ├── MCP/               # Jira 가져오기 UI
│   ├── Settings/          # 설정 뷰
│   └── Shared/            # 공유 컴포넌트 (PastelButton, GlassCard 등)
├── Services/              # ContextLauncher, MCPService, AppTracker, IconManager
├── ViewModels/            # BoardViewModel, ContextEditorViewModel, MCPViewModel
├── Utilities/             # HexColor, CGPoint+Codable, ProcessRunner
└── Resources/             # Assets, Info.plist
```

## 기술 스택

| 영역 | 기술 |
|------|------|
| UI | SwiftUI + AppKit (NSPanel) |
| 데이터 | SwiftData |
| 앱 관리 | NSWorkspace + NSRunningApplication |
| MCP 연동 | Claude CLI (subprocess) |
| 글로벌 핫키 | Carbon API |
| 배포 대상 | macOS 14.0+ |

## 구현 단계

- [x] **Phase 1**: MVP — 스티커 보드 + 수동 컨텍스트 CRUD + 원클릭 열기
- [ ] **Phase 2**: 전체 토글 + 비주얼 폴리시
- [ ] **Phase 3**: MCP/Jira 연동
- [ ] **Phase 4**: 글로벌 핫키, 퀵 스위처, 태그 필터링

## 라이선스

Internal — Nol Platform
