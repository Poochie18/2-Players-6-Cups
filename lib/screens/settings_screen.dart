import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String playerName = 'Player';
  bool playerGoesFirst = true; // По умолчанию игрок ходит первым
  final TextEditingController _nameController = TextEditingController(); // Контроллер для текста

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      playerName = prefs.getString('playerName') ?? 'Player';
      playerGoesFirst = prefs.getBool('playerGoesFirst') ?? true; // Загружаем настройку
      _nameController.text = playerName; // Устанавливаем текст в контроллер
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('playerName', playerName);
    await prefs.setBool('playerGoesFirst', playerGoesFirst);
    print('Settings saved - Player Name: $playerName, Player Goes First: $playerGoesFirst'); // Дебаг для проверки
  }

  @override
  void dispose() {
    _nameController.dispose();
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
              'Settings',
              style: TextStyle(
                fontSize: 48,
                color: Colors.blueGrey,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 2)],
              ),
            ),
            SizedBox(height: 30),
            Container(
              padding: EdgeInsets.all(16),
              width: 300, // Уменьшенная ширина контейнера настроек
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController, // Поле для ввода имени
                    decoration: InputDecoration(
                      labelText: 'Player Name',
                      labelStyle: TextStyle(color: Colors.blueGrey, fontSize: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (value) {
                      setState(() {
                        playerName = value.trim(); // Убираем лишние пробелы и сохраняем как есть
                      });
                      _saveSettings();
                    },
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Player Goes First',
                        style: TextStyle(fontSize: 18, color: Colors.blueGrey),
                      ),
                      Switch(
                        value: playerGoesFirst,
                        onChanged: (value) {
                          setState(() {
                            playerGoesFirst = value;
                          });
                          _saveSettings();
                        },
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Back', style: TextStyle(color: Colors.white, fontSize: 20)),
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