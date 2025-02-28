import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' show File, FileSystemEvent;
import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:async' show Timer;
import 'bot_logic.dart';

class GameScreen extends StatefulWidget {
  final String gameMode;
  final String? botDifficulty;
  final String? roomCode;
  final bool? isLocal;
  final bool? isHost;
  final bool? isJoining;

  GameScreen({
    required this.gameMode,
    this.botDifficulty,
    this.roomCode,
    this.isLocal,
    this.isHost,
    this.isJoining,
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
  bool isWaitingForPlayer2 = false; // Флаг ожидания второго игрока
  String? gameFilePath;
  bool isGameActive = false; // Флаг активной игры
  String playerName = 'Player'; // Переменная имени игрока
  bool isBotThinking = false; // Флаг, что бот думает

  @override
  void initState() {
    super.initState();
    if (widget.gameMode != 'multiplayer' && widget.gameMode != 'single') {
      throw Exception('This screen is for single or multiplayer only');
    }
    if (widget.gameMode == 'single' && widget.botDifficulty == null) {
      throw Exception('Bot difficulty must be provided for single player mode');
    }
    _loadSettings().then((_) {
      _printDebugSettings();
      print('Game started: ${currentPlayer == 1 ? playerName : (widget.gameMode == 'single' ? 'Bot' : 'Opponent')} turn');
      if (widget.gameMode == 'multiplayer' && widget.isHost == true && !(widget.isJoining ?? false)) {
        setState(() {
          isWaitingForPlayer2 = true;
          isGameActive = false; // Игра ещё не активна, пока не подключится второй игрок
        });
        _initializeMultiplayer();
      } else if (widget.gameMode == 'multiplayer' && (widget.isJoining ?? false)) {
        _initializeMultiplayer();
      } else if (widget.gameMode == 'single') {
        setState(() {
          isGameActive = true; // Активная игра в одиночном режиме
        });
        if (currentPlayer == 2) _startBotMove(); // Бот ходит первым, если настроено
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
      _loadGameStatePeriodically(); // Периодическая проверка состояния файла
      if (widget.isHost == true && !(widget.isJoining ?? false)) {
        _saveGameState(); // Сохраняем начальное состояние для хоста
      }
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
          'isGameActive': isGameActive,
        }));
      }
    }
  }

