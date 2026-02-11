import AppKit

public final class VoiceOverAnnouncer {
    public static let shared = VoiceOverAnnouncer()

    private init() {}

    public var isVoiceOverRunning: Bool {
        NSWorkspace.shared.isVoiceOverEnabled
    }

    public func announce(_ message: String) {
        AccessibilityHelpers.announce(message)
    }
}
