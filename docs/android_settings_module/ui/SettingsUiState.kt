package com.leiturinha.settings.ui

import com.leiturinha.settings.data.UserProfile

/**
 * Representa os estados possíveis de autenticação na UI (Clean State Machine).
 */
sealed interface AuthUiState {
    
    /**
     * Fluxo de autenticação ou inicialização em progresso (exibe loader).
     */
    object Loading : AuthUiState

    /**
     * Usuário devidamente autenticado com o perfil Google associado.
     * @property user Dados do perfil obtidos do Credential Manager.
     */
    data class LoggedIn(val user: UserProfile) : AuthUiState

    /**
     * Usuário desconectado (sessão anônima).
     */
    object LoggedOut : AuthUiState

    /**
     * Erro ocorrido durante login ou logout.
     * @property errorMessage Mensagem de erro amigável.
     */
    data class Error(val errorMessage: String) : AuthUiState
}

/**
 * Enum que representa as opções de Tema do Aplicativo.
 */
enum class AppTheme {
    LIGHT,
    DARK,
    SYSTEM
}

/**
 * Enum que representa a seleção de idiomas disponíveis no App.
 */
enum class AppLanguage(val code: String, val displayName: String) {
    PORTUGUESE("pt", "Português"),
    ENGLISH("en", "English"),
    SPANISH("es", "Español")
}

/**
 * Estado completo de preferências da tela de configurações.
 * Mantém todos os toggles e seletores locais de forma reativa.
 */
data class PreferencesUiState(
    val theme: AppTheme = AppTheme.SYSTEM,
    val language: AppLanguage = AppLanguage.PORTUGUESE,
    val isPushEnabled: Boolean = true,
    val isEmailEnabled: Boolean = false,
    val isSoundEnabled: Boolean = true,
    val isAnalyticsEnabled: Boolean = true
)
