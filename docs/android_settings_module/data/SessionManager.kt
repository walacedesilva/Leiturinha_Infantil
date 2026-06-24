package com.leiturinha.settings.data

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import java.io.IOException
import java.security.GeneralSecurityException

/**
 * Gerenciador de Sessão Seguro utilizando [EncryptedSharedPreferences] para
 * criptografia em nível de hardware através do Android Keystore System (AES-256-GCM).
 *
 * Esta classe é projetada para ser injetada via Hilt/Dagger ou inicializada de forma singleton.
 */
class SessionManager(private val context: Context) {

    companion object {
        private const val TAG = "SessionManager"
        private const val SECURE_PREFS_FILE = "secure_user_session_prefs"
        
        // Chaves de preferência
        private const val KEY_ID_TOKEN = "oauth_id_token"
        private const val KEY_ACCESS_TOKEN = "oauth_access_token"
        private const val KEY_USER_NAME = "user_display_name"
        private const val KEY_USER_EMAIL = "user_email"
        private const val KEY_USER_PHOTO_URL = "user_photo_url"
        private const val KEY_ANALYTICS_ENABLED = "analytics_sharing_enabled"
        private const val KEY_PUSH_ENABLED = "push_notifications_enabled"
        private const val KEY_EMAIL_ENABLED = "email_notifications_enabled"
        private const val KEY_SOUND_ENABLED = "sound_notifications_enabled"
    }

    private val sharedPreferences: SharedPreferences by lazy {
        try {
            // Criação da MasterKey associada ao Keystore para criptografia em hardware
            val masterKey = MasterKey.Builder(context)
                .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                .build()

            EncryptedSharedPreferences.create(
                context,
                SECURE_PREFS_FILE,
                masterKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
        } catch (e: Exception) {
            Log.e(TAG, "Erro fatal ao inicializar o EncryptedSharedPreferences. Resetando arquivo.", e)
            // Tratamento preventivo em caso de corrupção do Android Keystore (comum em upgrades de SO ou custom ROMs)
            deleteSharedPrefsFile()
            fallbackInitialize()
        }
    }

    /**
     * Limpa o arquivo físico de preferências em caso de erro crítico no Keystore.
     */
    private fun deleteSharedPrefsFile() {
        try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
                context.deleteSharedPreferences(SECURE_PREFS_FILE)
            } else {
                val file = context.getSharedPreferences(SECURE_PREFS_FILE, Context.MODE_PRIVATE)
                file.edit().clear().commit()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao tentar apagar fisicamente o arquivo SharedPreferences corrompido", e)
        }
    }

    /**
     * Inicialização de fallback caso a criptografia do Keystore falhe (tenta recriar o arquivo limpo).
     */
    private fun fallbackInitialize(): SharedPreferences {
        val masterKey = MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()
        return EncryptedSharedPreferences.create(
            context,
            SECURE_PREFS_FILE,
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )
    }

    /* ==========================================
       MÉTODOS DE ESCRITA / SALVAMENTO
       ========================================== */

    /**
     * Salva a sessão ativa do usuário após autenticação bem-sucedida do Google.
     */
    fun saveSession(
        idToken: String?,
        accessToken: String?,
        displayName: String?,
        email: String?,
        photoUrl: String?
    ) {
        sharedPreferences.edit().apply {
            putString(KEY_ID_TOKEN, idToken)
            putString(KEY_ACCESS_TOKEN, accessToken)
            putString(KEY_USER_NAME, displayName)
            putString(KEY_USER_EMAIL, email)
            putString(KEY_USER_PHOTO_URL, photoUrl)
            apply()
        }
        Log.d(TAG, "Sessão do usuário salva com segurança.")
    }

    /**
     * Limpa de forma segura todos os tokens de autenticação e dados do perfil local.
     */
    fun clearSession() {
        sharedPreferences.edit().apply {
            remove(KEY_ID_TOKEN)
            remove(KEY_ACCESS_TOKEN)
            remove(KEY_USER_NAME)
            remove(KEY_USER_EMAIL)
            remove(KEY_USER_PHOTO_URL)
            apply()
        }
        Log.d(TAG, "Tokens e dados de perfil removidos das SharedPreferences seguras.")
    }

    /* ==========================================
       MÉTODOS DE LEITURA / GETTERS
       ========================================== */

    val idToken: String?
        get() = sharedPreferences.getString(KEY_ID_TOKEN, null)

    val accessToken: String?
        get() = sharedPreferences.getString(KEY_ACCESS_TOKEN, null)

    val userDisplayName: String?
        get() = sharedPreferences.getString(KEY_USER_NAME, null)

    val userEmail: String?
        get() = sharedPreferences.getString(KEY_USER_EMAIL, null)

    val userPhotoUrl: String?
        get() = sharedPreferences.getString(KEY_USER_PHOTO_URL, null)

    val isUserLoggedIn: Boolean
        get() = !idToken.isNullOrEmpty()

    /* ==========================================
       CONFIGURAÇÕES DE PRIVACIDADE E NOTIFICAÇÕES (Toggles)
       ========================================== */

    var isAnalyticsEnabled: Boolean
        get() = sharedPreferences.getBoolean(KEY_ANALYTICS_ENABLED, true) // Habilitado por padrão
        set(value) = sharedPreferences.edit().putBoolean(KEY_ANALYTICS_ENABLED, value).apply()

    var isPushEnabled: Boolean
        get() = sharedPreferences.getBoolean(KEY_PUSH_ENABLED, true)
        set(value) = sharedPreferences.edit().putBoolean(KEY_PUSH_ENABLED, value).apply()

    var isEmailEnabled: Boolean
        get() = sharedPreferences.getBoolean(KEY_EMAIL_ENABLED, false) // Opt-in por padrão
        set(value) = sharedPreferences.edit().putBoolean(KEY_EMAIL_ENABLED, value).apply()

    var isSoundEnabled: Boolean
        get() = sharedPreferences.getBoolean(KEY_SOUND_ENABLED, true)
        set(value) = sharedPreferences.edit().putBoolean(KEY_SOUND_ENABLED, value).apply()
}
