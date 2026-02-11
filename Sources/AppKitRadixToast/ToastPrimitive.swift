import AppKit
import AppKitRadixCore
import AppKitRadixBehaviors
import Combine

/// Toast — Temporary auto-dismissing notification.
///
/// Radix UI equivalent: `@radix-ui/react-toast`
public enum ToastPrimitive {

    public enum Position { case topLeft, topRight, bottomLeft, bottomRight }
    public enum ToastType { case foreground, background }

    public struct ToastData: Identifiable {
        public let id: String
        public var title: String
        public var description: String?
        public var duration: TimeInterval
        public var type: ToastType
        public init(id: String = UUID().uuidString, title: String, description: String? = nil, duration: TimeInterval = 5, type: ToastType = .foreground) {
            self.id = id; self.title = title; self.description = description; self.duration = duration; self.type = type
        }
    }

    public final class Provider: ObservableObject {
        public static let shared = Provider()
        @Published public var toasts: [ToastData] = []
        public var maxVisible: Int = 5
        public var position: Position = .bottomRight
        public func show(_ toast: ToastData) { toasts.append(toast); if toasts.count > maxVisible { toasts.removeFirst() } }
        public func dismiss(id: String) { toasts.removeAll { $0.id == id } }
        private init() {}
    }

    public final class Root: PrimitiveRoot {
        public var duration: TimeInterval = 5
        public var type: ToastType = .foreground
        public var toastId: String = UUID().uuidString
        private var dismissTimer: DispatchWorkItem?
        private var trackingArea: NSTrackingArea?

        override public func commonInit() {
            super.commonInit(); wantsLayer = true; layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
            layer?.cornerRadius = 8; layer?.shadowOpacity = 0.15; layer?.shadowRadius = 6
        }

        public func startDismissTimer() {
            guard duration > 0 else { return }
            let item = DispatchWorkItem { [weak self] in guard let self else { return }; Provider.shared.dismiss(id: self.toastId) }
            dismissTimer = item; DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: item)
        }

        override public func updateTrackingAreas() {
            super.updateTrackingAreas(); if let t = trackingArea { removeTrackingArea(t) }
            let t = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInActiveApp], owner: self)
            addTrackingArea(t); trackingArea = t
        }
        override public func mouseEntered(with event: NSEvent) { dismissTimer?.cancel() }
        override public func mouseExited(with event: NSEvent) { startDismissTimer() }
        override public func accessibilityRole() -> NSAccessibility.Role? { type == .foreground ? .group : .group }
    }

    public final class Title: PrimitiveView {
        public var text = "" { didSet { label.stringValue = text } }
        private let label: NSTextField = { let l = NSTextField(labelWithString: ""); l.translatesAutoresizingMaskIntoConstraints = false; l.font = .systemFont(ofSize: 13, weight: .semibold); return l }()
        override public func commonInit() { super.commonInit(); addSubview(label); NSLayoutConstraint.activate([label.leadingAnchor.constraint(equalTo: leadingAnchor), label.trailingAnchor.constraint(equalTo: trailingAnchor), label.topAnchor.constraint(equalTo: topAnchor), label.bottomAnchor.constraint(equalTo: bottomAnchor)]) }
        override public func accessibilityRole() -> NSAccessibility.Role? { .staticText }
    }

    public final class Description: PrimitiveView {
        public var text = "" { didSet { label.stringValue = text } }
        private let label: NSTextField = { let l = NSTextField(labelWithString: ""); l.translatesAutoresizingMaskIntoConstraints = false; l.font = .systemFont(ofSize: 12); l.textColor = .secondaryLabelColor; return l }()
        override public func commonInit() { super.commonInit(); addSubview(label); NSLayoutConstraint.activate([label.leadingAnchor.constraint(equalTo: leadingAnchor), label.trailingAnchor.constraint(equalTo: trailingAnchor), label.topAnchor.constraint(equalTo: topAnchor), label.bottomAnchor.constraint(equalTo: bottomAnchor)]) }
    }

    public final class Action: PrimitiveView {
        public var title = "Action" { didSet { btn.title = title } }
        public var onAction: (() -> Void)?
        private let btn: NSButton = { let b = NSButton(title: "Action", target: nil, action: nil); b.translatesAutoresizingMaskIntoConstraints = false; b.bezelStyle = .rounded; return b }()
        override public func commonInit() { super.commonInit(); btn.target = self; btn.action = #selector(tap); addSubview(btn); NSLayoutConstraint.activate([btn.leadingAnchor.constraint(equalTo: leadingAnchor), btn.trailingAnchor.constraint(equalTo: trailingAnchor), btn.topAnchor.constraint(equalTo: topAnchor), btn.bottomAnchor.constraint(equalTo: bottomAnchor)]) }
        @objc private func tap() { onAction?() }
        override public func accessibilityRole() -> NSAccessibility.Role? { .button }
    }

    public final class Close: PrimitiveView {
        public var toastId: String = ""
        private let btn: NSButton = { let b = NSButton(title: "×", target: nil, action: nil); b.translatesAutoresizingMaskIntoConstraints = false; b.bezelStyle = .rounded; b.isBordered = false; return b }()
        override public func commonInit() { super.commonInit(); btn.target = self; btn.action = #selector(tap); addSubview(btn); NSLayoutConstraint.activate([btn.leadingAnchor.constraint(equalTo: leadingAnchor), btn.trailingAnchor.constraint(equalTo: trailingAnchor), btn.topAnchor.constraint(equalTo: topAnchor), btn.bottomAnchor.constraint(equalTo: bottomAnchor)]) }
        @objc private func tap() { Provider.shared.dismiss(id: toastId) }
        override public func accessibilityRole() -> NSAccessibility.Role? { .button }
    }

    public final class Viewport: PrimitiveView {
        override public func commonInit() { super.commonInit() }
        override public func accessibilityRole() -> NSAccessibility.Role? { .group }
    }
}
