import AppKit
import AppKitRadixCore
import AppKitRadixBehaviors
import Combine

/// RadioGroup — Mutually exclusive option selection.
///
/// Radix UI equivalent: `@radix-ui/react-radio-group`
public enum RadioGroupPrimitive {

    public enum Orientation { case horizontal, vertical }
    private enum CK { static let value = "radioValue" }

    public final class Root: PrimitiveRoot {
        @Published private var _value: String?
        public var defaultValue: String?
        public var onValueChange: ((String?) -> Void)?
        public var orientation: Orientation = .vertical
        public var isDisabled = false
        public var isRequired = false

        public var value: String? { _value }
        public func setValue(_ v: String?) { _value = v; componentContext?.setState(v as Any, for: CK.value); onValueChange?(v) }

        private let stackView: NSStackView = { let s = NSStackView(); s.translatesAutoresizingMaskIntoConstraints = false; return s }()
        private let rovingFocus = RovingFocusGroup()

        public init(defaultValue: String? = nil, orientation: Orientation = .vertical, id: String = UUID().uuidString) {
            self.defaultValue = defaultValue; self.orientation = orientation; super.init(id: id)
            _value = defaultValue; componentContext?.setState(defaultValue as Any, for: CK.value)
        }
        @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }

        override public func commonInit() {
            super.commonInit()
            stackView.orientation = orientation == .vertical ? .vertical : .horizontal; stackView.spacing = 8
            rovingFocus.orientation = orientation == .vertical ? .vertical : .horizontal; rovingFocus.install(on: self)
            addSubview(stackView); NSLayoutConstraint.activate([stackView.topAnchor.constraint(equalTo: topAnchor), stackView.leadingAnchor.constraint(equalTo: leadingAnchor), stackView.trailingAnchor.constraint(equalTo: trailingAnchor), stackView.bottomAnchor.constraint(equalTo: bottomAnchor)])
        }

        public func addItem(_ view: NSView) { stackView.addArrangedSubview(view); rovingFocus.register(view) }
        override public func accessibilityRole() -> NSAccessibility.Role? { .radioGroup }
    }

    public final class Item: PrimitiveView {
        public let value: String
        public var isDisabled = false

        public init(value: String) { self.value = value; super.init(frame: .zero) }
        @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }

        override public func commonInit() {
            super.commonInit(); wantsLayer = true
            let w = widthAnchor.constraint(equalToConstant: 16); let h = heightAnchor.constraint(equalToConstant: 16)
            w.priority = .defaultHigh; h.priority = .defaultHigh; w.isActive = true; h.isActive = true
            layer?.cornerRadius = 8; layer?.borderWidth = 1.5; layer?.borderColor = NSColor.controlAccentColor.cgColor
        }

        override public func didAttachToComponent() {
            super.didAttachToComponent()
            componentContext?.publisher(for: CK.value, default: Optional<String>.none as Any)
                .sink { [weak self] _ in self?.needsDisplay = true }.store(in: &cancellables)
        }

        override public var acceptsFirstResponder: Bool { !isDisabled }

        override public func mouseDown(with event: NSEvent) {
            guard !isDisabled else { return }; findRoot()?.setValue(value)
        }

        override public func keyDown(with event: NSEvent) {
            if event.keyCode == 49 { guard !isDisabled else { return }; findRoot()?.setValue(value) }
            else { super.keyDown(with: event) }
        }

        override public func draw(_ dirtyRect: NSRect) {
            super.draw(dirtyRect)
            guard let ctx = componentContext else { return }
            let selected = (ctx.state(for: CK.value, default: Optional<String>.none as Any) as? String) == value
            if selected {
                let inner = bounds.insetBy(dx: 4, dy: 4)
                let path = NSBezierPath(ovalIn: inner)
                NSColor.controlAccentColor.setFill(); path.fill()
            }
        }

        private func findRoot() -> Root? { var v: NSView? = superview; while let w = v { if let r = w as? Root { return r }; v = w.superview }; return nil }
        override public func accessibilityRole() -> NSAccessibility.Role? { .radioButton }
        override public func accessibilityValue() -> Any? { guard let ctx = componentContext else { return 0 }; return (ctx.state(for: CK.value, default: Optional<String>.none as Any) as? String) == value ? 1 : 0 }
    }

    public final class Indicator: PrimitiveView {
        override public func commonInit() { super.commonInit() }
    }
}
