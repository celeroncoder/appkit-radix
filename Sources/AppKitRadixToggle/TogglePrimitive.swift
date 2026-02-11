import AppKit
import AppKitRadixCore
import Combine

/// Toggle — Two-state button (pressed/unpressed).
///
/// Radix UI equivalent: `@radix-ui/react-toggle`
public enum TogglePrimitive {

    public final class Root: PrimitiveRoot, CheckedStateManaging {

        @Published private var _checkedState: CheckedState = .unchecked

        public var defaultChecked: CheckedState = .unchecked
        public var onCheckedChange: ((CheckedState) -> Void)?
        public var isDisabled: Bool = false

        public var title: String = "" {
            didSet { titleLabel.stringValue = title; setAccessibilityLabel(title) }
        }

        public var checkedState: CheckedState { _checkedState }

        public var checkedPublisher: AnyPublisher<CheckedState, Never> {
            $_checkedState.eraseToAnyPublisher()
        }

        public func setChecked(_ state: CheckedState) {
            guard !isDisabled else { return }
            _checkedState = state
            onCheckedChange?(state)
            updateVisual()
            AccessibilityHelpers.postValueChanged(element: self)
        }

        private let titleLabel: NSTextField = {
            let l = NSTextField(labelWithString: "")
            l.translatesAutoresizingMaskIntoConstraints = false
            l.alignment = .center
            l.isEditable = false
            l.isBordered = false
            l.drawsBackground = false
            return l
        }()

        public init(title: String = "", defaultChecked: CheckedState = .unchecked, id: String = UUID().uuidString) {
            self.defaultChecked = defaultChecked
            super.init(id: id)
            self._checkedState = defaultChecked
            self.title = title
            titleLabel.stringValue = title
            setAccessibilityLabel(title)
        }

        @available(*, unavailable)
        public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

        override public var primitiveAccessibilityRole: NSAccessibility.Role { .checkBox }

        override public func commonInit() {
            super.commonInit()
            wantsLayer = true
            layer?.cornerRadius = 6
            addSubview(titleLabel)
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
                titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
                titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 6),
                titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            ])
            updateVisual()
        }

        override public var acceptsFirstResponder: Bool { !isDisabled }

        override public func mouseDown(with event: NSEvent) {
            guard !isDisabled else { return }
            setChecked(_checkedState == .checked ? .unchecked : .checked)
        }

        override public func keyDown(with event: NSEvent) {
            if event.keyCode == 49 { // Space
                guard !isDisabled else { return }
                setChecked(_checkedState == .checked ? .unchecked : .checked)
            } else {
                super.keyDown(with: event)
            }
        }

        private func updateVisual() {
            layer?.backgroundColor = (_checkedState == .checked
                ? NSColor.controlAccentColor.withAlphaComponent(0.15)
                : NSColor.controlBackgroundColor).cgColor
        }

        override public func accessibilityRole() -> NSAccessibility.Role? { .checkBox }
        override public func accessibilityValue() -> Any? { _checkedState == .checked ? 1 : 0 }
    }
}
