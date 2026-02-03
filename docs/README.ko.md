# Promptist

macOS 메뉴 바에서 AI 프롬프트 템플릿을 관리하고 즉시 실행하는 네이티브 앱입니다.

ChatGPT, Claude, Cursor 등 AI 앱을 사용할 때, 자주 쓰는 프롬프트를 저장해두고 단축키 한 번으로 클립보드에 복사할 수 있습니다.

> **[English documentation is available here.](../README.md)**

## 설치

### Homebrew (권장)

```bash
brew tap jadru/promptist
brew install --cask promptist
```

### 직접 다운로드

[GitHub Releases](https://github.com/jadru/homebrew-promptist/releases)에서 최신 DMG 파일을 다운로드하세요.

## 시스템 요구 사항

- macOS 15.0 (Sequoia) 이상
- macOS 26 (Tahoe) Liquid Glass 디자인 지원

## 주요 기능

### 메뉴 바 런처

메뉴 바 아이콘을 클릭하면 Raycast 스타일의 커맨드 팔레트가 열립니다. 검색, 키보드 탐색, 미리보기 패널을 지원하며 프롬프트를 선택하면 바로 클립보드에 복사됩니다.

### 앱별 프롬프트 연동

프롬프트 템플릿을 특정 앱에 연결할 수 있습니다. 현재 사용 중인 앱을 자동 감지하여 해당 앱에 연결된 프롬프트를 우선 표시합니다.

지원하는 앱:
- **AI**: ChatGPT, Claude for Desktop, Comet (Perplexity), ChatGPT Atlas
- **개발**: Cursor, Xcode, Android Studio, Warp, Docker
- **생산성**: Conductor, ClickUp, Obsidian, Goodnotes, Figma, Google Chrome
- 커스텀 앱도 직접 추가 가능

### 템플릿 변수

프롬프트 본문에 변수를 삽입하면 실행 시 자동으로 치환됩니다.

| 변수 | 설명 |
|------|------|
| `{{selection}}` | 현재 앱에서 선택한 텍스트 (Accessibility API) |
| `{{clipboard}}` | 클립보드 히스토리에서 선택 |
| `{{date}}` | 오늘 날짜 |
| `{{time}}` | 현재 시간 |
| `{{datetime}}` | 날짜 + 시간 |
| `{{input:질문}}` | 실행 시 사용자 입력을 받는 필드 |

예시:

```
다음 코드를 리뷰해줘. 버그, 성능, 가독성 관점에서 분석해줘.

{{selection}}
```

### 글로벌 단축키

프롬프트마다 단축키를 등록할 수 있습니다. 어떤 앱에서든 단축키를 누르면 해당 프롬프트가 클립보드에 복사됩니다.

- **글로벌 단축키**: 모든 앱에서 동작
- **앱별 단축키**: 특정 앱에서만 동작 (같은 키 조합을 앱마다 다르게 지정 가능)

> 글로벌 단축키를 사용하려면 **접근성 권한**이 필요합니다. 최초 실행 시 온보딩에서 안내합니다.

### 컬렉션 & 카테고리

프롬프트를 컬렉션으로 묶거나, 기본 제공되는 카테고리별로 분류할 수 있습니다.

기본 카테고리:
- **Coding** — Code Review, Debugging, Refactoring, Testing, Explain Code, Generate Code, Documentation
- **Writing & Communication** — Rewrite/Polish, Formal Writing, Creative Writing, Email, Translation, Summarization
- **Productivity** — Task Automation, Meeting Notes, Brainstorming, Planning, Decision Support
- **Research & Analysis** — Information Extraction, Comparison, Market/Topic Research, Critical Review
- **Image / Media Generation** — Image, Video, Audio
- **General Utilities** — General Q&A, Quick Commands, Daily Tools

### 기타

- 로그인 시 자동 실행
- 다크 모드 / 라이트 모드 / 시스템 설정 따르기
- 사용 빈도순 자동 정렬
- 최근 사용 프롬프트 섹션
- 영어 / 한국어 지원

## 권한 설정

Promptist는 다음 권한이 필요합니다:

- **접근성(Accessibility)**: 글로벌 단축키 감지 및 `{{selection}}` 변수를 통한 텍스트 선택 가져오기

설정 방법:
1. 시스템 설정 > 개인정보 보호 및 보안 > 접근성
2. Promptist를 목록에서 찾아 활성화
3. 앱 재시작

## 빌드

Xcode로 직접 빌드하려면:

```bash
git clone https://github.com/jadru/homebrew-promptist.git
cd homebrew-promptist
open Promptist.xcodeproj
```

Xcode에서 `Promptist` 스킴을 선택하고 빌드하세요. 외부 의존성 없이 Swift/SwiftUI만으로 구성되어 있습니다.

### 릴리스 빌드

```bash
./scripts/release.sh
```

DMG와 ZIP 파일이 `build/release/` 디렉토리에 생성됩니다.

## CI/CD

`main` 브랜치에 `Promptist/` 경로의 변경이 푸시되면 GitHub Actions가 자동으로:

1. Xcode 프로젝트에서 버전을 추출
2. Release 아카이브 빌드
3. DMG 생성
4. GitHub Release 발행
5. Homebrew Cask 포뮬러 업데이트

## 제거

### Homebrew로 설치한 경우

```bash
brew uninstall --cask promptist
```

### 수동 제거

앱을 삭제한 뒤 다음 파일을 제거하세요:

```
~/Library/Preferences/com.jadru.promptist.plist
~/Library/Application Support/Promptist
```

## 라이선스

Copyright 2025 Younggun Park

이 프로젝트는 [Apache License 2.0](../LICENSE)에 따라 배포됩니다.

자유롭게 사용, 수정, 배포할 수 있으며 상업적 이용도 가능합니다. 특허 보호 조항이 포함되어 있어 기여자의 특허권이 사용자에게 자동으로 부여됩니다. 자세한 내용은 [LICENSE](../LICENSE) 파일을 참조하세요.
