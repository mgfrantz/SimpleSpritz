import AppKit
import Carbon

private let hotKeySignature = OSType(UInt32(ascii: "CSPZ"))
private let hotKeyID = UInt32(1)

private struct PasteboardSnapshot {
    let items: [[NSPasteboard.PasteboardType: Data]]
}

private struct HotKeySetting {
    var keyCode: UInt32
    var modifiers: UInt32
    var displayName: String
}

private extension UInt32 {
    init(ascii: String) {
        self = ascii.utf8.reduce(0) { ($0 << 8) + UInt32($1) }
    }
}

private final class ReaderState: ObservableObject {
    @Published var word = ""
    @Published var left = ""
    @Published var pivot = ""
    @Published var right = ""
    @Published var progress = "0 / 0"
    @Published var speed = 500
    @Published var rampDuration = 1.0
    @Published var glassOpacity = 0.93
    @Published var hotKeyDisplayName = "Command Option S"
    @Published var isRecordingHotKey = false
    @Published var isRunning = false

    private var words: [String] = []
    private var index = 0
    private var timer: Timer?
    private var rampStartTime: Date?

    func load(_ text: String) {
        words = text
            .replacingOccurrences(of: #"[\r\n\t]+"#, with: " ", options: .regularExpression)
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
        index = 0
        showCurrent()
        start()
    }

    func start() {
        guard !words.isEmpty else { return }
        isRunning = true
        rampStartTime = Date()
        schedule()
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func toggle() {
        isRunning ? pause() : start()
    }

    func setSpeed(_ newSpeed: Int) {
        speed = min(900, max(100, newSpeed))
        if isRunning {
            schedule()
        }
    }

    func setRampDuration(_ duration: Double) {
        rampDuration = min(10.0, max(0.0, duration))
        if isRunning {
            schedule()
        }
    }

    func setGlassOpacity(_ opacity: Double) {
        glassOpacity = min(1.0, max(0.25, opacity))
    }

    func setHotKeyDisplayName(_ displayName: String) {
        hotKeyDisplayName = displayName
        isRecordingHotKey = false
    }

    func step(_ delta: Int) {
        guard !words.isEmpty else { return }
        index = min(words.count - 1, max(0, index + delta))
        showCurrent()
    }

    private func schedule() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: currentInterval(), repeats: false) { [weak self] _ in
            self?.advance()
        }
    }

    private func advance() {
        guard !words.isEmpty else { return }
        if index >= words.count - 1 {
            pause()
            return
        }
        index += 1
        showCurrent()
        if isRunning {
            schedule()
        }
    }

    private func currentInterval() -> TimeInterval {
        60.0 / currentSpeed()
    }

    private func currentSpeed() -> Double {
        let targetSpeed = Double(speed)
        guard rampDuration > 0, let rampStartTime else {
            return targetSpeed
        }

        let elapsed = Date().timeIntervalSince(rampStartTime)
        let progress = min(1.0, max(0.0, elapsed / rampDuration))
        let speedMultiplier = 0.5 + (0.5 * progress)
        return targetSpeed * speedMultiplier
    }

    private func showCurrent() {
        guard !words.isEmpty else {
            left = ""
            pivot = "Paste text first"
            right = ""
            progress = "0 / 0"
            return
        }

        let current = words[index]
        let pivotIndex = pivotOffset(for: current.count)
        let chars = Array(current)
        left = String(chars.prefix(pivotIndex))
        pivot = String(chars[pivotIndex])
        right = String(chars.dropFirst(pivotIndex + 1))
        word = current
        progress = "\(index + 1) / \(words.count)"
    }

    private func pivotOffset(for count: Int) -> Int {
        switch count {
        case 0...1: return 0
        case 2...5: return 1
        case 6...9: return 2
        case 10...13: return 3
        default: return 4
        }
    }
}

