import AppKit
import AppKitRadixCore

/// Separator — Visual or semantic divider.
///
/// Radix UI equivalent: `@radix-ui/react-separator`
public enum SeparatorPrimitive {

    public enum Orientation { case horizontal, vertical }

    public final class Root: PrimitiveRoot {

        public var orientation: Orientation {
            didSet { invalidateLayout() }
        }

        public var isDecorative: Bool {
            didSet { updateAccessibility() }
        }

        public var thickness: CGFloat = 1 {
            didSet { invalidateLayout() }
        }

        public var separatorColor: NSColor = .separatorColor {
            didSet { needsDisplay = true }
        }

        private var thicknessConstraint: NSLayoutConstraint?

        public init(orientation: Orientation = .horizontal, isDecorative: Bool = false, id: String = UUID().uuidString) {
            self.orientation = orientation
            self.isDecorative = isDecorative
            super.init(id: id)
        }

        @available(*, unavailable)
        public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

        override public var primitiveAccessibilityRole: NSAccessibility.Role {
            isDecorative ? .unknown : .splitter
        }

        override public func commonInit() {
            super.commonInit()
            wantsLayer = true
            updateAccessibility()
            invalidateLayout()
        }

        override public var wantsUpdateLayer: Bool { true }

        override public func updateLayer() {
            layer?.backgroundColor = separatorColor.cgColor
        }

        override public var intrinsicContentSize: NSSize {
            switch orientation {
            case .horizontal: return NSSize(width: NSView.noIntrinsicMetric, height: thickness)
            case .vertical: return NSSize(width: thickness, height: NSView.noIntrinsicMetric)
            }
        }

        private func invalidateLayout() {
            thicknessConstraint?.isActive = false
            switch orientation {
            case .horizontal: thicknessConstraint = heightAnchor.constraint(equalToConstant: thickness)
            case .vertical: thicknessConstraint = widthAnchor.constraint(equalToConstant: thickness)
            }
            thicknessConstraint?.priority = .defaultHigh
            thicknessConstraint?.isActive = true
            invalidateIntrinsicContentSize()
            needsDisplay = true
        }

        private func updateAccessibility() {
            setAccessibilityElement(!isDecorative)
            setAccessibilityRole(isDecorative ? .unknown : .splitter)
            if !isDecorative {
                setAccessibilityOrientation(orientation == .horizontal ? .horizontal : .vertical)
            }
        }

        override public func accessibilityRole() -> NSAccessibility.Role? {
            isDecorative ? .unknown : .splitter
        }

        override public func isAccessibilityElement() -> Bool { !isDecorative }
    }
}
