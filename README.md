# LiveSelect

A tiny macOS menu bar app that lets you **drag-select any region of the screen, OCR it on-device, and paste the recognized text anywhere**.

Text recognition runs locally through Apple's Vision framework — on Apple Silicon it uses the Neural Engine, so it's fast and nothing leaves your machine.

## Features

- Lives in the menu bar — no Dock icon, no main window
- Drag-to-select a region across any display
- On-device OCR (Apple Vision / Neural Engine)
- Recognized text is copied to your clipboard automatically
- Sound + system notification when capture completes
- Optional Launch at Login

## Requirements

- macOS 14 Sonoma or later
- Xcode 16 or later (to build)
- Apple Silicon recommended (Vision runs on the Neural Engine); Intel Macs work too, just slower

> **Note:** The Xcode project ships with `MACOSX_DEPLOYMENT_TARGET = 26.5` (the SDK version at the time of writing). If you want to run on older macOS versions, lower it to `14.0` in the project's Build Settings — none of the code uses macOS 15+ APIs.

## Install

There are no signed releases yet. Build from source:

```sh
git clone <this-repo-url>
cd LiveSelect
xcodebuild -project LiveSelect.xcodeproj -scheme LiveSelect -configuration Release build
cp -R \
  ~/Library/Developer/Xcode/DerivedData/LiveSelect-*/Build/Products/Release/LiveSelect.app \
  /Applications/
open /Applications/LiveSelect.app
```

Or open `LiveSelect.xcodeproj` in Xcode and hit ⌘R.

## Usage

1. Click the **`text.viewfinder`** icon in the menu bar
2. Choose **Capture**
3. Drag a rectangle around the text you want
4. Release the mouse — the text is now on your clipboard
5. Paste anywhere with ⌘V

To cancel a capture in progress, press **Esc**.

To start automatically at login, click the menu bar icon and toggle **Launch at Login**.

## Permissions

On first capture, macOS will prompt for **Screen Recording** permission. Grant it in:

> System Settings → Privacy & Security → Screen Recording

Then **quit and relaunch** LiveSelect — macOS does not apply the new permission to the currently-running process.

If you ever revoke the permission, LiveSelect will show an alert offering to open System Settings to the right pane.

Notifications permission is requested the first time the app launches. If you decline, the Glass sound still plays on success — you just won't get the banner.

## How it works

LiveSelect is a thin, AppKit-based menu bar app. The capture pipeline:

1. **`SelectionOverlayWindow`** — a borderless, transparent `NSWindow` is shown on each `NSScreen`. A custom `NSView` tracks mouse drags and draws a live cutout rectangle using the even-odd winding rule.
2. **`ScreenCaptureService`** — once the user releases the mouse, the selected rectangle is converted from AppKit's bottom-left screen coordinates to ScreenCaptureKit's top-left display coordinates. `SCScreenshotManager.captureImage` returns a `CGImage` at native (Retina) resolution. LiveSelect's own windows are excluded from the capture via `SCContentFilter(display:excludingApplications:exceptingWindows:)`.
3. **`TextRecognitionService`** — the `CGImage` is fed to `VNRecognizeTextRequest` (`.accurate` revision, `usesLanguageCorrection = true`, automatic language detection). The work runs on a detached `Task` so the main actor stays responsive.
4. **`ClipboardAndFeedback`** — the recognized text is written to `NSPasteboard.general`, the Glass system sound plays, and a `UNNotification` is posted with the character count.

If no text is recognized, the user gets a `Pop` sound and a "No text recognized" banner. If anything throws, the same sound plus the error's localized description.

## Project structure

```
LiveSelect/
├── LiveSelectApp.swift           # @main, hooks into AppDelegate
├── AppDelegate.swift             # NSStatusItem, menu, lifecycle
├── CaptureCoordinator.swift      # Orchestrates overlay → capture → OCR → clipboard
├── SelectionOverlayWindow.swift  # Transparent drag-select window + view
├── ScreenCaptureService.swift    # ScreenCaptureKit wrapper
├── TextRecognitionService.swift  # Vision OCR
├── ClipboardAndFeedback.swift    # NSPasteboard, NSSound, UNUserNotification
├── LoginItemManager.swift        # SMAppService.mainApp toggle
└── PermissionsManager.swift      # CGPreflightScreenCaptureAccess + alert
```

The Xcode project uses `PBXFileSystemSynchronizedRootGroup`, so adding a new Swift file to `LiveSelect/` is automatically picked up by the build — no pbxproj edits required.

## Roadmap / known limitations

- **No global hotkey yet.** Capture must be triggered from the menu. A `⌘⇧2`-style global shortcut is straightforward to add with Carbon's `RegisterEventHotKey`; happy to take a PR.
- **No capture history.** Each capture overwrites the clipboard; there's no built-in list of recent captures.
- **English-biased OCR.** `automaticallyDetectsLanguage = true` covers a lot of the common Latin-alphabet languages, but there's no UI to pin to a specific language.
- **Selection is bounded per display.** Cross-monitor drags aren't supported — start your drag on the display you want to capture from.
- **Ad-hoc signing only.** There's no Developer ID / notarized release; build it yourself.

## Contributing

Issues and PRs welcome. For non-trivial changes, please open an issue first so we can sketch the approach.

The codebase is intentionally small (well under 1k lines of Swift). Each pipeline stage is one file; adding a feature usually means touching one or two of them.

## License

TBD — currently unlicensed. Add a license file before publishing if you intend others to reuse the code.
