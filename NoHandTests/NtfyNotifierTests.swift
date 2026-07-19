import XCTest
@testable import nohand

final class MockURLSessionDataTask: URLSessionDataTaskProtocol {
    private let closure: () -> Void
    init(closure: @escaping () -> Void) { self.closure = closure }
    func resume() { closure() }
}

final class MockURLSession: URLSessionProtocol {
    var lastRequest: URLRequest?
    var nextData: Data?
    var nextResponse: URLResponse?
    var nextError: Error?

    func dataTask(
        with request: URLRequest,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTaskProtocol {
        lastRequest = request
        let data = nextData
        let response = nextResponse
        let error = nextError
        return MockURLSessionDataTask {
            completionHandler(data, response, error)
        }
    }
}

final class NtfyNotifierTests: XCTestCase {
    var mockSession: MockURLSession!
    var notifier: NtfyNotifier!

    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
        notifier = NtfyNotifier(baseURL: "https://ntfy.sh", session: mockSession)
    }

    override func tearDown() {
        mockSession = nil
        notifier = nil
        super.tearDown()
    }

    func testSendTheftAlertConstructsCorrectRequest() {
        mockSession.nextResponse = HTTPURLResponse(
            url: URL(string: "https://ntfy.sh/test-topic")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        notifier.sendTheftAlert(topic: "test-topic")

        XCTAssertNotNil(mockSession.lastRequest)
        XCTAssertEqual(mockSession.lastRequest?.url?.absoluteString, "https://ntfy.sh/test-topic")
        XCTAssertEqual(mockSession.lastRequest?.httpMethod, "POST")
        XCTAssertEqual(mockSession.lastRequest?.value(forHTTPHeaderField: "Title"), "MacBook Theft Alert")
        XCTAssertEqual(mockSession.lastRequest?.value(forHTTPHeaderField: "Priority"), "5")
        XCTAssertEqual(mockSession.lastRequest?.value(forHTTPHeaderField: "Tags"), "rotating_light,laptop")

        let body = mockSession.lastRequest?.httpBody.flatMap { String(data: $0, encoding: .utf8) }
        XCTAssertEqual(body, "Lid closed while armed. Possible theft detected.")
    }

    func testSendTestNotificationConstructsCorrectRequest() {
        mockSession.nextResponse = HTTPURLResponse(
            url: URL(string: "https://ntfy.sh/test-topic")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        notifier.sendTestNotification(topic: "test-topic")

        XCTAssertEqual(mockSession.lastRequest?.value(forHTTPHeaderField: "Title"), "NoHand Test")
        XCTAssertEqual(mockSession.lastRequest?.value(forHTTPHeaderField: "Priority"), "3")
        XCTAssertEqual(mockSession.lastRequest?.value(forHTTPHeaderField: "Tags"), "white_check_mark")
    }

    func testSendTheftAlertSkipsEmptyTopic() {
        notifier.sendTheftAlert(topic: "")
        XCTAssertNil(mockSession.lastRequest)
    }

    func testSendTestNotificationSkipsEmptyTopic() {
        notifier.sendTestNotification(topic: "")
        XCTAssertNil(mockSession.lastRequest)
    }
}
