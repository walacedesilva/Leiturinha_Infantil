import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'features/reading_game/domain/game_logic.dart';
import 'features/reading_game/presentation/screens/game_screen.dart';
import 'services/audio_manager.dart';
import 'services/storage_service.dart';

void main() async {
  // Garantir que a inicialização de serviços do Flutter está feita
  WidgetsFlutterBinding.ensureInitialized();

  // Travar orientação em Portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inicializar serviços vitais
  final storageService = StorageService();
  await storageService.init();

  final audioManager = AudioManager();
  await audioManager.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        Provider<AudioManager>.value(value: audioManager),
        ChangeNotifierProvider<GameLogic>(
          create: (context) => GameLogic(storageService, audioManager),
        ),
      ],
      child: const LeiturinhaApp(),
    ),
  );
}

class LeiturinhaApp extends StatelessWidget {
  const LeiturinhaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leiturinha Infantil',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const GameScreen(),
    );
  }
}
