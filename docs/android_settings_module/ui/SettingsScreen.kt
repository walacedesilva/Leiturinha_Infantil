package com.leiturinha.settings.ui

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.Toast
import androidx.browser.customtabs.CustomTabsIntent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.leiturinha.settings.R
import com.leiturinha.settings.data.UserProfile

// PLACEHOLDERS CONFIGURÁVEIS
private const val PRIVACY_POLICY_URL = "https://leiturinhadevs.com.br/politica-privacidade"
private const val TERMS_OF_USE_URL = "https://leiturinhadevs.com.br/termos-uso"
private const val FAQ_URL = "https://leiturinhadevs.com.br/ajuda"
private const val SUPPORT_EMAIL = "suporte.app@leiturinha.com.br"

/**
 * Interface principal do Menu de Configurações desenvolvida em Jetpack Compose com Material Design 3.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    viewModel: SettingsViewModel,
    onNavigateBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val authState by viewModel.authUiState.collectAsState()
    val preferencesState by viewModel.preferencesUiState.collectAsState()

    // Modais e diálogos de controle local
    var showDeleteDialog by remember { mutableStateOf(false) }
    var showExportDialog by remember { mutableStateOf(false) }
    var showThemeDialog by remember { mutableStateOf(false) }
    var showLanguageDialog by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            LargeTopAppBar(
                title = { Text(text = stringResource(id = R.string.settings_title)) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.Default.ArrowBack,
                            contentDescription = "Voltar para tela anterior"
                        )
                    }
                },
                colors = TopAppBarDefaults.largeTopAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background,
                    titleContentColor = MaterialTheme.colorScheme.onBackground
                )
            )
        },
        modifier = modifier
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(MaterialTheme.colorScheme.background)
                .padding(innerPadding)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // ==========================================
                // CATEGORIA 1: Conta & Login (Google)
                // ==========================================
                SettingsCategoryHeader(title = stringResource(id = R.string.category_account))
                AccountSectionCard(
                    authState = authState,
                    onSignInClick = { viewModel.signIn() },
                    onSignOutClick = { viewModel.signOut() },
                    onManagePermissionsClick = {
                        openChromeCustomTab(context, viewModel.permissionsManagementUrl)
                    }
                )

                // ==========================================
                // CATEGORIA 2: Aparência & Idioma
                // ==========================================
                SettingsCategoryHeader(title = stringResource(id = R.string.category_appearance))
                Card(
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f)),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column {
                        SettingsClickableRow(
                            icon = Icons.Default.Palette,
                            title = stringResource(id = R.string.setting_theme),
                            subtitle = when (preferencesState.theme) {
                                AppTheme.LIGHT -> stringResource(id = R.string.theme_light)
                                AppTheme.DARK -> stringResource(id = R.string.theme_dark)
                                AppTheme.SYSTEM -> stringResource(id = R.string.theme_system)
                            },
                            onClick = { showThemeDialog = true }
                        )
                        HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
                        SettingsClickableRow(
                            icon = Icons.Default.Language,
                            title = stringResource(id = R.string.setting_language),
                            subtitle = preferencesState.language.displayName,
                            onClick = { showLanguageDialog = true }
                        )
                    }
                }

                // ==========================================
                // CATEGORIA 3: Notificações (Toggles)
                // ==========================================
                SettingsCategoryHeader(title = stringResource(id = R.string.category_notifications))
                Card(
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f)),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column {
                        SettingsToggleRow(
                            icon = Icons.Default.Notifications,
                            title = stringResource(id = R.string.setting_push_notifications),
                            subtitle = stringResource(id = R.string.setting_push_desc),
                            checked = preferencesState.isPushEnabled,
                            onCheckedChange = { viewModel.togglePushNotifications(it) },
                            accessibilityDescription = stringResource(id = R.string.acc_toggle_push)
                        )
                        HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
                        SettingsToggleRow(
                            icon = Icons.Default.Email,
                            title = stringResource(id = R.string.setting_email_notifications),
                            subtitle = stringResource(id = R.string.setting_email_desc),
                            checked = preferencesState.isEmailEnabled,
                            onCheckedChange = { viewModel.toggleEmailNotifications(it) },
                            accessibilityDescription = stringResource(id = R.string.acc_toggle_email)
                        )
                        HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
                        SettingsToggleRow(
                            icon = Icons.Default.VolumeUp,
                            title = stringResource(id = R.string.setting_sound_notifications),
                            subtitle = stringResource(id = R.string.setting_sound_desc),
                            checked = preferencesState.isSoundEnabled,
                            onCheckedChange = { viewModel.toggleSoundNotifications(it) },
                            accessibilityDescription = stringResource(id = R.string.acc_toggle_sound)
                        )
                    }
                }

                // ==========================================
                // CATEGORIA 4: Privacidade & Segurança
                // ==========================================
                SettingsCategoryHeader(title = stringResource(id = R.string.category_privacy))
                Card(
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f)),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column {
                        SettingsClickableRow(
                            icon = Icons.Default.PrivacyTip,
                            title = stringResource(id = R.string.setting_privacy_policy),
                            subtitle = stringResource(id = R.string.setting_privacy_policy_desc),
                            onClick = { openChromeCustomTab(context, PRIVACY_POLICY_URL) }
                        )
                        HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
                        SettingsToggleRow(
                            icon = Icons.Default.Analytics,
                            title = stringResource(id = R.string.setting_analytics_sharing),
                            subtitle = stringResource(id = R.string.setting_analytics_desc),
                            checked = preferencesState.isAnalyticsEnabled,
                            onCheckedChange = { viewModel.toggleAnalyticsSharing(it) },
                            accessibilityDescription = stringResource(id = R.string.acc_toggle_analytics)
                        )
                        HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
                        SettingsClickableRow(
                            icon = Icons.Default.Download,
                            title = stringResource(id = R.string.setting_export_data),
                            subtitle = stringResource(id = R.string.setting_export_data_desc),
                            onClick = { showExportDialog = true }
                        )
                        
                        // Exibe a opção de exclusão apenas se estiver logado
                        if (authState is AuthUiState.LoggedIn) {
                            HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
                            SettingsClickableRow(
                                icon = Icons.Default.DeleteForever,
                                title = stringResource(id = R.string.setting_delete_account),
                                subtitle = stringResource(id = R.string.setting_delete_account_desc),
                                titleColor = MaterialTheme.colorScheme.error,
                                onClick = { showDeleteDialog = true }
                            )
                        }
                    }
                }

                // Banner Informativo de Armazenamento Local vs Nuvem
                Card(
                    shape = RoundedCornerShape(12.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.2f)
                    ),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(
                        modifier = Modifier.padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.CloudQueue,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary
                        )
                        Text(
                            text = stringResource(id = R.string.privacy_storage_warning),
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onPrimaryContainer,
                            textAlign = TextAlign.Start
                        )
                    }
                }

                // ==========================================
                // CATEGORIA 5: Suporte & Avaliação
                // ==========================================
                SettingsCategoryHeader(title = stringResource(id = R.string.category_support))
                Card(
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f)),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column {
                        SettingsClickableRow(
                            icon = Icons.Default.HelpOutline,
                            title = stringResource(id = R.string.support_faq),
                            subtitle = stringResource(id = R.string.support_faq_desc),
                            onClick = { openChromeCustomTab(context, FAQ_URL) }
                        )
                        HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
                        SettingsClickableRow(
                            icon = Icons.Default.MailOutline,
                            title = stringResource(id = R.string.support_email),
                            subtitle = stringResource(id = R.string.support_email_desc),
                            onClick = { composeEmailIntent(context, SUPPORT_EMAIL) }
                        )
                        HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
                        SettingsClickableRow(
                            icon = Icons.Default.StarBorder,
                            title = stringResource(id = R.string.support_rate),
                            subtitle = stringResource(id = R.string.support_rate_desc),
                            onClick = { openPlayStoreReview(context) }
                        )
                    }
                }

                // ==========================================
                // CATEGORIA 6: Sobre o App (Créditos/Versão)
                // ==========================================
                SettingsCategoryHeader(title = stringResource(id = R.string.category_about))
                Card(
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f)),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column {
                        SettingsStaticRow(
                            title = stringResource(id = R.string.about_version),
                            value = getAppVersionName(context)
                        )
                        HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
                        SettingsStaticRow(
                            title = stringResource(id = R.string.about_build),
                            value = getAppBuildNumber(context)
                        )
                        HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
                        SettingsClickableRow(
                            icon = Icons.Default.ReceiptLong,
                            title = stringResource(id = R.string.about_terms),
                            onClick = { openChromeCustomTab(context, TERMS_OF_USE_URL) }
                        )
                        HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
                        SettingsClickableRow(
                            icon = Icons.Default.Copyright,
                            title = stringResource(id = R.string.about_licenses),
                            onClick = { 
                                // Simula navegação para a tela integrada do Google de open source
                                Toast.makeText(context, "Abrindo licenças...", Toast.LENGTH_SHORT).show()
                            }
                        )
                    }
                }

                Spacer(modifier = Modifier.height(32.dp))
            }

            // Exibe Loader em cima de toda a tela caso esteja autenticando/processando
            AnimatedVisibility(
                visible = authState is AuthUiState.Loading,
                enter = fadeIn(),
                exit = fadeOut()
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(Color.Black.copy(alpha = 0.4f))
                        .clickable(enabled = false) {}, // Bloqueia toques indesejados
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(
                        color = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.semantics {
                            contentDescription = context.getString(R.string.acc_loading_auth)
                        }
                    )
                }
            }
        }
    }

    /* ==========================================
       MODAIS E DIÁLOGOS DE CONFIRMAÇÃO (LGPD & Temas)
       ========================================== */

    // 1. DIÁLOGO DO TEMA
    if (showThemeDialog) {
        AlertDialog(
            onDismissRequest = { showThemeDialog = false },
            title = { Text(text = stringResource(id = R.string.setting_theme)) },
            text = {
                Column {
                    AppTheme.values().forEach { themeOption ->
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    viewModel.updateTheme(themeOption)
                                    showThemeDialog = false
                                }
                                .padding(vertical = 12.dp)
                        ) {
                            RadioButton(
                                selected = (preferencesState.theme == themeOption),
                                onClick = {
                                    viewModel.updateTheme(themeOption)
                                    showThemeDialog = false
                                }
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = when (themeOption) {
                                    AppTheme.LIGHT -> stringResource(id = R.string.theme_light)
                                    AppTheme.DARK -> stringResource(id = R.string.theme_dark)
                                    AppTheme.SYSTEM -> stringResource(id = R.string.theme_system)
                                }
                            )
                        }
                    }
                }
            },
            confirmButton = {}
        )
    }

    // 2. DIÁLOGO DO IDIOMA
    if (showLanguageDialog) {
        AlertDialog(
            onDismissRequest = { showLanguageDialog = false },
            title = { Text(text = stringResource(id = R.string.setting_language)) },
            text = {
                Column {
                    AppLanguage.values().forEach { langOption ->
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    viewModel.updateLanguage(langOption)
                                    showLanguageDialog = false
                                }
                                .padding(vertical = 12.dp)
                        ) {
                            RadioButton(
                                selected = (preferencesState.language == langOption),
                                onClick = {
                                    viewModel.updateLanguage(langOption)
                                    showLanguageDialog = false
                                }
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(text = langOption.displayName)
                        }
                    }
                }
            },
            confirmButton = {}
        )
    }

    // 3. DIÁLOGO DE CONFIRMAÇÃO EXCLUSÃO LGPD
    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            icon = { Icon(Icons.Default.Warning, contentDescription = null, tint = MaterialTheme.colorScheme.error) },
            title = { Text(text = "Excluir Conta Permanentemente?", fontWeight = FontWeight.Bold) },
            text = {
                Text(
                    text = "Aviso: Esta ação apagará definitivamente todo o progresso de leitura da criança e seus dados de login. Esta ação não poderá ser desfeita.",
                    textAlign = TextAlign.Center
                )
            },
            confirmButton = {
                Button(
                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error),
                    onClick = {
                        showDeleteDialog = false
                        viewModel.requestAccountDeletion(
                            onSuccess = { Toast.makeText(context, "Conta deletada com sucesso.", Toast.LENGTH_LONG).show() },
                            onError = { err -> Toast.makeText(context, "Erro: $err", Toast.LENGTH_SHORT).show() }
                        )
                    }
                ) {
                    Text(text = "Excluir")
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDialog = false }) {
                    Text(text = "Cancelar")
                }
            }
        )
    }

    // 4. DIÁLOGO EXPORTAÇÃO DE DADOS (LGPD)
    if (showExportDialog) {
        AlertDialog(
            onDismissRequest = { showExportDialog = false },
            title = { Text(text = "Solicitar Cópia de Dados") },
            text = {
                Text(
                    text = "Gostaria de solicitar um relatório contendo todos os dados coletados de seu uso? O arquivo compactado será processado e disponibilizado para download em seu e-mail cadastrado.",
                    textAlign = TextAlign.Center
                )
            },
            confirmButton = {
                Button(
                    onClick = {
                        showExportDialog = false
                        viewModel.requestDataExport(
                            onSuccess = { msg -> Toast.makeText(context, msg, Toast.LENGTH_LONG).show() },
                            onError = { err -> Toast.makeText(context, err, Toast.LENGTH_SHORT).show() }
                        )
                    }
                ) {
                    Text(text = "Solicitar")
                }
            },
            dismissButton = {
                TextButton(onClick = { showExportDialog = false }) {
                    Text(text = "Fechar")
                }
            }
        )
    }

    // Gerenciador de Erro Snackbar temporário
    LaunchedEffect(authState) {
        if (authState is AuthUiState.Error) {
            val errorMsg = (authState as AuthUiState.Error).errorMessage
            Toast.makeText(context, errorMsg, Toast.LENGTH_LONG).show()
            viewModel.clearErrorState()
        }
    }
}

