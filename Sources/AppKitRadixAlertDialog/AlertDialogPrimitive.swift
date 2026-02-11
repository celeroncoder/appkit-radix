import AppKit
import AppKitRadixCore
import AppKitRadixBehaviors
import Combine

/// AlertDialog — Blocking modal requiring user acknowledgment; no outside dismiss.
///
/// Radix UI equivalent: `@radix-ui/react-alert-dialog`
public enum AlertDialogPrimitive {

    private enum CK { static let isOpen = "alertOpen" }

    public final class Root: PrimitiveRoot, OpenStateManaging {
        @Published private var _isOpen = false
        public var defaultOpen = false
        public var onOpenChange: ((Bool) -> Void)?
        public var isOpen: Bool { _isOpen }
        public var isOpenPublisher: AnyPublisher<Bool, Never> { $_isOpen.eraseToAnyPublisher() }
        public func setOpen(_ open: Bool) {
            _isOpen = open; componentContext?.setState(open, for: CK.isOpen); onOpenChange?(open)
        }
        public init(defaultOpen: Bool = false, id: String = UUID().uuidString) {
            self.defaultOpen = defaultOpen; super.init(id: id)
            if defaultOpen { setOpen(true) }
        }
        @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }
        override public func accessibilityRole() -> NSAccessibility.Role? { .group }
    }

    public final class Trigger: PrimitiveView {
        public var title = "Open" { didSet { btn.title = title } }
        private let btn: NSButton = { let b = NSButton(title: "Open", target: nil, action: nil); b.translatesAutoresizingMaskIntoConstraints = false; b.bezelStyle = .rounded; return b }()
        override public func commonInit() {
            super.commonInit(); btn.target = self; btn.action = #selector(tap)
            addSubview(btn); NSLayoutConstraint.activate([btn.leadingAnchor.constraint(equalTo: leadingAnchor), btn.trailingAnchor.constraint(equalTo: trailingAnchor), btn.topAnchor.constraint(equalTo: topAnchor), btn.bottomAnchor.constraint(equalTo: bottomAnchor)])
        }
        @objc private func tap() { findRoot()?.setOpen(true) }
        private func findRoot() -> Root? { var v: NSView? = superview; while let w = v { if let r = w as? Root { return r }; v = w.superview }; return nil }
        override public func accessibilityRole() -> NSAccessibility.Role? { .button }
    }

    public final class Overlay: PrimitiveView {
        private let presence = Presence(isPresent: false)
        override public func commonInit() {
            super.commonInit(); wantsLayer = true; layer?.backgroundColor = NSColor.black.withAlphaComponent(0.5).cgColor; isHidden = true
            presence.$isMounted.removeDuplicates().sink { [weak self] m in self?.isHidden = !m }.store(in: &cancellables)
        }
        override public func didAttachToComponent() {
            super.didAttachToComponent()
            componentContext?.publisher(for: CK.isOpen, default: false).sink { [weak self] (o: Bool) in self?.presence.isPresent = o }.store(in: &cancellables)
        }
        // No click-to-dismiss for AlertDialog
    }

    public final class Content: PrimitiveView {
        private let focusScope = FocusScope()
        private let dismissRegion = DismissableRegion()
        private let presence = Presence(isPresent: false)
        override public func commonInit() {
            super.commonInit(); wantsLayer = true; layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
            layer?.cornerRadius = 12; layer?.shadowOpacity = 0.3; layer?.shadowRadius = 20; isHidden = true
            presence.$isMounted.removeDuplicates().sink { [weak self] m in
                self?.isHidden = !m; if m { self?.onOpen() } else { self?.onClose() }
            }.store(in: &cancellables)
        }
        override public func didAttachToComponent() {
            super.didAttachToComponent()
            componentContext?.publisher(for: CK.isOpen, default: false).sink { [weak self] (o: Bool) in self?.presence.isPresent = o }.store(in: &cancellables)
        }
        private func onOpen() {
            focusScope.trap(in: self)
            dismissRegion.monitorEscape { [weak self] _ in self?.findRoot()?.setOpen(false); return .dismiss }
            AccessibilityHelpers.postLayoutChanged(focusedElement: self)
            AccessibilityHelpers.announce("Alert", priority: .high)
        }
        private func onClose() { focusScope.release(); dismissRegion.stopMonitoring() }
        private func findRoot() -> Root? { var v: NSView? = superview; while let w = v { if let r = w as? Root { return r }; v = w.superview }; return nil }
        override public func accessibilityRole() -> NSAccessibility.Role? { .sheet }
    }

    public final class Title: PrimitiveView {
        public var text = "" { didSet { label.stringValue = text } }
        private let label: NSTextField = { let l = NSTextField(labelWithString: ""); l.translatesAutoresizingMaskIntoConstraints = false; l.font = .systemFont(ofSize: 17, weight: .bold); return l }()
        override public func commonInit() { super.commonInit(); addSubview(label); NSLayoutConstraint.activate([label.leadingAnchor.constraint(equalTo: leadingAnchor), label.trailingAnchor.constraint(equalTo: trailingAnchor), label.topAnchor.constraint(equalTo: topAnchor), label.bottomAnchor.constraint(equalTo: bottomAnchor)]) }
        override public func accessibilityRole() -> NSAccessibility.Role? { .staticText }
    }

    public final class Description: PrimitiveView {
        public var text = "" { didSet { label.stringValue = text } }
        private let label: NSTextField = { let l = NSTextField(labelWithString: ""); l.translatesAutoresizingMaskIntoConstraints = false; l.font = .systemFont(ofSize: 13); l.textColor = .secondaryLabelColor; return l }()
        override public func commonInit() { super.commonInit(); addSubview(label); NSLayoutConstraint.activate([label.leadingAnchor.constraint(equalTo: leadingAnchor), label.trailingAnchor.constraint(equalTo: trailingAnchor), label.topAnchor.constraint(equalTo: topAnchor), label.bottomAnchor.constraint(equalTo: bottomAnchor)]) }
        override public func accessibilityRole() -> NSAccessibility.Role? { .staticText }
    }

    public final class Cancel: PrimitiveView {
        public var title = "Cancel" { didSet { btn.title = title } }
        private let btn: NSButton = { let b = NSButton(title: "Cancel", target: nil, action: nil); b.translatesAutoresizingMaskIntoConstraints = false; b.bezelStyle = .rounded; return b }()
        override public func commonInit() { super.commonInit(); btn.target = self; btn.action = #selector(tap); addSubview(btn); NSLayoutConstraint.activate([btn.leadingAnchor.constraint(equalTo: leadingAnchor), btn.trailingAnchor.constraint(equalTo: trailingAnchor), btn.topAnchor.constraint(equalTo: topAnchor), btn.bottomAnchor.constraint(equalTo: bottomAnchor)]) }
        @objc private func tap() { var v: NSView? = superview; while let w = v { if let r = w as? Root { r.setOpen(false); return }; v = w.superview } }
        override public func accessibilityRole() -> NSAccessibility.Role? { .button }
    }

    public final class Action: PrimitiveView {
        public var title = "Confirm" { didSet { btn.title = title } }
        public var onAction: (() -> Void)?
        private let btn: NSButton = { let b = NSButton(title: "Confirm", target: nil, action: nil); b.translatesAutoresizingMaskIntoConstraints = false; b.bezelStyle = .rounded; return b }()
        override public func commonInit() { super.commonInit(); btn.target = self; btn.action = #selector(tap); addSubview(btn); NSLayoutConstraint.activate([btn.leadingAnchor.constraint(equalTo: leadingAnchor), btn.trailingAnchor.constraint(equalTo: trailingAnchor), btn.topAnchor.constraint(equalTo: topAnchor), btn.bottomAnchor.constraint(equalTo: bottomAnchor)]) }
        @objc private func tap() { onAction?(); var v: NSView? = superview; while let w = v { if let r = w as? Root { r.setOpen(false); return }; v = w.superview } }
        override public func accessibilityRole() -> NSAccessibility.Role? { .button }
    }
}
