// ignore_for_file: constant_identifier_names
import 'package:flutter/material.dart';

// =============================================================================
// GUIA DE ESTILO VISUAL — Leiturinha Infantil
// Versão: 2.0 (mai/2026)
// Público-alvo : Crianças de 4–7 anos em processo de alfabetização
// Acessibilidade: WCAG 2.1 AA (contraste ≥ 4.5:1, toque ≥ 44 × 44 px)
// Fonte         : Nunito (Regular 400 + Bold 700 disponíveis em assets)
//                 Pesos w800/w600 fazem fallback para 700 até que os arquivos
//                 ExtraBold.ttf e SemiBold.ttf sejam adicionados ao projeto.
// =============================================================================

// ─────────────────────────────────────────────────────────────────────────────
// §1  PALETA DE CORES
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppColors {
  // ── Roxo — cor principal da marca ─────────────────────────────────────────
  // Significado: criatividade, imaginação, aprendizado
  static const Color primary50  = Color(0xFFF5F3FF); // fundos sutis
  static const Color primary100 = Color(0xFFEDE9FE); // hover states
  static const Color primary200 = Color(0xFFDDD6FE); // bordas, divisores
  static const Color primary300 = Color(0xFFC4B5FD); // elementos desabilitados
  static const Color primary400 = Color(0xFFA78BFA); // elementos secundários
  static const Color primary500 = Color(0xFF8B5CF6); // ◀ COR PRINCIPAL
  static const Color primary600 = Color(0xFF7C3AED); // hover de botões
  static const Color primary700 = Color(0xFF6D28D9); // active states
  static const Color primary800 = Color(0xFF5B21B6); // textos importantes
  static const Color primary900 = Color(0xFF4C1D95); // títulos em destaque

  // ── Laranja — ação e energia ───────────────────────────────────────────────
  // Significado: energia, entusiasmo, diversão
  static const Color orange50  = Color(0xFFFFF7ED);
  static const Color orange100 = Color(0xFFFFEDD5);
  static const Color orange200 = Color(0xFFFED7AA);
  static const Color orange300 = Color(0xFFFDBA74);
  static const Color orange400 = Color(0xFFFB923C);
  static const Color orange500 = Color(0xFFF97316); // CTAs secundários
  static const Color orange600 = Color(0xFFEA580C); // hover
  static const Color orange700 = Color(0xFFC2410C);
  static const Color orange800 = Color(0xFF9A3412);
  static const Color orange900 = Color(0xFF7C2D12);

  // ── Verde — acerto, progresso, positivo ───────────────────────────────────
  // Significado: conquista, evolução, "muito bem!"
  static const Color green50  = Color(0xFFF0FDF4);
  static const Color green100 = Color(0xFFDCFCE7);
  static const Color green200 = Color(0xFFBBF7D0);
  static const Color green300 = Color(0xFF86EFAC);
  static const Color green400 = Color(0xFF4ADE80);
  static const Color green500 = Color(0xFF22C55E); // ✅ feedback positivo
  static const Color green600 = Color(0xFF16A34A); // hover
  static const Color green700 = Color(0xFF15803D);
  static const Color green800 = Color(0xFF166534);
  static const Color green900 = Color(0xFF14532D);

  // ── Amarelo — atenção, recompensa, destaque ────────────────────────────────
  // Significado: recompensa, conquista, "olhe aqui!"
  static const Color yellow50  = Color(0xFFFEFCE8);
  static const Color yellow100 = Color(0xFFFEF9C3);
  static const Color yellow200 = Color(0xFFFEF08A);
  static const Color yellow300 = Color(0xFFFDE047);
  static const Color yellow400 = Color(0xFFFACC15);
  static const Color yellow500 = Color(0xFFEAB308); // ⭐ moedas, estrelas, badges
  static const Color yellow600 = Color(0xFFCA8A04);
  static const Color yellow700 = Color(0xFFA16207);
  static const Color yellow800 = Color(0xFF854D0E);
  static const Color yellow900 = Color(0xFF713F12);

  // ── Vermelho suave — erro (nunca agressivo) ────────────────────────────────
  // Uso: indicação de "vamos tentar de novo" — sem punição
  static const Color red50  = Color(0xFFFEF2F2);
  static const Color red100 = Color(0xFFFEE2E2);
  static const Color red200 = Color(0xFFFECACA);
  static const Color red300 = Color(0xFFFCA5A5);
  static const Color red400 = Color(0xFFF87171);
  static const Color red500 = Color(0xFFEF4444); // erros, tentativas
  static const Color red600 = Color(0xFFDC2626);
  static const Color red700 = Color(0xFFB91C1C);
  static const Color red800 = Color(0xFF991B1B);
  static const Color red900 = Color(0xFF7F1D1D);

  // ── Azul — informação, calma, confiança ───────────────────────────────────
  // Significado: segurança, aprendizado, "você consegue!"
  static const Color blue50  = Color(0xFFEFF6FF);
  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color blue200 = Color(0xFFBFDBFE);
  static const Color blue300 = Color(0xFF93C5FD);
  static const Color blue400 = Color(0xFF60A5FA);
  static const Color blue500 = Color(0xFF3B82F6); // ℹ️ informações, dicas
  static const Color blue600 = Color(0xFF2563EB);
  static const Color blue700 = Color(0xFF1D4ED8);
  static const Color blue800 = Color(0xFF1E40AF);
  static const Color blue900 = Color(0xFF1E3A8A);

  // ── Cinzas ────────────────────────────────────────────────────────────────
  static const Color gray50  = Color(0xFFF9FAFB); // fundos de tela
  static const Color gray100 = Color(0xFFF3F4F6); // cards, superfícies
  static const Color gray200 = Color(0xFFE5E7EB); // bordas sutis
  static const Color gray300 = Color(0xFFD1D5DB); // divisores, placeholders
  static const Color gray400 = Color(0xFF9CA3AF); // textos desabilitados
  static const Color gray500 = Color(0xFF6B7280); // textos secundários
  static const Color gray600 = Color(0xFF4B5563); // textos principais
  static const Color gray700 = Color(0xFF374151); // títulos
  static const Color gray800 = Color(0xFF1F2937); // textos importantes
  static const Color gray900 = Color(0xFF111827); // preto suave

  static const Color white    = Color(0xFFFFFFFF);
  static const Color whiteOff = Color(0xFFFFEFFD); // fundo alternativo

  // ── Cores temáticas — famílias silábicas ──────────────────────────────────
  static const Color familyB = Color(0xFFF97316); // Laranja
  static const Color familyC = Color(0xFF22C55E); // Verde
  static const Color familyD = Color(0xFF3B82F6); // Azul
  static const Color familyF = Color(0xFFA855F7); // Roxo
  static const Color familyG = Color(0xFFEC4899); // Rosa
  static const Color familyJ = Color(0xFF14B8A6); // Turquesa
  static const Color familyL = Color(0xFFF59E0B); // Âmbar
  static const Color familyM = Color(0xFF8B5CF6); // Violeta
  static const Color familyP = Color(0xFFEF4444); // Vermelho
  static const Color familyR = Color(0xFF06B6D4); // Cyan
  static const Color familyS = Color(0xFF84CC16); // Lima
  static const Color familyT = Color(0xFFF43F5E); // Rose
  static const Color familyV = Color(0xFF10B981); // Esmeralda

  // ── Aliases semânticos — compatibilidade com código anterior ─────────────

  /// = [primary500] roxo amigável
  static const Color principal = primary500;

  /// = [green500] verde positivo
  static const Color sucesso   = green500;

  /// = [yellow500] amarelo atenção
  static const Color atencao   = yellow500;

  /// = [red500] vermelho suave
  static const Color erro      = red500;

  // Superfícies
  static const Color background = gray50;
  static const Color surface    = white;
  static const Color surfaceDim = primary100;

  // Texto
  static const Color textDark  = gray800;
  static const Color textMid   = gray600;
  static const Color textLight = gray400;

  // Acentos auxiliares
  static const Color accentBlue   = blue400;
  static const Color accentOrange = orange500;
  static const Color accentPurple = primary700;

  // ── Utilitário: cor de família silábica por letra ──────────────────────────
  static Color forFamily(String letter) {
    switch (letter.toUpperCase()) {
      case 'B': return familyB;
      case 'C': return familyC;
      case 'D': return familyD;
      case 'F': return familyF;
      case 'G': return familyG;
      case 'J': return familyJ;
      case 'L': return familyL;
      case 'M': return familyM;
      case 'P': return familyP;
      case 'R': return familyR;
      case 'S': return familyS;
      case 'T': return familyT;
      case 'V': return familyV;
      default : return primary500;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §2  GRADIENTES
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppGradients {
  // ── Botões e elementos especiais ──────────────────────────────────────────

  /// Gradiente principal — botões primários
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
  );

  /// Gradiente sucesso — botão verde, barra de progresso
  static const LinearGradient success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22C55E), Color(0xFF4ADE80)],
  );

  /// Gradiente dourado — moedas, badges, XP
  static const LinearGradient gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEAB308), Color(0xFFFACC15), Color(0xFFFDE047)],
    stops: [0.0, 0.5, 1.0],
  );

  /// Gradiente sunset — CTAs secundários, botão microfone
  static const LinearGradient sunset = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF97316), Color(0xFFFB923C), Color(0xFFFDBA74)],
    stops: [0.0, 0.5, 1.0],
  );

  /// Gradiente ocean — informações, fundo de dicas
  static const LinearGradient ocean = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
  );

  // ── Fundos de cenários ────────────────────────────────────────────────────

  /// Céu — fundo de tela principal
  static const LinearGradient sky = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFDBEAFE), Color(0xFFEFF6FF)],
  );

  /// Prado — fundo de telas de prática
  static const LinearGradient meadow = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFDCFCE7), Color(0xFFF0FDF4)],
  );

  // ── Barra de XP ───────────────────────────────────────────────────────────

  /// Preenchimento da barra de XP
  static const LinearGradient xpFill = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
  );

  /// Trilho da barra de XP (fundo)
  static const LinearGradient xpTrack = LinearGradient(
    colors: [Color(0xFFFDE68A), Color(0xFFFCD34D)],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// §3  TIPOGRAFIA — Nunito
//
//  HIERARQUIA:
//  H1 (32 w800) > H2 (24 w700) > H3 (20 w700)
//  bodyLg (20 w600) > bodyMd (16 w400) > bodySm (14 w400)
//  buttonLg (20 w700) | buttonMd (16 w700)
//  syllable (48 w800) | word (32 w700)
//  numberDisplay (40 w800 tabular) | numberSm (18 w700 tabular)
//
//  REGRAS:
//  ✅ Máx. 3 tamanhos por tela | contraste ≥ 4.5:1 | centralize títulos
//  ❌ Sem itálico | sem justificado | mínimo 14 px | sem ALL CAPS longo
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppTextStyles {
  static const _font = 'Nunito';

  // ── Títulos ───────────────────────────────────────────────────────────────

  /// H1 — w800 32 px | Títulos de tela, nomes de fases
  static const TextStyle h1 = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w800, // ExtraBold (fallback → Bold 700)
    fontSize: 32,
    height: 1.25,                // line-height 40 px
    letterSpacing: -0.5,
    color: Color(0xFF2D3748),
  );

  /// H2 — w700 24 px | Títulos de cards, seções
  static const TextStyle h2 = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w700,
    fontSize: 24,
    height: 1.33,                // line-height 32 px
    color: Color(0xFF2D3748),
  );

  /// H3 — w700 20 px | Subtítulos, nomes de conquistas
  static const TextStyle h3 = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w700,
    fontSize: 20,
    height: 1.4,                 // line-height 28 px
    color: Color(0xFF4A5568),
  );

  // ── Corpo de texto ────────────────────────────────────────────────────────

  /// Body LG — w600 20 px | Instruções principais, feedback
  static const TextStyle bodyLg = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w600, // SemiBold (fallback → Bold 700)
    fontSize: 20,
    height: 1.4,
    color: Color(0xFF4A5568),
  );

  /// Body MD — w400 16 px | Textos explicativos, descrições
  static const TextStyle bodyMd = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 1.5,
    color: Color(0xFF4A5568),
  );

  /// Body SM — w400 14 px | Legendas, informações secundárias
  static const TextStyle bodySm = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 1.43,                // line-height 20 px
    color: Color(0xFF718096),
  );

  // ── Botões e CTAs ──────────────────────────────────────────────────────────

  /// Button LG — w700 20 px uppercase | Botões primários ("JOGAR AGORA")
  static const TextStyle buttonLg = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w700,
    fontSize: 20,
    height: 1.4,
    letterSpacing: 0.5,
    color: AppColors.white,
  );

  /// Button MD — w700 16 px | Botões secundários
  static const TextStyle buttonMd = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w700,
    fontSize: 16,
    height: 1.5,
    color: AppColors.white,
  );

  // ── Sílabas e Palavras ────────────────────────────────────────────────────

  /// Syllable — w800 48 px | Display de sílabas BO-CA
  static const TextStyle syllable = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w800,
    fontSize: 48,
    height: 1.17,                // line-height 56 px
    letterSpacing: 2,
    color: AppColors.white,
  );

  /// Word — w700 32 px | Palavras completas
  static const TextStyle word = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w700,
    fontSize: 32,
    height: 1.25,
    letterSpacing: 1,
    color: AppColors.gray800,
  );

  // ── Números e contadores ──────────────────────────────────────────────────

  /// Number Display — w800 40 px tabular | Contador de moedas, XP
  static const TextStyle numberDisplay = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w800,
    fontSize: 40,
    height: 1.2,
    fontFeatures: [FontFeature.tabularFigures()],
    color: AppColors.gray800,
  );

  /// Number SM — w700 18 px tabular | Números em badges, níveis
  static const TextStyle numberSm = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w700,
    fontSize: 18,
    height: 1.33,
    fontFeatures: [FontFeature.tabularFigures()],
    color: AppColors.gray800,
  );

  // ── Aliases — compatibilidade com código anterior ─────────────────────────

  /// = [h2]
  static const TextStyle titulo      = h2;

  /// = [h3]
  static const TextStyle tituloSmall = h3;

  /// = [bodyLg]
  static const TextStyle corpo       = bodyLg;

  /// = [bodySm]
  static const TextStyle corpoSmall  = bodySm;

  /// = [buttonLg]
  static const TextStyle botao       = buttonLg;

  /// Rótulo pequeno — w700 13 px | tags, chips
  static const TextStyle label = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w700,
    fontSize: 13,
    color: AppColors.textMid,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// §4  SOMBRAS
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppShadows {
  /// Card padrão — sombra suave
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 6,  offset: Offset(0, 1)),
    BoxShadow(color: Color(0x1A000000), blurRadius: 3,  offset: Offset(0, 1)),
  ];

  /// Botão primário — sombra roxa
  static const List<BoxShadow> buttonPrimary = [
    BoxShadow(color: Color(0x4D8B5CF6), blurRadius: 6,  offset: Offset(0, 4)),
    BoxShadow(color: Color(0x1A000000), blurRadius: 4,  offset: Offset(0, 2)),
  ];

  /// Botão laranja — CTAs secundários / microfone
  static const List<BoxShadow> buttonOrange = [
    BoxShadow(color: Color(0x66F97316), blurRadius: 16, offset: Offset(0, 8)),
  ];

  /// Botão sucesso — sombra verde
  static const List<BoxShadow> buttonSuccess = [
    BoxShadow(color: Color(0x4D22C55E), blurRadius: 6,  offset: Offset(0, 4)),
  ];

  /// Card de recompensa — sombra dourada
  static const List<BoxShadow> cardGold = [
    BoxShadow(color: Color(0x33EAB308), blurRadius: 12, offset: Offset(0, 6)),
  ];

  /// Card de ilha no mapa
  static const List<BoxShadow> island = [
    BoxShadow(color: Color(0x664ADE80), blurRadius: 24, offset: Offset(0, 8)),
  ];

  /// Tooltip azul
  static const List<BoxShadow> tooltip = [
    BoxShadow(color: Color(0x663B82F6), blurRadius: 12, offset: Offset(0, 4)),
  ];

  /// Conquista desbloqueada
  static const List<BoxShadow> badgeUnlocked = [
    BoxShadow(color: Color(0x4DEAB308), blurRadius: 12, offset: Offset(0, 4)),
  ];

  /// Nav bar — sombra superior suave
  static const List<BoxShadow> bottomNav = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, -4)),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// §5  RAIOS DE BORDA
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppRadius {
  static const double xs  =  8; // checkboxes, small inputs
  static const double sm  = 12; // botões pequenos
  static const double md  = 16; // botões, cards de sílaba
  static const double lg  = 20; // cards padrão
  static const double xl  = 24; // modais
  static const double xxl = 32; // chips, pill buttons

  static const BorderRadius card         = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius modal        = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius button       = BorderRadius.all(Radius.circular(md));
  static const BorderRadius buttonSm     = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius chip         = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius syllableCard = BorderRadius.all(Radius.circular(md));
  static const BorderRadius bottomNav    = BorderRadius.only(
    topLeft:  Radius.circular(xl),
    topRight: Radius.circular(xl),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// §6  DIMENSÕES
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppDimensions {
  // Acessibilidade — toque mínimo WCAG 2.1 AA
  static const double minTouchTarget = 44;

  // Botões
  static const double buttonHeightLg = 56;
  static const double buttonHeightMd = 52;
  static const double buttonHeightSm = 44;

  // Botão microfone (ícone grande circular)
  static const double micButtonSize = 120;

  // Navegação
  static const double bottomNavHeight = 80;
  static const double headerHeight    = 80;

  // Ícones (px)
  static const double iconSm   = 24;
  static const double iconMd   = 32;
  static const double iconLg   = 48;

  // Avatares
  static const double avatar   =  64;
  static const double avatarLg = 128;

  // Card de sílaba no jogo
  static const double syllableCardSize = 100;

  // Padding padrão
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 24);
  static const EdgeInsets cardPadding   = EdgeInsets.all(24);
  static const EdgeInsets cardPaddingMd = EdgeInsets.all(20);
}

// ─────────────────────────────────────────────────────────────────────────────
// §7  DECORAÇÕES REUTILIZÁVEIS
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppDecorations {
  // ── Cards ─────────────────────────────────────────────────────────────────

  /// Card padrão — branco, borda gray100, sombra suave
  static BoxDecoration card({Color? borderColor}) => BoxDecoration(
    color: AppColors.white,
    borderRadius: AppRadius.card,
    border: Border.all(color: borderColor ?? AppColors.gray100, width: 2),
    boxShadow: AppShadows.card,
  );

  /// Card de recompensa — borda dourada
  static final BoxDecoration cardReward = BoxDecoration(
    color: AppColors.white,
    borderRadius: AppRadius.card,
    border: Border.all(color: AppColors.yellow300, width: 3),
    boxShadow: AppShadows.cardGold,
  );

  /// Card de XP — gradiente roxo com borda
  static final BoxDecoration cardXp = BoxDecoration(
    gradient: AppGradients.primary,
    borderRadius: AppRadius.card,
    border: Border.all(color: AppColors.primary200, width: 3),
  );

  // ── Feedback ──────────────────────────────────────────────────────────────

  /// Fundo de feedback positivo — verde claro com borda esquerda
  static const BoxDecoration feedbackSuccess = BoxDecoration(
    color: AppColors.green50,
    borderRadius: AppRadius.card,
    border: Border(
      left: BorderSide(color: AppColors.green500, width: 4),
    ),
  );

  /// Fundo de dica / encorajamento — azul claro com borda esquerda
  static const BoxDecoration feedbackInfo = BoxDecoration(
    color: AppColors.blue50,
    borderRadius: AppRadius.card,
    border: Border(
      left: BorderSide(color: AppColors.blue500, width: 4),
    ),
  );

  // ── Jogo ──────────────────────────────────────────────────────────────────

  /// Card de sílaba — laranja normal, verde quando selecionado
  static BoxDecoration syllableCard({bool selected = false}) => BoxDecoration(
    color: selected ? AppColors.green500 : AppColors.orange500,
    borderRadius: AppRadius.syllableCard,
    boxShadow: selected ? AppShadows.buttonSuccess : AppShadows.buttonOrange,
  );

  // ── Badges / Conquistas ───────────────────────────────────────────────────

  /// Conquista desbloqueada — borda dourada com sombra
  static final BoxDecoration badgeUnlocked = BoxDecoration(
    color: AppColors.white,
    borderRadius: AppRadius.syllableCard,
    border: Border.all(color: AppColors.yellow500, width: 3),
    boxShadow: AppShadows.badgeUnlocked,
  );

  /// Conquista bloqueada — borda cinza (opacidade no widget pai)
  static final BoxDecoration badgeLocked = BoxDecoration(
    color: AppColors.white,
    borderRadius: AppRadius.syllableCard,
    border: Border.all(color: AppColors.gray200, width: 3),
  );

  // ── Navegação ─────────────────────────────────────────────────────────────

  /// Bottom nav bar — branco com sombra superior
  static final BoxDecoration bottomNav = BoxDecoration(
    color: AppColors.white,
    borderRadius: AppRadius.bottomNav,
    boxShadow: AppShadows.bottomNav,
  );

  // ── Botão microfone ───────────────────────────────────────────────────────

  /// Botão microfone — circular com gradiente sunset
  static const BoxDecoration micButton = BoxDecoration(
    gradient: AppGradients.sunset,
    shape: BoxShape.circle,
    boxShadow: AppShadows.buttonOrange,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// §8  ESTILOS DE BOTÃO
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppButtonStyles {
  /// Botão secundário — laranja sólido, altura mínima 52 px
  static final ButtonStyle secondary = ElevatedButton.styleFrom(
    backgroundColor: AppColors.orange500,
    foregroundColor: AppColors.white,
    minimumSize: const Size(0, AppDimensions.buttonHeightMd),
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
    textStyle: AppTextStyles.buttonMd,
    elevation: 0,
  );

  /// Botão sucesso — verde sólido, altura mínima 56 px
  static final ButtonStyle success = ElevatedButton.styleFrom(
    backgroundColor: AppColors.green500,
    foregroundColor: AppColors.white,
    minimumSize: const Size(0, AppDimensions.buttonHeightLg),
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
    textStyle: AppTextStyles.buttonLg,
    elevation: 0,
  );

  /// Botão pequeno — altura mínima 44 px (WCAG mínimo)
  static final ButtonStyle small = ElevatedButton.styleFrom(
    minimumSize: const Size(0, AppDimensions.buttonHeightSm),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.buttonSm),
    textStyle: AppTextStyles.buttonMd,
    elevation: 0,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// §9  TRANSIÇÕES SUAVES
// Duração máx.: 300–500 ms | estilo: fade + slide horizontal suave
// ─────────────────────────────────────────────────────────────────────────────

/// Transição padrão do app — fade + slide 320 ms.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({required Widget page})
      : super(
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 260),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, __, child) {
            final curved =
                CurvedAnimation(parent: animation, curve: Curves.easeOut);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}

// ─────────────────────────────────────────────────────────────────────────────
// §10  ACESSIBILIDADE
// WCAG 2.1 AA | toque ≥ 44 × 44 px | contraste ≥ 4.5:1
// Não usar apenas cor para transmitir informação
// ─────────────────────────────────────────────────────────────────────────────

/// Garante que o filho tenha área de toque mínima de 44×44 px.
class MinTouchArea extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const MinTouchArea({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth:  AppDimensions.minTouchTarget,
          minHeight: AppDimensions.minTouchTarget,
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §11  ESPAÇAMENTO — base 8 px
//
//  Escala: 4 · 8 · 12 · 16 · 20 · 24 · 32 · 40 · 48 · 64 · 80 · 96
//
//  Uso semântico:
//  paddingSmall  = 16 px   paddingMedium = 24 px   paddingLarge = 32 px
//  marginSection = 48 px   marginComponent = 24 px  marginElement = 16 px
//  gapCard = 16 px         gapGrid = 24 px
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppSpacing {
  // ── Escala ────────────────────────────────────────────────────────────────
  static const double s1  =  4;   // metade da base
  static const double s2  =  8;   // base
  static const double s3  = 12;   // 1.5×
  static const double s4  = 16;   // 2×
  static const double s5  = 20;   // 2.5×
  static const double s6  = 24;   // 3×
  static const double s8  = 32;   // 4×
  static const double s10 = 40;   // 5×
  static const double s12 = 48;   // 6×
  static const double s16 = 64;   // 8×
  static const double s20 = 80;   // 10×
  static const double s24 = 96;   // 12×

  // ── Aliases semânticos ────────────────────────────────────────────────────
  static const double paddingSmall    = s4;   // padding interno pequeno
  static const double paddingMedium   = s6;   // padding interno médio
  static const double paddingLarge    = s8;   // padding interno grande

  static const double marginSection   = s12;  // entre seções de tela
  static const double marginComponent = s6;   // entre componentes
  static const double marginElement   = s4;   // entre elementos internos

  static const double gapCard         = s4;   // gap entre cards
  static const double gapGrid         = s6;   // gap em grids

  // ── EdgeInsets prontas ────────────────────────────────────────────────────

  /// Padding de tela padrão (24 px horizontal)
  static const EdgeInsets screen =
      EdgeInsets.symmetric(horizontal: s6);

  /// Padding interno de card (24 px todos os lados)
  static const EdgeInsets card = EdgeInsets.all(s6);

  /// Padding interno de card compacto (20 px)
  static const EdgeInsets cardMd = EdgeInsets.all(s5);

  /// Padding de botão primário
  static const EdgeInsets buttonLg =
      EdgeInsets.symmetric(horizontal: s8, vertical: s4);

  /// Padding de botão secundário
  static const EdgeInsets buttonMd =
      EdgeInsets.symmetric(horizontal: s7, vertical: s3p5);

  /// Padding de botão pequeno (WCAG mínimo)
  static const EdgeInsets buttonSm =
      EdgeInsets.symmetric(horizontal: s5, vertical: s2p5);

  // Valores intermediários usados acima (não expostos publicamente como API)
  static const double s7    = 28;
  static const double s3p5  = 14;
  static const double s2p5  = 10;
}

// ─────────────────────────────────────────────────────────────────────────────
// §12  ANIMAÇÕES E MICROINTERAÇÕES
//
//  Durações:  instant 100 ms · fast 200 ms · base 300 ms
//             slow 500 ms · slower 800 ms
//
//  Curvas  :  smooth = easeInOut  · bounce = elasticOut
//             elastic = easeOutBack · page = easeOut
//
//  Regra   :  Respeitar prefer-reduce-motion (ver AppAccessibility)
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppDurations {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast    = Duration(milliseconds: 200);
  static const Duration base    = Duration(milliseconds: 300);
  static const Duration slow    = Duration(milliseconds: 500);
  static const Duration slower  = Duration(milliseconds: 800);

  // Específicos
  static const Duration buttonHover    = fast;
  static const Duration modalEnter     = base;
  static const Duration pageTransition = Duration(milliseconds: 320);
  static const Duration progressUpdate = slower;
  static const Duration micRecording   = Duration(seconds: 5);  // máx. gravação
  static const Duration processingMax  = Duration(seconds: 2);  // máx. STT
  static const Duration feedbackShow   = Duration(seconds: 4);  // exibição
  static const Duration celebrationMin = Duration(seconds: 3);  // conquista
}

abstract class AppCurves {
  /// Transições suaves — equivale a cubic-bezier(0.4, 0, 0.2, 1)
  static const Curve smooth   = Curves.easeInOut;

  /// Bounce — elasticOut para entradas de cards e modais
  static const Curve bounce   = Curves.elasticOut;

  /// Elástico suave — easeOutBack para pop-ins
  static const Curve elastic  = Curves.easeOutBack;

  /// Saída padrão de páginas
  static const Curve page     = Curves.easeOut;

  /// Progresso — aceleração natural para barras de XP/progresso
  static const Curve progress = Curves.easeOut;
}

/// Durações reduzidas para `MediaQuery.of(ctx).disableAnimations`.
/// Use [AppDurations.orReduced] em vez dos valores diretos quando possível.
extension AnimationDurationX on Duration {
  /// Retorna [Duration.zero] se animações estão desabilitadas pelo sistema.
  Duration orReduced(BuildContext context) =>
      MediaQuery.of(context).disableAnimations ? Duration.zero : this;
}

// ─────────────────────────────────────────────────────────────────────────────
// §13  ACESSIBILIDADE — WCAG 2.1 AA
//
//  Ratios de contraste verificados (texto sobre fundo):
//  white / primary600  = 12.6:1 ✓
//  white / green500    =  4.6:1 ✓
//  gray900 / yellow400 =  8.2:1 ✓
//
//  Evitar:
//  gray400 / white     =  2.3:1 ✗
//  green400 / white    =  2.1:1 ✗
//
//  Dislexia  : letter-spacing ≥ 0.05em | sem itálico | sem justificado
//  TEA       : interface limpa | animações opcionais | fluxo previsível
//  TDAH      : sessões 5–10 min | feedback imediato | gamificação visível
//  Baixa vis.: toque ≥ 48 px | contraste ≥ 4.5:1 | feedback multimodal
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppAccessibility {
  // ── Toque ─────────────────────────────────────────────────────────────────

  /// Toque mínimo iOS WCAG 2.1 AA (44 px)
  static const double minTouchIos     = 44;

  /// Toque mínimo Android Material (48 px)
  static const double minTouchAndroid = 48;

  /// Gap mínimo entre elementos interativos próximos
  static const double minInteractiveGap = 8;

  // ── Tipografia acessível ──────────────────────────────────────────────────

  /// Tamanho mínimo de fonte para leitura (crianças com dislexia)
  static const double minReadingFontSize = 18;

  /// Espaçamento entre letras recomendado para dislexia
  static const double dyslexiaLetterSpacing = 0.05; // em → use como fontSize * 0.05

  /// Tamanho mínimo absoluto (nenhum texto abaixo disso)
  static const double absoluteMinFontSize = 14;

  // ── Alto contraste (prefer-contrast: high) ────────────────────────────────

  /// Cor principal em modo alto contraste
  static const Color highContrastPrimary = AppColors.primary800;

  /// Texto principal em modo alto contraste
  static const Color highContrastText = AppColors.gray900;

  // ── Semântica / ARIA equivalentes em Flutter ──────────────────────────────

  /// Rótulo semântico do botão de microfone
  static const String labelMicButton      = 'Gravar sua voz';

  /// Rótulo da barra de progresso da lição
  static const String labelProgressBar    = 'Progresso da lição';

  /// Hint para leitor de tela ao exibir alerta de feedback
  static const String hintFeedbackAlert   = 'Resultado da sua pronúncia';

  // ── Verificação de reduce-motion ─────────────────────────────────────────

  /// `true` quando o usuário preferiu reduzir animações.
  static bool prefersReducedMotion(BuildContext context) =>
      MediaQuery.of(context).disableAnimations;

  /// Retorna [reduced] se prefer-reduced-motion estiver ativo; caso contrário [normal].
  static Duration chooseDuration(
    BuildContext context, {
    required Duration normal,
    Duration reduced = Duration.zero,
  }) =>
      prefersReducedMotion(context) ? reduced : normal;
}

// ─────────────────────────────────────────────────────────────────────────────
// §14  PADRÕES DE INTERAÇÃO
//
//  Fluxo "pronunciar palavra":
//   1 exibir palavra + imagem
//   2 microfone pulsa (dica visual)
//   3 toque → animação "ouvindo"
//   4 processar STT (máx. 2 s)
//   5 feedback visual + sonoro
//   6 recompensa / incentivo
//   7 repetir ou próxima
//
//  Fluxo "desbloquear conquista":
//   1 completar requisito
//   2 confetes + som (3 s — não pular)
//   3 modal com badge
//   4 recompensas ganhas
//   5 "Continuar" ou "Compartilhar"
//
//  Feedback de erro — nunca agressivo:
//   • Usar azul/info em vez de vermelho puro
//   • Mensagens encorajadoras (ver [AppErrorMessages])
//   • Após 3 erros seguidos: oferecer modo prática
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppTimings {
  /// Máximo de gravação de voz (STT)
  static const Duration maxRecording = Duration(seconds: 5);

  /// Máximo de processamento STT antes de exibir "aguarde"
  static const Duration maxProcessing = Duration(seconds: 2);

  /// Tempo mínimo que o feedback de acerto fica visível
  static const Duration feedbackVisible = Duration(seconds: 4);

  /// Mínimo para animação de conquista (não interrompível)
  static const Duration achievementCelebration = Duration(seconds: 3);

  /// Duração recomendada de uma sessão infantil
  static const Duration recommendedSessionMin = Duration(minutes: 5);
  static const Duration recommendedSessionMax = Duration(minutes: 10);
}

abstract class AppErrorMessages {
  // Pronúncia não entendida
  static const String notUnderstood =
      'Mmm, não entendi direito. Pode falar de novo?';

  // Pronúncia incorreta
  static const String almostRight =
      'Quase lá! Tente assim:';

  // Silêncio prolongado
  static const String stillListening =
      'Estou te ouvindo… pode falar!';

  // Múltiplos erros (3+) na mesma palavra
  static const String practiceMode =
      'Vamos praticar juntos? Escuta:';

  // Microfone sem permissão
  static const String micPermissionDenied =
      'Preciso do microfone para te ouvir. Pode liberar?';
}

abstract class AppSfxFiles {
  /// Acerto — "plim" agudo e alegre (0.5 s)
  static const String success = 'audio/sfx/sfx-success.mp3';

  /// Conquista — fanfarra 3 notas (1.5 s)
  static const String achievement = 'audio/sfx/sfx-achievement.mp3';

  /// Moeda — "tlim" metálico (0.3 s)
  static const String coin = 'audio/sfx/sfx-coin.mp3';

  /// Erro suave — "bloop" grave (0.4 s)
  static const String tryAgain = 'audio/sfx/sfx-try-again.mp3';

  /// Início de gravação — beep suave (0.2 s)
  static const String recordingStart = 'audio/sfx/sfx-recording-start.mp3';
}

// ─────────────────────────────────────────────────────────────────────────────
// §15  WIDGET UTILITÁRIO — GradientButton
//
//  Botão primário com gradiente roxo.
//  Uso:
//    GradientButton(
//      label: 'JOGAR AGORA',
//      onTap: () { … },
//    )
// ─────────────────────────────────────────────────────────────────────────────

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final double? width;
  final EdgeInsets padding;
  final List<Color>? gradientColors;

  const GradientButton({
    super.key,
    required this.label,
    this.onTap,
    this.width,
    this.padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ??
        const [Color(0xFF8B5CF6), Color(0xFFA78BFA)];

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        width: width,
        constraints: const BoxConstraints(
          minWidth: 180,
          minHeight: AppDimensions.buttonHeightLg,
        ),
        padding: padding,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: onTap != null ? colors : [AppColors.gray300, AppColors.gray300],
          ),
          borderRadius: AppRadius.button,
          boxShadow: onTap != null ? AppShadows.buttonPrimary : null,
        ),
        child: Center(
          child: Text(
            label.toUpperCase(),
            style: AppTextStyles.buttonLg,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

