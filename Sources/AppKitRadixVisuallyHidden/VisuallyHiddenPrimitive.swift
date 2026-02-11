import AppKit
import AppKitRadixCore

/// VisuallyHidden — Content hidden visually, visible to VoiceOver.
///
/// Radix UI equivalent: `@radix-ui/react-visually-hidden`
public enum VisuallyHiddenPrimitive {

    public final class Root: PrimitiveRoot {

        private var contentView: NSView?

        public override init(id: String = UUID().uuidString) {
            super.init(id: id)
        }

        @available(*, unavailable)
        public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

        override public func commonInit() {
            super.commonInit()
            translatesAutoresizingMaskIntoConstraints = true
            frame = NSRect(x: -10_000, y: -10_000, width: 1, height: 1)
            wantsLayer = true
            layer?.masksToBounds = true
        }

        public func setContent(_ view: NSView) {
            contentView?.removeFromSuperview()
            contentView = view
            view.translatesAutoresizingMaskIntoConstraints = true
            view.frame = bounds
            addSubview(view)
        }

        override public var intrinsicContentSize: NSSize { NSSize(width: 1, height: 1) }

        override public func layout() {
            super.layout()
            contentView?.frame = bounds
        }

        override public func isAccessibilityElement() -> Bool { true }
        override public func accessibilityRole() -> NSAccessibility.Role? { .group }
        override public func accessibilityChildren() -> [Any]? { contentView.map { [$0] } }
    }
}
