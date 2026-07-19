import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    enum State {
        case disarmed
        case armed
        case triggered
    }

    private var statusItem: NSStatusItem!
    private let lidMonitor = LidMonitor()
    private let alarmController = AlarmController()
    private let lockScreenController = LockScreenController()
    private let clamshellSleepController = ClamshellSleepController()
    private var state: State = .disarmed
    private var sleepAssertion = PowerAssertion()
    private var appNapActivity: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        setupStatusItem()
        NSApp.activate(ignoringOtherApps: true)

        if clamshellSleepController.needsRestore && !clamshellSleepController.restoreClamshellSleep() {
            showClamshellSleepError(action: "restore normal sleep after the previous run")
        }

        lidMonitor.delegate = self
        lidMonitor.start()

        lockScreenController.onUnlock = { [weak self] in
            self?.handleUnlock()
        }
        lockScreenController.startMonitoring()

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleWillSleep(_:)),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleDidWake(_:)),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        appNapActivity = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .latencyCritical],
            reason: "NoHand: Lid monitoring active"
        )

        NSLog("[AppDelegate] NoHand launched — state: disarmed")
    }

    func applicationWillTerminate(_ notification: Notification) {
        alarmController.stop()
        lidMonitor.stop()
        lockScreenController.stopMonitoring()
        sleepAssertion.release()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        if let activity = appNapActivity {
            ProcessInfo.processInfo.endActivity(activity)
        }
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard clamshellSleepController.restoreClamshellSleep() else {
            showClamshellSleepError(action: "restore normal sleep before quitting")
            return .terminateCancel
        }
        return .terminateNow
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem.button else {
            NSLog("[AppDelegate] ERROR: statusItem.button is nil")
            return
        }

        button.title = "NoHand"
        button.imagePosition = .imageLeading

        updateStatusIcon()

        let menu = NSMenu()

        let armItem = NSMenuItem(title: "Arm", action: #selector(toggleArm), keyEquivalent: "")
        armItem.tag = 1
        menu.addItem(armItem)

        menu.addItem(NSMenuItem.separator())

        let setTopicItem = NSMenuItem(title: "Set ntfy Topic...", action: #selector(setTopic), keyEquivalent: "")
        menu.addItem(setTopicItem)

        let testNotifItem = NSMenuItem(title: "Test Notification", action: #selector(testNotification), keyEquivalent: "")
        menu.addItem(testNotifItem)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Quit NoHand", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    private func updateStatusIcon() {
        guard let button = statusItem.button else { return }

        let symbolName: String
        switch state {
        case .disarmed: symbolName = "shield"
        case .armed: symbolName = "shield.fill"
        case .triggered: symbolName = "exclamationmark.shield.fill"
        }

        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) {
            let configured = image.withSymbolConfiguration(config)
            configured?.isTemplate = true
            button.image = configured
        }
    }

    @objc private func toggleArm(_ sender: NSMenuItem) {
        switch state {
        case .disarmed:
            guard confirmClamshellSleepRiskIfNeeded() else { return }
            if !clamshellSleepController.preventClamshellSleep() {
                showClamshellSleepError(action: "keep the Mac awake with its lid closed")
                return
            }
            state = .armed
            updateStatusIcon()
            sender.title = "Armed"
            sleepAssertion.acquire(name: "NoHand: Armed")
            alarmController.prepare()
            lockScreenController.lockNow()
            NSLog("[AppDelegate] ARMED — assertion=\(sleepAssertion.isActive)")
        case .armed:
            state = .disarmed
            updateStatusIcon()
            sender.title = "Arm"
            alarmController.stop()
            sleepAssertion.release()
            restoreClamshellSleepIfNeeded()
            NSLog("[AppDelegate] DISARMED (manual)")
        case .triggered:
            break
        }
    }

    private func confirmClamshellSleepRiskIfNeeded() -> Bool {
        let key = "didAcknowledgeClamshellSleepRisk"
        guard !UserDefaults.standard.bool(forKey: key) else { return true }

        let alert = NSAlert()
        alert.messageText = "Keep Mac Awake While Armed?"
        alert.informativeText = "Arming NoHand changes a system-wide sleep setting so the alarm can continue with the lid closed. This may increase battery use and heat. Normal sleep is restored when you unlock, disarm, or quit."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Continue and Arm")
        alert.addButton(withTitle: "Cancel")

        guard alert.runModal() == .alertFirstButtonReturn else { return false }
        UserDefaults.standard.set(true, forKey: key)
        return true
    }

    @objc private func setTopic() {
        let alert = NSAlert()
        alert.messageText = "Set ntfy.sh Topic"
        alert.informativeText = "Enter your ntfy.sh topic name (e.g., my-secret-topic-123):"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 280, height: 24))
        textField.placeholderString = "my-topic"
        textField.stringValue = UserDefaults.standard.string(forKey: "ntfyTopic") ?? ""
        alert.accessoryView = textField

        if alert.runModal() == .alertFirstButtonReturn {
            let topic = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            UserDefaults.standard.set(topic, forKey: "ntfyTopic")
            NSLog("[AppDelegate] ntfy topic saved: \(topic)")
        }
    }

    @objc private func testNotification() {
        let topic = UserDefaults.standard.string(forKey: "ntfyTopic") ?? ""
        if topic.isEmpty {
            let alert = NSAlert()
            alert.messageText = "Topic Not Set"
            alert.informativeText = "Please set your ntfy.sh topic first."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }
        NtfyNotifier.shared.sendTestNotification(topic: topic)
        NSLog("[AppDelegate] Test notification sent")
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    @objc private func handleWillSleep(_ notification: Notification) {
        NSLog("[AppDelegate] willSleepNotification — state=\(state)")
        if state == .armed {
            NSLog("[AppDelegate] Sleep detected while armed — triggering alarm")
            handleTrigger()
        }
    }

    @objc private func handleDidWake(_ notification: Notification) {
        NSLog("[AppDelegate] didWakeNotification — state=\(state)")
        if state == .triggered {
            alarmController.resumeAfterWake()
        }
    }

    private func handleTrigger() {
        guard state == .armed else {
            NSLog("[AppDelegate] handleTrigger ignored — state is \(state)")
            return
        }
        state = .triggered
        NSLog("[AppDelegate] TRIGGERED — firing alarm")

        updateStatusIcon()

        alarmController.trigger()

        let topic = UserDefaults.standard.string(forKey: "ntfyTopic") ?? ""
        NtfyNotifier.shared.sendTheftAlert(topic: topic)
    }

    private func handleUnlock() {
        switch state {
        case .triggered:
            alarmController.stop()
            fallthrough
        case .armed:
            disarm()
        case .disarmed:
            break
        }
    }

    private func disarm() {
        alarmController.stop()
        state = .disarmed
        updateStatusIcon()
        sleepAssertion.release()
        restoreClamshellSleepIfNeeded()

        if let armItem = statusItem.menu?.item(withTag: 1) {
            armItem.title = "Arm"
        }

        NSLog("[AppDelegate] DISARMED via unlock")
    }

    private func restoreClamshellSleepIfNeeded() {
        if !clamshellSleepController.restoreClamshellSleep() {
            showClamshellSleepError(action: "restore normal sleep")
        }
    }

    private func showClamshellSleepError(action: String) {
        let alert = NSAlert()
        alert.messageText = "Could Not Change Sleep Setting"
        alert.informativeText = "NoHand could not \(action).\n\n\(clamshellSleepController.lastError ?? "Unknown error")"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

extension AppDelegate: LidMonitorDelegate {
    func lidMonitor(_ monitor: LidMonitor, lidDidClose isClosed: Bool) {
        NSLog("[AppDelegate] LidMonitor: closed=\(isClosed) state=\(state)")
        if isClosed && state == .armed {
            NSLog("[AppDelegate] Lid closed while armed — triggering alarm")
            handleTrigger()
        }
    }
}
