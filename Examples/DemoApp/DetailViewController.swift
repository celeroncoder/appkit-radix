import AppKit
import AppKitRadix

private final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}

final class DetailViewController: NSViewController {
    private let scrollView = NSScrollView()
    private let contentView = FlippedView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let statusLabel = NSTextField(labelWithString: "")
    private var currentComponent: ComponentItem?
    private var demoView: NSView?

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.documentView = contentView
        contentView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = .systemFont(ofSize: 13)
        statusLabel.textColor = .secondaryLabelColor

        contentView.addSubview(titleLabel)
        contentView.addSubview(statusLabel)

        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            contentView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
            contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.contentView.heightAnchor),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            statusLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
        ])

        showWelcome()
    }

    func showDemo(for component: ComponentItem) {
        currentComponent = component
        titleLabel.stringValue = component.name
        statusLabel.stringValue = "Category: \(component.category.rawValue)"

        demoView?.removeFromSuperview()
        let demo = buildDemo(for: component.name)
        demo.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(demo)
        demoView = demo

        NSLayoutConstraint.activate([
            demo.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 24),
            demo.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            demo.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 24),
            demo.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -24),
            demo.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -24),
        ])
    }

    private func showWelcome() {
        titleLabel.stringValue = "AppKitRadix Demo"
        statusLabel.stringValue = "Select a component from the sidebar to see its demo."
    }

    // MARK: - Demo builders

    private func buildDemo(for name: String) -> NSView {
        switch name {
        case "Dialog": return buildDialogDemo()
        case "AlertDialog": return buildAlertDialogDemo()
        case "Popover": return buildPopoverDemo()
        case "HoverCard": return buildHoverCardDemo()
        case "Tooltip": return buildTooltipDemo()
        case "Toast": return buildToastDemo()
        case "DropdownMenu": return buildDropdownMenuDemo()
        case "ContextMenu": return buildContextMenuDemo()
        case "Menubar": return buildMenubarDemo()
        case "NavigationMenu": return buildNavigationMenuDemo()
        case "Tabs": return buildTabsDemo()
        case "Checkbox": return buildCheckboxDemo()
        case "RadioGroup": return buildRadioGroupDemo()
        case "Switch": return buildSwitchDemo()
        case "Slider": return buildSliderDemo()
        case "Toggle": return buildToggleDemo()
        case "ToggleGroup": return buildToggleGroupDemo()
        case "Select": return buildSelectDemo()
        case "Label": return buildLabelDemo()
        case "Accordion": return buildAccordionDemo()
        case "Collapsible": return buildCollapsibleDemo()
        case "AspectRatio": return buildAspectRatioDemo()
        case "Avatar": return buildAvatarDemo()
        case "Progress": return buildProgressDemo()
        case "Separator": return buildSeparatorDemo()
        case "ScrollArea": return buildScrollAreaDemo()
        case "Toolbar": return buildToolbarDemo()
        case "AccessibleIcon": return buildAccessibleIconDemo()
        case "VisuallyHidden": return buildVisuallyHiddenDemo()
        default: return makeLabel("No demo available")
        }
    }

    // MARK: - Overlay Demos

    private func buildDialogDemo() -> NSView {
        let root = DialogPrimitive.Root()
        let trigger = DialogPrimitive.Trigger()
        trigger.title = "Open Dialog"
        let overlay = DialogPrimitive.Overlay()
        let content = DialogPrimitive.Content()
        let title = DialogPrimitive.Title()
        title.text = "Dialog Title"
        let desc = DialogPrimitive.Description()
        desc.text = "This is a dialog description."
        let close = DialogPrimitive.Close()
        close.title = "Close"

        let stack = NSStackView(views: [title, desc, close])
        stack.orientation = .vertical; stack.spacing = 12; stack.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(stack)
        NSLayoutConstraint.activate([stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 20), stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20), stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20), stack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20)])

        root.addSubview(trigger); root.addSubview(overlay); root.addSubview(content)
        trigger.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([trigger.topAnchor.constraint(equalTo: root.topAnchor), trigger.leadingAnchor.constraint(equalTo: root.leadingAnchor)])
        return root
    }

    private func buildAlertDialogDemo() -> NSView {
        let root = AlertDialogPrimitive.Root()
        let trigger = AlertDialogPrimitive.Trigger()
        trigger.title = "Delete Item"
        let overlay = AlertDialogPrimitive.Overlay()
        let content = AlertDialogPrimitive.Content()
        let title = AlertDialogPrimitive.Title()
        title.text = "Are you sure?"
        let desc = AlertDialogPrimitive.Description()
        desc.text = "This action cannot be undone."
        let cancel = AlertDialogPrimitive.Cancel()
        cancel.title = "Cancel"
        let action = AlertDialogPrimitive.Action()
        action.title = "Delete"

        let btnStack = NSStackView(views: [cancel, action])
        btnStack.orientation = .horizontal; btnStack.spacing = 8
        let stack = NSStackView(views: [title, desc, btnStack])
        stack.orientation = .vertical; stack.spacing = 12; stack.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(stack)
        NSLayoutConstraint.activate([stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 20), stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20), stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20), stack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20)])

        root.addSubview(trigger); root.addSubview(overlay); root.addSubview(content)
        trigger.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([trigger.topAnchor.constraint(equalTo: root.topAnchor), trigger.leadingAnchor.constraint(equalTo: root.leadingAnchor)])
        return root
    }

    private func buildPopoverDemo() -> NSView {
        let root = PopoverPrimitive.Root()
        let trigger = PopoverPrimitive.Trigger()
        trigger.title = "Show Popover"
        let content = PopoverPrimitive.Content()
        let label = makeLabel("Popover content goes here")
        label.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(label)
        NSLayoutConstraint.activate([label.topAnchor.constraint(equalTo: content.topAnchor, constant: 12), label.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 12), label.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -12), label.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -12)])

        root.addSubview(trigger); root.addSubview(content)
        trigger.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([trigger.topAnchor.constraint(equalTo: root.topAnchor), trigger.leadingAnchor.constraint(equalTo: root.leadingAnchor)])
        return root
    }

    private func buildHoverCardDemo() -> NSView {
        let root = HoverCardPrimitive.Root()
        let trigger = HoverCardPrimitive.Trigger()
        let triggerLabel = makeLabel("Hover over me")
        triggerLabel.translatesAutoresizingMaskIntoConstraints = false; triggerLabel.textColor = .linkColor
        trigger.addSubview(triggerLabel)
        NSLayoutConstraint.activate([triggerLabel.topAnchor.constraint(equalTo: trigger.topAnchor), triggerLabel.leadingAnchor.constraint(equalTo: trigger.leadingAnchor), triggerLabel.trailingAnchor.constraint(equalTo: trigger.trailingAnchor), triggerLabel.bottomAnchor.constraint(equalTo: trigger.bottomAnchor)])

        let content = HoverCardPrimitive.Content()
        let infoLabel = makeLabel("This is a hover card with additional info")
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(infoLabel)
        NSLayoutConstraint.activate([infoLabel.topAnchor.constraint(equalTo: content.topAnchor, constant: 12), infoLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 12), infoLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -12), infoLabel.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -12)])

        root.addSubview(trigger); root.addSubview(content)
        trigger.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([trigger.topAnchor.constraint(equalTo: root.topAnchor), trigger.leadingAnchor.constraint(equalTo: root.leadingAnchor)])
        return root
    }

    private func buildTooltipDemo() -> NSView {
        let root = TooltipPrimitive.Root()
        let trigger = TooltipPrimitive.Trigger()
        let btn = NSButton(title: "Hover for tooltip", target: nil, action: nil)
        btn.translatesAutoresizingMaskIntoConstraints = false
        trigger.addSubview(btn)
        NSLayoutConstraint.activate([btn.topAnchor.constraint(equalTo: trigger.topAnchor), btn.leadingAnchor.constraint(equalTo: trigger.leadingAnchor), btn.trailingAnchor.constraint(equalTo: trigger.trailingAnchor), btn.bottomAnchor.constraint(equalTo: trigger.bottomAnchor)])

        let content = TooltipPrimitive.Content()
        content.text = "This is a tooltip"

        root.addSubview(trigger); root.addSubview(content)
        trigger.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([trigger.topAnchor.constraint(equalTo: root.topAnchor), trigger.leadingAnchor.constraint(equalTo: root.leadingAnchor)])
        return root
    }

    private func buildToastDemo() -> NSView {
        let stack = NSStackView()
        stack.orientation = .vertical; stack.spacing = 12

        let btn = NSButton(title: "Show Toast", target: nil, action: nil)
        btn.target = self; btn.action = #selector(showToast)
        stack.addArrangedSubview(btn)
        stack.addArrangedSubview(makeLabel("Click the button to trigger a toast notification"))
        return stack
    }

    @objc private func showToast() {
        let toast = ToastPrimitive.ToastData(title: "Success", description: "Operation completed", duration: 3)
        ToastPrimitive.Provider.shared.show(toast)
    }

    // MARK: - Menu Demos

    private func buildDropdownMenuDemo() -> NSView {
        let root = DropdownMenuPrimitive.Root()
        let trigger = DropdownMenuPrimitive.Trigger()
        trigger.title = "Open Menu"

        let content = DropdownMenuPrimitive.Content()
        let item1 = DropdownMenuPrimitive.Item(title: "Cut")
        let item2 = DropdownMenuPrimitive.Item(title: "Copy")
        let item3 = DropdownMenuPrimitive.Item(title: "Paste")
        let sep = DropdownMenuPrimitive.Separator()
        let item4 = DropdownMenuPrimitive.Item(title: "Select All")
        content.addItem(item1); content.addItem(item2); content.addItem(item3)
        content.addItem(sep); content.addItem(item4)

        root.addSubview(trigger); root.addSubview(content)
        trigger.translatesAutoresizingMaskIntoConstraints = false
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            trigger.topAnchor.constraint(equalTo: root.topAnchor),
            trigger.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            content.topAnchor.constraint(equalTo: trigger.bottomAnchor, constant: 4),
            content.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            content.widthAnchor.constraint(equalToConstant: 180),
        ])
        return root
    }

    private func buildContextMenuDemo() -> NSView {
        let root = ContextMenuPrimitive.Root()
        let trigger = ContextMenuPrimitive.Trigger()
        trigger.wantsLayer = true; trigger.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        trigger.layer?.cornerRadius = 8
        let label = makeLabel("Right-click this area")
        label.translatesAutoresizingMaskIntoConstraints = false
        trigger.addSubview(label)
        NSLayoutConstraint.activate([label.centerXAnchor.constraint(equalTo: trigger.centerXAnchor), label.centerYAnchor.constraint(equalTo: trigger.centerYAnchor)])
        trigger.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([trigger.widthAnchor.constraint(equalToConstant: 200), trigger.heightAnchor.constraint(equalToConstant: 100)])

        let content = ContextMenuPrimitive.Content()
        content.addItem(ContextMenuPrimitive.Item(title: "Action 1"))
        content.addItem(ContextMenuPrimitive.Item(title: "Action 2"))
        content.addItem(ContextMenuPrimitive.Separator())
        content.addItem(ContextMenuPrimitive.Item(title: "Action 3"))

        root.addSubview(trigger); root.addSubview(content)
        trigger.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([trigger.topAnchor.constraint(equalTo: root.topAnchor), trigger.leadingAnchor.constraint(equalTo: root.leadingAnchor)])
        return root
    }

    private func buildMenubarDemo() -> NSView {
        let root = MenubarPrimitive.Root()
        let fileMenu = MenubarPrimitive.Menu(menuId: "file")
        let fileTrigger = MenubarPrimitive.Trigger(title: "File")
        let fileContent = MenubarPrimitive.Content()
        fileContent.addItem(MenubarPrimitive.Item(title: "New"))
        fileContent.addItem(MenubarPrimitive.Item(title: "Open"))
        fileContent.addItem(MenubarPrimitive.Separator())
        fileContent.addItem(MenubarPrimitive.Item(title: "Save"))
        fileContent.bindToMenu(fileMenu)
        fileMenu.addContent(fileTrigger); fileMenu.addContent(fileContent)

        let editMenu = MenubarPrimitive.Menu(menuId: "edit")
        let editTrigger = MenubarPrimitive.Trigger(title: "Edit")
        let editContent = MenubarPrimitive.Content()
        editContent.addItem(MenubarPrimitive.Item(title: "Undo"))
        editContent.addItem(MenubarPrimitive.Item(title: "Redo"))
        editContent.bindToMenu(editMenu)
        editMenu.addContent(editTrigger); editMenu.addContent(editContent)

        root.addMenu(fileMenu); root.addMenu(editMenu)
        return root
    }

    // MARK: - Navigation Demos

    private func buildNavigationMenuDemo() -> NSView {
        let root = NavigationMenuPrimitive.Root()

        let list = NavigationMenuPrimitive.List()
        let item1 = NavigationMenuPrimitive.Item(value: "getting-started")
        let trigger1 = NavigationMenuPrimitive.Trigger(title: "Getting Started")
        item1.addContent(trigger1)

        let item2 = NavigationMenuPrimitive.Item(value: "components")
        let trigger2 = NavigationMenuPrimitive.Trigger(title: "Components")
        item2.addContent(trigger2)

        list.addItem(item1); list.addItem(item2)

        let content1 = NavigationMenuPrimitive.Content(value: "getting-started")
        let lbl1 = makeLabel("Introduction and setup guide")
        lbl1.translatesAutoresizingMaskIntoConstraints = false
        content1.addSubview(lbl1)
        NSLayoutConstraint.activate([lbl1.topAnchor.constraint(equalTo: content1.topAnchor, constant: 12), lbl1.leadingAnchor.constraint(equalTo: content1.leadingAnchor, constant: 12)])

        let content2 = NavigationMenuPrimitive.Content(value: "components")
        let lbl2 = makeLabel("Browse all 29 components")
        lbl2.translatesAutoresizingMaskIntoConstraints = false
        content2.addSubview(lbl2)
        NSLayoutConstraint.activate([lbl2.topAnchor.constraint(equalTo: content2.topAnchor, constant: 12), lbl2.leadingAnchor.constraint(equalTo: content2.leadingAnchor, constant: 12)])

        root.addContent(list); root.addContent(content1); root.addContent(content2)
        return root
    }

    private func buildTabsDemo() -> NSView {
        let root = TabsPrimitive.Root(defaultValue: "account")

        let list = TabsPrimitive.List()
        let tab1 = TabsPrimitive.Trigger(value: "account", title: "Account")
        let tab2 = TabsPrimitive.Trigger(value: "password", title: "Password")
        let tab3 = TabsPrimitive.Trigger(value: "settings", title: "Settings")
        list.addTrigger(tab1); list.addTrigger(tab2); list.addTrigger(tab3)

        let panel1 = TabsPrimitive.Content(value: "account")
        let l1 = makeLabel("Account settings content"); l1.translatesAutoresizingMaskIntoConstraints = false
        panel1.addSubview(l1); NSLayoutConstraint.activate([l1.topAnchor.constraint(equalTo: panel1.topAnchor, constant: 16), l1.leadingAnchor.constraint(equalTo: panel1.leadingAnchor, constant: 16)])

        let panel2 = TabsPrimitive.Content(value: "password")
        let l2 = makeLabel("Password change form"); l2.translatesAutoresizingMaskIntoConstraints = false
        panel2.addSubview(l2); NSLayoutConstraint.activate([l2.topAnchor.constraint(equalTo: panel2.topAnchor, constant: 16), l2.leadingAnchor.constraint(equalTo: panel2.leadingAnchor, constant: 16)])

        let panel3 = TabsPrimitive.Content(value: "settings")
        let l3 = makeLabel("General settings"); l3.translatesAutoresizingMaskIntoConstraints = false
        panel3.addSubview(l3); NSLayoutConstraint.activate([l3.topAnchor.constraint(equalTo: panel3.topAnchor, constant: 16), l3.leadingAnchor.constraint(equalTo: panel3.leadingAnchor, constant: 16)])

        root.addArrangedSubview(list)
        root.addArrangedSubview(panel1); root.addArrangedSubview(panel2); root.addArrangedSubview(panel3)
        return root
    }

    // MARK: - Form Control Demos

    private func buildCheckboxDemo() -> NSView {
        let stack = NSStackView(); stack.orientation = .vertical; stack.spacing = 12

        let checkbox1 = CheckboxPrimitive.Root()
        let lbl1 = makeLabel("Accept terms and conditions")
        let row1 = NSStackView(views: [checkbox1, lbl1]); row1.orientation = .horizontal; row1.spacing = 8

        let checkbox2 = CheckboxPrimitive.Root()
        let lbl2 = makeLabel("Subscribe to newsletter")
        let row2 = NSStackView(views: [checkbox2, lbl2]); row2.orientation = .horizontal; row2.spacing = 8

        stack.addArrangedSubview(row1); stack.addArrangedSubview(row2)
        return stack
    }

    private func buildRadioGroupDemo() -> NSView {
        let root = RadioGroupPrimitive.Root(defaultValue: "comfortable")

        let item1 = RadioGroupPrimitive.Item(value: "default")
        let lbl1 = makeLabel("Default")
        let row1 = NSStackView(views: [item1, lbl1]); row1.orientation = .horizontal; row1.spacing = 8

        let item2 = RadioGroupPrimitive.Item(value: "comfortable")
        let lbl2 = makeLabel("Comfortable")
        let row2 = NSStackView(views: [item2, lbl2]); row2.orientation = .horizontal; row2.spacing = 8

        let item3 = RadioGroupPrimitive.Item(value: "compact")
        let lbl3 = makeLabel("Compact")
        let row3 = NSStackView(views: [item3, lbl3]); row3.orientation = .horizontal; row3.spacing = 8

        root.addItem(row1); root.addItem(row2); root.addItem(row3)
        return root
    }

    private func buildSwitchDemo() -> NSView {
        let stack = NSStackView(); stack.orientation = .vertical; stack.spacing = 12

        let sw = SwitchPrimitive.Root()
        let lbl = makeLabel("Airplane Mode")
        let row = NSStackView(views: [sw, lbl]); row.orientation = .horizontal; row.spacing = 8
        stack.addArrangedSubview(row)

        let sw2 = SwitchPrimitive.Root()
        let lbl2 = makeLabel("Dark Mode")
        let row2 = NSStackView(views: [sw2, lbl2]); row2.orientation = .horizontal; row2.spacing = 8
        stack.addArrangedSubview(row2)

        return stack
    }

    private func buildSliderDemo() -> NSView {
        let stack = NSStackView(); stack.orientation = .vertical; stack.spacing = 16

        let slider = SliderPrimitive.Root()
        slider.values = [50]
        let track = SliderPrimitive.Track()
        let range = SliderPrimitive.Range()
        let thumb = SliderPrimitive.Thumb()
        track.addSubview(range); track.addSubview(thumb)
        slider.addSubview(track)
        track.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([track.topAnchor.constraint(equalTo: slider.topAnchor), track.leadingAnchor.constraint(equalTo: slider.leadingAnchor), track.trailingAnchor.constraint(equalTo: slider.trailingAnchor), track.bottomAnchor.constraint(equalTo: slider.bottomAnchor)])

        let sliderLabel = makeLabel("Volume: 50%")
        slider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([slider.widthAnchor.constraint(equalToConstant: 300)])

        stack.addArrangedSubview(sliderLabel)
        stack.addArrangedSubview(slider)
        return stack
    }

    private func buildToggleDemo() -> NSView {
        let stack = NSStackView(); stack.orientation = .horizontal; stack.spacing = 12

        let toggle = TogglePrimitive.Root()
        let label = makeLabel("Bold")
        toggle.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([toggle.widthAnchor.constraint(equalToConstant: 40), toggle.heightAnchor.constraint(equalToConstant: 32)])

        stack.addArrangedSubview(toggle)
        stack.addArrangedSubview(label)
        return stack
    }

    private func buildToggleGroupDemo() -> NSView {
        let root = ToggleGroupPrimitive.Root(type: .single)

        let item1 = ToggleGroupPrimitive.Item(value: "left")
        let item2 = ToggleGroupPrimitive.Item(value: "center")
        let item3 = ToggleGroupPrimitive.Item(value: "right")

        root.addItem(item1); root.addItem(item2); root.addItem(item3)
        return root
    }

    private func buildSelectDemo() -> NSView {
        let root = SelectPrimitive.Root(defaultValue: "apple")
        let trigger = SelectPrimitive.Trigger()
        let content = SelectPrimitive.Content()

        let group = SelectPrimitive.Group()
        let groupLabel = SelectPrimitive.Label(); groupLabel.text = "Fruits"
        group.addItem(groupLabel)
        group.addItem(SelectPrimitive.Item(value: "apple", text: "Apple"))
        group.addItem(SelectPrimitive.Item(value: "banana", text: "Banana"))
        group.addItem(SelectPrimitive.Item(value: "cherry", text: "Cherry"))
        content.addItem(group)

        root.addSubview(trigger); root.addSubview(content)
        trigger.translatesAutoresizingMaskIntoConstraints = false
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            trigger.topAnchor.constraint(equalTo: root.topAnchor),
            trigger.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            content.topAnchor.constraint(equalTo: trigger.bottomAnchor, constant: 4),
            content.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            content.widthAnchor.constraint(equalToConstant: 200),
        ])
        return root
    }

    private func buildLabelDemo() -> NSView {
        let stack = NSStackView(); stack.orientation = .vertical; stack.spacing = 8

        let label = LabelPrimitive.Root()
        label.text = "Email Address"
        let textField = NSTextField(); textField.placeholderString = "you@example.com"
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([textField.widthAnchor.constraint(equalToConstant: 250)])

        stack.addArrangedSubview(label)
        stack.addArrangedSubview(textField)
        return stack
    }

    // MARK: - Disclosure Demos

    private func buildAccordionDemo() -> NSView {
        let root = AccordionPrimitive.Root(type: .single)

        for (i, title) in ["What is AppKitRadix?", "How do I install it?", "Is it accessible?"].enumerated() {
            let item = AccordionPrimitive.Item(value: "item-\(i)")
            let header = AccordionPrimitive.Header()
            let trigger = AccordionPrimitive.Trigger()
            trigger.title = title
            header.addSubview(trigger)
            trigger.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([trigger.topAnchor.constraint(equalTo: header.topAnchor), trigger.leadingAnchor.constraint(equalTo: header.leadingAnchor), trigger.trailingAnchor.constraint(equalTo: header.trailingAnchor), trigger.bottomAnchor.constraint(equalTo: header.bottomAnchor)])

            let content = AccordionPrimitive.Content()
            let label = makeLabel("Content for: \(title)")
            label.translatesAutoresizingMaskIntoConstraints = false
            content.addSubview(label)
            NSLayoutConstraint.activate([label.topAnchor.constraint(equalTo: content.topAnchor, constant: 8), label.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 8)])

            item.addSubview(header); item.addSubview(content)
            header.translatesAutoresizingMaskIntoConstraints = false; content.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                header.topAnchor.constraint(equalTo: item.topAnchor), header.leadingAnchor.constraint(equalTo: item.leadingAnchor), header.trailingAnchor.constraint(equalTo: item.trailingAnchor),
                content.topAnchor.constraint(equalTo: header.bottomAnchor), content.leadingAnchor.constraint(equalTo: item.leadingAnchor), content.trailingAnchor.constraint(equalTo: item.trailingAnchor), content.bottomAnchor.constraint(equalTo: item.bottomAnchor),
            ])
            root.addItem(item)
        }
        return root
    }

    private func buildCollapsibleDemo() -> NSView {
        let root = CollapsiblePrimitive.Root()
        let trigger = CollapsiblePrimitive.Trigger()
        trigger.title = "Toggle Section"
        let content = CollapsiblePrimitive.Content()
        let label = makeLabel("This is collapsible content that can be shown or hidden.")
        label.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(label)
        NSLayoutConstraint.activate([label.topAnchor.constraint(equalTo: content.topAnchor, constant: 8), label.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 8)])

        let stack = NSStackView(views: [trigger, content])
        stack.orientation = .vertical; stack.spacing = 8
        root.addSubview(stack); stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([stack.topAnchor.constraint(equalTo: root.topAnchor), stack.leadingAnchor.constraint(equalTo: root.leadingAnchor), stack.trailingAnchor.constraint(equalTo: root.trailingAnchor), stack.bottomAnchor.constraint(equalTo: root.bottomAnchor)])
        return root
    }

    // MARK: - Layout Demos

    private func buildAspectRatioDemo() -> NSView {
        let stack = NSStackView(); stack.orientation = .vertical; stack.spacing = 12

        let ratio16_9 = AspectRatioPrimitive.Root(ratio: 16.0 / 9.0)
        ratio16_9.wantsLayer = true; ratio16_9.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.2).cgColor
        ratio16_9.layer?.cornerRadius = 8
        let label = makeLabel("16:9"); label.translatesAutoresizingMaskIntoConstraints = false; label.alignment = .center
        ratio16_9.addSubview(label)
        NSLayoutConstraint.activate([label.centerXAnchor.constraint(equalTo: ratio16_9.centerXAnchor), label.centerYAnchor.constraint(equalTo: ratio16_9.centerYAnchor)])
        ratio16_9.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([ratio16_9.widthAnchor.constraint(equalToConstant: 320)])

        stack.addArrangedSubview(makeLabel("AspectRatio maintains a 16:9 ratio:"))
        stack.addArrangedSubview(ratio16_9)
        return stack
    }

    private func buildAvatarDemo() -> NSView {
        let stack = NSStackView(); stack.orientation = .horizontal; stack.spacing = 16

        let avatar1 = AvatarPrimitive.Root()
        let fallback1 = AvatarPrimitive.Fallback()
        fallback1.text = "JD"
        avatar1.addSubview(fallback1)
        fallback1.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([fallback1.topAnchor.constraint(equalTo: avatar1.topAnchor), fallback1.leadingAnchor.constraint(equalTo: avatar1.leadingAnchor), fallback1.trailingAnchor.constraint(equalTo: avatar1.trailingAnchor), fallback1.bottomAnchor.constraint(equalTo: avatar1.bottomAnchor)])

        let avatar2 = AvatarPrimitive.Root()
        let fallback2 = AvatarPrimitive.Fallback()
        fallback2.text = "AB"
        avatar2.addSubview(fallback2)
        fallback2.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([fallback2.topAnchor.constraint(equalTo: avatar2.topAnchor), fallback2.leadingAnchor.constraint(equalTo: avatar2.leadingAnchor), fallback2.trailingAnchor.constraint(equalTo: avatar2.trailingAnchor), fallback2.bottomAnchor.constraint(equalTo: avatar2.bottomAnchor)])

        stack.addArrangedSubview(avatar1)
        stack.addArrangedSubview(avatar2)
        stack.addArrangedSubview(makeLabel("Avatars with fallback initials"))
        return stack
    }

    private func buildProgressDemo() -> NSView {
        let stack = NSStackView(); stack.orientation = .vertical; stack.spacing = 12

        let progress = ProgressPrimitive.Root()
        progress.value = 66; progress.max = 100
        let indicator = ProgressPrimitive.Indicator()
        progress.addSubview(indicator)

        progress.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([progress.widthAnchor.constraint(equalToConstant: 300), progress.heightAnchor.constraint(equalToConstant: 8)])

        stack.addArrangedSubview(makeLabel("Progress: 66%"))
        stack.addArrangedSubview(progress)
        return stack
    }

    private func buildSeparatorDemo() -> NSView {
        let stack = NSStackView(); stack.orientation = .vertical; stack.spacing = 12

        let sep1 = SeparatorPrimitive.Root(orientation: .horizontal)
        sep1.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([sep1.widthAnchor.constraint(equalToConstant: 300)])

        stack.addArrangedSubview(makeLabel("Content above"))
        stack.addArrangedSubview(sep1)
        stack.addArrangedSubview(makeLabel("Content below"))
        return stack
    }

    private func buildScrollAreaDemo() -> NSView {
        let root = ScrollAreaPrimitive.Root()
        root.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([root.widthAnchor.constraint(equalToConstant: 300), root.heightAnchor.constraint(equalToConstant: 200)])

        let docView = NSView()
        docView.translatesAutoresizingMaskIntoConstraints = false
        let stack = NSStackView(); stack.orientation = .vertical; stack.spacing = 4; stack.translatesAutoresizingMaskIntoConstraints = false
        for i in 1...30 {
            stack.addArrangedSubview(makeLabel("Scrollable item \(i)"))
        }
        docView.addSubview(stack)
        NSLayoutConstraint.activate([stack.topAnchor.constraint(equalTo: docView.topAnchor), stack.leadingAnchor.constraint(equalTo: docView.leadingAnchor), stack.trailingAnchor.constraint(equalTo: docView.trailingAnchor), stack.bottomAnchor.constraint(equalTo: docView.bottomAnchor)])
        root.setDocumentView(docView)
        return root
    }

    private func buildToolbarDemo() -> NSView {
        let root = ToolbarPrimitive.Root()

        let btn1 = ToolbarPrimitive.Button(title: "Cut")
        let btn2 = ToolbarPrimitive.Button(title: "Copy")
        let btn3 = ToolbarPrimitive.Button(title: "Paste")
        let sep = ToolbarPrimitive.Separator()
        let group = ToolbarPrimitive.ToggleGroup()
        let bold = ToolbarPrimitive.ToggleItem(value: "bold", title: "B")
        let italic = ToolbarPrimitive.ToggleItem(value: "italic", title: "I")
        group.addToggle(bold); group.addToggle(italic)

        root.addItem(btn1); root.addItem(btn2); root.addItem(btn3)
        root.addItem(sep); root.addItem(group)
        return root
    }

    // MARK: - Utility Demos

    private func buildAccessibleIconDemo() -> NSView {
        let stack = NSStackView(); stack.orientation = .horizontal; stack.spacing = 12

        let img = NSImage(systemSymbolName: "gear", accessibilityDescription: nil)
        let icon = AccessibleIconPrimitive.Root(label: "Settings gear", image: img)

        stack.addArrangedSubview(icon)
        stack.addArrangedSubview(makeLabel("Accessible icon with VoiceOver label: \"Settings gear\""))
        return stack
    }

    private func buildVisuallyHiddenDemo() -> NSView {
        let stack = NSStackView(); stack.orientation = .vertical; stack.spacing = 12

        let hidden = VisuallyHiddenPrimitive.Root()
        let hiddenLabel = makeLabel("This text is visually hidden but readable by screen readers")
        hiddenLabel.translatesAutoresizingMaskIntoConstraints = false
        hidden.addSubview(hiddenLabel)

        stack.addArrangedSubview(makeLabel("The VisuallyHidden component below contains screen-reader-only text:"))
        stack.addArrangedSubview(hidden)
        stack.addArrangedSubview(makeLabel("(The text above is off-screen but in the accessibility tree)"))
        return stack
    }

    // MARK: - Helpers

    private func makeLabel(_ text: String) -> NSTextField {
        let l = NSTextField(labelWithString: text)
        l.isEditable = false; l.isBordered = false; l.drawsBackground = false
        return l
    }
}
