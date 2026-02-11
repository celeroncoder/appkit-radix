import AppKit
import AppKitRadixCore
import AppKitRadixBehaviors
import Combine

/// Tabs — Tabbed content switching.
///
/// Radix UI equivalent: `@radix-ui/react-tabs`
public enum TabsPrimitive {

    public enum Orientation { case horizontal, vertical }
    public enum ActivationMode { case automatic, manual }
    private enum CK { static let value = "tabValue" }

    public final class Root: PrimitiveRoot {
        @Published private var _value: String?
        public var defaultValue: String?
        public var onValueChange: ((String?) -> Void)?
        public var orientation: Orientation = .horizontal
        public var activationMode: ActivationMode = .automatic

        public var value: String? { _value }

        public func setValue(_ v: String?) {
            _value = v; componentContext?.setState(v as Any, for: CK.value); onValueChange?(v)
        }

        private let stackView: NSStackView = { let s = NSStackView(); s.orientation = .vertical; s.spacing = 0; s.translatesAutoresizingMaskIntoConstraints = false; return s }()

        public init(defaultValue: String? = nil, id: String = UUID().uuidString) {
            self.defaultValue = defaultValue; super.init(id: id)
            _value = defaultValue; componentContext?.setState(defaultValue as Any, for: CK.value)
        }
        @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }

        override public func commonInit() {
            super.commonInit(); addSubview(stackView)
            NSLayoutConstraint.activate([stackView.topAnchor.constraint(equalTo: topAnchor), stackView.leadingAnchor.constraint(equalTo: leadingAnchor), stackView.trailingAnchor.constraint(equalTo: trailingAnchor), stackView.bottomAnchor.constraint(equalTo: bottomAnchor)])
        }

        public func addArrangedSubview(_ view: NSView) { stackView.addArrangedSubview(view) }
        override public func accessibilityRole() -> NSAccessibility.Role? { .tabGroup }
    }

    public final class List: PrimitiveView {
        private let stackView: NSStackView = { let s = NSStackView(); s.orientation = .horizontal; s.spacing = 0; s.translatesAutoresizingMaskIntoConstraints = false; return s }()
        private let rovingFocus = RovingFocusGroup()

        override public func commonInit() {
            super.commonInit(); rovingFocus.orientation = .horizontal; rovingFocus.install(on: self)
            addSubview(stackView); NSLayoutConstraint.activate([stackView.topAnchor.constraint(equalTo: topAnchor), stackView.leadingAnchor.constraint(equalTo: leadingAnchor), stackView.trailingAnchor.constraint(equalTo: trailingAnchor), stackView.bottomAnchor.constraint(equalTo: bottomAnchor)])
        }

        public func addTrigger(_ view: NSView) { stackView.addArrangedSubview(view); rovingFocus.register(view) }
        override public func accessibilityRole() -> NSAccessibility.Role? { .tabGroup }
    }

    public final class Trigger: PrimitiveView {
        public let value: String
        public var title = "" { didSet { label.stringValue = title } }
        public var isDisabled = false

        private let label: NSTextField = { let l = NSTextField(labelWithString: ""); l.translatesAutoresizingMaskIntoConstraints = false; l.isEditable = false; l.isBordered = false; l.drawsBackground = false; l.alignment = .center; return l }()

        public init(value: String, title: String = "") {
            self.value = value; self.title = title; super.init(frame: .zero); label.stringValue = title
        }
        @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }

        override public func commonInit() {
            super.commonInit(); wantsLayer = true
            addSubview(label); NSLayoutConstraint.activate([label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12), label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12), label.topAnchor.constraint(equalTo: topAnchor, constant: 8), label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)])
        }

        override public func didAttachToComponent() {
            super.didAttachToComponent()
            componentContext?.publisher(for: CK.value, default: Optional<String>.none as Any)
                .sink { [weak self] _ in self?.updateVisual() }.store(in: &cancellables)
        }

        override public var acceptsFirstResponder: Bool { !isDisabled }

        override public func mouseDown(with event: NSEvent) {
            guard !isDisabled else { return }; findRoot()?.setValue(value)
        }

        override public func keyDown(with event: NSEvent) {
            if event.keyCode == 49 || event.keyCode == 36 { guard !isDisabled else { return }; findRoot()?.setValue(value) }
            else { super.keyDown(with: event) }
        }

        private func updateVisual() {
            guard let ctx = componentContext else { return }
            let selected = (ctx.state(for: CK.value, default: Optional<String>.none as Any) as? String) == value
            layer?.backgroundColor = (selected ? NSColor.controlAccentColor.withAlphaComponent(0.1) : NSColor.clear).cgColor
        }

        private func findRoot() -> Root? { var v: NSView? = superview; while let w = v { if let r = w as? Root { return r }; v = w.superview }; return nil }
        override public func accessibilityRole() -> NSAccessibility.Role? { .radioButton }
        override public func accessibilityLabel() -> String? { title }
    }

    public final class Content: PrimitiveView {
        public let value: String
        public var forceMount = false { didSet { presence.forceMount = forceMount } }
        private let presence = Presence(isPresent: false)

        public init(value: String) { self.value = value; super.init(frame: .zero) }
        @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }

        override public func commonInit() {
            super.commonInit(); isHidden = true
            presence.$isMounted.removeDuplicates().sink { [weak self] m in self?.isHidden = !m }.store(in: &cancellables)
        }

        override public func didAttachToComponent() {
            super.didAttachToComponent()
            componentContext?.publisher(for: CK.value, default: Optional<String>.none as Any)
                .sink { [weak self] val in
                    guard let self else { return }
                    self.presence.isPresent = (val as? String) == self.value
                }.store(in: &cancellables)
        }

        override public func accessibilityRole() -> NSAccessibility.Role? { .group }
    }
}
