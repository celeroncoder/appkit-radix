# AppKitRadix: Headless UI Primitives for macOS AppKit

## Executive Summary

**AppKitRadix** is a headless, composable, accessibility-first UI primitive library for macOS AppKit — directly inspired by [Radix UI](https://www.radix-ui.com/primitives). It provides unstyled, behavior-rich building blocks that developers compose and style to create polished native macOS interfaces.

There is currently **no equivalent library** in the AppKit ecosystem. While SwiftUI offers high-level declarative components, and libraries like DSFAppKitBuilder (now archived) attempted declarative wrappers, no one has built a Radix-style part-based primitive system for AppKit. AppKitRadix fills this gap.

The library ships as a **Swift Package** with a monorepo structure — individual component targets that can be imported selectively or via an umbrella import. A companion **demo app** showcases every primitive in action.

---

## Table of Contents

1. [Problem Statement](#1-problem-statement)
2. [Design Principles](#2-design-principles)
3. [Architecture](#3-architecture)
4. [Component Catalog](#4-component-catalog)
5. [API Patterns](#5-api-patterns)
6. [Core Infrastructure](#6-core-infrastructure)
7. [Component Specifications](#7-component-specifications)
8. [Project Structure](#8-project-structure)
9. [Demo Application](#9-demo-application)
10. [Implementation Phases](#10-implementation-phases)
11. [Packaging & Distribution](#11-packaging--distribution)
12. [Appendix: Radix UI Mapping](#appendix-radix-ui-mapping)

---

## 1. Problem Statement

### The Gap

In web development, Radix UI solved a critical problem: developers needed accessible, well-behaved UI components without being locked into a specific design system. Radix provides **headless primitives** — all the behavior, accessibility, and keyboard navigation built in, with zero styling opinions.

AppKit has no equivalent. Developers face two options:

1. **Use raw AppKit controls** — functional but require manual coordination of state, accessibility, keyboard navigation, and composition between related controls (e.g., a trigger button + its popover + its overlay).

2. **Use SwiftUI** — declarative and ergonomic but not AppKit. Many macOS apps still need or prefer AppKit for fine-grained control, performance, or compatibility.

### What We're Building

A Swift package that provides **composable, part-based UI primitives** for AppKit. Each primitive:

- Manages its own state (open/closed, selected, expanded, etc.)
- Wires up accessibility automatically (VoiceOver, keyboard navigation)
- Exposes composable "parts" (Root, Trigger, Content, etc.) that developers arrange and style
- Works with system appearance by default but allows full customization
- Supports both controlled and uncontrolled usage patterns

---

## 2. Design Principles

These principles guide every API decision in AppKitRadix, directly adapted from Radix UI's philosophy for the native macOS context.

### 2.1 Accessibility First

Every component implements macOS accessibility out of the box:

- **VoiceOver**: Correct `NSAccessibility` roles, labels, values, and notifications
- **Keyboard navigation**: Full keyboard support — Tab, Arrow keys, Enter, Escape, Space — matching [WAI-ARIA Authoring Practices](https://www.w3.org/WAI/ARIA/apg/) where applicable
- **Focus management**: Automatic focus trapping in modals, focus restoration on dismiss, roving tabindex equivalent for grouped controls

### 2.2 Composable Parts

Complex components are decomposed into cooperating sub-parts. Each part is a standalone `NSView` subclass (or controller) that coordinates with siblings through a shared state context. Developers compose parts freely:

```swift
let dialog = DialogPrimitive.Root()
let trigger = DialogPrimitive.Trigger(title: "Open Settings")
let content = DialogPrimitive.Content()
let title = DialogPrimitive.Title(text: "Settings")
let closeButton = DialogPrimitive.Close(title: "Done")

// Compose however you want
content.addPart(title)
content.addPart(settingsForm)  // Your custom view
content.addPart(closeButton)

dialog.trigger = trigger
dialog.content = content
```

### 2.3 System-Native by Default, Customizable Always

Unlike web Radix (which ships zero CSS), AppKit components have inherent system styling. AppKitRadix embraces this:

- **Default**: Components render with standard macOS appearance (respecting Dark Mode, accent colors, accessibility settings)
- **Customizable**: Every visual part exposes a `style` protocol for full override — backgrounds, fonts, spacing, animations
- **No style lock-in**: The primitive behavior layer is cleanly separated from any default appearance

### 2.4 Controlled & Uncontrolled

Every stateful component works in two modes:

```swift
// Uncontrolled — component manages its own state
let accordion = AccordionPrimitive.Root(type: .single)

// Controlled — you manage state externally
let accordion = AccordionPrimitive.Root(type: .single)
accordion.bind(expandedValue: myPublisher, onExpandedChange: { newValue in ... })
```

### 2.5 Incremental Adoption

Import only what you need. Each primitive is an independent Swift target with minimal dependencies:

```swift
import AppKitRadixDialog    // Just dialogs
import AppKitRadixPopover   // Just popovers
import AppKitRadix          // Or import everything
```

### 2.6 Combine-Powered Reactivity

State changes propagate via Combine publishers. Components expose `@Published` properties and accept `AnyPublisher` bindings, making integration with existing Combine-based architectures seamless.

### 2.7 Programmatic-First

No XIBs, no storyboards. Every component is created and configured entirely in code. This makes components testable, versionable, and composable without Interface Builder dependencies.

---

## 3. Architecture

### 3.1 Layer Model

AppKitRadix follows a four-layer architecture mirroring Radix UI's internal structure:

```
┌─────────────────────────────────────────────────────┐
│  Layer 4: Consumer Application                       │
│  Your macOS app — composes and styles primitives     │
├─────────────────────────────────────────────────────┤
│  Layer 3: Component Primitives                       │
│  Dialog, Popover, Menu, Select, Accordion, Tabs...  │
├─────────────────────────────────────────────────────┤
│  Layer 2: Behavior Utilities                         │
│  FocusScope, DismissableRegion, Presence,           │
│  PopoverPositioning, Collection, RovingFocus        │
├─────────────────────────────────────────────────────┤
│  Layer 1: Foundation                                 │
│  Primitive base, State management, Accessibility,   │
│  Composition helpers, Event handling                 │
└─────────────────────────────────────────────────────┘
```

### 3.2 Part-Based Component Model

Each component is a namespace (Swift `enum` used as namespace) containing its parts:

```swift
public enum DialogPrimitive {
    public class Root: PrimitiveRoot { ... }
    public class Trigger: PrimitiveView { ... }
    public class Content: PrimitiveView { ... }
    public class Overlay: PrimitiveView { ... }
    public class Close: PrimitiveView { ... }
    public class Title: PrimitiveView { ... }
    public class Description: PrimitiveView { ... }
}
```

Parts communicate through a shared `ComponentContext` (analogous to Radix's React Context). The `Root` owns the context; child parts discover it through the view hierarchy.

### 3.3 State Flow

```
┌──────────┐    publishes     ┌────────────────┐    observes    ┌──────────┐
│  Root     │ ──────────────> │ ComponentState  │ <──────────── │  Parts   │
│ (owner)   │                 │ (@Published)    │               │ (views)  │
└──────────┘                  └────────────────┘               └──────────┘
      ▲                              │
      │         onStateChange        │
      └──────────────────────────────┘
            (optional callback)
```

- `Root` creates and owns a `ComponentState` object
- Parts subscribe to relevant `@Published` properties via Combine
- External code can bind to state for controlled mode
- State changes trigger accessibility notifications automatically

### 3.4 Accessibility Architecture

Each primitive part conforms to `NSAccessibility` protocols automatically:

```swift
public class PrimitiveView: NSView {
    // Every primitive view has built-in accessibility
    override public func accessibilityRole() -> NSAccessibility.Role? { ... }
    override public func accessibilityLabel() -> String? { ... }
    override public func accessibilityValue() -> Any? { ... }

    // Subclasses override to declare their role
    open var primitiveAccessibilityRole: NSAccessibility.Role { .unknown }
}
```

Components post `NSAccessibility.Notification` events when state changes (e.g., dialog opens → `.layoutChanged` with focus on content).

---

## 4. Component Catalog

AppKitRadix targets **30 component primitives** across 7 categories, mapping 1:1 to Radix UI's primitive set. Components are listed with their Radix equivalent and the AppKit controls they build upon or replace.

### 4.1 Overlay / Dialog Components

| Component | Description | Radix Equivalent | AppKit Foundation |
|-----------|-------------|-------------------|-------------------|
| **Dialog** | Modal window overlaid on primary content with focus trap | `@radix-ui/react-dialog` | `NSPanel` / `NSWindow` as sheet |
| **AlertDialog** | Blocking modal requiring user acknowledgment; no outside dismiss | `@radix-ui/react-alert-dialog` | `NSAlert` (enhanced) |
| **Popover** | Floating panel anchored to a trigger element | `@radix-ui/react-popover` | `NSPopover` (wrapped) |
| **HoverCard** | Preview card appearing on hover over a trigger | `@radix-ui/react-hover-card` | `NSPopover` with hover tracking |
| **Tooltip** | Small informational popup on hover/focus | `@radix-ui/react-tooltip` | `NSToolTipOwner` / custom overlay |
| **Toast** | Temporary auto-dismissing notification | `@radix-ui/react-toast` | Custom overlay window |

### 4.2 Menu Components

| Component | Description | Radix Equivalent | AppKit Foundation |
|-----------|-------------|-------------------|-------------------|
| **DropdownMenu** | Action menu triggered by a button | `@radix-ui/react-dropdown-menu` | `NSMenu` + `NSPopUpButton` |
| **ContextMenu** | Right-click contextual menu | `@radix-ui/react-context-menu` | `NSMenu` (context) |
| **Menubar** | Horizontal menu bar with dropdown menus | `@radix-ui/react-menubar` | `NSMenu` (main menu) |

### 4.3 Navigation Components

| Component | Description | Radix Equivalent | AppKit Foundation |
|-----------|-------------|-------------------|-------------------|
| **NavigationMenu** | Site/app navigation with dropdown panels | `@radix-ui/react-navigation-menu` | `NSToolbar` + custom views |
| **Tabs** | Tabbed content switching | `@radix-ui/react-tabs` | `NSTabView` (reimagined) |

### 4.4 Form / Input Components

| Component | Description | Radix Equivalent | AppKit Foundation |
|-----------|-------------|-------------------|-------------------|
| **Checkbox** | Checkable input (checked/unchecked/indeterminate) | `@radix-ui/react-checkbox` | `NSButton` (checkbox type) |
| **RadioGroup** | Mutually exclusive option selection | `@radix-ui/react-radio-group` | `NSButton` (radio type) |
| **Switch** | Toggle on/off | `@radix-ui/react-switch` | `NSSwitch` |
| **Slider** | Range value selection with draggable thumb(s) | `@radix-ui/react-slider` | `NSSlider` (enhanced) |
| **Toggle** | Two-state button (pressed/unpressed) | `@radix-ui/react-toggle` | `NSButton` (toggle type) |
| **ToggleGroup** | Group of toggles with single/multiple selection | `@radix-ui/react-toggle-group` | `NSSegmentedControl` alternative |
| **Select** | Custom dropdown for choosing from a list | `@radix-ui/react-select` | `NSPopUpButton` (reimagined) |
| **Label** | Accessible label wired to a form control | `@radix-ui/react-label` | `NSTextField` (label mode) |

### 4.5 Disclosure / Collapsible Components

| Component | Description | Radix Equivalent | AppKit Foundation |
|-----------|-------------|-------------------|-------------------|
| **Accordion** | Vertically stacked collapsible sections | `@radix-ui/react-accordion` | `NSStackView` + disclosure |
| **Collapsible** | Single show/hide section | `@radix-ui/react-collapsible` | `NSStackView` + animation |

### 4.6 Layout / Display Components

| Component | Description | Radix Equivalent | AppKit Foundation |
|-----------|-------------|-------------------|-------------------|
| **AspectRatio** | Content constrained to a width:height ratio | `@radix-ui/react-aspect-ratio` | `NSView` + constraints |
| **Avatar** | User image with loading state and fallback | `@radix-ui/react-avatar` | `NSImageView` + fallback |
| **Progress** | Progress bar with determinate/indeterminate states | `@radix-ui/react-progress` | `NSProgressIndicator` |
| **Separator** | Visual or semantic divider | `@radix-ui/react-separator` | `NSBox` (separator type) |
| **ScrollArea** | Custom-styled scrollable region | `@radix-ui/react-scroll-area` | `NSScrollView` (wrapped) |
| **Toolbar** | Container for grouped actions | `@radix-ui/react-toolbar` | `NSStackView` + roving focus |

### 4.7 Utility Primitives

| Component | Description | Radix Equivalent | AppKit Foundation |
|-----------|-------------|-------------------|-------------------|
| **AccessibleIcon** | Icon with screen reader label | `@radix-ui/react-accessible-icon` | `NSImageView` + a11y |
| **VisuallyHidden** | Content hidden visually, visible to VoiceOver | `@radix-ui/react-visually-hidden` | `NSView` (off-screen positioning) |

---

## 5. API Patterns

These are the recurring API patterns that provide consistency across all components.

### 5.1 Root / Trigger / Content Pattern

Most interactive components follow this anatomy:

```swift
// The universal pattern
let root = ComponentPrimitive.Root()       // State container
let trigger = ComponentPrimitive.Trigger() // Opens/activates
let content = ComponentPrimitive.Content() // The revealed content

root.trigger = trigger
root.content = content
parentView.addSubview(root.view)
```

### 5.2 State Properties

Every stateful component exposes consistent state interfaces:

```swift
// Open/Close state (Dialog, Popover, Collapsible, menus)
public protocol OpenStateManaging {
    var isOpen: Bool { get }
    var isOpenPublisher: AnyPublisher<Bool, Never> { get }
    var defaultOpen: Bool { get set }
    func setOpen(_ open: Bool)
    var onOpenChange: ((Bool) -> Void)? { get set }
}

// Value state (Select, RadioGroup, Tabs)
public protocol ValueStateManaging {
    associatedtype Value: Hashable
    var value: Value? { get }
    var valuePublisher: AnyPublisher<Value?, Never> { get }
    var defaultValue: Value? { get set }
    func setValue(_ value: Value?)
    var onValueChange: ((Value?) -> Void)? { get set }
}

// Checked state (Checkbox, Switch, Toggle)
public protocol CheckedStateManaging {
    var checkedState: CheckedState { get }  // .checked, .unchecked, .indeterminate
    var checkedPublisher: AnyPublisher<CheckedState, Never> { get }
    var defaultChecked: CheckedState { get set }
    func setChecked(_ state: CheckedState)
    var onCheckedChange: ((CheckedState) -> Void)? { get set }
}
```

### 5.3 Positioning Configuration

For floating components (Popover, Tooltip, HoverCard, menus):

```swift
public struct PositioningConfiguration {
    public var preferredEdge: NSRectEdge = .minY  // bottom
    public var offset: CGFloat = 0
    public var alignment: Alignment = .center     // .leading, .center, .trailing
    public var alignmentOffset: CGFloat = 0
    public var avoidClipping: Bool = true
    public var constrainToScreen: Bool = true
}
```

### 5.4 Content Interaction

For dismissable components:

```swift
public protocol DismissableContent {
    var onEscapeKeyDown: ((NSEvent) -> DismissAction)? { get set }
    var onClickOutside: ((NSEvent) -> DismissAction)? { get set }
    var onInteractOutside: ((NSEvent) -> DismissAction)? { get set }
}

public enum DismissAction {
    case dismiss    // Allow dismissal
    case prevent    // Prevent dismissal
}
```

### 5.5 Focus Management

```swift
public protocol FocusManaging {
    var onOpenAutoFocus: ((inout Bool) -> Void)? { get set }   // Bool = shouldPreventDefault
    var onCloseAutoFocus: ((inout Bool) -> Void)? { get set }
    var trapFocus: Bool { get set }
    var restoreFocusOnClose: Bool { get set }
}
```

### 5.6 Animation Support

Components expose state-change hooks and support animated transitions:

```swift
public protocol AnimatableTransition {
    var transitionDuration: TimeInterval { get set }
    var enterAnimation: NSView.AnimationOptions? { get set }
    var exitAnimation: NSView.AnimationOptions? { get set }
    var forceMount: Bool { get set }  // Keep in view hierarchy even when hidden
}
```

Components also expose their current state via observable properties, letting consumers drive animations with `NSAnimationContext`, Core Animation, or any animation framework.

---

## 6. Core Infrastructure

The foundation layer provides shared functionality used by all primitives.

### 6.1 PrimitiveView (Base Class)

```swift
/// Base class for all AppKitRadix primitive views.
/// Provides accessibility defaults, state observation, and composition support.
open class PrimitiveView: NSView {
    /// The component context this part belongs to (discovered via view hierarchy)
    public internal(set) weak var componentContext: ComponentContext?

    /// Override in subclasses to define the accessibility role
    open var primitiveAccessibilityRole: NSAccessibility.Role { .unknown }

    /// Combine cancellables for state subscriptions
    public var cancellables = Set<AnyCancellable>()

    /// Called when the part is added to a component hierarchy
    open func didAttachToComponent() {}

    /// Called when the part is removed from a component hierarchy
    open func willDetachFromComponent() {}
}
```

### 6.2 ComponentContext

```swift
/// Shared state container for a component's parts.
/// Analogous to Radix UI's React Context usage.
public class ComponentContext: ObservableObject {
    /// Unique identifier for this component instance
    public let id: String

    /// Whether the component is disabled
    @Published public var isDisabled: Bool = false

    /// Arbitrary state storage for component-specific data
    private var stateStore: [String: Any] = [:]

    public func state<T>(for key: String, default defaultValue: T) -> T { ... }
    public func setState<T>(_ value: T, for key: String) { ... }
    public func publisher<T>(for key: String) -> AnyPublisher<T, Never> { ... }
}
```

### 6.3 FocusScope

Manages focus trapping for modal components:

```swift
public class FocusScope {
    /// Traps Tab/Shift-Tab focus within the given view hierarchy
    public func trap(in view: NSView)

    /// Releases the focus trap and restores previous focus
    public func release()

    /// Moves focus to the first focusable element within scope
    public func focusFirst()

    /// Moves focus to the last focusable element within scope
    public func focusLast()
}
```

### 6.4 DismissableRegion

Handles click-outside and escape-key dismissal:

```swift
public class DismissableRegion {
    /// Monitors for clicks outside the specified view
    public func monitor(view: NSView, onClickOutside: @escaping (NSEvent) -> DismissAction)

    /// Monitors for Escape key
    public func monitorEscape(onEscape: @escaping (NSEvent) -> DismissAction)

    /// Stops all monitoring
    public func stopMonitoring()
}
```

### 6.5 Presence

Controls mount/unmount lifecycle with animation support:

```swift
public class Presence {
    @Published public var isPresent: Bool
    @Published public private(set) var isMounted: Bool

    /// When true, keeps the view mounted even when not present (for animations)
    public var forceMount: Bool = false

    /// Transition duration — view stays mounted this long after isPresent becomes false
    public var exitDuration: TimeInterval = 0
}
```

### 6.6 RovingFocus

Implements arrow-key navigation within grouped controls:

```swift
public class RovingFocusGroup {
    public var orientation: Orientation = .horizontal  // .horizontal, .vertical, .both
    public var loop: Bool = true

    /// Register a focusable item
    public func register(_ view: NSView)

    /// Remove a focusable item
    public func unregister(_ view: NSView)

    /// Install keyboard monitoring on the container
    public func install(on container: NSView)
}
```

### 6.7 Collection

Item registry for components with dynamic children (menus, selects, tabs):

```swift
public class Collection<Item: Hashable> {
    @Published public private(set) var items: [Item] = []

    public func register(_ item: Item)
    public func unregister(_ item: Item)
    public func item(at index: Int) -> Item?
    public func index(of item: Item) -> Int?
}
```

---

## 7. Component Specifications

Detailed API specification for each component primitive. Each spec covers: parts, state, key behaviors, and accessibility.

### 7.1 Dialog

**Purpose**: Modal window overlaid on primary content. Traps focus, dims background.

**Parts**:

| Part | Type | Description |
|------|------|-------------|
| `Root` | State container | Manages open/closed state |
| `Trigger` | `NSButton` subclass | Toggles dialog open |
| `Overlay` | `NSView` subclass | Semi-transparent backdrop covering the window |
| `Content` | `NSView` subclass | The modal panel, receives focus |
| `Close` | `NSButton` subclass | Closes the dialog |
| `Title` | `NSTextField` subclass | Accessible title — announced by VoiceOver on open |
| `Description` | `NSTextField` subclass | Accessible description |

**State**: `OpenStateManaging`

**Behaviors**:
- Opens as a sheet or floating panel (configurable)
- Focus trapped within Content when open
- Escape key closes (configurable via `onEscapeKeyDown`)
- Click on Overlay closes (configurable via `onClickOutside`)
- Focus restores to Trigger on close
- Title announced by VoiceOver when opened

**Accessibility**: Role `.dialog` or `.sheet`, `aria-labelledby` equivalent via Title, `aria-describedby` via Description.

---

### 7.2 AlertDialog

**Purpose**: Blocking modal for destructive/critical actions. Cannot be dismissed by clicking outside.

**Parts**:

| Part | Type | Description |
|------|------|-------------|
| `Root` | State container | Manages open/closed state |
| `Trigger` | `NSButton` subclass | Opens the alert |
| `Overlay` | `NSView` subclass | Backdrop (non-dismissable) |
| `Content` | `NSView` subclass | Alert panel |
| `Title` | `NSTextField` subclass | Alert title |
| `Description` | `NSTextField` subclass | Alert message |
| `Cancel` | `NSButton` subclass | Cancel action — closes dialog |
| `Action` | `NSButton` subclass | Destructive/confirm action |

**Behaviors**:
- Click outside does NOT close
- Escape triggers Cancel action
- Focus starts on Cancel button (safe default)

**Accessibility**: Role `.dialog`, announced as alert.

---

### 7.3 Popover

**Purpose**: Floating panel anchored to a trigger, for rich interactive content.

**Parts**:

| Part | Type | Description |
|------|------|-------------|
| `Root` | State container | Manages open/closed state |
| `Trigger` | `NSButton` subclass | Toggles popover |
| `Anchor` | `NSView` subclass | Optional alternative anchor point |
| `Content` | `NSView` subclass | The floating panel |
| `Arrow` | `NSView` subclass | Visual arrow connecting trigger and content |
| `Close` | `NSButton` subclass | Closes the popover |

**State**: `OpenStateManaging`, `PositioningConfiguration`

**Behaviors**:
- Positions relative to trigger/anchor with collision avoidance
- Dismisses on click outside or Escape
- Supports configurable preferred edge and alignment
- Arrow rotates to match actual positioned edge

**Accessibility**: Role `.popover`, linked to trigger via accessibility relationships.

---

### 7.4 HoverCard

**Purpose**: Preview card on hover — for links, user profiles, etc.

**Parts**: `Root`, `Trigger`, `Content`, `Arrow`

**Behaviors**:
- Opens on mouse enter (with configurable delay)
- Closes on mouse leave (with configurable delay)
- Content stays open while mouse is over it
- Does NOT trap focus — purely supplementary content

---

### 7.5 Tooltip

**Purpose**: Brief text label on hover/focus.

**Parts**: `Provider` (app-level config), `Root`, `Trigger`, `Content`, `Arrow`

**Behaviors**:
- Opens on hover and keyboard focus
- Global delay shared via Provider (avoid tooltip storms)
- Only one tooltip visible at a time (instant switch between triggers)
- Dismisses immediately on click or scroll

**Accessibility**: `Trigger` gets `accessibilityHelp` set to tooltip content.

---

### 7.6 Toast

**Purpose**: Temporary notification with optional action.

**Parts**: `Provider` (manages toast stack), `Root` (single toast), `Title`, `Description`, `Action`, `Close`, `Viewport` (rendering area)

**Behaviors**:
- Auto-dismiss after configurable duration
- Pause timer on hover
- Swipe to dismiss
- Stack management (configurable max visible)
- Viewport positioned at configurable screen edge

**Accessibility**: Role `.alert` for important toasts, VoiceOver announces immediately.

---

### 7.7 DropdownMenu

**Purpose**: Action menu from a button trigger.

**Parts**: `Root`, `Trigger`, `Content`, `Item`, `Group`, `Label`, `CheckboxItem`, `RadioGroup`, `RadioItem`, `ItemIndicator`, `Separator`, `Sub`, `SubTrigger`, `SubContent`

**Behaviors**:
- Arrow key navigation between items
- Type-ahead search (type characters to jump to matching item)
- Submenu opens on hover/right arrow, closes on left arrow
- CheckboxItem/RadioItem manage checked state
- Escape closes current menu level

**Accessibility**: Menu role with menuitem/menuitemcheckbox/menuitemradio roles on items.

---

### 7.8 ContextMenu

**Purpose**: Right-click menu.

**Parts**: Same structure as DropdownMenu, but Trigger responds to right-click/Control-click.

**Behaviors**: Same as DropdownMenu. Trigger area defined by the Root's view bounds.

---

### 7.9 Menubar

**Purpose**: Horizontal menu bar (application menu style).

**Parts**: `Root` (horizontal bar), `Menu` (top-level item), `Trigger`, `Content`, plus all DropdownMenu sub-parts.

**Behaviors**:
- Left/Right arrow moves between top-level menus
- Opening one menu and arrowing left/right auto-opens adjacent menus
- Full keyboard navigation within open menus

---

### 7.10 NavigationMenu

**Purpose**: App/site navigation with dropdown content panels.

**Parts**: `Root`, `List`, `Item`, `Trigger`, `Content`, `Link`, `Indicator`, `Viewport`

**Behaviors**:
- Trigger opens content panel on click (or hover, configurable)
- Indicator tracks the active trigger position
- Viewport can be external (positioned separately for animation)
- Smooth transitions between content panels

---

### 7.11 Tabs

**Purpose**: Tabbed content panels.

**Parts**: `Root`, `List` (tab bar), `Trigger` (individual tab), `Content` (panel)

**State**: `ValueStateManaging<String>`

**Behaviors**:
- Arrow key navigation between triggers
- Active trigger linked to visible content panel
- Orientation: horizontal or vertical
- Activation mode: automatic (on focus) or manual (on click/Enter)

**Accessibility**: `tablist`, `tab`, `tabpanel` roles. `aria-selected` equivalent.

---

### 7.12 Checkbox

**Parts**: `Root` (the control), `Indicator` (check mark container)

**State**: `CheckedStateManaging` — supports `.checked`, `.unchecked`, `.indeterminate`

**Behaviors**:
- Click or Space toggles
- Renders hidden form-compatible state
- Indicator visible only when checked/indeterminate

---

### 7.13 RadioGroup

**Parts**: `Root` (group), `Item` (individual radio), `Indicator`

**State**: `ValueStateManaging<String>`

**Behaviors**:
- Arrow keys move selection within group (roving focus)
- Only one item selected at a time
- Tab moves focus in/out of group, arrows move within

---

### 7.14 Switch

**Parts**: `Root` (track), `Thumb` (sliding indicator)

**State**: `CheckedStateManaging` (only `.checked`/`.unchecked`)

**Behaviors**:
- Click or Space toggles
- Thumb animates between positions

---

### 7.15 Slider

**Parts**: `Root`, `Track`, `Range` (filled portion), `Thumb` (draggable handle)

**State**: Value management with `min`, `max`, `step`

**Behaviors**:
- Drag thumb to change value
- Click track to jump to position
- Arrow keys increment/decrement by step
- Multiple thumbs for range selection
- Orientation: horizontal or vertical

---

### 7.16 Toggle

**Parts**: `Root` (single button)

**State**: `CheckedStateManaging` (pressed/unpressed)

**Behaviors**: Click or Space toggles. Visual state change on press.

---

### 7.17 ToggleGroup

**Parts**: `Root`, `Item`

**Behaviors**:
- `type: .single` — one item active at a time
- `type: .multiple` — any combination of items active
- Roving focus between items

---

### 7.18 Select

**Parts**: `Root`, `Trigger`, `Value` (display), `Icon`, `Content`, `Viewport`, `Item`, `ItemText`, `ItemIndicator`, `ScrollUpButton`, `ScrollDownButton`, `Group`, `Label`, `Separator`

**State**: `ValueStateManaging<String>`

**Behaviors**:
- Opens floating list anchored to trigger
- Type-ahead search
- Arrow key navigation
- Selected item indicated visually
- Scroll buttons for long lists
- Value display updates to match selection

---

### 7.19 Label

**Parts**: `Root`

**Behaviors**:
- Associates with a form control via explicit binding or containment
- Click on label focuses the associated control
- Exposed via accessibility as the control's label

---

### 7.20 Accordion

**Parts**: `Root`, `Item`, `Header`, `Trigger`, `Content`

**State**:
- `type: .single` — one item open, `ValueStateManaging<String>`
- `type: .multiple` — many items open, `ValueStateManaging<Set<String>>`

**Behaviors**:
- Trigger toggles its item's Content visibility
- Content animates open/closed (height transition)
- Collapsible: in single mode, can optionally allow all items closed
- Arrow key navigation between triggers

**Accessibility**: Each trigger/content pair linked via `aria-controls`/`aria-expanded` equivalents.

---

### 7.21 Collapsible

**Parts**: `Root`, `Trigger`, `Content`

**State**: `OpenStateManaging`

**Behaviors**:
- Trigger toggles Content visibility
- Content height animates

---

### 7.22 AspectRatio

**Parts**: `Root`

**Behaviors**: Constrains child content to specified width:height ratio via Auto Layout constraints.

---

### 7.23 Avatar

**Parts**: `Root`, `Image`, `Fallback`

**Behaviors**:
- Image loads asynchronously
- Fallback displays during loading and on error
- Optional delay before showing fallback (avoids flash)

---

### 7.24 Progress

**Parts**: `Root`, `Indicator`

**Behaviors**:
- Determinate (value from 0 to max) or indeterminate
- Indicator width proportional to value/max

**Accessibility**: Role `.progressIndicator`, value announced.

---

### 7.25 Separator

**Parts**: `Root`

**Behaviors**:
- Orientation: horizontal or vertical
- Decorative mode (no accessibility semantics) vs semantic mode

---

### 7.26 ScrollArea

**Parts**: `Root`, `Viewport`, `Scrollbar`, `Thumb`, `Corner`

**Behaviors**:
- Custom-styled scrollbars overlaying content
- Scrollbar visibility: auto, always, scroll, hover
- Thumb size proportional to viewport/content ratio
- Native scroll physics preserved

---

### 7.27 Toolbar

**Parts**: `Root`, `Button`, `Link`, `ToggleGroup`, `ToggleItem`, `Separator`

**Behaviors**:
- Roving focus between toolbar items
- Orientation: horizontal or vertical

**Accessibility**: Role `.toolbar`.

---

### 7.28-7.30 Utilities

**AccessibleIcon**: Wraps `NSImageView`, adds `accessibilityLabel`, hides the icon from VoiceOver (only the label is announced).

**VisuallyHidden**: Positions content off-screen (not `isHidden = true`, which hides from VoiceOver too). Content remains in the accessibility tree.

---

## 8. Project Structure

### 8.1 Repository Layout

```
appkit-radix/
├── Package.swift                           # Root package manifest
├── README.md
├── LICENSE
├── proposal.md                             # This document
│
├── Sources/
│   ├── AppKitRadixCore/                    # Foundation layer
│   │   ├── PrimitiveView.swift
│   │   ├── ComponentContext.swift
│   │   ├── StateManagement/
│   │   │   ├── OpenStateManaging.swift
│   │   │   ├── ValueStateManaging.swift
│   │   │   └── CheckedStateManaging.swift
│   │   ├── Accessibility/
│   │   │   ├── AccessibilityHelpers.swift
│   │   │   └── VoiceOverAnnouncer.swift
│   │   └── Utilities/
│   │       ├── WeakRef.swift
│   │       └── CombineExtensions.swift
│   │
│   ├── AppKitRadixBehaviors/               # Behavior utilities layer
│   │   ├── FocusScope.swift
│   │   ├── DismissableRegion.swift
│   │   ├── Presence.swift
│   │   ├── RovingFocusGroup.swift
│   │   ├── Collection.swift
│   │   └── PopoverPositioning.swift
│   │
│   ├── AppKitRadixDialog/                  # Individual component targets
│   │   ├── DialogPrimitive.swift
│   │   └── DialogParts/
│   │       ├── DialogRoot.swift
│   │       ├── DialogTrigger.swift
│   │       ├── DialogOverlay.swift
│   │       ├── DialogContent.swift
│   │       ├── DialogClose.swift
│   │       ├── DialogTitle.swift
│   │       └── DialogDescription.swift
│   │
│   ├── AppKitRadixAlertDialog/
│   ├── AppKitRadixPopover/
│   ├── AppKitRadixHoverCard/
│   ├── AppKitRadixTooltip/
│   ├── AppKitRadixToast/
│   ├── AppKitRadixDropdownMenu/
│   ├── AppKitRadixContextMenu/
│   ├── AppKitRadixMenubar/
│   ├── AppKitRadixNavigationMenu/
│   ├── AppKitRadixTabs/
│   ├── AppKitRadixCheckbox/
│   ├── AppKitRadixRadioGroup/
│   ├── AppKitRadixSwitch/
│   ├── AppKitRadixSlider/
│   ├── AppKitRadixToggle/
│   ├── AppKitRadixToggleGroup/
│   ├── AppKitRadixSelect/
│   ├── AppKitRadixLabel/
│   ├── AppKitRadixAccordion/
│   ├── AppKitRadixCollapsible/
│   ├── AppKitRadixAspectRatio/
│   ├── AppKitRadixAvatar/
│   ├── AppKitRadixProgress/
│   ├── AppKitRadixSeparator/
│   ├── AppKitRadixScrollArea/
│   ├── AppKitRadixToolbar/
│   ├── AppKitRadixAccessibleIcon/
│   └── AppKitRadixVisuallyHidden/
│
├── Tests/
│   ├── AppKitRadixCoreTests/
│   ├── AppKitRadixBehaviorsTests/
│   ├── AppKitRadixDialogTests/
│   ├── AppKitRadixTabsTests/
│   └── ...                                 # One test target per component
│
└── Examples/
    └── DemoApp/                            # macOS demo application
        ├── DemoApp.xcodeproj
        └── DemoApp/
            ├── AppDelegate.swift
            ├── MainWindowController.swift
            ├── SidebarViewController.swift  # Component list navigation
            ├── Scenes/
            │   ├── ButtonDemoVC.swift
            │   ├── DialogDemoVC.swift
            │   ├── PopoverDemoVC.swift
            │   ├── TabsDemoVC.swift
            │   ├── AccordionDemoVC.swift
            │   ├── MenuDemoVC.swift
            │   ├── SelectDemoVC.swift
            │   ├── CheckboxDemoVC.swift
            │   ├── SliderDemoVC.swift
            │   ├── ToastDemoVC.swift
            │   └── ...                      # One per component
            ├── Assets.xcassets
            └── Info.plist
```

### 8.2 Package.swift

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AppKitRadix",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        // Umbrella — imports everything
        .library(name: "AppKitRadix", targets: [
            "AppKitRadixCore",
            "AppKitRadixBehaviors",
            "AppKitRadixDialog",
            "AppKitRadixAlertDialog",
            "AppKitRadixPopover",
            "AppKitRadixHoverCard",
            "AppKitRadixTooltip",
            "AppKitRadixToast",
            "AppKitRadixDropdownMenu",
            "AppKitRadixContextMenu",
            "AppKitRadixMenubar",
            "AppKitRadixNavigationMenu",
            "AppKitRadixTabs",
            "AppKitRadixCheckbox",
            "AppKitRadixRadioGroup",
            "AppKitRadixSwitch",
            "AppKitRadixSlider",
            "AppKitRadixToggle",
            "AppKitRadixToggleGroup",
            "AppKitRadixSelect",
            "AppKitRadixLabel",
            "AppKitRadixAccordion",
            "AppKitRadixCollapsible",
            "AppKitRadixAspectRatio",
            "AppKitRadixAvatar",
            "AppKitRadixProgress",
            "AppKitRadixSeparator",
            "AppKitRadixScrollArea",
            "AppKitRadixToolbar",
            "AppKitRadixAccessibleIcon",
            "AppKitRadixVisuallyHidden",
        ]),

        // Individual libraries for selective import
        .library(name: "AppKitRadixCore", targets: ["AppKitRadixCore"]),
        .library(name: "AppKitRadixBehaviors", targets: ["AppKitRadixBehaviors"]),
        .library(name: "AppKitRadixDialog", targets: ["AppKitRadixDialog"]),
        .library(name: "AppKitRadixAlertDialog", targets: ["AppKitRadixAlertDialog"]),
        .library(name: "AppKitRadixPopover", targets: ["AppKitRadixPopover"]),
        .library(name: "AppKitRadixHoverCard", targets: ["AppKitRadixHoverCard"]),
        .library(name: "AppKitRadixTooltip", targets: ["AppKitRadixTooltip"]),
        .library(name: "AppKitRadixToast", targets: ["AppKitRadixToast"]),
        .library(name: "AppKitRadixDropdownMenu", targets: ["AppKitRadixDropdownMenu"]),
        .library(name: "AppKitRadixContextMenu", targets: ["AppKitRadixContextMenu"]),
        .library(name: "AppKitRadixMenubar", targets: ["AppKitRadixMenubar"]),
        .library(name: "AppKitRadixNavigationMenu", targets: ["AppKitRadixNavigationMenu"]),
        .library(name: "AppKitRadixTabs", targets: ["AppKitRadixTabs"]),
        .library(name: "AppKitRadixCheckbox", targets: ["AppKitRadixCheckbox"]),
        .library(name: "AppKitRadixRadioGroup", targets: ["AppKitRadixRadioGroup"]),
        .library(name: "AppKitRadixSwitch", targets: ["AppKitRadixSwitch"]),
        .library(name: "AppKitRadixSlider", targets: ["AppKitRadixSlider"]),
        .library(name: "AppKitRadixToggle", targets: ["AppKitRadixToggle"]),
        .library(name: "AppKitRadixToggleGroup", targets: ["AppKitRadixToggleGroup"]),
        .library(name: "AppKitRadixSelect", targets: ["AppKitRadixSelect"]),
        .library(name: "AppKitRadixLabel", targets: ["AppKitRadixLabel"]),
        .library(name: "AppKitRadixAccordion", targets: ["AppKitRadixAccordion"]),
        .library(name: "AppKitRadixCollapsible", targets: ["AppKitRadixCollapsible"]),
        .library(name: "AppKitRadixAspectRatio", targets: ["AppKitRadixAspectRatio"]),
        .library(name: "AppKitRadixAvatar", targets: ["AppKitRadixAvatar"]),
        .library(name: "AppKitRadixProgress", targets: ["AppKitRadixProgress"]),
        .library(name: "AppKitRadixSeparator", targets: ["AppKitRadixSeparator"]),
        .library(name: "AppKitRadixScrollArea", targets: ["AppKitRadixScrollArea"]),
        .library(name: "AppKitRadixToolbar", targets: ["AppKitRadixToolbar"]),
        .library(name: "AppKitRadixAccessibleIcon", targets: ["AppKitRadixAccessibleIcon"]),
        .library(name: "AppKitRadixVisuallyHidden", targets: ["AppKitRadixVisuallyHidden"]),
    ],
    targets: [
        // ── Foundation ──
        .target(name: "AppKitRadixCore"),
        .target(name: "AppKitRadixBehaviors", dependencies: ["AppKitRadixCore"]),

        // ── Overlay / Dialog ──
        .target(name: "AppKitRadixDialog", dependencies: ["AppKitRadixCore", "AppKitRadixBehaviors"]),
        .target(name: "AppKitRadixAlertDialog", dependencies: ["AppKitRadixCore", "AppKitRadixBehaviors"]),
        .target(name: "AppKitRadixPopover", dependencies: ["AppKitRadixCore", "AppKitRadixBehaviors"]),
        .target(name: "AppKitRadixHoverCard", dependencies: ["AppKitRadixCore", "AppKitRadixBehaviors"]),
        .target(name: "AppKitRadixTooltip", dependencies: ["AppKitRadixCore", "AppKitRadixBehaviors"]),
        .target(name: "AppKitRadixToast", dependencies: ["AppKitRadixCore", "AppKitRadixBehaviors"]),

        // ── Menus ──
        .target(name: "AppKitRadixDropdownMenu", dependencies: ["AppKitRadixCore", "AppKitRadixBehaviors"]),
        .target(name: "AppKitRadixContextMenu", dependencies: ["AppKitRadixCore", "AppKitRadixBehaviors"]),
        .target(name: "AppKitRadixMenubar", dependencies: ["AppKitRadixCore", "AppKitRadixBehaviors"]),

        // ── Navigation ──
        .target(name: "AppKitRadixNavigationMenu", dependencies: ["AppKitRadixCore", "AppKitRadixBehaviors"]),
        .target(name: "AppKitRadixTabs", dependencies: ["AppKitRadixCore", "AppKitRadixBehaviors"]),

        // ── Form Controls ──
        .target(name: "AppKitRadixCheckbox", dependencies: ["AppKitRadixCore"]),
        .target(name: "AppKitRadixRadioGroup", dependencies: ["AppKitRadixCore", "AppKitRadixBehaviors"]),
        .target(name: "AppKitRadixSwitch", dependencies: ["AppKitRadixCore"]),
        .target(name: "AppKitRadixSlider", dependencies: ["AppKitRadixCore"]),
        .target(name: "AppKitRadixToggle", dependencies: ["AppKitRadixCore"]),
        .target(name: "AppKitRadixToggleGroup", dependencies: ["AppKitRadixCore", "AppKitRadixBehaviors"]),
        .target(name: "AppKitRadixSelect", dependencies: ["AppKitRadixCore", "AppKitRadixBehaviors"]),
        .target(name: "AppKitRadixLabel", dependencies: ["AppKitRadixCore"]),

        // ── Disclosure ──
        .target(name: "AppKitRadixAccordion", dependencies: ["AppKitRadixCore", "AppKitRadixBehaviors"]),
        .target(name: "AppKitRadixCollapsible", dependencies: ["AppKitRadixCore", "AppKitRadixBehaviors"]),

        // ── Layout / Display ──
        .target(name: "AppKitRadixAspectRatio", dependencies: ["AppKitRadixCore"]),
        .target(name: "AppKitRadixAvatar", dependencies: ["AppKitRadixCore"]),
        .target(name: "AppKitRadixProgress", dependencies: ["AppKitRadixCore"]),
        .target(name: "AppKitRadixSeparator", dependencies: ["AppKitRadixCore"]),
        .target(name: "AppKitRadixScrollArea", dependencies: ["AppKitRadixCore"]),
        .target(name: "AppKitRadixToolbar", dependencies: ["AppKitRadixCore", "AppKitRadixBehaviors"]),

        // ── Utilities ──
        .target(name: "AppKitRadixAccessibleIcon", dependencies: ["AppKitRadixCore"]),
        .target(name: "AppKitRadixVisuallyHidden", dependencies: ["AppKitRadixCore"]),

        // ── Tests ──
        .testTarget(name: "AppKitRadixCoreTests", dependencies: ["AppKitRadixCore"]),
        .testTarget(name: "AppKitRadixBehaviorsTests", dependencies: ["AppKitRadixBehaviors"]),
        .testTarget(name: "AppKitRadixDialogTests", dependencies: ["AppKitRadixDialog"]),
        .testTarget(name: "AppKitRadixTabsTests", dependencies: ["AppKitRadixTabs"]),
        .testTarget(name: "AppKitRadixAccordionTests", dependencies: ["AppKitRadixAccordion"]),
        .testTarget(name: "AppKitRadixCheckboxTests", dependencies: ["AppKitRadixCheckbox"]),
        .testTarget(name: "AppKitRadixSelectTests", dependencies: ["AppKitRadixSelect"]),
    ]
)
```

---

## 9. Demo Application

The demo app is a macOS application that showcases every primitive. It serves as both a development testbed and a living reference for consumers.

### 9.1 Structure

- **Sidebar**: Lists all components by category (matching Section 4 categories)
- **Main area**: Shows the selected component's demo with:
  - Live interactive examples
  - State inspector showing current component state
  - Code snippets showing usage
  - Variations (controlled vs uncontrolled, different configs)

### 9.2 Layout

```
┌──────────────────────────────────────────────────────────┐
│  AppKitRadix Demo                                        │
├────────────┬─────────────────────────────────────────────┤
│            │                                             │
│  Overlays  │   Dialog                                    │
│   Dialog ◄─│                                             │
│   Alert    │   ┌─ Basic Dialog ──────────────────────┐   │
│   Popover  │   │                                     │   │
│   Tooltip  │   │  [Open Dialog]                      │   │
│   ...      │   │                                     │   │
│            │   │  State: closed                       │   │
│  Menus     │   └─────────────────────────────────────┘   │
│   Dropdown │                                             │
│   Context  │   ┌─ Controlled Dialog ─────────────────┐   │
│   Menubar  │   │                                     │   │
│            │   │  isOpen: ☐  [Open] [Close]          │   │
│  Forms     │   │                                     │   │
│   Checkbox │   └─────────────────────────────────────┘   │
│   Radio    │                                             │
│   Switch   │   ┌─ Custom Styled ─────────────────────┐   │
│   ...      │   │                                     │   │
│            │   │  (Custom appearance demo)            │   │
│            │   │                                     │   │
│            │   └─────────────────────────────────────┘   │
└────────────┴─────────────────────────────────────────────┘
```

### 9.3 Demo App Setup

The demo app is an Xcode project that references the library as a local Swift package:

1. `Examples/DemoApp/DemoApp.xcodeproj` — standard macOS app target
2. The root `Package.swift` is added as a local package dependency
3. Demo app target links against `AppKitRadix` (umbrella library)
4. Each demo scene (`*DemoVC.swift`) demonstrates one component

Developers working on the library get live preview: edit a source file in `Sources/`, build the demo app, and see the changes immediately.

---

## 10. Implementation Phases

### Phase 1: Foundation (Weeks 1-2)

**Goal**: Core infrastructure that all components build on.

**Deliverables**:
- `AppKitRadixCore` target — `PrimitiveView`, `ComponentContext`, state management protocols
- `AppKitRadixBehaviors` target — `FocusScope`, `DismissableRegion`, `Presence`, `RovingFocusGroup`, `Collection`
- Unit tests for all foundation code
- Demo app skeleton (sidebar + empty scenes)

**Why first**: Every component depends on this layer. Getting it right up front avoids retrofitting.

### Phase 2: Simple Primitives (Weeks 3-4)

**Goal**: Build the simplest components to validate the architecture.

**Components**:
- Separator
- Label
- AspectRatio
- VisuallyHidden
- AccessibleIcon
- Progress
- Avatar
- Toggle
- Checkbox
- Switch

**Why these**: Low complexity, few parts, validate the `PrimitiveView` pattern and state protocols work in practice.

### Phase 3: Disclosure & Collapsible (Weeks 5-6)

**Goal**: First compound components with animation.

**Components**:
- Collapsible
- Accordion
- ToggleGroup

**Why here**: These introduce the Root/Trigger/Content pattern, animated presence, and multi-item state management — patterns used by nearly everything in later phases.

### Phase 4: Overlays (Weeks 7-9)

**Goal**: Floating content — the most complex interaction patterns.

**Components**:
- Tooltip
- Popover
- HoverCard
- Dialog
- AlertDialog
- Toast

**Why here**: These require `FocusScope`, `DismissableRegion`, `Presence`, positioning logic, and overlay management. The hardest components technically.

### Phase 5: Selection & Inputs (Weeks 10-11)

**Goal**: Form-oriented components.

**Components**:
- RadioGroup
- Slider
- Select
- Tabs

**Why here**: These build on `Collection`, `RovingFocusGroup`, and `ValueStateManaging` — all proven in earlier phases.

### Phase 6: Menus (Weeks 12-14)

**Goal**: Full menu system.

**Components**:
- DropdownMenu
- ContextMenu
- Menubar
- NavigationMenu
- Toolbar
- ScrollArea

**Why last**: Menus are the most complex components (submenus, type-ahead, checkbox/radio items, positioning). They require everything from prior phases to be solid.

### Phase 7: Polish & Release (Weeks 15-16)

**Goal**: Production readiness.

**Deliverables**:
- Complete demo app with all components
- Documentation for every component (doc comments + README sections)
- Performance profiling and optimization
- Accessibility audit (VoiceOver testing on every component)
- CI/CD setup (GitHub Actions for build + test)
- Version 0.1.0 tagged release

---

## 11. Packaging & Distribution

### 11.1 Swift Package Manager (Primary)

Users add AppKitRadix via SPM:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/celeroncoder/appkit-radix.git", from: "0.1.0")
]

// Target dependencies — pick what you need
.target(name: "MyApp", dependencies: [
    .product(name: "AppKitRadix", package: "appkit-radix"),        // Everything
    // OR
    .product(name: "AppKitRadixDialog", package: "appkit-radix"),  // Just Dialog
    .product(name: "AppKitRadixTabs", package: "appkit-radix"),    // Just Tabs
])
```

Or via Xcode: File → Add Package Dependencies → paste the GitHub URL.

### 11.2 Versioning

- Semantic versioning: `MAJOR.MINOR.PATCH`
- Pre-1.0: API is unstable, minor versions may break
- Post-1.0: Standard semver guarantees
- Each component's API stability tracked independently in CHANGELOG

### 11.3 Platform Requirements

- **Minimum**: macOS 13.0 (Ventura)
- **Swift**: 5.9+
- **Xcode**: 15.0+

macOS 13 chosen as floor because:
- Supports `NSSwitch` and modern `NSComboButton`
- Covers the vast majority of active macOS users
- Allows use of newer AppKit APIs without excessive availability checks

### 11.4 Dependencies

**Zero external dependencies.** AppKitRadix depends only on:
- `AppKit` (system framework)
- `Combine` (system framework)
- `Foundation` (system framework)

This is a deliberate choice: no third-party positioning libraries, no animation frameworks, no dependency chain to manage. Everything is built on Apple's frameworks.

---

## Appendix: Radix UI Mapping

Complete mapping of Radix UI primitives to AppKitRadix equivalents.

| Radix UI Primitive | AppKitRadix Target | Status | Notes |
|-|-|-|-|
| `@radix-ui/react-accordion` | `AppKitRadixAccordion` | Planned | Phase 3 |
| `@radix-ui/react-alert-dialog` | `AppKitRadixAlertDialog` | Planned | Phase 4 |
| `@radix-ui/react-aspect-ratio` | `AppKitRadixAspectRatio` | Planned | Phase 2 |
| `@radix-ui/react-avatar` | `AppKitRadixAvatar` | Planned | Phase 2 |
| `@radix-ui/react-checkbox` | `AppKitRadixCheckbox` | Planned | Phase 2 |
| `@radix-ui/react-collapsible` | `AppKitRadixCollapsible` | Planned | Phase 3 |
| `@radix-ui/react-context-menu` | `AppKitRadixContextMenu` | Planned | Phase 6 |
| `@radix-ui/react-dialog` | `AppKitRadixDialog` | Planned | Phase 4 |
| `@radix-ui/react-dropdown-menu` | `AppKitRadixDropdownMenu` | Planned | Phase 6 |
| `@radix-ui/react-hover-card` | `AppKitRadixHoverCard` | Planned | Phase 4 |
| `@radix-ui/react-label` | `AppKitRadixLabel` | Planned | Phase 2 |
| `@radix-ui/react-menubar` | `AppKitRadixMenubar` | Planned | Phase 6 |
| `@radix-ui/react-navigation-menu` | `AppKitRadixNavigationMenu` | Planned | Phase 6 |
| `@radix-ui/react-popover` | `AppKitRadixPopover` | Planned | Phase 4 |
| `@radix-ui/react-progress` | `AppKitRadixProgress` | Planned | Phase 2 |
| `@radix-ui/react-radio-group` | `AppKitRadixRadioGroup` | Planned | Phase 5 |
| `@radix-ui/react-scroll-area` | `AppKitRadixScrollArea` | Planned | Phase 6 |
| `@radix-ui/react-select` | `AppKitRadixSelect` | Planned | Phase 5 |
| `@radix-ui/react-separator` | `AppKitRadixSeparator` | Planned | Phase 2 |
| `@radix-ui/react-slider` | `AppKitRadixSlider` | Planned | Phase 5 |
| `@radix-ui/react-switch` | `AppKitRadixSwitch` | Planned | Phase 2 |
| `@radix-ui/react-tabs` | `AppKitRadixTabs` | Planned | Phase 5 |
| `@radix-ui/react-toast` | `AppKitRadixToast` | Planned | Phase 4 |
| `@radix-ui/react-toggle` | `AppKitRadixToggle` | Planned | Phase 2 |
| `@radix-ui/react-toggle-group` | `AppKitRadixToggleGroup` | Planned | Phase 3 |
| `@radix-ui/react-toolbar` | `AppKitRadixToolbar` | Planned | Phase 6 |
| `@radix-ui/react-tooltip` | `AppKitRadixTooltip` | Planned | Phase 4 |
| `@radix-ui/react-accessible-icon` | `AppKitRadixAccessibleIcon` | Planned | Phase 2 |
| `@radix-ui/react-visually-hidden` | `AppKitRadixVisuallyHidden` | Planned | Phase 2 |
| `@radix-ui/react-form` | — | Deferred | Preview in Radix; revisit post-1.0 |
| `@radix-ui/react-one-time-password-field` | — | Deferred | New in Radix; revisit post-1.0 |
| `@radix-ui/react-password-toggle-field` | — | Deferred | New in Radix; revisit post-1.0 |
| `@radix-ui/react-direction` | — | Not needed | macOS handles layout direction natively |
| `@radix-ui/react-portal` | — | Internal only | Part of Behaviors layer, not user-facing |
| `@radix-ui/react-slot` | — | Not applicable | `asChild` is a React pattern; AppKit uses subclassing/composition |

**29 components planned** for initial release. 3 deferred (Form, OTP, PasswordToggle — all preview/new in Radix). 3 not applicable (Direction, Portal, Slot — handled differently in AppKit).

---

*This proposal is a living document. It will be updated as implementation progresses and architectural decisions are refined.*
