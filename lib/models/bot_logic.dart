class BotLogic {
  final List<List<Map<String, dynamic>?>> board;
  final List<Map<String, dynamic>> cups;
  final String difficulty;

  BotLogic(this.board, this.cups, this.difficulty);

  Map<String, dynamic>? findBestMove(List<int> freeCells, List<int> overwriteCells, int player, int cupsLeft) {
    if (freeCells.isNotEmpty) {
      return {
        'moveIndex': freeCells[0],
        'size': cups[0]['size'], // Выбираем первую доступную чашку
      };
    } else if (overwriteCells.isNotEmpty) {
      return {
        'moveIndex': overwriteCells[0],
        'size': cups.firstWhere((cup) => cup['size'] == 'large', orElse: () => cups[0])['size'], // Предпочитаем большую чашку, иначе первую
      };
    }
    return null;
  }
}