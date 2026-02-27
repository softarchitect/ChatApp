import Foundation

struct APISession {
    let token: String
    let companyId: Int
}

enum APIConfig {
    static let baseURL: URL = {
        let env = ProcessInfo.processInfo.environment["API_BASE_URL"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        let value = (env?.isEmpty == false ? env! : "https://apps.widers.net")
        return URL(string: value) ?? URL(string: "https://apps.widers.net")!
    }()
}

final class WidersAPIClient {
    private let baseURL: URL

    init(baseURL: URL = APIConfig.baseURL) {
        self.baseURL = baseURL
    }

    func login(email: String, password: String) async throws -> [String: Any] {
        try await postJSON(path: "/api/login", body: ["email": email, "password": password])
    }

    func getChatsList(session: APISession, page: Int = 1, limit: Int = 30) async throws -> [String: Any] {
        try await postJSON(
            path: "/api/wpbox/getConversations/none",
            body: sessionBody(session, extra: [
                "page": String(page),
                "limit": limit,
                "status": "all",
                "tag": "all",
                "agent": "all",
                "rating": "all",
                "tap": "all",
                "order_by": "default"
            ])
        )
    }

    func getContactsList(session: APISession) async throws -> [String: Any] {
        try await get(path: "/api/wpbox/getContacts", query: sessionBody(session))
    }

    func getTemplatesList(session: APISession) async throws -> [String: Any] {
        try await get(path: "/api/setup/templates", query: sessionBody(session))
    }

    func getTagsList(session: APISession) async throws -> [String: Any] {
        try await get(path: "/api/chats/tags/list", query: sessionBody(session))
    }

    func getRepliesList(session: APISession) async throws -> [String: Any] {
        try await get(path: "/api/chats/replies/list", query: sessionBody(session))
    }

    func getFlowsList(session: APISession) async throws -> [String: Any] {
        try await get(path: "/api/flow/list", query: sessionBody(session))
    }

    func getAgentsList(session: APISession) async throws -> [String: Any] {
        try await get(path: "/api/chats/agents/list", query: sessionBody(session))
    }

    func getContactCustomFields(session: APISession, contactId: Int) async throws -> [String: Any] {
        try await get(path: "/api/sync-contact-custom-fields", query: sessionBody(session, extra: ["contact_id": contactId]))
    }

    func syncContactCustomFields(session: APISession, contactId: Int, custom: [String: Any]) async throws -> [String: Any] {
        try await postJSON(path: "/api/sync-contact-custom-fields", body: [
            "token": session.token,
            "contact_id": contactId,
            "custom": custom
        ])
    }

    func attachTagToChat(session: APISession, contactId: Int, tagId: Int) async throws -> [String: Any] {
        try await postJSON(path: "/api/chats/tags/attach", body: sessionBody(session, extra: ["contact_id": contactId, "tag_id": tagId]))
    }

    func detachTagFromChat(session: APISession, contactId: Int, tagId: Int) async throws -> [String: Any] {
        try await postJSON(path: "/api/chats/tags/detach", body: sessionBody(session, extra: ["contact_id": contactId, "tag_id": tagId]))
    }

    func searchChats(session: APISession, keyword: String, page: Int = 1, limit: Int = 50) async throws -> [String: Any] {
        try await postJSON(path: "/api/chats/search", body: sessionBody(session, extra: ["search": keyword, "page": page, "limit": limit]))
    }

    func getChatMessages(session: APISession, contactId: Int, afterId: Int = 0) async throws -> [String: Any] {
        try await postJSON(path: "/api/wpbox/getMessages", body: sessionBody(session, extra: ["contact_id": contactId, "after_id": afterId]))
    }

    func addNote(session: APISession, contactId: Int, note: String) async throws -> [String: Any] {
        try await postJSON(path: "/api/chats/add/note", body: sessionBody(session, extra: ["contact_id": contactId, "note": note]))
    }

    func sendTemplateMessage(session: APISession, contactId: Int, templateId: Int) async throws -> [String: Any] {
        try await postJSON(path: "/api/setup/templates/sendTemplate", body: sessionBody(session, extra: ["contact_id": contactId, "template_id": templateId]))
    }

    func sendFlow(session: APISession, contactId: Int, flowId: Int) async throws -> [String: Any] {
        try await postJSON(path: "/api/flow/send", body: sessionBody(session, extra: ["contact_id": contactId, "flow_id": flowId]))
    }

    func sendMessageMedia(
        session: APISession,
        phone: String,
        text: String?,
        fileName: String?,
        fileData: Data?
    ) async throws -> [String: Any] {
        var fields: [String: String] = [
            "token": session.token,
            "company_id": String(session.companyId),
            "phone": phone
        ]
        if let text, !text.isEmpty {
            fields["message"] = text
        }
        return try await postMultipart(
            path: "/api/wpbox/sendmessage",
            fields: fields,
            fileField: "file",
            fileName: fileName,
            fileData: fileData
        )
    }

    func assignAgent(session: APISession, contactId: Int, agent: Int) async throws -> [String: Any] {
        try await postJSON(path: "/api/chats/assign/agent", body: sessionBody(session, extra: ["contact_id": contactId, "agent": agent]))
    }

    func unassignAgent(session: APISession, contactId: Int) async throws -> [String: Any] {
        try await postJSON(path: "/api/chats/unassign/agent", body: sessionBody(session, extra: ["contact_id": contactId]))
    }

    func updateMuteStatus(session: APISession, contactId: Int, status: Bool) async throws -> [String: Any] {
        try await postJSON(path: "/api/chats/update/mute/status", body: sessionBody(session, extra: ["contact_id": contactId, "status": status]))
    }

