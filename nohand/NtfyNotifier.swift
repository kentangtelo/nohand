import Foundation

protocol URLSessionProtocol {
    func dataTask(
        with request: URLRequest,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTaskProtocol
}

protocol URLSessionDataTaskProtocol {
    func resume()
}

extension URLSession: URLSessionProtocol {
    func dataTask(
        with request: URLRequest,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTaskProtocol {
        let task: URLSessionDataTask = dataTask(with: request, completionHandler: completionHandler)
        return task
    }
}

extension URLSessionDataTask: URLSessionDataTaskProtocol {}

class NtfyNotifier {
    static let shared = NtfyNotifier()

    let baseURL: String
    private let session: URLSessionProtocol

    init(baseURL: String = "https://ntfy.sh", session: URLSessionProtocol = URLSession.shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func sendTheftAlert(topic: String) {
        guard !topic.isEmpty else {
            print("[NtfyNotifier] Topic is empty, skipping notification")
            return
        }

        send(
            topic: topic,
            title: "MacBook Theft Alert",
            message: "Lid closed while armed. Possible theft detected.",
            priority: 5,
            tags: "rotating_light,laptop"
        )
    }

    func sendTestNotification(topic: String) {
        guard !topic.isEmpty else {
            print("[NtfyNotifier] Topic is empty, skipping test notification")
            return
        }

        send(
            topic: topic,
            title: "NoHand Test",
            message: "This is a test notification from NoHand. Your setup is working correctly.",
            priority: 3,
            tags: "white_check_mark"
        )
    }

    func send(topic: String, title: String, message: String, priority: Int, tags: String) {
        guard let url = URL(string: "\(baseURL)/\(topic)") else {
            print("[NtfyNotifier] Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(title, forHTTPHeaderField: "Title")
        request.setValue("\(priority)", forHTTPHeaderField: "Priority")
        request.setValue(tags, forHTTPHeaderField: "Tags")
        request.httpBody = message.data(using: .utf8)

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[NtfyNotifier] Request failed: \(error.localizedDescription)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("[NtfyNotifier] Sent '\(title)' — status: \(httpResponse.statusCode)")
            }
        }
        task.resume()
    }
}
