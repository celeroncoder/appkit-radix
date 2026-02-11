import AppKit

public final class RovingFocusGroup {
    public enum Orientation { case horizontal, vertical, both }

    public var orientation: Orientation = .horizontal
    public var loop: Bool = true

    private var items: [WeakViewRef] = []
    private var keyMonitor: Any?

    public init() {}

    public func register(_ view: NSView) {
        items.append(WeakViewRef(view))
        cleanup()
    }

    public func unregister(_ view: NSView) {
        items.removeAll { $0.view === view }
    }

    public func install(on container: NSView) {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self, weak container] event in
            guard let self, container != nil else { return event }
            return self.handleKey(event) ? nil : event
        }
    }

    private func handleKey(_ event: NSEvent) -> Bool {
        let views = items.compactMap(\.view)
        guard !views.isEmpty else { return false }
        guard let current = views.first(where: { $0.window?.firstResponder === $0 }),
              let idx = views.firstIndex(of: current) else { return false }

        var next: Int?
        switch event.keyCode {
        case 123 where orientation != .vertical:  next = prev(idx, views.count)
        case 124 where orientation != .vertical:  next = self.next(idx, views.count)
        case 125 where orientation != .horizontal: next = self.next(idx, views.count)
        case 126 where orientation != .horizontal: next = prev(idx, views.count)
        default: return false
        }

        if let i = next { views[i].window?.makeFirstResponder(views[i]); return true }
        return false
    }

    private func next(_ i: Int, _ count: Int) -> Int? {
        i + 1 < count ? i + 1 : (loop ? 0 : nil)
    }

    private func prev(_ i: Int, _ count: Int) -> Int? {
        i - 1 >= 0 ? i - 1 : (loop ? count - 1 : nil)
    }

    private func cleanup() { items.removeAll { $0.view == nil } }

    deinit { if let m = keyMonitor { NSEvent.removeMonitor(m) } }
}

private final class WeakViewRef {
    weak var view: NSView?
    init(_ view: NSView) { self.view = view }
}
