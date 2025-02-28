import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'bot_logic.dart';

class GameScreen extends StatefulWidget {
  final String gameMode;
  final String? botDifficulty;
  final String? roomCode;
  final String? hostIp;

  GameScreen({required this.gameMode, this.botDifficulty, this.roomCode, this.hostIp});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int currentPlayer = 1; // 1 = Player, 2 = Bot (по умолчанию игрок)
  List<List<Map<String, dynamic>?>> board = List.generate(3, (_) => List.filled(3, null));
  List<Map<String, dynamic>> playerCups = [
    {'size': 'small', 'player': 1}, {'size': 'small', 'player': 1},
    {'size': 'medium', 'player': 1}, {'size': 'medium', 'player': 1},
    {'size': 'large', 'player': 1}, {'size': 'large', 'player': 1},
  ];
  List<Map<String, dynamic>> botCups = [
    {'size': 'small', 'player': 2}, {'size': 'small', 'player': 2},
    {'size': 'medium', 'player': 2}, {'size': 'medium', 'player': 2},
    {'size': 'large', 'player': 2}, {'size': 'large', 'player': 2},
  ];
  String? winner;
  String? drawMessage; // Для сообщения о ничьей
  bool isBotThinking = false;
  String playerName = 'Player';

  @override
  void initState() {
    super.initState();
    if (widget.gameMode != 'single') {
      throw Exception('This screen is for single player only');
    }
    _loadSettings().then((_) {
      _printDebugSettings(); // Вызываем после загрузки настроек
      print('Game started: ${currentPlayer == 1 ? playerName : 'Bot'} turn');
      if (currentPlayer == 2 && !isBotThinking) { // Если бот ходит первым
        isBotThinking = true;
        final random = Random();
        final delay = Duration(milliseconds: 500 + random.nextInt(1000)); // Задержка 500–1500 мс
        Future.delayed(delay, () {
          botMove();
        });
      }
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      playerName = prefs.getString('playerName') ?? 'Player';
      currentPlayer = (prefs.getBool('playerGoesFirst') ?? true) ? 1 : 2; // Убедимся, что загружаем корректно
    });
  }

  void _printDebugSettings() {
    print('Debug Settings - Player Name: $playerName, Player Goes First: ${currentPlayer == 1}');
  }

