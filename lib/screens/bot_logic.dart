import 'dart:math';

class BotLogic {
  final List<List<Map<String, dynamic>?>> board;
  final List<Map<String, dynamic>> botCups; // Все чашки бота
  final String difficulty;
  final Random random = Random();

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
    final winningCombos = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6],
    ];

    // Для "easy" режима иногда делаем случайный ход
    if (difficulty == 'easy' && random.nextDouble() < 0.4) {
      return makeRandomMove(freeCells, overwriteCells, currentPlayer);
    }

    // Шаг 1: Проверка на возможность победы в 1 ход
    var winMove = findWinningOrBlockingMove(winningCombos, 2, freeCells, overwriteCells);
    if (winMove != null && (difficulty != 'easy' || random.nextDouble() > 0.3)) {
      return winMove;
    }

    // Шаг 2: Проверка на необходимость блокировки победы противника
    var blockMove = findWinningOrBlockingMove(winningCombos, 1, freeCells, overwriteCells);
    if (blockMove != null && (difficulty != 'easy' || random.nextDouble() > 0.2)) {
      return blockMove;
    }

    // Шаг 3: Перекрытие стратегических чашек противника
    var overwriteMove = findStrategicOverwriteMove(winningCombos, overwriteCells);
    if (overwriteMove != null && (difficulty != 'easy' || random.nextDouble() > 0.25)) {
      return overwriteMove;
    }

    // Для "hard" бота делаем дополнительный прогноз на 2 хода вперед
    if (difficulty == 'hard' && botCupCount > 1) {
      var strategicMove = findStrategicMove(freeCells, overwriteCells, currentPlayer);
      if (strategicMove != null) {
        return strategicMove;
      }
    }

    // Оценка позиции для выбора лучшего хода и чашки
    Map<String, dynamic>? bestMove = null;
    int bestScore = -1;

    // Анализируем все возможные ходы
    for (var cup in botCups) {
      final cupSize = cup['size'];
      
      // На сложном уровне приоритизируем большие чашки в начале и средине игры
      if (difficulty == 'hard' && botCupCount > 2) {
        if (cupSize == 'large' && hasBetterUseForLargeCup(freeCells, overwriteCells)) {
          continue; // Сохраняем большие чашки для более важных ходов
        }
      }
      
      for (var index in freeCells + overwriteCells) {
        if (canPlaceAt(index, 2, currentPlayer, cupSize)) {
          int score = evaluateMove(index, 2, cupSize, botCupCount);

          // Если это перекрытие вражеской чашки, добавляем бонус
          final row = index ~/ 3;
          final col = index % 3;
          final cell = board[row][col];
          if (cell != null && cell['player'] == 1) {
            // Повышаем бонус за перекрытие вражеских чашек
            score += getDifficultyBasedOverwriteBonus(cell['size']);
          }
          
          // Для средней и сложной сложности оцениваем стратегическую ценность позиции
          if (difficulty != 'easy') {
            score += evaluatePositionValue(index);
            
            // Проверяем, является ли ход частью будущей линии
            score += evaluateFutureLine(index, cupSize);
          }

          // Для сложного режима добавляем случайный фактор для непредсказуемости
          if (difficulty == 'hard') {
            score += random.nextInt(200);
          }

          if (score > bestScore) {
            bestScore = score;
            bestMove = {'moveIndex': index, 'size': cupSize, 'player': 2};
          }
        }
      }
    }

    // Если не нашли подходящий ход, делаем случайный
    if (bestMove == null) {
      return makeRandomMove(freeCells, overwriteCells, currentPlayer);
    }

    return bestMove;
  }

  // Новый метод для поиска стратегического перекрытия чашек противника
  Map<String, dynamic>? findStrategicOverwriteMove(List<List<int>> winningCombos, List<int> overwriteCells) {
    // Сначала ищем чашки противника, которые находятся в потенциально выигрышных комбинациях
    List<int> threatPositions = [];
    
    for (var combo in winningCombos) {
      int playerCupCount = 0;
      List<int> playerPositions = [];
      
      for (var index in combo) {
        final row = index ~/ 3;
        final col = index % 3;
        final cell = board[row][col];
        
        if (cell != null && cell['player'] == 1) {
          playerCupCount++;
          playerPositions.add(index);
        }
      }
      
      // Если у игрока есть хотя бы одна чашка в линии, проверяем возможность перекрытия
      if (playerCupCount > 0 && playerCupCount <= 2) {
        threatPositions.addAll(playerPositions);
      }
    }
    
    // Отсортируем позиции угроз по важности (сначала чашки в линиях с большим числом чашек игрока)
    Map<int, int> threatScores = {};
    for (var position in threatPositions) {
      threatScores[position] = (threatScores[position] ?? 0) + 1;
    }
    
    // Сортируем все позиции по убыванию "опасности"
    List<int> sortedPositions = threatPositions.toSet().toList()
      ..sort((a, b) => (threatScores[b] ?? 0).compareTo(threatScores[a] ?? 0));
    
    // Проверяем каждую позицию на возможность перекрытия
    for (var position in sortedPositions) {
      if (overwriteCells.contains(position)) {
        final row = position ~/ 3;
        final col = position % 3;
        final cell = board[row][col];
        
        if (cell != null && cell['player'] == 1) {
          // Находим подходящую чашку для перекрытия
          if (cell['size'] == 'small') {
            // Предпочитаем среднюю чашку для перекрытия маленькой, сохраняя большую
            if (botCups.any((c) => c['size'] == 'medium')) {
              return {'moveIndex': position, 'size': 'medium', 'player': 2};
            } else if (botCups.any((c) => c['size'] == 'large')) {
              return {'moveIndex': position, 'size': 'large', 'player': 2};
            }
          } else if (cell['size'] == 'medium') {
            if (botCups.any((c) => c['size'] == 'large')) {
              return {'moveIndex': position, 'size': 'large', 'player': 2};
            }
          }
        }
      }
    }
    
    return null;
  }

  // Новый метод для поиска выигрышного или блокирующего хода
  Map<String, dynamic>? findWinningOrBlockingMove(List<List<int>> winningCombos, int playerToAnalyze, 
                                                List<int> freeCells, List<int> overwriteCells) {
    for (var combo in winningCombos) {
      int count = 0;
      int? emptyIndex;
      
      for (var index in combo) {
        final cell = board[index ~/ 3][index % 3];
        if (cell != null && cell['player'] == playerToAnalyze) {
          count++;
        } else if (freeCells.contains(index) || 
                  (overwriteCells.contains(index) && canOverwriteAt(index))) {
          emptyIndex = index;
        }
      }
      
      if (count == 2 && emptyIndex != null) {
        // Для победы или блокировки используем оптимальную чашку
        return findOptimalCupForMove(emptyIndex, playerToAnalyze == 2 ? 'win' : 'block');
      }
    }
    return null;
  }

  // Новый метод для поиска стратегического хода (для сложного режима)
  Map<String, dynamic>? findStrategicMove(List<int> freeCells, List<int> overwriteCells, int currentPlayer) {
    // Находим позиции, которые создают "вилку" (атаку в двух направлениях)
    var forkMove = findForkMove(freeCells, overwriteCells);
    if (forkMove != null) {
      return forkMove;
    }
    
    // Занимаем центр, если он свободен (стратегически важная позиция)
    if (freeCells.contains(4)) {
      for (var cup in botCups) {
        if (cup['size'] == 'medium' || cup['size'] == 'large') {
          return {'moveIndex': 4, 'size': cup['size'], 'player': 2};
        }
      }
    }
    
    // Занимаем углы, если они свободны
    List<int> corners = [0, 2, 6, 8];
    for (var corner in corners) {
      if (freeCells.contains(corner)) {
        for (var cup in botCups.where((c) => c['size'] == 'large' || c['size'] == 'medium')) {
          return {'moveIndex': corner, 'size': cup['size'], 'player': 2};
        }
      }
    }
    
    return null;
  }

  // Поиск "вилки" - хода, создающего две угрозы одновременно
  Map<String, dynamic>? findForkMove(List<int> freeCells, List<int> overwriteCells) {
    final winningCombos = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6],
    ];
    
    for (var index in freeCells) {
      int threatCount = 0;
      
      // Проверяем, сколько угроз создает этот ход
      for (var combo in winningCombos) {
        if (combo.contains(index)) {
          int botCount = 0;
          bool valid = true;
          
          for (var i in combo) {
            if (i == index) continue;
            
            final cell = board[i ~/ 3][i % 3];
            if (cell != null) {
              if (cell['player'] == 1) {
                valid = false;
                break;
              } else if (cell['player'] == 2) {
                botCount++;
              }
            }
          }
          
          if (valid && botCount == 1) {
            threatCount++;
          }
        }
      }
      
      if (threatCount >= 2) {
        // Нашли "вилку", используем наилучшую чашку
        for (var cup in botCups.where((c) => c['size'] == 'large' || c['size'] == 'medium')) {
          return {'moveIndex': index, 'size': cup['size'], 'player': 2};
        }
        
        if (botCups.isNotEmpty) {
          var cup = botCups.first;
          return {'moveIndex': index, 'size': cup['size'], 'player': 2};
        }
      }
    }
    
    return null;
  }

  // Оценивает потенциал клетки для создания будущей линии
  int evaluateFutureLine(int index, String cupSize) {
    int score = 0;
    final winningCombos = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6],
    ];
    
    // Проверяем каждую комбинацию, содержащую данную клетку
    for (var combo in winningCombos) {
      if (combo.contains(index)) {
        int botCount = 0;
        int emptyOrOverwritableCount = 0;
        bool canFormLine = true;
        
        for (var i in combo) {
          if (i == index) continue; // Пропускаем текущий ход
          
          final cell = board[i ~/ 3][i % 3];
          if (cell == null) {
            emptyOrOverwritableCount++;
          } else if (cell['player'] == 2) {
            botCount++;
          } else if (cell['player'] == 1) {
            // Если чашка игрока может быть перекрыта ботом, считаем её потенциально пустой
            if (canOverwritePlayerCup(cell['size'], cupSize)) {
              emptyOrOverwritableCount++;
            } else {
              canFormLine = false;
              break;
            }
          }
        }
        
        // Если можно сформировать линию, добавляем очки в зависимости от уже имеющихся фигур
        if (canFormLine) {
          if (botCount == 1 && emptyOrOverwritableCount == 1) {
            score += 1500; // Почти готовая линия
          } else if (emptyOrOverwritableCount == 2) {
            score += 800; // Потенциальная линия
          }
        }
      }
    }
    
    return score;
  }

  // Проверяет, может ли данная чашка перекрыть чашку игрока
  bool canOverwritePlayerCup(String playerCupSize, String botCupSize) {
    if (playerCupSize == 'small') {
      return botCupSize == 'medium' || botCupSize == 'large';
    } else if (playerCupSize == 'medium') {
      return botCupSize == 'large';
    }
    return false;
  }

  // Новый метод для выбора оптимальной чашки для конкретного хода
  Map<String, dynamic>? findOptimalCupForMove(int index, String moveType) {
    // Для выигрышного или блокирующего хода используем приоритетно большие чашки
    List<String> sizePreference = (moveType == 'win' || moveType == 'block') 
        ? ['large', 'medium', 'small'] 
        : ['medium', 'large', 'small'];
    
    final row = index ~/ 3;
    final col = index % 3;
    final existingCup = board[row][col];
    
    // Если клетка уже занята, нужна подходящая чашка для перекрытия
    if (existingCup != null) {
      if (existingCup['size'] == 'small') {
        if (botCups.any((c) => c['size'] == 'medium')) {
          return {'moveIndex': index, 'size': 'medium', 'player': 2};
        } else if (botCups.any((c) => c['size'] == 'large')) {
          return {'moveIndex': index, 'size': 'large', 'player': 2};
        }
      } else if (existingCup['size'] == 'medium') {
        if (botCups.any((c) => c['size'] == 'large')) {
          return {'moveIndex': index, 'size': 'large', 'player': 2};
        }
      }
      return null; // Нет подходящей чашки для перекрытия
    }
    
    // Если клетка свободна, используем предпочтительный размер
    for (var size in sizePreference) {
      if (botCups.any((c) => c['size'] == size)) {
        return {'moveIndex': index, 'size': size, 'player': 2};
      }
    }
    
    // Если нет предпочтительных размеров, используем любую доступную чашку
    if (botCups.isNotEmpty) {
      return {'moveIndex': index, 'size': botCups.first['size'], 'player': 2};
    }
    
    return null;
  }

  // Проверяет, можно ли перекрыть фигуру на данной позиции
  bool canOverwriteAt(int index) {
    final row = index ~/ 3;
    final col = index % 3;
    final existingCup = board[row][col];
    
    if (existingCup == null) return true;
    if (existingCup['player'] == 2) return false; // Свою фигуру нельзя перекрыть
    
    // Проверяем, есть ли у бота подходящая чашка для перекрытия
    if (existingCup['size'] == 'small') {
      return botCups.any((c) => c['size'] == 'medium' || c['size'] == 'large');
    } else if (existingCup['size'] == 'medium') {
      return botCups.any((c) => c['size'] == 'large');
    }
    
    return false; // Большую чашку перекрыть нельзя
  }

  // Проверяет, стоит ли сохранить большую чашку для более важного хода
  bool hasBetterUseForLargeCup(List<int> freeCells, List<int> overwriteCells) {
    // Проверяем, есть ли возможности для перекрытия средних чашек противника
    for (var index in overwriteCells) {
      final row = index ~/ 3;
      final col = index % 3;
      final cell = board[row][col];
      
      if (cell != null && cell['player'] == 1 && cell['size'] == 'medium') {
        return true; // Лучше сохранить большую чашку для перекрытия средней чашки противника
      }
    }
    
    // Проверяем наличие стратегических позиций (центр, углы)
    List<int> strategicPositions = [4, 0, 2, 6, 8]; // Центр и углы
    for (var pos in strategicPositions) {
      if (freeCells.contains(pos)) {
        return true; // Можно использовать большую чашку для занятия стратегической позиции
      }
    }
    
    return false;
  }

  // Возвращает бонус за перекрытие вражеской чашки в зависимости от сложности и размера
  int getDifficultyBasedOverwriteBonus(String size) {
    // Базовые бонусы за перекрытие чашек разного размера
    int baseBonus = 0;
    
    // Бонус зависит от размера перекрываемой чашки
    if (size == 'medium') {
      baseBonus = 1500; // Перекрытие средней чашки очень ценно
    } else if (size == 'small') {
      baseBonus = 1000; // Перекрытие маленькой чашки тоже ценно
    }
    
    // Корректируем бонус в зависимости от сложности
    switch (difficulty) {
      case 'easy': return (baseBonus * 0.5).toInt();
      case 'medium': return (baseBonus * 0.8).toInt();
      case 'hard': return baseBonus;
      default: return (baseBonus * 0.7).toInt();
    }
  }

  // Оценивает стратегическую ценность позиции
  int evaluatePositionValue(int index) {
    // Центр имеет наибольшую ценность
    if (index == 4) return 500;
    
    // Углы также ценны
    if ([0, 2, 6, 8].contains(index)) return 300;
    
    // Стороны менее ценны
    return 100;
  }

  // Создает случайный ход
  Map<String, dynamic>? makeRandomMove(List<int> freeCells, List<int> overwriteCells, int currentPlayer) {
    if (freeCells.isEmpty && overwriteCells.isEmpty) return null;
    
    final allCells = [...freeCells, ...overwriteCells];
    final validMoves = <Map<String, dynamic>>[];
    
    // Собираем все возможные ходы
    for (var index in allCells) {
      for (var cup in botCups) {
        if (canPlaceAt(index, 2, currentPlayer, cup['size'])) {
          validMoves.add({'moveIndex': index, 'size': cup['size'], 'player': 2});
        }
      }
    }
    
    if (validMoves.isEmpty) return null;
    
    // Выбираем случайный ход из возможных
    return validMoves[random.nextInt(validMoves.length)];
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
    
    // Применяем множитель сложности к базовой оценке
    double difficultyMultiplier = difficulty == 'hard' ? 1.5 : 
                                 difficulty == 'medium' ? 1.0 : 0.5;
    
    for (var combo in winningCombos) {
      if (combo.contains(index)) {
        int playerCount = 0, botCount = 0, emptyCount = 0;
        
        for (var i in combo) {
          final cell = board[i ~/ 3][i % 3];
          if (cell != null && cell['player'] == 1) playerCount++;
          else if (cell != null && cell['player'] == 2) botCount++;
          else emptyCount++;
        }
        
        if (player == 2) {
          // Оценка для бота
          if (botCount == 2 && emptyCount == 1) score += 8000; // Почти победа
          else if (botCount == 1 && emptyCount == 2) score += 2500; // Потенциальная линия
          
          // Блокировка игрока
          if (playerCount == 2 && emptyCount == 1) score += 7000; // Блокировка близкой победы
          else if (playerCount == 1 && emptyCount == 2) score += 2000; // Блокировка потенциальной линии
          
          // Оценка перекрытия
          final row = index ~/ 3;
          final col = index % 3;
          final cell = board[row][col];
          if (cell != null && cell['player'] == 1) {
            if (cupSize == 'large' && cell['size'] == 'medium') score += 1500;
            else if (cupSize == 'medium' && cell['size'] == 'small') score += 1200;
            else if (cupSize == 'large' && cell['size'] == 'small') score += 1000;
          }
          
          // Стратегия в зависимости от стадии игры
          if (botCupCount >= 4) { // Начало игры
            // Ценность занятия стратегических позиций
            if (index == 4) score += 600; // Центр
            else if ([0, 2, 6, 8].contains(index)) score += 400; // Углы
          } else if (botCupCount >= 2) { // Середина игры
            // Более активная тактика
            score += 1000; 
          } else { // Конец игры
            // Максимально агрессивная игра
            score += 2000;
          }
        }
      }
    }
    
    // Применяем множитель сложности
    score = (score * difficultyMultiplier).toInt();
    
    return score;
  }
}