  Future<void> _loadGameState() async {
    if (gameFilePath != null && (widget.isHost ?? false || (widget.isJoining ?? false))) {
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
          isGameActive = data['isGameActive'] as bool? ?? false;
          if (isGameActive && isWaitingForPlayer2) {
            isWaitingForPlayer2 = false; // Начинаем игру, когда второй игрок подключился
          }
        });
      }
    }
  }

  void _loadGameStatePeriodically() {
    if (gameFilePath != null) {
      Timer.periodic(Duration(milliseconds: 500), (timer) async {
        if (mounted) await _loadGameState(); // Проверяем состояние файла каждые 500 мс
      });
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
        'isGameActive': isGameActive,
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

  void _startBotMove() {
    if (widget.gameMode != 'single' || currentPlayer != 2 || player2Cups.isEmpty || !isGameActive || winner != null || drawMessage != null) return;
    isBotThinking = true;
    final random = Random();
    final delay = Duration(milliseconds: 500 + random.nextInt(1000));
    Future.delayed(delay, () {
      botMove();
    });
  }

  void botMove() {
    if (widget.gameMode != 'single' || currentPlayer != 2 || player2Cups.isEmpty || !isGameActive || winner != null || drawMessage != null) {
      print('Bot move skipped: currentPlayer=$currentPlayer, cups left=${player2Cups.length}');
      currentPlayer = 1;
      isBotThinking = false;
      _checkGameEndAfterMove();
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
      _checkGameEndAfterMove();
      return;
    }

    final BotLogic botLogic = BotLogic(board, player2Cups, widget.botDifficulty ?? 'easy');
    final Map<String, dynamic>? bestCup = botLogic.findBestMove(freeCells, overwriteCells, 2, player2Cups.length);

    if (bestCup != null) {
      final moveIndex = bestCup['moveIndex'] as int;
      final botCup = player2Cups.firstWhere((cup) => cup['size'] == bestCup['size']);
      setState(() {
        final row = moveIndex ~/ 3;
        final col = moveIndex % 3;
        board[row][col] = botCup;
        player2Cups.remove(botCup);
        print('Bot placed ${botCup['size']} at ($row, $col). Cups left: ${player2Cups.length}');
        _checkGameEndAfterMove();
        if (winner == null && drawMessage == null) {
          currentPlayer = 1;
          isBotThinking = false;
        }
      });
    } else {
      currentPlayer = 1;
      isBotThinking = false;
      _checkGameEndAfterMove();
      print('Bot has no valid moves, switching back to $playerName');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.gameMode == 'multiplayer' && widget.isHost == true && !(widget.isJoining ?? false) && isWaitingForPlayer2) {
      return Scaffold(
        backgroundColor: Colors.grey[100]!,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Room Code: ${widget.roomCode}',
                style: TextStyle(fontSize: 24, color: Colors.blueGrey, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text(
                'Waiting for second player...',
                style: TextStyle(fontSize: 20, color: Colors.blueGrey),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst); // Возвращаемся в главное меню
                  },
                  child: Text('Cancel', style: TextStyle(color: Colors.white, fontSize: 20)),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
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
                  cups: widget.gameMode == 'single' ? player2Cups : (widget.isHost ?? false ? player2Cups : player1Cups),
                  isMyTurn: (widget.gameMode == 'single' && currentPlayer == 2 && !isBotThinking) ||
                      (widget.gameMode == 'multiplayer' && currentPlayer == 2 && !isBotThinking && isGameActive),
                  label: widget.gameMode == 'single' ? 'Bot (${widget.botDifficulty ?? 'Easy'})' : 'Opponent',
                  winner: winner,
                  drawMessage: drawMessage,
                  gameMode: widget.gameMode, // Передаём gameMode как параметр
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
                        onAccept: (data) => _handleMyMove(data, index),
                        builder: (context, candidateData, rejectedData) {
                          return Center(
                            child: board[index ~/ 3][index % 3] != null
                                ? CupWidget(size: board[index ~/ 3][index % 3]!['size'], player: board[index ~/ 3][index % 3]!['player'])
                                : (candidateData.isNotEmpty
                                    ? Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.blue, width: 2),
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                    : null),
                          );
                        },
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
                  isMyTurn: currentPlayer == 1 && !isBotThinking && (widget.gameMode == 'single' || isGameActive),
                  label: playerName,
                  winner: winner,
                  drawMessage: drawMessage,
                  gameMode: widget.gameMode, // Передаём gameMode как параметр
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
        ],
      ),
    );
  }

  void _handleMyMove(Map<String, dynamic> data, int index) {
    if (!isGameActive || currentPlayer != (widget.gameMode == 'single' ? 1 : (widget.isHost ?? false ? 1 : 2))) {
      print('Move blocked: currentPlayer=$currentPlayer, isGameActive=$isGameActive');
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
      } else {
        player2Cups.remove(data);
      }
      print('${currentPlayer == 1 ? playerName : (widget.gameMode == 'single' ? 'Bot' : 'Opponent')} placed ${data['size']} at ($row, $col). Cups left: ${currentPlayer == 1 ? player1Cups.length : player2Cups.length}');

      _checkGameEndAfterMove();
      if (winner == null && drawMessage == null) {
        if (widget.gameMode == 'single' && currentPlayer == 1) {
          currentPlayer = 2;
          _startBotMove();
        } else {
          currentPlayer = 3 - currentPlayer; // Переключаем игрока
          if (widget.isLocal ?? false) {
            _saveGameState();
          }
          print('Switching to ${currentPlayer == (widget.gameMode == 'single' ? 1 : (widget.isHost ?? false ? 1 : 2)) ? 'Your turn' : (widget.gameMode == 'single' ? "Bot's turn" : "Opponent's turn")}');
        }
      } else {
        setState(() {
          isGameActive = false; // Блокируем игру после победы или ничьей
          isBotThinking = false; // Останавливаем бота, если игра закончилась
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
      isGameActive = widget.gameMode == 'single' ? true : false;
      isWaitingForPlayer2 = widget.isHost == true && !(widget.isJoining ?? false);
      print('Game reset: ${currentPlayer == (widget.gameMode == 'single' ? 1 : (widget.isHost ?? false ? 1 : 2)) ? playerName : (widget.gameMode == 'single' ? 'Bot' : 'Opponent')} turn');
      if (widget.gameMode == 'single' && currentPlayer == 2) {
        _startBotMove();
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
          _showWinDialog(playerName);
        });
        print('$playerName wins!');
        return;
      } else if (cells.every((cell) => cell != null && cell['player'] == 2)) {
        setState(() {
          winner = widget.gameMode == 'single' ? 'Bot' : 'Opponent';
          _showWinDialog(widget.gameMode == 'single' ? 'Bot' : 'Opponent');
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
        _showDrawDialog();
      });
      print('Draw! No moves possible for either player.');
      return;
    }

    // Дополнительная проверка: если у обоих игроков закончились чашки, но они не могут сделать ходы
    if (player1Cups.isEmpty && (widget.gameMode == 'single' ? player2Cups.isEmpty : player2Cups.isEmpty)) {
      setState(() {
        drawMessage = 'Draw! Both players are out of cups.';
        _showDrawDialog();
      });
      print('Draw! Both players are out of cups.');
      return;
    }
  }

  void _showWinDialog(String winnerName) {
    showDialog(
      context: context,
      barrierDismissible: false, // Предотвращаем закрытие нажатием вне dialogs
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[100]!,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[300]!, Colors.green[700]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 5))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$winnerName won!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 2)],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      resetGame();
                    },
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
    );
  }

  void _showDrawDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Предотвращаем закрытие нажатием вне dialogs
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[100]!,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[300]!, Colors.green[700]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 5))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Draw!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 2)],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      resetGame();
                    },
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
    );
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
  final String? winner;
  final String? drawMessage;
  final String gameMode; // Добавляем параметр gameMode

  PlayerArea({
    required this.player,
    required this.cups,
    required this.isMyTurn,
    required this.label,
    required this.winner,
    required this.drawMessage,
    required this.gameMode,
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
                    return (isMyTurn && winner == null && drawMessage == null && (player == 1 || gameMode == 'single')) // Блокируем перетаскивание чашек бота, если он ходит
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

class BotLogic {
  final List<List<Map<String, dynamic>?>> board;
  final List<Map<String, dynamic>> cups;
  final String difficulty;

  BotLogic(this.board, this.cups, this.difficulty);

  Map<String, dynamic>? findBestMove(List<int> freeCells, List<int> overwriteCells, int player, int cupsLeft) {
    // Простая логика бота для одиночной игры
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