import AppKit
import AppKitRadixCore

public final class PopoverPositioning {
    public init() {}

    public func calculateFrame(
        for contentSize: NSSize,
        relativeTo anchorRect: NSRect,
        in screenFrame: NSRect,
        configuration: PositioningConfiguration
    ) -> NSRect {
        var origin = anchorPoint(for: anchorRect, edge: configuration.preferredEdge, size: contentSize)

        switch configuration.alignment {
        case .leading: break
        case .center:
            if configuration.preferredEdge == .minY || configuration.preferredEdge == .maxY {
                origin.x = anchorRect.midX - contentSize.width / 2
            } else {
                origin.y = anchorRect.midY - contentSize.height / 2
            }
        case .trailing:
            if configuration.preferredEdge == .minY || configuration.preferredEdge == .maxY {
                origin.x = anchorRect.maxX - contentSize.width
            } else {
                origin.y = anchorRect.maxY - contentSize.height
            }
        }

        origin.x += configuration.alignmentOffset

        switch configuration.preferredEdge {
        case .minY: origin.y -= configuration.offset
        case .maxY: origin.y += configuration.offset
        case .minX: origin.x -= configuration.offset
        case .maxX: origin.x += configuration.offset
        @unknown default: break
        }

        var frame = NSRect(origin: origin, size: contentSize)
        if configuration.constrainToScreen { frame = constrain(frame, to: screenFrame) }
        return frame
    }

    private func anchorPoint(for rect: NSRect, edge: NSRectEdge, size: NSSize) -> NSPoint {
        switch edge {
        case .minY: return NSPoint(x: rect.minX, y: rect.minY - size.height)
        case .maxY: return NSPoint(x: rect.minX, y: rect.maxY)
        case .minX: return NSPoint(x: rect.minX - size.width, y: rect.minY)
        case .maxX: return NSPoint(x: rect.maxX, y: rect.minY)
        @unknown default: return rect.origin
        }
    }

    private func constrain(_ rect: NSRect, to bounds: NSRect) -> NSRect {
        var r = rect
        if r.maxX > bounds.maxX { r.origin.x = bounds.maxX - r.width }
        if r.minX < bounds.minX { r.origin.x = bounds.minX }
        if r.maxY > bounds.maxY { r.origin.y = bounds.maxY - r.height }
        if r.minY < bounds.minY { r.origin.y = bounds.minY }
        return r
    }
}
