import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/reading_game/presentation/screens/menu_screen.dart';
import 'features/reading_game/domain/game_logic.dart';
import 'services/audio_manager.dart';
import 'services/progress_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Travar em Portrait (padrão infantil)
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Inicializar SharedPreferences para o ProgressService
  final prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
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
    return MaterialApp(
      title: 'Aprenda a Ler',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Nunito',
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
      ),
      home: const MenuScreen(),
    );
  }
}