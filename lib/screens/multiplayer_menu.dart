import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class MultiplayerMenu extends StatefulWidget {
  @override
  _MultiplayerMenuState createState() => _MultiplayerMenuState();
}

class _MultiplayerMenuState extends State<MultiplayerMenu> {
  String _mode = 'Local'; // По умолчанию локальный мультиплеер
  final _roomCodeController = TextEditingController();

  void _startGame() {
    final roomCode = _roomCodeController.text.trim();
    Navigator.pushNamed(
      context,
      '/game',
      arguments: {
        'gameMode': 'multiplayer',
        'roomCode': roomCode.isEmpty ? 'LOCAL123' : roomCode,
        'isLocal': _mode == 'Local',
        'isHost': true, // Локальный мультиплеер всегда начинается с хоста
      },
    );
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
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
              style: TextStyle(
                fontSize: 48,
                color: Colors.blueGrey,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 2)],
              ),
            ),
            SizedBox(height: 30),
            DropdownButton<String>(
              value: _mode,
              onChanged: (String? newValue) {
                setState(() {
                  _mode = newValue!;
                });
              },
              items: <String>['Local', 'Online'].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: TextStyle(fontSize: 20, color: Colors.blueGrey)),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            if (_mode == 'Local')
              TextField(
                controller: _roomCodeController,
                decoration: InputDecoration(
                  labelText: 'Room Code (optional)',
                  labelStyle: TextStyle(color: Colors.blueGrey, fontSize: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: _startGame,
                child: Text('Start Game', style: TextStyle(color: Colors.white, fontSize: 20)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
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
}