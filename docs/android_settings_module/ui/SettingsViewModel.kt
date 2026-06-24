package com.leiturinha.settings.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.leiturinha.settings.data.AuthRepository
import com.leiturinha.settings.data.SessionManager
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * ViewModel responsável por gerenciar a lógica de negócios da tela de Configurações.
 * Comunica-se com o [AuthRepository] e [SessionManager] para atualizar a UI reativamente.
 */
class SettingsViewModel(
    private val authRepository: AuthRepository,
    private val sessionManager: SessionManager
) : ViewModel() {

    // 1. Estado reativo do fluxo de Autenticação (Loading, LoggedIn, LoggedOut, Error)
    private val _authUiState = MutableStateFlow<AuthUiState>(AuthUiState.Loading)
    val authUiState: StateFlow<AuthUiState> = _authUiState.asStateFlow()

    // 2. Estado reativo das preferências locais de configuração
    private val _preferencesUiState = MutableStateFlow(PreferencesUiState())
    val preferencesUiState: StateFlow<PreferencesUiState> = _preferencesUiState.asStateFlow()

    init {
        // Observa as mudanças no perfil do usuário no repositório
        observeUserSession()
        // Carrega as preferências do usuário salvas localmente
        loadLocalPreferences()
    }

    /**
     * Observa ativamente o fluxo de dados da sessão no repositório.
     * Atualiza o estado da UI sempre que há login/logout.
     */
    private fun observeUserSession() {
        viewModelScope.launch {
            authRepository.currentUser.collectLatest { userProfile ->
                if (userProfile != null) {
                    _authUiState.value = AuthUiState.LoggedIn(userProfile)
                } else {
                    _authUiState.value = AuthUiState.LoggedOut
                }
            }
        }
    }

    /**
     * Carrega as configurações locais mantidas de forma segura no SessionManager.
     */
    private fun loadLocalPreferences() {
        _preferencesUiState.update { currentState ->
            currentState.copy(
                isPushEnabled = sessionManager.isPushEnabled,
                isEmailEnabled = sessionManager.isEmailEnabled,
                isSoundEnabled = sessionManager.isSoundEnabled,
                isAnalyticsEnabled = sessionManager.isAnalyticsEnabled
                // Observação: Tema e Idioma podem ser integrados ao SessionManager se desejado
            )
        }
    }

    /* ==========================================
       AÇÕES DE AUTENTICAÇÃO (Google Sign-In)
       ========================================== */

    /**
     * Dispara o fluxo moderno do Google Sign-In via Credential Manager.
     */
    fun signIn() {
        viewModelScope.launch {
            _authUiState.value = AuthUiState.Loading
            
            // Tenta o One Tap primeiro (silent auto-login); caso falhe, 
            // o AuthRepository cuida de cair no seletor de contas manual automaticamente.
            val result = authRepository.signInWithGoogle(filterByAuthorizedAccounts = true)
            
            result.onFailure { exception ->
                _authUiState.value = AuthUiState.Error(
                    exception.localizedMessage ?: "Ocorreu um erro ao fazer login com o Google."
                )
            }
        }
    }

    /**
     * Dispara o encerramento seguro da sessão do usuário.
     */
    fun signOut() {
        viewModelScope.launch {
            _authUiState.value = AuthUiState.Loading
            val result = authRepository.signOut()
            
            result.onFailure { exception ->
                _authUiState.value = AuthUiState.Error(
                    exception.localizedMessage ?: "Falha ao desconectar da conta."
                )
            }
        }
    }

    /**
     * Limpa o estado de erro da UI, retornando para o estado anterior.
     */
    fun clearErrorState() {
        viewModelScope.launch {
            if (authRepository.currentUser.value != null) {
                _authUiState.value = AuthUiState.LoggedIn(authRepository.currentUser.value!!)
            } else {
                _authUiState.value = AuthUiState.LoggedOut
            }
        }
    }

    /* ==========================================
       LÓGICA DOS TOGGLES (Preferências locais)
       ========================================== */

    fun togglePushNotifications(enabled: Boolean) {
        sessionManager.isPushEnabled = enabled
        _preferencesUiState.update { it.copy(isPushEnabled = enabled) }
    }

    fun toggleEmailNotifications(enabled: Boolean) {
        sessionManager.isEmailEnabled = enabled
        _preferencesUiState.update { it.copy(isEmailEnabled = enabled) }
    }

    fun toggleSoundNotifications(enabled: Boolean) {
        sessionManager.isSoundEnabled = enabled
        _preferencesUiState.update { it.copy(isSoundEnabled = enabled) }
    }

    fun toggleAnalyticsSharing(enabled: Boolean) {
        sessionManager.isAnalyticsEnabled = enabled
        _preferencesUiState.update { it.copy(isAnalyticsEnabled = enabled) }
    }

    fun updateTheme(newTheme: AppTheme) {
        // Salva e atualiza o tema da aplicação
        _preferencesUiState.update { it.copy(theme = newTheme) }
    }

    fun updateLanguage(newLanguage: AppLanguage) {
        // Salva e atualiza o idioma da aplicação
        _preferencesUiState.update { it.copy(language = newLanguage) }
    }

    /* ==========================================
       OPÇÕES DE PRIVACIDADE LGPD / EXCLUSÃO
       ========================================== */

    /**
     * Lógica para solicitação de exclusão permanente de dados (LGPD/GDPR).
     * Em produção, isso dispararia uma requisição de API segura para o backend.
     */
    fun requestAccountDeletion(onSuccess: () -> Unit, onError: (String) -> Unit) {
        viewModelScope.launch {
            try {
                _authUiState.value = AuthUiState.Loading
                
                // Simula requisição ao servidor
                kotlinx.coroutines.delay(2000)
                
                // Em caso de sucesso, encerra a sessão localmente
                authRepository.signOut()
                onSuccess()
            } catch (e: Exception) {
                _authUiState.value = AuthUiState.Error("Falha ao processar a exclusão da conta.")
                onError(e.localizedMessage ?: "Erro de conexão.")
            }
        }
    }

    /**
     * Lógica para exportação de dados em conformidade com a LGPD.
     */
    fun requestDataExport(onSuccess: (String) -> Unit, onError: (String) -> Unit) {
        viewModelScope.launch {
            try {
                // Simula geração de arquivo compactado json/csv de dados do usuário
                kotlinx.coroutines.delay(1500)
                onSuccess("Um link seguro com seus dados foi enviado para o e-mail cadastrado.")
            } catch (e: Exception) {
                onError("Não foi possível solicitar a exportação de dados no momento.")
            }
        }
    }

    /**
     * Link para gerenciamento de permissões adicionais.
     */
    val permissionsManagementUrl: String
        get() = authRepository.getGooglePermissionsManagementUrl()
}