/* ==========================================
   COMPONENTES GRÁFICOS INTERNOS (Sub-views)
   ========================================== */

@Composable
fun SettingsCategoryHeader(title: String) {
    Text(
        text = title,
        style = MaterialTheme.typography.titleSmall,
        fontWeight = FontWeight.SemiBold,
        color = MaterialTheme.colorScheme.primary,
        modifier = Modifier.padding(start = 8.dp, bottom = 4.dp, top = 8.dp)
    )
}

/**
 * Card de Seção de Conta Integrado e Reativo.
 */
@Composable
fun AccountSectionCard(
    authState: AuthUiState,
    onSignInClick: () -> Unit,
    onSignOutClick: () -> Unit,
    onManagePermissionsClick: () -> Unit
) {
    Card(
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f)
        ),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            when (authState) {
                is AuthUiState.LoggedIn -> {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        // Foto arredondada do perfil obtido do Google
                        AsyncImage(
                            model = authState.user.photoUrl,
                            contentDescription = stringResource(id = R.string.acc_user_avatar),
                            error = painterResource(id = android.R.drawable.sym_def_app_icon),
                            fallback = painterResource(id = android.R.drawable.sym_def_app_icon),
                            modifier = Modifier
                                .size(64.dp)
                                .clip(CircleShape)
                                .background(MaterialTheme.colorScheme.primaryContainer),
                            contentScale = ContentScale.Crop
                        )

                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = authState.user.displayName ?: "Usuário Google",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                            Text(
                                text = authState.user.email ?: "",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }

                    HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))

                    TextButton(
                        onClick = onManagePermissionsClick,
                        modifier = Modifier.fillMaxWidth(),
                        colors = ButtonDefaults.textButtonColors(contentColor = MaterialTheme.colorScheme.primary)
                    ) {
                        Icon(Icons.Default.SettingsAccessibility, contentDescription = null)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(text = stringResource(id = R.string.manage_google_permissions))
                    }

                    Button(
                        onClick = onSignOutClick,
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(10.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.errorContainer, contentColor = MaterialTheme.colorScheme.onErrorContainer)
                    ) {
                        Icon(Icons.Default.ExitToApp, contentDescription = null)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(text = stringResource(id = R.string.btn_sign_out))
                    }
                }
                else -> {
                    // Estado Deslogado ou de erro (exibe o botão Google Sign-In)
                    Column(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Text(
                            text = stringResource(id = R.string.account_not_logged),
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )

                        // Botão Premium "Entrar com o Google" alinhado aos guidelines oficiais de Branding
                        Card(
                            onClick = onSignInClick,
                            shape = RoundedCornerShape(10.dp),
                            elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
                            colors = CardDefaults.cardColors(containerColor = Color.White),
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(48.dp)
                                .semantics {
                                    contentDescription = "Entrar com a sua conta do Google"
                                }
                        ) {
                            Row(
                                modifier = Modifier.fillMaxSize(),
                                horizontalArrangement = Arrangement.Center,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                // Substitua pelo ícone oficial do Google (G Logo) no arquivo de recursos real.
                                Icon(
                                    imageVector = Icons.Default.AccountCircle,
                                    contentDescription = null,
                                    tint = Color.DarkGray,
                                    modifier = Modifier.size(24.dp)
                                )
                                Spacer(modifier = Modifier.width(12.dp))
                                Text(
                                    text = stringResource(id = R.string.btn_sign_in_google),
                                    style = MaterialTheme.typography.titleSmall,
                                    color = Color.Black,
                                    fontWeight = FontWeight.Medium
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

/**
 * Linha clicável padrão para o menu de configurações (Custom List Item).
 */
@Composable
fun SettingsClickableRow(
    icon: ImageVector,
    title: String,
    subtitle: String? = null,
    titleColor: Color = MaterialTheme.colorScheme.onSurface,
    onClick: () -> Unit
) {
    val context = LocalContext.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .minimumInteractiveComponentSize() // Garante alvo de toque mínimo de 48dp
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 16.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = if (titleColor == MaterialTheme.colorScheme.error) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurfaceVariant
        )
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyLarge,
                color = titleColor,
                fontWeight = FontWeight.Medium
            )
            if (subtitle != null) {
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
        Icon(
            imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
            contentDescription = stringResource(id = R.string.acc_external_link),
            tint = MaterialTheme.colorScheme.outline
        )
    }
}

/**
 * Linha com interruptor Toggle reativo.
 */
@Composable
fun SettingsToggleRow(
    icon: ImageVector,
    title: String,
    subtitle: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    accessibilityDescription: String
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .minimumInteractiveComponentSize()
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.Medium,
                color = MaterialTheme.colorScheme.onSurface
            )
            Text(
                text = subtitle,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange,
            modifier = Modifier.semantics {
                contentDescription = accessibilityDescription
            }
        )
    }
}

/**
 * Linha estática informativa.
 */
@Composable
fun SettingsStaticRow(
    title: String,
    value: String
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 16.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurface,
            fontWeight = FontWeight.Medium
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            fontWeight = FontWeight.Normal
        )
    }
}

