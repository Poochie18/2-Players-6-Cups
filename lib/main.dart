import 'package:flutter/material.dart';
import 'screens/main_menu.dart';
import 'screens/difficulty_menu.dart';
import 'screens/multiplayer_menu.dart';
import 'screens/single_player_game_screen.dart';
import 'screens/multiplayer_game_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/ui_style.dart'; // Добавляем импорт

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Two Players, Six Cups',
      theme: ThemeData(
        primarySwatch: MaterialColor(UIStyle.primaryColor.value, {
          50: UIStyle.primaryColor.withOpacity(0.1),
          100: UIStyle.primaryColor.withOpacity(0.2),
          200: UIStyle.primaryColor.withOpacity(0.3),
          300: UIStyle.primaryColor.withOpacity(0.4),
          400: UIStyle.primaryColor.withOpacity(0.5),
          500: UIStyle.primaryColor.withOpacity(0.6),
          600: UIStyle.primaryColor.withOpacity(0.7),
          700: UIStyle.primaryColor.withOpacity(0.8),
          800: UIStyle.primaryColor.withOpacity(0.9),
          900: UIStyle.primaryColor,
        }),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => MainMenu(),
        '/difficulty': (context) => DifficultyMenu(),
        '/multiplayer': (context) => MultiplayerMenu(),
        '/game': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          final gameMode = args?['gameMode'] as String? ?? 'single';
          if (gameMode == 'single') {
            return SinglePlayerGameScreen(botDifficulty: args?['botDifficulty'] as String? ?? 'easy');
          } else {
            return MultiplayerGameScreen(
              roomCode: args?['roomCode'] as String? ?? 'LOCAL123',
              isHost: args?['isHost'] as bool? ?? false,
              isJoining: args?['isJoining'] as bool? ?? false,
            );
          }
        },
        '/settings': (context) => SettingsScreen(),
      },
    );
  }
}