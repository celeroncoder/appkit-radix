import AppKit
import Combine

public protocol ComponentContextProviding: AnyObject {
    var componentContext: ComponentContext? { get }
}

open class PrimitiveRoot: PrimitiveView, ComponentContextProviding {
    private let _context: ComponentContext

    open override var componentContext: ComponentContext? {
        get { _context }
        set {} // Root owns its context; setter is a no-op.
    }

    public init(id: String = UUID().uuidString) {
        _context = ComponentContext(id: id)
        super.init(frame: .zero)
    }

    public required init?(coder: NSCoder) {
        _context = ComponentContext(id: UUID().uuidString)
        super.init(coder: coder)
    }
}
