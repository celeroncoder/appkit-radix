import AppKit
import AppKitRadixCore
import AppKitRadixBehaviors
import Combine

/// Dialog — Modal window overlaid on primary content with focus trap.
///
/// Radix UI equivalent: `@radix-ui/react-dialog`
public enum DialogPrimitive {

    private enum CK { static let isOpen = "dialogOpen" }

    // MARK: - Root

    public final class Root: PrimitiveRoot, OpenStateManaging {

        @Published private var _isOpen = false
        public var defaultOpen = false
        public var onOpenChange: ((Bool) -> Void)?

        public var isOpen: Bool { _isOpen }
        public var isOpenPublisher: AnyPublisher<Bool, Never> { $_isOpen.eraseToAnyPublisher() }

        public func setOpen(_ open: Bool) {
            _isOpen = open
            componentContext?.setState(open, for: CK.isOpen)
            onOpenChange?(open)
        }

        public init(defaultOpen: Bool = false, id: String = UUID().uuidString) {
            self.defaultOpen = defaultOpen
            super.init(id: id)
            if defaultOpen { setOpen(true) }
        }

        @available(*, unavailable)
        public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

        override public func accessibilityRole() -> NSAccessibility.Role? { .group }
    }

    // MARK: - Trigger

    public final class Trigger: PrimitiveView {

        public var title: String = "" { didSet { button.title = title } }

        private let button: NSButton = {
            let b = NSButton(title: "Open", target: nil, action: nil)
            b.translatesAutoresizingMaskIntoConstraints = false
            b.bezelStyle = .rounded
            return b
        }()

        override public func commonInit() {
            super.commonInit()
            button.target = self; button.action = #selector(handleClick)
            addSubview(button)
            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: leadingAnchor),
                button.trailingAnchor.constraint(equalTo: trailingAnchor),
                button.topAnchor.constraint(equalTo: topAnchor),
                button.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }

        @objc private func handleClick() {
            guard let root = findRoot() else { return }
            root.setOpen(!root.isOpen)
        }

        private func findRoot() -> Root? {
            var v: NSView? = superview
            while let view = v { if let r = view as? Root { return r }; v = view.superview }
            return nil
        }

