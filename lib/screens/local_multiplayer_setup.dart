import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:two_players_six_cups/styles/text_styles.dart';

class LocalMultiplayerSetup extends StatefulWidget {
  @override
  _LocalMultiplayerSetupState createState() => _LocalMultiplayerSetupState();
}

class _LocalMultiplayerSetupState extends State<LocalMultiplayerSetup> {
  final TextEditingController _player1Controller = TextEditingController();
  final TextEditingController _player2Controller = TextEditingController();
  bool _isLoading = true;
  bool _player1GoesFirst = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _player1Controller.text = prefs.getString('playerName') ?? 'Player 1';
        _player2Controller.text = prefs.getString('player2Name') ?? 'Player 2';
        _player1GoesFirst = prefs.getBool('playerGoesFirst') ?? true;
        _isLoading = false;
      });
    }
  }

  Future<void> _savePlayer2Name() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('player2Name', _player2Controller.text.trim());
  }

  @override
  void dispose() {
    _player1Controller.dispose();
    _player2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100]!,
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.green)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: Text(
                      'Local Multiplayer',
                      style: AppTextStyles.screenTitle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 30),
                  Container(
                    padding: EdgeInsets.all(16),
                    width: 300,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _player1Controller,
                          decoration: InputDecoration(
                            labelText: 'Player 1 Name',
                            labelStyle: TextStyle(color: Colors.blue, fontSize: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        SizedBox(height: 20),
                        TextField(
                          controller: _player2Controller,
                          decoration: InputDecoration(
                            labelText: 'Player 2 Name',
                            labelStyle: TextStyle(color: Colors.orange, fontSize: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Player 1 Goes First',
                              style: AppTextStyles.settingsLabel,
                            ),
                            Switch(
                              value: _player1GoesFirst,
                              onChanged: (value) {
                                setState(() {
                                  _player1GoesFirst = value;
                                });
                              },
                              activeColor: Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 140,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Back', style: AppTextStyles.buttonText),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      SizedBox(
                        width: 140,
                        child: ElevatedButton(
                          onPressed: () {
                            // Сохраняем имя второго игрока
                            _savePlayer2Name();
                            
                            // Передаем параметры в игровой экран
                            Navigator.pushNamed(
                              context, 
                              '/game',
                              arguments: {
                                'gameMode': 'local_multiplayer',
                                'player1Name': _player1Controller.text.trim(),
                                'player2Name': _player2Controller.text.trim(),
                                'player1GoesFirst': _player1GoesFirst,
                              },
                            );
                          },
                          child: Text('Start Game', style: AppTextStyles.buttonText),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
} 