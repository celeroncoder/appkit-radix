import Foundation

struct ComponentItem: Hashable {
    let name: String
    let category: Category

    enum Category: String, CaseIterable {
        case overlays = "Overlays"
        case menus = "Menus"
        case navigation = "Navigation"
        case forms = "Form Controls"
        case disclosure = "Disclosure"
        case layout = "Layout / Display"
        case utilities = "Utilities"
    }

    static let all: [ComponentItem] = [
        // Overlays
        ComponentItem(name: "Dialog", category: .overlays),
        ComponentItem(name: "AlertDialog", category: .overlays),
        ComponentItem(name: "Popover", category: .overlays),
        ComponentItem(name: "HoverCard", category: .overlays),
        ComponentItem(name: "Tooltip", category: .overlays),
        ComponentItem(name: "Toast", category: .overlays),

        // Menus
        ComponentItem(name: "DropdownMenu", category: .menus),
        ComponentItem(name: "ContextMenu", category: .menus),
        ComponentItem(name: "Menubar", category: .menus),

        // Navigation
        ComponentItem(name: "NavigationMenu", category: .navigation),
        ComponentItem(name: "Tabs", category: .navigation),

        // Form Controls
        ComponentItem(name: "Checkbox", category: .forms),
        ComponentItem(name: "RadioGroup", category: .forms),
        ComponentItem(name: "Switch", category: .forms),
        ComponentItem(name: "Slider", category: .forms),
        ComponentItem(name: "Toggle", category: .forms),
        ComponentItem(name: "ToggleGroup", category: .forms),
        ComponentItem(name: "Select", category: .forms),
        ComponentItem(name: "Label", category: .forms),

        // Disclosure
        ComponentItem(name: "Accordion", category: .disclosure),
        ComponentItem(name: "Collapsible", category: .disclosure),

        // Layout / Display
        ComponentItem(name: "AspectRatio", category: .layout),
        ComponentItem(name: "Avatar", category: .layout),
        ComponentItem(name: "Progress", category: .layout),
        ComponentItem(name: "Separator", category: .layout),
        ComponentItem(name: "ScrollArea", category: .layout),
        ComponentItem(name: "Toolbar", category: .layout),

        // Utilities
        ComponentItem(name: "AccessibleIcon", category: .utilities),
        ComponentItem(name: "VisuallyHidden", category: .utilities),
    ]

    static func grouped() -> [(category: Category, items: [ComponentItem])] {
        Category.allCases.compactMap { category in
            let items = all.filter { $0.category == category }
            return items.isEmpty ? nil : (category, items)
        }
    }
}