/* ==========================================
   MÉTODOS INTERNOS / UTILS (CustomTabs, Intents e Versões)
   ========================================== */

/**
 * Abre uma URL utilizando Chrome Custom Tabs para transições mais elegantes e navegação embutida.
 */
fun openChromeCustomTab(context: Context, url: String) {
    try {
        val customTabsIntent = CustomTabsIntent.Builder()
            .setShowTitle(true)
            .setInstantAppsEnabled(true)
            .build()
        customTabsIntent.launchUrl(context, Uri.parse(url))
    } catch (e: Exception) {
        // Fallback caso navegador nativo falhe
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
        context.startActivity(intent)
    }
}

/**
 * Dispara envio de e-mail limitando a aplicativos clientes de e-mail (mailto URI scheme).
 */
fun composeEmailIntent(context: Context, recipient: String) {
    val intent = Intent(Intent.ACTION_SENDTO).apply {
        data = Uri.parse("mailto:") // Restringe a apps de e-mail nativos
        putExtra(Intent.EXTRA_EMAIL, arrayOf(recipient))
        putExtra(Intent.EXTRA_SUBJECT, "Suporte - Aplicativo Leiturinha")
    }
    try {
        context.startActivity(Intent.createChooser(intent, "Enviar feedback por:"))
    } catch (e: Exception) {
        Toast.makeText(context, "Nenhum aplicativo de e-mail encontrado.", Toast.LENGTH_SHORT).show()
    }
}

