import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'bot_logic.dart';
import 'package:two_players_six_cups/styles/text_styles.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';

class GameScreen extends StatefulWidget {
  final String gameMode;
  final String? botDifficulty;
  final String? roomCode;
  final String? hostIp;

  GameScreen({
    required this.gameMode,
    this.botDifficulty,
    this.roomCode,
    this.hostIp,
  });

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
  late String player1Name;
  late String player2Name;
  bool soundEnabled = true; // По умолчанию звук включен
  bool player1Turn = true;
  bool gameEnded = false;
  bool isDragging = false;

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
    _loadPlayerNames();
  }

  Future<void> _loadSinglePlayerSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final localizations = AppLocalizations.of(context);
    final difficulty = widget.botDifficulty ?? 'easy';
    final playerGoesFirst = prefs.getBool('playerGoesFirst') ?? true;
    
    setState(() {
      player1Name = prefs.getString('player1Name') ?? 'Player 1';
      player2Name = 'Bot ${difficulty}';
      currentPlayer = playerGoesFirst ? 1 : 2;
      soundEnabled = prefs.getBool('soundEnabled') ?? true;
      
      // Если бот ходит первым (playerGoesFirst = false), делаем ход бота
      if (!playerGoesFirst) {
        Future.delayed(Duration(milliseconds: 500), () {
          botMove();
        });
      }
    });
  }

  Future<void> _loadMultiplayerSettings() async {
    // Получаем параметры, переданные из экрана настройки локальной игры
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      if (args != null) {
        player1Name = args['player1Name'] ?? 'Player 1';
        player2Name = args['player2Name'] ?? 'Player 2';
        // Явно приводим к bool и проверяем значение
        bool player1GoesFirst = args['player1GoesFirst'] == true;
        currentPlayer = player1GoesFirst ? 1 : 2;
        // Сохраняем настройку в SharedPreferences
        prefs.setBool('player1GoesFirst', player1GoesFirst);
        print('Multiplayer settings loaded from args: player1GoesFirst=$player1GoesFirst, currentPlayer=$currentPlayer');
      } else {
        // Если параметры не переданы, загружаем из настроек
        player1Name = prefs.getString('player1Name') ?? 'Player 1';
        player2Name = prefs.getString('player2Name') ?? 'Player 2';
        bool player1GoesFirst = prefs.getBool('player1GoesFirst') ?? true;
        currentPlayer = player1GoesFirst ? 1 : 2;
        print('Multiplayer settings loaded from prefs: player1GoesFirst=$player1GoesFirst, currentPlayer=$currentPlayer');
      }
      soundEnabled = prefs.getBool('soundEnabled') ?? true;
    });
  }

  Future<void> _loadPlayerNames() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (widget.gameMode == 'single') {
        player1Name = prefs.getString('playerName') ?? 'Player';
        player2Name = 'Bot ${widget.botDifficulty}';
      } else {
        player1Name = prefs.getString('player1Name') ?? 'Player 1';
        player2Name = prefs.getString('player2Name') ?? 'Player 2';
      }
    });
  }

  // Метод для воспроизведения звука нажатия
  void _playTapSound() {
    if (soundEnabled) {
      // Здесь будет код для воспроизведения звука
      print('Playing tap sound');
    }
  }

  void _showGameMenu() {
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          margin: EdgeInsets.only(top: 20),
          child: Align(
            alignment: const Alignment(0, -0.9),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400),
              child: Dialog(
                backgroundColor: Colors.white.withOpacity(0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              localizations.mainMenu,
                              style: AppTextStyles.screenTitle.copyWith(fontSize: 24),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: IconButton(
                              icon: Icon(Icons.close, color: Colors.grey),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      _buildMenuButton(
                        context,
                        localizations.restart,
                        () {
                          Navigator.pop(context);
                          _restartGame();
                        },
                      ),
                      SizedBox(height: 10),
                      _buildMenuButton(
                        context,
                        localizations.mainMenu,
                        () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showWinnerDialog(String winnerName) {
    final localizations = AppLocalizations.of(context);
    setState(() {
      gameEnded = true;
      winner = winnerName;
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          margin: EdgeInsets.only(top: 60), // Еще больше поднял верхний отступ
          child: Align(
            alignment: const Alignment(0, -0.5), // Поднял еще выше (было -0.7)
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 600, // Увеличил ширину с 500 до 600
                maxHeight: 350, // Увеличил высоту с 300 до 350
              ),
              child: AlertDialog(
                backgroundColor: Colors.white.withOpacity(0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: EdgeInsets.all(35), // Увеличил внутренние отступы до 35
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$winnerName ${localizations.winner}!',
                      style: AppTextStyles.screenTitle.copyWith(
                        fontSize: 32, // Увеличил размер текста для соответствия
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 40), // Увеличил расстояние до кнопок
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _restartGame();
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: 25, // Увеличил высоту кнопок
                                horizontal: 20, // Добавил горизонтальный padding
                              ),
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              localizations.playAgain,
                              style: AppTextStyles.buttonText.copyWith(
                                fontSize: 20, // Увеличил текст для пропорций
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        SizedBox(width: 20), // Увеличил расстояние между кнопками
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: 25, // Увеличил высоту кнопок
                                horizontal: 20, // Добавил горизонтальный padding
                              ),
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              localizations.mainMenu,
                              style: AppTextStyles.buttonText.copyWith(
                                fontSize: 20, // Увеличил текст для пропорций
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDrawDialog() {
    final localizations = AppLocalizations.of(context);
    setState(() {
      gameEnded = true;
      winner = null;
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          margin: EdgeInsets.only(top: 20),
          child: Align(
            alignment: const Alignment(0, -0.9),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400),
              child: AlertDialog(
                backgroundColor: Colors.white.withOpacity(0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: EdgeInsets.all(20),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      localizations.draw,
                      style: AppTextStyles.screenTitle.copyWith(fontSize: 24),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _restartGame();
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 15),
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              localizations.playAgain,
                              style: AppTextStyles.buttonText,
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 15),
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              localizations.mainMenu,
                              style: AppTextStyles.buttonText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuButton(BuildContext context, String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 15),
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        child: Text(
          text,
          style: AppTextStyles.buttonText,
        ),
      ),
    );
  }

  void _restartGame() async {
    final prefs = await SharedPreferences.getInstance();
    bool player1GoesFirst;
    
    if (widget.gameMode == 'single') {
      player1GoesFirst = prefs.getBool('playerGoesFirst') ?? true;
    } else {
      // В мультиплеере меняем очередность хода при рестарте
      bool currentPlayer1GoesFirst = prefs.getBool('player1GoesFirst') ?? true;
      player1GoesFirst = !currentPlayer1GoesFirst;
      prefs.setBool('player1GoesFirst', player1GoesFirst);
      print('Restart game: switching first player, player1GoesFirst=$player1GoesFirst');
    }
    
    setState(() {
      currentPlayer = player1GoesFirst ? 1 : 2;
      gameEnded = false;
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final playerAreaHeight = screenHeight * 0.25;
    final gameAreaHeight = screenHeight - (playerAreaHeight * 2);
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Верхняя часть (перевернутая для второго игрока)
                Transform.rotate(
                  angle: widget.gameMode == 'local_multiplayer' && currentPlayer == 2 ? pi : 0,
                  child: Container(
                    height: playerAreaHeight,
                    child: PlayerArea(
                      player: 2,
                      cups: player2Cups,
                      isMyTurn: currentPlayer == 2,
                      label: player2Name,
                      alwaysShowLabel: true,
                    ),
                  ),
                ),
                // Игровое поле
                Container(
                  height: gameAreaHeight,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.translate(
                        offset: Offset(0, 30),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: MediaQuery.of(context).size.width > 400 ? 400 : MediaQuery.of(context).size.width * 0.9,
                              height: MediaQuery.of(context).size.width > 400 ? 400 : MediaQuery.of(context).size.width * 0.9,
                              padding: EdgeInsets.all(20),
                              child: GridView.builder(
                                physics: NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  childAspectRatio: 1,
                                ),
                                itemCount: 9,
                                itemBuilder: (context, index) {
                                  return DragTarget<Map<String, dynamic>>(
                                    onWillAccept: (data) {
                                      if (data == null) return false;
                                      final row = index ~/ 3;
                                      final col = index % 3;
                                      final existingCup = board[row][col];
                                      return canPlace(data['size'], existingCup, data['player']);
                                    },
                                    onAccept: (data) => handleDrop(data, index),
                                    builder: (context, candidateData, rejectedData) {
                                      bool canAccept = candidateData.isNotEmpty;
                                      return Container(
                                        decoration: BoxDecoration(
                                          border: Border(
                                            top: index ~/ 3 == 0 ? BorderSide.none : BorderSide(color: Colors.black, width: 2),
                                            bottom: index ~/ 3 == 2 ? BorderSide.none : BorderSide(color: Colors.black, width: 2),
                                            left: index % 3 == 0 ? BorderSide.none : BorderSide(color: Colors.black, width: 2),
                                            right: index % 3 == 2 ? BorderSide.none : BorderSide(color: Colors.black, width: 2),
                                          ),
                                          color: canAccept ? Colors.green.withOpacity(0.3) : null,
                                        ),
                                        child: Center(
                                          child: board[index ~/ 3][index % 3] != null
                                              ? CupWidget(size: board[index ~/ 3][index % 3]!['size'], player: board[index ~/ 3][index % 3]!['player'])
                                              : null,
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 0,
                        child: Transform.rotate(
                          angle: widget.gameMode == 'local_multiplayer' && currentPlayer == 2 ? pi : 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (!gameEnded)
                                Text(
                                  widget.gameMode == 'single' 
                                    ? (currentPlayer == 1 ? localizations.yourTurn : localizations.opponentTurn)
                                    : (currentPlayer == 1 ? '${player1Name} ${localizations.turn}' : '${player2Name} ${localizations.turn}'),
                                  style: AppTextStyles.turnIndicator,
                                  textAlign: TextAlign.center,
                                )
                              else
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        winner != null 
                                          ? '$winner ${localizations.winner}!'
                                          : localizations.draw,
                                        style: AppTextStyles.turnIndicator.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 20),
                                      IconButton(
                                        icon: Icon(Icons.refresh, color: Colors.white),
                                        onPressed: _restartGame,
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.home, color: Colors.white),
                                        onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Нижняя часть
                Container(
                  height: playerAreaHeight,
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
            // Меню
            Positioned(
              bottom: 10,
              left: 10,
              child: IconButton(
                icon: Icon(Icons.home, size: 30, color: Colors.blueGrey),
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
              ),
            ),
          ],
        ),
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
    final localizations = AppLocalizations.of(context);
    
    // Проверка на победу
    for (var combo in _winningCombos) {
      final cells = combo.map((index) => board[index ~/ 3][index % 3]).toList();
      if (cells.every((cell) => cell != null && cell['player'] == 1)) {
        setState(() {
          winner = player1Name;
          gameEnded = true;
        });
        print('$player1Name wins!');
        return;
      } else if (cells.every((cell) => cell != null && cell['player'] == 2)) {
        setState(() {
          winner = player2Name;
          gameEnded = true;
        });
        print('$player2Name wins!');
        return;
      }
    }

    // Проверка на ничью
    bool canPlayer1Move = false;
    bool canPlayer2Move = false;

    // Проверяем возможность хода для каждого игрока
    for (int i = 0; i < 9; i++) {
      final row = i ~/ 3;
      final col = i % 3;
      final cell = board[row][col];
      
      // Проверяем возможность хода для первого игрока
      if (!canPlayer1Move && player1Cups.isNotEmpty) {
        for (var cup in player1Cups) {
          if (canPlace(cup['size'], cell, 1)) {
            canPlayer1Move = true;
            break;
          }
        }
      }
      
      // Проверяем возможность хода для второго игрока
      if (!canPlayer2Move && player2Cups.isNotEmpty) {
        for (var cup in player2Cups) {
          if (canPlace(cup['size'], cell, 2)) {
            canPlayer2Move = true;
            break;
          }
        }
      }
      
      if (canPlayer1Move && canPlayer2Move) break;
    }

    // Проверяем условия ничьей
    bool isDraw = false;

    // Условие 1: У обоих игроков не осталось чашек
    if (player1Cups.isEmpty && player2Cups.isEmpty) {
      isDraw = true;
      print('Draw! Both players are out of cups.');
    }
    // Условие 2: Ни один из игроков не может сделать ход
    else if (!canPlayer1Move && !canPlayer2Move) {
      isDraw = true;
      print('Draw! No moves possible for either player.');
    }

    if (isDraw) {
      setState(() {
        drawMessage = localizations.draw;
        winner = null;
        gameEnded = true;
      });
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
  final bool alwaysShowLabel;

  PlayerArea({
    required this.player,
    required this.cups,
    required this.isMyTurn,
    required this.label,
    this.alwaysShowLabel = false
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cupWidth = 60.0;
    final maxWidth = screenWidth * 0.9;
    
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: maxWidth,
            height: 110,
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[300]!, Colors.green[700]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: Column(
              children: [
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
                Expanded(
                  child: Transform.rotate(
                    angle: player == 2 ? pi : 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: cups.map((cup) => isMyTurn
                        ? Transform.rotate(
                            angle: player == 2 ? -pi : 0,
                            child: Draggable<Map<String, dynamic>>(
                              data: cup,
                              child: CupWidget(size: cup['size'], player: cup['player']),
                              feedback: CupWidget(size: cup['size'], player: cup['player'], isDragging: true),
                              childWhenDragging: Container(width: 60, height: 60),
                            ),
                          )
                        : Transform.rotate(
                            angle: player == 2 ? -pi : 0,
                            child: CupWidget(size: cup['size'], player: cup['player']),
                          ),
                      ).toList(),
                    ),
                  ),
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