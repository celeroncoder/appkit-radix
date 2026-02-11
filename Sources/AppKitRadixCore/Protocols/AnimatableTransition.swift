import AppKit

public protocol AnimatableTransition: AnyObject {
    var transitionDuration: TimeInterval { get set }
    var enterAnimation: CAAnimation? { get set }
    var exitAnimation: CAAnimation? { get set }
    var forceMount: Bool { get set }
}
