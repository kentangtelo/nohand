import AppKit

final class ClamshellSleepController {
    private let recoveryKey = "clamshellSleepDisabledByNoHand"
    private(set) var lastError: String?

    var needsRestore: Bool {
        UserDefaults.standard.bool(forKey: recoveryKey)
    }

    func preventClamshellSleep() -> Bool {
        guard !needsRestore else { return true }
        guard runPMSet(disableSleep: true) else { return false }

        UserDefaults.standard.set(true, forKey: recoveryKey)
        NSLog("[ClamshellSleepController] System sleep disabled")
        return true
    }

    func restoreClamshellSleep() -> Bool {
        guard needsRestore else { return true }
        guard runPMSet(disableSleep: false) else { return false }

        UserDefaults.standard.removeObject(forKey: recoveryKey)
        NSLog("[ClamshellSleepController] System sleep restored")
        return true
    }

    private func runPMSet(disableSleep: Bool) -> Bool {
        let value = disableSleep ? "1" : "0"
        let source = "do shell script \"/usr/bin/pmset -a disablesleep \(value)\" with administrator privileges"
        guard let script = NSAppleScript(source: source) else {
            lastError = "Could not create the administrator command."
            return false
        }

        var error: NSDictionary?
        script.executeAndReturnError(&error)
        if let error {
            lastError = error[NSAppleScript.errorMessage] as? String ?? error.description
            NSLog("[ClamshellSleepController] pmset failed: \(lastError ?? "Unknown error")")
            return false
        }

        lastError = nil
        return true
    }
}
