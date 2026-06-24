import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/reading_game/presentation/screens/ilha_das_palavras_screen.dart';
import '../features/reading_game/presentation/screens/desafios_screen.dart';
import '../features/reading_game/presentation/screens/conquistas_screen.dart';
import '../features/reading_game/presentation/screens/avatar_personalizacao_screen.dart';
import '../features/reading_game/presentation/screens/settings_screen.dart';

// ═════════════════════════════════════════════════════════════════════════════
// NAV TAB CONTROLLER
// InheritedWidget exposto para qualquer descendente poder trocar de aba.
// Exemplo: NavTabController.of(context).setTab(3)
// ═════════════════════════════════════════════════════════════════════════════

class NavTabController extends InheritedWidget {
  final ValueChanged<int> setTab;
  final int currentTab;

  const NavTabController({
    super.key,
    required this.setTab,
    required this.currentTab,
    required super.child,
  });

  static NavTabController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NavTabController>();

  @override
  bool updateShouldNotify(NavTabController old) =>
      old.currentTab != currentTab;
}

// ═════════════════════════════════════════════════════════════════════════════
// NAV SHELL — Shell raiz com tab bar persistente
// ═════════════════════════════════════════════════════════════════════════════

class NavShell extends StatefulWidget {
  const NavShell({super.key});

  @override
  State<NavShell> createState() => NavShellState();
}

class NavShellState extends State<NavShell> with TickerProviderStateMixin {
  int _currentIndex = 0;

  // Um Navigator por aba — mantém estado ao trocar de aba
  final List<GlobalKey<NavigatorState>> _navKeys = [
    GlobalKey<NavigatorState>(), // 0: Início
    GlobalKey<NavigatorState>(), // 1: Desafios
    GlobalKey<NavigatorState>(), // 2: Conquistas
    GlobalKey<NavigatorState>(), // 3: Perfil
    GlobalKey<NavigatorState>(), // 4: Ajustes
  ];

  // Controladores para animação dos ícones
  late final List<AnimationController> _iconCtrl;

