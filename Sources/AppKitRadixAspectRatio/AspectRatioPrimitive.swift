import AppKit
import AppKitRadixCore

/// AspectRatio — Content constrained to a width:height ratio.
///
/// Radix UI equivalent: `@radix-ui/react-aspect-ratio`
public enum AspectRatioPrimitive {

    public final class Root: PrimitiveRoot {

        public var ratio: CGFloat {
            didSet { guard ratio != oldValue else { return }; updateConstraint() }
        }

        private var aspectConstraint: NSLayoutConstraint?
        private var contentView: NSView?

        public init(ratio: CGFloat = 1.0, id: String = UUID().uuidString) {
            self.ratio = ratio
            super.init(id: id)
        }

        @available(*, unavailable)
        public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

        override public func commonInit() {
            super.commonInit()
            updateConstraint()
        }

        public func setContent(_ view: NSView) {
            contentView?.removeFromSuperview()
            contentView = view
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
            NSLayoutConstraint.activate([
                view.leadingAnchor.constraint(equalTo: leadingAnchor),
                view.trailingAnchor.constraint(equalTo: trailingAnchor),
                view.topAnchor.constraint(equalTo: topAnchor),
                view.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }

        private func updateConstraint() {
            aspectConstraint?.isActive = false
            let c = widthAnchor.constraint(equalTo: heightAnchor, multiplier: ratio)
            c.priority = .defaultHigh
            c.isActive = true
            aspectConstraint = c
        }

        override public func accessibilityRole() -> NSAccessibility.Role? { .group }
    }
}
