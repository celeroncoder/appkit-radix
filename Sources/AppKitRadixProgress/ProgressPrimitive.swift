import AppKit
import AppKitRadixCore
import Combine

/// Progress — Progress bar with determinate/indeterminate states.
///
/// Radix UI equivalent: `@radix-ui/react-progress`
public enum ProgressPrimitive {

    private enum CK {
        static let value = "progressValue"
        static let max = "progressMax"
    }

    // MARK: - Root

    public final class Root: PrimitiveRoot {

        public var value: Double? {
            didSet {
                componentContext?.setState(value as Any, for: CK.value)
                updateAccessibility()
            }
        }

        public var max: Double = 100 {
            didSet { componentContext?.setState(max, for: CK.max) }
        }

        private let trackLayer = CALayer()

        public init(value: Double? = nil, max: Double = 100, id: String = UUID().uuidString) {
            self.max = max
            super.init(id: id)
            self.value = value
        }

        @available(*, unavailable)
        public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

        override public var primitiveAccessibilityRole: NSAccessibility.Role { .progressIndicator }

        override public func commonInit() {
            super.commonInit()
            wantsLayer = true
            layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
            layer?.cornerRadius = 4
            let h = heightAnchor.constraint(equalToConstant: 8)
            h.priority = .defaultHigh
            h.isActive = true
        }

        private func updateAccessibility() {
            if let v = value {
                setAccessibilityValue(NSNumber(value: v))
                setAccessibilityLabel("Progress: \(Int(v / max * 100))%")
            } else {
                setAccessibilityValue(nil)
                setAccessibilityLabel("Loading")
            }
            AccessibilityHelpers.postValueChanged(element: self)
        }

        override public func accessibilityRole() -> NSAccessibility.Role? { .progressIndicator }
    }

    // MARK: - Indicator

    public final class Indicator: PrimitiveView {

        override public func commonInit() {
            super.commonInit()
            wantsLayer = true
            layer?.backgroundColor = NSColor.controlAccentColor.cgColor
            layer?.cornerRadius = 4
        }

        override public func didAttachToComponent() {
            super.didAttachToComponent()
            guard let ctx = componentContext else { return }
            ctx.publisher(for: CK.value, default: Optional<Double>.none as Any)
                .combineLatest(ctx.publisher(for: CK.max, default: 100.0 as Any))
                .sink { [weak self] _, _ in self?.needsLayout = true }
                .store(in: &cancellables)
        }

        override public func layout() {
            super.layout()
            guard let parent = superview, let ctx = componentContext else { return }
            let max = ctx.state(for: CK.max, default: 100.0 as Any) as? Double ?? 100
            let val = ctx.state(for: CK.value, default: Optional<Double>.none as Any) as? Double
            let fraction = val.map { min(Swift.max($0, 0), max) / max } ?? 0
            frame = NSRect(x: 0, y: 0, width: parent.bounds.width * fraction, height: parent.bounds.height)
        }
    }
}
