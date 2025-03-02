import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'bot_logic.dart';
import 'package:two_players_six_cups/styles/text_styles.dart';
import 'package:flutter/services.dart';

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
  int currentPlayer = 1; // 1 = Player 1, 2 = Player 2
  List<List<Map<String, dynamic>?>> board = List.generate(3, (_) => List.filled(3, null));
  List<Map<String, dynamic>> player1Cups = [
    {'size': 'small', 'player': 1}, {'size': 'small', 'player': 1},
    {'size': 'medium', 'player': 1}, {'size': 'medium', 'player': 1},
    {'size': 'large', 'player': 1}, {'size': 'large', 'player': 1},
  ];
  List<Map<String, dynamic>> player2Cups = [
    {'size': 'small', 'player': 2}, {'size': 'small', 'player': 2},
    {'size': 'medium', 'player': 2}, {'size': 'medium', 'player': 2},
    {'size': 'large', 'player': 2}, {'size': 'large', 'player': 2},
  ];
  String? winner;
  String? drawMessage; // Для сообщения о ничьей
  String player1Name = 'Player 1';
  String player2Name = 'Player 2';
  bool soundEnabled = true; // По умолчанию звук включен

  @override
  void initState() {
    super.initState();
    
    if (widget.gameMode == 'single') {
      // Режим игры с ботом
      _loadSinglePlayerSettings().then((_) {
        _printDebugSettings();
        print('Single player game started: ${currentPlayer == 1 ? player1Name : player2Name} turn');
        
        // Если бот ходит первым, делаем ход бота
        if (currentPlayer == 2) {
          final random = Random();
          final delay = Duration(milliseconds: 500 + random.nextInt(1000));
          Future.delayed(delay, () {
            botMove();
          });
        }
      });
    } else if (widget.gameMode == 'local_multiplayer') {
      // Режим игры для двух игроков
      _loadMultiplayerSettings().then((_) {
        _printDebugSettings();
        print('Local multiplayer game started: ${currentPlayer == 1 ? player1Name : player2Name} turn');
      });
    }
  }

  Future<void> _loadSinglePlayerSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      player1Name = prefs.getString('playerName') ?? 'Player 1';
      player2Name = 'Bot (${widget.botDifficulty ?? 'Easy'})';
      currentPlayer = (prefs.getBool('playerGoesFirst') ?? true) ? 1 : 2;
      soundEnabled = prefs.getBool('soundEnabled') ?? true;
    });
  }

  Future<void> _loadMultiplayerSettings() async {
    // Получаем параметры, переданные из экрана настройки локальной игры
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    
    if (args != null) {
      setState(() {
        player1Name = args['player1Name'] ?? 'Player 1';
        player2Name = args['player2Name'] ?? 'Player 2';
        currentPlayer = args['player1GoesFirst'] == true ? 1 : 2;
      });
    } else {
      // Если параметры не переданы, загружаем из настроек
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        player1Name = prefs.getString('playerName') ?? 'Player 1';
        player2Name = prefs.getString('player2Name') ?? 'Player 2';
        currentPlayer = (prefs.getBool('player1GoesFirst') ?? true) ? 1 : 2;
        soundEnabled = prefs.getBool('soundEnabled') ?? true;
      });
    }
  }

  // Метод для воспроизведения звука нажатия
  void _playTapSound() {
    if (soundEnabled) {
      // Здесь будет код для воспроизведения звука
      print('Playing tap sound');
    }
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
            style: AppTextStyles.popupTitle,
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
                child: Text('Restart', style: AppTextStyles.buttonText),
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
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: Text('Main Menu', style: AppTextStyles.buttonText),
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
                  SystemNavigator.pop();
                },
                child: Text('Exit Game', style: AppTextStyles.buttonText),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.red,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 1,
                child: PlayerArea(
                  player: 2,
                  cups: player2Cups,
                  isMyTurn: currentPlayer == 2,
                  label: player2Name,
                  alwaysShowLabel: true,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green[700],
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 3))],
                  ),
                  child: Text(
                    winner == null && drawMessage == null
                        ? (currentPlayer == 1 ? '$player1Name turn' : "$player2Name turn")
                        : '',
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black38, blurRadius: 2, offset: Offset(1, 1))],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Container(
                width: 300,
                height: 300,
                child: GridView.builder(
                  physics: NeverScrollableScrollPhysics(),
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
              if (drawMessage != null)
                Text(
                  drawMessage!,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              Expanded(
                flex: 1,
                child: PlayerArea(
                  player: 1,
                  cups: player1Cups,
                  isMyTurn: currentPlayer == 1,
                  label: player1Name,
                  alwaysShowLabel: true,
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
              top: 20,
              left: (MediaQuery.of(context).size.width - 400) / 2,
              child: Container(
                width: 400,
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
                      style: AppTextStyles.winnerText,
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
    if (currentPlayer != data['player']) {
      print('Move blocked: currentPlayer=$currentPlayer');
      return;
    }

    final row = index ~/ 3;
    final col = index % 3;
    final existingCup = board[row][col];

    if (existingCup != null && !canPlace(data['size'], existingCup, currentPlayer)) {
      print('Cannot place ${data['size']} over ${existingCup['size']}');
      return;
    }

    _playTapSound();

    setState(() {
      board[row][col] = data;
      if (currentPlayer == 1) {
        player1Cups.remove(data);
      } else {
        player2Cups.remove(data);
      }
      print('${currentPlayer == 1 ? player1Name : player2Name} placed ${data['size']} at ($row, $col).');

      if (winner == null) {
        _checkGameEndAfterSecondPlayer();
        if (winner == null && drawMessage == null) {
          currentPlayer = 3 - currentPlayer; // Переключение между 1 и 2
          print('Switching to ${currentPlayer == 1 ? player1Name : player2Name} turn');
          
          // Если это режим одиночной игры и ход бота, делаем ход бота
          if (widget.gameMode == 'single' && currentPlayer == 2) {
            final random = Random();
            final delay = Duration(milliseconds: 500 + random.nextInt(1000));
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

  void _checkGameEndAfterSecondPlayer() {
    // Проверка на победу
    for (var combo in _winningCombos) {
      final cells = combo.map((index) => board[index ~/ 3][index % 3]).toList();
      if (cells.every((cell) => cell != null && cell['player'] == 1)) {
        setState(() => winner = player1Name);
        print('$player1Name wins!');
        return;
      } else if (cells.every((cell) => cell != null && cell['player'] == 2)) {
        setState(() => winner = player2Name);
        print('$player2Name wins!');
        return;
      }
    }

    // Ничья проверяется только после хода второго игрока
    if (currentPlayer == (currentPlayer == 1 ? 2 : 1)) { // Если это ход второго игрока
      if (player1Cups.isEmpty && player2Cups.isEmpty) {
        setState(() {
          drawMessage = 'Draw! Both players are out of cups.';
          winner = null;
        });
        print('Draw! Both players are out of cups.');
        return;
      }

      bool canPlayer1Move = false;
      for (int i = 0; i < 9; i++) {
        final row = i ~/ 3;
        final col = i % 3;
        final cell = board[row][col];
        for (var cup in player1Cups) {
          if (canPlace(cup['size'], cell, 1)) {
            canPlayer1Move = true;
            break;
          }
        }
        if (canPlayer1Move) break;
      }

      bool canPlayer2Move = false;
      for (int i = 0; i < 9; i++) {
        final row = i ~/ 3;
        final col = i % 3;
        final cell = board[row][col];
        for (var cup in player2Cups) {
          if (canPlace(cup['size'], cell, 2)) {
            canPlayer2Move = true;
            break;
          }
        }
        if (canPlayer2Move) break;
      }

      if (!canPlayer1Move && !canPlayer2Move) {
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
      player1Cups = [
        {'size': 'small', 'player': 1}, {'size': 'small', 'player': 1},
        {'size': 'medium', 'player': 1}, {'size': 'medium', 'player': 1},
        {'size': 'large', 'player': 1}, {'size': 'large', 'player': 1},
      ];
      player2Cups = [
        {'size': 'small', 'player': 2}, {'size': 'small', 'player': 2},
        {'size': 'medium', 'player': 2}, {'size': 'medium', 'player': 2},
        {'size': 'large', 'player': 2}, {'size': 'large', 'player': 2},
      ];
      
      if (widget.gameMode == 'single') {
        currentPlayer = (prefs.getBool('playerGoesFirst') ?? true) ? 1 : 2;
      } else if (widget.gameMode == 'local_multiplayer') {
        currentPlayer = (prefs.getBool('player1GoesFirst') ?? true) ? 1 : 2;
      }
      
      winner = null;
      drawMessage = null;
      print('Game reset: ${currentPlayer == 1 ? player1Name : player2Name} turn');
      
      // Если это режим одиночной игры и ход бота, делаем ход бота
      if (widget.gameMode == 'single' && currentPlayer == 2) {
        final random = Random();
        final delay = Duration(milliseconds: 500 + random.nextInt(1000));
        Future.delayed(delay, () {
          botMove();
        });
      }
    });
  }

  // Метод для хода бота
  void botMove() {
    if (currentPlayer != 2 || widget.gameMode != 'single' || player2Cups.isEmpty) {
      print('Bot move skipped: currentPlayer=$currentPlayer, cups left=${player2Cups.length}');
      currentPlayer = 1;
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
      } else if (cell['player'] == 1 && player2Cups.any((cup) => canPlace(cup['size'], cell, 2))) {
        overwriteCells.add(i);
      }
    }

    if (freeCells.isEmpty && overwriteCells.isEmpty) {
      print('No available moves for Bot, but forcing a move if possible');
      for (int i = 0; i < 9; i++) {
        final row = i ~/ 3;
        final col = i % 3;
        final cell = board[row][col];
        for (var cup in player2Cups) {
          if (canPlace(cup['size'], cell, 2)) {
            freeCells.add(i);
            break;
          }
        }
      }
      if (freeCells.isEmpty) {
        currentPlayer = 1;
        return;
      }
    }

    final BotLogic botLogic = BotLogic(board, player2Cups, widget.botDifficulty ?? 'easy');
    final Map<String, dynamic>? bestCup = botLogic.findBestMove(freeCells, overwriteCells, 2, player2Cups.length);

    if (bestCup != null) {
      final moveIndex = bestCup['moveIndex'] as int;
      final botCup = player2Cups.firstWhere((cup) => cup['size'] == bestCup['size']);
      setState(() {
        board[moveIndex ~/ 3][moveIndex % 3] = botCup;
        player2Cups.remove(botCup);
        print('Bot placed ${botCup['size']} at (${moveIndex ~/ 3}, ${moveIndex % 3}). Cups left: ${player2Cups.length}');

        if (winner == null) {
          _checkGameEndAfterSecondPlayer();
          if (winner == null && drawMessage == null) {
            currentPlayer = 1;
          }
        }
      });
    } else {
      currentPlayer = 1;
      print('Bot has no valid moves, switching back to $player1Name');
    }
  }

  void _printDebugSettings() {
    print('Debug Settings - Player 1 Name: $player1Name, Player 2 Name: $player2Name, Player 1 Goes First: ${currentPlayer == 1}, Sound Enabled: $soundEnabled');
  }
}

class PlayerArea extends StatelessWidget {
  final int player;
  final List<Map<String, dynamic>> cups;
  final bool isMyTurn;
  final String label;
  final bool alwaysShowLabel;

  PlayerArea({required this.player, required this.cups, required this.isMyTurn, required this.label, this.alwaysShowLabel = false});

  @override
  Widget build(BuildContext context) {
    final cupWidth = 60.0; // Ширина одной чашки
    final totalCupsWidth = cupWidth * 6 + 80; // Фиксированная ширина стола (6 чашек + отступы)
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: totalCupsWidth,
            height: 110, // Уменьшенная высота для предотвращения переполнения
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
            child: Column(
              children: [
                // Имя игрока внутри зеленого столика
                if (alwaysShowLabel || isMyTurn)
                  Padding(
                    padding: EdgeInsets.only(bottom: 5),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black38, blurRadius: 2, offset: Offset(1, 1))],
                      ),
                    ),
                  ),
                // Чашки
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
        ],
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