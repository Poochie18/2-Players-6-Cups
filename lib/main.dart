import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:two_players_six_cups/screens/main_menu.dart';
import 'package:two_players_six_cups/screens/difficulty_menu.dart';
import 'package:two_players_six_cups/screens/game_screen.dart';
import 'package:two_players_six_cups/screens/multiplayer_menu.dart';
import 'package:two_players_six_cups/screens/settings_screen.dart';
import 'package:two_players_six_cups/screens/local_multiplayer_setup.dart';
import 'package:two_players_six_cups/screens/online_multiplayer_menu.dart';
import 'package:two_players_six_cups/screens/create_game_screen.dart';
import 'package:two_players_six_cups/screens/join_game_screen.dart';
import 'l10n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Устанавливаем полноэкранный режим
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();

  static _MyAppState of(BuildContext context) {
    return context.findAncestorStateOfType<_MyAppState>()!;
  }
}

class _MyAppState extends State<MyApp> {
  Locale _locale = Locale('en');

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('languageCode') ?? 'en';
    setState(() {
      _locale = Locale(languageCode);
    });
  }

  void setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Two Players Six Cups',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.grey[100],
        textTheme: TextTheme(bodyMedium: TextStyle(color: Colors.blueGrey)),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      locale: _locale,
      supportedLocales: [
        Locale('en'),
        Locale('uk'),
        Locale('de'),
        Locale('zh'),
        Locale('fr'),
      ],
      localizationsDelegates: [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: '/',
      routes: {
        '/': (context) => MainMenu(),
        '/difficulty': (context) => DifficultyMenu(),
        '/multiplayer': (context) => MultiplayerMenu(),
        '/settings': (context) => SettingsScreen(),
        '/local_multiplayer': (context) => LocalMultiplayerSetup(),
        '/online_multiplayer': (context) => OnlineMultiplayerMenu(),
        '/create_game': (context) => CreateGameScreen(),
        '/join_game': (context) => JoinGameScreen(),
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
            // Для режима локальной игры или онлайн-игры
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