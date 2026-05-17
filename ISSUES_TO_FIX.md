# Unresolved Issues & Improvements

This document tracks identified issues, deprecations, and potential logic bugs in the **AlarmPlus** project that need fixing.

## 🔴 High Priority: Potential Bugs & Reliability
- **Empty Tests:** `test/widget_test.dart` is empty. There is zero automated test coverage for core alarm logic.
- **Android Signing:** `android/app/build.gradle.kts` still uses debug keys for release builds (line 36). A real keystore must be configured before publishing to Play Store.
- **Memory/Hardware Performance:** `.github/workflows/build-apk.yml` mentions "Fix memory issues", implying possible leaks or high consumption during builds/runtime.

## ✅ Fixed
- **Silent Failures (catch blocks):** All empty `catch (_) {}` blocks across `smart_alarm_service.dart`, `alarm_ring_screen.dart`, `alarm_ring_flow.dart`, `home_screen.dart`, `trivia_service.dart`, and `voice_memo_service.dart` now log via `debugPrint`.
- **Hardcoded Package Name:** `android/app/build.gradle.kts` application ID changed from `com.example.lumio` to `com.alarmplus.app`; Kotlin source files moved to matching package directory.
- **Flutter Deprecations:** All `MaterialStatePropertyAll`, `MaterialStateProperty`, and `MaterialState` usages replaced with `WidgetState*` equivalents across all affected screens.
- **Unused Field:** `_settingsKey` in `storage_service.dart` was already absent in current code (stale issue).

---
*Updated on 2026-05-17*
