public protocol FocusManaging: AnyObject {
    var onOpenAutoFocus: ((inout Bool) -> Void)? { get set }
    var onCloseAutoFocus: ((inout Bool) -> Void)? { get set }
    var trapFocus: Bool { get set }
    var restoreFocusOnClose: Bool { get set }
}
