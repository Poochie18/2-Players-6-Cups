import 'dart:math';

class BotLogic {
  final List<List<Map<String, dynamic>?>> board;
  final List<Map<String, dynamic>> botCups; // Все чашки бота
  final String difficulty;

  BotLogic(this.board, this.botCups, this.difficulty);

  bool canPlace(String newSize, Map<String, dynamic>? existingCup, int currentPlayer) {
    if (newSize == 'small') return false;
    if (existingCup == null) return true; // Можно размещать на пустой клетке
    final isOwnCup = existingCup['player'] == currentPlayer; // Проверяем, свои ли это чашки
    if (isOwnCup) {
      return false; // Нельзя перекрывать свои чашки
    }
    // Всегда можно перекрывать вражеские чашки по фиксированным правилам
    final existingSize = existingCup['size'];
    if (existingSize == 'small') {
      return newSize == 'medium' || newSize == 'large';
    }
    if (existingSize == 'medium') {
      return newSize == 'large';
    }
    if (existingSize == 'large') {
      return false; // Большие чашки нельзя перекрывать
    }
    return false;
  }

  Map<String, dynamic>? findBestMove(List<int> freeCells, List<int> overwriteCells, int currentPlayer, int botCupCount) {
    final random = Random();
    final winningCombos = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6],
    ];

    // Оценка позиции для выбора лучшего хода и чашки
    Map<String, dynamic>? bestMove = null;
    int bestScore = -1;

    // Проверяем каждую комбинацию чашки и клетки
    for (var cup in botCups) {
      final cupSize = cup['size'];
      for (var index in freeCells + overwriteCells) {
        if (canPlaceAt(index, 2, currentPlayer, cupSize)) {
          int score = evaluateMove(index, 2, cupSize, botCupCount);
          if (score > bestScore) {
            bestScore = score;
            bestMove = {'moveIndex': index, 'size': cupSize, 'player': 2}; // Сохраняем лучшую чашку и ход
          }
        }
      }
    }

    // Если нет стратегических ходов, используем случайный ход для Easy
    if (bestMove == null && difficulty == 'easy') {
      if (freeCells.isNotEmpty || overwriteCells.isNotEmpty) {
        final allCells = freeCells + overwriteCells;
        final index = allCells[random.nextInt(allCells.length)];
        final cup = botCups[random.nextInt(botCups.length)]; // Случайная чашка
        return {'moveIndex': index, 'size': cup['size'], 'player': 2};
      }
      return null;
    }

    // Для Medium и Hard: приоритет победе, блокировке и перекрытию
    if (bestMove == null && (difficulty == 'medium' || difficulty == 'hard')) {
      // Приоритет победе (максимальный)
      for (var combo in winningCombos) {
        int botCount = 0;
        int? emptyIndex;
        for (var index in combo) {
          final cell = board[index ~/ 3][index % 3];
          if (cell != null && cell['player'] == 2) {
            botCount++;
          } else if (freeCells.contains(index) || overwriteCells.contains(index)) {
            emptyIndex = index;
          }
        }
        if (botCount == 2 && emptyIndex != null) {
          for (var cup in botCups) {
            if (canPlaceAt(emptyIndex, 2, currentPlayer, cup['size'])) {
              return {'moveIndex': emptyIndex, 'size': cup['size'], 'player': 2};
            }
          }
        }
      }

      // Блокировка игрока (высокий приоритет)
      for (var combo in winningCombos) {
        int playerCount = 0;
        int? emptyIndex;
        for (var index in combo) {
          final cell = board[index ~/ 3][index % 3];
          if (cell != null && cell['player'] == 1) {
            playerCount++;
          } else if (freeCells.contains(index) || overwriteCells.contains(index)) {
            emptyIndex = index;
          }
        }
        if (playerCount == 2 && emptyIndex != null) {
          for (var cup in botCups) {
            if (canPlaceAt(emptyIndex, 2, currentPlayer, cup['size'])) {
              return {'moveIndex': emptyIndex, 'size': cup['size'], 'player': 2};
            }
          }
        }
      }

      // Перекрытие вражеских чашек (средний приоритет)
      for (var index in overwriteCells) {
        final cell = board[index ~/ 3][index % 3];
        if (cell != null && cell['player'] == 1) {
          for (var cup in botCups) {
            if (canPlaceAt(index, 2, currentPlayer, cup['size'])) {
              return {'moveIndex': index, 'size': cup['size'], 'player': 2};
            }
          }
        }
      }

      // Случайный ход, если нет стратегических действий
      if (freeCells.isNotEmpty || overwriteCells.isNotEmpty) {
        final allCells = freeCells + overwriteCells;
        final index = allCells[random.nextInt(allCells.length)];
        final cup = botCups[random.nextInt(botCups.length)]; // Случайная чашка
        return {'moveIndex': index, 'size': cup['size'], 'player': 2};
      }
    }

    return bestMove;
  }

  bool canPlaceAt(int index, int player, int currentPlayer, String cupSize) {
    final row = index ~/ 3;
    final col = index % 3;
    final existingCup = board[row][col];
    if (existingCup == null) return true;
    return canPlace(cupSize, existingCup, player);
  }

  int evaluateMove(int index, int player, String cupSize, int botCupCount) {
    int score = 0;
    final winningCombos = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6],
    ];
    for (var combo in winningCombos) {
      if (combo.contains(index)) {
        int playerCount = 0, botCount = 0;
        for (var i in combo) {
          final cell = board[i ~/ 3][i % 3];
          if (cell != null && cell['player'] == 1) playerCount++;
          if (cell != null && cell['player'] == 2) botCount++;
        }
        if (player == 2) {
          // Максимальный приоритет победе
          if (botCount == 2) score += 5000; // Увеличен приоритет победы
          if (botCount == 1) score += 2000; // Увеличена подготовка к победе
          // Высокий приоритет блокировке игрока
          if (playerCount == 2) score += 4000; // Увеличен приоритет блокировки
          if (playerCount == 1) score += 1500; // Увеличена активная угроза
          // Оценка перекрытия вражеских чашек
          final row = index ~/ 3;
          final col = index % 3;
          final cell = board[row][col];
          if (cell != null && cell['player'] == 1) {
            if (cupSize == 'large' && cell['size'] == 'medium') score += 1000;
            else if (cupSize == 'medium' && cell['size'] == 'small') score += 1000;
            else if (cupSize == 'large' && cell['size'] == 'small') score += 1000;
          }
          // Оценка в зависимости от сложности и стадии игры
          if (difficulty == 'hard') {
            if (botCupCount >= 4) { // Начало игры
              score += 800; // Агрессивное начало
            } else if (botCupCount >= 2) { // Середина игры
              score += 1000; // Активное перекрытие и блокировка
            } else { // Конец игры
              score += 1500; // Максимальная агрессия для победы
            }
          } else if (difficulty == 'medium') {
            if (botCupCount >= 4) score += 500; // Меньшая агрессия в начале
            else if (botCupCount >= 2) score += 700; // Умеренная стратегия
            else score += 900; // Умеренная агрессия в конце
          }
        } else {
          if (playerCount == 2) score += 4000; // Блокировка бота
          if (botCount == 2) score += 5000; // Стремление к победе
          if (playerCount == 1) score += 2000; // Подготовка к победе
          if (botCount == 1) score += 1500; // Угроза бота
        }
      }
    }
    // Уменьшаем вероятность случайных ходов для Easy
    if (difficulty == 'easy') score = score ~/ 3; // Уменьшаем оценку для случайных ходов
    return score;
  }
}