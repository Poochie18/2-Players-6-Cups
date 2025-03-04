import 'package:flutter/material.dart';

class AppTextStyles {
  // Заголовки
  static TextStyle mainTitle = TextStyle(
    fontSize: 36, // Уменьшенный размер для заголовка "Two Players, Six Cups"
    color: Colors.blueGrey,
    fontWeight: FontWeight.bold,
    shadows: [Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 2)],
  );

  static TextStyle screenTitle = TextStyle(
    fontSize: 32, // Уменьшенный размер для заголовка "Choose Difficulty"
    color: Colors.blueGrey,
    fontWeight: FontWeight.bold,
    shadows: [Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 2)],
  );

  // Кнопки
  static TextStyle buttonText = TextStyle(
    color: Colors.white, 
    fontSize: 22, // Увеличенный размер для кнопок в меню
  );

  static TextStyle difficultyButtonText = TextStyle(
    color: Colors.white, 
    fontSize: 24, // Увеличенный размер для кнопок выбора сложности
  );

  // Игровой процесс
  static TextStyle playerTurnText = TextStyle(
    fontSize: 20,
    color: Colors.black,
    fontWeight: FontWeight.bold,
    shadows: [Shadow(color: Colors.white, offset: Offset(1, 1), blurRadius: 2)],
  );

  static TextStyle winnerText = TextStyle(
    fontSize: 32, 
    fontWeight: FontWeight.bold, 
    color: Colors.white, 
    shadows: [Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 2)],
  );

  // Настройки
  static TextStyle settingsLabel = TextStyle(
    fontSize: 18, 
    color: Colors.blueGrey,
  );

  static TextStyle popupTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.blueGrey,
    shadows: [Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 2)],
  );

  static TextStyle turnIndicator = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.green[800],
    shadows: [Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 2)],
  );
} 