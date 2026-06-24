import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'navigation/nav_shell.dart';
import 'features/reading_game/presentation/screens/login_screen.dart';
import 'services/speech_validator.dart';

/// Tela de splash exibida na abertura do app (~2.8s) antes do menu principal.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Pré-inicializa STT para solicitar permissão de microfone antes do jogo
    SpeechValidator().initialize();
    Timer(const Duration(milliseconds: 2800), _goToMenu);
  }

  void _goToMenu() async {
    if (!mounted) return;
    
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('auth_google_user');
    
    if (!mounted) return;
    
    final Widget nextScreen = userJson != null 
        ? const NavShell() 
        : const LoginScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => nextScreen,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF5BC8F5),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Logo ─────────────────────────────────────────────────
            Image.asset(
              'assets/images/logo.png',
              width: width * 0.70,
            )
                .animate()
                .fadeIn(duration: 750.ms, curve: Curves.easeOut)
                .scale(
                  begin: const Offset(0.68, 0.68),
                  end: const Offset(1.0, 1.0),
                  duration: 750.ms,
                  curve: Curves.easeOutBack,
                ),

            const SizedBox(height: 52),

            // ── Bolinhas de carregamento ──────────────────────────────
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(
                      onPlay: (c) => c.repeat(reverse: true),
                      delay: Duration(milliseconds: 220 * i),
                    )
                    .scaleXY(
                      begin: 0.45,
                      end: 1.0,
                      duration: 520.ms,
                      curve: Curves.easeInOut,
                    )
                    .fadeIn(duration: 520.ms),
              ),
            ).animate(delay: 850.ms).fadeIn(duration: 450.ms),
          ],
        ),
      ),
    );
  }
}
