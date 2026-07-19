import XCTest
@testable import nohand

final class AlarmControllerTests: XCTestCase {
    var controller: AlarmController!

    override func setUp() {
        super.setUp()
        controller = AlarmController()
    }

    override func tearDown() {
        controller.stop()
        controller = nil
        super.tearDown()
    }

    func testTriggerDoesNotThrow() {
        controller.trigger()
    }

    func testDoubleTriggerDoesNotCrash() {
        controller.trigger()
        controller.trigger()
    }

    func testStopWhenNotPlayingDoesNotCrash() {
        controller.stop()
    }

    func testStopAfterTriggerDoesNotCrash() {
        controller.trigger()
        controller.stop()
    }

    func testStopAfterDoubleTrigger() {
        controller.trigger()
        controller.trigger()
        controller.stop()
    }

    func testDeinitStopsCleanly() {
        var c: AlarmController? = AlarmController()
        c?.trigger()
        c = nil
    }
}
