import AppKit
import AppKitRadixCore
import AppKitRadixBehaviors
import Combine

/// Collapsible — Single show/hide section.
///
/// Radix UI equivalent: `@radix-ui/react-collapsible`
public enum CollapsiblePrimitive {

    private enum CK { static let isOpen = "isOpen" }

    // MARK: - Root

    public final class Root: PrimitiveRoot, OpenStateManaging {

        @Published private var _isOpen: Bool = false

        public var defaultOpen: Bool = false
        public var onOpenChange: ((Bool) -> Void)?
        public var isDisabled: Bool = false { didSet { componentContext?.isDisabled = isDisabled } }

        public var isOpen: Bool { _isOpen }
        public var isOpenPublisher: AnyPublisher<Bool, Never> { $_isOpen.eraseToAnyPublisher() }

        public func setOpen(_ open: Bool) {
            guard !isDisabled else { return }
            _isOpen = open
            componentContext?.setState(open, for: CK.isOpen)
            onOpenChange?(open)
        }

        private let stackView: NSStackView = {
            let s = NSStackView()
            s.orientation = .vertical; s.alignment = .leading; s.spacing = 0
            s.translatesAutoresizingMaskIntoConstraints = false
            return s
        }()

        public init(defaultOpen: Bool = false, id: String = UUID().uuidString) {
            self.defaultOpen = defaultOpen
            super.init(id: id)
            _isOpen = defaultOpen
            componentContext?.setState(defaultOpen, for: CK.isOpen)
        }

        @available(*, unavailable)
        public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

        override public func commonInit() {
            super.commonInit()
            addSubview(stackView)
            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: topAnchor),
                stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
                stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }

        public func addArrangedSubview(_ view: NSView) { stackView.addArrangedSubview(view) }

        override public func accessibilityRole() -> NSAccessibility.Role? { .group }
    }

    // MARK: - Trigger

    public final class Trigger: PrimitiveView {

        public var title: String = "" {
            didSet { titleLabel.stringValue = title; setAccessibilityLabel(title) }
        }

        private let titleLabel: NSTextField = {
            let l = NSTextField(labelWithString: "")
            l.translatesAutoresizingMaskIntoConstraints = false
            l.isEditable = false; l.isBordered = false; l.drawsBackground = false
            l.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .medium)
            return l
        }()

        override public var primitiveAccessibilityRole: NSAccessibility.Role { .button }

        override public func commonInit() {
            super.commonInit()
            addSubview(titleLabel)
            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
                titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
                titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
                titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            ])
            setAccessibilitySubrole(.toggle)
        }

        override public func didAttachToComponent() {
            super.didAttachToComponent()
            componentContext?.publisher(for: CK.isOpen, default: false)
                .sink { [weak self] (open: Bool) in self?.setAccessibilityExpanded(open) }
                .store(in: &cancellables)
        }

        override public var acceptsFirstResponder: Bool { true }

        override public func mouseDown(with event: NSEvent) {
            guard let root = findRoot(), !root.isDisabled else { return }
            root.setOpen(!root.isOpen)
        }

        override public func keyDown(with event: NSEvent) {
            if event.keyCode == 49 || event.keyCode == 36 {
                guard let root = findRoot(), !root.isDisabled else { return }
                root.setOpen(!root.isOpen)
            } else { super.keyDown(with: event) }
        }

        private func findRoot() -> Root? {
            var v: NSView? = superview
            while let view = v { if let r = view as? Root { return r }; v = view.superview }
            return nil
        }

        override public func accessibilityLabel() -> String? { title }
    }

    // MARK: - Content

    public final class Content: PrimitiveView {

        public var forceMount: Bool = false { didSet { presence.forceMount = forceMount } }

        private let presence = Presence(isPresent: false)

        override public func commonInit() {
            super.commonInit()
            isHidden = true
            presence.$isMounted.removeDuplicates()
                .sink { [weak self] m in
                    self?.isHidden = !m
                    if m { AccessibilityHelpers.postLayoutChanged(focusedElement: self) }
                }
                .store(in: &cancellables)
        }

        override public func didAttachToComponent() {
            super.didAttachToComponent()
            componentContext?.publisher(for: CK.isOpen, default: false)
                .sink { [weak self] (open: Bool) in self?.presence.isPresent = open }
                .store(in: &cancellables)
        }

        override public func accessibilityRole() -> NSAccessibility.Role? { .group }
    }
}
