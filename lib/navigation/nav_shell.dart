import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/reading_game/presentation/screens/praca_central_screen.dart';
import '../features/reading_game/presentation/screens/desafios_screen.dart';
import '../features/reading_game/presentation/screens/conquistas_screen.dart';
import '../features/reading_game/presentation/screens/perfil_screen.dart';

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
  ];

  // Controladores para animação dos ícones
  late final List<AnimationController> _iconCtrl;

  @override
  void initState() {
    super.initState();
    _iconCtrl = List.generate(
      4,
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
                child: const PracaCentralScreen(),
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
                child: const PerfilScreen(),
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

  // Definições das abas: emoji, rótulo, cor ativa
  static const _tabs = [
    _TabDef(emoji: '🏠', label: 'Início',     activeColor: Color(0xFF8B5CF6)),
    _TabDef(emoji: '🎮', label: 'Desafios',   activeColor: Color(0xFFF97316)),
    _TabDef(emoji: '🏆', label: 'Conquistas', activeColor: Color(0xFFD97706)),
    _TabDef(emoji: '👤', label: 'Perfil',     activeColor: Color(0xFF3B82F6)),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      // Altura fixa + padding para safe area (notch/home bar)
      height: 74 + bottomPad,
      padding: EdgeInsets.only(bottom: bottomPad),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, -4),
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
// TAB ITEM
// ─────────────────────────────────────────────────────────────────────────────

class _TabDef {
  final String emoji;
  final String label;
  final Color activeColor;

  const _TabDef({
    required this.emoji,
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
            final t = controller.value; // 0.0 = inativo, 1.0 = ativo
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Indicador superior ──────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  height: 3,
                  width: isActive ? 28 : 0,
                  margin: const EdgeInsets.only(bottom: 5),
                  decoration: BoxDecoration(
                    color: tab.activeColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // ── Emoji do ícone com pill de destaque ─────────────────
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
                      tab.activeColor.withOpacity(0.12),
                      t,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Transform.scale(
                    scale: 1.0 + t * 0.18,
                    child: Text(
                      tab.emoji,
                      style: const TextStyle(fontSize: 22),
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
                        isActive ? FontWeight.w800 : FontWeight.w600,
                    color: isActive
                        ? tab.activeColor
                        : const Color(0xFF9CA3AF),
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
