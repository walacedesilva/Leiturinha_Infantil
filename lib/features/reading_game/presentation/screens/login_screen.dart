import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../services/audio_manager.dart';
import '../../../../navigation/nav_shell.dart';
import '../../../../services/google_auth_service.dart';

/**
 * Tela de Login Lúdica e Premium baseada no design 'Leitura Feliz'.
 * Oferece layout responsivo de duas colunas em telas amplas e empilhamento em celulares,
 * ilustrações vetorizadas interativas desenhadas com CustomPainter,
 * micro-animações com flutter_animate e integração tátil auditiva.
 */
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isAuthenticating = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Autenticação real com o Google ───────────────────────────────────────
  void _handleGoogleSignIn() async {
    HapticFeedback.mediumImpact();
    AudioManager().playSFX(SFXType.pop);
    
    setState(() => _isAuthenticating = true);

    _showPlayfulSnackBar('Conectando de forma segura à sua Conta Google... 🤖');

    try {
      final user = await GoogleAuthService().login();
      
      if (!mounted) return;
      setState(() => _isAuthenticating = false);

      if (user != null) {
        HapticFeedback.mediumImpact();
        AudioManager().playSFX(SFXType.correct);
        _showPlayfulSnackBar('Bem-vindo ao Leitura Feliz, ${user.name}! 🌈', isSuccess: true);
        _navigateToGameShell();
      } else {
        // O login foi cancelado pelo usuário
        _showPlayfulSnackBar('Login cancelado pelos pais. 🧸');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAuthenticating = false);
      
      HapticFeedback.vibrate();
      AudioManager().playSFX(SFXType.error);
      
      debugPrint('❌ Erro durante Google Sign-In nativo: $e');
      
      // Abre o diálogo lúdico de simulação estelar do Google como fallback seguro e acessível
      _showGoogleFallbackDialog(e);
    }
  }

  // ── Diálogo Lúdico de Simulação Estelar Google ───────────────────────────
  void _showGoogleFallbackDialog(dynamic originalError) {
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
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F301F).withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🚀 Simulador Estelar Google',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2B150A),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'O login real do Google encontrou uma limitação no seu dispositivo (comum em emuladores ou Windows).\n\nPara continuar sua jornada pedagógica sem bloqueios, escolha uma das contas Google simuladas para jogar!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    color: const Color(0xFF2B150A).withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 4.0),
                    child: Text(
                      'Selecione uma conta:',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFE15827),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                
                _buildMockProfileTile(
                  ctx,
                  name: 'Pai Explorador',
                  email: 'pai.explorador@gmail.com',
                  emoji: '👨‍🚀',
                  color: const Color(0xFF4FC3F7),
                ),
                const SizedBox(height: 8),
                _buildMockProfileTile(
                  ctx,
                  name: 'Mãe Estelar',
                  email: 'mae.estelar@gmail.com',
                  emoji: '👩‍🚀',
                  color: const Color(0xFFFFF176),
                ),
                const SizedBox(height: 8),
                _buildMockProfileTile(
                  ctx,
                  name: 'Pequeno Astronauta',
                  email: 'pequeno.astronauta@gmail.com',
                  emoji: '👶',
                  color: const Color(0xFF81C784),
                ),
                const SizedBox(height: 20),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8E7D75),
                        ),
                      ),
                    ),
                  ],
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
          _showPlayfulSnackBar('Simulação Ativa! Bem-vindo, ${user.name}! 🌈', isSuccess: true);
          _navigateToGameShell();
        } catch (e) {
          if (!mounted) return;
          setState(() => _isAuthenticating = false);
          HapticFeedback.vibrate();
          AudioManager().playSFX(SFXType.error);
          _showPlayfulSnackBar('Falha ao autenticar com a conta simulada. 🧸');
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
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
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 20),
              ),
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
                      color: Color(0xFF2B150A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Color(0xFF8E7D75),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF8E7D75),
            ),
          ],
        ),
      ),
    );
  }

  // ── Simulação de Sign In Clássico ─────────────────────────────────────────
  void _handleSignIn() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.vibrate();
      AudioManager().playSFX(SFXType.error);
      return;
    }

    HapticFeedback.mediumImpact();
    AudioManager().playSFX(SFXType.correct);
    
    setState(() => _isAuthenticating = true);
    _showPlayfulSnackBar('Verificando estrelas da sua conta... ✨');

    await Future.delayed(const Duration(milliseconds: 1600));

    if (!mounted) return;
    setState(() => _isAuthenticating = false);

    _showPlayfulSnackBar('Acesso liberado! Carregando as constelações... 🚀', isSuccess: true);
    
    _navigateToGameShell();
  }

  void _navigateToGameShell() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const NavShell(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 750),
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
        backgroundColor: isSuccess ? const Color(0xFF10B981) : const Color(0xFF2B150A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isDesktop = size.width > 780;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Orbes de Fundo Coloridos Flutuantes (Ambiental)
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFE0B2).withOpacity(0.35),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .move(begin: const Offset(0, 0), end: const Offset(30, 20), duration: 8.seconds, curve: Curves.easeInOut),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 480,
              height: 480,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFCC80).withOpacity(0.35),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .move(begin: const Offset(0, 0), end: const Offset(-20, -30), duration: 10.seconds, curve: Curves.easeInOut),
          ),

          // 2. Fundo Base Gradiente Pêssego/Laranja
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFFF2EA).withOpacity(0.4),
                  const Color(0xFFFDE8DB).withOpacity(0.4),
                ],
              ),
            ),
          ),

          // 3. Central Card Layout responsivo
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 960 : 440,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.82),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F301F).withOpacity(0.06),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: _isAuthenticating
                        ? SizedBox(
                            height: 400,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE15827)),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Carregando Estrelas...',
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF2B150A).withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : isDesktop
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Esquerda: Formulário
                                  Expanded(child: _buildFormSide(context)),
                                  // Direita: Ilustração
                                  Expanded(child: _buildIllustrationSide(context, true)),
                                ],
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Topo: Ilustração fofa reduzida
                                  _buildIllustrationSide(context, false),
                                  const Divider(height: 1, thickness: 1, color: Colors.white),
                                  // Fundo: Formulário
                                  _buildFormSide(context),
                                ],
                              ),
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms).scaleXY(begin: 0.95, end: 1.0, curve: Curves.easeOutCubic),
            ),
          ),
        ],
      ),
    );
  }

  // ── Coluna 1: O Formulário de Entrada ─────────────────────────────────────
  Widget _buildFormSide(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Login',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2B150A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),
            
            // Email Input
            const Text(
              'Email',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8E7D75),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
              decoration: InputDecoration(
                hintText: 'username@gmail.com',
                hintStyle: const TextStyle(color: Color(0xFFC0B4AE)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0x152B150A), width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0x152B150A), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFF9A03F), width: 1.5),
                ),
              ),
              validator: (val) {
                if (val == null || val.isEmpty || !val.contains('@')) {
                  return 'Insira um e-mail estelar válido!';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 18),
            
            // Password Input
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Password',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8E7D75),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showPlayfulSnackBar('Recuperação de senha estelar enviada!');
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE15827),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Password',
                hintStyle: const TextStyle(color: Color(0xFFC0B4AE)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: const Color(0xFF8E7D75),
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0x152B150A), width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0x152B150A), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFF9A03F), width: 1.5),
                ),
              ),
              validator: (val) {
                if (val == null || val.length < 4) {
                  return 'Senha secreta deve ter no mínimo 4 dígitos!';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Sign In Button
            ElevatedButton(
              onPressed: _handleSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE15827),
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: const Color(0xFFE15827).withOpacity(0.3),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Sign in',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Divider "Or Continue With"
            Row(
              children: [
                Expanded(child: Divider(color: const Color(0xFF2B150A).withOpacity(0.08), thickness: 1.5)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Or Continue With',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF8E7D75),
                    ),
                  ),
                ),
                Expanded(child: Divider(color: const Color(0xFF2B150A).withOpacity(0.08), thickness: 1.5)),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Google Button
            OutlinedButton(
              onPressed: _handleGoogleSignIn,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide(color: const Color(0xFF2B150A).withOpacity(0.08), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Vector Google G Logo
                  CustomPaint(
                    size: const Size(20, 20),
                    painter: _GoogleLogoPainter(),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2B150A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Coluna 2: A Ilustração Fofa (Vetorizada via CustomPainter) ────────────
  Widget _buildIllustrationSide(BuildContext context, bool showLarge) {
    return Container(
      color: Colors.white.withOpacity(0.2),
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Círculo cinza-marrom lúdico de fundo exato da imagem
            Container(
              width: showLarge ? 320 : 200,
              height: showLarge ? 320 : 200,
              decoration: BoxDecoration(
                color: const Color(0xFFDDD5CD),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: CustomPaint(
                  painter: _GirlReadingPainter(scale: showLarge ? 1.0 : 0.65),
                ),
              ),
            ),

            // Livro Flutuante Animado Esquerdo
            Positioned(
              left: showLarge ? 28 : 20,
              top: showLarge ? 95 : 60,
              child: _buildFloatingBook(
                Icons.menu_book_rounded,
                const Color(0xFFFFF176),
                -15,
                showLarge ? 42 : 28,
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .moveY(begin: 0, end: -8, duration: 2.seconds, curve: Curves.easeInOut),
            ),

            // Livro Flutuante Animado Direito
            Positioned(
              right: showLarge ? 28 : 20,
              top: showLarge ? 90 : 56,
              child: _buildFloatingBook(
                Icons.book_rounded,
                const Color(0xFF81C784),
                18,
                showLarge ? 40 : 26,
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .moveY(begin: 0, end: -10, duration: 2.2.seconds, curve: Curves.easeInOut),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingBook(IconData icon, Color color, double rotateDegrees, double size) {
    return Transform.rotate(
      angle: rotateDegrees * math.pi / 180,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F301F).withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Icon(
          icon,
          color: const Color(0xFF2B150A),
          size: size,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTERS (Vetorização Nativa da Menina Sorridente e Logos)
// ═════════════════════════════════════════════════════════════════════════════

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w / 2;

    final paint = Paint()..style = PaintingStyle.fill;

    // G Logo paths
    // Red
    paint.color = const Color(0xFFEA4335);
    final redPath = Path()
      ..moveTo(r, r - 3)
      ..lineTo(r, 0)
      ..arcToPoint(Offset(r + r * 0.86, r - r * 0.5), radius: Radius.circular(r), clockwise: true)
      ..lineTo(r + r * 0.5, r - r * 0.1)
      ..close();
    canvas.drawPath(redPath, paint);

    // Blue
    paint.color = const Color(0xFF4285F4);
    final bluePath = Path()
      ..moveTo(r, r)
      ..lineTo(w, r)
      ..arcToPoint(Offset(r, w), radius: Radius.circular(r), clockwise: true)
      ..lineTo(r, r + r * 0.5)
      ..close();
    canvas.drawPath(bluePath, paint);

    // Yellow
    paint.color = const Color(0xFFFBBC05);
    final yellowPath = Path()
      ..moveTo(r, r)
      ..lineTo(r - r * 0.86, r + r * 0.5)
      ..arcToPoint(Offset(0, r), radius: Radius.circular(r), clockwise: true)
      ..lineTo(r - r * 0.5, r)
      ..close();
    canvas.drawPath(yellowPath, paint);

    // Green
    paint.color = const Color(0xFF34A853);
    final greenPath = Path()
      ..moveTo(r, r)
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: Radius.circular(r), clockwise: true)
      ..lineTo(r, r - r * 0.5)
      ..close();
    canvas.drawPath(greenPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GirlReadingPainter extends CustomPainter {
  final double scale;
  _GirlReadingPainter({required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    // Escala e centraliza o desenho no tamanho disponível
    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scale);

    final paint = Paint();

    // 1. Cabelo Traseiro (Castanho escuro)
    paint.color = const Color(0xFF4F301F);
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(0, 30), 85, paint);
    
    // Mechas traseiras adicionais onduladas
    canvas.drawCircle(const Offset(-65, 55), 35, paint);
    canvas.drawCircle(const Offset(65, 55), 35, paint);

    // 2. Rosto da Menina (Pele)
    paint.color = const Color(0xFFFFD1B3);
    canvas.drawCircle(const Offset(0, 10), 62, paint);

    // 3. Cabelo superior e Franja
    paint.color = const Color(0xFF361C10);
    // Franja Esquerda
    final bangsLeft = Path()
      ..moveTo(-62, -10)
      ..quadraticBezierTo(-40, -45, 0, -40)
      ..quadraticBezierTo(-25, -20, -50, 15)
      ..close();
    canvas.drawPath(bangsLeft, paint);
    // Franja Direita
    final bangsRight = Path()
      ..moveTo(62, -10)
      ..quadraticBezierTo(40, -45, 0, -40)
      ..quadraticBezierTo(25, -20, 50, 15)
      ..close();
    canvas.drawPath(bangsRight, paint);
    // Tiara superior de cabelo
    canvas.drawArc(
      Rect.fromCenter(center: const Offset(0, 10), width: 126, height: 126),
      -math.pi,
      math.pi,
      true,
      paint,
    );

    // 4. Olhos Grandes
    paint.color = const Color(0xFF2B150A);
    canvas.drawOval(Rect.fromCenter(center: const Offset(-24, 8), width: 18, height: 16), paint);
    canvas.drawOval(Rect.fromCenter(center: const Offset(24, 8), width: 18, height: 16), paint);
    
    // Brilho dos Olhos (Pupila)
    paint.color = Colors.white;
    canvas.drawCircle(const Offset(-27, 5), 4, paint);
    canvas.drawCircle(const Offset(-21, 11), 2, paint);
    canvas.drawCircle(const Offset(21, 5), 4, paint);
    canvas.drawCircle(const Offset(27, 11), 2, paint);

    // Sobrancelhas
    paint.color = const Color(0xFF2B150A);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.5;
    paint.strokeCap = StrokeCap.round;
    // Sobrancelha Esquerda
    canvas.drawArc(
      Rect.fromCenter(center: const Offset(-25, -5), width: 22, height: 10),
      -math.pi * 0.8,
      math.pi * 0.6,
      false,
      paint,
    );
    // Sobrancelha Direita
    canvas.drawArc(
      Rect.fromCenter(center: const Offset(25, -5), width: 22, height: 10),
      -math.pi * 0.8,
      math.pi * 0.6,
      false,
      paint,
    );

    // Bochechas rosadas (Blush)
    paint.color = const Color(0xFFE57373).withOpacity(0.35);
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(-40, 24), 10, paint);
    canvas.drawCircle(const Offset(40, 24), 10, paint);

    // Sorriso com dentinhos separados
    paint.color = const Color(0xFF2B150A);
    canvas.drawArc(
      Rect.fromCenter(center: const Offset(0, 32), width: 34, height: 20),
      0,
      math.pi,
      true,
      paint,
    );
    // Dentinho 1
    paint.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(-7, 32, 5, 4), paint);
    // Dentinho 2
    canvas.drawRect(Rect.fromLTWH(3, 32, 5, 4), paint);

    // 5. Óculos Mágicos de "A" e "B"
    // Lente Esquerda (Moldura Laranja)
    paint.color = const Color(0xFFE15827);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 7;
    canvas.drawCircle(const Offset(-32, 60), 32, paint);
    
    // Vidro Azul
    paint.color = const Color(0xFF4FC3F7).withOpacity(0.85);
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(-32, 60), 28, paint);
    // Letra "A"
    paint.color = Colors.white;
    final textPainterA = TextPainter(
      text: const TextSpan(
        text: 'A',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainterA.paint(canvas, Offset(-32 - textPainterA.width / 2, 60 - textPainterA.height / 2));

    // Lente Direita (Moldura Laranja)
    paint.color = const Color(0xFFE15827);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 7;
    canvas.drawCircle(const Offset(32, 60), 32, paint);
    
    // Vidro Amarelo
    paint.color = const Color(0xFFFFF176).withOpacity(0.85);
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(32, 60), 28, paint);
    // Letra "B"
    final textPainterB = TextPainter(
      text: const TextSpan(
        text: 'B',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Color(0xFF2B150A),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainterB.paint(canvas, Offset(32 - textPainterB.width / 2, 60 - textPainterB.height / 2));

    // Ponte dos Óculos
    paint.color = const Color(0xFFE15827);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 7;
    canvas.drawArc(
      Rect.fromCenter(center: const Offset(0, 50), width: 16, height: 10),
      -math.pi * 0.9,
      math.pi * 0.8,
      false,
      paint,
    );

    // Gola de Roupa de Leitura
    paint.color = const Color(0xFFE57373);
    paint.style = PaintingStyle.fill;
    final shirtPath = Path()
      ..moveTo(-25, 72)
      ..lineTo(0, 95)
      ..lineTo(25, 72)
      ..lineTo(35, 110)
      ..lineTo(-35, 110)
      ..close();
    canvas.drawPath(shirtPath, paint);
    paint.color = const Color(0xFF2B150A);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.5;
    canvas.drawPath(shirtPath, paint);

    // 6. Texto da Marca em Arco "LEITURA FELIZ"
    final arcTextPainter = TextPainter(
      text: const TextSpan(
        text: 'LEITURA FELIZ',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: Color(0xFF2B150A),
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    arcTextPainter.paint(canvas, Offset(-arcTextPainter.width / 2, -100));

    // Subtexto "APRENDENDO BRINCANDO"
    final subTextPainter = TextPainter(
      text: const TextSpan(
        text: 'APRENDENDO BRINCANDO',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 8,
          fontWeight: FontWeight.w800,
          color: Color(0xFF8E7D75),
          letterSpacing: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    subTextPainter.paint(canvas, Offset(-subTextPainter.width / 2, -80));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GirlReadingPainter oldDelegate) => oldDelegate.scale != scale;
}
