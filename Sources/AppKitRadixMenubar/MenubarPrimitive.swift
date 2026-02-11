import AppKit
import AppKitRadixCore
import AppKitRadixBehaviors
import Combine

/// Menubar — Horizontal menu bar with dropdown menus.
///
/// Radix UI equivalent: `@radix-ui/react-menubar`
public enum MenubarPrimitive {

    private enum CK { static let activeMenu = "menubarActive" }

    // MARK: - Root

    public final class Root: PrimitiveRoot {
        @Published private var _activeMenu: String?
        public var onActiveMenuChange: ((String?) -> Void)?

        public var activeMenu: String? { _activeMenu }
        public func setActiveMenu(_ id: String?) { _activeMenu = id; componentContext?.setState(id as Any, for: CK.activeMenu); onActiveMenuChange?(id) }

        private let stackView: NSStackView = { let s = NSStackView(); s.orientation = .horizontal; s.spacing = 0; s.translatesAutoresizingMaskIntoConstraints = false; return s }()
        private let rovingFocus = RovingFocusGroup()

        public override init(id: String = UUID().uuidString) { super.init(id: id) }
        @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }

        override public func commonInit() {
            super.commonInit(); wantsLayer = true
            rovingFocus.orientation = .horizontal; rovingFocus.install(on: self)
            addSubview(stackView); NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: topAnchor),
                stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
                stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }

        public func addMenu(_ view: NSView) { stackView.addArrangedSubview(view); rovingFocus.register(view) }
        override public func accessibilityRole() -> NSAccessibility.Role? { .menuBar }
    }

    // MARK: - Menu

    public final class Menu: PrimitiveView {
        public let menuId: String
        @Published public var isOpen = false

        private let stackView: NSStackView = { let s = NSStackView(); s.orientation = .vertical; s.spacing = 0; s.translatesAutoresizingMaskIntoConstraints = false; return s }()

        public init(menuId: String) { self.menuId = menuId; super.init(frame: .zero) }
        @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }

        override public func commonInit() {
            super.commonInit()
            addSubview(stackView); NSLayoutConstraint.activate([stackView.leadingAnchor.constraint(equalTo: leadingAnchor), stackView.trailingAnchor.constraint(equalTo: trailingAnchor), stackView.topAnchor.constraint(equalTo: topAnchor), stackView.bottomAnchor.constraint(equalTo: bottomAnchor)])
        }

        override public func didAttachToComponent() {
            super.didAttachToComponent()
            componentContext?.publisher(for: CK.activeMenu, default: Optional<String>.none as Any)
                .sink { [weak self] val in
                    guard let self else { return }
                    self.isOpen = (val as? String) == self.menuId
                }.store(in: &cancellables)
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
            addSubview(label); NSLayoutConstraint.activate([label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12), label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12), label.topAnchor.constraint(equalTo: topAnchor, constant: 6), label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6)])
        }

        override public var acceptsFirstResponder: Bool { true }

        override public func mouseDown(with event: NSEvent) {
            guard let menu = findMenu(), let root = findRoot() else { return }
            if root.activeMenu == menu.menuId { root.setActiveMenu(nil) }
            else { root.setActiveMenu(menu.menuId) }
        }

        override public func mouseEntered(with event: NSEvent) {
            guard let menu = findMenu(), let root = findRoot(), root.activeMenu != nil else { return }
            root.setActiveMenu(menu.menuId)
        }

        override public func keyDown(with event: NSEvent) {
            if event.keyCode == 49 || event.keyCode == 36 {
                guard let menu = findMenu(), let root = findRoot() else { return }
                if root.activeMenu == menu.menuId { root.setActiveMenu(nil) }
                else { root.setActiveMenu(menu.menuId) }
            } else { super.keyDown(with: event) }
        }

        private func findMenu() -> Menu? { var v: NSView? = superview; while let w = v { if let m = w as? Menu { return m }; v = w.superview }; return nil }
        private func findRoot() -> Root? { var v: NSView? = superview; while let w = v { if let r = w as? Root { return r }; v = w.superview }; return nil }
        override public func accessibilityRole() -> NSAccessibility.Role? { .menuBarItem }
        override public func accessibilityLabel() -> String? { title }
    }

    // MARK: - Content

    public final class Content: PrimitiveView {
        private let presence = Presence(isPresent: false)
        private let rovingFocus = RovingFocusGroup()

        private let stackView: NSStackView = { let s = NSStackView(); s.orientation = .vertical; s.spacing = 2; s.translatesAutoresizingMaskIntoConstraints = false; return s }()

        override public func commonInit() {
            super.commonInit(); wantsLayer = true; isHidden = true
            layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor; layer?.cornerRadius = 6
            layer?.borderWidth = 0.5; layer?.borderColor = NSColor.separatorColor.cgColor
            layer?.shadowOpacity = 0.2; layer?.shadowRadius = 8
            rovingFocus.orientation = .vertical; rovingFocus.install(on: self)
            addSubview(stackView); NSLayoutConstraint.activate([stackView.topAnchor.constraint(equalTo: topAnchor, constant: 4), stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4), stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4), stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)])
            presence.$isMounted.removeDuplicates().sink { [weak self] m in self?.isHidden = !m }.store(in: &cancellables)
        }

        public func bindToMenu(_ menu: Menu) {
            menu.$isOpen.sink { [weak self] open in self?.presence.isPresent = open }.store(in: &cancellables)
        }

        public func addItem(_ view: NSView) { stackView.addArrangedSubview(view); rovingFocus.register(view) }
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
        override public func mouseDown(with event: NSEvent) { guard !isDisabled else { return }; onSelect?(); findRoot()?.setActiveMenu(nil) }
        override public func keyDown(with event: NSEvent) {
            if event.keyCode == 49 || event.keyCode == 36 { guard !isDisabled else { return }; onSelect?(); findRoot()?.setActiveMenu(nil) }
            else { super.keyDown(with: event) }
        }

        private func findRoot() -> Root? { var v: NSView? = superview; while let w = v { if let r = w as? Root { return r }; v = w.superview }; return nil }
        override public func accessibilityRole() -> NSAccessibility.Role? { .menuItem }
        override public func accessibilityLabel() -> String? { title }
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
