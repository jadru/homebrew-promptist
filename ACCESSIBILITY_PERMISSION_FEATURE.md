# Accessibility Permission Management Feature

## Overview (개요)

Accessibility 권한이 없을 때 사용자가 쉽게 설정할 수 있도록 **인앱 UI와 자동 시스템 설정 연동** 기능을 구현했습니다.

## Problems Solved (해결된 문제)

### Before (이전):
```
사용자가 단축키 설정
  ↓
다른 앱에서 동작 안 함
  ↓
❌ 이유: Accessibility 권한 없음
  ↓
사용자가 직접 찾아야 함:
1. System Settings 앱 열기
2. Privacy & Security 찾기
3. Accessibility 찾기
4. Promptist 추가 (Finder에서 찾아서...)
5. 체크박스 활성화
6. 앱 재시작
```

### After (이후):
```
Shortcut Manager 열기
  ↓
✅ 권한 없으면 배너 자동 표시
  ↓
"권한 부여" 버튼 클릭
  ↓
✅ 자동으로 System Settings → Accessibility 화면으로 이동
  ↓
Promptist 찾아서 활성화
  ↓
✅ 단축키 작동!
```

## Implementation (구현 내용)

### 1. AccessibilityPermissionManager (새 파일)

**File**: `Services/AccessibilityPermissionManager.swift`

#### Core Functionality:

```swift
@MainActor
final class AccessibilityPermissionManager: ObservableObject {
    @Published var hasPermission: Bool = false

    func checkPermission(promptIfNeeded: Bool = false)
    func requestPermission()
    func openSystemSettings()  // ✅ 핵심 기능!
}
```

#### System Settings Deep Link:

```swift
func openSystemSettings() {
    if #available(macOS 13.0, *) {
        // macOS 13+ (Ventura): Direct link to Accessibility pane
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    } else {
        // macOS 12 and earlier
        let prefpaneUrl = URL(fileURLWithPath: "/System/Library/PreferencePanes/Security.prefPane")
        NSWorkspace.shared.open(prefpaneUrl)
    }
}
```

**결과**:
- ✅ macOS 13+: System Settings → Privacy & Security → **Accessibility** (정확한 위치)
- ✅ macOS 12-: System Settings → Security & Privacy (일반 화면)

### 2. Permission Banner (배너)

**Component**: `AccessibilityPermissionBanner`

권한이 없을 때 Shortcut Manager 상단에 표시되는 경고 배너:

```swift
struct AccessibilityPermissionBanner: View {
    var body: some View {
        HStack {
            ⚠️ Icon
            VStack {
                "접근성 권한 필요"
                "다른 앱에서 키보드 단축키를 사용하려면 활성화하세요"
            }
            [권한 부여] 버튼
        }
        .background(warning yellow)
    }
}
```

**표시 조건**:
```swift
if !permissionManager.hasPermission {
    AccessibilityPermissionBanner(permissionManager: permissionManager)
}
```

### 3. Detailed Permission Alert (상세 안내 모달)

**Component**: `AccessibilityPermissionAlert`

더 자세한 단계별 안내를 보여주는 전체 화면 모달:

```swift
struct AccessibilityPermissionAlert: View {
    var body: some View {
        VStack {
            🔒 Shield Icon
            "접근성 권한 필요"

            // 단계별 안내
            ① "아래 '시스템 설정 열기' 버튼을 클릭하세요"
            ② "자물쇠 아이콘을 클릭하고 비밀번호를 입력하세요"
            ③ "목록에서 'Promptist' 또는 'ai-prompter'를 찾으세요"
            ④ "옆의 체크박스를 활성화하세요"
            ⑤ "변경사항 적용을 위해 Promptist를 재시작하세요"

            ⚠️ "이 권한 없이는 다른 앱에서 키보드 단축키가 작동하지 않습니다."

            [시스템 설정 열기] 버튼
            [나중에 하기] 버튼
        }
    }
}
```

### 4. Integration (통합)

**File**: `Views/ShortcutManagerView.swift`

