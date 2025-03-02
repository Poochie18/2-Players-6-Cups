import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:two_players_six_cups/styles/text_styles.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String playerName = 'Player';
  bool playerGoesFirst = true; // По умолчанию игрок ходит первым
  bool soundEnabled = true; // По умолчанию звук включен
  final TextEditingController _nameController = TextEditingController(); // Контроллер для текста
  bool _isLoading = true; // Флаг загрузки настроек

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        playerName = prefs.getString('playerName') ?? 'Player';
        playerGoesFirst = prefs.getBool('playerGoesFirst') ?? true;
        soundEnabled = prefs.getBool('soundEnabled') ?? true;
        _nameController.text = playerName; // Устанавливаем текст в контроллер
        _isLoading = false; // Настройки загружены
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('playerName', playerName);
    await prefs.setBool('playerGoesFirst', playerGoesFirst);
    await prefs.setBool('soundEnabled', soundEnabled);
    print('Settings saved - Player Name: $playerName, Player Goes First: $playerGoesFirst, Sound Enabled: $soundEnabled');
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
        child: _isLoading 
          ? CircularProgressIndicator(color: Colors.green) // Показываем индикатор загрузки
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: Text(
                    'Settings',
                    style: AppTextStyles.screenTitle,
                    textAlign: TextAlign.center,
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Player Goes First',
                            style: AppTextStyles.settingsLabel,
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
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Sound Enabled',
                            style: AppTextStyles.settingsLabel,
                          ),
                          Switch(
                            value: soundEnabled,
                            onChanged: (value) {
                              setState(() {
                                soundEnabled = value;
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
                    child: Text('Back', style: AppTextStyles.buttonText),
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