  @override
  void initState() {
    super.initState();
    _iconCtrl = List.generate(
      5,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 280),
      ),
    );
    _iconCtrl[0].value = 1.0; // Início ativo por padrão
  }

  @override
  void dispose() {
    for (final c in _iconCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  // ── API pública para descendentes ──────────────────────────────────────────
  void setTab(int index) => _onTabTap(index);

  // ── Troca de aba com guarda de saída ───────────────────────────────────────
  Future<void> _onTabTap(int index) async {
    HapticFeedback.selectionClick();

    // Mesma aba → pop até a raiz (ex: sair de uma atividade sem confirmação)
    if (index == _currentIndex) {
      _navKeys[index].currentState?.popUntil((r) => r.isFirst);
      return;
    }

    // Verifica se o usuário está no meio de uma atividade
    final canPop = _navKeys[_currentIndex].currentState?.canPop() ?? false;
    if (canPop) {
      final confirmed = await _showLeaveDialog();
      if (!mounted || confirmed != true) return;
      // Volta à raiz da aba atual antes de trocar
      _navKeys[_currentIndex].currentState?.popUntil((r) => r.isFirst);
    }

    // Anima ícones
    _iconCtrl[_currentIndex].reverse();
    _iconCtrl[index].forward();

    setState(() => _currentIndex = index);
  }

  // ── Modal "Quer pausar?" ────────────────────────────────────────────────────
  Future<bool?> _showLeaveDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (ctx) => _LeaveActivityDialog(
        onContinue: () => Navigator.of(ctx).pop(false),
        onLeave: () {
          HapticFeedback.mediumImpact();
          Navigator.of(ctx).pop(true);
        },
      ),
    );
  }

  // ── Botão físico de voltar ─────────────────────────────────────────────────
  void _handleHardwareBack() {
    HapticFeedback.selectionClick();
    final nav = _navKeys[_currentIndex].currentState;
    if (nav?.canPop() == true) {
      nav!.pop();
    } else if (_currentIndex != 0) {
      // Não está na aba Início → vai para Início
      _iconCtrl[_currentIndex].reverse();
      _iconCtrl[0].forward();
      setState(() => _currentIndex = 0);
    }
    // Se já está no Início na raiz → permanece no app (não sai)
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return NavTabController(
      setTab: setTab,
      currentTab: _currentIndex,
      child: PopScope(
        canPop: false,
        onPopInvoked: (_) => _handleHardwareBack(),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          // IndexedStack mantém todas as abas vivas (estado preservado)
          body: IndexedStack(
            index: _currentIndex,
            children: [
              _TabNavigator(
                navigatorKey: _navKeys[0],
                child: const IlhaDasPalavrasScreen(),
              ),
              _TabNavigator(
                navigatorKey: _navKeys[1],
                child: const DesafiosScreen(),
              ),
              _TabNavigator(
                navigatorKey: _navKeys[2],
                child: const ConquistasScreen(),
              ),
              _TabNavigator(
                navigatorKey: _navKeys[3],
                child: const AvatarPersonalizacaoScreen(),
              ),
              _TabNavigator(
                navigatorKey: _navKeys[4],
                child: const SettingsScreen(),
              ),
            ],
          ),
          bottomNavigationBar: _BottomTabBar(
            currentIndex: _currentIndex,
            iconControllers: _iconCtrl,
            onTap: _onTabTap,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB NAVIGATOR — Navigator isolado por aba
// ═════════════════════════════════════════════════════════════════════════════

class _TabNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  const _TabNavigator({
    required this.navigatorKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (_) => child,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// LEAVE ACTIVITY DIALOG
// ═════════════════════════════════════════════════════════════════════════════

class _LeaveActivityDialog extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback onLeave;

  const _LeaveActivityDialog({
    required this.onContinue,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⏸️', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            const Text(
              'Quer pausar?',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E2A38),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Seu progresso até aqui\nestá salvo! 🌟',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                // Continuar
                Expanded(
                  child: GestureDetector(
                    onTap: onContinue,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                            color: const Color(0xFFE5E7EB), width: 1.5),
                      ),
                      child: const Center(
                        child: Text(
                          '▶️ Continuar',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Sair
                Expanded(
                  child: GestureDetector(
                    onTap: onLeave,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                        ),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withOpacity(0.45),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '🚪 Sair',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// BOTTOM TAB BAR — Sempre fixa na base, z-index acima de todo conteúdo
// ═════════════════════════════════════════════════════════════════════════════

class _BottomTabBar extends StatelessWidget {
  final int currentIndex;
  final List<AnimationController> iconControllers;
  final ValueChanged<int> onTap;

  const _BottomTabBar({
    required this.currentIndex,
    required this.iconControllers,
    required this.onTap,
  });

  // Definições das abas: ícone moderno, rótulo, cor ativa neon cyan
  static const _tabs = [
    _TabDef(icon: Icons.home_rounded, label: 'Início', activeColor: Color(0xFF00F2FE)),
    _TabDef(icon: Icons.sports_esports_rounded, label: 'Desafios', activeColor: Color(0xFF00F2FE)),
    _TabDef(icon: Icons.star_rounded, label: 'Conquistas', activeColor: Color(0xFF00F2FE)),
    _TabDef(icon: Icons.person_rounded, label: 'Perfil', activeColor: Color(0xFF00F2FE)),
    _TabDef(icon: Icons.settings_rounded, label: 'Ajustes', activeColor: Color(0xFF00F2FE)),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      // Altura fixa + padding para safe area (notch/home bar)
      height: 74 + bottomPad,
      padding: EdgeInsets.only(bottom: bottomPad),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.9), // Glass dark nav background
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.08),
            width: 1.5,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          _tabs.length,
          (i) => _TabItem(
            tab: _tabs[i],
            isActive: i == currentIndex,
            controller: iconControllers[i],
            onTap: () => onTap(i),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB ITEM DEFINITION
// ─────────────────────────────────────────────────────────────────────────────

class _TabDef {
  final IconData icon;
  final String label;
  final Color activeColor;

  const _TabDef({
    required this.icon,
    required this.label,
    required this.activeColor,
  });
}

class _TabItem extends StatelessWidget {
  final _TabDef tab;
  final bool isActive;
  final AnimationController controller;
  final VoidCallback onTap;

  const _TabItem({
    super.key,
    required this.tab,
    required this.isActive,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedBuilder(
          animation: controller,
          builder: (_, __) {
            final t = controller.value; // 0.0 = inactive, 1.0 = active
            final activeColor = tab.activeColor;
            const inactiveColor = Color(0xFF94A3B8); // Slate gray from design
            final currentColor = Color.lerp(inactiveColor, activeColor, t)!;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Indicador superior neon cyan ──────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  height: 3,
                  width: isActive ? 28 : 0,
                  margin: const EdgeInsets.only(bottom: 5),
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      if (isActive)
                        BoxShadow(
                          color: activeColor.withOpacity(0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                    ],
                  ),
                ),
                // ── Destaque do ícone / scale no toque ─────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: isActive ? 14 : 0,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      Colors.transparent,
                      activeColor.withOpacity(0.08),
                      t,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Transform.scale(
                    scale: 1.0 + t * 0.14,
                    child: Icon(
                      tab.icon,
                      size: 26,
                      color: currentColor,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                // ── Rótulo animado ──────────────────────────────────────
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 10,
                    fontWeight:
                        isActive ? FontWeight.w900 : FontWeight.w600,
                    color: currentColor,
                  ),
                  child: Text(tab.label),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

                                                                                                                                                               