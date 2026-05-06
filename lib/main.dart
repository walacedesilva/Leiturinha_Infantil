import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme_provider.dart';
import 'features/reading_game/presentation/screens/menu_screen.dart';
import 'features/reading_game/domain/game_logic.dart';
import 'services/audio_manager.dart';
import 'services/progress_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        // GameLogic depende de ProgressService e AudioManager (singleton)
        ChangeNotifierProxyProvider<ProgressService, GameLogic>(
          create: (ctx) => GameLogic(
            ctx.read<ProgressService>(),
            AudioManager(),
          ),
          update: (ctx, progressService, previous) =>
              previous ?? GameLogic(progressService, AudioManager()),
        ),
      ],
      child: const LearnToReadApp(),
    ),
  );
}

class LearnToReadApp extends StatelessWidget {
  const LearnToReadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Aprenda a Ler',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.themeData,
          home: const MenuScreen(),
        );
      },
    );
  }
}