    func updateReadStatus(session: APISession, contactId: Int, status: Bool) async throws -> [String: Any] {
        try await postJSON(path: "/api/chats/update/read/status", body: sessionBody(session, extra: ["contact_id": contactId, "status": status]))
    }

    func updateOpenStatus(session: APISession, contactId: Int, status: Bool) async throws -> [String: Any] {
        try await postJSON(path: "/api/chats/update/open/status", body: sessionBody(session, extra: ["contact_id": contactId, "status": status]))
    }

    func deleteChat(session: APISession, contactId: Int) async throws -> [String: Any] {
        try await postJSON(path: "/api/chats/delete", body: sessionBody(session, extra: ["contact_id": contactId]))
    }

    func addContact(session: APISession, name: String, phone: String, email: String?) async throws -> [String: Any] {
        try await postJSON(path: "/api/chats/add/contact", body: sessionBody(session, extra: [
            "name": name,
            "phone": phone,
            "email": email ?? ""
        ]))
    }

    func searchContacts(session: APISession, query: String) async throws -> [String: Any] {
        try await postJSON(path: "/api/wpbox/search/contact", body: sessionBody(session, extra: ["query": query]))
    }

    func updateContact(session: APISession, contactId: Int, name: String, phone: String, email: String?) async throws -> [String: Any] {
        try await postJSON(path: "/api/chats/update/contact", body: sessionBody(session, extra: [
            "contact_id": contactId,
            "name": name,
            "phone": phone,
            "email": email ?? ""
        ]))
    }

    func createOrUpdateTag(session: APISession, name: String, color: String, tagId: Int?) async throws -> [String: Any] {
        var body = sessionBody(session, extra: ["name": name, "color": color])
        if let tagId { body["tag_id"] = tagId }
        return try await postJSON(path: "/api/chats/tags/new", body: body)
    }

    func createOrUpdateReply(session: APISession, name: String, text: String, replyId: Int?) async throws -> [String: Any] {
        var body = sessionBody(session, extra: ["name": name, "text": text])
        if let replyId { body["reply_id"] = replyId }
        return try await postJSON(path: "/api/chats/replies/create", body: body)
    }

    private func sessionBody(_ session: APISession, extra: [String: Any] = [:]) -> [String: Any] {
        var body: [String: Any] = ["token": session.token, "company_id": session.companyId]
        extra.forEach { body[$0.key] = $0.value }
        return body
    }

    private func get(path: String, query: [String: Any]) async throws -> [String: Any] {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path.trimmingPrefix("/")), resolvingAgainstBaseURL: false) else {
            return [:]
        }
        components.queryItems = query.map { URLQueryItem(name: $0.key, value: String(describing: $0.value)) }
        var request = URLRequest(url: components.url ?? baseURL)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return try await execute(request)
    }

    private func postJSON(path: String, body: [String: Any]) async throws -> [String: Any] {
        var request = URLRequest(url: baseURL.appendingPathComponent(path.trimmingPrefix("/")))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("utf-8", forHTTPHeaderField: "Accept-Charset")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return try await execute(request)
    }

    private func postMultipart(
        path: String,
        fields: [String: String],
        fileField: String,
        fileName: String?,
        fileData: Data?
    ) async throws -> [String: Any] {
        var request = URLRequest(url: baseURL.appendingPathComponent(path.trimmingPrefix("/")))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("utf-8", forHTTPHeaderField: "Accept-Charset")

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary); charset=UTF-8", forHTTPHeaderField: "Content-Type")
        var data = Data()

        for (key, value) in fields {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"\(key)\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: text/plain; charset=UTF-8\r\n\r\n".data(using: .utf8)!)
            data.append("\(value)\r\n".data(using: .utf8)!)
        }

        if let fileName, let fileData {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"\(fileField)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
            data.append(fileData)
            data.append("\r\n".data(using: .utf8)!)
        }

        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = data
        return try await execute(request)
    }

    private func execute(_ request: URLRequest) async throws -> [String: Any] {
        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        let parsedObject = try? JSONSerialization.jsonObject(with: data)

        if !(200...299).contains(statusCode) {
            let serverMessage = (parsedObject as? [String: Any])?["message"] as? String
            let fallback = HTTPURLResponse.localizedString(forStatusCode: statusCode)
            throw NSError(
                domain: "WidersAPIClient",
                code: statusCode,
                userInfo: [NSLocalizedDescriptionKey: serverMessage?.isEmpty == false ? serverMessage! : fallback]
            )
        }
        if let object = parsedObject as? [String: Any] {
            let statusValue = object["status"]
            let apiSuccess: Bool = {
                switch statusValue {
                case let value as Bool:
                    return value
                case let value as NSNumber:
                    return value.intValue == 1
                case let value as String:
                    let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    return normalized == "success" || normalized == "true" || normalized == "1"
                case nil:
                    return true
                default:
                    return true
                }
            }()
            if !apiSuccess {
                let message = (object["message"] as? String)
                    ?? (object["error"] as? String)
                    ?? "Request was rejected by API"
                throw NSError(
                    domain: "WidersAPIClient",
                    code: statusCode,
                    userInfo: [NSLocalizedDescriptionKey: message]
                )
            }
            var enriched = object
            enriched["status_code"] = statusCode
            return enriched
        }
        if let array = parsedObject as? [[String: Any]] {
            return ["data": array, "status_code": statusCode]
        }
        return ["status_code": statusCode]
    }
}

private extension String {
    func trimmingPrefix(_ prefix: String) -> String {
        hasPrefix(prefix) ? String(dropFirst(prefix.count)) : self
    }
}
