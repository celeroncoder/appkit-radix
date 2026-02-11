import AppKit

final class MainWindowController: NSWindowController {
    private let sidebar = SidebarViewController()

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "AppKitRadix Demo"
        window.center()
        window.setFrameAutosaveName("MainWindow")
        window.minSize = NSSize(width: 640, height: 400)

        self.init(window: window)

        let splitView = NSSplitViewController()
        let sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebar)
        sidebarItem.minimumThickness = 200
        sidebarItem.maximumThickness = 300

        let detail = DetailViewController()
        let detailItem = NSSplitViewItem(viewController: detail)
        detailItem.minimumThickness = 400

        splitView.addSplitViewItem(sidebarItem)
        splitView.addSplitViewItem(detailItem)

        window.contentViewController = splitView

        sidebar.onSelectComponent = { [weak self] component in
            self?.showDemo(for: component, in: detail)
        }
    }

    private func showDemo(for component: ComponentItem, in detail: DetailViewController) {
        detail.showDemo(for: component)
    }
}
