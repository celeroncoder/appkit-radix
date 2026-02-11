import AppKit
import AppKitRadixCore
import AppKitRadixBehaviors
import Combine

/// Toolbar — Container for grouped actions with roving focus.
///
/// Radix UI equivalent: `@radix-ui/react-toolbar`
public enum ToolbarPrimitive {

    public enum Orientation { case horizontal, vertical }

    public final class Root: PrimitiveRoot {
        public var orientation: Orientation = .horizontal

        private let stackView: NSStackView = { let s = NSStackView(); s.translatesAutoresizingMaskIntoConstraints = false; return s }()
        private let rovingFocus = RovingFocusGroup()

        public init(orientation: Orientation = .horizontal, id: String = UUID().uuidString) {
            self.orientation = orientation; super.init(id: id)
        }
        @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }

        override public func commonInit() {
            super.commonInit()
            stackView.orientation = orientation == .vertical ? .vertical : .horizontal; stackView.spacing = 4
            rovingFocus.orientation = orientation == .vertical ? .vertical : .horizontal
            rovingFocus.install(on: self)
            addSubview(stackView)
            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: topAnchor),
                stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
                stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }

        public func addItem(_ view: NSView) { stackView.addArrangedSubview(view); rovingFocus.register(view) }
        override public func accessibilityRole() -> NSAccessibility.Role? { .toolbar }
    }

    public final class Button: PrimitiveView {
        public var title = "" { didSet { btn.title = title } }
        public var onAction: (() -> Void)?
        public var isDisabled = false { didSet { btn.isEnabled = !isDisabled } }

        private let btn: NSButton = { let b = NSButton(title: "", target: nil, action: nil); b.translatesAutoresizingMaskIntoConstraints = false; b.bezelStyle = .rounded; return b }()

        public init(title: String = "") { self.title = title; super.init(frame: .zero); btn.title = title }
        @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }

        override public func commonInit() {
            super.commonInit(); btn.target = self; btn.action = #selector(tap)
            addSubview(btn); NSLayoutConstraint.activate([btn.leadingAnchor.constraint(equalTo: leadingAnchor), btn.trailingAnchor.constraint(equalTo: trailingAnchor), btn.topAnchor.constraint(equalTo: topAnchor), btn.bottomAnchor.constraint(equalTo: bottomAnchor)])
        }
        @objc private func tap() { onAction?() }
        override public var acceptsFirstResponder: Bool { !isDisabled }
        override public func accessibilityRole() -> NSAccessibility.Role? { .button }
    }

    public final class Link: PrimitiveView {
        public var title = "" { didSet { label.stringValue = title } }
        public var onAction: (() -> Void)?

        private let label: NSTextField = { let l = NSTextField(labelWithString: ""); l.translatesAutoresizingMaskIntoConstraints = false; l.textColor = .linkColor; return l }()

        public init(title: String = "") { self.title = title; super.init(frame: .zero); label.stringValue = title }
        @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }

        override public func commonInit() {
            super.commonInit()
            addSubview(label); NSLayoutConstraint.activate([label.leadingAnchor.constraint(equalTo: leadingAnchor), label.trailingAnchor.constraint(equalTo: trailingAnchor), label.topAnchor.constraint(equalTo: topAnchor), label.bottomAnchor.constraint(equalTo: bottomAnchor)])
        }
        override public var acceptsFirstResponder: Bool { true }
        override public func mouseDown(with event: NSEvent) { onAction?() }
        override public func keyDown(with event: NSEvent) {
            if event.keyCode == 49 || event.keyCode == 36 { onAction?() } else { super.keyDown(with: event) }
        }
        override public func accessibilityRole() -> NSAccessibility.Role? { .link }
    }

    public final class ToggleGroup: PrimitiveView {
        public enum SelectionType { case single, multiple }
        public var type: SelectionType = .single
        @Published public private(set) var selectedValues: Set<String> = []

        private let stackView: NSStackView = { let s = NSStackView(); s.orientation = .horizontal; s.spacing = 2; s.translatesAutoresizingMaskIntoConstraints = false; return s }()

        override public func commonInit() {
            super.commonInit()
            addSubview(stackView); NSLayoutConstraint.activate([stackView.leadingAnchor.constraint(equalTo: leadingAnchor), stackView.trailingAnchor.constraint(equalTo: trailingAnchor), stackView.topAnchor.constraint(equalTo: topAnchor), stackView.bottomAnchor.constraint(equalTo: bottomAnchor)])
        }

        public func addToggle(_ view: NSView) { stackView.addArrangedSubview(view) }

        public func toggle(value: String) {
            if type == .single { selectedValues = selectedValues.contains(value) ? [] : [value] }
            else { if selectedValues.contains(value) { selectedValues.remove(value) } else { selectedValues.insert(value) } }
        }

        override public func accessibilityRole() -> NSAccessibility.Role? { .group }
    }

    public final class ToggleItem: PrimitiveView {
        public let value: String
        public var title = "" { didSet { btn.title = title } }
        public var isDisabled = false { didSet { btn.isEnabled = !isDisabled } }

        private let btn: NSButton = { let b = NSButton(title: "", target: nil, action: nil); b.translatesAutoresizingMaskIntoConstraints = false; b.bezelStyle = .rounded; b.setButtonType(.toggle); return b }()

        public init(value: String, title: String = "") { self.value = value; self.title = title; super.init(frame: .zero); btn.title = title }
        @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }

        override public func commonInit() {
            super.commonInit(); btn.target = self; btn.action = #selector(tap)
            addSubview(btn); NSLayoutConstraint.activate([btn.leadingAnchor.constraint(equalTo: leadingAnchor), btn.trailingAnchor.constraint(equalTo: trailingAnchor), btn.topAnchor.constraint(equalTo: topAnchor), btn.bottomAnchor.constraint(equalTo: bottomAnchor)])
        }

        @objc private func tap() { findToggleGroup()?.toggle(value: value) }

        private func findToggleGroup() -> ToggleGroup? { var v: NSView? = superview; while let w = v { if let g = w as? ToggleGroup { return g }; v = w.superview }; return nil }
        override public var acceptsFirstResponder: Bool { !isDisabled }
        override public func accessibilityRole() -> NSAccessibility.Role? { .button }
    }

    public final class Separator: PrimitiveView {
        override public func commonInit() {
            super.commonInit(); wantsLayer = true; layer?.backgroundColor = NSColor.separatorColor.cgColor
            let w = widthAnchor.constraint(equalToConstant: 1); w.priority = .defaultHigh; w.isActive = true
            let h = heightAnchor.constraint(equalToConstant: 20); h.priority = .defaultHigh; h.isActive = true
        }
        override public func accessibilityRole() -> NSAccessibility.Role? { .splitter }
    }
}