/**
 * Abre a página do app na Play Store para avaliação (com fallback para navegador web).
 */
fun openPlayStoreReview(context: Context) {
    val packageName = context.packageName
    val playStoreUri = Uri.parse("market://details?id=$packageName")
    val webStoreUri = Uri.parse("https://play.google.com/store/apps/details?id=$packageName")
    
    val intent = Intent(Intent.ACTION_VIEW, playStoreUri)
    try {
        context.startActivity(intent)
    } catch (e: Exception) {
        // Fallback para navegador web caso o aparelho não tenha Google Play (Ex: Huawei sem GMS)
        context.startActivity(Intent(Intent.ACTION_VIEW, webStoreUri))
    }
}

// Helpers de Info do Sistema
fun getAppVersionName(context: Context): String {
    return try {
        val pInfo = context.packageManager.getPackageInfo(context.packageName, 0)
        pInfo.versionName ?: "1.0.0"
    } catch (e: Exception) {
        "1.0.0"
    }
}

fun getAppBuildNumber(context: Context): String {
    return try {
        val pInfo = context.packageManager.getPackageInfo(context.packageName, 0)
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
            pInfo.longVersionCode.toString()
        } else {
            pInfo.versionCode.toString()
        }
    } catch (e: Exception) {
        "1"
    }
}
