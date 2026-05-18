# Copilot Instructions for Fast Bridge Frontend

## Project context

Fast Bridge is a Flutter frontend for Android device inspection/control. The app depends on a local FastAPI backend running at `http://127.0.0.1:8000` (README), while the hosted frontend is served from Vercel.

## Build, test, and lint commands

```bash
# Install dependencies
flutter pub get

# Run app in debug mode
flutter run

# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Run one specific test case
flutter test test/widget_test.dart --plain-name "Counter increments smoke test"

# Static analysis
flutter analyze

# Format source files
dart format lib/ test/

# Production builds
flutter build apk --release
flutter build web --release
```

## High-level architecture

### 1) App entry + route parsing (`lib/main.dart`)
- Route handling is centralized in `onGenerateRoute`, with URI segment parsing (not a separate routing package).
- Implemented routes:
  - `/`
  - `/settings`
  - `/device/:serial`
  - `/device/:serial/file_manager`
  - `/device/:serial/full_control`

### 2) Data boundary (`lib/data/`)
- `DeviceRepository` is the single API gateway used by viewmodels.
- Transport is split into:
  - `HttpClient` for REST (`get/post/put`)
  - `WsClient` for control streaming (`ws://127.0.0.1:8000/ws/device/{serial}/control`)
- Models map backend payloads:
  - JSON models (`fetch_device_info`, `screen_info`, `file_node`)
  - XML model (`UiHierarchy.fromXmlString`) for window dump trees

### 3) Presentation + state (`lib/view/` + `lib/viewmodel/`)
- Pages are StatefulWidgets that instantiate a dedicated ViewModel in `initState` and dispose it in `dispose`.
- State is `ValueNotifier`-driven; UI uses `ValueListenableBuilder` and/or manual listeners with `setState`.
- Main flows:
  - Home: device discovery + backend health SnackBar
  - Device page: screenshot + hierarchy + node properties in a synchronized 3-panel layout
  - Full control: fetch screen info, connect WebSocket, stream frames, send touch/key/text events
  - File manager: lazy tree expansion with per-path cache

## Key conventions (repo-specific)

- **Backend endpoint is hardcoded** in `DeviceRepository` (`127.0.0.1:8000`) for both HTTP and WS calls; do not introduce ad-hoc URLs in widgets/viewmodels.
- **Error notifier naming is mixed by design right now**: most viewmodels use `erro` (Portuguese), while `FullControlViewModel` uses `error`.
- **Device navigation is enum-driven** (`DeviceSection` in `device_nav_dropdown.dart`); some sections intentionally return `null` route and show a "Coming soon" SnackBar.
- **File manager state model** uses three notifiers (`cache`, `expanded`, `loading`) keyed by path; root path constant is `sdcard/`; listing is sorted with directories first.
- **Theme switching is global** through `themeNotifier` in `lib/view/ui/theme.dart` and default mode is dark.
- **`DeviceStore` is deprecated** and aliased to `HomeViewModel`; new work should use `HomeViewModel` directly.
- **Current test baseline** is still the default `test/widget_test.dart` counter smoke test and does not reflect the current app UI flows.

## Existing assistant guidance (from `CLAUDE.md`)

- Keep responses short, direct, and summarize changes after execution.