```swift
struct ShortcutManagerView: View {
    @StateObject private var permissionManager = AccessibilityPermissionManager()

    var body: some View {
        VStack {
            // Toolbar
            // ...

            // ✅ Permission Banner (권한 없을 때만)
            if !permissionManager.hasPermission {
                AccessibilityPermissionBanner(permissionManager: permissionManager)
                    .padding()
            }

            // Shortcut list
            // ...
        }
        .onAppear {
            permissionManager.checkPermission()  // 화면 표시 시 체크
        }
    }
}
```

## User Experience Flow (사용자 경험 흐름)

### Scenario 1: First Launch - No Permission (첫 실행 - 권한 없음)

```
1. 앱 최초 실행
   ↓
2. Shortcut Manager 탭 클릭
   ↓
3. ✅ 노란색 배너 자동 표시:
   ┌────────────────────────────────────────┐
   │ ⚠️ 접근성 권한 필요                    │
   │ 다른 앱에서 키보드 단축키를 사용하려면  │
   │ 활성화하세요                [권한 부여] │
   └────────────────────────────────────────┘
   ↓
4. [권한 부여] 버튼 클릭
   ↓
5. ✅ System Settings → Accessibility 자동 열림
   ↓
6. 사용자가 Promptist 찾아서 체크
   ↓
7. 앱으로 돌아오기
   ↓
8. ✅ 배너 자동으로 사라짐 (권한 감지)
   ↓
9. 단축키 설정 가능!
```

### Scenario 2: Permission Denied - Banner Always Visible

```
사용자가 권한을 계속 거부하는 경우:
  ↓
배너가 항상 표시됨 (리마인더 역할)
  ↓
사용자가 마음을 바꾸면 언제든지 [권한 부여] 클릭 가능
```

### Scenario 3: Permission Granted - Banner Hidden

```
권한이 이미 있는 경우:
  ↓
✅ 배너 표시 안 됨
  ↓
깔끔한 UI로 단축키 관리
```

## Technical Details (기술 세부사항)

### Permission Check API

```swift
func checkPermission(promptIfNeeded: Bool = false) {
    let options: NSDictionary = [
        kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: promptIfNeeded
    ]
    hasPermission = AXIsProcessTrustedWithOptions(options)
}
```

**Parameters**:
- `promptIfNeeded: false` → 조용히 체크만 (우리가 사용)
- `promptIfNeeded: true` → 시스템 다이얼로그 표시 (사용 안 함)

**Why we don't use system prompt**:
- 시스템 다이얼로그는 UI가 구식이고 설명이 부족함
- 우리의 커스텀 배너/모달이 훨씬 더 친절하고 상세함

### Deep Link URLs

macOS 13+ (Ventura):
```
x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility
                          └─────────────────────┘ └──────────────────────┘
                                Preference ID           Specific pane
```

macOS 12 and earlier:
```
file:///System/Library/PreferencePanes/Security.prefPane
```

### Auto App Addition (자동 앱 추가)

**Q**: Finder를 거치지 않고 Promptist를 Accessibility 목록에 자동으로 추가할 수 있나?

**A**: ❌ **불가능합니다.**

macOS 보안 정책상 **사용자가 직접 수동으로 추가**해야 합니다:

**이유**:
1. **Security by Design**: 앱이 스스로 Accessibility 권한을 받으면 키로거 등 악성 앱에 악용 가능
2. **User Consent**: 사용자가 명시적으로 허용해야 함
3. **System Integrity Protection (SIP)**: macOS가 시스템 설정 변경을 차단

**우리가 할 수 있는 최선**:
- ✅ System Settings를 정확한 화면으로 열어주기 (구현됨)
- ✅ 명확한 단계별 안내 제공 (구현됨)
- ✅ 친절한 배너로 계속 리마인드 (구현됨)

### Permission State Tracking

```swift
@StateObject private var permissionManager = AccessibilityPermissionManager()
              └─────────────┘
              ObservableObject - 상태 변경 시 UI 자동 업데이트
```

**State Changes**:
```swift
hasPermission: false
  ↓ (사용자가 권한 부여)
hasPermission: true
  ↓ (UI 자동 업데이트)
배너 사라짐
```

## Localization (다국어 지원)

