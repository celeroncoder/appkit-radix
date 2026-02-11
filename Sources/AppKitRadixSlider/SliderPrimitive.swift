import AppKit
import AppKitRadixCore
import Combine

/// Slider — Range value selection with draggable thumb(s).
///
/// Radix UI equivalent: `@radix-ui/react-slider`
public enum SliderPrimitive {

    public enum Orientation { case horizontal, vertical }
    private enum CK { static let values = "sliderValues" }

    // MARK: - Root

    public final class Root: PrimitiveRoot {

        public var values: [Double] = [0] {
            didSet {
                componentContext?.setState(values, for: CK.values)
                onValueChange?(values)
                needsLayout = true
                AccessibilityHelpers.postValueChanged(element: self)
            }
        }

        public var min: Double = 0
        public var max: Double = 100
        public var step: Double = 1
        public var orientation: Orientation = .horizontal
        public var isDisabled: Bool = false
        public var onValueChange: (([Double]) -> Void)?

        public init(defaultValue: [Double] = [0], min: Double = 0, max: Double = 100, step: Double = 1, id: String = UUID().uuidString) {
            self.min = min; self.max = max; self.step = step
            super.init(id: id)
            self.values = defaultValue
            componentContext?.setState(defaultValue, for: CK.values)
        }

        @available(*, unavailable)
        public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

        override public var primitiveAccessibilityRole: NSAccessibility.Role { .slider }

        override public func commonInit() {
            super.commonInit()
            let h = heightAnchor.constraint(equalToConstant: 20)
            h.priority = .defaultHigh; h.isActive = true
        }

        public func fraction(for value: Double) -> Double {
            guard max > min else { return 0 }
            return (value - min) / (max - min)
        }

        public func snapped(_ value: Double) -> Double {
            let clamped = Swift.max(min, Swift.min(max, value))
            return (clamped / step).rounded() * step
        }

        override public func accessibilityRole() -> NSAccessibility.Role? { .slider }
        override public func accessibilityValue() -> Any? { values.first.map { NSNumber(value: $0) } }
    }

    // MARK: - Track

    public final class Track: PrimitiveView {
        override public func commonInit() {
            super.commonInit()
            wantsLayer = true
            layer?.backgroundColor = NSColor.separatorColor.cgColor
            layer?.cornerRadius = 2
            let h = heightAnchor.constraint(equalToConstant: 4)
            h.priority = .defaultHigh; h.isActive = true
        }
    }

    // MARK: - Range

    public final class Range: PrimitiveView {
        override public func commonInit() {
            super.commonInit()
            wantsLayer = true
            layer?.backgroundColor = NSColor.controlAccentColor.cgColor
            layer?.cornerRadius = 2
            translatesAutoresizingMaskIntoConstraints = true
        }

        override public func didAttachToComponent() {
            super.didAttachToComponent()
            componentContext?.publisher(for: CK.values, default: [0.0])
                .sink { [weak self] (_: [Double]) in self?.superview?.needsLayout = true }
                .store(in: &cancellables)
        }
    }

    // MARK: - Thumb

    public final class Thumb: PrimitiveView {

        public var index: Int = 0
        private var isDragging = false
        private var dragStartX: CGFloat = 0

        override public func commonInit() {
            super.commonInit()
            wantsLayer = true
            layer?.backgroundColor = NSColor.white.cgColor
            layer?.cornerRadius = 8
            layer?.borderWidth = 1
            layer?.borderColor = NSColor.separatorColor.cgColor
            layer?.shadowOpacity = 0.15
            layer?.shadowRadius = 2
            translatesAutoresizingMaskIntoConstraints = true
            frame = NSRect(x: 0, y: 0, width: 16, height: 16)
        }

        override public var acceptsFirstResponder: Bool { true }

        override public func mouseDown(with event: NSEvent) {
            isDragging = true
            dragStartX = convert(event.locationInWindow, from: nil).x
        }

        override public func mouseDragged(with event: NSEvent) {
            guard isDragging, let root = findRoot(), let track = superview else { return }
            let loc = track.convert(event.locationInWindow, from: nil)
            let fraction = Double(loc.x / track.bounds.width)
            let raw = root.min + fraction * (root.max - root.min)
            let snapped = root.snapped(raw)
            var vals = root.values
            if index < vals.count { vals[index] = snapped }
            root.values = vals
        }

        override public func mouseUp(with event: NSEvent) { isDragging = false }

        override public func keyDown(with event: NSEvent) {
            guard let root = findRoot() else { super.keyDown(with: event); return }
            var vals = root.values
            guard index < vals.count else { return }
            switch event.keyCode {
            case 123, 125: vals[index] = root.snapped(vals[index] - root.step); root.values = vals
            case 124, 126: vals[index] = root.snapped(vals[index] + root.step); root.values = vals
            default: super.keyDown(with: event)
            }
        }

        private func findRoot() -> Root? {
            var v: NSView? = superview
            while let view = v {
                if let root = view as? Root { return root }
                v = view.superview
            }
            return nil
        }

        override public func accessibilityRole() -> NSAccessibility.Role? { .slider }
    }
}
