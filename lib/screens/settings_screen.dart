import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:two_players_six_cups/utils/ui_style.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _playerGoesFirst;
  late String _playerName;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _playerGoesFirst = prefs.getBool('playerGoesFirst') ?? true;
      _playerName = prefs.getString('playerName') ?? 'Player';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('playerGoesFirst', _playerGoesFirst);
    await prefs.setString('playerName', _playerName);
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
              'Settings',
              style: UIStyle.titleStyle,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Player Goes First: ',
                  style: UIStyle.subtitleStyle,
                ),
                Switch(
                  value: _playerGoesFirst,
                  onChanged: (value) {
                    setState(() {
                      _playerGoesFirst = value;
                      _saveSettings();
                    });
                  },
                  activeColor: UIStyle.primaryColor,
                ),
              ],
            ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: 'Player Name',
                labelStyle: UIStyle.subtitleStyle.copyWith(color: UIStyle.secondaryColor),
                border: OutlineInputBorder(borderRadius: UIStyle.buttonBorderRadius),
              ),
              controller: TextEditingController(text: _playerName),
              onChanged: (value) {
                setState(() {
                  _playerName = value;
                  _saveSettings();
                });
              },
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