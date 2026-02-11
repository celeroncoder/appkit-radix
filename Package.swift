// swift-tools-version: 5.9
import PackageDescription

// All component target names for the umbrella product
let componentTargets: [String] = [
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
]

let package = Package(
    name: "AppKitRadix",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        // Umbrella — imports everything
        .library(
            name: "AppKitRadix",
            targets: ["AppKitRadix"]
        ),

        // Foundation
        .library(name: "AppKitRadixCore", targets: ["AppKitRadixCore"]),
        .library(name: "AppKitRadixBehaviors", targets: ["AppKitRadixBehaviors"]),

        // Individual component libraries
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
        // ── Umbrella ──
        .target(
            name: "AppKitRadix",
            dependencies: ["AppKitRadixCore", "AppKitRadixBehaviors"] + componentTargets.map { Target.Dependency(stringLiteral: $0) }
        ),

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

        // ── Demo App (not distributed as a product) ──
        .executableTarget(
            name: "DemoApp",
            dependencies: ["AppKitRadix"],
            path: "Examples/DemoApp"
        ),

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
