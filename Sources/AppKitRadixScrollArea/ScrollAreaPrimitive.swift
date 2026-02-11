import AppKit
import AppKitRadixCore
import Combine

/// ScrollArea — Custom-styled scrollable region.
///
/// Radix UI equivalent: `@radix-ui/react-scroll-area`
public enum ScrollAreaPrimitive {

    public enum ScrollbarVisibility { case auto, always, scroll, hover }

    public final class Root: PrimitiveRoot {
        public var scrollbarVisibility: ScrollbarVisibility = .auto

        private var scrollView: NSScrollView?

        override public func commonInit() {
            super.commonInit()
            wantsLayer = true
            let sv = NSScrollView()
            sv.translatesAutoresizingMaskIntoConstraints = false
            sv.drawsBackground = false
            sv.hasVerticalScroller = true
            sv.hasHorizontalScroller = true
            sv.autohidesScrollers = true
            sv.borderType = .noBorder
            scrollView = sv
            addSubview(sv)
            NSLayoutConstraint.activate([
                sv.topAnchor.constraint(equalTo: topAnchor),
                sv.leadingAnchor.constraint(equalTo: leadingAnchor),
                sv.trailingAnchor.constraint(equalTo: trailingAnchor),
                sv.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }

        public func setDocumentView(_ view: NSView) {
            scrollView?.documentView = view
        }

        override public func accessibilityRole() -> NSAccessibility.Role? { .scrollArea }
    }

    public final class Viewport: PrimitiveView {
        private let contentView: NSView = { let v = NSView(); v.translatesAutoresizingMaskIntoConstraints = false; return v }()

        override public func commonInit() {
            super.commonInit()
            addSubview(contentView)
            NSLayoutConstraint.activate([
                contentView.topAnchor.constraint(equalTo: topAnchor),
                contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
                contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
                contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }

        public func addContent(_ view: NSView) { contentView.addSubview(view) }
        override public func accessibilityRole() -> NSAccessibility.Role? { .group }
    }

    public final class Scrollbar: PrimitiveView {
        public enum Orientation { case horizontal, vertical }
        public var orientation: Orientation = .vertical

        override public func commonInit() {
            super.commonInit(); wantsLayer = true
            layer?.backgroundColor = NSColor.separatorColor.withAlphaComponent(0.1).cgColor
        }
        override public func accessibilityRole() -> NSAccessibility.Role? { .scrollBar }
    }

    public final class Thumb: PrimitiveView {
        override public func commonInit() {
            super.commonInit(); wantsLayer = true
            layer?.backgroundColor = NSColor.separatorColor.cgColor; layer?.cornerRadius = 3
            let w = widthAnchor.constraint(equalToConstant: 6); w.priority = .defaultHigh; w.isActive = true
        }
    }

    public final class Corner: PrimitiveView {
        override public func commonInit() {
            super.commonInit(); wantsLayer = true
            let w = widthAnchor.constraint(equalToConstant: 6); let h = heightAnchor.constraint(equalToConstant: 6)
            w.priority = .defaultHigh; h.priority = .defaultHigh; w.isActive = true; h.isActive = true
        }
    }
}