private final class ReaderView: NSView {
    private let state: ReaderState
    private let onHotKeyRecorded: (HotKeySetting) -> Void
    private let glassView = NSVisualEffectView()
    private let appLabel = NSTextField(labelWithString: "SimpleSpritz")
    private let leftLabel = NSTextField(labelWithString: "")
    private let pivotLabel = NSTextField(labelWithString: "")
    private let rightLabel = NSTextField(labelWithString: "")
    private let progressLabel = NSTextField(labelWithString: "")
    private let speedLabel = NSTextField(labelWithString: "")
    private let rampLabel = NSTextField(labelWithString: "")
    private let opacityLabel = NSTextField(labelWithString: "")
    private let hotKeyLabel = NSTextField(labelWithString: "")
    private let settingsButton = NSButton(title: "Settings", target: nil, action: nil)
    private let hotKeyButton = NSButton(title: "Change Hotkey", target: nil, action: nil)
    private let playButton = NSButton(title: "Pause", target: nil, action: nil)
    private let slowerButton = NSButton(title: "-", target: nil, action: nil)
    private let fasterButton = NSButton(title: "+", target: nil, action: nil)
    private let shorterRampButton = NSButton(title: "-", target: nil, action: nil)
    private let longerRampButton = NSButton(title: "+", target: nil, action: nil)
    private let speedSlider = NSSlider(value: 500, minValue: 100, maxValue: 900, target: nil, action: nil)
    private let rampSlider = NSSlider(value: 1, minValue: 0, maxValue: 10, target: nil, action: nil)
    private let opacitySlider = NSSlider(value: 0.93, minValue: 0.25, maxValue: 1.0, target: nil, action: nil)
    private let settingsStack = NSStackView()
    private var settingsExpanded = false

    init(state: ReaderState, onHotKeyRecorded: @escaping (HotKeySetting) -> Void) {
        self.state = state
        self.onHotKeyRecorded = onHotKeyRecorded
        super.init(frame: NSRect(x: 0, y: 0, width: 660, height: 210))
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.cornerRadius = 22
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.white.withAlphaComponent(0.28).cgColor
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = 0.22
        layer?.shadowRadius = 24
        layer?.shadowOffset = NSSize(width: 0, height: -8)
        build()
        refresh()
        Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in self?.refresh() }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if state.isRecordingHotKey {
            recordHotKey(from: event)
            return
        }

