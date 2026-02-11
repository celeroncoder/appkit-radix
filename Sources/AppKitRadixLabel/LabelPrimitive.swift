import AppKit
import AppKitRadixCore

/// Label — Accessible label wired to a form control.
///
/// Radix UI equivalent: `@radix-ui/react-label`
public enum LabelPrimitive {

    public final class Root: PrimitiveRoot {

        public var text: String {
            get { labelField.stringValue }
            set { labelField.stringValue = newValue }
        }

        public weak var htmlFor: NSView? {
            didSet { updateAccessibilityRelationship() }
        }

        private let labelField: NSTextField = {
            let f = NSTextField(labelWithString: "")
            f.translatesAutoresizingMaskIntoConstraints = false
            f.isEditable = false
            f.isSelectable = false
            f.isBezeled = false
            f.drawsBackground = false
            f.lineBreakMode = .byTruncatingTail
            return f
        }()

        public init(text: String = "", id: String = UUID().uuidString) {
            super.init(id: id)
            labelField.stringValue = text
        }

        @available(*, unavailable)
        public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

        override public var primitiveAccessibilityRole: NSAccessibility.Role { .staticText }

        override public func commonInit() {
            super.commonInit()
            addSubview(labelField)
            NSLayoutConstraint.activate([
                labelField.leadingAnchor.constraint(equalTo: leadingAnchor),
                labelField.trailingAnchor.constraint(equalTo: trailingAnchor),
                labelField.topAnchor.constraint(equalTo: topAnchor),
                labelField.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }

        override public func mouseDown(with event: NSEvent) {
            super.mouseDown(with: event)
            if let target = htmlFor { target.window?.makeFirstResponder(target) }
        }

        private func updateAccessibilityRelationship() {
            if let control = htmlFor {
                control.setAccessibilityTitleUIElement(self)
                setAccessibilityServesAsTitleForUIElements([control])
            } else {
                setAccessibilityServesAsTitleForUIElements(nil)
            }
        }

        override public func accessibilityRole() -> NSAccessibility.Role? { .staticText }
        override public func accessibilityValue() -> Any? { labelField.stringValue }
    }
}
