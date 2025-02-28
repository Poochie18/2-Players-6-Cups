import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' show File, FileSystemEvent;
import 'dart:convert' show jsonDecode, jsonEncode;
import 'bot_logic.dart';

class GameScreen extends StatefulWidget {
  final String gameMode;
  final String? botDifficulty;
  final String? roomCode;
  final bool? isLocal;
  final bool? isHost;

  GameScreen({
    required this.gameMode,
    this.botDifficulty,
    this.roomCode,
    this.isLocal,
    this.isHost,
  });

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int currentPlayer = 1; // 1 = Player 1, 2 = Bot/Player 2
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
  bool isBotThinking = false;
  String playerName = 'Player';
  String? gameFilePath;

  @override
  void initState() {
    super.initState();
    if (widget.gameMode != 'multiplayer' && widget.gameMode != 'single') {
      throw Exception('This screen is for single or multiplayer only');
    }
    _loadSettings().then((_) {
      _printDebugSettings();
      print('Game started: ${currentPlayer == 1 ? playerName : (widget.gameMode == 'single' ? 'Bot' : 'Opponent')} turn');
      if (widget.gameMode == 'single' && currentPlayer == 2 && !isBotThinking) {
        isBotThinking = true;
        final random = Random();
        final delay = Duration(milliseconds: 500 + random.nextInt(1000)); // Задержка 500–1500 мс
        Future.delayed(delay, () {
          botMove();
        });
      } else if (widget.isLocal ?? false) {
        _initializeMultiplayer();
      }
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      playerName = prefs.getString('playerName') ?? 'Player';
      currentPlayer = (prefs.getBool('playerGoesFirst') ?? true) ? 1 : 2; // Загружаем, кто ходит первым
    });
  }

  void _printDebugSettings() {
    print('Debug Settings - Player Name: $playerName, Player Goes First: ${currentPlayer == 1}');
  }

  void _initializeMultiplayer() async {
    if (widget.isLocal ?? false) {
      final directory = await getApplicationDocumentsDirectory();
      gameFilePath = '${directory.path}/multiplayer_game_${widget.roomCode ?? 'LOCAL123'}.json';
      await _createGameFileIfNotExists(); // Создаём файл, если его нет
      _loadGameState(); // Загружаем состояние игры из файла
      _startListeningForChanges(); // Начинаем слушать изменения в файле
    }
  }

  Future<void> _createGameFileIfNotExists() async {
    if (gameFilePath != null) {
      final file = File(gameFilePath!);
      if (!await file.exists()) {
        await file.create(recursive: true); // Создаём файл и директории, если их нет
        await file.writeAsString(jsonEncode({
          'board': board,
          'player1Cups': player1Cups,
          'player2Cups': player2Cups,
          'currentPlayer': currentPlayer,
          'winner': winner,
          'drawMessage': drawMessage,
        }));
      }
    }
  }

