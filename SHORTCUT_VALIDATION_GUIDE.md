# Shortcut Validation System

## Overview (개요)

단축키 입력 시점에 실시간으로 유효성을 검사하여 **사용 불가능한 단축키를 사전에 차단**합니다.

## Problems Solved (해결된 문제)

### Before (이전):
```
사용자가 ⌃Z 입력
  ↓
저장됨
  ↓
다른 앱에서 실행 시도
  ↓
❌ 동작하지 않음 (이유 불명)
```

### After (이후):
```
사용자가 ⌃Z 입력
  ↓
❌ 즉시 에러 표시: "Shift-only shortcuts are not recommended. Add ⌘, ⌥, or ⌃"
  ↓
사용자가 ⌘⌥P로 변경
  ↓
✅ 저장 가능
  ↓
다른 앱에서 정상 동작
```

## Validation Rules (검증 규칙)

### 1. **Modifier Key Required (모디파이어 필수)**

❌ **거부**:
- `A` (모디파이어 없음)
- `1` (숫자만)
- `Space` (단일 키)

✅ **허용**:
- `⌘A`
- `⌥1`
- `⌃Space`

### 2. **System Reserved Shortcuts (시스템 예약 단축키)**

❌ **절대 사용 불가**:
- `⌘Space` - Spotlight
- `⌘⇧3/4/5` - Screenshot
- `⌃Space` - Input source switching
- `⌘⌥⎋` - Force Quit
- `⌃↑/↓/←/→` - Mission Control

**에러 메시지**: "This shortcut is reserved by macOS and cannot be used"

### 3. **Too Simple Combinations (너무 단순한 조합)**

❌ **권장하지 않음**:
- `⇧A` - Shift만 사용
- `⇧1` - Shift + 숫자

**에러 메시지**: "Shift-only shortcuts are not recommended. Add ⌘, ⌥, or ⌃"

**이유**: Shift는 대문자 입력에 사용되므로 텍스트 입력과 충돌 가능

### 4. **Problematic Keys (문제가 있는 키)**

❌ **사용 불가**:
- `ESC` (예약: 녹화 취소용)
- `Return/Enter`
- `Tab`
- `Delete`

**에러 메시지**: "This key cannot be used for shortcuts"

### 5. **Accessibility Permissions (접근성 권한)**

❌ **권한 없음**:
```
에러 메시지:
"Accessibility permissions required.

Open System Settings → Privacy & Security → Accessibility
and enable 'Promptist' or 'ai-prompter'."
```

## Implementation Details (구현 세부사항)

### Files Created (생성된 파일)

#### `Services/ShortcutValidator.swift`

**핵심 기능**:

```swift
class ShortcutValidator {
    func validate(_ keyCombo: KeyCombo) -> Result<Void, ShortcutValidationError>
}
```

**검증 순서**:
1. ✅ Modifier 존재 여부
2. ✅ 시스템 예약 단축키 체크
3. ✅ Shift-only 조합 체크
4. ✅ 문제 키 체크
5. ✅ Accessibility 권한 체크

**시스템 예약 단축키 목록**:
```swift
private static let systemReservedShortcuts: Set<String> = [
    "⌘ ",   // Spotlight
    "⌃↑", "⌃↓", "⌃←", "⌃→",  // Mission Control
    "⌘⇧3", "⌘⇧4", "⌘⇧5",    // Screenshot
    "⌘⌥⎋",  // Force Quit
    "⌃⌘Q",  // Lock Screen
    "⌃ ",   // Input source
]
```

### UI Changes (UI 변경사항)

#### `Views/ShortcutRecorderSheet.swift`

**Before (이전)**:
```swift
// 단순히 키 조합 저장
onKeyCaptured: { keyCombo in
    recordedKeyCombo = keyCombo
    isRecording = false
}
```

**After (이후)**:
```swift
// 즉시 유효성 검사 후 저장
onKeyCaptured: { keyCombo in
    recordedKeyCombo = keyCombo
    validateKeyCombo(keyCombo)  // ✅ 실시간 검증
    isRecording = false
}

private func validateKeyCombo(_ keyCombo: KeyCombo) {
    let result = validator.validate(keyCombo)
    switch result {
    case .success:
        errorMessage = nil  // ✅ 저장 가능
    case .failure(let error):
        errorMessage = error.localizedDescription  // ❌ 에러 표시
    }
}
```

**Error Display (에러 표시)**:
```swift
// Red error box
if let error = errorMessage {
    HStack(alignment: .top, spacing: DesignTokens.Spacing.xs) {
        Image(systemName: "exclamationmark.circle.fill")
        Text(error)
            .fixedSize(horizontal: false, vertical: true)
    }
    .foregroundColor(DesignTokens.Colors.error)
    .padding(DesignTokens.Spacing.sm)
    .background(
        RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
            .fill(DesignTokens.Colors.error.opacity(0.1))
    )
}
```

**Save Button State (저장 버튼 상태)**:
```swift
ActionButton("Save", variant: .primary) {
    // ...
}
.disabled(recordedKeyCombo == nil || errorMessage != nil)
//                                    ^^^^^^^^^^^^^^^^
//                                    에러 있으면 비활성화
```

## User Experience Flow (사용자 경험 흐름)

### Success Case (성공 케이스):
```
1. "Click to record shortcut" 클릭
   → 녹화 시작

2. ⌘⌥P 입력
   → ✅ Captured key combo: ⌘⌥P
   → ✅ Valid shortcut: ⌘⌥P

3. UI 업데이트
   → 버튼에 "⌘⌥P" 표시
   → Save 버튼 활성화
   → 에러 메시지 없음

4. Save 클릭
   → 단축키 저장 성공
```

