import AppKit
import AppKitRadixCore
import Combine

/// Avatar — User image with loading state and fallback.
///
/// Radix UI equivalent: `@radix-ui/react-avatar`
public enum AvatarPrimitive {

    public enum ImageStatus: String { case idle, loading, loaded, error }

    private enum CK { static let status = "imageStatus" }

    // MARK: - Root

    public final class Root: PrimitiveRoot {

        public var size: CGFloat = 40 {
            didSet { updateSize() }
        }

        private var widthC: NSLayoutConstraint?
        private var heightC: NSLayoutConstraint?

        public override init(id: String = UUID().uuidString) {
            super.init(id: id)
            componentContext?.setState(ImageStatus.idle.rawValue, for: CK.status)
        }

        @available(*, unavailable)
        public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

        override public func commonInit() {
            super.commonInit()
            wantsLayer = true
            layer?.masksToBounds = true
            updateSize()
        }

        override public func layout() {
            super.layout()
            layer?.cornerRadius = bounds.width / 2
        }

        private func updateSize() {
            widthC?.isActive = false
            heightC?.isActive = false
            widthC = widthAnchor.constraint(equalToConstant: size)
            heightC = heightAnchor.constraint(equalToConstant: size)
            widthC?.isActive = true
            heightC?.isActive = true
        }

        override public func accessibilityRole() -> NSAccessibility.Role? { .image }
    }

    // MARK: - Image

    public final class Image: PrimitiveView {

        public var url: URL? {
            didSet { if let u = url { loadImage(from: u) } }
        }

        public var image: NSImage? {
            didSet {
                imageView.image = image
                if image != nil {
                    componentContext?.setState(ImageStatus.loaded.rawValue, for: CK.status)
                    isHidden = false
                }
            }
        }

        private let imageView: NSImageView = {
            let v = NSImageView()
            v.translatesAutoresizingMaskIntoConstraints = false
            v.imageScaling = .scaleProportionallyUpOrDown
            return v
        }()

        override public func commonInit() {
            super.commonInit()
            isHidden = true
            addSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
                imageView.topAnchor.constraint(equalTo: topAnchor),
                imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }

        private func loadImage(from url: URL) {
            componentContext?.setState(ImageStatus.loading.rawValue, for: CK.status)
            URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if let data, let img = NSImage(data: data) {
                        self.imageView.image = img
                        self.isHidden = false
                        self.componentContext?.setState(ImageStatus.loaded.rawValue, for: CK.status)
                    } else {
                        self.componentContext?.setState(ImageStatus.error.rawValue, for: CK.status)
                    }
                }
            }.resume()
        }

        override public func accessibilityRole() -> NSAccessibility.Role? { .image }
    }

    // MARK: - Fallback

    public final class Fallback: PrimitiveView {

        public var text: String = "" {
            didSet { label.stringValue = text }
        }

        public var delayMs: Int = 0

        private let label: NSTextField = {
            let l = NSTextField(labelWithString: "")
            l.translatesAutoresizingMaskIntoConstraints = false
            l.alignment = .center
            l.font = .systemFont(ofSize: 14, weight: .medium)
            l.textColor = .secondaryLabelColor
            return l
        }()

        private var delayItem: DispatchWorkItem?

        override public func commonInit() {
            super.commonInit()
            wantsLayer = true
            layer?.backgroundColor = NSColor.controlColor.cgColor
            addSubview(label)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: centerXAnchor),
                label.centerYAnchor.constraint(equalTo: centerYAnchor),
            ])
        }

        override public func didAttachToComponent() {
            super.didAttachToComponent()
            guard let ctx = componentContext else { return }
            ctx.publisher(for: CK.status, default: ImageStatus.idle.rawValue)
                .sink { [weak self] (status: String) in self?.handleStatus(status) }
                .store(in: &cancellables)
        }

        private func handleStatus(_ status: String) {
            delayItem?.cancel()
            if status == ImageStatus.loaded.rawValue {
                isHidden = true
            } else if delayMs > 0 && status == ImageStatus.loading.rawValue {
                isHidden = true
                let item = DispatchWorkItem { [weak self] in self?.isHidden = false }
                delayItem = item
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(delayMs), execute: item)
            } else {
                isHidden = false
            }
        }

        override public func accessibilityRole() -> NSAccessibility.Role? { .staticText }
        override public func accessibilityLabel() -> String? { text }
    }
}