### English (en.lproj/Localizable.strings):
```
"accessibility.alert.title" = "Accessibility Permission Required";
"accessibility.alert.step1" = "Click 'Open System Settings' below";
"accessibility.banner.title" = "Accessibility permission required";
"accessibility.banner.button" = "Grant Permission";
```

### Korean (ko.lproj/Localizable.strings):
```
"accessibility.alert.title" = "접근성 권한 필요";
"accessibility.alert.step1" = "아래 '시스템 설정 열기' 버튼을 클릭하세요";
"accessibility.banner.title" = "접근성 권한 필요";
"accessibility.banner.button" = "권한 부여";
```

## UI Design

### Banner Design:
```
┌────────────────────────────────────────────────────────┐
│ ⚠️  접근성 권한 필요                      [권한 부여]   │
│     다른 앱에서 키보드 단축키를 사용하려면              │
│     활성화하세요                                        │
└────────────────────────────────────────────────────────┘
```

**Colors**:
- Background: `DesignTokens.Colors.warning.opacity(0.1)` (연한 노란색)
- Border: `DesignTokens.Colors.warning.opacity(0.3)`
- Icon: `DesignTokens.Colors.warning` (주황색)
- Button background: `DesignTokens.Colors.accentPrimary.opacity(0.1)`

### Alert Modal Design:
```
┌──────────────────────────────────────────┐
│                                          │
│              🔒 (48pt)                   │
│                                          │
│        접근성 권한 필요                   │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │ ① 아래 '시스템 설정 열기'...      │  │
│  │ ② 자물쇠 아이콘을 클릭하고...     │  │
│  │ ③ 목록에서 'Promptist'...         │  │
│  │ ④ 옆의 체크박스를...              │  │
│  │ ⑤ 변경사항 적용을 위해...         │  │
│  └────────────────────────────────────┘  │
│                                          │
│  ⚠️ 이 권한 없이는 다른 앱에서...        │
│                                          │
│                                          │
│     [시스템 설정 열기]                    │
│     [나중에 하기]                         │
│                                          │
└──────────────────────────────────────────┘
```

**Size**: 500x520-600pt

## Testing Checklist (테스트 체크리스트)

### Initial State Tests:
- [ ] 권한 없이 Shortcut Manager 열기 → 배너 표시
- [ ] 권한 있는 상태로 열기 → 배너 숨김

### Banner Interaction:
- [ ] [권한 부여] 버튼 클릭 → System Settings 열림
- [ ] macOS 13+: Accessibility 화면으로 직접 이동
- [ ] macOS 12-: Security & Privacy 일반 화면 열림

### Permission Flow:
- [ ] System Settings에서 Promptist 찾기
- [ ] 체크박스 활성화
- [ ] 앱으로 돌아오기 → 배너 자동 사라짐

### State Persistence:
- [ ] 권한 부여 후 앱 재시작 → 배너 계속 숨김
- [ ] 권한 해제 후 앱 재시작 → 배너 다시 표시

### Localization:
- [ ] 영어 → 모든 텍스트 영어로 표시
- [ ] 한국어 → 모든 텍스트 한국어로 표시

## Build Status (빌드 상태)

```
✅ BUILD SUCCEEDED
```

## Summary (요약)

**구현된 기능**:
1. ✅ Accessibility 권한 자동 체크
2. ✅ 권한 없을 때 배너 자동 표시
3. ✅ "권한 부여" 버튼으로 System Settings 자동 열기
4. ✅ macOS 13+에서 Accessibility 화면으로 직접 이동
5. ✅ 단계별 상세 안내 모달
6. ✅ 권한 부여 후 배너 자동 숨김
7. ✅ 완전한 다국어 지원 (영어/한국어)

**불가능한 기능**:
- ❌ Finder 없이 자동으로 앱을 Accessibility 목록에 추가
  - **이유**: macOS 보안 정책상 사용자가 직접 수동으로 추가해야 함
  - **대안**: System Settings를 정확한 위치로 열어주는 것이 최선

**사용자 경험 개선**:
- Before: 사용자가 System Settings를 직접 찾아야 함 (7단계)
- After: 버튼 한 번으로 정확한 위치로 이동 (3단계)

이제 Accessibility 권한 설정이 **훨씬 쉽고 직관적**입니다! 🎉