        switch event.keyCode {
        case 49: state.toggle()
        case 123: state.step(-1)
        case 124: state.step(1)
        case 126: state.setSpeed(state.speed + 25)
        case 125: state.setSpeed(state.speed - 25)
        case 12 where event.modifierFlags.contains(.command): NSApp.terminate(nil)
        case 53: window?.close()
        default: super.keyDown(with: event)
        }
    }

    private func build() {
        glassView.material = .hudWindow
        glassView.blendingMode = .behindWindow
        glassView.state = .active
        glassView.wantsLayer = true
        glassView.layer?.cornerRadius = 22
        glassView.layer?.masksToBounds = true
        glassView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(glassView)

        appLabel.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        appLabel.textColor = .secondaryLabelColor
        appLabel.alignment = .center
        appLabel.translatesAutoresizingMaskIntoConstraints = false

        let wordRow = NSStackView(views: [leftLabel, pivotLabel, rightLabel])
        wordRow.orientation = .horizontal
        wordRow.alignment = .centerY
        wordRow.spacing = 0
        wordRow.translatesAutoresizingMaskIntoConstraints = false

        for label in [leftLabel, pivotLabel, rightLabel] {
            label.font = NSFont.monospacedSystemFont(ofSize: 42, weight: .medium)
            label.textColor = .labelColor
            label.alignment = .center
            label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        }
        leftLabel.alignment = .right
        leftLabel.widthAnchor.constraint(equalToConstant: 250).isActive = true
        pivotLabel.textColor = .systemRed
        pivotLabel.widthAnchor.constraint(equalToConstant: 28).isActive = true
        rightLabel.alignment = .left
        rightLabel.widthAnchor.constraint(equalToConstant: 250).isActive = true

        settingsButton.target = self
        settingsButton.action = #selector(toggleSettings)
        hotKeyButton.target = self
        hotKeyButton.action = #selector(startRecordingHotKey)
        playButton.target = self
        playButton.action = #selector(toggle)
        slowerButton.target = self
        slowerButton.action = #selector(slower)
        fasterButton.target = self
        fasterButton.action = #selector(faster)
        speedSlider.target = self
        speedSlider.action = #selector(sliderChanged)
        shorterRampButton.target = self
        shorterRampButton.action = #selector(shorterRamp)
        longerRampButton.target = self
        longerRampButton.action = #selector(longerRamp)
        rampSlider.target = self
        rampSlider.action = #selector(rampSliderChanged)
        opacitySlider.target = self
        opacitySlider.action = #selector(opacitySliderChanged)

        let controls = NSStackView(views: [playButton, slowerButton, speedSlider, fasterButton, speedLabel])
        controls.orientation = .horizontal
        controls.alignment = .centerY
        controls.spacing = 10
        controls.translatesAutoresizingMaskIntoConstraints = false
        speedSlider.widthAnchor.constraint(equalToConstant: 180).isActive = true

        let rampControls = NSStackView(views: [NSTextField(labelWithString: "Ramp"), shorterRampButton, rampSlider, longerRampButton, rampLabel])
        rampControls.orientation = .horizontal
        rampControls.alignment = .centerY
        rampControls.spacing = 10
        rampControls.translatesAutoresizingMaskIntoConstraints = false
        rampSlider.widthAnchor.constraint(equalToConstant: 180).isActive = true

        let opacityControls = NSStackView(views: [NSTextField(labelWithString: "Glass"), opacitySlider, opacityLabel])
        opacityControls.orientation = .horizontal
        opacityControls.alignment = .centerY
        opacityControls.spacing = 10
        opacityControls.translatesAutoresizingMaskIntoConstraints = false
        opacitySlider.widthAnchor.constraint(equalToConstant: 180).isActive = true

        let hotKeyControls = NSStackView(views: [NSTextField(labelWithString: "Hotkey"), hotKeyButton, hotKeyLabel])
        hotKeyControls.orientation = .horizontal
        hotKeyControls.alignment = .centerY
        hotKeyControls.spacing = 10
        hotKeyControls.translatesAutoresizingMaskIntoConstraints = false

        for label in [speedLabel, rampLabel, opacityLabel, hotKeyLabel] {
            label.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            label.textColor = .secondaryLabelColor
            label.alignment = .left
        }
        for label in [speedLabel, rampLabel, opacityLabel] {
            label.widthAnchor.constraint(equalToConstant: 70).isActive = true
        }
        hotKeyLabel.widthAnchor.constraint(equalToConstant: 180).isActive = true

        progressLabel.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        progressLabel.textColor = .secondaryLabelColor
        progressLabel.alignment = .center
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.translatesAutoresizingMaskIntoConstraints = false

        settingsStack.orientation = .vertical
        settingsStack.alignment = .centerX
        settingsStack.spacing = 12
        settingsStack.translatesAutoresizingMaskIntoConstraints = false
        settingsStack.addArrangedSubview(controls)
        settingsStack.addArrangedSubview(rampControls)
        settingsStack.addArrangedSubview(opacityControls)
        settingsStack.addArrangedSubview(hotKeyControls)
        settingsStack.isHidden = true

        addSubview(appLabel)
        addSubview(wordRow)
        addSubview(progressLabel)
        addSubview(settingsButton)
        addSubview(settingsStack)

        NSLayoutConstraint.activate([
            glassView.leadingAnchor.constraint(equalTo: leadingAnchor),
            glassView.trailingAnchor.constraint(equalTo: trailingAnchor),
            glassView.topAnchor.constraint(equalTo: topAnchor),
            glassView.bottomAnchor.constraint(equalTo: bottomAnchor),
            appLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            appLabel.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            wordRow.centerXAnchor.constraint(equalTo: centerXAnchor),
            wordRow.topAnchor.constraint(equalTo: appLabel.bottomAnchor, constant: 34),
            progressLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            progressLabel.topAnchor.constraint(equalTo: wordRow.bottomAnchor, constant: 22),
            settingsButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            settingsButton.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 14),
            settingsStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            settingsStack.topAnchor.constraint(equalTo: settingsButton.bottomAnchor, constant: 14)
        ])
    }

    private func refresh() {
        leftLabel.stringValue = state.left
        pivotLabel.stringValue = state.pivot
        rightLabel.stringValue = state.right
        progressLabel.stringValue = state.progress
        speedLabel.stringValue = "\(state.speed) wpm"
        rampLabel.stringValue = String(format: "%.1fs", state.rampDuration)
        opacityLabel.stringValue = "\(Int(round(state.glassOpacity * 100)))%"
        hotKeyLabel.stringValue = state.isRecordingHotKey ? "Press keys..." : state.hotKeyDisplayName
        hotKeyButton.title = state.isRecordingHotKey ? "Recording..." : "Change Hotkey"
        alphaValue = CGFloat(state.glassOpacity)
        settingsButton.title = settingsExpanded ? "Hide Settings" : "Settings"
        playButton.title = state.isRunning ? "Pause" : "Read"
        if Int(speedSlider.integerValue) != state.speed {
            speedSlider.integerValue = state.speed
        }
        if abs(rampSlider.doubleValue - state.rampDuration) > 0.05 {
            rampSlider.doubleValue = state.rampDuration
        }
        if abs(opacitySlider.doubleValue - state.glassOpacity) > 0.01 {
            opacitySlider.doubleValue = state.glassOpacity
        }
    }

    @objc private func toggle() { state.toggle() }
    @objc private func toggleSettings() {
        settingsExpanded.toggle()
        settingsStack.isHidden = !settingsExpanded
        resizeWindowForSettings()
    }
    @objc private func slower() { state.setSpeed(state.speed - 25) }
    @objc private func faster() { state.setSpeed(state.speed + 25) }
    @objc private func sliderChanged() { state.setSpeed(speedSlider.integerValue) }
    @objc private func shorterRamp() { state.setRampDuration(state.rampDuration - 0.5) }
    @objc private func longerRamp() { state.setRampDuration(state.rampDuration + 0.5) }
    @objc private func rampSliderChanged() { state.setRampDuration(rampSlider.doubleValue) }
    @objc private func opacitySliderChanged() { state.setGlassOpacity(opacitySlider.doubleValue) }
    @objc private func startRecordingHotKey() {
        state.isRecordingHotKey = true
        window?.makeFirstResponder(self)
    }

    private func resizeWindowForSettings() {
        guard let window else { return }

        let newHeight: CGFloat = settingsExpanded ? 362 : 210
        let currentFrame = window.frame
        let newFrame = NSRect(
            x: currentFrame.origin.x,
            y: currentFrame.origin.y + currentFrame.height - newHeight,
            width: currentFrame.width,
            height: newHeight
        )

        window.setFrame(newFrame, display: true, animate: true)
    }

    private func recordHotKey(from event: NSEvent) {
        guard let setting = hotKeySetting(from: event) else {
            NSSound.beep()
            state.isRecordingHotKey = false
            return
        }

        onHotKeyRecorded(setting)
    }

    private func hotKeySetting(from event: NSEvent) -> HotKeySetting? {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let keyCode = UInt32(event.keyCode)
        guard !flags.intersection([.command, .option, .control, .shift]).isEmpty else {
            return nil
        }

        var carbonModifiers = UInt32(0)
        var parts: [String] = []
        if flags.contains(.command) {
            carbonModifiers |= UInt32(cmdKey)
            parts.append("Command")
        }
        if flags.contains(.option) {
            carbonModifiers |= UInt32(optionKey)
            parts.append("Option")
        }
        if flags.contains(.control) {
            carbonModifiers |= UInt32(controlKey)
            parts.append("Control")
        }
        if flags.contains(.shift) {
            carbonModifiers |= UInt32(shiftKey)
            parts.append("Shift")
        }

        parts.append(keyName(for: event))
        return HotKeySetting(keyCode: keyCode, modifiers: carbonModifiers, displayName: parts.joined(separator: " "))
    }

    private func keyName(for event: NSEvent) -> String {
        if let characters = event.charactersIgnoringModifiers, !characters.isEmpty {
            return characters.uppercased()
        }

        switch Int(event.keyCode) {
        case kVK_Space: return "Space"
        case kVK_Escape: return "Escape"
        case kVK_LeftArrow: return "Left"
        case kVK_RightArrow: return "Right"
        case kVK_UpArrow: return "Up"
        case kVK_DownArrow: return "Down"
        default: return "Key \(event.keyCode)"
        }
    }
}

