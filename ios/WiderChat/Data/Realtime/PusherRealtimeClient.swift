import Foundation

@MainActor
final class PusherRealtimeClient {
    private let key: String
    private let cluster: String
    private let onGeneralEvent: (String) -> Void

    private var socketTask: URLSessionWebSocketTask?
    private var listenTask: Task<Void, Never>?
    private var pingTask: Task<Void, Never>?
    private var isConnected = false
    private var currentCompanyId: Int?
    private var currentChatId: String?

    init(key: String, cluster: String, onGeneralEvent: @escaping (String) -> Void) {
        self.key = key
        self.cluster = cluster
        self.onGeneralEvent = onGeneralEvent
    }

    func connect(companyId: Int) {
        guard companyId > 0, !key.isEmpty, !cluster.isEmpty else { return }
        let reconnectRequired = currentCompanyId != companyId || socketTask == nil
        currentCompanyId = companyId
        if reconnectRequired {
            disconnect()
            openSocket()
        } else {
            subscribeAll()
        }
    }

    func setActiveChat(chatId: String?) {
        let changed = currentChatId != chatId
        currentChatId = chatId
        if isConnected, changed {
            subscribeAll()
        }
    }

    func disconnect() {
        isConnected = false
        listenTask?.cancel()
        listenTask = nil
        pingTask?.cancel()
        pingTask = nil
        socketTask?.cancel(with: .normalClosure, reason: nil)
        socketTask = nil
    }

    private func openSocket() {
        let rawUrl = "wss://ws-\(cluster).pusher.com/app/\(key)?protocol=7&client=ios&version=1.0"
        guard let url = URL(string: rawUrl) else { return }
        let session = URLSession(configuration: .default)
        let task = session.webSocketTask(with: url)
        socketTask = task
        task.resume()
        startListening()
        startPinging()
    }

    private func startListening() {
        listenTask?.cancel()
        listenTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                guard let socketTask = self.socketTask else { return }
                do {
                    let message = try await socketTask.receive()
                    switch message {
                    case let .string(text):
                        self.handleMessage(text)
                    case let .data(data):
                        if let text = String(data: data, encoding: .utf8) {
                            self.handleMessage(text)
                        }
                    @unknown default:
                        break
                    }
                } catch {
                    self.isConnected = false
                    return
                }
            }
        }
    }

    private func startPinging() {
        pingTask?.cancel()
        pingTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 25_000_000_000)
                guard let socketTask = self.socketTask else { return }
                do {
                    try await socketTask.sendPingAsync()
                } catch {
                    self.isConnected = false
                    return
                }
            }
        }
    }

    private func handleMessage(_ text: String) {
        guard
            let data = text.data(using: .utf8),
            let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        else { return }
        let event = (json["event"] as? String) ?? ""
        switch event {
        case "pusher:connection_established":
            isConnected = true
            subscribeAll()
        case "pusher:ping":
            send(event: "pusher:pong", data: [:])
        case "general":
            let channel = (json["channel"] as? String) ?? ""
            if !channel.isEmpty {
                DispatchQueue.main.async { [onGeneralEvent] in
                    onGeneralEvent(channel)
                }
            }
        default:
            break
        }
    }

    private func subscribeAll() {
        guard isConnected, let companyId = currentCompanyId else { return }
        send(
            event: "pusher:subscribe",
            data: ["channel": "chatupdate.\(companyId)"]
        )
        if let chatId = currentChatId, !chatId.isEmpty {
            send(
                event: "pusher:subscribe",
                data: ["channel": "chat.\(chatId)"]
            )
        }
    }

    private func send(event: String, data: [String: Any]) {
        guard let socketTask else { return }
        guard
            let payloadData = try? JSONSerialization.data(withJSONObject: ["event": event, "data": data]),
            let payloadText = String(data: payloadData, encoding: .utf8)
        else { return }
        Task {
            try? await socketTask.send(.string(payloadText))
        }
    }
}

private extension URLSessionWebSocketTask {
    func sendPingAsync() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.sendPing { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
