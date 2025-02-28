import 'dart:math';

class GameLogic {
  static const List<List<int>> _winningCombos = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8],
    [0, 3, 6], [1, 4, 7], [2, 5, 8],
    [0, 4, 8], [2, 4, 6],
  ];

  static bool checkWin(List<List<Map<String, dynamic>?>> board, int player) {
    for (var combo in _winningCombos) {
      if (combo.every((index) => board[index ~/ 3][index % 3] != null && board[index ~/ 3][index % 3]!['player'] == player)) {
        return true;
      }
    }
    return false;
  }

  static bool canPlace(String newSize, Map<String, dynamic>? existingCup, int currentPlayer) {
    if (newSize == 'small') return false;
    if (existingCup == null) return true; // Можно размещать на пустой клетке
    final isOwnCup = existingCup['player'] == currentPlayer; // Проверяем, свои ли это чашки
    if (isOwnCup) {
      return false; // Нельзя перекрывать свои чашки
    }
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

  static bool canPlayerMove(List<List<Map<String, dynamic>?>> board, List<Map<String, dynamic>> cups, int player) {
    for (int i = 0; i < 9; i++) {
      final row = i ~/ 3;
      final col = i % 3;
      final cell = board[row][col];
      for (var cup in cups) {
        if (canPlace(cup['size'], cell, player)) {
          return true;
        }
      }
    }
    return false;
  }
}