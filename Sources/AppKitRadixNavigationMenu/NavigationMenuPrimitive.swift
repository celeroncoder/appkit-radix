import AppKit
import AppKitRadixCore
import AppKitRadixBehaviors
import Combine

/// NavigationMenu — App/site navigation with dropdown content panels.
///
/// Radix UI equivalent: `@radix-ui/react-navigation-menu`
public enum NavigationMenuPrimitive {

    private enum CK { static let value = "navValue" }

    // MARK: - Root

    public final class Root: PrimitiveRoot {
        @Published private var _value: String?
        public var onValueChange: ((String?) -> Void)?

        public var value: String? { _value }
        public func setValue(_ v: String?) { _value = v; componentContext?.setState(v as Any, for: CK.value); onValueChange?(v) }

        private let stackView: NSStackView = { let s = NSStackView(); s.orientation = .vertical; s.spacing = 0; s.translatesAutoresizingMaskIntoConstraints = false; return s }()

        public override init(id: String = UUID().uuidString) { super.init(id: id) }
        @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }

        override public func commonInit() {
            super.commonInit(); wantsLayer = true
            addSubview(stackView); NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: topAnchor),
                stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
                stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }

        public func addContent(_ view: NSView) { stackView.addArrangedSubview(view) }
        override public func accessibilityRole() -> NSAccessibility.Role? { .group }
    }

    // MARK: - List

    public final class List: PrimitiveView {
        private let stackView: NSStackView = { let s = NSStackView(); s.orientation = .horizontal; s.spacing = 4; s.translatesAutoresizingMaskIntoConstraints = false; return s }()
        private let rovingFocus = RovingFocusGroup()

        override public func commonInit() {
            super.commonInit()
            rovingFocus.orientation = .horizontal; rovingFocus.install(on: self)
            addSubview(stackView); NSLayoutConstraint.activate([stackView.topAnchor.constraint(equalTo: topAnchor), stackView.leadingAnchor.constraint(equalTo: leadingAnchor), stackView.trailingAnchor.constraint(equalTo: trailingAnchor), stackView.bottomAnchor.constraint(equalTo: bottomAnchor)])
        }

        public func addItem(_ view: NSView) { stackView.addArrangedSubview(view); rovingFocus.register(view) }
        override public func accessibilityRole() -> NSAccessibility.Role? { .list }
    }

    // MARK: - Item

    public final class Item: PrimitiveView {
        public let value: String
        private let stackView: NSStackView = { let s = NSStackView(); s.orientation = .vertical; s.spacing = 0; s.translatesAutoresizingMaskIntoConstraints = false; return s }()

        public init(value: String) { self.value = value; super.init(frame: .zero) }
        @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }

        override public func commonInit() {
            super.commonInit()
            addSubview(stackView); NSLayoutConstraint.activate([stackView.leadingAnchor.constraint(equalTo: leadingAnchor), stackView.trailingAnchor.constraint(equalTo: trailingAnchor), stackView.topAnchor.constraint(equalTo: topAnchor), stackView.bottomAnchor.constraint(equalTo: bottomAnchor)])
        }

        public func addContent(_ view: NSView) { stackView.addArrangedSubview(view) }
        override public func accessibilityRole() -> NSAccessibility.Role? { .group }
    }

    // MARK: - Trigger

    public final class Trigger: PrimitiveView {
        public var title = "" { didSet { label.stringValue = title } }

        private let label: NSTextField = { let l = NSTextField(labelWithString: ""); l.translatesAutoresizingMaskIntoConstraints = false; l.isEditable = false; l.isBordered = false; l.drawsBackground = false; l.alignment = .center; return l }()

        public init(title: String = "") { self.title = title; super.init(frame: .zero); label.stringValue = title }
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

        override public var acceptsFirstResponder: Bool { true }

        override public func mouseDown(with event: NSEvent) {
            guard let item = findItem(), let root = findRoot() else { return }
            if root.value == item.value { root.setValue(nil) }
            else { root.setValue(item.value) }
        }

        override public func keyDown(with event: NSEvent) {
            if event.keyCode == 49 || event.keyCode == 36 {
                guard let item = findItem(), let root = findRoot() else { return }
                if root.value == item.value { root.setValue(nil) }
                else { root.setValue(item.value) }
            } else { super.keyDown(with: event) }
        }

        private func updateVisual() {
            guard let item = findItem() else { return }
            guard let ctx = componentContext else { return }
            let isActive = (ctx.state(for: CK.value, default: Optional<String>.none as Any) as? String) == item.value
            layer?.backgroundColor = (isActive ? NSColor.controlAccentColor.withAlphaComponent(0.1) : NSColor.clear).cgColor
        }

        private func findItem() -> Item? { var v: NSView? = superview; while let w = v { if let i = w as? Item { return i }; v = w.superview }; return nil }
        private func findRoot() -> Root? { var v: NSView? = superview; while let w = v { if let r = w as? Root { return r }; v = w.superview }; return nil }
        override public func accessibilityRole() -> NSAccessibility.Role? { .button }
        override public func accessibilityLabel() -> String? { title }
    }

    // MARK: - Content

    public final class Content: PrimitiveView {
        public let value: String
        private let presence = Presence(isPresent: false)

        public init(value: String) { self.value = value; super.init(frame: .zero) }
        @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }

        override public func commonInit() {
            super.commonInit(); wantsLayer = true; isHidden = true
            layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor; layer?.cornerRadius = 6
            layer?.borderWidth = 0.5; layer?.borderColor = NSColor.separatorColor.cgColor
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

    // MARK: - Link

    public final class Link: PrimitiveView {
        public var title = "" { didSet { label.stringValue = title } }
        public var isActive = false
        public var onSelect: (() -> Void)?

        private let label: NSTextField = { let l = NSTextField(labelWithString: ""); l.translatesAutoresizingMaskIntoConstraints = false; l.isEditable = false; l.isBordered = false; l.drawsBackground = false; l.textColor = .linkColor; return l }()

        public init(title: String = "") { self.title = title; super.init(frame: .zero); label.stringValue = title }
        @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }

        override public func commonInit() {
            super.commonInit(); wantsLayer = true
            addSubview(label); NSLayoutConstraint.activate([label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8), label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8), label.topAnchor.constraint(equalTo: topAnchor, constant: 4), label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)])
        }

        override public var acceptsFirstResponder: Bool { true }
        override public func mouseDown(with event: NSEvent) { onSelect?() }
        override public func keyDown(with event: NSEvent) {
            if event.keyCode == 49 || event.keyCode == 36 { onSelect?() } else { super.keyDown(with: event) }
        }
        override public func accessibilityRole() -> NSAccessibility.Role? { .link }
        override public func accessibilityLabel() -> String? { title }
    }

    // MARK: - Indicator

    public final class Indicator: PrimitiveView {
        override public func commonInit() {
            super.commonInit(); wantsLayer = true
            layer?.backgroundColor = NSColor.controlAccentColor.cgColor
            let h = heightAnchor.constraint(equalToConstant: 2); h.priority = .defaultHigh; h.isActive = true
        }
    }

    // MARK: - Viewport

    public final class Viewport: PrimitiveView {
        override public func commonInit() {
            super.commonInit(); wantsLayer = true
        }

        public func addContent(_ view: NSView) { addSubview(view) }
        override public func accessibilityRole() -> NSAccessibility.Role? { .group }
    }
}
