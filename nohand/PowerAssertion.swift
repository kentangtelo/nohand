import Foundation

struct PowerAssertion {
    private var id: UInt32 = 0
    private var caffeinateProcess: Process?

    private typealias CreateFunc = @convention(c) (
        CFString, UInt32, CFString, UnsafeMutablePointer<UInt32>
    ) -> Int32
    private typealias ReleaseFunc = @convention(c) (UInt32) -> Int32

    mutating func acquire(name: String) {
        guard id == 0 else { return }

        tryIOKit(assertionType: "PreventUserIdleSystemSleep", name: name)

        if id == 0 {
            tryCaffeinate()
        }
    }

    mutating func release() {
        stopCaffeinate()

        guard id != 0 else { return }
        guard let releaseFn: ReleaseFunc = loadSymbol("IOPMAssertionRelease") else {
            NSLog("[PowerAssertion] IOPMAssertionRelease not found")
            id = 0
            return
        }
        _ = releaseFn(id)
        NSLog("[PowerAssertion] Released: \(id)")
        id = 0
    }

    private mutating func tryIOKit(assertionType: String, name: String) {
        guard let create: CreateFunc = loadSymbol("IOPMAssertionCreateWithName") else {
            NSLog("[PowerAssertion] IOPMAssertionCreateWithName not found in IOKit")
            return
        }

        var localID: UInt32 = 0
        let kr = create(assertionType as CFString, 255, name as CFString, &localID)
        if kr == 0 {
            id = localID
            NSLog("[PowerAssertion] '\(assertionType)' acquired: \(id)")
        } else {
            NSLog("[PowerAssertion] '\(assertionType)' failed: \(kr)")
        }
    }

    private mutating func tryCaffeinate() {
        let process = Process()
        process.launchPath = "/usr/bin/caffeinate"
        process.arguments = ["-i"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            caffeinateProcess = process
            NSLog("[PowerAssertion] caffeinate -i started (pid \(process.processIdentifier))")
        } catch {
            NSLog("[PowerAssertion] caffeinate failed: \(error)")
        }
    }

    private mutating func stopCaffeinate() {
        if let p = caffeinateProcess, p.isRunning {
            p.terminate()
            NSLog("[PowerAssertion] caffeinate stopped")
        }
        caffeinateProcess = nil
    }

    var isActive: Bool { id != 0 || caffeinateProcess?.isRunning == true }

    private func loadSymbol<T>(_ name: String) -> T? {
        let path = "/System/Library/Frameworks/IOKit.framework/IOKit"
        guard let handle = dlopen(path, RTLD_LAZY) else { return nil }
        guard let sym = dlsym(handle, name) else { return nil }
        return unsafeBitCast(sym, to: T.self)
    }
}
