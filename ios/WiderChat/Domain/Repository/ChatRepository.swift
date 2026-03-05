import Foundation

protocol ChatRepository {
    func login(email: String, password: String) async -> Bool
    func getConversations() async -> [Conversation]
    func getMessages(conversationId: String) async -> [ChatMessage]
    func sendMessage(conversationId: String, text: String) async -> Bool
    func sendMedia(conversationId: String, fileName: String, fileData: Data, text: String?) async -> Bool
    func addNote(conversationId: String, note: String) async -> Bool
    func updateConversationStatus(conversationId: String, open: Bool) async -> Bool

    func getContactsList() async -> [String: Any]?
    func getTemplatesList() async -> [String: Any]?
    func getTagsList() async -> [String: Any]?
    func getRepliesList() async -> [String: Any]?
    func getFlowsList() async -> [String: Any]?
    func getAgentsList() async -> [String: Any]?
    func getContactCustomFields(contactId: Int) async -> [String: Any]?
    func syncContactCustomFields(contactId: Int, custom: [String: Any]) async -> [String: Any]?
    func attachTag(contactId: Int, tagId: Int) async -> [String: Any]?
    func detachTag(contactId: Int, tagId: Int) async -> [String: Any]?
    func searchChats(keyword: String, page: Int, limit: Int) async -> [String: Any]?
    func sendTemplateMessage(contactId: Int, templateId: Int) async -> [String: Any]?
    func sendFlow(contactId: Int, flowId: Int) async -> [String: Any]?
    func assignAgent(contactId: Int, agent: Int) async -> [String: Any]?
    func unassignAgent(contactId: Int) async -> [String: Any]?
    func updateMute(contactId: Int, status: Bool) async -> [String: Any]?
    func updateRead(contactId: Int, status: Bool) async -> [String: Any]?
    func deleteChat(contactId: Int) async -> [String: Any]?
    func addContact(name: String, phone: String, email: String?) async -> [String: Any]?
    func searchContacts(query: String) async -> [String: Any]?
    func updateContact(contactId: Int, name: String, phone: String, email: String?) async -> [String: Any]?
    func createOrUpdateTag(name: String, color: String, tagId: Int?) async -> [String: Any]?
    func createOrUpdateReply(name: String, text: String, replyId: Int?) async -> [String: Any]?
    func registerPushToken(token: String, platform: String) async -> Bool

    func currentSessionSnapshot() -> APISession?
    func currentUserSnapshot() -> (name: String?, email: String?)
    func restoreSession(token: String, companyId: Int)
    func clearSession()
}
