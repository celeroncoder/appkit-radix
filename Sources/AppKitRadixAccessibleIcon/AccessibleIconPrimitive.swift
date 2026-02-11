import AppKit
import AppKitRadixCore

/// AccessibleIcon — Icon with screen reader label.
///
/// Radix UI equivalent: `@radix-ui/react-accessible-icon`
public enum AccessibleIconPrimitive {

    public final class Root: PrimitiveRoot {

        public var label: String {
            didSet { setAccessibilityLabel(label) }
        }

        public var image: NSImage? {
            get { imageView.image }
            set { imageView.image = newValue }
        }

        private let imageView: NSImageView = {
            let v = NSImageView()
            v.translatesAutoresizingMaskIntoConstraints = false
            v.imageScaling = .scaleProportionallyUpOrDown
            v.setAccessibilityElement(false)
            v.setAccessibilityRole(.unknown)
            return v
        }()

        public init(label: String, image: NSImage? = nil, id: String = UUID().uuidString) {
            self.label = label
            super.init(id: id)
            imageView.image = image
            setAccessibilityLabel(label)
        }

        @available(*, unavailable)
        public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

        override public var primitiveAccessibilityRole: NSAccessibility.Role { .image }

        override public func commonInit() {
            super.commonInit()
            addSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
                imageView.topAnchor.constraint(equalTo: topAnchor),
                imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }

        override public func isAccessibilityElement() -> Bool { true }
        override public func accessibilityRole() -> NSAccessibility.Role? { .image }
        override public func accessibilityLabel() -> String? { label }
        override public func accessibilityChildren() -> [Any]? { nil }
    }
}
