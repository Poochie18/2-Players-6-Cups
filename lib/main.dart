import 'package:flutter/material.dart';
import 'package:two_players_six_cups/screens/main_menu.dart';
import 'package:two_players_six_cups/screens/difficulty_menu.dart';
import 'package:two_players_six_cups/screens/game_screen.dart';
import 'package:two_players_six_cups/screens/multiplayer_menu.dart';
import 'package:two_players_six_cups/screens/settings_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2 Players 6 Cups',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.grey[100],
        textTheme: TextTheme(bodyMedium: TextStyle(color: Colors.blueGrey)),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => MainMenu(),
        '/difficulty': (context) => DifficultyMenu(),
        '/game': (context) => GameScreen(gameMode: 'single', botDifficulty: ModalRoute.of(context)!.settings.arguments as String?),
        '/multiplayer': (context) => MultiplayerMenu(),
        '/settings': (context) => SettingsScreen(),
      },
    );
  }
}