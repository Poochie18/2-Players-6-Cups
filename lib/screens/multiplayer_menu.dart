import 'package:flutter/material.dart';
import 'dart:math';
import 'package:two_players_six_cups/utils/ui_style.dart';

class MultiplayerMenu extends StatefulWidget {
  @override
  _MultiplayerMenuState createState() => _MultiplayerMenuState();
}

class _MultiplayerMenuState extends State<MultiplayerMenu> {
  final _roomCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _roomCodeController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
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
    final roomCode = _roomCodeController.text.trim();
    if (roomCode.length == 6 && int.tryParse(roomCode) != null) {
      Navigator.pushNamed(
        context,
        '/game',
        arguments: {
          'gameMode': 'multiplayer',
          'roomCode': roomCode,
          'isLocal': true,
          'isHost': false,
          'isJoining': true,
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => UIStyle.alertDialogStyle(
          title: 'Error',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Please enter a valid 6-digit room code.',
                style: UIStyle.subtitleStyle.copyWith(color: UIStyle.accentColor),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK', style: TextStyle(color: UIStyle.primaryColor, fontSize: 16)),
                style: UIStyle.buttonStyle(backgroundColor: UIStyle.accentColor, textColor: UIStyle.primaryColor),
              ),
            ],
          ),
        ),
      );
    }
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
              style: UIStyle.buttonStyle(),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _roomCodeController,
              decoration: InputDecoration(
                labelText: 'Enter 6-Digit Room Code',
                labelStyle: UIStyle.subtitleStyle.copyWith(color: UIStyle.secondaryColor),
                border: OutlineInputBorder(borderRadius: UIStyle.buttonBorderRadius),
                errorText: _roomCodeController.text.length == 6 && int.tryParse(_roomCodeController.text) == null
                    ? 'Code must be numeric'
                    : null,
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _joinGame,
              child: Text('Join Game', style: UIStyle.buttonTextStyle),
              style: UIStyle.buttonStyle(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Back', style: UIStyle.buttonTextStyle),
              style: UIStyle.buttonStyle(),
            ),
          ],
        ),
      ),
    );
  }
}