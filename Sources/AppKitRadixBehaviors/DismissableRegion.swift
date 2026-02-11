import AppKit
import AppKitRadixCore

public final class DismissableRegion {
    private var clickMonitor: Any?
    private var keyMonitor: Any?

    public init() {}

    public func monitor(view: NSView, onClickOutside: @escaping (NSEvent) -> DismissAction) {
        clickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { event in
            guard let eventWindow = event.window, eventWindow == view.window else { return event }
            let location = view.convert(event.locationInWindow, from: nil)
            if !view.bounds.contains(location) {
                if onClickOutside(event) == .dismiss { return nil }
            }
            return event
        }
    }

    public func monitorEscape(onEscape: @escaping (NSEvent) -> DismissAction) {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // Escape
                if onEscape(event) == .dismiss { return nil }
            }
            return event
        }
    }

    public func stopMonitoring() {
        if let m = clickMonitor { NSEvent.removeMonitor(m); clickMonitor = nil }
        if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
    }

    deinit { stopMonitoring() }
}
