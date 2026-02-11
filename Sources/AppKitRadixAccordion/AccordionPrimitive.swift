import AppKit
import AppKitRadixCore
import AppKitRadixBehaviors
import Combine

/// Accordion — Vertically stacked collapsible sections.
///
/// Radix UI equivalent: `@radix-ui/react-accordion`
public enum AccordionPrimitive {

    public enum AccordionType { case single, multiple }
    private enum CK {
        static let expandedValue = "expandedValue"
        static let expandedValues = "expandedValues"
    }

    // MARK: - Root

    public final class Root: PrimitiveRoot {

        public var type: AccordionType = .single
        public var collapsible: Bool = true
        public var isDisabled: Bool = false { didSet { componentContext?.isDisabled = isDisabled } }
        public var onValueChange: ((Any) -> Void)?

        private let stackView: NSStackView = {
            let s = NSStackView(); s.orientation = .vertical; s.alignment = .leading; s.spacing = 0
            s.translatesAutoresizingMaskIntoConstraints = false; return s
        }()

        private let rovingFocus = RovingFocusGroup()

        public init(type: AccordionType = .single, id: String = UUID().uuidString) {
            self.type = type
            super.init(id: id)
            if type == .single {
                componentContext?.setState(Optional<String>.none, for: CK.expandedValue)
            } else {
                componentContext?.setState(Set<String>(), for: CK.expandedValues)
            }
        }

        @available(*, unavailable)
        public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

        override public func commonInit() {
            super.commonInit()
            rovingFocus.orientation = .vertical
            rovingFocus.install(on: self)
            addSubview(stackView)
            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: topAnchor),
                stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
                stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }

        public func addItem(_ view: NSView) { stackView.addArrangedSubview(view) }

        func registerTrigger(_ view: NSView) { rovingFocus.register(view) }

        func toggleItem(_ value: String) {
            guard !isDisabled else { return }
            if type == .single {
                let current: String? = componentContext?.state(for: CK.expandedValue, default: nil)
                let newVal: String? = (current == value && collapsible) ? nil : value
                componentContext?.setState(newVal, for: CK.expandedValue)
                onValueChange?(newVal as Any)
            } else {
                var set: Set<String> = componentContext?.state(for: CK.expandedValues, default: Set<String>()) ?? []
                if set.contains(value) { set.remove(value) } else { set.insert(value) }
                componentContext?.setState(set, for: CK.expandedValues)
                onValueChange?(set)
            }
        }

        func isExpanded(_ value: String) -> Bool {
            if type == .single {
                return componentContext?.state(for: CK.expandedValue, default: Optional<String>.none) == value
            } else {
                let set: Set<String> = componentContext?.state(for: CK.expandedValues, default: Set<String>()) ?? []
                return set.contains(value)
            }
        }

        override public func accessibilityRole() -> NSAccessibility.Role? { .group }
    }

    // MARK: - Item

    public final class Item: PrimitiveView {
        public let value: String
        private let stack: NSStackView = {
            let s = NSStackView(); s.orientation = .vertical; s.alignment = .leading; s.spacing = 0
            s.translatesAutoresizingMaskIntoConstraints = false; return s
        }()

        public init(value: String) {
            self.value = value
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

        override public func commonInit() {
            super.commonInit()
            addSubview(stack)
            NSLayoutConstraint.activate([
                stack.topAnchor.constraint(equalTo: topAnchor),
                stack.leadingAnchor.constraint(equalTo: leadingAnchor),
                stack.trailingAnchor.constraint(equalTo: trailingAnchor),
                stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }

        public func addArrangedSubview(_ view: NSView) { stack.addArrangedSubview(view) }
        override public func accessibilityRole() -> NSAccessibility.Role? { .group }
    }

    // MARK: - Header

    public final class Header: PrimitiveView {
        override public func accessibilityRole() -> NSAccessibility.Role? { .group }
    }

    // MARK: - Trigger

    public final class Trigger: PrimitiveView {

        public var title: String = "" { didSet { label.stringValue = title } }
        public weak var item: Item?

        private let label: NSTextField = {
            let l = NSTextField(labelWithString: "")
            l.translatesAutoresizingMaskIntoConstraints = false; l.isEditable = false
            l.isBordered = false; l.drawsBackground = false
            l.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .medium)
            return l
        }()

        override public func commonInit() {
            super.commonInit()
            addSubview(label)
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: topAnchor, constant: 8),
                label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
                label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
                label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            ])
        }

        override public func didAttachToComponent() {
            super.didAttachToComponent()
            if let root = findRoot() { root.registerTrigger(self) }
        }

        override public var acceptsFirstResponder: Bool { true }

        override public func mouseDown(with event: NSEvent) {
            guard let item, let root = findRoot(), !root.isDisabled else { return }
            root.toggleItem(item.value)
        }

        override public func keyDown(with event: NSEvent) {
            if event.keyCode == 49 || event.keyCode == 36 {
                guard let item, let root = findRoot(), !root.isDisabled else { return }
                root.toggleItem(item.value)
            } else { super.keyDown(with: event) }
        }

        private func findRoot() -> Root? {
            var v: NSView? = superview
            while let view = v { if let r = view as? Root { return r }; v = view.superview }
            return nil
        }

        override public func accessibilityRole() -> NSAccessibility.Role? { .button }
        override public func accessibilityLabel() -> String? { title }
    }

    // MARK: - Content

    public final class Content: PrimitiveView {

        public var forceMount: Bool = false { didSet { presence.forceMount = forceMount } }
        public weak var item: Item?

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
            guard let ctx = componentContext, let _ = item else { return }
            // Listen for single mode
            ctx.publisher(for: CK.expandedValue, default: Optional<String>.none)
                .sink { [weak self] (val: String?) in
                    guard let self, let item = self.item else { return }
                    self.presence.isPresent = (val == item.value)
                }
                .store(in: &cancellables)
            // Listen for multiple mode
            ctx.publisher(for: CK.expandedValues, default: Set<String>())
                .sink { [weak self] (set: Set<String>) in
                    guard let self, let item = self.item else { return }
                    self.presence.isPresent = set.contains(item.value)
                }
                .store(in: &cancellables)
        }

        override public func accessibilityRole() -> NSAccessibility.Role? { .group }
    }
}
