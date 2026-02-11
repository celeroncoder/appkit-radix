import AppKit
import AppKitRadixCore
import Combine

/// Checkbox — Checkable input (checked/unchecked/indeterminate).
///
/// Radix UI equivalent: `@radix-ui/react-checkbox`
public enum CheckboxPrimitive {

    private enum CK { static let checked = "checked" }

    // MARK: - Root

    public final class Root: PrimitiveRoot, CheckedStateManaging {

        @Published private var _checkedState: CheckedState = .unchecked

        public var defaultChecked: CheckedState = .unchecked
        public var onCheckedChange: ((CheckedState) -> Void)?
        public var isDisabled: Bool = false

        public var checkedState: CheckedState { _checkedState }

        public var checkedPublisher: AnyPublisher<CheckedState, Never> {
            $_checkedState.eraseToAnyPublisher()
        }

        public func setChecked(_ state: CheckedState) {
            guard !isDisabled, !componentContext!.isDisabled else { return }
            _checkedState = state
            componentContext?.setState(state, for: CK.checked)
            onCheckedChange?(state)
            updateVisual()
            AccessibilityHelpers.postValueChanged(element: self)
        }

        public init(defaultChecked: CheckedState = .unchecked, id: String = UUID().uuidString) {
            self.defaultChecked = defaultChecked
            super.init(id: id)
            self._checkedState = defaultChecked
            componentContext?.setState(defaultChecked, for: CK.checked)
        }

        @available(*, unavailable)
        public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

        override public var primitiveAccessibilityRole: NSAccessibility.Role { .checkBox }

        override public func commonInit() {
            super.commonInit()
            wantsLayer = true
            layer?.cornerRadius = 4
            layer?.borderWidth = 1.5
            layer?.borderColor = NSColor.controlAccentColor.cgColor
            let w = widthAnchor.constraint(equalToConstant: 20)
            let h = heightAnchor.constraint(equalToConstant: 20)
            w.priority = .defaultHigh; h.priority = .defaultHigh
            NSLayoutConstraint.activate([w, h])
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
            } else { super.keyDown(with: event) }
        }

        override public func draw(_ dirtyRect: NSRect) {
            super.draw(dirtyRect)
            guard _checkedState != .unchecked else { return }
            let path = NSBezierPath()
            let b = bounds.insetBy(dx: 4, dy: 4)
            if _checkedState == .checked {
                path.move(to: NSPoint(x: b.minX, y: b.midY))
                path.line(to: NSPoint(x: b.midX - 1, y: b.minY))
                path.line(to: NSPoint(x: b.maxX, y: b.maxY))
            } else { // indeterminate
                path.move(to: NSPoint(x: b.minX, y: b.midY))
                path.line(to: NSPoint(x: b.maxX, y: b.midY))
            }
            NSColor.controlAccentColor.setStroke()
            path.lineWidth = 2
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            path.stroke()
        }

        private func updateVisual() {
            layer?.backgroundColor = (_checkedState != .unchecked
                ? NSColor.controlAccentColor.withAlphaComponent(0.1)
                : NSColor.clear).cgColor
            needsDisplay = true
        }

        override public func accessibilityRole() -> NSAccessibility.Role? { .checkBox }
        override public func accessibilityValue() -> Any? {
            switch _checkedState {
            case .checked: return 1
            case .unchecked: return 0
            case .indeterminate: return 2
            }
        }
    }

    // MARK: - Indicator

    public final class Indicator: PrimitiveView {
        override public func commonInit() {
            super.commonInit()
            isHidden = true
        }

        override public func didAttachToComponent() {
            super.didAttachToComponent()
            componentContext?.publisher(for: CK.checked, default: CheckedState.unchecked)
                .sink { [weak self] (state: CheckedState) in
                    self?.isHidden = state == .unchecked
                }
                .store(in: &cancellables)
        }
    }
}
