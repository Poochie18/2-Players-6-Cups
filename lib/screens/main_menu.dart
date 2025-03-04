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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              alignment: Alignment.center,
              child: Text(
                '2 Players 6 Cups',
                style: AppTextStyles.screenTitle.copyWith(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                  shadows: [
                    Shadow(
                      offset: Offset(2.0, 2.0),
                      blurRadius: 3.0,
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 50),
            _buildMenuButton(
              context,
              localizations.singlePlayer,
              () => Navigator.pushNamed(context, '/difficulty'),
              Colors.green,
            ),
            SizedBox(height: 20),
            _buildMenuButton(
              context,
              localizations.twoPlayers,
              () => Navigator.pushNamed(context, '/local_multiplayer'),
              Colors.green,
            ),
            SizedBox(height: 20),
            _buildMenuButton(
              context,
              localizations.settings,
              () => Navigator.pushNamed(context, '/settings'),
              Colors.green,
            ),
            SizedBox(height: 20),
            _buildMenuButton(
              context,
              localizations.exit,
              () => SystemNavigator.pop(),
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String text, VoidCallback onPressed, Color color) {
    return SizedBox(
      width: 200,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: AppTextStyles.buttonText,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}