  Future<void> _loadGameState() async {
    if (gameFilePath != null) {
      final file = File(gameFilePath!);
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        setState(() {
          board = List<List<Map<String, dynamic>?>>.from(
            (data['board'] as List).map((row) => List<Map<String, dynamic>?>.from(row.map((cell) => cell != null ? Map<String, dynamic>.from(cell) : null))),
          );
          player1Cups = List<Map<String, dynamic>>.from(data['player1Cups'].map((cup) => Map<String, dynamic>.from(cup)));
          player2Cups = List<Map<String, dynamic>>.from(data['player2Cups'].map((cup) => Map<String, dynamic>.from(cup)));
          currentPlayer = data['currentPlayer'] as int;
          winner = data['winner'] as String?;
          drawMessage = data['drawMessage'] as String?;
        });
      }
    }
  }

  void _startListeningForChanges() {
    if (gameFilePath != null) {
      final file = File(gameFilePath!);
      if (file.existsSync()) { // Проверяем существование файла перед вызовом watch
        file.watch().listen((event) async {
          if (event is FileSystemEvent && event.type == FileSystemEvent.modify) {
            await _loadGameState();
          }
        });
      } else {
        print('File does not exist, creating it...');
        _createGameFileIfNotExists(); // Создаём файл, если его нет
      }
    }
  }

  void _saveGameState() async {
    if (gameFilePath != null) {
      final file = File(gameFilePath!);
      await file.writeAsString(jsonEncode({
        'board': board,
        'player1Cups': player1Cups,
        'player2Cups': player2Cups,
        'currentPlayer': currentPlayer,
        'winner': winner,
        'drawMessage': drawMessage,
      }));
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
                  cups: widget.gameMode == 'single'
                      ? player2Cups // Используем player2Cups для бота
                      : (widget.isHost ?? false ? player2Cups : player1Cups),
                  isMyTurn: (widget.gameMode == 'single' && currentPlayer == 2 && !isBotThinking) ||
                      (widget.gameMode == 'multiplayer' && currentPlayer == 2 && !isBotThinking),
                  label: widget.gameMode == 'single' ? 'Bot (${widget.botDifficulty ?? 'Easy'})' : 'Opponent',
                  winner: winner, // Передаём winner в PlayerArea
                  drawMessage: drawMessage, // Передаём drawMessage в PlayerArea
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
                        onAccept: (data) => _handleMyMove(data, index),
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
                    ? (currentPlayer == (widget.gameMode == 'single' ? 1 : (widget.isHost ?? false ? 1 : 2))
                        ? 'Your turn'
                        : (widget.gameMode == 'single' ? "Bot's turn" : "Opponent's turn"))
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
                  cups: player1Cups,
                  isMyTurn: currentPlayer == 1 && !isBotThinking,
                  label: playerName,
                  winner: winner, // Передаём winner в PlayerArea
                  drawMessage: drawMessage, // Передаём drawMessage в PlayerArea
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

  void _handleMyMove(Map<String, dynamic> data, int index) {
    if (currentPlayer != (widget.gameMode == 'single' ? 1 : (widget.isHost ?? false ? 1 : 2))) {
      print('Move blocked: currentPlayer=$currentPlayer');
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
        player1Cups.remove(data);
      } else if (widget.gameMode == 'single') {
        player2Cups.remove(data);
      } else {
        player2Cups.remove(data);
      }
      print('$playerName placed ${data['size']} at ($row, $col). Cups left: ${currentPlayer == 1 ? player1Cups.length : player2Cups.length}');

      _checkGameEndAfterMove(); // Проверяем победу или ничью после каждого хода
      if (winner == null && drawMessage == null) {
        if (widget.gameMode == 'single' && currentPlayer == 1) {
          currentPlayer = 2;
          isBotThinking = true;
          final random = Random();
          final delay = Duration(milliseconds: 500 + random.nextInt(1000)); // Задержка 500–1500 мс
          Future.delayed(delay, () {
            botMove();
          });
        } else {
          currentPlayer = 3 - currentPlayer; // Переключаем игрока
          if (widget.isLocal ?? false) {
            _saveGameState(); // Сохраняем состояние в файл для мультиплеера
          }
          print('Switching to ${currentPlayer == (widget.gameMode == 'single' ? 1 : (widget.isHost ?? false ? 1 : 2)) ? 'Your turn' : (widget.gameMode == 'single' ? "Bot's turn" : "Opponent's turn")}');
        }
      } else {
        // Блокируем дальнейшие ходы, если игра закончилась
        setState(() {
          isBotThinking = false; // Останавливаем бота
        });
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
    if (currentPlayer != 2 || widget.gameMode != 'single' || player2Cups.isEmpty) {
      print('Bot move skipped: currentPlayer=$currentPlayer, cups left=${player2Cups.length}');
      currentPlayer = 1;
      isBotThinking = false;
      _checkGameEndAfterMove(); // Проверяем победу или ничью после пропуска хода бота
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
      print('No available moves for Bot');
      currentPlayer = 1;
      isBotThinking = false;
      _checkGameEndAfterMove(); // Проверяем победу или ничью после пропуска хода бота
      return;
    }

    final BotLogic botLogic = BotLogic(board, player2Cups, widget.botDifficulty ?? 'easy');
    final Map<String, dynamic>? bestCup = botLogic.findBestMove(freeCells, overwriteCells, 2, player2Cups.length);

    if (bestCup != null) {
      final moveIndex = bestCup['moveIndex'] as int;
      final botCup = player2Cups.firstWhere((cup) => cup['size'] == bestCup['size']); // Находим чашку по размеру
      setState(() {
        final row = moveIndex ~/ 3;
        final col = moveIndex % 3;
        board[row][col] = botCup;
        player2Cups.remove(botCup); // Удаляем использованную чашку
        print('Bot placed ${botCup['size']} at ($row, $col). Cups left: ${player2Cups.length}');

        _checkGameEndAfterMove(); // Проверяем победу или ничью после хода бота
        if (winner == null && drawMessage == null) {
          currentPlayer = 1;
          isBotThinking = false;
        } else {
          isBotThinking = false; // Останавливаем бота, если игра закончилась
        }
      });
    } else {
      currentPlayer = 1;
      isBotThinking = false;
      _checkGameEndAfterMove(); // Проверяем победу или ничью после пропуска хода бота
      print('Bot has no valid moves, switching back to $playerName');
    }
  }

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
      currentPlayer = (prefs.getBool('playerGoesFirst') ?? true) ? 1 : 2; // Сбрасываем на настройки
      winner = null;
      drawMessage = null;
      isBotThinking = false;
      print('Game reset: ${currentPlayer == (widget.gameMode == 'single' ? 1 : (widget.isHost ?? false ? 1 : 2)) ? playerName : (widget.gameMode == 'single' ? 'Bot' : 'Opponent')} turn');
      if (widget.gameMode == 'single' && currentPlayer == 2 && !isBotThinking) {
        isBotThinking = true;
        final random = Random();
        final delay = Duration(milliseconds: 500 + random.nextInt(1000)); // Задержка 500–1500 мс
        Future.delayed(delay, () {
          botMove();
        });
      } else if (widget.isLocal ?? false) {
        _saveGameState(); // Сохраняем сброшенное состояние для мультиплеера
      }
    });
  }

  void _checkGameEndAfterMove() {
    // Проверка на победу после каждого хода
    for (var combo in _winningCombos) {
      final cells = combo.map((index) => board[index ~/ 3][index % 3]).toList();
      if (cells.every((cell) => cell != null && cell['player'] == 1)) {
        setState(() {
          winner = playerName;
          if (widget.gameMode == 'single') isBotThinking = false; // Останавливаем бота
        });
        print('$playerName wins!');
        return;
      } else if (cells.every((cell) => cell != null && cell['player'] == 2)) {
        setState(() {
          winner = widget.gameMode == 'single' ? 'Bot' : 'Opponent';
          if (widget.gameMode == 'single') isBotThinking = false; // Останавливаем бота
        });
        print('${widget.gameMode == 'single' ? 'Bot' : 'Opponent'} wins!');
        return;
      }
    }

    // Проверка на ничью: игра заканчивается, если ни один игрок не может сделать ход
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
      for (var cup in widget.gameMode == 'single' ? player2Cups : player2Cups) {
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
        if (widget.gameMode == 'single') isBotThinking = false; // Останавливаем бота
      });
      print('Draw! No moves possible for either player.');
      return;
    }

    // Дополнительная проверка: если у обоих игроков закончились чашки, но они не могут сделать ходы
    if (player1Cups.isEmpty && (widget.gameMode == 'single' ? player2Cups.isEmpty : player2Cups.isEmpty)) {
      setState(() {
        drawMessage = 'Draw! Both players are out of cups.';
        winner = null;
        if (widget.gameMode == 'single') isBotThinking = false; // Останавливаем бота
      });
      print('Draw! Both players are out of cups.');
      return;
    }
  }

  static const _winningCombos = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8],
    [0, 3, 6], [1, 4, 7], [2, 5, 8],
    [0, 4, 8], [2, 4, 6],
  ];
}

class PlayerArea extends StatelessWidget {
  final int player;
  final List<Map<String, dynamic>> cups;
  final bool isMyTurn;
  final String label;
  final String? winner; // Добавляем параметр winner
  final String? drawMessage; // Добавляем параметр drawMessage

  PlayerArea({
    required this.player,
    required this.cups,
    required this.isMyTurn,
    required this.label,
    required this.winner,
    required this.drawMessage,
  });

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
                    return (isMyTurn && winner == null && drawMessage == null) // Блокируем перетаскивание, если игра закончилась
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