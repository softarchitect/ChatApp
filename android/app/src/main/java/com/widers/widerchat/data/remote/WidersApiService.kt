package com.widers.widerchat.data.remote

import java.io.DataOutputStream
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import org.json.JSONArray
import org.json.JSONObject

class ApiHttpException(
    val statusCode: Int,
    override val message: String
) : RuntimeException(message)

data class SessionContext(
    val token: String,
    val companyId: Long
)

class WidersApiService(
    private val baseUrl: String
) {
    fun login(email: String, password: String): JSONObject = postJson(
        "/api/login",
        JSONObject().put("email", email).put("password", password)
    )

    fun getChatsList(
        session: SessionContext,
        page: Int = 1,
        limit: Int = 30,
        status: String = "all",
        tag: String = "all",
        agent: String = "all",
        rating: String = "all",
        tap: String = "all",
        orderBy: String = "default"
    ): JSONObject = postJson(
        "/api/wpbox/getConversations/none",
        sessionPayload(session)
            .put("page", page.toString())
            .put("limit", limit)
            .put("status", status)
            .put("tag", tag)
            .put("agent", agent)
            .put("rating", rating)
            .put("tap", tap)
            .put("order_by", orderBy)
    )

    fun getContactsList(session: SessionContext): JSONObject =
        getWithQuery("/api/wpbox/getContacts", sessionPayload(session))

    fun getTemplatesList(session: SessionContext): JSONObject =
        getWithQuery("/api/setup/templates", sessionPayload(session))

    fun getTagsList(session: SessionContext): JSONObject =
        getWithQuery("/api/chats/tags/list", sessionPayload(session))

    fun getRepliesList(session: SessionContext): JSONObject =
        getWithQuery("/api/chats/replies/list", sessionPayload(session))

    fun getFlowsList(session: SessionContext): JSONObject =
        getWithQuery("/api/flow/list", sessionPayload(session))

    fun getAgentsList(session: SessionContext): JSONObject =
        getWithQuery("/api/chats/agents/list", sessionPayload(session))

    fun getContactCustomFields(session: SessionContext, contactId: Long): JSONObject {
        val path = "/api/sync-contact-custom-fields"
        // Primary style (current implementation): GET + query payload.
        try {
            return getWithQuery(path, sessionPayload(session).put("contact_id", contactId))
        } catch (_: Exception) {
            // Fallback 1: POST with full session payload.
            try {
                return postJson(path, sessionPayload(session).put("contact_id", contactId))
            } catch (_: Exception) {
                // Fallback 2: POST legacy payload shape used by some backend variants.
                return postJson(
                    path,
                    JSONObject()
                        .put("token", session.token)
                        .put("company_id", session.companyId)
                        .put("contact_id", contactId)
                )
            }
        }
    }

    fun syncContactCustomFields(session: SessionContext, contactId: Long, custom: JSONObject): JSONObject =
        postJson(
            "/api/sync-contact-custom-fields",
            JSONObject()
                .put("token", session.token)
                .put("contact_id", contactId)
                .put("custom", custom)
        )

    fun attachTagToChat(session: SessionContext, contactId: Long, tagId: Long): JSONObject =
        postJson(
            "/api/chats/tags/attach",
            sessionPayload(session).put("contact_id", contactId).put("tag_id", tagId)
        )

    fun detachTagFromChat(session: SessionContext, contactId: Long, tagId: Long): JSONObject =
        postJson(
            "/api/chats/tags/detach",
            sessionPayload(session).put("contact_id", contactId).put("tag_id", tagId)
        )

    fun searchChats(session: SessionContext, keyword: String, page: Int = 1, limit: Int = 50): JSONObject =
        postJson(
            "/api/chats/search",
            sessionPayload(session)
                .put("search", keyword)
                .put("page", page)
                .put("limit", limit)
        )

    fun getChatMessages(session: SessionContext, contactId: Long, afterId: Long = 0): JSONObject =
        postJson(
            "/api/wpbox/getMessages",
            sessionPayload(session)
                .put("contact_id", contactId)
                .put("after_id", afterId)
        )

    fun addNote(session: SessionContext, contactId: Long, note: String): JSONObject =
        postJson(
            "/api/chats/add/note",
            sessionPayload(session)
                .put("contact_id", contactId)
                .put("note", note)
        )

    fun sendTemplateMessage(session: SessionContext, contactId: Long, templateId: Long): JSONObject =
        postJson(
            "/api/setup/templates/sendTemplate",
            sessionPayload(session).put("contact_id", contactId).put("template_id", templateId)
        )

    fun sendFlow(session: SessionContext, contactId: Long, flowId: Long): JSONObject =
        postJson(
            "/api/flow/send",
            sessionPayload(session).put("contact_id", contactId).put("flow_id", flowId)
        )

    fun sendMessageMedia(
        session: SessionContext,
        phone: String,
        fileName: String?,
        fileBytes: ByteArray?,
        text: String? = null
    ): JSONObject = postMultipart(
        "/api/wpbox/sendmessage",
        fields = mapOf(
            "token" to session.token,
            "company_id" to session.companyId.toString(),
            "phone" to phone,
            "message" to text
        ),
        fileField = "file",
        fileName = fileName,
        fileBytes = fileBytes
    )

    fun assignAgent(session: SessionContext, contactId: Long, agent: Long): JSONObject =
        postJson(
            "/api/chats/assign/agent",
            sessionPayload(session).put("contact_id", contactId).put("agent", agent)
        )

    fun unassignAgent(session: SessionContext, contactId: Long): JSONObject =
        postJson(
            "/api/chats/unassign/agent",
            sessionPayload(session).put("contact_id", contactId)
        )

    fun updateMuteStatus(session: SessionContext, contactId: Long, status: Boolean): JSONObject =
        postJson(
            "/api/chats/update/mute/status",
            sessionPayload(session).put("contact_id", contactId).put("status", status)
        )

    fun updateReadStatus(session: SessionContext, contactId: Long, status: Boolean): JSONObject =
        postJson(
            "/api/chats/update/read/status",
            sessionPayload(session).put("contact_id", contactId).put("status", status)
        )

    fun updateOpenStatus(session: SessionContext, contactId: Long, status: Boolean): JSONObject =
        postJson(
            "/api/chats/update/open/status",
            sessionPayload(session).put("contact_id", contactId).put("status", status)
        )

    fun deleteChat(session: SessionContext, contactId: Long): JSONObject =
        postJson(
            "/api/chats/delete",
            sessionPayload(session).put("contact_id", contactId)
        )

    fun addContact(session: SessionContext, name: String, phone: String, email: String?): JSONObject =
        postJson(
            "/api/chats/add/contact",
            sessionPayload(session).put("name", name).put("phone", phone).put("email", email ?: "")
        )

    fun searchContacts(session: SessionContext, query: String): JSONObject =
        postJson(
            "/api/wpbox/search/contact",
            sessionPayload(session).put("query", query)
        )

    fun updateContact(session: SessionContext, contactId: Long, name: String, phone: String, email: String?): JSONObject =
        postJson(
            "/api/chats/update/contact",
            sessionPayload(session)
                .put("contact_id", contactId)
                .put("name", name)
                .put("phone", phone)
                .put("email", email ?: "")
        )

    fun createOrUpdateTag(
        session: SessionContext,
        name: String,
        color: String,
        tagId: Long?
    ): JSONObject {
        val payload = sessionPayload(session).put("name", name).put("color", color)
        if (tagId != null) payload.put("tag_id", tagId)
        return postJson("/api/chats/tags/new", payload)
    }

    fun createOrUpdateReply(
        session: SessionContext,
        name: String,
        text: String,
        replyId: Long?
    ): JSONObject {
        val payload = sessionPayload(session).put("name", name).put("text", text)
        if (replyId != null) payload.put("reply_id", replyId)
        return postJson("/api/chats/replies/create", payload)
    }

    private fun sessionPayload(session: SessionContext): JSONObject =
        JSONObject().put("token", session.token).put("company_id", session.companyId)

    private fun postJson(path: String, payload: JSONObject): JSONObject {
        val connection = openConnection(path, "POST")
        connection.setRequestProperty("Content-Type", "application/json")
        connection.doOutput = true
        connection.outputStream.use { it.write(payload.toString().toByteArray(Charsets.UTF_8)) }
        return readJson(connection)
    }

    private fun getWithQuery(path: String, query: JSONObject): JSONObject {
        val params = buildString {
            val keys = query.keys()
            var first = true
            while (keys.hasNext()) {
                val key = keys.next()
                val value = query.opt(key)?.toString() ?: continue
                if (!first) append("&") else first = false
                append(URLEncoder.encode(key, Charsets.UTF_8.name()))
                append("=")
                append(URLEncoder.encode(value, Charsets.UTF_8.name()))
            }
        }
        val targetPath = if (params.isEmpty()) path else "$path?$params"
        val connection = openConnection(targetPath, "GET")
        return readJson(connection)
    }

    private fun postMultipart(
        path: String,
        fields: Map<String, String?>,
        fileField: String,
        fileName: String?,
        fileBytes: ByteArray?
    ): JSONObject {
        val boundary = "----WidersBoundary${System.currentTimeMillis()}"
        val connection = openConnection(path, "POST")
        connection.setRequestProperty("Content-Type", "multipart/form-data; boundary=$boundary; charset=UTF-8")
        connection.setRequestProperty("Accept-Charset", "UTF-8")
        connection.doOutput = true

        DataOutputStream(connection.outputStream).use { out ->
            fields.forEach { (key, value) ->
                if (value == null) return@forEach
                out.write("--$boundary\r\n".toByteArray(Charsets.UTF_8))
                out.write("Content-Disposition: form-data; name=\"$key\"\r\n".toByteArray(Charsets.UTF_8))
                out.write("Content-Type: text/plain; charset=UTF-8\r\n\r\n".toByteArray(Charsets.UTF_8))
                out.write(value.toByteArray(Charsets.UTF_8))
                out.write("\r\n".toByteArray(Charsets.UTF_8))
            }

            if (fileBytes != null && !fileName.isNullOrBlank()) {
                out.write("--$boundary\r\n".toByteArray(Charsets.UTF_8))
                out.write("Content-Disposition: form-data; name=\"$fileField\"; filename=\"$fileName\"\r\n".toByteArray(Charsets.UTF_8))
                out.write("Content-Type: application/octet-stream\r\n\r\n".toByteArray(Charsets.UTF_8))
                out.write(fileBytes)
                out.write("\r\n".toByteArray(Charsets.UTF_8))
            }

            out.write("--$boundary--\r\n".toByteArray(Charsets.UTF_8))
            out.flush()
        }

        return readJson(connection)
    }

    private fun openConnection(path: String, method: String): HttpURLConnection {
        val normalizedBase = baseUrl.trimEnd('/')
        val normalizedPath = if (path.startsWith("/")) path else "/$path"
        val url = URL("$normalizedBase$normalizedPath")
        return (url.openConnection() as HttpURLConnection).apply {
            requestMethod = method
            connectTimeout = 20_000
            readTimeout = 20_000
            setRequestProperty("Accept", "application/json")
        }
    }

    private fun readJson(connection: HttpURLConnection): JSONObject {
        val statusCode = connection.responseCode
        val source = if (statusCode in 200..299) connection.inputStream else connection.errorStream
        val rawBody = source?.bufferedReader(Charsets.UTF_8)?.use { it.readText() }.orEmpty()
        if (rawBody.isBlank() && statusCode in 200..299) {
            return JSONObject().put("status_code", statusCode).put("ok", true)
        }

        val parsed = try {
            JSONObject(rawBody).put("status_code", statusCode)
        } catch (_: Exception) {
            try {
                JSONObject().put("data", JSONArray(rawBody)).put("status_code", statusCode)
            } catch (_: Exception) {
                JSONObject().put("raw", rawBody).put("status_code", statusCode)
            }
        }

        if (statusCode !in 200..299) {
            val message = parsed.optString("message")
                .ifBlank { parsed.optString("error") }
                .ifBlank { parsed.optString("raw") }
                .ifBlank { "HTTP $statusCode request failed" }
            throw ApiHttpException(statusCode, message)
        }

        val statusField = parsed.opt("status")
        val apiSuccess = when (statusField) {
            is Boolean -> statusField
            is Number -> statusField.toInt() == 1
            is String -> statusField.equals("success", ignoreCase = true) || statusField.equals("true", ignoreCase = true) || statusField == "1"
            null -> true
            else -> true
        }
        if (!apiSuccess) {
            val message = parsed.optString("message")
                .ifBlank { parsed.optString("error") }
                .ifBlank { parsed.optJSONObject("errors")?.toString() ?: "" }
                .ifBlank { "Request was rejected by API" }
            throw ApiHttpException(statusCode, message)
        }

        return parsed.put("ok", true)
    }
}
