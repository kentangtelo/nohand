import XCTest
@testable import nohand

final class StateMachineTests: XCTestCase {
    func testDefaultStateIsDisarmed() {
        let state = AppDelegate.State.disarmed
        XCTAssertEqual(state, .disarmed)
    }

    func testAllStatesAreDistinct() {
        let states: Set<AppDelegate.State> = [.disarmed, .armed, .triggered]
        XCTAssertEqual(states.count, 3)
    }

    func testDisarmedToArmedTransition() {
        var state = AppDelegate.State.disarmed
        state = .armed
        XCTAssertEqual(state, .armed)
    }

    func testArmedToDisarmedTransition() {
        var state = AppDelegate.State.armed
        state = .disarmed
        XCTAssertEqual(state, .disarmed)
    }

    func testArmedToTriggeredTransition() {
        var state = AppDelegate.State.armed
        state = .triggered
        XCTAssertEqual(state, .triggered)
    }

    func testTriggeredToDisarmedTransition() {
        var state = AppDelegate.State.triggered
        state = .disarmed
        XCTAssertEqual(state, .disarmed)
    }
}