### Error Case 1: System Reserved (시스템 예약):
```
1. "Click to record shortcut" 클릭

2. ⌘Space 입력
   → ✅ Captured key combo: ⌘Space
   → ❌ Invalid shortcut: This shortcut is reserved by macOS and cannot be used

3. UI 업데이트
   → 버튼에 "⌘Space" 표시 (회색)
   → 🔴 에러 박스 표시: "This shortcut is reserved by macOS and cannot be used"
   → Save 버튼 비활성화 (회색)

4. 사용자가 다른 조합 입력해야 함
```

### Error Case 2: Too Simple (너무 단순):
```
1. "Click to record shortcut" 클릭

2. ⇧Z 입력
   → ✅ Captured key combo: ⇧Z
   → ❌ Invalid shortcut: Shift-only shortcuts are not recommended. Add ⌘, ⌥, or ⌃

3. UI 업데이트
   → 🔴 에러 박스: "Shift-only shortcuts are not recommended..."
   → Save 버튼 비활성화

4. ⌘⇧Z 입력
   → ✅ Valid shortcut: ⌘⇧Z
   → Save 버튼 활성화
```

### Error Case 3: No Accessibility (권한 없음):
```
1. "Click to record shortcut" 클릭

2. ⌘⌥P 입력
   → ✅ Captured key combo: ⌘⌥P
   → ❌ Invalid shortcut: Accessibility permissions required...

3. UI 업데이트
   → 🔴 에러 박스 (여러 줄):
     "Accessibility permissions required.

      Open System Settings → Privacy & Security → Accessibility
      and enable 'Promptist' or 'ai-prompter'."
   → Save 버튼 비활성화

4. 사용자가 System Settings에서 권한 부여 후 재시도
```

## Console Logs (콘솔 로그)

### Success (성공):
```bash
🎤 Started local key capture
⏸️ Shortcut monitoring paused
🎹 Key captured: keyCode=35
✅ Captured key combo: ⌘⌥P
✅ Valid shortcut: ⌘⌥P
🛑 Stopped local key capture
▶️ Shortcut monitoring resumed
```

### System Reserved (시스템 예약):
```bash
🎤 Started local key capture
🎹 Key captured: keyCode=49
✅ Captured key combo: ⌘
❌ Invalid shortcut: This shortcut is reserved by macOS and cannot be used
```

### Too Simple (너무 단순):
```bash
🎤 Started local key capture
🎹 Key captured: keyCode=6
✅ Captured key combo: ⇧Z
❌ Invalid shortcut: Shift-only shortcuts are not recommended. Add ⌘, ⌥, or ⌃
```

### No Accessibility (권한 없음):
```bash
🎤 Started local key capture
🎹 Key captured: keyCode=35
✅ Captured key combo: ⌘⌥P
❌ Invalid shortcut: Accessibility permissions required.

Open System Settings → Privacy & Security → Accessibility
and enable 'Promptist' or 'ai-prompter'.
```

## Testing Checklist (테스트 체크리스트)

### ✅ Valid Shortcuts (유효한 단축키):
- [ ] `⌘⌥P` → 저장 가능
- [ ] `⌃⌥A` → 저장 가능
- [ ] `⌘⌃⇧F` → 저장 가능
- [ ] `⌥⇧G` → 저장 가능

### ❌ Invalid Shortcuts (무효한 단축키):

#### System Reserved:
- [ ] `⌘Space` → "reserved by macOS" 에러
- [ ] `⌘⇧4` → "reserved by macOS" 에러
- [ ] `⌃Space` → "reserved by macOS" 에러

#### Too Simple:
- [ ] `⇧Z` → "Shift-only... not recommended" 에러
- [ ] `⇧1` → "Shift-only... not recommended" 에러

#### No Modifiers:
- [ ] `A` → "must include at least one modifier" 에러
- [ ] `1` → "must include at least one modifier" 에러

#### No Accessibility:
- [ ] Accessibility 꺼진 상태에서 아무 단축키 → "permissions required" 에러

### UI State Tests:
- [ ] 에러 발생 시 Save 버튼 비활성화
- [ ] 에러 해결 시 Save 버튼 활성화
- [ ] 에러 메시지가 여러 줄일 때 박스 크기 자동 조정
- [ ] Clear 버튼 클릭 시 에러 메시지 사라짐

## Code Quality (코드 품질)

### ✅ Improvements:
1. **Fail Fast**: 키 입력 즉시 검증 → 사용자가 빠르게 피드백 받음
2. **Clear Errors**: 구체적인 에러 메시지로 문제 해결 방법 제시
3. **Disabled Save**: 잘못된 단축키 저장 불가
4. **Permission Check**: Accessibility 권한 사전 체크
5. **Extensible**: 새로운 검증 규칙 추가 용이

### 📝 Future Enhancements (향후 개선사항):
1. **Warning vs Error**: 권장하지 않는 단축키는 경고만 표시하고 저장은 허용
2. **Conflict Detection**: 다른 앱의 단축키와 충돌 감지
3. **Suggestions**: 유사한 대체 단축키 제안
4. **Permission Prompt**: Accessibility 권한 요청 버튼 추가

## Summary (요약)

이제 **사용 불가능한 단축키를 입력 시점에 차단**하여:
- ✅ 시스템 예약 단축키 → 저장 불가
- ✅ 너무 단순한 조합 → 경고 후 차단
- ✅ 권한 없음 → 명확한 안내 메시지
- ✅ 모든 에러가 실시간으로 표시됨
- ✅ Save 버튼이 에러 상태에서 비활성화됨

**다른 앱에서 동작하지 않는 문제가 사전에 방지됩니다!** 🎉
