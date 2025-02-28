import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:two_players_six_cups/models/game_logic.dart';
import 'package:two_players_six_cups/models/multiplayer_sync.dart';
import 'package:two_players_six_cups/utils/ui_style.dart';

class MultiplayerGameScreen extends StatefulWidget {
  final String roomCode;
  final bool isHost;
  final bool isJoining;

  MultiplayerGameScreen({required this.roomCode, required this.isHost, required this.isJoining});

  @override
  _MultiplayerGameScreenState createState() => _MultiplayerGameScreenState();
}

class _MultiplayerGameScreenState extends State<MultiplayerGameScreen> {
  int currentPlayer = 1; // 1 = Player 1 (Host), 2 = Player 2 (Joining)
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
  String? drawMessage;
  bool isWaitingForPlayer2 = false;
  bool isGameActive = false;
  late MultiplayerSync sync;
  String playerName = 'Player';

  @override
  void initState() {
    super.initState();
    sync = MultiplayerSync(widget.roomCode);
    _loadSettings().then((_) {
      _initializeGame();
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      playerName = prefs.getString('playerName') ?? 'Player';
      currentPlayer = widget.isHost ? 1 : 2;
    });
  }

  void _initializeGame() async {
    await sync.initialize();
    sync.startPeriodicSync((state) {
      if (mounted) {
        setState(() {
          board = List<List<Map<String, dynamic>?>>.from(
            (state['board'] as List).map((row) => List<Map<String, dynamic>?>.from(row.map((cell) => cell != null ? Map<String, dynamic>.from(cell) : null))),
          );
          player1Cups = List<Map<String, dynamic>>.from(state['player1Cups'].map((cup) => Map<String, dynamic>.from(cup)));
          player2Cups = List<Map<String, dynamic>>.from(state['player2Cups'].map((cup) => Map<String, dynamic>.from(cup)));
          currentPlayer = state['currentPlayer'] as int;
          winner = state['winner'] as String?;
          drawMessage = state['drawMessage'] as String?;
          isGameActive = state['isGameActive'] as bool? ?? false;
          if (widget.isHost && !isGameActive) {
            isWaitingForPlayer2 = true;
          } else if (isGameActive) {
            isWaitingForPlayer2 = false;
          }
        });
      }
    });
    if (widget.isHost && !isGameActive) {
      setState(() {
        isWaitingForPlayer2 = true;
      });
    }
  }

  void _handleMyMove(Map<String, dynamic> data, int index) {
    if (!isGameActive || currentPlayer != (widget.isHost ? 1 : 2) || winner != null || drawMessage != null) return;

    final row = index ~/ 3;
    final col = index % 3;
    final existingCup = board[row][col];

    if (existingCup != null && !GameLogic.canPlace(data['size'], existingCup, currentPlayer)) return;

    setState(() {
      board[row][col] = data;
      if (currentPlayer == 1) {
        player1Cups.remove(data);
      } else {
        player2Cups.remove(data);
      }
      print('${currentPlayer == 1 ? playerName : 'Opponent'} placed ${data['size']} at ($row, $col). Cups left: ${currentPlayer == 1 ? player1Cups.length : player2Cups.length}');
      _checkGameEnd();
      if (winner == null && drawMessage == null) {
        currentPlayer = 3 - currentPlayer;
        _saveGameState();
      }
    });
  }

  void _checkGameEnd() {
    if (GameLogic.checkWin(board, 1)) {
      setState(() {
        winner = playerName;
        _showWinDialog(playerName);
      });
      _saveGameState();
    } else if (GameLogic.checkWin(board, 2)) {
      setState(() {
        winner = 'Opponent';
        _showWinDialog('Opponent');
      });
      _saveGameState();
    } else if (!GameLogic.canPlayerMove(board, player1Cups, 1) && !GameLogic.canPlayerMove(board, player2Cups, 2)) {
      setState(() {
        drawMessage = 'Draw! No moves possible for either player.';
        _showDrawDialog();
      });
      _saveGameState();
    } else if (player1Cups.isEmpty && player2Cups.isEmpty) {
      setState(() {
        drawMessage = 'Draw! Both players are out of cups.';
        _showDrawDialog();
      });
      _saveGameState();
    }
  }

  void _saveGameState() {
    sync.saveGameState(
      board: board,
      player1Cups: player1Cups,
      player2Cups: player2Cups,
      currentPlayer: currentPlayer,
      winner: winner,
      drawMessage: drawMessage,
      isGameActive: isGameActive,
    );
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
      currentPlayer = widget.isHost ? 1 : 2;
      winner = null;
      drawMessage = null;
      isGameActive = true;
      isWaitingForPlayer2 = widget.isHost && !isGameActive;
      _saveGameState();
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
    if (widget.isHost && isWaitingForPlayer2) {
      return Scaffold(
        backgroundColor: Colors.grey[100]!,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Room Code: ${widget.roomCode}',
                style: UIStyle.subtitleStyle,
              ),
              SizedBox(height: 20),
              Text(
                'Waiting for second player...',
                style: UIStyle.subtitleStyle,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: Text('Cancel', style: UIStyle.buttonTextStyle.copyWith(color: UIStyle.accentColor)),
                style: UIStyle.buttonStyle(backgroundColor: UIStyle.errorColor),
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
                  cups: widget.isHost ? player2Cups : player1Cups,
                  isMyTurn: currentPlayer == 2 && !isGameActive,
                  label: 'Opponent',
                  winner: winner,
                  drawMessage: drawMessage,
                  gameMode: 'multiplayer',
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
                    ? (currentPlayer == (widget.isHost ? 1 : 2) ? 'Your turn' : "Opponent's turn")
                    : '',
                style: UIStyle.subtitleStyle,
              ),
              if (drawMessage != null) Text(drawMessage!, style: UIStyle.subtitleStyle.copyWith(color: Colors.grey)),
              Expanded(
                flex: 1,
                child: PlayerArea(
                  player: 1,
                  cups: widget.isHost ? player1Cups : player2Cups,
                  isMyTurn: currentPlayer == 1 && isGameActive,
                  label: playerName,
                  winner: winner,
                  drawMessage: drawMessage,
                  gameMode: 'multiplayer',
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
    final cupWidth = 60.0;
    final totalCupsWidth = cupWidth * 6 + 80;
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