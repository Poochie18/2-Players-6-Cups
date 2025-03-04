import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'mainMenu': 'Main Menu',
      'singlePlayer': 'Single Player',
      'twoPlayers': 'Two Players',
      'settings': 'Settings',
      'exit': 'Exit',
      'playerName': 'Player Name',
      'playerGoesFirst': 'Player Goes First',
      'changeLanguage': 'Change Language',
      'selectLanguage': 'Select Language',
      'playAgain': 'Play Together',
      'back': 'Back',
      'winner': 'Winner',
      'draw': 'Draw!',
      'player1Turn': 'Player 1\'s Turn',
      'player2Turn': 'Player 2\'s Turn',
      'yourTurn': 'Your turn',
      'botTurn': 'Bot\'s Turn',
      'easy': 'Easy',
      'medium': 'Medium',
      'hard': 'Hard',
      'selectDifficulty': 'Select Difficulty',
      'restart': 'Restart',
      'bot': 'Bot',
      'turn': 'turn',
      'opponentTurn': 'Opponent\'s turn',
    },
    'uk': {
      'mainMenu': 'Меню',
      'singlePlayer': 'Одиночна гра',
      'twoPlayers': 'Два гравці',
      'settings': 'Налаштування',
      'exit': 'Вихід',
      'playerName': 'Ім\'я гравця',
      'playerGoesFirst': 'Хід гравця',
      'changeLanguage': 'Змінити мову',
      'selectLanguage': 'Оберіть мову',
      'playAgain': 'Грати знову',
      'back': 'Назад',
      'winner': 'Переміг',
      'draw': 'Нічия!',
      'player1Turn': 'Хід гравця 1',
      'player2Turn': 'Хід гравця 2',
      'yourTurn': 'Ваш хід',
      'botTurn': 'Хід бота',
      'easy': 'Легкий',
      'medium': 'Середній',
      'hard': 'Складний',
      'selectDifficulty': 'Оберіть складність',
      'restart': 'Заново',
      'bot': 'Бот',
      'turn': 'хід',
      'opponentTurn': 'Хід опонента',
    },
    'de': {
      'mainMenu': 'Hauptmenü',
      'singlePlayer': 'Einzelspieler',
      'twoPlayers': 'Zwei Spieler',
      'settings': 'Einstellungen',
      'exit': 'Beenden',
      'playerName': 'Spielername',
      'playerGoesFirst': 'Spieler beginnt',
      'changeLanguage': 'Sprache ändern',
      'selectLanguage': 'Sprache auswählen',
      'playAgain': 'Nochmal spielen',
      'back': 'Zurück',
      'winner': 'Gewinner',
      'draw': 'Unentschieden!',
      'player1Turn': 'Spieler 1 ist dran',
      'player2Turn': 'Spieler 2 ist dran',
      'yourTurn': 'Du bist dran',
      'botTurn': 'Bot ist dran',
      'easy': 'Einfach',
      'medium': 'Mittel',
      'hard': 'Schwer',
      'selectDifficulty': 'Schwierigkeit wählen',
      'restart': 'Neustart',
      'bot': 'Bot',
      'turn': 'ist dran',
      'opponentTurn': 'Gegner ist dran',
    },
    'zh': {
      'mainMenu': '主菜单',
      'singlePlayer': '单人游戏',
      'twoPlayers': '双人游戏',
      'settings': '设置',
      'exit': '退出',
      'playerName': '玩家名称',
      'playerGoesFirst': '玩家先手',
      'changeLanguage': '更改语言',
      'selectLanguage': '选择语言',
      'playAgain': '再玩一次',
      'back': '返回',
      'winner': '获胜者',
      'draw': '平局！',
      'player1Turn': '玩家1回合',
      'player2Turn': '玩家2回合',
      'yourTurn': '轮到你了',
      'botTurn': '机器人回合',
      'easy': '简单',
      'medium': '中等',
      'hard': '困难',
      'selectDifficulty': '选择难度',
      'restart': '重新开始',
      'bot': '机器人',
      'turn': '回合',
      'opponentTurn': '对手回合',
    },
    'fr': {
      'mainMenu': 'Menu Principal',
      'singlePlayer': 'Un Joueur',
      'twoPlayers': 'Deux Joueurs',
      'settings': 'Paramètres',
      'exit': 'Quitter',
      'playerName': 'Nom du Joueur',
      'playerGoesFirst': 'Le Joueur Commence',
      'changeLanguage': 'Changer de Langue',
      'selectLanguage': 'Sélectionner la Langue',
      'playAgain': 'Rejouer',
      'back': 'Retour',
      'winner': 'Gagnant',
      'draw': 'Match Nul !',
      'player1Turn': 'Tour du Joueur 1',
      'player2Turn': 'Tour du Joueur 2',
      'yourTurn': 'À votre tour',
      'botTurn': 'Tour du Bot',
      'easy': 'Facile',
      'medium': 'Moyen',
      'hard': 'Difficile',
      'selectDifficulty': 'Sélectionner la Difficulté',
      'restart': 'Redémarrer',
      'bot': 'Bot',
      'turn': 'tour',
      'opponentTurn': 'Tour de l\'adversaire',
    },
  };

  String get mainMenu => _localizedValues[locale.languageCode]!['mainMenu']!;
  String get singlePlayer => _localizedValues[locale.languageCode]!['singlePlayer']!;
  String get twoPlayers => _localizedValues[locale.languageCode]!['twoPlayers']!;
  String get settings => _localizedValues[locale.languageCode]!['settings']!;
  String get exit => _localizedValues[locale.languageCode]!['exit']!;
  String get playerName => _localizedValues[locale.languageCode]!['playerName']!;
  String get playerGoesFirst => _localizedValues[locale.languageCode]!['playerGoesFirst']!;
  String get changeLanguage => _localizedValues[locale.languageCode]!['changeLanguage']!;
  String get selectLanguage => _localizedValues[locale.languageCode]!['selectLanguage']!;
  String get playAgain => _localizedValues[locale.languageCode]!['playAgain']!;
  String get back => _localizedValues[locale.languageCode]!['back']!;
  String get winner => _localizedValues[locale.languageCode]!['winner']!;
  String get draw => _localizedValues[locale.languageCode]!['draw']!;
  String get player1Turn => _localizedValues[locale.languageCode]!['player1Turn']!;
  String get player2Turn => _localizedValues[locale.languageCode]!['player2Turn']!;
  String get yourTurn => _localizedValues[locale.languageCode]!['yourTurn']!;
  String get botTurn => _localizedValues[locale.languageCode]!['botTurn']!;
  String get easy => _localizedValues[locale.languageCode]!['easy']!;
  String get medium => _localizedValues[locale.languageCode]!['medium']!;
  String get hard => _localizedValues[locale.languageCode]!['hard']!;
  String get selectDifficulty => _localizedValues[locale.languageCode]!['selectDifficulty']!;
  String get restart => _localizedValues[locale.languageCode]!['restart']!;
  String get bot => _localizedValues[locale.languageCode]!['bot']!;
  String get turn => _localizedValues[locale.languageCode]!['turn']!;
  String get opponentTurn => _localizedValues[locale.languageCode]!['opponentTurn']!;

  String getBotName(String difficulty) {
    final difficultyText = difficulty == 'easy' ? easy :
                          difficulty == 'medium' ? medium :
                          difficulty == 'hard' ? hard : easy;
    return 'Bot ($difficultyText)';
  }

  String getString(String key) {
    return _localizedValues[locale.languageCode]![key] ?? key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'uk', 'de', 'zh', 'fr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
} 