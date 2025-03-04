import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../styles/text_styles.dart';
import '../l10n/app_localizations.dart';

class LocalMultiplayerSetup extends StatefulWidget {
  @override
  _LocalMultiplayerSetupState createState() => _LocalMultiplayerSetupState();
}

class _LocalMultiplayerSetupState extends State<LocalMultiplayerSetup> {
  final TextEditingController _player1Controller = TextEditingController(text: 'Player 1');
  final TextEditingController _player2Controller = TextEditingController(text: 'Player 2');
  bool player1GoesFirst = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _player1Controller.dispose();
    _player2Controller.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _player1Controller.text = prefs.getString('player1Name') ?? 'Player 1';
        _player2Controller.text = prefs.getString('player2Name') ?? 'Player 2';
        player1GoesFirst = prefs.getBool('player1GoesFirst') ?? true;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('player1Name', _player1Controller.text);
    await prefs.setString('player2Name', _player2Controller.text);
    await prefs.setBool('player1GoesFirst', player1GoesFirst);
  }

  void _startGame() async {
    await _saveSettings();
    Navigator.pushNamed(
      context,
      '/game',
      arguments: {
        'gameMode': 'local',
        'player1Name': _player1Controller.text,
        'player2Name': _player2Controller.text,
        'player1GoesFirst': player1GoesFirst,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.green)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    localizations.twoPlayers,
                    style: AppTextStyles.screenTitle,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                  Container(
                    padding: EdgeInsets.all(16),
                    width: 300,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _player1Controller,
                          decoration: InputDecoration(
                            labelText: 'Player 1',
                            labelStyle: TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 18,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        TextField(
                          controller: _player2Controller,
                          decoration: InputDecoration(
                            labelText: 'Player 2',
                            labelStyle: TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 18,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Player 1 goes first',
                              style: AppTextStyles.settingsLabel,
                            ),
                            Switch(
                              value: player1GoesFirst,
                              onChanged: (value) {
                                setState(() {
                                  player1GoesFirst = value;
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
                          child: Text(
                            localizations.back,
                            style: AppTextStyles.buttonText,
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      SizedBox(
                        width: 140,
                        child: ElevatedButton(
                          onPressed: _startGame,
                          child: Text(
                            localizations.playAgain,
                            style: AppTextStyles.buttonText,
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
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