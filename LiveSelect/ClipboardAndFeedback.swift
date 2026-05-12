import AppKit
import UserNotifications

@MainActor
final class ClipboardAndFeedback {
    func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { _, _ in }
    }

    func deliverSuccess(text: String) {
        copyToPasteboard(text)
        NSSound(named: "Glass")?.play()
        let plural = text.count == 1 ? "" : "s"
        postNotification(
            title: "Text copied",
            body: "\(text.count) character\(plural) on the clipboard"
        )
    }

    func deliverNoTextFound() {
        NSSound(named: "Pop")?.play()
        postNotification(
            title: "No text recognized",
            body: "The selected region didn't contain readable text."
        )
    }

    func deliverError(_ error: Error) {
        NSSound(named: "Pop")?.play()
        postNotification(
            title: "Capture failed",
            body: error.localizedDescription
        )
    }

    private func copyToPasteboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    private func postNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
