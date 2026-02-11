import AppKit
import AppKitRadixCore
import AppKitRadixBehaviors
import Combine

/// Popover — Floating panel anchored to a trigger element.
///
/// Radix UI equivalent: `@radix-ui/react-popover`
public enum PopoverPrimitive {

    private enum CK { static let isOpen = "popoverOpen" }

    public final class Root: PrimitiveRoot, OpenStateManaging {
        @Published private var _isOpen = false
        public var defaultOpen = false
        public var onOpenChange: ((Bool) -> Void)?
        public var positioning = PositioningConfiguration()
        public var isOpen: Bool { _isOpen }
        public var isOpenPublisher: AnyPublisher<Bool, Never> { $_isOpen.eraseToAnyPublisher() }
        public func setOpen(_ open: Bool) { _isOpen = open; componentContext?.setState(open, for: CK.isOpen); onOpenChange?(open) }
        public init(defaultOpen: Bool = false, id: String = UUID().uuidString) { self.defaultOpen = defaultOpen; super.init(id: id) }
        @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }
        override public func accessibilityRole() -> NSAccessibility.Role? { .group }
    }

    public final class Trigger: PrimitiveView {
        public var title = "" { didSet { btn.title = title } }
        private let btn: NSButton = { let b = NSButton(title: "", target: nil, action: nil); b.translatesAutoresizingMaskIntoConstraints = false; b.bezelStyle = .rounded; return b }()
        override public func commonInit() {
            super.commonInit(); btn.target = self; btn.action = #selector(tap)
            addSubview(btn); NSLayoutConstraint.activate([btn.leadingAnchor.constraint(equalTo: leadingAnchor), btn.trailingAnchor.constraint(equalTo: trailingAnchor), btn.topAnchor.constraint(equalTo: topAnchor), btn.bottomAnchor.constraint(equalTo: bottomAnchor)])
        }
        @objc private func tap() { guard let r = findRoot() else { return }; r.setOpen(!r.isOpen) }
        private func findRoot() -> Root? { var v: NSView? = superview; while let w = v { if let r = w as? Root { return r }; v = w.superview }; return nil }
        override public func accessibilityRole() -> NSAccessibility.Role? { .button }
    }

    public final class Anchor: PrimitiveView {}

    public final class Content: PrimitiveView {
        private let dismissRegion = DismissableRegion()
        private let presence = Presence(isPresent: false)
        public var onEscapeKeyDown: ((NSEvent) -> DismissAction)?
        public var onClickOutside: ((NSEvent) -> DismissAction)?
        override public func commonInit() {
            super.commonInit(); wantsLayer = true; layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
            layer?.cornerRadius = 8; layer?.borderWidth = 0.5; layer?.borderColor = NSColor.separatorColor.cgColor
            layer?.shadowOpacity = 0.2; layer?.shadowRadius = 8; isHidden = true
            presence.$isMounted.removeDuplicates().sink { [weak self] m in
                self?.isHidden = !m; if m { self?.onOpen() } else { self?.onClose() }
            }.store(in: &cancellables)
        }
        override public func didAttachToComponent() {
            super.didAttachToComponent()
            componentContext?.publisher(for: CK.isOpen, default: false).sink { [weak self] (o: Bool) in self?.presence.isPresent = o }.store(in: &cancellables)
        }
        private func onOpen() {
            dismissRegion.monitorEscape { [weak self] e in let a = self?.onEscapeKeyDown?(e) ?? .dismiss; if a == .dismiss { self?.findRoot()?.setOpen(false) }; return a }
            dismissRegion.monitor(view: self) { [weak self] e in let a = self?.onClickOutside?(e) ?? .dismiss; if a == .dismiss { self?.findRoot()?.setOpen(false) }; return a }
        }
        private func onClose() { dismissRegion.stopMonitoring() }
        private func findRoot() -> Root? { var v: NSView? = superview; while let w = v { if let r = w as? Root { return r }; v = w.superview }; return nil }
        override public func accessibilityRole() -> NSAccessibility.Role? { .popover }
    }

    public final class Arrow: PrimitiveView {
        override public func commonInit() { super.commonInit(); wantsLayer = true; let w = widthAnchor.constraint(equalToConstant: 12); let h = heightAnchor.constraint(equalToConstant: 6); w.isActive = true; h.isActive = true }
        override public func draw(_ dirtyRect: NSRect) {
            let path = NSBezierPath(); path.move(to: NSPoint(x: 0, y: 0)); path.line(to: NSPoint(x: bounds.midX, y: bounds.maxY)); path.line(to: NSPoint(x: bounds.maxX, y: 0)); path.close()
            NSColor.windowBackgroundColor.setFill(); path.fill()
        }
    }

    public final class Close: PrimitiveView {
        public var title = "Close" { didSet { btn.title = title } }
        private let btn: NSButton = { let b = NSButton(title: "Close", target: nil, action: nil); b.translatesAutoresizingMaskIntoConstraints = false; b.bezelStyle = .rounded; return b }()
        override public func commonInit() { super.commonInit(); btn.target = self; btn.action = #selector(tap); addSubview(btn); NSLayoutConstraint.activate([btn.leadingAnchor.constraint(equalTo: leadingAnchor), btn.trailingAnchor.constraint(equalTo: trailingAnchor), btn.topAnchor.constraint(equalTo: topAnchor), btn.bottomAnchor.constraint(equalTo: bottomAnchor)]) }
        @objc private func tap() { var v: NSView? = superview; while let w = v { if let r = w as? Root { r.setOpen(false); return }; v = w.superview } }
        override public func accessibilityRole() -> NSAccessibility.Role? { .button }
    }
}
