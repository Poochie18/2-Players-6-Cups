import 'dart:math';

class BotLogic {
  final List<List<Map<String, dynamic>?>> board;
  final String cupSize;
  final String difficulty;

  BotLogic(this.board, this.cupSize, this.difficulty);

  bool canPlace(String newSize, String existingSize, int currentPlayer) {
    if (newSize == 'small') return false;
    final isOwnCup = existingSize != null && currentPlayer == (existingSize == 'small' ? 1 : existingSize == 'medium' ? 1 : 1); // Проверяем, свои ли это чашки
    if (isOwnCup) {
      return false; // Нельзя перекрывать свои чашки
    }
    // Всегда можно перекрывать вражеские чашки по фиксированным правилам
    if (existingSize == 'small') {
      return newSize == 'medium' || newSize == 'large';
    }
    if (existingSize == 'medium') {
      return newSize == 'large';
    }
    return false;
  }

  int? findBestMove(List<int> freeCells, List<int> overwriteCells, int currentPlayer) {
    final random = Random();
    final winningCombos = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6],
    ];

    // Оценка позиции для выбора лучшего хода
    int evaluateMove(int index, int player) {
      int score = 0;
      for (var combo in winningCombos) {
        if (combo.contains(index)) {
          int playerCount = 0, botCount = 0;
          for (var i in combo) {
            final cell = board[i ~/ 3][i % 3];
            if (cell != null && cell['player'] == 1) playerCount++;
            if (cell != null && cell['player'] == 2) botCount++;
          }
          if (player == 2) {
            if (botCount == 2) score += 1000; // Высокий приоритет для победы
            if (playerCount == 2) score += 800; // Блокировка игрока
            if (botCount == 1) score += 200; // Подготовка к победе
            if (playerCount == 1) score += 100; // Угроза игрока
          } else {
            if (playerCount == 2) score += 800; // Блокировка бота
            if (botCount == 2) score += 1000; // Стремление к победе
            if (playerCount == 1) score += 200; // Подготовка к победе
            if (botCount == 1) score += 100; // Угроза бота
          }
        }
      }
      return score;
    }

    // Hard: Ищем победу или лучший стратегический ход
    if (difficulty == 'hard') {
      int bestScore = -1;
      int? bestMove;
      for (var index in freeCells + overwriteCells) {
        if (canPlaceAt(index, 2, currentPlayer)) {
          int score = evaluateMove(index, 2);
          if (score > bestScore) {
            bestScore = score;
            bestMove = index;
          }
        }
      }
      if (bestMove != null) return bestMove;

      for (var combo in winningCombos) {
        int botCount = 0;
        int? emptyIndex;
        for (var index in combo) {
          final cell = board[index ~/ 3][index % 3];
          if (cell != null && cell['player'] == 2) {
            botCount++;
          } else if (canPlaceAt(index, 2, currentPlayer)) {
            emptyIndex = index;
          }
        }
        if (botCount == 2 && emptyIndex != null && (freeCells.contains(emptyIndex) || overwriteCells.contains(emptyIndex))) {
          return emptyIndex;
        }
      }
    }

    // Medium/Hard: Блокируем игрока
    for (var combo in winningCombos) {
      int playerCount = 0;
      int? emptyIndex;
      for (var index in combo) {
        final cell = board[index ~/ 3][index % 3];
        if (cell != null && cell['player'] == 1) {
          playerCount++;
        } else if (canPlaceAt(index, 2, currentPlayer)) {
          emptyIndex = index;
        }
      }
      if (playerCount == 2 && emptyIndex != null && (freeCells.contains(emptyIndex) || overwriteCells.contains(emptyIndex))) {
        return emptyIndex;
      }
    }

    // Medium/Hard: Перекрываем чашки игрока
    if (difficulty == 'medium' || difficulty == 'hard') {
      int bestScore = -1;
      int? bestMove;
      for (var index in overwriteCells) {
        if (canPlaceAt(index, 2, currentPlayer)) {
          int score = evaluateMove(index, 2);
          if (score > bestScore) {
            bestScore = score;
            bestMove = index;
          }
        }
      }
      if (bestMove != null) return bestMove;
    }

    // Easy или случайный ход, если нет стратегических ходов
    final allCells = freeCells + overwriteCells;
    if (allCells.isNotEmpty) {
      return allCells[random.nextInt(allCells.length)];
    }
    return null;
  }

  bool canPlaceAt(int index, int player, int currentPlayer) {
    final row = index ~/ 3;
    final col = index % 3;
    final existingCup = board[row][col];
    if (existingCup == null) return true;
    return canPlace(cupSize, existingCup['size'], player);
  }
}