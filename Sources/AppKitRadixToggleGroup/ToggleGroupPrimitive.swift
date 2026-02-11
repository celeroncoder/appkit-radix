import AppKit
import AppKitRadixCore
import AppKitRadixBehaviors
import Combine

/// ToggleGroup — Group of toggles with single/multiple selection.
///
/// Radix UI equivalent: `@radix-ui/react-toggle-group`
public enum ToggleGroupPrimitive {

    public enum GroupType { case single, multiple }
    private enum CK { static let value = "tgValue"; static let values = "tgValues" }

    public final class Root: PrimitiveRoot {

        public var type: GroupType = .single
        public var isDisabled: Bool = false { didSet { componentContext?.isDisabled = isDisabled } }
        public var onValueChange: ((Any) -> Void)?

        private let stackView: NSStackView = {
            let s = NSStackView(); s.orientation = .horizontal; s.spacing = 1
            s.translatesAutoresizingMaskIntoConstraints = false; return s
        }()
        private let rovingFocus = RovingFocusGroup()

        public init(type: GroupType = .single, id: String = UUID().uuidString) {
            self.type = type
            super.init(id: id)
            if type == .single { componentContext?.setState(Optional<String>.none, for: CK.value) }
            else { componentContext?.setState(Set<String>(), for: CK.values) }
        }

        @available(*, unavailable)
        public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

        override public func commonInit() {
            super.commonInit()
            rovingFocus.orientation = .horizontal
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
        func registerItem(_ view: NSView) { rovingFocus.register(view) }

        func toggleItem(_ value: String) {
            guard !isDisabled else { return }
            if type == .single {
                let cur: String? = componentContext?.state(for: CK.value, default: nil)
                let nv: String? = cur == value ? nil : value
                componentContext?.setState(nv, for: CK.value)
                onValueChange?(nv as Any)
            } else {
                var set: Set<String> = componentContext?.state(for: CK.values, default: Set<String>()) ?? []
                if set.contains(value) { set.remove(value) } else { set.insert(value) }
                componentContext?.setState(set, for: CK.values)
                onValueChange?(set)
            }
        }

        func isPressed(_ value: String) -> Bool {
            if type == .single { return componentContext?.state(for: CK.value, default: Optional<String>.none) == value }
            let set: Set<String> = componentContext?.state(for: CK.values, default: Set<String>()) ?? []
            return set.contains(value)
        }

        override public func accessibilityRole() -> NSAccessibility.Role? { .group }
    }

    public final class Item: PrimitiveView {

        public let value: String
        public var title: String = "" { didSet { label.stringValue = title } }
        public var isDisabled: Bool = false

        private let label: NSTextField = {
            let l = NSTextField(labelWithString: ""); l.translatesAutoresizingMaskIntoConstraints = false
            l.isEditable = false; l.isBordered = false; l.drawsBackground = false; l.alignment = .center
            return l
        }()

        public init(value: String, title: String = "") {
            self.value = value; self.title = title
            super.init(frame: .zero)
            label.stringValue = title
        }

        @available(*, unavailable)
        public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

        override public func commonInit() {
            super.commonInit()
            wantsLayer = true; layer?.cornerRadius = 4
            addSubview(label)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
                label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
                label.topAnchor.constraint(equalTo: topAnchor, constant: 4),
                label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            ])
        }

        override public func didAttachToComponent() {
            super.didAttachToComponent()
            if let root = findRoot() { root.registerItem(self) }
            // Observe changes to update visual state
            componentContext?.publisher(for: CK.value, default: Optional<String>.none)
                .sink { [weak self] (_: String?) in self?.updateVisual() }
                .store(in: &cancellables)
            componentContext?.publisher(for: CK.values, default: Set<String>())
                .sink { [weak self] (_: Set<String>) in self?.updateVisual() }
                .store(in: &cancellables)
        }

        override public var acceptsFirstResponder: Bool { !isDisabled }

        override public func mouseDown(with event: NSEvent) {
            guard !isDisabled, let root = findRoot() else { return }
            root.toggleItem(value)
        }

        override public func keyDown(with event: NSEvent) {
            if event.keyCode == 49 {
                guard !isDisabled, let root = findRoot() else { return }
                root.toggleItem(value)
            } else { super.keyDown(with: event) }
        }

        private func updateVisual() {
            let pressed = findRoot()?.isPressed(value) ?? false
            layer?.backgroundColor = (pressed
                ? NSColor.controlAccentColor.withAlphaComponent(0.15)
                : NSColor.controlBackgroundColor).cgColor
        }

        private func findRoot() -> Root? {
            var v: NSView? = superview
            while let view = v { if let r = view as? Root { return r }; v = view.superview }
            return nil
        }

        override public func accessibilityRole() -> NSAccessibility.Role? { .checkBox }
        override public func accessibilityValue() -> Any? { findRoot()?.isPressed(value) == true ? 1 : 0 }
    }
}
