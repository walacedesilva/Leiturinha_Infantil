import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../services/audio_manager.dart';
import '../../../../services/gamification_service.dart';
import '../../../../navigation/nav_shell.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:app_settings/app_settings.dart';
import '../../../../services/google_auth_service.dart';

// ═════════════════════════════════════════════════════════════════════════════
// SETTINGS SCREEN — "Alfabetização Mágica"
// ═════════════════════════════════════════════════════════════════════════════

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Controle de Modo (Criança / Pais)
  bool _isParentMode = false;

  // Estados locais das configurações (persistidos em SharedPreferences)
  double _masterVolume = 0.8;
  double _sfxVolume = 0.7;
  double _narrationVolume = 0.9;
  double _musicVolume = 0.5;

  double _brightness = 0.8;
  bool _dyslexiaFont = false;
  bool _highContrast = false;
  bool _reduceMotion = false;
  String _textSize = 'M'; // P, M, G, GG

  bool _notifMissoes = true;
  bool _notifNovidades = true;
  bool _notifMarketing = false; // DESATIVADA POR PADRÃO (GDPR-K)

  String _difficulty = 'Automático'; // Automático, Iniciante, Avançado
  bool _weeklyReport = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    GoogleAuthService().addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    GoogleAuthService().removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // ── Carregar configurações locais ──────────────────────────────────────────
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Carrega o brilho real do hardware da tela se disponível, com fallback do SharedPreferences
    double systemBrightness = 0.8;
    try {
      systemBrightness = await ScreenBrightness().current;
    } catch (e) {
      systemBrightness = prefs.getDouble('cfg_brightness') ?? 0.8;
    }

    setState(() {
      _masterVolume = prefs.getDouble('cfg_master_volume') ?? 0.8;
      _sfxVolume = prefs.getDouble('cfg_sfx_volume') ?? 0.7;
      _narrationVolume = prefs.getDouble('cfg_narration_volume') ?? 0.9;
      _musicVolume = prefs.getDouble('cfg_music_volume') ?? 0.5;

      _brightness = systemBrightness;
      _dyslexiaFont = prefs.getBool('cfg_dyslexia_font') ?? false;
      _highContrast = prefs.getBool('cfg_high_contrast') ?? false;
      _reduceMotion = prefs.getBool('cfg_reduce_motion') ?? false;
      _textSize = prefs.getString('cfg_text_size') ?? 'M';

      _notifMissoes = prefs.getBool('cfg_notif_missoes') ?? true;
      _notifNovidades = prefs.getBool('cfg_notif_novidades') ?? true;
      _notifMarketing = prefs.getBool('cfg_notif_marketing') ?? false;

      _difficulty = prefs.getString('cfg_difficulty') ?? 'Automático';
      _weeklyReport = prefs.getBool('cfg_weekly_report') ?? true;
    });
  }

  // ── Salvar configuração individual ─────────────────────────────────────────
  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  // ── Desafio Matemático (Parental Gate) ──────────────────────────────────────
  void _triggerParentalGate() {
    HapticFeedback.mediumImpact();
    final random = math.Random();
    final num1 = random.nextInt(10) + 11; // 11-20
    final num2 = random.nextInt(9) + 2;   // 2-10
    final correctAnswer = num1 + num2;

    String currentInput = "";

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔒 Área dos Pais',
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E2A38))),
                    const SizedBox(height: 12),
                    const Text(
                      'Resolva a conta mágica para entrar na Área dos Pais:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15,
                          color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$num1 + $num2 = ${currentInput.isEmpty ? "?" : currentInput}',
                        style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF8B5CF6)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Teclado Numérico Customizado (Acessível)
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: List.generate(10, (index) {
                        final number = (index + 1) % 10;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setModalState(() {
                              if (currentInput.length < 3) {
                                currentInput += number.toString();
                              }
                            });
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFFE5E7EB), width: 1.5),
                            ),
                            child: Center(
                              child: Text(
                                '$number',
                                style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF374151)),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              setModalState(() => currentInput = "");
                            },
                            child: const Text('Limpar',
                                style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.redAccent)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5CF6),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              final answer = int.tryParse(currentInput);
                              if (answer == correctAnswer) {
                                AudioManager().playSFX(SFXType.correct);
                                setState(() {
                                  _isParentMode = true;
                                });
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                        '🔓 Área dos Pais desbloqueada com sucesso!'),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: const Color(0xFF10B981),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16)),
                                  ),
                                );
                              } else {
                                AudioManager().playSFX(SFXType.error);
                                HapticFeedback.vibrate();
                                setModalState(() {
                                  currentInput = "";
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('⚠️ Ops, tente de novo!'),
                                    backgroundColor: Colors.redAccent,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            child: const Text('Entrar',
                                style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.w800)),
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
      },
    );
  }

  // ── Exportar Meus Dados (JSON) ─────────────────────────────────────────────
  Future<void> _exportData() async {
    HapticFeedback.mediumImpact();
    final gam = context.read<GamificationService>();
    final state = gam.state;

    final dataMap = {
      "app": "Alfabetização Mágica",
      "exported_at": DateTime.now().toIso8601String(),
      "progress": {
        "coins": state.coins,
        "xp": state.xp,
        "streak_days": state.currentStreak,
        "total_words_validated": state.totalWordsValidated,
        "badges_earned": state.earnedBadgeIds.toList(),
        "families_played": state.familiesPlayed.toList()
      },
      "settings": {
        "textSize": _textSize,
        "dyslexiaFont": _dyslexiaFont,
        "highContrast": _highContrast,
        "masterVolume": _masterVolume,
        "difficulty": _difficulty
      }
    };

    final prettyString = const JsonEncoder.withIndent('  ').convert(dataMap);
    await Share.share(prettyString, subject: 'Alfabetização Mágica - Meus Dados');
  }

  // ── Excluir Conta e Dados (Google Play & LGPD Cascading Simulation) ──────────
  void _triggerDeleteAccountFlow() {
    HapticFeedback.heavyImpact();
    // Confirmação 1
    showDialog(
      context: context,
      builder: (ctx1) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('⚠️ Excluir Conta e Dados?',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFEF4444))),
          content: const Text(
            'Você deseja mesmo iniciar o processo de exclusão permanente de sua conta e dados?',
            style: TextStyle(fontFamily: 'Nunito', color: Color(0xFF374151)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx1),
              child: const Text('Cancelar',
                  style: TextStyle(
                      fontFamily: 'Nunito', color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
              onPressed: () {
                Navigator.pop(ctx1);
                // Confirmação 2 (Dupla Confirmação Crítica)
                _showSecondDeleteConfirmation();
              },
              child: const Text('Continuar',
                  style: TextStyle(
                      fontFamily: 'Nunito', fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showSecondDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx2) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('🚨 Ação Irreversível!',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFEF4444))),
          content: const Text(
            'Isso apagará permanentemente o perfil, progresso, moedas, badges e dados sincronizados na nuvem de nossos servidores (LGPD Art. 18). Esta ação não pode ser desfeita!',
            style: TextStyle(fontFamily: 'Nunito', color: Color(0xFF374151)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx2),
              child: const Text('Voltar ao Seguro',
                  style: TextStyle(
                      fontFamily: 'Nunito', color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
              onPressed: () {
                Navigator.pop(ctx2);
                _performCascadeDeletion();
              },
              child: const Text('Sim, Excluir Tudo!',
                  style: TextStyle(
                      fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performCascadeDeletion() async {
    // Exibe tela/dialog de carregamento
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctxLoading) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: const Padding(
            padding: EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
                ),
                SizedBox(height: 20),
                Text(
                  'Anonimizando logs...',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 6),
                Text(
                  'Limpando servidores e base de dados...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Nunito', fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Simula atraso da delegação server-side
    await Future.delayed(const Duration(seconds: 3));

    // Ações técnicas de limpeza local
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Limpa AsyncStorage/SharedPreferences completamente

    // Reseta o serviço de gamificação
    if (mounted) {
      final gam = context.read<GamificationService>();
      await gam.reset();
    }

    // Fecha o loading dialog
    if (mounted) {
      Navigator.pop(context);
    }

    // Redireciona e exibe feedback de sucesso
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctxSuccess) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('✨ Conta e Dados Removidos',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF10B981))),
            content: const Text(
              'Sua conta foi excluída com sucesso de nossos servidores e todos os dados locais foram apagados.',
              style: TextStyle(fontFamily: 'Nunito'),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                onPressed: () {
                  Navigator.pop(ctxSuccess); // fecha diálogo
                  Navigator.pop(context);    // sai da tela de configurações
                },
                child: const Text('Concluir',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
    }
  }

  // ── Visualização da Política de Privacidade ─────────────────────────────────
  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('📄 Política de Privacidade',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E2A38))),
          content: const SingleChildScrollView(
            child: Text(
              'A sua privacidade é extremamente importante para nós. Coletamos apenas as informações estritamente necessárias para acompanhar o progresso educativo das crianças e oferecer feedbacks personalizados. Não realizamos venda de dados de menores de idade sob nenhuma circunstância. Todas as nossas operações de tratamento de dados cumprem rigorosamente a LGPD e a GDPR-K.',
              style: TextStyle(fontFamily: 'Nunito', height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fechar',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B5CF6))),
            ),
          ],
        );
      },
    );
  }

  // ── Visualização de Termos de Uso ──────────────────────────────────────────
  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('📝 Termos de Serviço',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E2A38))),
          content: const SingleChildScrollView(
            child: Text(
              'Bem-vindo ao aplicativo Alfabetização Mágica. Ao utilizar nossos serviços, você concorda que o app se destina apenas a uso pessoal, recreativo e de apoio pedagógico. Toda a propriedade intelectual e ativos visuais ou sonoros contidos pertencem à desenvolvedora.',
              style: TextStyle(fontFamily: 'Nunito', height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fechar',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B5CF6))),
            ),
          ],
        );
      },
    );
  }

  // ── Restaurar Compras (Mock) ───────────────────────────────────────────────
  void _restorePurchases() {
    AudioManager().playSFX(SFXType.correct);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('🎉 Compras e assinaturas restauradas com sucesso!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF10B981),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // ── Gerenciar Assinatura (Simula Deep Link) ──────────────────────────────────
  void _manageSubscription() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('🛍️ Assinatura do App',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E2A38))),
          content: const Text(
            'Redirecionando você diretamente para a página de gerenciamento de assinaturas da Google Play Store. Lá você poderá renovar, cancelar ou alterar o seu plano.',
            style: TextStyle(fontFamily: 'Nunito'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar',
                  style: TextStyle(
                      fontFamily: 'Nunito', color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Redirecionando para Google Play...'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Ir para a Loja',
                  style: TextStyle(
                      fontFamily: 'Nunito', fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // ── Visualizar Licenças Open Source ────────────────────────────────────────
  void _showLicenses() {
    showLicensePage(
      context: context,
      applicationName: 'Alfabetização Mágica',
      applicationVersion: 'v1.0.4 (Build 42)',
      applicationIcon: const Text('📚', style: TextStyle(fontSize: 48)),
    );
  }

  // ── Resetar Progresso (Confirmado) ─────────────────────────────────────────
  void _resetProgress() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('⚠️ Resetar Progresso?',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFEF4444))),
          content: const Text(
            'Você quer mesmo apagar o progresso de leitura, moedas e badges? A sua conta continuará ativa.',
            style: TextStyle(fontFamily: 'Nunito'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Manter Tudo',
                  style: TextStyle(
                      fontFamily: 'Nunito', color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
              onPressed: () async {
                Navigator.pop(ctx);
                final gam = context.read<GamificationService>();
                await gam.reset();
                AudioManager().playSFX(SFXType.correct);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('🌟 Progresso resetado! Comece sua nova jornada!'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                );
              },
              child: const Text('Resetar',
                  style: TextStyle(
                      fontFamily: 'Nunito', fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // ── Mock Trigger Permissões do Sistema ──────────────────────────────────────
  void _manageSystemPermissions() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('🎙️ Permissões do Sistema',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E2A38))),
          content: const Text(
            'Abrindo a tela de configurações nativas do dispositivo para que você possa habilitar ou desabilitar permissões como Microfone e Câmera para o app.',
            style: TextStyle(fontFamily: 'Nunito'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fechar',
                  style: TextStyle(
                      fontFamily: 'Nunito', color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
              onPressed: () {
                Navigator.pop(ctx);
                AppSettings.openAppSettings();
              },
              child: const Text('Abrir Ajustes',
                  style: TextStyle(
                      fontFamily: 'Nunito', fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // ── Build principal ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0.5,
        title: Text(
          _isParentMode ? '⚙️ Área dos Pais' : '⚙️ Configurações',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            final nav = Navigator.of(context);
            if (nav.canPop()) {
              nav.pop();
            } else {
              final tabCtrl = NavTabController.maybeOf(context);
              if (tabCtrl != null) {
                tabCtrl.setTab(0);
              } else {
                Navigator.maybePop(context);
              }
            }
          },
        ),
        actions: [
          if (_isParentMode)
            TextButton.icon(
              onPressed: () {
                setState(() => _isParentMode = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('👶 Retornou ao Modo Criança!'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                );
              },
              icon: const Icon(Icons.lock_rounded, color: Color(0xFF8B5CF6)),
              label: const Text(
                'Bloquear',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    color: Color(0xFF8B5CF6),
                    fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 👶 MODO CRIANÇA (Sempre Visível)
            _buildVolumeSliders(),
            const SizedBox(height: 12),
            _buildBrightnessSlider(),

            if (!_isParentMode) ...[
              const SizedBox(height: 24),
              // Botão para Área dos Pais
              GestureDetector(
                onTap: _triggerParentalGate,
                child: Container(
                  height: 68,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🔒', style: TextStyle(fontSize: 22)),
                        SizedBox(width: 10),
                        Text(
                          'Acessar Área dos Pais',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().scale(delay: 200.ms, duration: 300.ms, curve: Curves.easeOutBack),
              ),
            ],

            // 👨👩👧 ÁREA DOS PAIS (Visível apenas após destravar o gate)
            if (_isParentMode) ...[
              const SizedBox(height: 16),
              const Divider(height: 32, thickness: 1.5),

              _buildGoogleProfileCard(),
              const SizedBox(height: 20),

              // 🧠 1. ACESSIBILIDADE E VISUAL
              _buildSectionHeader('♿ Acessibilidade e Leitura'),
              _buildTextSizeSelector(),
              const SizedBox(height: 12),
              _buildVisualToggles(),

              const SizedBox(height: 20),

              // 🎯 2. PEDAGÓGICO
              _buildSectionHeader('🌱 Pedagógico'),
              _buildPedagogicoSection(),

              const SizedBox(height: 20),

              // 🔔 3. NOTIFICAÇÕES & PERMISSÕES
              _buildSectionHeader('🔔 Notificações e Permissões'),
              _buildNotificationSwitches(),

              const SizedBox(height: 20),

              // 💳 4. COMPRAS E ASSINATURAS
              _buildSectionHeader('💳 Compras e Assinatura'),
              _buildComprasSection(),

              const SizedBox(height: 20),

              // 🛡️ 5. PRIVACIDADE E DADOS (LGPD / Google Play)
              _buildSectionHeader('🛡️ Central de Privacidade e Dados'),
              _buildPrivacyDataSection(),

              const SizedBox(height: 24),

              // 🆘 6. SOBRE E SUPORTE
              _buildSectionHeader('ℹ️ Suporte e Informações'),
              _buildAboutSupportSection(),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── Componente: Cabeçalho de Seção ─────────────────────────────────────────
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 17,
          fontWeight: FontWeight.w900,
          color: Color(0xFF1F2937),
        ),
      ),
    );
  }

  // ── Componente: Card Customizado ──────────────────────────────────────────
  Widget _buildSettingsCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // ── Modo Criança: Sliders de Volume ────────────────────────────────────────
  Widget _buildVolumeSliders() {
    return _buildSettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Text('🔊', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                'Volume Geral',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Slider(
            value: _masterVolume,
            activeColor: const Color(0xFF8B5CF6),
            inactiveColor: const Color(0xFFE5E7EB),
            onChanged: (val) {
              setState(() => _masterVolume = val);
              _saveSetting('cfg_master_volume', val);
              AudioManager().setMasterVolume(val);
            },
          ),
          if (_isParentMode) ...[
            const Divider(height: 20),
            _buildSubVolumeSlider('Narrador 🎙️', _narrationVolume, (val) {
              setState(() => _narrationVolume = val);
              _saveSetting('cfg_narration_volume', val);
              AudioManager().setNarrationVolume(val);
            }),
            _buildSubVolumeSlider('Efeitos (SFX) 🎮', _sfxVolume, (val) {
              setState(() => _sfxVolume = val);
              _saveSetting('cfg_sfx_volume', val);
              AudioManager().setSfxVolume(val);
            },
                // Preview só ao SOLTAR (evita criar dezenas de players no arraste)
                onChangeEnd: () => AudioManager().playSFX(SFXType.pop)),
            _buildSubVolumeSlider('Trilha Sonora 🎵', _musicVolume, (val) {
              setState(() => _musicVolume = val);
              _saveSetting('cfg_music_volume', val);
              AudioManager().setMusicVolume(val);
            }),
          ]
        ],
      ),
    );
  }

  Widget _buildSubVolumeSlider(
      String label, double val, ValueChanged<double> onChanged,
      {VoidCallback? onChangeEnd}) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 13, color: Color(0xFF4B5563)),
          ),
        ),
        Expanded(
          child: Slider(
            value: val,
            activeColor: const Color(0xFF8B5CF6).withOpacity(0.7),
            inactiveColor: const Color(0xFFE5E7EB),
            onChanged: onChanged,
            onChangeEnd: onChangeEnd == null ? null : (_) => onChangeEnd(),
          ),
        ),
      ],
    );
  }

  // ── Modo Criança: Brilho do App ────────────────────────────────────────────
  Widget _buildBrightnessSlider() {
    return _buildSettingsCard(
      child: Row(
        children: [
          const Text('☀️', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          const Text(
            'Brilho do App',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4B5563),
            ),
          ),
          Expanded(
            child: Slider(
              value: _brightness,
              activeColor: const Color(0xFFF59E0B),
              inactiveColor: const Color(0xFFE5E7EB),
              onChanged: (val) async {
                setState(() => _brightness = val);
                _saveSetting('cfg_brightness', val);
                try {
                  await ScreenBrightness().setScreenBrightness(val);
                } catch (e) {
                  debugPrint('Erro ao definir brilho real: $e');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Modo Pais: Seletor de Tamanho de Texto (Acessibilidade) ────────────────
  Widget _buildTextSizeSelector() {
    final sizes = ['P', 'M', 'G', 'GG'];
    final double textPreviewSizes = {
      'P': 12.0,
      'M': 15.0,
      'G': 18.0,
      'GG': 22.0,
    }[_textSize]!;

    return _buildSettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Tamanho do Texto',
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: sizes.map((sz) {
              final active = _textSize == sz;
              return GestureDetector(
                onTap: () {
                  setState(() => _textSize = sz);
                  _saveSetting('cfg_text_size', sz);
                },
                child: Container(
                  width: 50,
                  height: 40,
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFF8B5CF6) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      sz,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: active ? Colors.white : const Color(0xFF374151),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          // Live Preview Area
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              'ABC — Sou um leitor mágico!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: textPreviewSizes,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Modo Pais: Toggles de Leitura & Visual (Acessibilidade) ────────────────
  Widget _buildVisualToggles() {
    return _buildSettingsCard(
      child: Column(
        children: [
          _buildToggleItem(
            'Fonte para Dislexia',
            'Utiliza a fonte Nunito com espaçamento e peso otimizados.',
            _dyslexiaFont,
            (val) {
              setState(() => _dyslexiaFont = val);
              _saveSetting('cfg_dyslexia_font', val);
            },
          ),
          const Divider(),
          _buildToggleItem(
            'Alto Contraste',
            'Melhora o contraste entre textos e planos de fundo (WCAG AAA).',
            _highContrast,
            (val) {
              setState(() => _highContrast = val);
              _saveSetting('cfg_high_contrast', val);
            },
          ),
          const Divider(),
          _buildToggleItem(
            'Reduzir Movimentos',
            'Desativa efeitos de partículas e acelera transições visuais.',
            _reduceMotion,
            (val) {
              setState(() => _reduceMotion = val);
              _saveSetting('cfg_reduce_motion', val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem(
      String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeColor: const Color(0xFF8B5CF6),
          onChanged: onChanged,
        ),
      ],
    );
  }

  // ── Modo Pais: Pedagógico ──────────────────────────────────────────────────
  Widget _buildPedagogicoSection() {
    return _buildSettingsCard(
      child: Column(
        children: [
          // Nível de Dificuldade
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dificuldade Pedagógica',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w800),
              ),
              DropdownButton<String>(
                value: _difficulty,
                underline: const SizedBox(),
                items: ['Automático', 'Iniciante', 'Avançado']
                    .map((val) => DropdownMenuItem(
                          value: val,
                          child: Text(val,
                              style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _difficulty = val);
                    _saveSetting('cfg_difficulty', val);
                  }
                },
              ),
            ],
          ),
          const Divider(),
          _buildToggleItem(
            'Relatório Semanal de Progresso',
            'Envia dados e conquistas de leitura semanais para os pais.',
            _weeklyReport,
            (val) {
              setState(() => _weeklyReport = val);
              _saveSetting('cfg_weekly_report', val);
            },
          ),
          const Divider(),
          // Resetar Progresso
          _buildActionItem(
            '⚠️ Resetar Progresso',
            'Apaga moedas, XP e histórico de leitura sem excluir sua conta.',
            onTap: _resetProgress,
            textColor: Colors.redAccent,
          ),
        ],
      ),
    );
  }

  // ── Modo Pais: Notificações & Permissões do Dispositivo ─────────────────────
  Widget _buildNotificationSwitches() {
    return _buildSettingsCard(
      child: Column(
        children: [
          _buildToggleItem(
            'Missões e Desafios',
            'Notificações sobre tarefas diárias e conquistas de sílabas.',
            _notifMissoes,
            (val) {
              setState(() => _notifMissoes = val);
              _saveSetting('cfg_notif_missoes', val);
            },
          ),
          const Divider(),
          _buildToggleItem(
            'Novidades e Conteúdos',
            'Avisos sobre novos livros de historinhas e novos jogos.',
            _notifNovidades,
            (val) {
              setState(() => _notifNovidades = val);
              _saveSetting('cfg_notif_novidades', val);
            },
          ),
          const Divider(),
          _buildToggleItem(
            'Marketing e Promoções',
            'Informações sobre novos pacotes ou promoções na loja.',
            _notifMarketing,
            (val) {
              setState(() => _notifMarketing = val);
              _saveSetting('cfg_notif_marketing', val);
            },
          ),
          const Divider(),
          _buildActionItem(
            '🎙️ Gerenciar Permissões',
            'Gerencie o acesso do app a recursos nativos (como microfone).',
            onTap: _manageSystemPermissions,
          ),
        ],
      ),
    );
  }

  // ── Modo Pais: Assinatura e Compras ────────────────────────────────────────
  Widget _buildComprasSection() {
    return _buildSettingsCard(
      child: Column(
        children: [
          _buildActionItem(
            '🔄 Restaurar Compras',
            'Restaurar conquistas ou planos adquiridos anteriormente.',
            onTap: _restorePurchases,
          ),
          const Divider(),
          _buildActionItem(
            '📝 Gerenciar Assinatura',
            'Gerencie ou cancele seu plano de suporte diretamente na loja.',
            onTap: _manageSubscription,
          ),
        ],
      ),
    );
  }

  // ── Modo Pais: Privacidade e Dados (LGPD/Google Play) ──────────────────────
  Widget _buildPrivacyDataSection() {
    return _buildSettingsCard(
      child: Column(
        children: [
          _buildActionItem(
            '🔗 Política de Privacidade',
            'Consulte como seus dados de leitura e voz são armazenados.',
            onTap: _showPrivacyPolicy,
          ),
          const Divider(),
          _buildActionItem(
            '📤 Exportar Meus Dados',
            'Baixar arquivo JSON contendo seu histórico e conquistas.',
            onTap: _exportData,
          ),
          const Divider(),
          _buildActionItem(
            '🗑️ Excluir Conta e Dados',
            'Solicita exclusão permanente server-side de todos os registros.',
            onTap: _triggerDeleteAccountFlow,
            textColor: Colors.redAccent,
          ),
        ],
      ),
    );
  }

  // ── Modo Pais: Sobre e Suporte ─────────────────────────────────────────────
  Widget _buildAboutSupportSection() {
    return _buildSettingsCard(
      child: Column(
        children: [
          _buildActionItem(
            '🆘 Fale Conosco',
            'Reportar problemas ou enviar sugestões para suporte técnico.',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Abrindo email para suporte@leiturinha.com...'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const Divider(),
          _buildActionItem(
            '📚 Licenças de Software',
            'Veja licenças open source das bibliotecas utilizadas no app.',
            onTap: _showLicenses,
          ),
          const Divider(),
          _buildActionItem(
            '📄 Termos de Serviço',
            'Leia nossos termos de uso do ecossistema educacional.',
            onTap: _showTermsOfService,
          ),
          const Divider(),
          // Dinâmico e Inline
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Versão do App',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  'v1.0.4 (Build 42)',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ── Helper: Item de Ação (Abertura de Modais/Links) ─────────────────────────
  Widget _buildActionItem(String title, String subtitle,
      {required VoidCallback onTap, Color? textColor}) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: textColor ?? const Color(0xFF1F2937),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            color: Color(0xFF6B7280),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
        onTap: onTap,
      ),
    );
  }

  Widget _buildGoogleProfileCard() {
    final auth = GoogleAuthService();
    final isLoggedIn = auth.isLoggedIn;
    final user = auth.currentUser;

    return _buildSettingsCard(
      child: isLoggedIn
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    // Avatar Google Premium com Borda e Sombras
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE15827).withOpacity(0.2),
                            blurRadius: 12,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          )
                        ],
                        border: Border.all(color: const Color(0xFFE15827), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFFFFCC80),
                        backgroundImage: user?.photoUrl != null
                            ? NetworkImage(user!.photoUrl!)
                            : null,
                        child: user?.photoUrl == null
                            ? Text(
                                user?.name.contains('Pai') == true
                                    ? '👨‍🚀'
                                    : user?.name.contains('Mãe') == true
                                        ? '👩‍🚀'
                                        : '👶',
                                style: const TextStyle(fontSize: 26),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Detalhes da Conta
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user?.name ?? 'Leitor Feliz',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1E2A38),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.verified_rounded,
                                color: Color(0xFF10B981),
                                size: 16,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? '',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: const Text(
                              'Responsável Autenticado',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 10,
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Botões de Ação: Desconectar e Trocar Perfil
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          AudioManager().playSFX(SFXType.pop);
                          
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              title: const Text(
                                'Desconectar Conta?',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1E2A38),
                                ),
                              ),
                              content: const Text(
                                'Isso desconectará a sua conta de progresso. O jogo continuará funcionando no modo offline local.',
                                style: TextStyle(fontFamily: 'Nunito'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancelar', style: TextStyle(fontFamily: 'Nunito', color: Color(0xFF6B7280))),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    await GoogleAuthService().logout();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('Conta desconectada com sucesso! 🧸'),
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: const Color(0xFF2B150A),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('Desconectar', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.logout_rounded, size: 16, color: Colors.redAccent),
                        label: const Text(
                          'Desconectar',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.redAccent,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          AudioManager().playSFX(SFXType.pop);
                          // Abre o simulador estelar para trocar o perfil diretamente!
                          _showGoogleFallbackDialog(null);
                        },
                        icon: const Icon(Icons.swap_horiz_rounded, size: 16, color: Colors.white),
                        label: const Text(
                          'Trocar Perfil',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Text('☁️', style: TextStyle(fontSize: 26)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Salvar Progresso na Nuvem',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E2A38),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Conecte com o Google para salvar conquistas e relatórios.',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    AudioManager().playSFX(SFXType.correct);
                    
                    try {
                      final user = await GoogleAuthService().login();
                      if (user != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Conta conectada com sucesso: ${user.name}! 🌟'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: const Color(0xFF10B981),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        _showGoogleFallbackDialog(e);
                      }
                    }
                  },
                  icon: const Icon(Icons.login_rounded, size: 16, color: Colors.white),
                  label: const Text(
                    'Conectar Conta Google',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ],
            ),
    );
  }

  // ── Diálogo Lúdico de Simulação Estelar Google na Tela de Configurações ───
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
                  'O login real do Google encontrou uma limitação no seu dispositivo (comum em emuladores ou Windows).\n\nPara continuar sua jornada pedagógica sem bloqueios, escolha uma das contas Google simuladas para conectar!',
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
          
          HapticFeedback.mediumImpact();
          AudioManager().playSFX(SFXType.correct);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Simulação Ativa! Conta conectada: ${user.name}! 🌟'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          );
        } catch (e) {
          if (!mounted) return;
          HapticFeedback.vibrate();
          AudioManager().playSFX(SFXType.error);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Falha ao autenticar com a conta simulada. 🧸'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          );
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
}
