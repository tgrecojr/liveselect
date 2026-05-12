import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem?
    private var launchAtLoginItem: NSMenuItem?
    private let captureCoordinator = CaptureCoordinator()
    private let feedback = ClipboardAndFeedback()
    private let loginItems = LoginItemManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        feedback.requestNotificationAuthorization()

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "text.viewfinder",
                                   accessibilityDescription: "LiveSelect")
            button.image?.isTemplate = true
        }

        let menu = NSMenu()
        menu.delegate = self

        let captureItem = menu.addItem(
            withTitle: "Capture",
            action: #selector(captureClicked),
            keyEquivalent: ""
        )
        captureItem.target = self

        menu.addItem(.separator())

        let loginItem = menu.addItem(
            withTitle: "Launch at Login",
            action: #selector(toggleLoginItem),
            keyEquivalent: ""
        )
        loginItem.target = self
        launchAtLoginItem = loginItem

        menu.addItem(.separator())

        menu.addItem(
            withTitle: "Quit LiveSelect",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )

        item.menu = menu
        statusItem = item
    }

    func menuWillOpen(_ menu: NSMenu) {
        launchAtLoginItem?.state = loginItems.isEnabled ? .on : .off
    }

    @objc private func captureClicked() {
        captureCoordinator.startCapture()
    }

    @objc private func toggleLoginItem() {
        do {
            try loginItems.setEnabled(!loginItems.isEnabled)
        } catch {
            NSLog("LiveSelect: failed to toggle login item: \(error)")
        }
    }
}
