import AppKit
import Combine

open class PrimitiveView: NSView {
    public var cancellables = Set<AnyCancellable>()
    public internal(set) weak var componentContext: ComponentContext?

    open var primitiveAccessibilityRole: NSAccessibility.Role { .unknown }

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    open func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
    }

    open func didAttachToComponent() {}
    open func willDetachFromComponent() {}

    // MARK: - Accessibility

    open override func accessibilityRole() -> NSAccessibility.Role? {
        primitiveAccessibilityRole
    }

    // MARK: - Context Discovery

    open override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        if superview != nil {
            discoverContext()
        } else {
            willDetachFromComponent()
            componentContext = nil
        }
    }

    private func discoverContext() {
        var current: NSView? = superview
        while let view = current {
            if let provider = view as? ComponentContextProviding {
                componentContext = provider.componentContext
                didAttachToComponent()
                return
            }
            current = view.superview
        }
    }
}
