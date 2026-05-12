import AppKit
import CoreGraphics

@MainActor
final class PermissionsManager {
    var hasScreenRecordingAccess: Bool {
        CGPreflightScreenCaptureAccess()
    }

    func presentScreenRecordingAlert() {
        let alert = NSAlert()
        alert.messageText = "Screen Recording permission required"
        alert.informativeText = """
            LiveSelect needs Screen Recording permission to capture and OCR your selection.

            Open System Settings → Privacy & Security → Screen Recording, enable LiveSelect, \
            then quit and relaunch the app.
            """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
            NSWorkspace.shared.open(url)
        }
    }
}
