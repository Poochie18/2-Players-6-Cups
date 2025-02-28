import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:two_players_six_cups/models/bot_logic.dart';
import 'package:two_players_six_cups/models/game_logic.dart';
import 'package:two_players_six_cups/utils/ui_style.dart';

class SinglePlayerGameScreen extends StatefulWidget {
  final String botDifficulty;

  SinglePlayerGameScreen({required this.botDifficulty});

  @override
  _SinglePlayerGameScreenState createState() => _SinglePlayerGameScreenState();
}

class _SinglePlayerGameScreenState extends State<SinglePlayerGameScreen> {
  int currentPlayer = 1; // 1 = Player, 2 = Bot
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
  String? drawMessage;
  bool isBotThinking = false;
  String playerName = 'Player';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      playerName = prefs.getString('playerName') ?? 'Player';
      currentPlayer = (prefs.getBool('playerGoesFirst') ?? true) ? 1 : 2;
      if (currentPlayer == 2) _startBotMove();
    });
  }

  void _startBotMove() {
    if (currentPlayer != 2 || botCups.isEmpty || winner != null || drawMessage != null) return;
    isBotThinking = true;
    final random = Random();
    final delay = Duration(milliseconds: 500 + random.nextInt(1000));
    Future.delayed(delay, () {
      botMove();
    });
  }

  void botMove() {
    if (currentPlayer != 2 || botCups.isEmpty || winner != null || drawMessage != null) {
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
      } else if (cell['player'] == 1 && botCups.any((cup) => GameLogic.canPlace(cup['size'], cell, 2))) {
        overwriteCells.add(i);
      }
    }

    if (freeCells.isEmpty && overwriteCells.isEmpty) {
      currentPlayer = 1;
      isBotThinking = false;
      _checkGameEnd();
      return;
    }

    final botLogic = BotLogic(board, botCups, widget.botDifficulty);
    final Map<String, dynamic>? bestMove = botLogic.findBestMove(freeCells, overwriteCells, 2, botCups.length);

    if (bestMove != null) {
      final moveIndex = bestMove['moveIndex'] as int;
      final botCup = botCups.firstWhere((cup) => cup['size'] == bestMove['size']);
      setState(() {
        final row = moveIndex ~/ 3;
        final col = moveIndex % 3;
        board[row][col] = botCup;
        botCups.remove(botCup);
        print('Bot placed ${botCup['size']} at ($row, $col). Cups left: ${botCups.length}');
        _checkGameEnd();
        if (winner == null && drawMessage == null) {
          currentPlayer = 1;
          isBotThinking = false;
        }
      });
    } else {
      currentPlayer = 1;
      isBotThinking = false;
      _checkGameEnd();
      print('Bot has no valid moves, switching back to $playerName');
    }
  }

  void _handleMyMove(Map<String, dynamic> data, int index) {
    if (currentPlayer != 1 || winner != null || drawMessage != null) return;

    final row = index ~/ 3;
    final col = index % 3;
    final existingCup = board[row][col];

    if (existingCup != null && !GameLogic.canPlace(data['size'], existingCup, 1)) return;

    setState(() {
      board[row][col] = data;
      playerCups.remove(data);
      print('$playerName placed ${data['size']} at ($row, $col). Cups left: ${playerCups.length}');
      _checkGameEnd();
      if (winner == null && drawMessage == null) {
        currentPlayer = 2;
        _startBotMove();
      }
    });
  }

  void _checkGameEnd() {
    if (GameLogic.checkWin(board, 1)) {
      setState(() {
        winner = playerName;
        _showWinDialog(playerName);
      });
      print('$playerName wins!');
    } else if (GameLogic.checkWin(board, 2)) {
      setState(() {
        winner = 'Bot';
        _showWinDialog('Bot');
      });
      print('Bot wins!');
    } else if (!GameLogic.canPlayerMove(board, playerCups, 1) && !GameLogic.canPlayerMove(board, botCups, 2)) {
      setState(() {
        drawMessage = 'Draw! No moves possible for either player.';
        _showDrawDialog();
      });
      print('Draw! No moves possible for either player.');
    } else if (playerCups.isEmpty && botCups.isEmpty) {
      setState(() {
        drawMessage = 'Draw! Both players are out of cups.';
        _showDrawDialog();
      });
      print('Draw! Both players are out of cups.');
    }
  }

  void _showWinDialog(String winnerName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UIStyle.alertDialogStyle(
        title: '$winnerName won!',
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                resetGame();
              },
              child: Text('Play Again', style: TextStyle(color: UIStyle.primaryColor, fontSize: 18)),
              style: UIStyle.buttonStyle(backgroundColor: UIStyle.accentColor, textColor: UIStyle.primaryColor),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: Text('Main Menu', style: TextStyle(color: UIStyle.primaryColor, fontSize: 18)),
              style: UIStyle.buttonStyle(backgroundColor: UIStyle.accentColor, textColor: UIStyle.primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  void _showDrawDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UIStyle.alertDialogStyle(
        title: 'Draw!',
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                resetGame();
              },
              child: Text('Play Again', style: TextStyle(color: UIStyle.primaryColor, fontSize: 18)),
              style: UIStyle.buttonStyle(backgroundColor: UIStyle.accentColor, textColor: UIStyle.primaryColor),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: Text('Main Menu', style: TextStyle(color: UIStyle.primaryColor, fontSize: 18)),
              style: UIStyle.buttonStyle(backgroundColor: UIStyle.accentColor, textColor: UIStyle.primaryColor),
            ),
          ],
        ),
      ),
    );
  }

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
      currentPlayer = (prefs.getBool('playerGoesFirst') ?? true) ? 1 : 2;
      winner = null;
      drawMessage = null;
      isBotThinking = false;
      if (currentPlayer == 2) _startBotMove();
    });
  }

  void _showMenuPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[100]!,
        shape: RoundedRectangleBorder(borderRadius: UIStyle.buttonBorderRadius),
        title: Center(
          child: Text(
            'Menu',
            style: UIStyle.menuTextStyle,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                resetGame();
              },
              child: Text('Restart', style: UIStyle.buttonTextStyle.copyWith(color: UIStyle.accentColor)),
              style: UIStyle.buttonStyle(),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: Text('Back to Main Menu', style: UIStyle.buttonTextStyle.copyWith(color: UIStyle.accentColor)),
              style: UIStyle.buttonStyle(),
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
                  cups: botCups,
                  isMyTurn: currentPlayer == 2 && !isBotThinking,
                  label: 'Bot (${widget.botDifficulty})',
                  winner: winner,
                  drawMessage: drawMessage,
                  gameMode: 'single',
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
                    ? (currentPlayer == 1 ? 'Your turn' : "Bot's turn")
                    : '',
                style: UIStyle.subtitleStyle,
              ),
              if (drawMessage != null) Text(drawMessage!, style: UIStyle.subtitleStyle.copyWith(color: Colors.grey)),
              Expanded(
                flex: 1,
                child: PlayerArea(
                  player: 1,
                  cups: playerCups,
                  isMyTurn: currentPlayer == 1,
                  label: playerName,
                  winner: winner,
                  drawMessage: drawMessage,
                  gameMode: 'single',
                ),
              ),
            ],
          ),
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              icon: Icon(Icons.menu, size: 30, color: UIStyle.secondaryColor),
              onPressed: _showMenuPopup,
            ),
          ),
        ],
      ),
    );
  }
}

