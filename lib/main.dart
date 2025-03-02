import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:two_players_six_cups/screens/main_menu.dart';
import 'package:two_players_six_cups/screens/difficulty_menu.dart';
import 'package:two_players_six_cups/screens/game_screen.dart';
import 'package:two_players_six_cups/screens/multiplayer_menu.dart';
import 'package:two_players_six_cups/screens/settings_screen.dart';
import 'package:two_players_six_cups/screens/local_multiplayer_setup.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Устанавливаем полноэкранный режим
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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
        '/multiplayer': (context) => MultiplayerMenu(),
        '/settings': (context) => SettingsScreen(),
        '/local_multiplayer': (context) => LocalMultiplayerSetup(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/game') {
          final args = settings.arguments;
          
          if (args is String) {
            // Для режима одиночной игры, где передается только сложность бота
            return MaterialPageRoute(
              builder: (context) => GameScreen(
                gameMode: 'single',
                botDifficulty: args,
              ),
            );
          } else if (args is Map<String, dynamic>) {
            // Для режима локальной игры, где передается карта параметров
            return MaterialPageRoute(
              builder: (context) => GameScreen(
                gameMode: args['gameMode'] ?? 'single',
                botDifficulty: args['botDifficulty'],
                roomCode: args['roomCode'],
                hostIp: args['hostIp'],
              ),
              settings: settings,
            );
          }
        }
        
        // Если маршрут не распознан, возвращаем страницу ошибки
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Text('Ошибка навигации'),
            ),
          ),
        );
      },
    );
  }
}