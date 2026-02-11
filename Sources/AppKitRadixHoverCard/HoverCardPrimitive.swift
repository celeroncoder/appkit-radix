import AppKit
import AppKitRadixCore
import AppKitRadixBehaviors
import Combine

/// HoverCard — Preview card appearing on hover over a trigger.
///
/// Radix UI equivalent: `@radix-ui/react-hover-card`
public enum HoverCardPrimitive {

    private enum CK { static let isOpen = "hoverCardOpen" }

    public final class Root: PrimitiveRoot, OpenStateManaging {
        @Published private var _isOpen = false
        public var defaultOpen = false
        public var onOpenChange: ((Bool) -> Void)?
        public var openDelay: TimeInterval = 0.7
        public var closeDelay: TimeInterval = 0.3
        public var isOpen: Bool { _isOpen }
        public var isOpenPublisher: AnyPublisher<Bool, Never> { $_isOpen.eraseToAnyPublisher() }
        public func setOpen(_ open: Bool) { _isOpen = open; componentContext?.setState(open, for: CK.isOpen); onOpenChange?(open) }
        public init(defaultOpen: Bool = false, id: String = UUID().uuidString) { self.defaultOpen = defaultOpen; super.init(id: id) }
        @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }
    }

    public final class Trigger: PrimitiveView {
        private var trackingArea: NSTrackingArea?
        private var openTimer: DispatchWorkItem?
        private var closeTimer: DispatchWorkItem?
        override public func updateTrackingAreas() {
            super.updateTrackingAreas(); if let t = trackingArea { removeTrackingArea(t) }
            let t = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInActiveApp], owner: self)
            addTrackingArea(t); trackingArea = t
        }
        override public func mouseEntered(with event: NSEvent) {
            closeTimer?.cancel()
            let delay = findRoot()?.openDelay ?? 0.7
            let item = DispatchWorkItem { [weak self] in self?.findRoot()?.setOpen(true) }
            openTimer = item; DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
        }
        override public func mouseExited(with event: NSEvent) {
            openTimer?.cancel()
            let delay = findRoot()?.closeDelay ?? 0.3
            let item = DispatchWorkItem { [weak self] in self?.findRoot()?.setOpen(false) }
            closeTimer = item; DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
        }
        private func findRoot() -> Root? { var v: NSView? = superview; while let w = v { if let r = w as? Root { return r }; v = w.superview }; return nil }
    }

    public final class Content: PrimitiveView {
        private let presence = Presence(isPresent: false)
        private var trackingArea: NSTrackingArea?
        private var closeTimer: DispatchWorkItem?
        override public func commonInit() {
            super.commonInit(); wantsLayer = true; layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
            layer?.cornerRadius = 8; layer?.borderWidth = 0.5; layer?.borderColor = NSColor.separatorColor.cgColor
            layer?.shadowOpacity = 0.15; layer?.shadowRadius = 8; isHidden = true
            presence.$isMounted.removeDuplicates().sink { [weak self] m in self?.isHidden = !m }.store(in: &cancellables)
        }
        override public func didAttachToComponent() {
            super.didAttachToComponent()
            componentContext?.publisher(for: CK.isOpen, default: false).sink { [weak self] (o: Bool) in self?.presence.isPresent = o }.store(in: &cancellables)
        }
        override public func updateTrackingAreas() {
            super.updateTrackingAreas(); if let t = trackingArea { removeTrackingArea(t) }
            let t = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInActiveApp], owner: self)
            addTrackingArea(t); trackingArea = t
        }
        override public func mouseEntered(with event: NSEvent) { closeTimer?.cancel() }
        override public func mouseExited(with event: NSEvent) {
            let delay = findRoot()?.closeDelay ?? 0.3
            let item = DispatchWorkItem { [weak self] in self?.findRoot()?.setOpen(false) }
            closeTimer = item; DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
        }
        private func findRoot() -> Root? { var v: NSView? = superview; while let w = v { if let r = w as? Root { return r }; v = w.superview }; return nil }
        override public func accessibilityRole() -> NSAccessibility.Role? { .group }
    }

    public final class Arrow: PrimitiveView {
        override public func commonInit() { super.commonInit(); wantsLayer = true; let w = widthAnchor.constraint(equalToConstant: 12); let h = heightAnchor.constraint(equalToConstant: 6); w.isActive = true; h.isActive = true }
    }
}
