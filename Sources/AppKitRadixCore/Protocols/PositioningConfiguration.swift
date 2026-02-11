import AppKit

public struct PositioningConfiguration {
    public enum Alignment {
        case leading, center, trailing
    }

    public var preferredEdge: NSRectEdge = .minY
    public var offset: CGFloat = 0
    public var alignment: Alignment = .center
    public var alignmentOffset: CGFloat = 0
    public var avoidClipping: Bool = true
    public var constrainToScreen: Bool = true

    public init() {}
}