        override public func accessibilityRole() -> NSAccessibility.Role? { .button }
        override public func accessibilityLabel() -> String? { title.isEmpty ? "Open" : title }
    }

    // MARK: - Overlay

    public final class Overlay: PrimitiveView {

        private let presence = Presence(isPresent: false)

        override public func commonInit() {
            super.commonInit()
            wantsLayer = true
            layer?.backgroundColor = NSColor.black.withAlphaComponent(0.4).cgColor
            isHidden = true
            presence.$isMounted.removeDuplicates()
                .sink { [weak self] m in self?.isHidden = !m }
                .store(in: &cancellables)
        }

        override public func didAttachToComponent() {
            super.didAttachToComponent()
            componentContext?.publisher(for: CK.isOpen, default: false)
                .sink { [weak self] (open: Bool) in self?.presence.isPresent = open }
                .store(in: &cancellables)
        }

        override public func mouseDown(with event: NSEvent) {
            // Click on overlay closes dialog
            if let root = findRoot() { root.setOpen(false) }
        }

        private func findRoot() -> Root? {
            var v: NSView? = superview
            while let view = v { if let r = view as? Root { return r }; v = view.superview }
            return nil
        }
    }

    // MARK: - Content

    public final class Content: PrimitiveView, DismissableContent, FocusManaging {

        public var onEscapeKeyDown: ((NSEvent) -> DismissAction)?
        public var onClickOutside: ((NSEvent) -> DismissAction)?
        public var onInteractOutside: ((NSEvent) -> DismissAction)?
        public var onOpenAutoFocus: ((inout Bool) -> Void)?
        public var onCloseAutoFocus: ((inout Bool) -> Void)?
        public var trapFocus: Bool = true
        public var restoreFocusOnClose: Bool = true

        private let focusScope = FocusScope()
        private let dismissRegion = DismissableRegion()
        private let presence = Presence(isPresent: false)

        override public func commonInit() {
            super.commonInit()
            wantsLayer = true
            layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
            layer?.cornerRadius = 12
            layer?.shadowOpacity = 0.3; layer?.shadowRadius = 20
            isHidden = true
            presence.$isMounted.removeDuplicates()
                .sink { [weak self] m in
                    self?.isHidden = !m
                    if m { self?.onOpen() } else { self?.onClose() }
                }
                .store(in: &cancellables)
        }

        override public func didAttachToComponent() {
            super.didAttachToComponent()
            componentContext?.publisher(for: CK.isOpen, default: false)
                .sink { [weak self] (open: Bool) in self?.presence.isPresent = open }
                .store(in: &cancellables)
        }

        private func onOpen() {
            if trapFocus { focusScope.trap(in: self) }
            dismissRegion.monitorEscape { [weak self] event in
                let action = self?.onEscapeKeyDown?(event) ?? .dismiss
                if action == .dismiss { self?.findRoot()?.setOpen(false) }
                return action
            }
            AccessibilityHelpers.postLayoutChanged(focusedElement: self)
        }

        private func onClose() {
            focusScope.release()
            dismissRegion.stopMonitoring()
        }

        private func findRoot() -> Root? {
            var v: NSView? = superview
            while let view = v { if let r = view as? Root { return r }; v = view.superview }
            return nil
        }

        override public func accessibilityRole() -> NSAccessibility.Role? { .sheet }
    }

    // MARK: - Close

    public final class Close: PrimitiveView {

        public var title: String = "Close" { didSet { button.title = title } }

        private let button: NSButton = {
            let b = NSButton(title: "Close", target: nil, action: nil)
            b.translatesAutoresizingMaskIntoConstraints = false; b.bezelStyle = .rounded
            return b
        }()

        override public func commonInit() {
            super.commonInit()
            button.target = self; button.action = #selector(handleClick)
            addSubview(button)
            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: leadingAnchor),
                button.trailingAnchor.constraint(equalTo: trailingAnchor),
                button.topAnchor.constraint(equalTo: topAnchor),
                button.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }

        @objc private func handleClick() {
            var v: NSView? = superview
            while let view = v { if let r = view as? Root { r.setOpen(false); return }; v = view.superview }
        }

        override public func accessibilityRole() -> NSAccessibility.Role? { .button }
    }

    // MARK: - Title

    public final class Title: PrimitiveView {
        public var text: String = "" { didSet { label.stringValue = text } }
        private let label: NSTextField = {
            let l = NSTextField(labelWithString: "")
            l.translatesAutoresizingMaskIntoConstraints = false; l.font = .systemFont(ofSize: 17, weight: .bold)
            return l
        }()
        override public func commonInit() {
            super.commonInit()
            addSubview(label)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: leadingAnchor),
                label.trailingAnchor.constraint(equalTo: trailingAnchor),
                label.topAnchor.constraint(equalTo: topAnchor),
                label.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }
        override public func accessibilityRole() -> NSAccessibility.Role? { .staticText }
    }

    // MARK: - Description

    public final class Description: PrimitiveView {
        public var text: String = "" { didSet { label.stringValue = text } }
        private let label: NSTextField = {
            let l = NSTextField(labelWithString: "")
            l.translatesAutoresizingMaskIntoConstraints = false; l.font = .systemFont(ofSize: 13)
            l.textColor = .secondaryLabelColor
            return l
        }()
        override public func commonInit() {
            super.commonInit()
            addSubview(label)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: leadingAnchor),
                label.trailingAnchor.constraint(equalTo: trailingAnchor),
                label.topAnchor.constraint(equalTo: topAnchor),
                label.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }
        override public func accessibilityRole() -> NSAccessibility.Role? { .staticText }
    }
}
