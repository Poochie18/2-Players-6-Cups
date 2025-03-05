import 'package:flutter/material.dart';
import '../styles/text_styles.dart';
import '../l10n/app_localizations.dart';

class MultiplayerMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 400),
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  localizations.multiplayer,
                  style: AppTextStyles.screenTitle,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                _buildMenuButton(
                  context,
                  localizations.createGame,
                  () => Navigator.pushNamed(context, '/create_game'),
                ),
                SizedBox(height: 20),
                _buildMenuButton(
                  context,
                  localizations.joinGame,
                  () => Navigator.pushNamed(context, '/join_game'),
                ),
                SizedBox(height: 20),
                _buildMenuButton(
                  context,
                  localizations.back,
                  () => Navigator.pop(context),
                  backgroundColor: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String text,
    VoidCallback onPressed, {
    Color backgroundColor = Colors.green,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 15),
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        child: Text(
          text,
          style: AppTextStyles.buttonText,
        ),
      ),
    );
  }
}