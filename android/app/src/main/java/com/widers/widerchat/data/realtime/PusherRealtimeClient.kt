package com.widers.widerchat.data.realtime

import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import org.json.JSONObject
import java.util.concurrent.TimeUnit

class PusherRealtimeClient(
    private val key: String,
    private val cluster: String,
    private val onGeneralEvent: (channel: String) -> Unit
) {
    private val httpClient = OkHttpClient.Builder()
        .pingInterval(25, TimeUnit.SECONDS)
        .build()

    private var webSocket: WebSocket? = null
    private var connected = false
    private var currentCompanyId: Long? = null
    private var currentChatId: String? = null

    fun connect(companyId: Long) {
        if (companyId <= 0L || key.isBlank() || cluster.isBlank()) return
        val reconnectRequired = currentCompanyId != companyId || webSocket == null
        currentCompanyId = companyId
        if (!reconnectRequired) {
            subscribeAll()
            return
        }
        disconnect()
        val wsUrl = "wss://ws-$cluster.pusher.com/app/$key?protocol=7&client=android&version=1.0"
        val request = Request.Builder().url(wsUrl).build()
        webSocket = httpClient.newWebSocket(request, socketListener)
    }

    fun setActiveChat(chatId: String?) {
        val changed = currentChatId != chatId
        currentChatId = chatId
        if (connected && changed) {
            subscribeAll()
        }
    }

    fun disconnect() {
        connected = false
        webSocket?.close(1000, "normal")
        webSocket = null
    }

    private fun subscribeAll() {
        val socket = webSocket ?: return
        val companyChannel = currentCompanyId?.let { "chatupdate.$it" } ?: return
        socket.send(
            JSONObject()
                .put("event", "pusher:subscribe")
                .put("data", JSONObject().put("channel", companyChannel))
                .toString()
        )
        val chatChannel = currentChatId?.takeIf { it.isNotBlank() }?.let { "chat.$it" }
        if (chatChannel != null) {
            socket.send(
                JSONObject()
                    .put("event", "pusher:subscribe")
                    .put("data", JSONObject().put("channel", chatChannel))
                    .toString()
            )
        }
    }

    private val socketListener = object : WebSocketListener() {
        override fun onOpen(webSocket: WebSocket, response: Response) {
            connected = true
            subscribeAll()
        }

        override fun onMessage(webSocket: WebSocket, text: String) {
            val payload = runCatching { JSONObject(text) }.getOrNull() ?: return
            val event = payload.optString("event")
            when (event) {
                "pusher:connection_established" -> {
                    connected = true
                    subscribeAll()
                }

                "pusher:ping" -> {
                    webSocket.send(JSONObject().put("event", "pusher:pong").put("data", JSONObject()).toString())
                }

                "general" -> {
                    val channel = payload.optString("channel")
                    if (channel.isNotBlank()) onGeneralEvent(channel)
                }
            }
        }

        override fun onClosing(webSocket: WebSocket, code: Int, reason: String) {
            connected = false
        }

        override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
            connected = false
        }

        override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
            connected = false
        }
    }
}
