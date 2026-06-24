import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/app_colors.dart';
import '../../../../services/audio_manager.dart';
import '../../../../navigation/nav_shell.dart';
import '../widgets/leo_bear.dart';

/// Onboarding — coleta nome e idade da criança antes de entrar no mapa.
///
/// Persiste em [SharedPreferences] (`child_name`, `child_age`) e navega
/// para o mapa ([NavShell]). Botão voltar retorna ao Login.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  int _selectedAge = 5; // default
  static const _ages = [4, 5, 6, 7];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _selectAge(int age) {
    HapticFeedback.selectionClick();
    AudioManager().playSFX(SFXType.pop);
    setState(() => _selectedAge = age);
  }

  Future<void> _start() async {
    HapticFeedback.mediumImpact();
    AudioManager().playSFX(SFXType.correct);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('child_name', _nameController.text.trim());
    await prefs.setInt('child_age', _selectedAge);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const NavShell(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppAccessibility.prefersReducedMotion(context);

    return Scaffold(
      body: Container(
        // Fundo — gradiente vertical claro
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary50, AppColors.blue50],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // ── Conteúdo rolável ───────────────────────────────────────
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(30, 78, 30, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildMascot(reduceMotion),
                    const SizedBox(height: 18),
                    _buildSpeechBubble(),
                    const SizedBox(height: 36),
                    _buildNameSection(),
                    const SizedBox(height: 32),
                    _buildAgeSection(),
                    const SizedBox(height: 40),
                    _buildStartButton(),
                  ],
                ),
              ),

              // ── Botão voltar flutuante ─────────────────────────────────
              Positioned(
                top: 6,
                left: 0,
                child: _buildBackButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Botão voltar ───────────────────────────────────────────────────────
  Widget _buildBackButton() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).pop();
        },
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.chevron_left_rounded,
              color: AppColors.primary600, size: 30),
        ),
      ),
    );
  }

  // ── Mascote (círculo dourado) ──────────────────────────────────────────
  Widget _buildMascot(bool reduceMotion) {
    final mascot = Container(
      width: 110,
      height: 110,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFDE68A), Color(0xFFFCD34D)],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40CA8A04),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: const LeoBear(size: 82),
    );
    if (reduceMotion) return mascot;
    return mascot
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -6, duration: 2800.ms, curve: Curves.easeInOut);
  }

  // ── Balão de fala ──────────────────────────────────────────────────────
  Widget _buildSpeechBubble() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary200, width: 3),
      ),
      child: const Text(
        'Oi! Eu sou o Léo 🐻 Vamos te conhecer?',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AppColors.primary800,
        ),
      ),
    );
  }

  // ── Seção nome ─────────────────────────────────────────────────────────
  Widget _buildNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('COMO VOCÊ SE CHAMA?'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primary200, width: 3),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
          child: Row(
            children: [
              const Icon(Icons.person_rounded,
                  color: AppColors.primary400, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  cursorColor: AppColors.primary500,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
                    border: InputBorder.none,
                    hintText: 'Seu nome',
                    hintStyle: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary300,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Seção idade ────────────────────────────────────────────────────────
  Widget _buildAgeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('QUANTOS ANOS VOCÊ TEM?'),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _ages.map(_buildAgeChip).toList(),
        ),
      ],
    );
  }

  Widget _buildAgeChip(int age) {
    final selected = age == _selectedAge;
    return GestureDetector(
      onTap: () => _selectAge(age),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 64,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected ? AppGradients.primary : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary500 : AppColors.primary200,
            width: 3,
          ),
        ),
        child: Text(
          '$age',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : AppColors.primary600,
          ),
        ),
      ),
    );
  }

  // ── Botão começar ──────────────────────────────────────────────────────
  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x807C3AED),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
          gradient: AppGradients.primary,
        ),
        child: ElevatedButton(
          onPressed: _start,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 17),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: const Text(
            'VAMOS COMEÇAR! →',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Rótulo de seção ────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: AppColors.primary600,
        letterSpacing: 0.7,
      ),
    );
  }
}
