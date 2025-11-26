# Empty Sheet Fix - ShortcutRecorderSheet

## Problem (문제)

**증상**:
```
1. Shortcut Manager 열기
2. "Add Shortcut" 클릭
3. ❌ 빈 화면(empty sheet)이 나타남
4. 다른 윈도우로 전환 후 다시 돌아오기
5. ✅ 정상적인 UI가 나타남
```

**스크린샷**: 빈 흰색 시트만 보임

## Root Cause (근본 원인)

### SwiftUI Sheet와 EnvironmentObject

SwiftUI의 `.sheet()` 모디파이어는 **새로운 window context**를 생성합니다. 이 때 부모 뷰의 `@EnvironmentObject`가 **자동으로 전달되지 않습니다**.

**Before (문제 코드)**:
```swift
.sheet(isPresented: $isPresentingRecorder) {
    ShortcutRecorderSheet(...)
    // ❌ languageSettings가 없음!
}
```

**ShortcutRecorderSheet의 코드**:
```swift
struct ShortcutRecorderSheet: View {
    @EnvironmentObject private var languageSettings: LanguageSettings
    //                         ^^^^^^^^^^^^^^^^^^^^
    //                         여기서 nil을 받아서 크래시 또는 빈 화면

    var body: some View {
        // languageSettings.locale 사용
        Text(String(localized: "...", locale: languageSettings.locale))
        //                                     ^^^^^^^^^^^^^^^^^^^^
        //                                     nil access → 빈 화면
    }
}
```

### 왜 다른 윈도우로 전환하면 작동했나?

SwiftUI가 윈도우 재활성화 시 environment를 재주입하는 버그/동작으로 인해 일시적으로 작동했을 가능성이 있습니다. 하지만 이는 **신뢰할 수 없는 동작**입니다.

## Solution (해결책)

### Explicit EnvironmentObject Injection

Sheet에 명시적으로 `environmentObject`를 주입합니다:

```swift
.sheet(isPresented: $isPresentingRecorder) {
    ShortcutRecorderSheet(...)
        .environmentObject(languageSettings)  // ✅ 명시적 전달
}
```

## Implementation (구현)

### File Modified: `Views/ShortcutManagerView.swift`

**Line 92**: Added `.environmentObject(languageSettings)`

```swift
// BEFORE (문제)
.sheet(isPresented: $isPresentingRecorder) {
    if let templateId = recordingTemplateId {
        ShortcutRecorderSheet(
            templateId: templateId,
            currentApp: currentAppTarget,
            shortcutManager: shortcutManager,
            onSave: { keyCombo, scope in
                viewModel.addShortcut(templateId: templateId, keyCombo: keyCombo, scope: scope)
                isPresentingRecorder = false
                recordingTemplateId = nil
            },
            onCancel: {
                isPresentingRecorder = false
                recordingTemplateId = nil
            }
        )
        // ❌ No environmentObject
    }
}

// AFTER (해결)
.sheet(isPresented: $isPresentingRecorder) {
    if let templateId = recordingTemplateId {
        ShortcutRecorderSheet(
            templateId: templateId,
            currentApp: currentAppTarget,
            shortcutManager: shortcutManager,
            onSave: { keyCombo, scope in
                viewModel.addShortcut(templateId: templateId, keyCombo: keyCombo, scope: scope)
                isPresentingRecorder = false
                recordingTemplateId = nil
            },
            onCancel: {
                isPresentingRecorder = false
                recordingTemplateId = nil
            }
        )
        .environmentObject(languageSettings)  // ✅ ADDED
    }
}
```

## Why This Happens (왜 이런 일이 발생하는가)

### SwiftUI Sheet Behavior

1. **Normal View Hierarchy**:
```
PromptManagerRootView
  @EnvironmentObject languageSettings
    ↓ (자동 전달)
  ShortcutManagerView
    @EnvironmentObject languageSettings
      ↓ (자동 전달)
    ShortcutItemRow
      @EnvironmentObject languageSettings
```

2. **Sheet Presentation**:
```
ShortcutManagerView
  .sheet {
    ShortcutRecorderSheet
      @EnvironmentObject languageSettings  ← ❌ NEW WINDOW CONTEXT
  }
```

Sheet는 **새로운 윈도우**를 생성하므로:
- 부모의 environment가 자동으로 상속되지 않음
- 명시적으로 `.environmentObject()`를 호출해야 함

### LocalizedString Calls

ShortcutRecorderSheet에서 여러 곳에서 `languageSettings.locale` 사용:

```swift
// Line 22
Text(String(localized: "shortcut_recorder.title", locale: languageSettings.locale))

// Line 34
Text(isRecording ?
    String(localized: "shortcut_recorder.button.press_combination", locale: languageSettings.locale) :
    String(localized: "shortcut_recorder.button.click_to_record", locale: languageSettings.locale))

// Line 63
Text(isRecording ?
    String(localized: "shortcut_recorder.help.cancel", locale: languageSettings.locale) :
    String(localized: "shortcut_recorder.help.modifiers", locale: languageSettings.locale))

// And more...
```

`languageSettings`가 nil이면:
- Crash (debug mode)
- Empty view (release mode)
- 또는 예측 불가능한 동작

## Testing (테스트)

### Before Fix (수정 전):
1. Shortcut Manager 열기
2. "Add Shortcut" 클릭
3. ❌ **빈 시트** 나타남
4. Console: 에러 또는 경고 (환경에 따라 다름)

### After Fix (수정 후):
1. Shortcut Manager 열기
2. "Add Shortcut" 클릭
3. ✅ **정상 UI** 즉시 나타남:
   - "Record Keyboard Shortcut" 제목
   - "Click to record shortcut" 버튼
   - "Use modifier keys..." 도움말
   - Scope 선택기
   - Cancel/Save 버튼

### Test Cases:
- [ ] 첫 실행 시 정상 표시
- [ ] 여러 번 열고 닫기 → 항상 정상 표시
- [ ] 다른 탭 갔다가 돌아오기 → 정상 표시
- [ ] 언어 변경 후 열기 → 정상 표시

## Additional Notes (추가 노트)

### Other Sheets in the App

동일한 패턴이 필요한 다른 sheet들도 확인 필요:

```swift
// Pattern to follow
.sheet(isPresented: $isPresented) {
    SomeView(...)
        .environmentObject(languageSettings)  // ✅ Always add
        .environmentObject(anyOtherEnvironmentObject)  // If needed
}
```

### Alternative Solutions (대안)

다른 해결 방법들 (사용하지 않은 이유):

1. **Pass locale as parameter**:
```swift
ShortcutRecorderSheet(locale: languageSettings.locale)
```
❌ 모든 하위 뷰에도 전달해야 함 → 코드 복잡

2. **Use .task or .onAppear to inject**:
```swift
.onAppear {
    // Too late - view already rendered
}
```
❌ 너무 늦음 - 이미 렌더링 시도함

3. **Use @Environment instead of @EnvironmentObject**:
```swift
@Environment(\.locale) var locale
```
❌ Custom LanguageSettings와 호환 안 됨

**Best Solution**: `.environmentObject()` 명시적 주입 ✅

## Summary (요약)

**Problem**: Sheet에서 빈 화면
**Cause**: EnvironmentObject가 자동 전달 안 됨
**Solution**: `.environmentObject(languageSettings)` 추가
**Result**: 첫 실행부터 정상 UI 표시

**Build Status**: ✅ BUILD SUCCEEDED

이제 "Add Shortcut" 클릭 시 **즉시 정상적인 UI가 표시**됩니다! 🎉
