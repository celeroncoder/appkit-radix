# AppKitRadix

Headless, composable, accessibility-first UI primitives for macOS AppKit — inspired by [Radix UI](https://www.radix-ui.com/primitives).

AppKitRadix provides unstyled, behavior-rich building blocks that you compose and style to create polished native macOS interfaces. Every component manages its own state, wires up accessibility automatically, and exposes composable parts (Root, Trigger, Content, etc.) that you arrange however you want.

**Zero external dependencies.** Built entirely on AppKit, Combine, and Foundation.

## Prerequisites

| Requirement | Minimum |
|-------------|---------|
| macOS       | 13.0 (Ventura) |
| Swift       | 5.9+ |
| Xcode       | 15.0+ |

> **Important:** Make sure Xcode (not just Command Line Tools) is your active developer directory. This is required for running tests and the demo app:
> ```bash
> sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
> ```

## Getting Started

### Clone the repo

```bash
git clone https://github.com/celeroncoder/appkit-radix.git
cd appkit-radix
```

### Build the library

```bash
swift build
```

This compiles all 29 component targets, the core/behaviors layers, and the demo app.

### Run the Demo App

```bash
swift run DemoApp
```

This launches a macOS window with a sidebar listing all components by category. Select any component to see its demo.

### Open in Xcode

```bash
open Package.swift
```

This opens the entire workspace in Xcode. You'll see all library targets, the demo app, and test targets in the sidebar. Select the `DemoApp` scheme and hit Run.

### Run Tests

```bash
swift test
```

Or in Xcode: Product > Test (Cmd+U).

## Repository Structure

```
appkit-radix/
├── Package.swift                        # Root package manifest
├── Sources/
│   ├── AppKitRadix/                     # Umbrella — `import AppKitRadix` gets everything
│   ├── AppKitRadixCore/                 # Foundation layer
│   │   ├── PrimitiveView.swift          # Base class for all primitive views
│   │   ├── PrimitiveRoot.swift          # Base class for Root parts (owns context)
│   │   ├── ComponentContext.swift       # Shared state container
│   │   ├── StateManagement/             # State protocols
│   │   │   ├── OpenStateManaging.swift
│   │   │   ├── ValueStateManaging.swift
│   │   │   └── CheckedStateManaging.swift
│   │   ├── Protocols/                   # Behavior protocols
│   │   │   ├── DismissableContent.swift
│   │   │   ├── FocusManaging.swift
│   │   │   ├── AnimatableTransition.swift
│   │   │   └── PositioningConfiguration.swift
│   │   ├── Accessibility/               # Accessibility helpers
│   │   └── Utilities/                   # WeakRef, Combine extensions
│   │
│   ├── AppKitRadixBehaviors/            # Behavior utilities layer
│   │   ├── FocusScope.swift             # Focus trapping for modals
│   │   ├── DismissableRegion.swift      # Click-outside / Escape handling
│   │   ├── Presence.swift               # Mount/unmount with animation
│   │   ├── RovingFocusGroup.swift       # Arrow key navigation
│   │   ├── Collection.swift             # Item registry
│   │   └── PopoverPositioning.swift     # Floating content positioning
│   │
│   ├── AppKitRadixDialog/               # Each component gets its own target
│   ├── AppKitRadixPopover/
│   ├── AppKitRadixTabs/
│   ├── ...                              # 29 component targets total
│   └── AppKitRadixVisuallyHidden/
│
├── Tests/                               # Test targets mirror source targets
│   ├── AppKitRadixCoreTests/
│   ├── AppKitRadixBehaviorsTests/
│   └── ...
│
├── Examples/
│   └── DemoApp/                         # macOS demo application
│       ├── main.swift
│       ├── AppDelegate.swift
│       ├── MainWindowController.swift   # Split view with sidebar + detail
│       ├── SidebarViewController.swift  # Component list by category
│       ├── DetailViewController.swift   # Component demo area
│       └── ComponentItem.swift          # Component catalog
│
├── proposal.md                          # Full design proposal
├── LICENSE                              # MIT
└── .gitignore
```

## Component Catalog

29 components across 7 categories:

| Category | Components |
|----------|-----------|
| **Overlays** | Dialog, AlertDialog, Popover, HoverCard, Tooltip, Toast |
| **Menus** | DropdownMenu, ContextMenu, Menubar |
| **Navigation** | NavigationMenu, Tabs |
| **Form Controls** | Checkbox, RadioGroup, Switch, Slider, Toggle, ToggleGroup, Select, Label |
| **Disclosure** | Accordion, Collapsible |
| **Layout / Display** | AspectRatio, Avatar, Progress, Separator, ScrollArea, Toolbar |
| **Utilities** | AccessibleIcon, VisuallyHidden |

## Importing

Import everything:

```swift
import AppKitRadix
```

Or import only what you need:

```swift
import AppKitRadixDialog
import AppKitRadixTabs
```

## Adding as a Dependency

In your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/celeroncoder/appkit-radix.git", from: "0.1.0")
]

// In your target:
.target(name: "MyApp", dependencies: [
    .product(name: "AppKitRadix", package: "appkit-radix"),     // Everything
    // OR pick individual components:
    // .product(name: "AppKitRadixDialog", package: "appkit-radix"),
])
```

Or in Xcode: File > Add Package Dependencies > paste the GitHub URL.

## Development Workflow

### Adding a new component

1. Create `Sources/AppKitRadixMyComponent/MyComponentPrimitive.swift`
2. Add the target to `Package.swift` (in the `targets` array with appropriate dependencies)
3. Add the library product to the `products` array
4. Add it to the `componentTargets` list at the top of `Package.swift`
5. Add the `@_exported import` to `Sources/AppKitRadix/AppKitRadix.swift`
6. Add a demo entry to `Examples/DemoApp/ComponentItem.swift`
7. Run `swift build` to verify

### Architecture layers

```
Layer 4: Your App (composes and styles primitives)
Layer 3: Component Primitives (Dialog, Popover, Tabs, ...)
Layer 2: Behavior Utilities (FocusScope, DismissableRegion, Presence, ...)
Layer 1: Foundation (PrimitiveView, ComponentContext, state protocols)
```

Every component depends on **AppKitRadixCore**. Components that need focus trapping, dismiss handling, or arrow-key navigation also depend on **AppKitRadixBehaviors**.

### Running just one test target

```bash
swift test --filter AppKitRadixCoreTests
```

## Design Principles

- **Accessibility first** — VoiceOver, keyboard navigation, focus management built in
- **Composable parts** — Complex components decomposed into cooperating sub-parts
- **System-native defaults** — Respects Dark Mode, accent colors, accessibility settings
- **Controlled & uncontrolled** — Every stateful component works both ways
- **Incremental adoption** — Import only the components you need
- **Combine-powered** — State changes propagate via publishers
- **Programmatic-first** — No XIBs, no storyboards, everything in code

See [proposal.md](./proposal.md) for the full design document with detailed component specs.

## License

MIT
