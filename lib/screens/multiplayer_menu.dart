import 'package:flutter/material.dart';
import 'dart:math';
import 'package:two_players_six_cups/utils/ui_style.dart';

class MultiplayerMenu extends StatefulWidget {
  @override
  _MultiplayerMenuState createState() => _MultiplayerMenuState();
}

class _MultiplayerMenuState extends State<MultiplayerMenu> {
  @override
  void dispose() {
    super.dispose();
  }

  String _generateRoomCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString(); // 6-значный код
  }

  void _createGame() {
    final roomCode = _generateRoomCode();
    Navigator.pushNamed(
      context,
      '/game',
      arguments: {
        'gameMode': 'multiplayer',
        'roomCode': roomCode,
        'isLocal': true,
        'isHost': true,
        'isJoining': false,
      },
    );
  }

  void _joinGame() {
    showDialog(
      context: context,
      builder: (context) => UIStyle.alertDialogStyle(
        title: 'Join Game',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Enter 6-Digit Room Code',
                labelStyle: UIStyle.subtitleStyle.copyWith(color: UIStyle.secondaryColor),
                border: OutlineInputBorder(borderRadius: UIStyle.buttonBorderRadius),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              onChanged: (value) {
                if (value.length == 6 && int.tryParse(value) != null) {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/game',
                    arguments: {
                      'gameMode': 'multiplayer',
                      'roomCode': value,
                      'isLocal': true,
                      'isHost': false,
                      'isJoining': true,
                    },
                  );
                }
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: UIStyle.buttonTextStyle.copyWith(color: UIStyle.accentColor)),
              style: UIStyle.buttonStyle(fixedWidth: 200), // Фиксированная ширина
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Multiplayer',
              style: UIStyle.titleStyle,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _createGame,
              child: Text('Create Game', style: UIStyle.buttonTextStyle),
              style: UIStyle.buttonStyle(fixedWidth: 200), // Фиксированная ширина
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _joinGame,
              child: Text('Join Game', style: UIStyle.buttonTextStyle),
              style: UIStyle.buttonStyle(fixedWidth: 200), // Фиксированная ширина
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Back', style: UIStyle.buttonTextStyle),
              style: UIStyle.buttonStyle(fixedWidth: 200), // Фиксированная ширина
            ),
          ],
        ),
      ),
    );
  }
}