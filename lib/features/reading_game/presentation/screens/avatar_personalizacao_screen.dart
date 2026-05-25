import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/app_colors.dart';
import '../../../../services/gamification_service.dart';
import 'loja_recompensas_screen.dart';

// ═════════════════════════════════════════════════════════════════════════════
// INCLUSIVE AVATAR SYSTEM — ADVANCED SPECIFICATION (Art Director Approved)
// ═════════════════════════════════════════════════════════════════════════════

class AvatarPersonalizacaoScreen extends StatefulWidget {
  const AvatarPersonalizacaoScreen({super.key});

  @override
  State<AvatarPersonalizacaoScreen> createState() =>
      _AvatarPersonalizacaoScreenState();
}

class _AvatarPersonalizacaoScreenState
    extends State<AvatarPersonalizacaoScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  // Estado completo do Avatar (Z-Index Layer Priority Engine)
  String _charName = 'Maria';
  String _pronouns = 'ela/dela';
  
  // 🧍 Corpo & Rosto
  String _skinTone = '#F5D7B1';
  String _faceShape = 'round';
  String _eyeColor = 'brown';
  String _expression = 'happy';

  // 💇 Cabelo
  String _hairStyle = 'curly_medium';
  String _hairColor = '#3D231A';

  // 👕 Roupas (Básicas, Texturizadas, Fantasia)
  String _clothingType = 'two_piece'; // 'two_piece' | 'full_body'
  String _clothingTop = 'tshirt'; // tshirt, hoodie, jacket, knit_sweater, denim_jacket, satin_blouse
  String _clothingTopColor = '#3B82F6';
  String _clothingBottom = 'jeans'; // jeans, shorts, skirt, corduroy_pants, tulle_skirt
  String _clothingBottomColor = '#1E40AF';
  String _fullBodyItem = 'none'; // princess_dress, jumpsuit, none
  String _fullBodyColor = '#D8B4E2';

  // 👓 Acessórios & Joias
  String _glasses = 'none'; // none, round, heart
  String _hat = 'none'; // none, cap, crown
  String _necklace = 'none'; // none, chunky_necklace, royal_pearls
  String _bracelet = 'none'; // none, chunky_bracelet
  String _accessory = 'none'; // none, book, wand, mascot_luna

  // Configurações do Sistema
  SharedPreferences? _prefs;
  bool _loading = true;
  bool _saved = false;
  bool _reducedMotion = false;

  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 7, vsync: this);
    _nameCtrl = TextEditingController(text: _charName);
    _loadPrefs();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Carregar preferências locais ───────────────────────────────────────────
  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _prefs = prefs;
      _charName = prefs.getString('avatar_name') ?? 'Maria';
      _pronouns = prefs.getString('avatar_pronouns') ?? 'ela/dela';
      
      _skinTone = prefs.getString('avatar_skin_tone') ?? '#F5D7B1';
      _faceShape = prefs.getString('avatar_face_shape') ?? 'round';
      _eyeColor = prefs.getString('avatar_eye_color') ?? 'brown';
      _expression = prefs.getString('avatar_expression') ?? 'happy';

      _hairStyle = prefs.getString('avatar_hair_style') ?? 'curly_medium';
      _hairColor = prefs.getString('avatar_hair_color') ?? '#3D231A';

      _clothingType = prefs.getString('avatar_clothing_type') ?? 'two_piece';
      _clothingTop = prefs.getString('avatar_clothing_top') ?? 'tshirt';
      _clothingTopColor = prefs.getString('avatar_clothing_top_color') ?? '#3B82F6';
      _clothingBottom = prefs.getString('avatar_clothing_bottom') ?? 'jeans';
      _clothingBottomColor = prefs.getString('avatar_clothing_bottom_color') ?? '#1E40AF';
      _fullBodyItem = prefs.getString('avatar_full_body_item') ?? 'none';
      _fullBodyColor = prefs.getString('avatar_full_body_color') ?? '#D8B4E2';

      _glasses = prefs.getString('avatar_glasses') ?? 'none';
      _hat = prefs.getString('avatar_hat') ?? 'none';
      _necklace = prefs.getString('avatar_necklace') ?? 'none';
      _bracelet = prefs.getString('avatar_bracelet') ?? 'none';
      _accessory = prefs.getString('avatar_accessory') ?? 'none';
      
      _reducedMotion = prefs.getBool('cfg_reduce_motion') ?? false;

      _nameCtrl.text = _charName;
      _loading = false;
    });
  }

  // ── Salvar configurações do avatar (Persistência e Backward Compatibility) ───
  Future<void> _save() async {
    final prefs = _prefs;
    if (prefs == null) return;

    await Future.wait([
      prefs.setString('avatar_name', _charName),
      prefs.setString('avatar_pronouns', _pronouns),
      prefs.setString('avatar_skin_tone', _skinTone),
      prefs.setString('avatar_face_shape', _faceShape),
      prefs.setString('avatar_eye_color', _eyeColor),
      prefs.setString('avatar_expression', _expression),
      prefs.setString('avatar_hair_style', _hairStyle),
      prefs.setString('avatar_hair_color', _hairColor),
      prefs.setString('avatar_clothing_type', _clothingType),
      prefs.setString('avatar_clothing_top', _clothingTop),
      prefs.setString('avatar_clothing_top_color', _clothingTopColor),
      prefs.setString('avatar_clothing_bottom', _clothingBottom),
      prefs.setString('avatar_clothing_bottom_color', _clothingBottomColor),
      prefs.setString('avatar_full_body_item', _fullBodyItem),
      prefs.setString('avatar_full_body_color', _fullBodyColor),
      prefs.setString('avatar_glasses', _glasses),
      prefs.setString('avatar_hat', _hat),
      prefs.setString('avatar_necklace', _necklace),
      prefs.setString('avatar_bracelet', _bracelet),
      prefs.setString('avatar_accessory', _accessory),
    ]);

    // Backward compatibility com widgets legados que usam os emojis clássicos
    String fallbackChar = '🧒';
    if (_hairStyle == 'afro_puff' || _hairStyle == 'box_braids' || _hairStyle == 'curly_medium' || _hairStyle == 'straight_fringe') {
      fallbackChar = '👧';
    } else if (_hairStyle == 'short_cool') {
      fallbackChar = '👦';
    }
    await prefs.setString('avatar_char', fallbackChar);

    String fallbackHat = '';
    if (_hat == 'cap') fallbackHat = '🧢';
    if (_hat == 'crown') fallbackHat = '👑';
    await prefs.setString('avatar_hat', fallbackHat);

    String fallbackAcc = '';
    if (_accessory == 'book') fallbackAcc = '📖';
    if (_accessory == 'wand') fallbackAcc = '⭐';
    if (_accessory == 'mascot_luna') fallbackAcc = '🦊';
    await prefs.setString('avatar_acc', fallbackAcc);

    HapticFeedback.mediumImpact();
    setState(() => _saved = true);

    // Toast de Look Salvo! 🪄
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Text('🪄 ', style: TextStyle(fontSize: 22)),
            Expanded(
              child: Text(
                'Look mágico salvo com sucesso!',
                style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF10B981),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  // ── Resetar a categoria da aba atual para os padrões ────────────────────────
  void _resetCategory(int tabIndex) {
    HapticFeedback.lightImpact();
    setState(() {
      switch (tabIndex) {
        case 0: // Corpo & Rosto
          _skinTone = '#F5D7B1';
          _faceShape = 'round';
          _eyeColor = 'brown';
          _expression = 'happy';
          break;
        case 1: // Cabelo
          _hairStyle = 'curly_medium';
          _hairColor = '#3D231A';
          break;
        case 2: // Roupas Básicas
          _clothingType = 'two_piece';
          _clothingTop = 'tshirt';
          _clothingTopColor = '#3B82F6';
          _clothingBottom = 'jeans';
          _clothingBottomColor = '#1E40AF';
          break;
        case 3: // Roupas Texturizadas
          _clothingType = 'two_piece';
          _clothingTop = 'knit_sweater';
          _clothingBottom = 'corduroy_pants';
          break;
        case 4: // Fantasia
          _clothingType = 'two_piece';
          _fullBodyItem = 'none';
          _hat = 'none';
          _necklace = 'none';
          _bracelet = 'none';
          break;
        case 5: // Acessórios
          _glasses = 'none';
          _accessory = 'none';
          break;
        case 6: // Identidade
          _charName = 'Maria';
          _pronouns = 'ela/dela';
          _nameCtrl.text = _charName;
          break;
      }
    });
  }

  // ── Gerar combinação divertida aleatória ────────────────────────────────────
  void _randomize() {
    HapticFeedback.lightImpact();
    final random = math.Random();

    final skinTones = ['#FFE2D1', '#F5D7B1', '#E6C29E', '#C59B76', '#A87B57', '#8D5A38', '#603B26', '#3D231A'];
    final eyeColors = ['brown', 'blue', 'green', 'hazel'];
    final hairStyles = ['short_cool', 'afro_puff', 'box_braids', 'curly_medium', 'straight_fringe', 'top_knot', 'bald'];
    final hairColors = ['#1E1E1E', '#3D231A', '#E9C46A', '#E76F51', '#F43F5E', '#3B82F6', '#A855F7'];
    
    // Decidir se veste Roupa Básica, Texturizada ou Fantasia
    final clothChoice = random.nextInt(3);
    if (clothChoice == 0) { // Básica
      _clothingType = 'two_piece';
      final basicTops = ['tshirt', 'hoodie', 'jacket'];
      final basicBottoms = ['jeans', 'shorts', 'skirt'];
      _clothingTop = basicTops[random.nextInt(basicTops.length)];
      _clothingBottom = basicBottoms[random.nextInt(basicBottoms.length)];
      _fullBodyItem = 'none';
    } else if (clothChoice == 1) { // Texturizada
      _clothingType = 'two_piece';
      final texTops = ['knit_sweater', 'denim_jacket', 'satin_blouse'];
      final texBottoms = ['corduroy_pants', 'tulle_skirt'];
      _clothingTop = texTops[random.nextInt(texTops.length)];
      _clothingBottom = texBottoms[random.nextInt(texBottoms.length)];
      _fullBodyItem = 'none';
    } else { // Fantasia (Princess Dress ou Macacão)
      _clothingType = 'full_body';
      final fulls = ['princess_dress', 'jumpsuit'];
      _fullBodyItem = fulls[random.nextInt(fulls.length)];
    }

    final topColors = ['#F43F5E', '#3B82F6', '#10B981', '#F59E0B', '#A855F7', '#F97316'];
    final glassesOptions = ['none', 'round', 'heart'];
    final hatOptions = ['none', 'cap', 'crown'];
    final necklaceOptions = ['none', 'chunky_necklace', 'royal_pearls'];
    final accOptions = ['none', 'book', 'wand', 'mascot_luna'];
    final expressions = ['happy', 'curious', 'focused', 'surprised', 'calm'];

    setState(() {
      _skinTone = skinTones[random.nextInt(skinTones.length)];
      _eyeColor = eyeColors[random.nextInt(eyeColors.length)];
      _hairStyle = hairStyles[random.nextInt(hairStyles.length)];
      _hairColor = hairColors[random.nextInt(hairColors.length)];
      _clothingTopColor = topColors[random.nextInt(topColors.length)];
      _glasses = glassesOptions[random.nextInt(glassesOptions.length)];
      _hat = hatOptions[random.nextInt(hatOptions.length)];
      _necklace = necklaceOptions[random.nextInt(necklaceOptions.length)];
      _accessory = accOptions[random.nextInt(accOptions.length)];
      _expression = expressions[random.nextInt(expressions.length)];
    });
  }

  @override
  Widget build(BuildContext context) {
    final int coins = context.watch<GamificationService>().state.coins;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _TopBar(coins: coins, onLoja: _openLoja),
                  const SizedBox(height: 4),
                  
                  // Real-time Preview central (220x220px anchor-aligned canvas)
                  _RealtimeAvatarPreview(
                    skinTone: _skinTone,
                    faceShape: _faceShape,
                    eyeColor: _eyeColor,
                    hairStyle: _hairStyle,
                    hairColor: _hairColor,
                    clothingType: _clothingType,
                    clothingTop: _clothingTop,
                    clothingTopColor: _clothingTopColor,
                    clothingBottom: _clothingBottom,
                    clothingBottomColor: _clothingBottomColor,
                    fullBodyItem: _fullBodyItem,
                    fullBodyColor: _fullBodyColor,
                    glasses: _glasses,
                    hat: _hat,
                    necklace: _necklace,
                    bracelet: _bracelet,
                    accessory: _accessory,
                    expression: _expression,
                    reducedMotion: _reducedMotion,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Grade de Categorias em Abas com Rolagem Horizontal
                  _TabBar(controller: _tabCtrl),
                  const SizedBox(height: 8),
                  
                  Expanded(
                    child: TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _buildCorpoTab(),
                        _buildCabeloTab(),
                        _buildRoupasBasicasTab(),
                        _buildRoupasTexturizadasTab(),
                        _buildFantasiaTab(),
                        _buildAcessorioTab(),
                        _buildIdentidadeTab(),
                      ],
                    ),
                  ),
                  
                  _buildActionsFooter(),
                ],
              ),
      ),
    );
  }

  void _openLoja() {
    Navigator.of(context).push(
      AppPageRoute(page: const LojaRecompensasScreen()),
    );
  }

  // ── Seção Header de Ajuda ──────────────────────────────────────────────────
  Widget _buildSectionTitle(String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            fontSize: 15,
            color: AppColors.textDark,
          ),
        ),
        TextButton.icon(
          onPressed: () => _resetCategory(_tabCtrl.index),
          icon: const Icon(Icons.refresh_rounded, size: 14, color: AppColors.textMid),
          label: const Text(
            'Resetar',
            style: TextStyle(fontFamily: 'Nunito', fontSize: 11, color: AppColors.textMid, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // ── Tab 1: Corpo & Rosto ───────────────────────────────────────────────────
  Widget _buildCorpoTab() {
    final List<Map<String, String>> skinTones = [
      {'value': '#FFE2D1', 'name': 'Porcelana'},
      {'value': '#F5D7B1', 'name': 'Pêssego'},
      {'value': '#E6C29E', 'name': 'Caramel'},
      {'value': '#C59B76', 'name': 'Bronze'},
      {'value': '#A87B57', 'name': 'Dourado'},
      {'value': '#8D5A38', 'name': 'Cacau'},
      {'value': '#603B26', 'name': 'Expresso'},
      {'value': '#3D231A', 'name': 'Retinto'},
    ];
    final List<Map<String, String>> expressions = [
      {'value': 'happy', 'name': 'Feliz 🌟'},
      {'value': 'curious', 'name': 'Curioso 🤔'},
      {'value': 'focused', 'name': 'Focado 🧠'},
      {'value': 'surprised', 'name': 'Surpreso 😮'},
      {'value': 'calm', 'name': 'Tranquilo 😌'},
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        _buildSectionTitle('🧍 Tons de Pele Inclusivos'),
        const SizedBox(height: 4),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: skinTones.length,
            itemBuilder: (ctx, i) {
              final tone = skinTones[i];
              final isSelected = _skinTone == tone['value'];
              return _buildGridTile(
                isSelected: isSelected,
                accessibilityLabel: 'Pele ${tone['name']}',
                onTap: () => setState(() => _skinTone = tone['value']!),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color(int.parse(tone['value']!.replaceAll('#', '0xFF'))),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('🎭 Expressões Faciais'),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.1,
          ),
          itemCount: expressions.length,
          itemBuilder: (ctx, i) {
            final exp = expressions[i];
            final isSelected = _expression == exp['value'];
            return _buildGridTile(
              isSelected: isSelected,
              accessibilityLabel: 'Expressão ${exp['name']}',
              onTap: () => setState(() => _expression = exp['value']!),
              child: Center(
                child: Text(
                  exp['name']!,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: isSelected ? const Color(0xFF22C55E) : AppColors.textDark,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Tab 2: Cabelo ──────────────────────────────────────────────────────────
  Widget _buildCabeloTab() {
    final List<Map<String, String>> styles = [
      {'value': 'short_cool', 'name': 'Curto Fofo'},
      {'value': 'afro_puff', 'name': 'Afro Puffs'},
      {'value': 'box_braids', 'name': 'Tranças'},
      {'value': 'curly_medium', 'name': 'Cacheado'},
      {'value': 'straight_fringe', 'name': 'Franja Lisa'},
      {'value': 'top_knot', 'name': 'Coque Alto'},
      {'value': 'bald', 'name': 'Carequinha'},
    ];
    final List<Map<String, String>> colors = [
      {'value': '#1E1E1E', 'name': 'Preto'},
      {'value': '#3D231A', 'name': 'Castanho'},
      {'value': '#E9C46A', 'name': 'Loiro'},
      {'value': '#E76F51', 'name': 'Ruivo'},
      {'value': '#F43F5E', 'name': 'Rosa'},
      {'value': '#3B82F6', 'name': 'Azul'},
      {'value': '#A855F7', 'name': 'Roxo'},
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        _buildSectionTitle('💇 Estilo do Cabelo'),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.1,
          ),
          itemCount: styles.length,
          itemBuilder: (ctx, i) {
            final st = styles[i];
            final isSelected = _hairStyle == st['value'];
            return _buildGridTile(
              isSelected: isSelected,
              accessibilityLabel: 'Cabelo ${st['name']}',
              onTap: () => setState(() => _hairStyle = st['value']!),
              child: Center(
                child: Text(
                  st['name']!,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: isSelected ? const Color(0xFF22C55E) : AppColors.textDark,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('🎨 Cor do Cabelo'),
        const SizedBox(height: 6),
        SizedBox(
          height: 64,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: colors.length,
            itemBuilder: (ctx, i) {
              final col = colors[i];
              final isSelected = _hairColor == col['value'];
              return _buildGridTile(
                isSelected: isSelected,
                accessibilityLabel: 'Cor ${col['name']}',
                onTap: () => setState(() => _hairColor = col['value']!),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Color(int.parse(col['value']!.replaceAll('#', '0xFF'))),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Tab 3: Roupas Básicas ───────────────────────────────────────────────────
  Widget _buildRoupasBasicasTab() {
    final List<Map<String, String>> tops = [
      {'value': 'tshirt', 'name': 'Camiseta 👕'},
      {'value': 'hoodie', 'name': 'Moletom 🧥'},
      {'value': 'jacket', 'name': 'Jaqueta 🧥'},
    ];
    final List<Map<String, String>> bottoms = [
      {'value': 'jeans', 'name': 'Calça Jeans 👖'},
      {'value': 'shorts', 'name': 'Shortinho 🩳'},
      {'value': 'skirt', 'name': 'Saia Rodada 👗'},
    ];

    final isFullBody = _clothingType == 'full_body';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        if (isFullBody) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.shade300, width: 1.5),
            ),
            child: const Text(
              '👑 Look de Fantasia completo ativo! Para vestir roupas separadas básicas, selecione uma peça abaixo.',
              style: TextStyle(fontFamily: 'Nunito', color: Color(0xFF92400E), fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        _buildSectionTitle('👕 Peça de Cima'),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.1,
          ),
          itemCount: tops.length,
          itemBuilder: (ctx, i) {
            final tp = tops[i];
            final isSelected = !isFullBody && _clothingTop == tp['value'];
            return _buildGridTile(
              isSelected: isSelected,
              accessibilityLabel: 'Cima ${tp['name']}',
              onTap: () {
                setState(() {
                  _clothingType = 'two_piece';
                  _clothingTop = tp['value']!;
                  _fullBodyItem = 'none';
                });
              },
              child: Center(
                child: Text(
                  tp['name']!,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: isSelected ? const Color(0xFF22C55E) : AppColors.textDark,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('👖 Peça de Baixo'),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.1,
          ),
          itemCount: bottoms.length,
          itemBuilder: (ctx, i) {
            final bt = bottoms[i];
            final isSelected = !isFullBody && _clothingBottom == bt['value'];
            return _buildGridTile(
              isSelected: isSelected,
              accessibilityLabel: 'Baixo ${bt['name']}',
              onTap: () {
                setState(() {
                  _clothingType = 'two_piece';
                  _clothingBottom = bt['value']!;
                  _fullBodyItem = 'none';
                });
              },
              child: Center(
                child: Text(
                  bt['name']!,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: isSelected ? const Color(0xFF22C55E) : AppColors.textDark,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Tab 4: Roupas Texturizadas ──────────────────────────────────────────────
  Widget _buildRoupasTexturizadasTab() {
    final List<Map<String, String>> texTops = [
      {'value': 'knit_sweater', 'name': 'Tricô Quentinho 🧶'},
      {'value': 'denim_jacket', 'name': 'Jaqueta Jeans 🧵'},
      {'value': 'satin_blouse', 'name': 'Blusa Cetim ✨'},
    ];
    final List<Map<String, String>> texBottoms = [
      {'value': 'corduroy_pants', 'name': 'Calça Veludo 🦺'},
      {'value': 'tulle_skirt', 'name': 'Saia Tule 🩰'},
    ];

    final isFullBody = _clothingType == 'full_body';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        _buildSectionTitle('🧶 Partes Superiores Texturizadas'),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.5,
          ),
          itemCount: texTops.length,
          itemBuilder: (ctx, i) {
            final tp = texTops[i];
            final isSelected = !isFullBody && _clothingTop == tp['value'];
            return _buildGridTile(
              isSelected: isSelected,
              accessibilityLabel: 'Tops texturizados ${tp['name']}',
              onTap: () {
                setState(() {
                  _clothingType = 'two_piece';
                  _clothingTop = tp['value']!;
                  _fullBodyItem = 'none';
                });
              },
              child: Center(
                child: Text(
                  tp['name']!,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: isSelected ? const Color(0xFF22C55E) : AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('🧵 Partes Inferiores Texturizadas'),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.5,
          ),
          itemCount: texBottoms.length,
          itemBuilder: (ctx, i) {
            final bt = texBottoms[i];
            final isSelected = !isFullBody && _clothingBottom == bt['value'];
            return _buildGridTile(
              isSelected: isSelected,
              accessibilityLabel: 'Bottoms texturizados ${bt['name']}',
              onTap: () {
                setState(() {
                  _clothingType = 'two_piece';
                  _clothingBottom = bt['value']!;
                  _fullBodyItem = 'none';
                });
              },
              child: Center(
                child: Text(
                  bt['name']!,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: isSelected ? const Color(0xFF22C55E) : AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Tab 5: Fantasia ────────────────────────────────────────────────────────
  Widget _buildFantasiaTab() {
    final List<Map<String, String>> fullBodys = [
      {'value': 'princess_dress', 'name': 'Vestido Princesa 👸'},
      {'value': 'jumpsuit', 'name': 'Macacão Estrelas 🌟'},
    ];
    final List<Map<String, String>> crowns = [
      {'value': 'none', 'name': 'Sem Adorno 🚫'},
      {'value': 'crown', 'name': 'Coroa Redonda 👑'},
    ];
    final List<Map<String, String>> necklaces = [
      {'value': 'none', 'name': 'Sem Colar 🚫'},
      {'value': 'chunky_necklace', 'name': 'Pedras Grandes 💎'},
      {'value': 'royal_pearls', 'name': 'Pérolas Reais 📿'},
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        _buildSectionTitle('👗 Looks de Fantasia Completos'),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.4,
          ),
          itemCount: fullBodys.length,
          itemBuilder: (ctx, i) {
            final fb = fullBodys[i];
            final isSelected = _clothingType == 'full_body' && _fullBodyItem == fb['value'];
            return _buildGridTile(
              isSelected: isSelected,
              accessibilityLabel: 'Look completo ${fb['name']}',
              onTap: () {
                setState(() {
                  _clothingType = 'full_body';
                  _fullBodyItem = fb['value']!;
                });
              },
              child: Center(
                child: Text(
                  fb['name']!,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: isSelected ? const Color(0xFF22C55E) : AppColors.textDark,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('👑 Coroas de Brincar'),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.4,
          ),
          itemCount: crowns.length,
          itemBuilder: (ctx, i) {
            final cr = crowns[i];
            final isSelected = _hat == cr['value'];
            return _buildGridTile(
              isSelected: isSelected,
              accessibilityLabel: 'Coroa ${cr['name']}',
              onTap: () => setState(() => _hat = cr['value']!),
              child: Center(
                child: Text(
                  cr['name']!,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: isSelected ? const Color(0xFF22C55E) : AppColors.textDark,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('💎 Joias (Colares)'),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.1,
          ),
          itemCount: necklaces.length,
          itemBuilder: (ctx, i) {
            final nc = necklaces[i];
            final isSelected = _necklace == nc['value'];
            return _buildGridTile(
              isSelected: isSelected,
              accessibilityLabel: 'Colar ${nc['name']}',
              onTap: () => setState(() => _necklace = nc['value']!),
              child: Center(
                child: Text(
                  nc['name']!,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: isSelected ? const Color(0xFF22C55E) : AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Tab 6: Acessórios ──────────────────────────────────────────────────────
  Widget _buildAcessorioTab() {
    final List<Map<String, String>> glassesList = [
      {'value': 'none', 'name': 'Sem Óculos 🚫'},
      {'value': 'round', 'name': 'Redondos 👓'},
      {'value': 'heart', 'name': 'Coração ❤️'},
    ];
    final List<Map<String, String>> hatsList = [
      {'value': 'none', 'name': 'Sem Chapéu 🚫'},
      {'value': 'cap', 'name': 'Boné 🧢'},
    ];
    final List<Map<String, String>> itemsList = [
      {'value': 'none', 'name': 'Sem Acessório 🚫'},
      {'value': 'book', 'name': 'Livro Mágico 📖'},
      {'value': 'wand', 'name': 'Varinha 🪄'},
      {'value': 'mascot_luna', 'name': 'Mascote Luna 🦊'},
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        _buildSectionTitle('👓 Óculos'),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.1,
          ),
          itemCount: glassesList.length,
          itemBuilder: (ctx, i) {
            final gl = glassesList[i];
            final isSelected = _glasses == gl['value'];
            return _buildGridTile(
              isSelected: isSelected,
              accessibilityLabel: 'Óculos ${gl['name']}',
              onTap: () => setState(() => _glasses = gl['value']!),
              child: Center(
                child: Text(
                  gl['name']!,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: isSelected ? const Color(0xFF22C55E) : AppColors.textDark,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('🧢 Chapéus Básicos'),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.5,
          ),
          itemCount: hatsList.length,
          itemBuilder: (ctx, i) {
            final ht = hatsList[i];
            final isSelected = _hat == ht['value'];
            return _buildGridTile(
              isSelected: isSelected,
              accessibilityLabel: 'Chapéu ${ht['name']}',
              onTap: () => setState(() => _hat = ht['value']!),
              child: Center(
                child: Text(
                  ht['name']!,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: isSelected ? const Color(0xFF22C55E) : AppColors.textDark,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('🪄 Itens de Segurar'),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.4,
          ),
          itemCount: itemsList.length,
          itemBuilder: (ctx, i) {
            final it = itemsList[i];
            final isSelected = _accessory == it['value'];
            return _buildGridTile(
              isSelected: isSelected,
              accessibilityLabel: 'Segurar ${it['name']}',
              onTap: () => setState(() => _accessory = it['value']!),
              child: Center(
                child: Text(
                  it['name']!,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: isSelected ? const Color(0xFF22C55E) : AppColors.textDark,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Tab 7: Identidade (Nome, Pronome) ──────────────────────────────────────
  Widget _buildIdentidadeTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        _buildSectionTitle('👤 Como quer ser chamado?'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
          ),
          child: TextField(
            controller: _nameCtrl,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: AppColors.textDark,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: 'Digite seu nome mágico...',
            ),
            onChanged: (val) {
              setState(() => _charName = val);
            },
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('⚧️ Qual pronome quer usar?'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
          ),
          child: DropdownButton<String>(
            value: _pronouns,
            underline: const SizedBox(),
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.principal),
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: AppColors.textDark,
            ),
            items: ['ela/dela', 'ele/dele', 'elu/delu', 'sem preferência']
                .map((val) => DropdownMenuItem(
                      value: val,
                      child: Text(val),
                    ))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _pronouns = val);
              }
            },
          ),
        ),
      ],
    );
  }

  // ── Helper: Construtor do Card da Grade (88x88px com checkmark) ──────────────
  Widget _buildGridTile({
    required bool isSelected,
    required String accessibilityLabel,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Semantics(
      label: '$accessibilityLabel, ${isSelected ? 'selecionado' : 'não selecionado'}',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF22C55E).withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? const Color(0xFF22C55E) : Colors.grey.shade200,
              width: isSelected ? 4.0 : 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF22C55E).withOpacity(0.24),
                      blurRadius: 8,
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
          ),
          child: Stack(
            children: [
              Positioned.fill(child: child),
              if (isSelected)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 10),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Barra Inferior de Ações (Aleatório + Salvar) ────────────────────────────
  Widget _buildActionsFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Row(
        children: [
          Semantics(
            label: 'Gerar combinação divertida aleatória',
            child: GestureDetector(
              onTap: _randomize,
              child: Container(
                width: 60,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF8B5CF6), width: 2),
                ),
                child: const Center(
                  child: Text('🎲', style: TextStyle(fontSize: 24)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _save,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 56,
                decoration: BoxDecoration(
                  color: _saved ? const Color(0xFF22C55E) : const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (_saved ? const Color(0xFF22C55E) : const Color(0xFF3B82F6)).withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_saved ? '✅' : '✨', style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text(
                      _saved ? 'Salvo!' : 'Salvar Avatar',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TOP BAR
// ═════════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  final int coins;
  final VoidCallback onLoja;

  const _TopBar({required this.coins, required this.onLoja});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (Navigator.of(context).canPop())
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          Container(
            width: 56,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFDE68A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 2),
                Text(
                  '$coins',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            child: Text(
              'Meu Avatar',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                fontSize: 24,
                color: AppColors.textDark,
              ),
            ),
          ),
          GestureDetector(
            onTap: onLoja,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFBBF24),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFBBF24).withOpacity(0.3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Text(
                'Loja',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: Color(0xFF92400E),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// REALTIME LAYER PRIORITY VECTOR PREVIEW ENGINE
// ═════════════════════════════════════════════════════════════════════════════

class _RealtimeAvatarPreview extends StatefulWidget {
  final String skinTone;
  final String faceShape;
  final String eyeColor;
  final String hairStyle;
  final String hairColor;
  final String clothingType;
  final String clothingTop;
  final String clothingTopColor;
  final String clothingBottom;
  final String clothingBottomColor;
  final String fullBodyItem;
  final String fullBodyColor;
  final String glasses;
  final String hat;
  final String necklace;
  final String bracelet;
  final String accessory;
  final String expression;
  final bool reducedMotion;

  const _RealtimeAvatarPreview({
    required this.skinTone,
    required this.faceShape,
    required this.eyeColor,
    required this.hairStyle,
    required this.hairColor,
    required this.clothingType,
    required this.clothingTop,
    required this.clothingTopColor,
    required this.clothingBottom,
    required this.clothingBottomColor,
    required this.fullBodyItem,
    required this.fullBodyColor,
    required this.glasses,
    required this.hat,
    required this.necklace,
    required this.bracelet,
    required this.accessory,
    required this.expression,
    required this.reducedMotion,
  });

  @override
  State<_RealtimeAvatarPreview> createState() => _RealtimeAvatarPreviewState();
}

class _RealtimeAvatarPreviewState extends State<_RealtimeAvatarPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  bool _blink = false;
  math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    
    if (!widget.reducedMotion) {
      _animCtrl.repeat(reverse: true);
      _triggerPeriodicBlink();
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _triggerPeriodicBlink() async {
    while (mounted) {
      await Future.delayed(Duration(seconds: 3 + _random.nextInt(4)));
      if (mounted && !widget.reducedMotion) {
        setState(() => _blink = true);
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) setState(() => _blink = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final skinColor = Color(int.parse(widget.skinTone.replaceAll('#', '0xFF')));
    final hairColorVal = Color(int.parse(widget.hairColor.replaceAll('#', '0xFF')));
    final topColorVal = Color(int.parse(widget.clothingTopColor.replaceAll('#', '0xFF')));
    final bottomColorVal = Color(int.parse(widget.clothingBottomColor.replaceAll('#', '0xFF')));
    
    final eyeColorMap = {
      'brown': const Color(0xFF5C3D2E),
      'blue': const Color(0xFF3B82F6),
      'green': const Color(0xFF10B981),
      'hazel': const Color(0xFFB5A642),
    };
    final activeEyeColor = eyeColorMap[widget.eyeColor] ?? const Color(0xFF5C3D2E);

    final isFullBody = widget.clothingType == 'full_body';

    // Dynamic scale breathing simulation (Z-index priorities implemented)
    final Widget previewCore = AnimatedBuilder(
      animation: _animCtrl,
      builder: (context, child) {
        final double scaleY = widget.reducedMotion
            ? 1.0
            : 1.0 + (_animCtrl.value * 0.02);
        return Transform.scale(
          scaleY: scaleY,
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // 1. CORPO BASE (Torso / Ombros)
                Positioned(
                  bottom: 16,
                  child: Container(
                    width: 106,
                    height: 48,
                    decoration: BoxDecoration(
                      color: skinColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                  ),
                ),
                
                // 2. CABELO (PARTE DE TRÁS - Evita clipping)
                if (widget.hairStyle == 'box_braids' || widget.hairStyle == 'curly_medium' || widget.hairStyle == 'straight_fringe')
                  Positioned(
                    bottom: 75,
                    child: _buildHairBack(hairColorVal),
                  ),

                // 3. PESCOÇO
                Positioned(
                  bottom: 58,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: skinColor.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),

                // 4. PARTE INFERIOR (Calça / Saia)
                if (!isFullBody)
                  Positioned(
                    bottom: 12,
                    child: _buildClothingBottom(bottomColorVal),
                  ),

                // 5. PARTE SUPERIOR (Camiseta / Blusa) OU VESTIDO INTEIRO (Full body)
                Positioned(
                  bottom: 22,
                  child: isFullBody
                      ? _buildFullBodyOutfit(skinColor)
                      : _buildClothingTop(topColorVal),
                ),

                // 6. ROSTO E CABEÇA BASE
                Positioned(
                  bottom: 66,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: skinColor,
                      borderRadius: BorderRadius.circular(
                        widget.faceShape == 'oval'
                            ? 45
                            : widget.faceShape == 'heart'
                                ? 36
                                : 40, // round / default
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Bochechas
                        Positioned(bottom: 22, left: 10, child: _buildBlush()),
                        Positioned(bottom: 22, right: 10, child: _buildBlush()),
                        // Sobrancelhas
                        Positioned(
                          top: 24,
                          child: Row(
                            children: [
                              Transform.rotate(
                                angle: widget.expression == 'curious' ? -0.12 : 0.05,
                                child: _buildEyebrow(),
                              ),
                              const SizedBox(width: 28),
                              Transform.rotate(
                                angle: widget.expression == 'focused' ? -0.05 : 0.05,
                                child: _buildEyebrow(),
                              ),
                            ],
                          ),
                        ),
                        // Olhos
                        Positioned(
                          top: 32,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildEye(activeEyeColor),
                              const SizedBox(width: 24),
                              _buildEye(activeEyeColor),
                            ],
                          ),
                        ),
                        // Boca
                        Positioned(
                          bottom: 22,
                          child: _buildMouth(),
                        ),
                      ],
                    ),
                  ),
                ),

                // 7. CABELO (PARTE DA FRENTE / FRANJA)
                Positioned(
                  bottom: 124,
                  child: _buildHairFront(hairColorVal),
                ),

                // 8. JOIAS (COLAR - Renderizado acima das roupas)
                if (widget.necklace != 'none')
                  Positioned(
                    bottom: 50,
                    child: _buildNecklace(),
                  ),

                // 9. ÓCULOS
                if (widget.glasses != 'none')
                  Positioned(
                    bottom: widget.glasses == 'round' ? 102 : 84,
                    child: _buildGlasses(),
                  ),

                // 10. COROA OU CHAPÉU (Renderizado acima do cabelo)
                if (widget.hat != 'none')
                  Positioned(
                    bottom: widget.hat == 'crown' ? 148 : 144,
                    child: _buildHat(),
                  ),

                // 11. ITEM NA MÃO / MASCOTE
                if (widget.accessory != 'none')
                  _buildAccessory(),
              ],
            ),
          ),
        );
      },
    );

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE0E7FF), Color(0xFFC7D2FE)],
              ),
              border: Border.all(color: Colors.white, width: 6),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.18),
                  blurRadius: 20,
                ),
              ],
            ),
          ),
          previewCore,
        ],
      ),
    );
  }

  // ── OMBROS / ROUPAS RENDERING (2D Baked Textures) ──────────────────────────
  Widget _buildClothingTop(Color color) {
    final double width = 100;
    final double height = 42;

    switch (widget.clothingTop) {
      case 'knit_sweater': // Tricô Quentinho (linhas cruzadas baked)
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: CustomPaint(
            painter: _KnitTexturePainter(),
          ),
        );
      case 'denim_jacket': // Jaqueta Jeans (costuras e botões)
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF4B6584), // Denim
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: CustomPaint(
            painter: _DenimTexturePainter(),
          ),
        );
      case 'satin_blouse': // Blusa Cetim (manga bufante, gradiente sutil)
        return Container(
          width: width + 12,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.85), color, color.withOpacity(0.9)],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: const Center(child: Text('✨', style: TextStyle(color: Colors.white60, fontSize: 10))),
        );
      case 'hoodie':
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 3, height: 12, color: Colors.white54),
                  const SizedBox(width: 6),
                  Container(width: 3, height: 12, color: Colors.white54),
                ],
              ),
            ),
          ),
        );
      case 'jacket':
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: CustomPaint(painter: _JacketLinePainter()),
        );
      case 'tshirt':
      default:
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
        );
    }
  }

  // ── PARTES INFERIORES RENDERING ────────────────────────────────────────────
  Widget _buildClothingBottom(Color color) {
    final double width = 80;
    final double height = 18;

    switch (widget.clothingBottom) {
      case 'corduroy_pants': // Veludo cotelê (listras finas verticais)
        return Container(
          width: width,
          height: height,
          decoration: const BoxDecoration(
            color: Color(0xFF8C7AE6), // corduroy purple
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          child: CustomPaint(painter: _CorduroyTexturePainter()),
        );
      case 'tulle_skirt': // Saia Tule (camadas transparentes)
        return Stack(
          alignment: Alignment.center,
          children: [
            // Under Shorts
            Container(
              width: width - 8,
              height: height,
              color: Colors.grey.shade400,
            ),
            // Tulle layers overlay
            Container(
              width: width + 10,
              height: height + 6,
              decoration: BoxDecoration(
                color: const Color(0xFFF472B6).withOpacity(0.55),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
            ),
          ],
        );
      case 'skirt':
        return Container(
          width: width + 8,
          height: height + 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
        );
      case 'shorts':
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(6),
            ),
          ),
        );
      case 'jeans':
      default:
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(6),
            ),
          ),
        );
    }
  }

  // ── VESTIDOS E PEÇAS INTEIRAS (Princess Dress & Macacão) ───────────────────
  Widget _buildFullBodyOutfit(Color skinColor) {
    if (widget.fullBodyItem == 'princess_dress') {
      // Vestido princesa (saia rodada tulle, corpete, recortes pele nos braços)
      return SizedBox(
        width: 114,
        height: 60,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Flared Princess Skirt
            Positioned(
              bottom: 0,
              child: Container(
                width: 114,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFD8B4E2), // Lavender pink
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: CustomPaint(painter: _TulleDetailPainter()),
              ),
            ),
            // Corpete bodice
            Positioned(
              top: 0,
              child: Container(
                width: 90,
                height: 26,
                decoration: const BoxDecoration(
                  color: Color(0xFFC084FC),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text('👑', style: TextStyle(fontSize: 8, color: Colors.white54)),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Macacão Estampado (jumpsuit)
      return Container(
        width: 96,
        height: 52,
        decoration: const BoxDecoration(
          color: Color(0xFF14B8A6), // Teal
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
            bottomLeft: Radius.circular(14),
            bottomRight: Radius.circular(14),
          ),
        ),
        child: CustomPaint(painter: _JumpsuitPatternPainter()),
      );
    }
  }

  // ── CABELOS LAYERING ───────────────────────────────────────────────────────
  // Parte de trás (renderizado embaixo da cabeça)
  Widget _buildHairBack(Color hairColor) {
    final double width = 86;
    switch (widget.hairStyle) {
      case 'box_braids':
        return Container(
          width: width + 8,
          height: 68,
          decoration: BoxDecoration(
            color: hairColor,
            borderRadius: BorderRadius.circular(10),
          ),
        );
      case 'curly_medium':
        return Container(
          width: width + 14,
          height: 58,
          decoration: BoxDecoration(
            color: hairColor,
            borderRadius: BorderRadius.circular(16),
          ),
        );
      case 'straight_fringe':
        return Container(
          width: width + 6,
          height: 62,
          decoration: BoxDecoration(
            color: hairColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
          ),
        );
      default:
        return const SizedBox(width: 10, height: 10);
    }
  }

  // Parte da frente (renderizado no topo do rosto)
  Widget _buildHairFront(Color hairColor) {
    final double width = 84;
    switch (widget.hairStyle) {
      case 'short_cool':
        return Container(
          width: width + 6,
          height: 42,
          decoration: BoxDecoration(
            color: hairColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(40),
              topRight: Radius.circular(40),
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(6),
            ),
          ),
        );
      case 'afro_puff': // Puffs inclusivos
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned(
              left: -14,
              top: -12,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: hairColor, shape: BoxShape.circle),
              ),
            ),
            Positioned(
              right: -14,
              top: -12,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: hairColor, shape: BoxShape.circle),
              ),
            ),
            Container(
              width: width,
              height: 40,
              decoration: BoxDecoration(
                color: hairColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
            ),
          ],
        );
      case 'top_knot':
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned(
              top: -22,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: hairColor, shape: BoxShape.circle),
              ),
            ),
            Container(
              width: width,
              height: 38,
              decoration: BoxDecoration(
                color: hairColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
            ),
          ],
        );
      case 'box_braids':
      case 'curly_medium':
      case 'straight_fringe':
        // Apenas a franja/capacete frontal (o resto renderiza por trás)
        return Container(
          width: width,
          height: 42,
          decoration: BoxDecoration(
            color: hairColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(40),
              topRight: Radius.circular(40),
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
        );
      case 'bald':
      default:
        return const SizedBox(width: 80, height: 4);
    }
  }

  // ── JOIAS & ADORNOS RENDERING ──────────────────────────────────────────────
  Widget _buildNecklace() {
    if (widget.necklace == 'chunky_necklace') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildJewelGem(Colors.amber),
          _buildJewelGem(Colors.redAccent),
          _buildJewelGem(Colors.amber),
        ],
      );
    } else {
      // Pearl necklace
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (_) => Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: const BoxDecoration(
            color: Colors.white70,
            shape: BoxShape.circle,
          ),
        )),
      );
    }
  }

  Widget _buildJewelGem(Color color) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.2),
      ),
    );
  }

  // Helper: Bochechas rosadas
  Widget _buildBlush() {
    return Container(
      width: 16,
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFFF43F5E).withOpacity(0.24),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  // Helper: Sobrancelha
  Widget _buildEyebrow() {
    return Container(
      width: 14,
      height: 2.5,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }

  // Helper: Olhos
  Widget _buildEye(Color irisColor) {
    if (_blink) {
      return Container(width: 16, height: 3, color: Colors.black.withOpacity(0.8));
    }
    if (widget.expression == 'calm') {
      return CustomPaint(
        size: const Size(16, 8),
        painter: _ClosedEyePainter(),
      );
    }
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: irisColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Stack(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                ),
                Positioned(
                  top: 1,
                  left: 1,
                  child: Container(
                    width: 2.5,
                    height: 2.5,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper: Boca
  Widget _buildMouth() {
    if (widget.expression == 'surprised') {
      return Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: Color(0xFF6B21A8),
          shape: BoxShape.circle,
        ),
      );
    }
    return CustomPaint(
      size: const Size(18, 9),
      painter: _SmilePainter(),
    );
  }

  // Helper: Óculos
  Widget _buildGlasses() {
    if (widget.glasses == 'round') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2.2),
            ),
          ),
          Container(width: 10, height: 3, color: Colors.black),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2.2),
            ),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('❤️', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 1.5),
          const Text('❤️', style: TextStyle(fontSize: 28)),
        ],
      );
    }
  }

  // Helper: Chapéus
  Widget _buildHat() {
    if (widget.hat == 'cap') {
      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 82,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFEF4444),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40),
                topRight: Radius.circular(40),
              ),
            ),
          ),
          Positioned(
            bottom: 2,
            left: 50,
            child: Transform.rotate(
              angle: 0.12,
              child: Container(
                width: 32,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // Rounded magical crown sitting exactly on top hair center
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text('👑', style: TextStyle(fontSize: 42)),
      );
    }
  }

  // Helper: Acessórios handheld
  Widget _buildAccessory() {
    if (widget.accessory == 'book') {
      return Positioned(
        bottom: 8,
        right: 4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: const Text('📖', style: TextStyle(fontSize: 18)),
        ),
      );
    } else if (widget.accessory == 'wand') {
      return const Positioned(
        bottom: 4,
        right: -8,
        child: Text('🪄', style: TextStyle(fontSize: 34)),
      );
    } else {
      return const Positioned(
        bottom: 4,
        left: -10,
        child: Text('🦊', style: TextStyle(fontSize: 30)),
      );
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB BAR (HORIZONTAL SCROLL)
// ═════════════════════════════════════════════════════════════════════════════

class _TabBar extends StatelessWidget {
  final TabController controller;

  const _TabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final List<String> labels = ['Rosto', 'Cabelo', 'Básicas', 'Texturizadas', 'Fantasia', 'Acessórios', 'Identidade'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDim,
          borderRadius: BorderRadius.circular(30),
        ),
        child: TabBar(
          controller: controller,
          isScrollable: true,
          labelStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
          ),
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textMid,
          indicator: BoxDecoration(
            color: AppColors.principal,
            borderRadius: BorderRadius.circular(30),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabs: labels
              .map((l) => Tab(text: l, height: 38))
              .toList(),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TEXTURE PAINTERS (2D baked illustrations)
// ═════════════════════════════════════════════════════════════════════════════

class _KnitTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.24)
      ..strokeWidth = 2.0;
    // Draw gentle horizontal knit rows
    for (double y = 8; y < size.height; y += 8) {
      canvas.drawLine(Offset(10, y), Offset(size.width - 10, y), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DenimTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber.shade200.withOpacity(0.4)
      ..strokeWidth = 1.5;
    // Baked stitching lines near borders
    canvas.drawLine(const Offset(6, 6), Offset(size.width - 6, 6), paint);
    canvas.drawLine(Offset(10, 0), Offset(10, size.height), paint);
    canvas.drawLine(Offset(size.width - 10, 0), Offset(size.width - 10, size.height), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CorduroyTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.12)
      ..strokeWidth = 1.8;
    // vertical cords ridges
    for (double x = 8; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TulleDetailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1.5;
    // Radial vertical fold lines for tulle skirt
    for (double x = 16; x < size.width; x += 16) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _JumpsuitPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.35);
    // Draw clean stars or dots pattern
    canvas.drawCircle(const Offset(20, 15), 3, paint);
    canvas.drawCircle(const Offset(50, 10), 3, paint);
    canvas.drawCircle(const Offset(80, 15), 3, paint);
    canvas.drawCircle(const Offset(35, 30), 3, paint);
    canvas.drawCircle(const Offset(65, 32), 3, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _JacketLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SmilePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6B21A8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(size.width / 2, size.height, size.width, 0);
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ClosedEyePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(size.width / 2, 0, size.width, size.height);
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
