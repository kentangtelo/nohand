import AppKit
import Foundation

class LockScreenController {
    var onUnlock: (() -> Void)?

    private let center = DistributedNotificationCenter.default()

    func lockNow() {
        if sacLockScreen() {
            NSLog("[LockScreenController] Lock screen triggered via SACLockScreenImmediate")
            return
        }

        if cgsessionSuspend() {
            NSLog("[LockScreenController] Lock screen triggered via CGSession")
            return
        }

        tryAppleScript()
    }

    private func sacLockScreen() -> Bool {
        typealias LockFunc = @convention(c) () -> Void

        guard let handle = dlopen(nil, RTLD_LAZY) else { return false }
        defer { dlclose(handle) }

        guard let sym = dlsym(handle, "SACLockScreenImmediate") else { return false }
        let lockScreen = unsafeBitCast(sym, to: LockFunc.self)
        lockScreen()
        return true
    }

    private func cgsessionSuspend() -> Bool {
        let path = "/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession"
        guard FileManager.default.isExecutableFile(atPath: path) else { return false }

        let process = Process()
        process.launchPath = path
        process.arguments = ["-suspend"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    private func tryAppleScript() {
        let opts = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): false] as CFDictionary
        guard AXIsProcessTrustedWithOptions(opts) else {
            showAccessibilityAlert()
            return
        }

        let script = """
        tell application "System Events"
            keystroke "q" using {control down, command down}
        end tell
        """

        guard let appleScript = NSAppleScript(source: script) else {
            NSLog("[LockScreenController] Failed to create AppleScript")
            return
        }

        var error: NSDictionary?
        appleScript.executeAndReturnError(&error)

        if let error = error {
            NSLog("[LockScreenController] AppleScript failed: \(error)")
            showAccessibilityAlert()
        } else {
            NSLog("[LockScreenController] Lock screen triggered via AppleScript")
        }
    }

    func startMonitoring() {
        center.addObserver(
            self,
            selector: #selector(handleUnlock),
            name: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil
        )
        NSLog("[LockScreenController] Monitoring unlock events")
    }

    func stopMonitoring() {
        center.removeObserver(self)
        NSLog("[LockScreenController] Stopped monitoring")
    }

    @objc private func handleUnlock(_ notification: Notification) {
        NSLog("[LockScreenController] Screen unlocked detected")
        DispatchQueue.main.async { [weak self] in
            self?.onUnlock?()
        }
    }

    private func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "Lock Screen Failed"
        alert.informativeText = """
        NoHand could not trigger the lock screen.

        Please go to System Settings → Privacy & Security → Accessibility,
        then enable NoHand in the list. After enabling, remove it from
        the list and re-add it to refresh permissions.

        After that, try arming again.
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Later")

        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(
                URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            )
        }
    }

    deinit {
        stopMonitoring()
    }
}
