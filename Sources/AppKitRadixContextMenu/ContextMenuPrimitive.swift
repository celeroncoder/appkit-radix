import AppKit
import AppKitRadixCore
import AppKitRadixBehaviors
import Combine

/// ContextMenu — Right-click contextual menu.
///
/// Radix UI equivalent: `@radix-ui/react-context-menu`
public enum ContextMenuPrimitive {

    private enum CK { static let isOpen = "contextMenuOpen" }

    // MARK: - Root

    public final class Root: PrimitiveRoot, OpenStateManaging {
        @Published private var _isOpen = false
        public var defaultOpen = false
        public var onOpenChange: ((Bool) -> Void)?

        public var isOpen: Bool { _isOpen }
        public var isOpenPublisher: AnyPublisher<Bool, Never> { $_isOpen.eraseToAnyPublisher() }

        public func setOpen(_ open: Bool) { _isOpen = open; componentContext?.setState(open, for: CK.isOpen); onOpenChange?(open) }

        public override init(id: String = UUID().uuidString) { super.init(id: id) }
        @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }
        override public func accessibilityRole() -> NSAccessibility.Role? { .group }
    }

    // MARK: - Trigger

    public final class Trigger: PrimitiveView {
        override public func commonInit() { super.commonInit() }

        override public func rightMouseDown(with event: NSEvent) {
            findRoot()?.setOpen(true)
        }

        override public func mouseDown(with event: NSEvent) {
            if event.modifierFlags.contains(.control) { findRoot()?.setOpen(true) }
            else { super.mouseDown(with: event) }
        }

        private func findRoot() -> Root? { var v: NSView? = superview; while let w = v { if let r = w as? Root { return r }; v = w.superview }; return nil }
    }

    // MARK: - Content

    public final class Content: PrimitiveView, DismissableContent {
        public var onEscapeKeyDown: ((NSEvent) -> DismissAction)?
        public var onClickOutside: ((NSEvent) -> DismissAction)?
        public var onInteractOutside: ((NSEvent) -> DismissAction)?

        private let presence = Presence(isPresent: false)
        private let dismissRegion = DismissableRegion()
        private let rovingFocus = RovingFocusGroup()

        private let stackView: NSStackView = { let s = NSStackView(); s.orientation = .vertical; s.spacing = 2; s.translatesAutoresizingMaskIntoConstraints = false; return s }()

        override public func commonInit() {
            super.commonInit(); wantsLayer = true; isHidden = true
            layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor; layer?.cornerRadius = 6
            layer?.borderWidth = 0.5; layer?.borderColor = NSColor.separatorColor.cgColor
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
            dismissRegion.monitorEscape { [weak self] event in
                let action = self?.onEscapeKeyDown?(event) ?? .dismiss
                if action == .dismiss { self?.findRoot()?.setOpen(false) }; return action
            }
        }
        private func onClose() { dismissRegion.stopMonitoring() }

        private func findRoot() -> Root? { var v: NSView? = superview; while let w = v { if let r = w as? Root { return r }; v = w.superview }; return nil }
        override public func accessibilityRole() -> NSAccessibility.Role? { .menu }
    }

    // MARK: - Item

    public final class Item: PrimitiveView {
        public var title = "" { didSet { label.stringValue = title } }
        public var isDisabled = false
        public var onSelect: (() -> Void)?

        private let label: NSTextField = { let l = NSTextField(labelWithString: ""); l.translatesAutoresizingMaskIntoConstraints = false; l.isEditable = false; l.isBordered = false; l.drawsBackground = false; return l }()

        public init(title: String = "") { self.title = title; super.init(frame: .zero); label.stringValue = title }
        @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }

        override public func commonInit() {
            super.commonInit(); wantsLayer = true
            addSubview(label); NSLayoutConstraint.activate([label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8), label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8), label.topAnchor.constraint(equalTo: topAnchor, constant: 4), label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)])
        }

        override public var acceptsFirstResponder: Bool { !isDisabled }
        override public func mouseDown(with event: NSEvent) { guard !isDisabled else { return }; onSelect?(); findRoot()?.setOpen(false) }
        override public func keyDown(with event: NSEvent) {
            if event.keyCode == 49 || event.keyCode == 36 { guard !isDisabled else { return }; onSelect?(); findRoot()?.setOpen(false) }
            else { super.keyDown(with: event) }
        }

        private func findRoot() -> Root? { var v: NSView? = superview; while let w = v { if let r = w as? Root { return r }; v = w.superview }; return nil }
        override public func accessibilityRole() -> NSAccessibility.Role? { .menuItem }
        override public func accessibilityLabel() -> String? { title }
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

    // MARK: - CheckboxItem

    public final class CheckboxItem: PrimitiveView {
        public var title = "" { didSet { label.stringValue = title } }
        @Published public var isChecked = false
        public var isDisabled = false
        public var onCheckedChange: ((Bool) -> Void)?

        private let label: NSTextField = { let l = NSTextField(labelWithString: ""); l.translatesAutoresizingMaskIntoConstraints = false; l.isEditable = false; l.isBordered = false; l.drawsBackground = false; return l }()
        private let indicator: NSTextField = { let l = NSTextField(labelWithString: ""); l.translatesAutoresizingMaskIntoConstraints = false; l.isEditable = false; l.isBordered = false; l.drawsBackground = false; return l }()

        public init(title: String = "") { self.title = title; super.init(frame: .zero); label.stringValue = title }
        @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }

        override public func commonInit() {
            super.commonInit(); wantsLayer = true
            addSubview(indicator); addSubview(label)
            NSLayoutConstraint.activate([
                indicator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8), indicator.widthAnchor.constraint(equalToConstant: 16), indicator.centerYAnchor.constraint(equalTo: centerYAnchor),
                label.leadingAnchor.constraint(equalTo: indicator.trailingAnchor, constant: 4), label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8), label.topAnchor.constraint(equalTo: topAnchor, constant: 4), label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            ])
            $isChecked.sink { [weak self] c in self?.indicator.stringValue = c ? "✓" : "" }.store(in: &cancellables)
        }

        override public var acceptsFirstResponder: Bool { !isDisabled }
        override public func mouseDown(with event: NSEvent) { guard !isDisabled else { return }; isChecked.toggle(); onCheckedChange?(isChecked) }
        override public func accessibilityRole() -> NSAccessibility.Role? { .menuItem }
    }

    // MARK: - RadioGroup

    public final class RadioGroup: PrimitiveView {
        @Published public var value: String?
        public var onValueChange: ((String?) -> Void)?
        private let stackView: NSStackView = { let s = NSStackView(); s.orientation = .vertical; s.spacing = 2; s.translatesAutoresizingMaskIntoConstraints = false; return s }()
        override public func commonInit() {
            super.commonInit(); addSubview(stackView); NSLayoutConstraint.activate([stackView.leadingAnchor.constraint(equalTo: leadingAnchor), stackView.trailingAnchor.constraint(equalTo: trailingAnchor), stackView.topAnchor.constraint(equalTo: topAnchor), stackView.bottomAnchor.constraint(equalTo: bottomAnchor)])
        }
        public func addRadioItem(_ view: NSView) { stackView.addArrangedSubview(view) }
        public func selectValue(_ v: String) { value = v; onValueChange?(v) }
        override public func accessibilityRole() -> NSAccessibility.Role? { .group }
    }

    // MARK: - RadioItem

    public final class RadioItem: PrimitiveView {
        public let value: String
        public var title = "" { didSet { label.stringValue = title } }
        public var isDisabled = false

        private let label: NSTextField = { let l = NSTextField(labelWithString: ""); l.translatesAutoresizingMaskIntoConstraints = false; l.isEditable = false; l.isBordered = false; l.drawsBackground = false; return l }()
        private let indicator: NSTextField = { let l = NSTextField(labelWithString: ""); l.translatesAutoresizingMaskIntoConstraints = false; l.isEditable = false; l.isBordered = false; l.drawsBackground = false; return l }()

        public init(value: String, title: String = "") { self.value = value; self.title = title; super.init(frame: .zero); label.stringValue = title }
        @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }

        override public func commonInit() {
            super.commonInit(); wantsLayer = true
            addSubview(indicator); addSubview(label)
            NSLayoutConstraint.activate([
                indicator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8), indicator.widthAnchor.constraint(equalToConstant: 16), indicator.centerYAnchor.constraint(equalTo: centerYAnchor),
                label.leadingAnchor.constraint(equalTo: indicator.trailingAnchor, constant: 4), label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8), label.topAnchor.constraint(equalTo: topAnchor, constant: 4), label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            ])
        }

        override public var acceptsFirstResponder: Bool { !isDisabled }
        override public func mouseDown(with event: NSEvent) { guard !isDisabled else { return }; findRadioGroup()?.selectValue(value) }

        private func findRadioGroup() -> RadioGroup? { var v: NSView? = superview; while let w = v { if let g = w as? RadioGroup { return g }; v = w.superview }; return nil }
        override public func accessibilityRole() -> NSAccessibility.Role? { .menuItem }
    }

    // MARK: - ItemIndicator

    public final class ItemIndicator: PrimitiveView {
        override public func commonInit() {
            super.commonInit()
            let w = widthAnchor.constraint(equalToConstant: 16); let h = heightAnchor.constraint(equalToConstant: 16)
            w.priority = .defaultHigh; h.priority = .defaultHigh; w.isActive = true; h.isActive = true
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

    // MARK: - Sub

    public final class Sub: PrimitiveView {
        @Published public var isOpen = false
        private let stackView: NSStackView = { let s = NSStackView(); s.orientation = .vertical; s.spacing = 0; s.translatesAutoresizingMaskIntoConstraints = false; return s }()
        override public func commonInit() {
            super.commonInit(); addSubview(stackView); NSLayoutConstraint.activate([stackView.leadingAnchor.constraint(equalTo: leadingAnchor), stackView.trailingAnchor.constraint(equalTo: trailingAnchor), stackView.topAnchor.constraint(equalTo: topAnchor), stackView.bottomAnchor.constraint(equalTo: bottomAnchor)])
        }
        public func addContent(_ view: NSView) { stackView.addArrangedSubview(view) }
        override public func accessibilityRole() -> NSAccessibility.Role? { .group }
    }

    // MARK: - SubTrigger

    public final class SubTrigger: PrimitiveView {
        public var title = "" { didSet { label.stringValue = title } }
        public var isDisabled = false

        private let label: NSTextField = { let l = NSTextField(labelWithString: ""); l.translatesAutoresizingMaskIntoConstraints = false; l.isEditable = false; l.isBordered = false; l.drawsBackground = false; return l }()
        private let arrow: NSTextField = { let l = NSTextField(labelWithString: "▸"); l.translatesAutoresizingMaskIntoConstraints = false; l.isEditable = false; l.isBordered = false; l.drawsBackground = false; l.alignment = .right; return l }()

        public init(title: String = "") { self.title = title; super.init(frame: .zero); label.stringValue = title }
        @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }

        override public func commonInit() {
            super.commonInit(); wantsLayer = true
            addSubview(label); addSubview(arrow)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8), label.topAnchor.constraint(equalTo: topAnchor, constant: 4), label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
                arrow.leadingAnchor.constraint(greaterThanOrEqualTo: label.trailingAnchor, constant: 8), arrow.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8), arrow.centerYAnchor.constraint(equalTo: centerYAnchor),
            ])
        }

        override public var acceptsFirstResponder: Bool { !isDisabled }
        override public func mouseEntered(with event: NSEvent) { findSub()?.isOpen = true }
        override public func mouseExited(with event: NSEvent) { findSub()?.isOpen = false }

        private func findSub() -> Sub? { var v: NSView? = superview; while let w = v { if let s = w as? Sub { return s }; v = w.superview }; return nil }
        override public func accessibilityRole() -> NSAccessibility.Role? { .menuItem }
    }

    // MARK: - SubContent

    public final class SubContent: PrimitiveView {
        private let presence = Presence(isPresent: false)
        private let stackView: NSStackView = { let s = NSStackView(); s.orientation = .vertical; s.spacing = 2; s.translatesAutoresizingMaskIntoConstraints = false; return s }()

        override public func commonInit() {
            super.commonInit(); wantsLayer = true; isHidden = true
            layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor; layer?.cornerRadius = 6
            layer?.borderWidth = 0.5; layer?.borderColor = NSColor.separatorColor.cgColor
            layer?.shadowOpacity = 0.2; layer?.shadowRadius = 8
            addSubview(stackView); NSLayoutConstraint.activate([stackView.topAnchor.constraint(equalTo: topAnchor, constant: 4), stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4), stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4), stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)])
            presence.$isMounted.removeDuplicates().sink { [weak self] m in self?.isHidden = !m }.store(in: &cancellables)
        }

        public func addItem(_ view: NSView) { stackView.addArrangedSubview(view) }

        public func bindToSub(_ sub: Sub) {
            sub.$isOpen.sink { [weak self] open in self?.presence.isPresent = open }.store(in: &cancellables)
        }

        override public func accessibilityRole() -> NSAccessibility.Role? { .menu }
    }
}
