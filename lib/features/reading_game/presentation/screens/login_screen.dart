import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/app_colors.dart';
import '../../../../services/audio_manager.dart';
import '../../../../services/google_auth_service.dart';
import '../../../../navigation/nav_shell.dart';
import '../widgets/leo_bear.dart';
import 'onboarding_screen.dart';

/// Tela de Login — porta de entrada do app (após a Splash).
///
/// Novo design (handoff "Fluxo de Entrada"): fundo em gradiente roxo, logo,
/// tagline, mascote Léo e um bloco de botões ancorado embaixo:
///  • "Começar a aventura" → [OnboardingScreen]
///  • "Já tenho uma conta"  → mapa ([NavShell])
///  • "Para os pais · Entrar com Google" → fluxo Google existente
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    // Trilha do menu (loop). Silenciosa até existir assets/audio/music/menu.mp3.
    AudioManager().playMusic('menu');
  }

  // ═══════════════════════════════════════════════════════════════════════
  // NAVEGAÇÃO
  // ═══════════════════════════════════════════════════════════════════════

  void _goToOnboarding() {
    HapticFeedback.mediumImpact();
    AudioManager().playSFX(SFXType.pop);
    Navigator.of(context).push(AppPageRoute(page: const OnboardingScreen()));
  }

  void _navigateToGameShell() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const NavShell(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AUTENTICAÇÃO GOOGLE (para os pais)
  // ═══════════════════════════════════════════════════════════════════════

  void _handleGoogleSignIn() async {
    HapticFeedback.mediumImpact();
    AudioManager().playSFX(SFXType.pop);

    setState(() => _isAuthenticating = true);
    _showPlayfulSnackBar('Conectando de forma segura à Conta Google... 🤖');

    try {
      final user = await GoogleAuthService().login();

      if (!mounted) return;
      setState(() => _isAuthenticating = false);

      if (user != null) {
        HapticFeedback.mediumImpact();
        AudioManager().playSFX(SFXType.correct);
        _showPlayfulSnackBar('Bem-vindo, ${user.name}! 🌈', isSuccess: true);
        _navigateToGameShell();
      } else {
        _showPlayfulSnackBar('Login cancelado pelos pais. 🧸');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAuthenticating = false);
      HapticFeedback.vibrate();
      AudioManager().playSFX(SFXType.error);
      debugPrint('❌ Erro durante Google Sign-In: $e');
      _showGoogleFallbackDialog();
    }
  }

  // ── Diálogo de fallback com contas simuladas ─────────────────────────────
  void _showGoogleFallbackDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x265B21B6),
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🚀 Entrar com Google',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'O login real do Google encontrou uma limitação neste dispositivo (comum em emuladores ou Windows).\n\nPara continuar a aventura, escolha uma das contas de demonstração:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    color: AppColors.gray600.withOpacity(0.9),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Selecione uma conta:',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildMockProfileTile(
                  ctx,
                  name: 'Pai Explorador',
                  email: 'pai.explorador@gmail.com',
                  emoji: '👨‍🚀',
                  color: AppColors.blue400,
                ),
                const SizedBox(height: 8),
                _buildMockProfileTile(
                  ctx,
                  name: 'Mãe Estelar',
                  email: 'mae.estelar@gmail.com',
                  emoji: '👩‍🚀',
                  color: AppColors.yellow400,
                ),
                const SizedBox(height: 8),
                _buildMockProfileTile(
                  ctx,
                  name: 'Pequeno Astronauta',
                  email: 'pequeno.astronauta@gmail.com',
                  emoji: '👶',
                  color: AppColors.green400,
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMockProfileTile(
    BuildContext dialogCtx, {
    required String name,
    required String email,
    required String emoji,
    required Color color,
  }) {
    return InkWell(
      onTap: () async {
        Navigator.pop(dialogCtx);
        setState(() => _isAuthenticating = true);

        final mockUser = GoogleUserModel(
          id: 'google_mock_${email.hashCode}',
          name: name,
          email: email,
          photoUrl: null,
          idToken: 'jwt_mock_token_${DateTime.now().millisecondsSinceEpoch}',
        );

        try {
          final user = await GoogleAuthService().loginWithMock(mockUser);
          if (!mounted) return;
          setState(() => _isAuthenticating = false);
          HapticFeedback.mediumImpact();
          AudioManager().playSFX(SFXType.correct);
          _showPlayfulSnackBar('Bem-vindo, ${user.name}! 🌈', isSuccess: true);
          _navigateToGameShell();
        } catch (e) {
          if (!mounted) return;
          setState(() => _isAuthenticating = false);
          HapticFeedback.vibrate();
          AudioManager().playSFX(SFXType.error);
          _showPlayfulSnackBar('Falha ao autenticar com a conta. 🧸');
        }
      },
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: AppColors.gray800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }

  void _showPlayfulSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(isSuccess ? '🌟' : '🔮', style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isSuccess ? AppColors.green600 : AppColors.primary800,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // UI
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppAccessibility.prefersReducedMotion(context);

    return Scaffold(
      body: Container(
        // Fundo — gradiente vertical roxo
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary500,
              AppColors.primary400,
              AppColors.primary300,
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // ── Formas decorativas ──────────────────────────────────────
            Positioned(
              top: -40,
              left: -40,
              child: _decoCircle(128, 0.12),
            ),
            Positioned(
              bottom: -50,
              right: -50,
              child: _decoCircle(170, 0.10),
            ),
            Positioned(
              top: 120,
              right: 36,
              child: _star(22, AppColors.yellow300, reduceMotion, 0),
            ),
            Positioned(
              bottom: 180,
              left: 30,
              child: _star(16, AppColors.yellow200, reduceMotion, 600),
            ),

            // ── Conteúdo ────────────────────────────────────────────────
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(30, 0, 30, 46),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 56),
                              _buildLogo(reduceMotion),
                              const SizedBox(height: 6),
                              _buildTagline(),
                              const SizedBox(height: 38),
                              _buildMascot(reduceMotion),
                              const Spacer(),
                              const SizedBox(height: 38),
                              _buildButtons(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Overlay de carregamento ─────────────────────────────────
            if (_isAuthenticating)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.25),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Logo: pill de ícone + "Leiturinha" ─────────────────────────────────
  Widget _buildLogo(bool reduceMotion) {
    final logo = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.45)),
          ),
          child: const Icon(Icons.menu_book_rounded,
              color: Colors.white, size: 26),
        ),
        const SizedBox(width: 12),
        const Text(
          'Leiturinha',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
    if (reduceMotion) return logo;
    return logo.animate().fadeIn(duration: 500.ms).slideY(
        begin: -0.2, end: 0, duration: 500.ms, curve: Curves.easeOut);
  }

  Widget _buildTagline() {
    return const Text(
      'Aprender a ler é uma aventura',
      style: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.primary100,
      ),
    );
  }

  // ── Mascote Léo dentro de um círculo translúcido ───────────────────────
  Widget _buildMascot(bool reduceMotion) {
    final mascot = Container(
      width: 156,
      height: 156,
      alignment: Alignment.bottomCenter,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 5),
      ),
      child: ClipOval(
        child: SizedBox(
          width: 156,
          height: 156,
          child: Align(
            alignment: const Alignment(0, 0.35),
            child: const LeoBear(size: 116),
          ),
        ),
      ),
    );
    if (reduceMotion) return mascot;
    return mascot
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -7, duration: 2800.ms, curve: Curves.easeInOut);
  }

  // ── Bloco de botões ────────────────────────────────────────────────────
  Widget _buildButtons() {
    return Column(
      children: [
        // Primário — "Começar a aventura"
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isAuthenticating ? null : _goToOnboarding,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary600,
              elevation: 8,
              padding: const EdgeInsets.symmetric(vertical: 17),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              shadowColor: const Color(0x664C1D95),
            ),
            child: const Text(
              'Começar a aventura',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primary600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Secundário — "Já tenho uma conta"
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isAuthenticating ? null : _navigateToGameShell,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.12),
              padding: const EdgeInsets.symmetric(vertical: 15),
              side: BorderSide(
                  color: Colors.white.withOpacity(0.6), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text(
              'Já tenho uma conta',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Auxiliar — Google (pais)
        TextButton(
          onPressed: _isAuthenticating ? null : _handleGoogleSignIn,
          child: const Text(
            'Para os pais · Entrar com Google',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary100,
            ),
          ),
        ),
        // Acesso de DEMONSTRAÇÃO (revisão da loja / testes, sem Google).
        TextButton(
          onPressed: _isAuthenticating ? null : _enterAsDemo,
          child: Text(
            'Acesso de demonstração',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ),
      ],
    );
  }

  /// Entra com uma conta DEMO fixa (sem Google), para revisão da Google Play
  /// e testes. As "credenciais" para o campo Acesso ao app são apenas tocar
  /// neste botão — não exige senha.
  Future<void> _enterAsDemo() async {
    setState(() => _isAuthenticating = true);
    final demo = GoogleUserModel(
      id: 'demo_revisor',
      name: 'Visitante',
      email: 'revisor@leiturinha.app',
      photoUrl: null,
      idToken: 'demo',
    );
    try {
      await GoogleAuthService().loginWithMock(demo);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _isAuthenticating = false);
    AudioManager().playSFX(SFXType.correct);
    _navigateToGameShell();
  }

  // ── Helpers decorativos ────────────────────────────────────────────────
  Widget _decoCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }

  Widget _star(double size, Color color, bool reduceMotion, int delayMs) {
    final star = Icon(Icons.star_rounded, color: color, size: size);
    if (reduceMotion) return star;
    return star
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(duration: 1800.ms, delay: Duration(milliseconds: delayMs))
        .scaleXY(begin: 0.7, end: 1.0, duration: 1800.ms);
  }
}
