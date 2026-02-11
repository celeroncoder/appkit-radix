import AppKit

public final class FocusScope {
    private weak var scopeView: NSView?
    private var previousFirstResponder: NSResponder?

    public init() {}

    public func trap(in view: NSView) {
        scopeView = view
        previousFirstResponder = view.window?.firstResponder
        focusFirst()
    }

    public func release() {
        if let previous = previousFirstResponder, let window = scopeView?.window {
            window.makeFirstResponder(previous)
        }
        scopeView = nil
        previousFirstResponder = nil
    }

    public func focusFirst() {
        guard let view = scopeView else { return }
        if let first = findFocusableViews(in: view).first {
            first.window?.makeFirstResponder(first)
        }
    }

    public func focusLast() {
        guard let view = scopeView else { return }
        if let last = findFocusableViews(in: view).last {
            last.window?.makeFirstResponder(last)
        }
    }

    private func findFocusableViews(in view: NSView) -> [NSView] {
        var result: [NSView] = []
        for subview in view.subviews {
            if subview.acceptsFirstResponder && !subview.isHidden && subview.alphaValue > 0 {
                result.append(subview)
            }
            result.append(contentsOf: findFocusableViews(in: subview))
        }
        return result
    }
}
