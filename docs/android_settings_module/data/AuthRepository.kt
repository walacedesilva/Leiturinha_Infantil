package com.leiturinha.settings.data

import android.content.Context
import android.util.Log
import androidx.credentials.ClearCredentialStateRequest
import androidx.credentials.CredentialManager
import androidx.credentials.GetCredentialRequest
import androidx.credentials.GetCredentialResponse
import androidx.credentials.exceptions.ClearCredentialException
import androidx.credentials.exceptions.GetCredentialCancellationException
import androidx.credentials.exceptions.GetCredentialException
import androidx.credentials.exceptions.NoCredentialException
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.withContext

/**
 * Modelo de dados que representa o perfil do usuário autenticado no app.
 */
data class UserProfile(
    val idToken: String,
    val displayName: String?,
    val email: String?,
    val photoUrl: String?
)

/**
 * Repositório responsável pela autenticação do usuário utilizando a moderna [Credential Manager API].
 * Abstrai o fluxo do Google Sign-In (One Tap e seletor manual de contas).
 */
class AuthRepository(
    private val context: Context,
    private val sessionManager: SessionManager
) {

    companion object {
        private const val TAG = "AuthRepository"
        
        // PLACEHOLDER: ID do Cliente Web do Console de APIs do Google.
        // Substitua pelo ID do seu projeto no ambiente de produção.
        private const val OAUTH_WEB_CLIENT_ID = "SEU_OAUTH_WEB_CLIENT_ID.apps.googleusercontent.com"
    }

    private val credentialManager = CredentialManager.create(context)

    // Estado reativo da sessão exposta para a UI
    private val _currentUser = MutableStateFlow<UserProfile?>(null)
    val currentUser: StateFlow<UserProfile?> = _currentUser.asStateFlow()

    init {
        // Inicializa o estado reativo com a sessão já armazenada no SessionManager (Auto Login)
        checkActiveSession()
    }

    /**
     * Verifica se existe uma sessão ativa salva localmente e atualiza o fluxo.
     */
    private fun checkActiveSession() {
        val idToken = sessionManager.idToken
        if (idToken != null) {
            _currentUser.value = UserProfile(
                idToken = idToken,
                displayName = sessionManager.userDisplayName,
                email = sessionManager.userEmail,
                photoUrl = sessionManager.userPhotoUrl
            )
        } else {
            _currentUser.value = null
        }
    }

    /**
     * Executa o fluxo de autenticação do Google Sign-In utilizando o Credential Manager.
     * Suporta o fluxo One Tap (com seletor automático se configurado) e o modal padrão do Google.
     *
     * @param filterByAuthorizedAccounts Se true, exibe apenas contas que já concederam acesso previamente (One Tap).
     * @return Result contendo o [UserProfile] em caso de sucesso ou a exceção correspondente.
     */
    suspend fun signInWithGoogle(filterByAuthorizedAccounts: Boolean = false): Result<UserProfile> = 
        withContext(Dispatchers.IO) {
            try {
                // 1. Configuração da opção Google ID (moderno substituto do play-services-auth)
                val googleIdOption = GetGoogleIdOption.Builder()
                    .setFilterByAuthorizedAccounts(filterByAuthorizedAccounts)
                    .setServerClientId(OAUTH_WEB_CLIENT_ID)
                    .setAutoSelectEnabled(true) // Ativa login silencioso/automático se houver apenas uma conta vinculada
                    .build()

                // 2. Monta a requisição para o gerenciador de credenciais do Android
                val request = GetCredentialRequest.Builder()
                    .addCredentialOption(googleIdOption)
                    .build()

                Log.d(TAG, "Iniciando chamada do Credential Manager. Filtro de autorizadas: $filterByAuthorizedAccounts")

                // 3. Solicita a credencial ao sistema operacional (abre o modal de autenticação nativo)
                val result: GetCredentialResponse = credentialManager.getCredential(
                    context = context,
                    request = request
                )

                // 4. Trata e valida a resposta da credencial recebida
                val credential = result.credential
                if (credential.type == GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL) {
                    val googleIdTokenCredential = GoogleIdTokenCredential.createFrom(credential.data)
                    
                    val profile = UserProfile(
                        idToken = googleIdTokenCredential.idToken,
                        displayName = googleIdTokenCredential.displayName,
                        email = googleIdTokenCredential.id, // O ID do GoogleIdTokenCredential representa o e-mail da conta
                        photoUrl = googleIdTokenCredential.profilePictureUri?.toString()
                    )

                    // 5. Salva de forma criptografada as informações locais do usuário
                    sessionManager.saveSession(
                        idToken = profile.idToken,
                        accessToken = null, // Credential Manager abstrai o access token inicial. Pode ser refrescado.
                        displayName = profile.displayName,
                        email = profile.email,
                        photoUrl = profile.photoUrl
                    )

                    // 6. Atualiza o StateFlow de sessão para atualizar a UI reativamente
                    _currentUser.value = profile
                    Log.i(TAG, "Login com o Google efetuado com sucesso para: ${profile.email}")
                    Result.success(profile)
                } else {
                    Log.e(TAG, "Tipo de credencial retornado é inesperado: ${credential.type}")
                    Result.failure(IllegalArgumentException("Tipo de credencial desconhecido ou inválido."))
                }

            } catch (e: GetCredentialCancellationException) {
                Log.w(TAG, "Fluxo de login cancelado voluntariamente pelo usuário.")
                Result.failure(e)
            } catch (e: NoCredentialException) {
                // Caso não haja credencial autorizada e filterByAuthorizedAccounts=true,
                // devemos fazer um fallback tentando sem filtro para exibir todas as contas do aparelho.
                if (filterByAuthorizedAccounts) {
                    Log.i(TAG, "Nenhuma credencial autorizada salva. Tentando login completo sem filtro de conta...")
                    signInWithGoogle(filterByAuthorizedAccounts = false)
                } else {
                    Log.e(TAG, "Nenhuma credencial do Google encontrada no dispositivo.", e)
                    Result.failure(e)
                }
            } catch (e: GetCredentialException) {
                Log.e(TAG, "Erro interno durante a obtenção da credencial: ${e.message}", e)
                Result.failure(e)
            } catch (e: Exception) {
                Log.e(TAG, "Erro inesperado durante o login do Google", e)
                Result.failure(e)
            }
        }

    /**
     * Realiza o log-out completo do usuário.
     * Limpa os tokens criptografados locais e limpa o estado de credenciais do dispositivo no Android.
     */
    suspend fun signOut(): Result<Unit> = 
        withContext(Dispatchers.IO) {
            try {
                // 1. Limpa o estado no Credential Manager do Android (impede auto sign-in involuntário imediato)
                credentialManager.clearCredentialState(ClearCredentialStateRequest())
                
                // 2. Limpa a sessão local persistida e criptografada
                sessionManager.clearSession()
                
                // 3. Atualiza o estado da aplicação
                _currentUser.value = null
                Log.i(TAG, "Sessão encerrada e tokens revogados com sucesso.")
                Result.success(Unit)
            } catch (e: ClearCredentialException) {
                Log.e(TAG, "Erro ao limpar estado de credencial no Android", e)
                // Faz o fallback mesmo assim para garantir segurança local
                sessionManager.clearSession()
                _currentUser.value = null
                Result.failure(e)
            } catch (e: Exception) {
                Log.e(TAG, "Erro genérico durante o encerramento da sessão", e)
                sessionManager.clearSession()
                _currentUser.value = null
                Result.failure(e)
            }
        }

    /**
     * Link direto para gerenciar as permissões concedidas pelo usuário ao aplicativo na Conta Google.
     * Guideline obrigatória de consentimento do Google Identity.
     */
    fun getGooglePermissionsManagementUrl(): String {
        return "https://myaccount.google.com/permissions"
    }
}
