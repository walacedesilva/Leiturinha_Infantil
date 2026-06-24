import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:intl/date_symbol_data_local.dart';

import 'core/theme_provider.dart';
import 'splash_screen.dart';
import 'features/reading_game/domain/game_logic.dart';
import 'services/audio_manager.dart';
import 'services/gamification_service.dart';
import 'services/progress_service.dart';
import 'services/session_tracking_service.dart';
import 'services/avatar_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Silencia toda a saída de debugPrint em builds de produção (release).
  // Em desenvolvimento os logs continuam visíveis. Isso evita vazar dados
  // de diagnóstico (voz, conta, gameplay) no console em produção sem precisar
  // alterar as ~80 chamadas espalhadas pelo app.
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // Inicializar localizações de data em pt_BR
  await initializeDateFormatting('pt_BR', null);

  // Inicializar AudioManager e TTS em background
  AudioManager().preloadSyllables([]);

  // Travar em Portrait (padrão infantil)
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Inicializar SharedPreferences para o ProgressService e ThemeProvider
  final prefs = await SharedPreferences.getInstance();
  final themeProvider = await ThemeProvider.load();

  runApp(
    MultiProvider(
      providers: [
        // Tema visual (princesa ou carros)
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        // ProgressService depende de SharedPreferences
        ChangeNotifierProvider<ProgressService>(
          create: (_) => ProgressService(prefs),
        ),
        // GamificationService depende de SharedPreferences
        ChangeNotifierProvider<GamificationService>(
          create: (_) => GamificationService(prefs),
        ),
        // SessionTrackingService depende de SharedPreferences
        ChangeNotifierProvider<SessionTrackingService>(
          create: (_) => SessionTrackingService(prefs),
        ),
        // AvatarService — personalização do avatar
        ChangeNotifierProvider<AvatarService>(
          create: (_) => AvatarService(prefs),
        ),
        // GameLogic depende de ProgressService, AudioManager, GamificationService e SessionTrackingService
        ChangeNotifierProxyProvider3<ProgressService, GamificationService,
            SessionTrackingService, GameLogic>(
          create: (ctx) => GameLogic(
            ctx.read<ProgressService>(),
            AudioManager(),
            ctx.read<GamificationService>(),
            ctx.read<SessionTrackingService>(),
          ),
          update: (ctx, progressService, gamification, tracking, previous) =>
              previous ??
              GameLogic(progressService, AudioManager(), gamification, tracking),
        ),
      ],
      child: const LearnToReadApp(),
    ),
  );
}

class LearnToReadApp extends Sta