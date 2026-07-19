import IOKit
import Foundation

protocol LidMonitorDelegate: AnyObject {
    func lidMonitor(_ monitor: LidMonitor, lidDidClose isClosed: Bool)
}

class LidMonitor {
    // These IOPM.h constants are not imported into Swift by the IOKit module.
    private static let clamshellStateChangeMessage: UInt32 = 0xe003_4100
    private static let clamshellClosedFlag: UInt = 1 << 0

    weak var delegate: LidMonitorDelegate?
    private var notifyPort: IONotificationPortRef?
    private var notifierObject: io_object_t = 0
    private var rootDomain: io_service_t = 0
    private var lastKnownState: Bool?
    private var pollTimer: Timer?

    var isLidClosed: Bool {
        readClamshellState()
    }

    func start() {
        rootDomain = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPMrootDomain"))
        guard rootDomain != 0 else {
            NSLog("[LidMonitor] Failed to get IOPMrootDomain")
            return
        }

        notifyPort = IONotificationPortCreate(kIOMainPortDefault)
        guard let port = notifyPort else {
            NSLog("[LidMonitor] Failed to create notification port")
            return
        }

        if let runLoopSource = IONotificationPortGetRunLoopSource(port)?.takeUnretainedValue() {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)
        }

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        let callback: IOServiceInterestCallback = { refcon, service, messageType, messageArgument in
            guard let refcon = refcon else { return }
            let monitor = Unmanaged<LidMonitor>.fromOpaque(refcon).takeUnretainedValue()
            if messageType == LidMonitor.clamshellStateChangeMessage {
                let flags = UInt(bitPattern: messageArgument)
                monitor.handleLidState((flags & LidMonitor.clamshellClosedFlag) != 0)
            } else {
                monitor.handleLidChange()
            }
        }

        let kr = IOServiceAddInterestNotification(port, rootDomain, kIOGeneralInterest, callback, selfPtr, &notifierObject)
        if kr != KERN_SUCCESS {
            NSLog("[LidMonitor] IOServiceAddInterestNotification failed: \(kr)")
        }

        lastKnownState = readClamshellState()
        NSLog("[LidMonitor] Started, initial state closed=\(lastKnownState ?? false)")

        startPolling()
    }

    func stop() {
        stopPolling()

        if notifierObject != 0 {
            IOObjectRelease(notifierObject)
            notifierObject = 0
        }
        if rootDomain != 0 {
            IOObjectRelease(rootDomain)
            rootDomain = 0
        }
        if let port = notifyPort {
            IONotificationPortDestroy(port)
            notifyPort = nil
        }
        lastKnownState = nil
        NSLog("[LidMonitor] Stopped")
    }

    private func startPolling() {
        stopPolling()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.handleLidChange()
        }
        RunLoop.current.add(pollTimer!, forMode: .common)
    }

    private func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func readClamshellState() -> Bool {
        let svc = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPMrootDomain"))
        guard svc != 0 else { return false }
        defer { IOObjectRelease(svc) }

        guard let prop = IORegistryEntryCreateCFProperty(svc, "AppleClamshellState" as CFString, kCFAllocatorDefault, 0) else {
            return false
        }
        return (prop.takeRetainedValue() as? Bool) ?? false
    }

    private func handleLidChange() {
        handleLidState(readClamshellState())
    }

    private func handleLidState(_ current: Bool) {
        guard current != lastKnownState else { return }
        lastKnownState = current
        NSLog("[LidMonitor] Lid state changed: closed=\(current)")
        delegate?.lidMonitor(self, lidDidClose: current)
    }
}
