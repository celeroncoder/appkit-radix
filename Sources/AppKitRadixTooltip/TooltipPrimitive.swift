import AppKit
import AppKitRadixCore
import AppKitRadixBehaviors
import Combine

/// Tooltip — Small informational popup on hover/focus.
///
/// Radix UI equivalent: `@radix-ui/react-tooltip`
public enum TooltipPrimitive {

    private enum CK { static let isOpen = "tooltipOpen" }

    public final class Provider {
        public static let shared = Provider()
        public var delayDuration: TimeInterval = 0.7
        public var skipDelayDuration: TimeInterval = 0.3
        private(set) weak var currentTooltip: Root?
        func setCurrent(_ root: Root?) { currentTooltip = root }
        private init() {}
    }

    public final class Root: PrimitiveRoot, OpenStateManaging {
        @Published private var _isOpen = false
        public var defaultOpen = false
        public var onOpenChange: ((Bool) -> Void)?
        public var isOpen: Bool { _isOpen }
        public var isOpenPublisher: AnyPublisher<Bool, Never> { $_isOpen.eraseToAnyPublisher() }
        public func setOpen(_ open: Bool) {
            _isOpen = open; componentContext?.setState(open, for: CK.isOpen); onOpenChange?(open)
            if open { Provider.shared.setCurrent(self) } else if Provider.shared.currentTooltip === self { Provider.shared.setCurrent(nil) }
        }
        public init(defaultOpen: Bool = false, id: String = UUID().uuidString) { self.defaultOpen = defaultOpen; super.init(id: id) }
        @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }
    }

    public final class Trigger: PrimitiveView {
        private var trackingArea: NSTrackingArea?
        private var openTimer: DispatchWorkItem?
        override public func commonInit() { super.commonInit() }
        override public func updateTrackingAreas() {
            super.updateTrackingAreas()
            if let t = trackingArea { removeTrackingArea(t) }
            let t = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInActiveApp], owner: self)
            addTrackingArea(t); trackingArea = t
        }
        override public func mouseEntered(with event: NSEvent) {
            openTimer?.cancel()
            let delay = Provider.shared.currentTooltip != nil ? Provider.shared.skipDelayDuration : Provider.shared.delayDuration
            let item = DispatchWorkItem { [weak self] in self?.findRoot()?.setOpen(true) }
            openTimer = item; DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
        }
        override public func mouseExited(with event: NSEvent) { openTimer?.cancel(); findRoot()?.setOpen(false) }
        override public func mouseDown(with event: NSEvent) { openTimer?.cancel(); findRoot()?.setOpen(false); super.mouseDown(with: event) }
        private func findRoot() -> Root? { var v: NSView? = superview; while let w = v { if let r = w as? Root { return r }; v = w.superview }; return nil }
    }

    public final class Content: PrimitiveView {
        public var text: String = "" { didSet { label.stringValue = text } }
        private let presence = Presence(isPresent: false)
        private let label: NSTextField = { let l = NSTextField(labelWithString: ""); l.translatesAutoresizingMaskIntoConstraints = false; l.font = .systemFont(ofSize: 11); l.isBordered = false; l.drawsBackground = false; return l }()
        override public func commonInit() {
            super.commonInit(); wantsLayer = true; layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
            layer?.cornerRadius = 4; layer?.borderWidth = 0.5; layer?.borderColor = NSColor.separatorColor.cgColor
            layer?.shadowOpacity = 0.1; layer?.shadowRadius = 4; isHidden = true
            addSubview(label); NSLayoutConstraint.activate([label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8), label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8), label.topAnchor.constraint(equalTo: topAnchor, constant: 4), label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)])
            presence.$isMounted.removeDuplicates().sink { [weak self] m in self?.isHidden = !m }.store(in: &cancellables)
        }
        override public func didAttachToComponent() {
            super.didAttachToComponent()
            componentContext?.publisher(for: CK.isOpen, default: false).sink { [weak self] (o: Bool) in self?.presence.isPresent = o }.store(in: &cancellables)
        }
        override public func accessibilityRole() -> NSAccessibility.Role? { .helpTag }
    }
}
