package com.widers.widerchat.data.local

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey

data class StoredSession(
    val token: String,
    val companyId: Long
)

class SecureSessionStore(context: Context) {
    private val prefs: SharedPreferences = createPrefs(context)

    fun save(session: StoredSession) {
        if (session.token.isBlank() || session.companyId <= 0L) return
        prefs.edit()
            .putString(KEY_TOKEN, session.token)
            .putLong(KEY_COMPANY_ID, session.companyId)
            .apply()
    }

    fun read(): StoredSession? {
        val token = prefs.getString(KEY_TOKEN, null).orEmpty().trim()
        val companyId = prefs.getLong(KEY_COMPANY_ID, 0L)
        if (token.isBlank() || companyId <= 0L) return null
        return StoredSession(token = token, companyId = companyId)
    }

    fun clear() {
        prefs.edit().clear().apply()
    }

    private fun createPrefs(context: Context): SharedPreferences {
        return try {
            val masterKey = MasterKey.Builder(context)
                .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                .build()
            EncryptedSharedPreferences.create(
                context,
                PREFS_NAME,
                masterKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
        } catch (_: Exception) {
            // Fallback keeps app functional if secure storage setup fails.
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        }
    }

    private companion object {
        const val PREFS_NAME = "widers_secure_session"
        const val KEY_TOKEN = "token"
        const val KEY_COMPANY_ID = "company_id"
    }
}
