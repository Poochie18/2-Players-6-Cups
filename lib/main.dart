import 'package:flutter/material.dart';
import 'screens/main_menu.dart';
import 'screens/difficulty_menu.dart';
import 'screens/multiplayer_menu.dart';
import 'screens/game_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Two Players, Six Cups',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => MainMenu(),
        '/difficulty': (context) => DifficultyMenu(),
        '/multiplayer': (context) => MultiplayerMenu(),
        '/game': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return GameScreen(
            gameMode: args?['gameMode'] as String? ?? 'single',
            botDifficulty: args?['botDifficulty'] as String?,
            roomCode: args?['roomCode'] as String?,
            isLocal: args?['isLocal'] as bool?,
            isHost: args?['isHost'] as bool?,
          );
        },
        '/settings': (context) => SettingsScreen(),
      },
    );
  }
}