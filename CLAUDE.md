# CLAUDE.md

This file provides guidance to Claude Code when working with this project.

## Project Overview

ContextBoard는 macOS 네이티브 앱으로, 개발자가 여러 티켓/태스크 간 컨텍스트를 쉽게 전환할 수 있도록 도와줍니다.
각 티켓의 관련 리소스(URL, 앱, 파일)를 그룹화하여 원클릭으로 열고/숨길 수 있습니다.

## Tech Stack

- **언어**: Swift 5.9+
- **UI**: SwiftUI + AppKit (NSPanel for floating window)
- **데이터**: SwiftData (macOS 14+)
- **앱 관리**: NSWorkspace, NSRunningApplication
- **MCP 연동**: Claude CLI subprocess
- **배포 대상**: macOS 14.0+ (Sonoma)

## Build & Run

```bash
# SPM 빌드
swift build

# 실행
swift run ContextBoard

# Xcode에서 열기
open Package.swift
```

## Architecture

- **App/**: 앱 진입점, AppDelegate (NSPanel 관리), GlobalHotkeyManager
- **Models/**: SwiftData @Model 클래스 (WorkContext, ContextItem, BoardSettings)
- **Views/**: SwiftUI 뷰 (Board, ContextEditor, MCP, Settings, Shared)
- **Services/**: 비즈니스 로직 (ContextLauncher, MCPService, AppTracker, IconManager)
- **ViewModels/**: @Observable 뷰모델
- **Utilities/**: HexColor 변환, CGPoint+Codable, ProcessRunner

## Key Patterns

- MenuBarExtra로 메뉴 바 상주
- NSPanel (floating, non-activating)로 스티커 보드 표시
- SwiftData로 로컬 데이터 저장 (~/Library/Application Support/)
- Claude CLI를 서브프로세스로 호출하여 Jira MCP 연동
- 카와이/파스텔 디자인 시스템

## Important Notes

- LSUIElement=YES: Dock에 표시되지 않는 메뉴 바 전용 앱
- 개별 브라우저 탭은 닫을 수 없음 — 전체 앱 숨기기만 가능 (macOS 제한)
- MCP 연동은 선택 사항 — Claude CLI 없이도 수동 입력으로 동작
