import AppKit
import AppKitRadixCore
import Combine

/// Switch — Toggle on/off.
///
/// Radix UI equivalent: `@radix-ui/react-switch`
public enum SwitchPrimitive {

    private enum CK { static let checked = "switchChecked" }

    // MARK: - Root

    public final class Root: PrimitiveRoot, CheckedStateManaging {

        @Published private var _checkedState: CheckedState = .unchecked

        public var defaultChecked: CheckedState = .unchecked
        public var onCheckedChange: ((CheckedState) -> Void)?
        public var isDisabled: Bool = false

        public var checkedState: CheckedState { _checkedState }
        public var checkedPublisher: AnyPublisher<CheckedState, Never> { $_checkedState.eraseToAnyPublisher() }

        public func setChecked(_ state: CheckedState) {
            guard !isDisabled else { return }
            let s: CheckedState = (state == .checked) ? .checked : .unchecked
            _checkedState = s
            componentContext?.setState(s, for: CK.checked)
            onCheckedChange?(s)
            updateVisual()
            AccessibilityHelpers.postValueChanged(element: self)
        }

        public init(defaultChecked: CheckedState = .unchecked, id: String = UUID().uuidString) {
            self.defaultChecked = defaultChecked
            super.init(id: id)
            _checkedState = defaultChecked
            componentContext?.setState(defaultChecked, for: CK.checked)
        }

        @available(*, unavailable)
        public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

        override public var primitiveAccessibilityRole: NSAccessibility.Role { .checkBox }

        override public func commonInit() {
            super.commonInit()
            wantsLayer = true
            layer?.cornerRadius = 11
            let w = widthAnchor.constraint(equalToConstant: 40)
            let h = heightAnchor.constraint(equalToConstant: 22)
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
            if event.keyCode == 49 {
                guard !isDisabled else { return }
                setChecked(_checkedState == .checked ? .unchecked : .checked)
            } else { super.keyDown(with: event) }
        }

        private func updateVisual() {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.2
                ctx.allowsImplicitAnimation = true
                self.layer?.backgroundColor = (self._checkedState == .checked
                    ? NSColor.controlAccentColor
                    : NSColor.separatorColor).cgColor
            }
            needsLayout = true
        }

        override public func accessibilityRole() -> NSAccessibility.Role? { .checkBox }
        override public func accessibilityValue() -> Any? { _checkedState == .checked ? 1 : 0 }
        override public func accessibilityLabel() -> String? { "Switch" }
    }

    // MARK: - Thumb

    public final class Thumb: PrimitiveView {

        override public func commonInit() {
            super.commonInit()
            wantsLayer = true
            layer?.backgroundColor = NSColor.white.cgColor
            layer?.cornerRadius = 9
            layer?.shadowOpacity = 0.15
            layer?.shadowRadius = 1
            layer?.shadowOffset = NSSize(width: 0, height: -1)
            translatesAutoresizingMaskIntoConstraints = true
            frame = NSRect(x: 2, y: 2, width: 18, height: 18)
        }

        override public func didAttachToComponent() {
            super.didAttachToComponent()
            componentContext?.publisher(for: CK.checked, default: CheckedState.unchecked)
                .sink { [weak self] (state: CheckedState) in
                    guard let self, let parent = self.superview else { return }
                    NSAnimationContext.runAnimationGroup { ctx in
                        ctx.duration = 0.2
                        ctx.allowsImplicitAnimation = true
                        let x: CGFloat = state == .checked ? parent.bounds.width - 20 : 2
                        self.frame.origin.x = x
                    }
                }
                .store(in: &cancellables)
        }
    }
}