class PlayerArea extends StatelessWidget {
  final int player;
  final List<Map<String, dynamic>> cups;
  final bool isMyTurn;
  final String label;
  final String? winner;
  final String? drawMessage;
  final String gameMode;

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
        height: 130,
        padding: UIStyle.buttonPadding,
        decoration: BoxDecoration(
          gradient: UIStyle.gradient,
          borderRadius: UIStyle.buttonBorderRadius,
          boxShadow: [UIStyle.boxShadow],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: UIStyle.subtitleStyle.copyWith(color: Colors.black),
              ),
              SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  if (index < cups.length) {
                    return (isMyTurn && winner == null && drawMessage == null && (player == 1 || gameMode == 'single'))
                        ? Draggable<Map<String, dynamic>>(
                            data: cups[index],
                            child: CupWidget(size: cups[index]['size'], player: cups[index]['player']),
                            feedback: CupWidget(size: cups[index]['size'], player: cups[index]['player'], isDragging: true),
                            childWhenDragging: Container(width: 60, height: 60),
                          )
                        : CupWidget(size: cups[index]['size'], player: cups[index]['player']);
                  } else {
                    return Container(width: 60, height: 60);
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
      margin: EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: player == 1 ? [Colors.blue[300]!, Colors.blue[800]!] : [Colors.orange[300]!, Colors.orange[800]!],
          center: Alignment(-0.3, -0.3),
          focal: Alignment(-0.3, -0.3),
          focalRadius: 0.1,
        ),
        boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 4))],
      ),
    );
  }
}