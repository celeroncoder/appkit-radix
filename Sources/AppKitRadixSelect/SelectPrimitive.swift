import AppKit
import AppKitRadixCore
import AppKitRadixBehaviors
import Combine

/// Select — Custom dropdown for choosing from a list.
///
/// Radix UI equivalent: `@radix-ui/react-select`
public enum SelectPrimitive {

    private enum CK { static let value = "selectValue"; static let isOpen = "selectOpen" }

    // MARK: - Root

    public final class Root: PrimitiveRoot, OpenStateManaging {
        @Published private var _isOpen = false
        @Published private var _value: String?
        public var defaultValue: String?
        public var defaultOpen = false
        public var onValueChange: ((String?) -> Void)?
        public var onOpenChange: ((Bool) -> Void)?
        public var isDisabled = false

        public var value: String? { _value }
        public var isOpen: Bool { _isOpen }
        public var isOpenPublisher: AnyPublisher<Bool, Never> { $_isOpen.eraseToAnyPublisher() }

        public func setOpen(_ open: Bool) { _isOpen = open; componentContext?.setState(open, for: CK.isOpen); onOpenChange?(open) }
        public func setValue(_ v: String?) { _value = v; componentContext?.setState(v as Any, for: CK.value); onValueChange?(v) }

        public init(defaultValue: String? = nil, id: String = UUID().uuidString) {
            self.defaultValue = defaultValue; super.init(id: id)
            _value = defaultValue; componentContext?.setState(defaultValue as Any, for: CK.value)
        }
        @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }
        override public func accessibilityRole() -> NSAccessibility.Role? { .popUpButton }
    }

    // MARK: - Trigger

    public final class Trigger: PrimitiveView {
        private let btn: NSButton = { let b = NSButton(title: "Select…", target: nil, action: nil); b.translatesAutoresizingMaskIntoConstraints = false; b.bezelStyle = .rounded; return b }()

        override public func commonInit() {
            super.commonInit(); btn.target = self; btn.action = #selector(handleClick)
            addSubview(btn); NSLayoutConstraint.activate([btn.leadingAnchor.constraint(equalTo: leadingAnchor), btn.trailingAnchor.constraint(equalTo: trailingAnchor), btn.topAnchor.constraint(equalTo: topAnchor), btn.bottomAnchor.constraint(equalTo: bottomAnchor)])
        }

        @objc private func handleClick() {
            guard let root = findRoot(), !root.isDisabled else { return }
            root.setOpen(!root.isOpen)
        }

        override public func didAttachToComponent() {
            super.didAttachToComponent()
            componentContext?.publisher(for: CK.value, default: Optional<String>.none as Any)
                .sink { [weak self] val in
                    if let s = val as? String { self?.btn.title = s } else { self?.btn.title = "Select…" }
                }.store(in: &cancellables)
        }

        private func findRoot() -> Root? { var v: NSView? = superview; while let w = v { if let r = w as? Root { return r }; v = w.superview }; return nil }
        override public func accessibilityRole() -> NSAccessibility.Role? { .popUpButton }
    }

    // MARK: - Value

    public final class Value: PrimitiveView {
        public var placeholder = "Select…"
        private let label: NSTextField = { let l = NSTextField(labelWithString: ""); l.translatesAutoresizingMaskIntoConstraints = false; return l }()

        override public func commonInit() {
            super.commonInit()
            label.stringValue = placeholder
            addSubview(label); NSLayoutConstraint.activate([label.leadingAnchor.constraint(equalTo: leadingAnchor), label.trailingAnchor.constraint(equalTo: trailingAnchor), label.topAnchor.constraint(equalTo: topAnchor), label.bottomAnchor.constraint(equalTo: bottomAnchor)])
        }

        override public func didAttachToComponent() {
            super.didAttachToComponent()
            componentContext?.publisher(for: CK.value, default: Optional<String>.none as Any)
                .sink { [weak self] val in
                    guard let self else { return }
                    if let s = val as? String, !s.isEmpty { self.label.stringValue = s }
                    else { self.label.stringValue = self.placeholder }
                }.store(in: &cancellables)
        }
    }

    // MARK: - Icon

    public final class Icon: PrimitiveView {
        override public func commonInit() {
            super.commonInit()
            let img = NSImageView(image: NSImage(systemSymbolName: "chevron.down", accessibilityDescription: nil) ?? NSImage())
            img.translatesAutoresizingMaskIntoConstraints = false
            addSubview(img); NSLayoutConstraint.activate([img.leadingAnchor.constraint(equalTo: leadingAnchor), img.trailingAnchor.constraint(equalTo: trailingAnchor), img.topAnchor.constraint(equalTo: topAnchor), img.bottomAnchor.constraint(equalTo: bottomAnchor)])
        }
    }

    // MARK: - Content

    public final class Content: PrimitiveView {
        private let presence = Presence(isPresent: false)
        private let dismissRegion = DismissableRegion()
        private let rovingFocus = RovingFocusGroup()
        private var typeAheadBuffer = ""
        private var typeAheadTimer: DispatchWorkItem?

        private let stackView: NSStackView = { let s = NSStackView(); s.orientation = .vertical; s.spacing = 2; s.translatesAutoresizingMaskIntoConstraints = false; return s }()

        override public func commonInit() {
            super.commonInit(); wantsLayer = true; isHidden = true
            layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
            layer?.cornerRadius = 6; layer?.borderWidth = 0.5; layer?.borderColor = NSColor.separatorColor.cgColor
            layer?.shadowOpacity = 0.2; layer?.shadowRadius = 8
            rovingFocus.orientation = .vertical; rovingFocus.install(on: self)
            addSubview(stackView); NSLayoutConstraint.activate([stackView.topAnchor.constraint(equalTo: topAnchor, constant: 4), stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4), stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4), stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)])
            presence.$isMounted.removeDuplicates().sink { [weak self] m in
                self?.isHidden = !m
                if m { self?.onOpen() } else { self?.onClose() }
            }.store(in: &cancellables)
        }

        override public func didAttachToComponent() {
            super.didAttachToComponent()
            componentContext?.publisher(for: CK.isOpen, default: false)
                .sink { [weak self] (open: Bool) in self?.presence.isPresent = open }.store(in: &cancellables)
        }

        public func addItem(_ view: NSView) { stackView.addArrangedSubview(view); rovingFocus.register(view) }

        private func onOpen() {
            dismissRegion.monitorEscape { [weak self] _ in self?.findRoot()?.setOpen(false); return .dismiss }
        }
        private func onClose() { dismissRegion.stopMonitoring() }

        override public func keyDown(with event: NSEvent) {
            guard let chars = event.characters, !chars.isEmpty else { super.keyDown(with: event); return }
            typeAheadTimer?.cancel()
            typeAheadBuffer += chars.lowercased()
            let item = DispatchWorkItem { [weak self] in self?.typeAheadBuffer = "" }
            typeAheadTimer = item; DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: item)
        }

        private func findRoot() -> Root? { var v: NSView? = superview; while let w = v { if let r = w as? Root { return r }; v = w.superview }; return nil }
        override public func accessibilityRole() -> NSAccessibility.Role? { .list }
    }

    // MARK: - Viewport

    public final class Viewport: PrimitiveView {
        override public func commonInit() { super.commonInit() }
    }

    // MARK: - Item

    public final class Item: PrimitiveView {
        public let value: String
        public var textValue: String = ""
        public var isDisabled = false

        private let label: NSTextField = { let l = NSTextField(labelWithString: ""); l.translatesAutoresizingMaskIntoConstraints = false; l.isEditable = false; l.isBordered = false; l.drawsBackground = false; return l }()

        public init(value: String, text: String = "") {
            self.value = value; self.textValue = text.isEmpty ? value : text; super.init(frame: .zero)
            label.stringValue = self.textValue
        }
        @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }

        override public func commonInit() {
            super.commonInit(); wantsLayer = true
            addSubview(label); NSLayoutConstraint.activate([label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8), label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8), label.topAnchor.constraint(equalTo: topAnchor, constant: 4), label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)])
        }

        override public func didAttachToComponent() {
            super.didAttachToComponent()
            componentContext?.publisher(for: CK.value, default: Optional<String>.none as Any)
                .sink { [weak self] _ in self?.updateVisual() }.store(in: &cancellables)
        }

        override public var acceptsFirstResponder: Bool { !isDisabled }

        override public func mouseDown(with event: NSEvent) {
            guard !isDisabled else { return }
            findRoot()?.setValue(value); findRoot()?.setOpen(false)
        }

        override public func keyDown(with event: NSEvent) {
            if event.keyCode == 49 || event.keyCode == 36 { guard !isDisabled else { return }; findRoot()?.setValue(value); findRoot()?.setOpen(false) }
            else { super.keyDown(with: event) }
        }

        private func updateVisual() {
            guard let ctx = componentContext else { return }
            let selected = (ctx.state(for: CK.value, default: Optional<String>.none as Any) as? String) == value
            layer?.backgroundColor = (selected ? NSColor.controlAccentColor.withAlphaComponent(0.1) : NSColor.clear).cgColor
        }

        private func findRoot() -> Root? { var v: NSView? = superview; while let w = v { if let r = w as? Root { return r }; v = w.superview }; return nil }
        override public func accessibilityRole() -> NSAccessibility.Role? { .menuItem }
    }

    // MARK: - ItemText

    public final class ItemText: PrimitiveView {
        public var text = "" { didSet { label.stringValue = text } }
        private let label: NSTextField = { let l = NSTextField(labelWithString: ""); l.translatesAutoresizingMaskIntoConstraints = false; l.isEditable = false; l.isBordered = false; l.drawsBackground = false; return l }()
        override public func commonInit() {
            super.commonInit(); addSubview(label); NSLayoutConstraint.activate([label.leadingAnchor.constraint(equalTo: leadingAnchor), label.trailingAnchor.constraint(equalTo: trailingAnchor), label.topAnchor.constraint(equalTo: topAnchor), label.bottomAnchor.constraint(equalTo: bottomAnchor)])
        }
    }

    // MARK: - ItemIndicator

    public final class ItemIndicator: PrimitiveView {
        override public func commonInit() {
            super.commonInit()
            let w = widthAnchor.constraint(equalToConstant: 16); let h = heightAnchor.constraint(equalToConstant: 16)
            w.priority = .defaultHigh; h.priority = .defaultHigh; w.isActive = true; h.isActive = true
        }
        override public func draw(_ dirtyRect: NSRect) {
            super.draw(dirtyRect)
            let path = NSBezierPath(); path.move(to: NSPoint(x: 3, y: 8)); path.line(to: NSPoint(x: 6, y: 5)); path.line(to: NSPoint(x: 13, y: 12))
            NSColor.controlAccentColor.setStroke(); path.lineWidth = 1.5; path.stroke()
        }
    }

    // MARK: - ScrollUpButton / ScrollDownButton

    public final class ScrollUpButton: PrimitiveView {
        override public func commonInit() {
            super.commonInit(); wantsLayer = true
            let h = heightAnchor.constraint(equalToConstant: 20); h.priority = .defaultHigh; h.isActive = true
        }
        override public func accessibilityRole() -> NSAccessibility.Role? { .button }
    }

    public final class ScrollDownButton: PrimitiveView {
        override public func commonInit() {
            super.commonInit(); wantsLayer = true
            let h = heightAnchor.constraint(equalToConstant: 20); h.priority = .defaultHigh; h.isActive = true
        }
        override public func accessibilityRole() -> NSAccessibility.Role? { .button }
    }

    // MARK: - Group

    public final class Group: PrimitiveView {
        private let stackView: NSStackView = { let s = NSStackView(); s.orientation = .vertical; s.spacing = 2; s.translatesAutoresizingMaskIntoConstraints = false; return s }()
        override public func commonInit() {
            super.commonInit(); addSubview(stackView); NSLayoutConstraint.activate([stackView.leadingAnchor.constraint(equalTo: leadingAnchor), stackView.trailingAnchor.constraint(equalTo: trailingAnchor), stackView.topAnchor.constraint(equalTo: topAnchor), stackView.bottomAnchor.constraint(equalTo: bottomAnchor)])
        }
        public func addItem(_ view: NSView) { stackView.addArrangedSubview(view) }
        override public func accessibilityRole() -> NSAccessibility.Role? { .group }
    }

    // MARK: - Label

    public final class Label: PrimitiveView {
        public var text = "" { didSet { label.stringValue = text } }
        private let label: NSTextField = { let l = NSTextField(labelWithString: ""); l.translatesAutoresizingMaskIntoConstraints = false; l.isEditable = false; l.isBordered = false; l.drawsBackground = false; l.font = .systemFont(ofSize: 11, weight: .medium); l.textColor = .secondaryLabelColor; return l }()
        override public func commonInit() {
            super.commonInit(); addSubview(label); NSLayoutConstraint.activate([label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8), label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8), label.topAnchor.constraint(equalTo: topAnchor, constant: 4), label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)])
        }
    }

    // MARK: - Separator

    public final class Separator: PrimitiveView {
        override public func commonInit() {
            super.commonInit(); wantsLayer = true; layer?.backgroundColor = NSColor.separatorColor.cgColor
            let h = heightAnchor.constraint(equalToConstant: 1); h.priority = .defaultHigh; h.isActive = true
        }
        override public func accessibilityRole() -> NSAccessibility.Role? { .splitter }
    }
}