  void _showMenuPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Center(
          child: Text(
            'Menu',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
              shadows: [Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 2)],
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  resetGame();
                },
                child: Text('Restart', style: TextStyle(color: Colors.white, fontSize: 20)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            SizedBox(height: 10),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.popUntil(context, (route) => route.isFirst); // Возвращаемся в главное меню
                },
                child: Text('Back to Main Menu', style: TextStyle(color: Colors.white, fontSize: 20)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100]!,
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Стандартное расположение
            children: [
              Expanded(
                flex: 1,
                child: PlayerArea(
                  player: 2,
                  cups: botCups,
                  isMyTurn: false,
                  label: 'Bot (${widget.botDifficulty ?? 'Easy'})',
                ),
              ),
              SizedBox(height: 10),
              Container(
                width: 300,
                height: 300,
                child: GridView.builder(
                  physics: NeverScrollableScrollPhysics(), // Убираем возможность скроллинга
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1,
                  ),
                  itemCount: 9,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: index ~/ 3 == 0 ? BorderSide.none : BorderSide(color: Colors.black, width: 2),
                          bottom: index ~/ 3 == 2 ? BorderSide.none : BorderSide(color: Colors.black, width: 2),
                          left: index % 3 == 0 ? BorderSide.none : BorderSide(color: Colors.black, width: 2),
                          right: index % 3 == 2 ? BorderSide.none : BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      child: DragTarget<Map<String, dynamic>>(
                        onAccept: (data) => handleDrop(data, index),
                        builder: (context, _, __) => Center(
                          child: board[index ~/ 3][index % 3] != null
                              ? CupWidget(size: board[index ~/ 3][index % 3]!['size'], player: board[index ~/ 3][index % 3]!['player'])
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 10),
              Text(
                winner == null && drawMessage == null
                    ? (currentPlayer == 1 ? 'Your turn' : "Opponent's turn")
                    : '',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
              if (drawMessage != null)
                Text(
                  drawMessage!,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              Expanded(
                flex: 1,
                child: PlayerArea(
                  player: 1,
                  cups: playerCups,
                  isMyTurn: currentPlayer == 1 && !isBotThinking,
                  label: playerName,
                ),
              ),
            ],
          ),
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              icon: Icon(Icons.menu, size: 30, color: Colors.blueGrey),
              onPressed: _showMenuPopup,
            ),
          ),
          if (winner != null)
            Positioned(
              top: 20, // Баннер над полем, ближе к верху
              left: (MediaQuery.of(context).size.width - 400) / 2, // Центрируем баннер шириной 400
              child: Container(
                width: 400, // Фиксированная ширина в стиле стола
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.green[300]!, Colors.green[700]!]),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 5))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$winner won!',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, shadows: [
                        Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 2),
                      ]),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: resetGame,
                          child: Text('Play Again', style: TextStyle(color: Colors.green[900], fontSize: 18)),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.popUntil(context, (route) => route.isFirst);
                          },
                          child: Text('Main Menu', style: TextStyle(color: Colors.green[900], fontSize: 18)),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void handleDrop(Map<String, dynamic> data, int index) {
    if (currentPlayer != data['player'] || isBotThinking) {
      print('Move blocked: currentPlayer=$currentPlayer, isBotThinking=$isBotThinking');
      return;
    }

    final row = index ~/ 3;
    final col = index % 3;
    final existingCup = board[row][col];

    if (existingCup != null && !canPlace(data['size'], existingCup, currentPlayer)) {
      print('Cannot place ${data['size']} over ${existingCup['size']} (only enemy cups can be overlapped: large/medium over small, large over medium)');
      return;
    }

    setState(() {
      board[row][col] = data;
      if (currentPlayer == 1) {
        playerCups.remove(data);
      } else {
        botCups.remove(data);
      }
      print('$playerName placed ${data['size']} at ($row, $col). Cups left: ${currentPlayer == 1 ? playerCups.length : botCups.length}');

      if (winner == null) {
        _checkGameEndAfterSecondPlayer(); // Проверяем исход после хода второго игрока
        if (winner == null && drawMessage == null) {
          currentPlayer = 3 - currentPlayer; // Переключение между 1 и 2
          isBotThinking = currentPlayer == 2;
          print('Switching to ${currentPlayer == 1 ? 'Your turn' : "Opponent's turn"}');
          if (isBotThinking) {
            final random = Random();
            final delay = Duration(milliseconds: 500 + random.nextInt(1000)); // Задержка 500–1500 мс
            Future.delayed(delay, () {
              botMove();
            });
          }
        }
      }
    });
  }

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

  void botMove() {
    if (currentPlayer != 2 || widget.gameMode != 'single' || botCups.isEmpty) {
      print('Bot move skipped: currentPlayer=$currentPlayer, cups left=${botCups.length}');
      currentPlayer = 1;
      isBotThinking = false;
      return;
    }

    final freeCells = <int>[];
    final overwriteCells = <int>[];
    for (int i = 0; i < 9; i++) {
      final row = i ~/ 3;
      final col = i % 3;
      final cell = board[row][col];
      if (cell == null) {
        freeCells.add(i);
      } else if (cell['player'] == 1 && botCups.any((cup) => canPlace(cup['size'], cell, 2))) { // Проверяем, можно ли перекрыть любую чашкой
        overwriteCells.add(i);
      }
    }

    if (freeCells.isEmpty && overwriteCells.isEmpty) {
      print('No available moves for Bot, but forcing a move if possible');
      // Если нет ходов, ищем любой возможный ход (даже случайный)
      for (int i = 0; i < 9; i++) {
        final row = i ~/ 3;
        final col = i % 3;
        final cell = board[row][col];
        for (var cup in botCups) {
          if (canPlace(cup['size'], cell, 2)) {
            freeCells.add(i);
            break;
          }
        }
      }
      if (freeCells.isEmpty) {
        currentPlayer = 1;
        isBotThinking = false;
        return;
      }
    }

    final BotLogic botLogic = BotLogic(board, botCups, widget.botDifficulty ?? 'easy');
    final Map<String, dynamic>? bestCup = botLogic.findBestMove(freeCells, overwriteCells, 2, botCups.length);

    if (bestCup != null) {
      final moveIndex = bestCup['moveIndex'] as int;
      final botCup = botCups.firstWhere((cup) => cup['size'] == bestCup['size']); // Находим чашку по размеру
      setState(() {
        board[moveIndex ~/ 3][moveIndex % 3] = botCup;
        botCups.remove(botCup); // Удаляем использованную чашку
        print('Bot placed ${botCup['size']} at (${moveIndex ~/ 3}, ${moveIndex % 3}). Cups left: ${botCups.length}');

        if (winner == null) {
          _checkGameEndAfterSecondPlayer(); // Проверяем исход после хода второго игрока
          if (winner == null && drawMessage == null) {
            currentPlayer = 1;
            isBotThinking = false;
          }
        }
      });
    } else {
      currentPlayer = 1;
      isBotThinking = false;
      print('Bot has no valid moves, switching back to $playerName');
    }
  }

  void _checkGameEndAfterSecondPlayer() {
    // Проверка на победу
    for (var combo in _winningCombos) {
      final cells = combo.map((index) => board[index ~/ 3][index % 3]).toList();
      if (cells.every((cell) => cell != null && cell['player'] == 1)) {
        setState(() => winner = playerName);
        print('$playerName wins!');
        return;
      } else if (cells.every((cell) => cell != null && cell['player'] == 2)) {
        setState(() => winner = 'Bot');
        print('Bot wins!');
        return;
      }
    }

    // Ничья проверяется только после хода второго игрока
    if (currentPlayer == (currentPlayer == 1 ? 2 : 1)) { // Если это ход второго игрока
      if (playerCups.isEmpty && botCups.isEmpty) {
        setState(() {
          drawMessage = 'Draw! Both players are out of cups.';
          winner = null;
        });
        print('Draw! Both players are out of cups.');
        return;
      }

      bool canPlayerMove = false;
      for (int i = 0; i < 9; i++) {
        final row = i ~/ 3;
        final col = i % 3;
        final cell = board[row][col];
        for (var cup in playerCups) {
          if (canPlace(cup['size'], cell, 1)) {
            canPlayerMove = true;
            break;
          }
        }
        if (canPlayerMove) break;
      }

      bool canBotMove = false;
      for (int i = 0; i < 9; i++) {
        final row = i ~/ 3;
        final col = i % 3;
        final cell = board[row][col];
        for (var cup in botCups) {
          if (canPlace(cup['size'], cell, 2)) {
            canBotMove = true;
            break;
          }
        }
        if (canBotMove) break;
      }

      if (!canPlayerMove && !canBotMove) {
        setState(() {
          drawMessage = 'Draw! No moves possible for either player.';
          winner = null;
        });
        print('Draw! No moves possible for either player.');
      }
    }
  }

  static const _winningCombos = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8],
    [0, 3, 6], [1, 4, 7], [2, 5, 8],
    [0, 4, 8], [2, 4, 6],
  ];

  void resetGame() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      board = List.generate(3, (_) => List.filled(3, null));
      playerCups = [
        {'size': 'small', 'player': 1}, {'size': 'small', 'player': 1},
        {'size': 'medium', 'player': 1}, {'size': 'medium', 'player': 1},
        {'size': 'large', 'player': 1}, {'size': 'large', 'player': 1},
      ];
      botCups = [
        {'size': 'small', 'player': 2}, {'size': 'small', 'player': 2},
        {'size': 'medium', 'player': 2}, {'size': 'medium', 'player': 2},
        {'size': 'large', 'player': 2}, {'size': 'large', 'player': 2},
      ];
      currentPlayer = (prefs.getBool('playerGoesFirst') ?? true) ? 1 : 2; // Сбрасываем на настройки
      winner = null;
      drawMessage = null;
      isBotThinking = false;
      print('Game reset: ${currentPlayer == 1 ? playerName : 'Bot'} turn');
      if (currentPlayer == 2 && !isBotThinking) { // Если бот ходит первым после сброса
        isBotThinking = true;
        final random = Random();
        final delay = Duration(milliseconds: 500 + random.nextInt(1000)); // Задержка 500–1500 мс
        Future.delayed(delay, () {
          botMove();
        });
      }
    });
  }
}

