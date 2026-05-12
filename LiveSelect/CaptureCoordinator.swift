import AppKit

@MainActor
final class CaptureCoordinator: SelectionOverlayDelegate {
    private var overlays: [SelectionOverlayWindow] = []
    private var isCapturing = false
    private let screenCapture = ScreenCaptureService()
    private let textRecognition = TextRecognitionService()
    private let feedback = ClipboardAndFeedback()
    private let permissions = PermissionsManager()

    func startCapture() {
        guard !isCapturing else { return }

        guard permissions.hasScreenRecordingAccess else {
            permissions.presentScreenRecordingAlert()
            return
        }

        isCapturing = true
        NSApp.activate()

        overlays = NSScreen.screens.map { screen in
            let overlay = SelectionOverlayWindow(screen: screen)
            overlay.selectionDelegate = self
            return overlay
        }
        overlays.forEach { $0.present() }
    }

    func overlay(_ window: SelectionOverlayWindow, didSelectRectInScreen rect: CGRect) {
        let screen = window.targetScreen
        dismissAll()

        Task {
            await runCapture(rect: rect, screen: screen)
        }
    }

    func overlayDidCancel(_ window: SelectionOverlayWindow) {
        dismissAll()
    }

    private func runCapture(rect: CGRect, screen: NSScreen) async {
        do {
            let image = try await screenCapture.captureRegion(rect, on: screen)
            let text = try await textRecognition.recognizeText(in: image)
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                feedback.deliverNoTextFound()
            } else {
                feedback.deliverSuccess(text: text)
            }
        } catch {
            feedback.deliverError(error)
        }
    }

    private func dismissAll() {
        overlays.forEach { $0.orderOut(nil) }
        overlays.removeAll()
        isCapturing = false
    }
}
