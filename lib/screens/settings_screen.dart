import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../styles/text_styles.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String playerName = 'Player';
  bool playerGoesFirst = true;
  bool _isLoading = true;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        playerName = prefs.getString('playerName') ?? 'Player';
        playerGoesFirst = prefs.getBool('playerGoesFirst') ?? true;
        _nameController.text = playerName;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('playerName', playerName);
    await prefs.setBool('playerGoesFirst', playerGoesFirst);
  }

  void _showLanguageDialog() {
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  localizations.selectLanguage,
                  style: AppTextStyles.screenTitle.copyWith(
                    fontSize: 24,
                    color: Colors.green[700],
                  ),
                ),
                SizedBox(height: 20),
                _buildLanguageButton('🇬🇧 English', 'en'),
                _buildLanguageButton('🇺🇦 Українська', 'uk'),
                _buildLanguageButton('🇩🇪 Deutsch', 'de'),
                _buildLanguageButton('🇨🇳 中文', 'zh'),
                _buildLanguageButton('🇫🇷 Français', 'fr'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageButton(String label, String code) {
    final isCurrentLanguage = Localizations.localeOf(context).languageCode == code;
    
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 5),
      child: ElevatedButton(
        onPressed: () {
          MyApp.of(context).setLocale(Locale(code));
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isCurrentLanguage ? Colors.green[700] : Colors.green,
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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
                  Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: Text(
                      localizations.settings,
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
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: localizations.playerName,
                            labelStyle: TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 18,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              playerName = value.trim();
                            });
                            _saveSettings();
                          },
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              localizations.playerGoesFirst,
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
                        SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showLanguageDialog,
                            icon: Icon(Icons.language, size: 24),
                            label: Text(
                              localizations.changeLanguage,
                              style: AppTextStyles.buttonText,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        localizations.back,
                        style: AppTextStyles.buttonText,
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
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
      ),
    );
  }
}