class PlayerArea extends StatelessWidget {
  final int player;
  final List<Map<String, dynamic>> cups;
  final bool isMyTurn;
  final String label;

  PlayerArea({required this.player, required this.cups, required this.isMyTurn, required this.label});

  @override
  Widget build(BuildContext context) {
    final cupWidth = 60.0; // Ширина одной чашки
    final totalCupsWidth = cupWidth * 6 + 80; // Фиксированная ширина стола (6 чашек + отступы)
    return Center(
      child: Container(
        width: totalCupsWidth,
        height: 130, // Уменьшенная высота для предотвращения переполнения
        padding: EdgeInsets.all(8), // Уменьшенный padding
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green[300]!, Colors.green[700]!], // Зелёный градиент в стиле игры
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 20, // Уменьшенный размер текста
                  color: Colors.black, // Контрастный цвет на белом фоне
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.white, offset: Offset(1, 1), blurRadius: 2)],
                ),
              ),
              SizedBox(height: 5), // Уменьшенный отступ
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  if (index < cups.length) {
                    return isMyTurn
                        ? Draggable<Map<String, dynamic>>(
                            data: cups[index],
                            child: CupWidget(size: cups[index]['size'], player: cups[index]['player']),
                            feedback: CupWidget(size: cups[index]['size'], player: cups[index]['player'], isDragging: true),
                            childWhenDragging: Container(
                              width: 60, // Фиксированная ширина для места чашки
                              height: 60, // Фиксированная высота для места чашки
                            ),
                          )
                        : CupWidget(size: cups[index]['size'], player: cups[index]['player']);
                  } else {
                    return Container(
                      width: 60, // Пустое место для сохранения позиции
                      height: 60,
                    );
                  }
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CupWidget extends StatelessWidget {
  final String size;
  final int player;
  final bool isDragging;

  CupWidget({required this.size, required this.player, this.isDragging = false});

  @override
  Widget build(BuildContext context) {
    double dimension = size == 'small' ? 30 : size == 'medium' ? 45 : 60;
    return Container(
      width: dimension,
      height: dimension,
      margin: EdgeInsets.all(4), // Уменьшенный margin
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: player == 1 ? [Colors.blue[300]!, Colors.blue[800]!] : [Colors.orange[300]!, Colors.orange[800]!],
          center: Alignment(-0.3, -0.3),
          focal: Alignment(-0.3, -0.3),
          focalRadius: 0.1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
    );
  }
}