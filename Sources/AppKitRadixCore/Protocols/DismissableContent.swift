import AppKit

public enum DismissAction {
    case dismiss
    case prevent
}

public protocol DismissableContent: AnyObject {
    var onEscapeKeyDown: ((NSEvent) -> DismissAction)? { get set }
    var onClickOutside: ((NSEvent) -> DismissAction)? { get set }
    var onInteractOutside: ((NSEvent) -> DismissAction)? { get set }
}
