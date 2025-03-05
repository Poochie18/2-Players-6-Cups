import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../styles/text_styles.dart';
import '../l10n/app_localizations.dart';

class MainMenu extends StatelessWidget {
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
                  'Two Players Six Cups',
                  style: AppTextStyles.screenTitle,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                _buildMenuButton(
                  context,
                  localizations.singlePlayer,
                  () => Navigator.pushNamed(context, '/difficulty'),
                ),
                SizedBox(height: 20),
                _buildMenuButton(
                  context,
                  localizations.localMultiplayer,
                  () => Navigator.pushNamed(context, '/local_multiplayer'),
                ),
                SizedBox(height: 20),
                _buildMenuButton(
                  context,
                  localizations.multiplayer,
                  () => Navigator.pushNamed(context, '/multiplayer'),
                ),
                SizedBox(height: 20),
                _buildMenuButton(
                  context,
                  localizations.settings,
                  () => Navigator.pushNamed(context, '/settings'),
                ),
                SizedBox(height: 20),
                _buildMenuButton(
                  context,
                  localizations.exit,
                  () => SystemNavigator.pop(),
                  backgroundColor: Colors.red,
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