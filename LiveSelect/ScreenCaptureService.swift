import AppKit
import ScreenCaptureKit

@MainActor
final class ScreenCaptureService {
    enum CaptureError: Error {
        case displayNotFound
        case rectOutOfBounds
    }

    func captureRegion(_ rectInScreen: CGRect, on nsScreen: NSScreen) async throws -> CGImage {
        let displayID = nsScreen.displayID
        let content = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
        )

        guard let scDisplay = content.displays.first(where: { $0.displayID == displayID }) else {
            throw CaptureError.displayNotFound
        }

        let screenFrame = nsScreen.frame
        let sourceRectRaw = CGRect(
            x: rectInScreen.origin.x - screenFrame.origin.x,
            y: screenFrame.maxY - rectInScreen.maxY,
            width: rectInScreen.width,
            height: rectInScreen.height
        )
        let displayBounds = CGRect(origin: .zero, size: screenFrame.size)
        let sourceRect = sourceRectRaw.intersection(displayBounds)

        guard !sourceRect.isNull, sourceRect.width > 1, sourceRect.height > 1 else {
            throw CaptureError.rectOutOfBounds
        }

        let ourBundleID = Bundle.main.bundleIdentifier
        let ourApps = content.applications.filter { $0.bundleIdentifier == ourBundleID }
        let filter = SCContentFilter(
            display: scDisplay,
            excludingApplications: ourApps,
            exceptingWindows: []
        )

        let scale = nsScreen.backingScaleFactor
        let config = SCStreamConfiguration()
        config.sourceRect = sourceRect
        config.width = max(1, Int(sourceRect.width * scale))
        config.height = max(1, Int(sourceRect.height * scale))
        config.scalesToFit = false
        config.showsCursor = false
        config.capturesAudio = false

        return try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: config
        )
    }
}

extension NSScreen {
    var displayID: CGDirectDisplayID {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        return (deviceDescription[key] as? NSNumber)?.uint32Value ?? 0
    }
}
