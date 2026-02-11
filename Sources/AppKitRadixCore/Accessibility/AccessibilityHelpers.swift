import AppKit

public enum AccessibilityHelpers {
    public static func announce(_ message: String, priority: NSAccessibilityPriorityLevel = .medium) {
        let info: [NSAccessibility.NotificationUserInfoKey: Any] = [
            .announcement: message,
            .priority: priority.rawValue,
        ]
        NSAccessibility.post(
            element: NSApp as Any,
            notification: .announcementRequested,
            userInfo: info
        )
    }

    public static func postLayoutChanged(focusedElement: Any? = nil) {
        if let element = focusedElement {
            NSAccessibility.post(element: element, notification: .layoutChanged)
        }
    }

    public static func postValueChanged(element: Any) {
        NSAccessibility.post(element: element, notification: .valueChanged)
    }
}