private final class AppDelegate: NSObject, NSApplicationDelegate {
    private let state = ReaderState()
    private var window: NSWindow?
    private var statusItem: NSStatusItem?
    private var hotKeyRef: EventHotKeyRef?
    private var hotKeyEventHandlerRef: EventHandlerRef?
    private var keyMonitor: Any?
    private var hotKeySetting = HotKeySetting(
        keyCode: UInt32(kVK_ANSI_S),
        modifiers: UInt32(cmdKey | optionKey),
        displayName: "Command Option S"
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        buildAppMenu()
        buildMenu()
        registerKeyMonitor()
        registerHotKey()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let hotKeyEventHandlerRef {
            RemoveEventHandler(hotKeyEventHandlerRef)
        }
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
        }
    }

    private func buildMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.button?.image = statusBarIcon()
        statusItem?.button?.toolTip = "SimpleSpritz"
        let menu = NSMenu()
        let readItem = NSMenuItem(title: "Read Selection", action: #selector(readSelection), keyEquivalent: "s")
        readItem.keyEquivalentModifierMask = [.command, .option]
        readItem.target = self
        menu.addItem(readItem)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem?.menu = menu
    }

    private func statusBarIcon() -> NSImage? {
        guard let icon = NSImage(named: "StatusBarIcon") else {
            return nil
        }

        icon.size = NSSize(width: 18, height: 18)
        icon.isTemplate = true
        return icon
    }

    private func buildAppMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu(title: "SimpleSpritz")

        let readItem = NSMenuItem(title: "Read Selection", action: #selector(readSelection), keyEquivalent: "s")
        readItem.keyEquivalentModifierMask = [.command, .option]
        readItem.target = self
        appMenu.addItem(readItem)
        let quitItem = NSMenuItem(title: "Quit SimpleSpritz", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        appMenu.addItem(quitItem)

        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        NSApp.mainMenu = mainMenu
    }

    private func registerKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.command), event.keyCode == UInt16(kVK_ANSI_Q) {
                NSApp.terminate(nil)
                return nil
            }
            return event
        }
    }

    private func registerHotKey() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if hotKeyEventHandlerRef == nil {
            var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
            let handlerStatus = InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
                var id = EventHotKeyID()
                GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &id)
                if id.signature == hotKeySignature && id.id == hotKeyID {
                    let appDelegate = Unmanaged<AppDelegate>.fromOpaque(userData!).takeUnretainedValue()
                    appDelegate.readSelection()
                }
                return noErr
            }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &hotKeyEventHandlerRef)

            guard handlerStatus == noErr else {
                NSLog("SimpleSpritz failed to install hotkey handler: \(handlerStatus)")
                return
            }
        }

        let id = EventHotKeyID(signature: hotKeySignature, id: hotKeyID)
        let hotKeyStatus = RegisterEventHotKey(hotKeySetting.keyCode, hotKeySetting.modifiers, id, GetApplicationEventTarget(), 0, &hotKeyRef)
        if hotKeyStatus != noErr {
            NSLog("SimpleSpritz failed to register hotkey \(hotKeySetting.displayName): \(hotKeyStatus)")
        }
    }

    private func updateHotKey(_ setting: HotKeySetting) {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        hotKeySetting = setting
        state.setHotKeyDisplayName(setting.displayName)
        registerHotKey()
    }

    @objc private func readSelection() {
        guard let text = selectedText() else {
            NSSound.beep()
            return
        }

        showWindow()
        state.load(text)
    }

    private func requestAccessibilityPermissionIfNeeded() {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptKey: true] as CFDictionary
        if !AXIsProcessTrustedWithOptions(options) {
            NSLog("SimpleSpritz needs Accessibility permission to copy selected text.")
        }
    }

    private func selectedText() -> String? {
        guard AXIsProcessTrusted() else {
            requestAccessibilityPermissionIfNeeded()
            return nil
        }

        let pasteboard = NSPasteboard.general
        let snapshot = snapshotPasteboard(pasteboard)
        let originalChangeCount = pasteboard.changeCount

        sendCopyCommand()

        let deadline = Date().addingTimeInterval(1.0)
        while pasteboard.changeCount == originalChangeCount && Date() < deadline {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.01))
        }

        guard pasteboard.changeCount != originalChangeCount else {
            restorePasteboard(pasteboard, from: snapshot)
            return nil
        }

        let text = pasteboard.string(forType: .string)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        restorePasteboard(pasteboard, from: snapshot)

        guard let text, !text.isEmpty else {
            return nil
        }

        return text
    }

    private func sendCopyCommand() {
        guard let source = CGEventSource(stateID: .combinedSessionState),
              let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: false) else {
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }

    private func snapshotPasteboard(_ pasteboard: NSPasteboard) -> PasteboardSnapshot {
        let items = pasteboard.pasteboardItems?.map { item in
            item.types.reduce(into: [NSPasteboard.PasteboardType: Data]()) { result, type in
                if let data = item.data(forType: type) {
                    result[type] = data
                }
            }
        } ?? []

        return PasteboardSnapshot(items: items)
    }

    private func restorePasteboard(_ pasteboard: NSPasteboard, from snapshot: PasteboardSnapshot) {
        pasteboard.clearContents()
        let restoredItems = snapshot.items.map { storedItem in
            let item = NSPasteboardItem()
            for (type, data) in storedItem {
                item.setData(data, forType: type)
            }
            return item
        }
        pasteboard.writeObjects(restoredItems)
    }

    private func showWindow() {
        if window == nil {
            let view = ReaderView(state: state) { [weak self] setting in
                self?.updateHotKey(setting)
            }
            let created = NSWindow(
                contentRect: view.frame,
                styleMask: [.titled, .closable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            created.title = "SimpleSpritz"
            created.contentView = view
            created.isReleasedWhenClosed = false
            created.level = .floating
            created.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            created.isOpaque = false
            created.backgroundColor = .clear
            created.hasShadow = false
            created.titlebarAppearsTransparent = true
            created.titleVisibility = .hidden
            created.center()
            window = created
        }

        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
        window?.contentView?.window?.makeFirstResponder(window?.contentView)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

let app = NSApplication.shared
private let delegate = AppDelegate()
app.delegate = delegate
app.run()
