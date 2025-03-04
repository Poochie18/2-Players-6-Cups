import 'package:flutter/material.dart';
import '../styles/text_styles.dart';
import '../l10n/app_localizations.dart';

class DifficultyMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              localizations.selectDifficulty,
              style: AppTextStyles.screenTitle,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 50),
            _buildDifficultyButton(
              context,
              localizations.easy,
              () => Navigator.pushNamed(context, '/game', arguments: 'easy'),
            ),
            SizedBox(height: 20),
            _buildDifficultyButton(
              context,
              localizations.medium,
              () => Navigator.pushNamed(context, '/game', arguments: 'medium'),
            ),
            SizedBox(height: 20),
            _buildDifficultyButton(
              context,
              localizations.hard,
              () => Navigator.pushNamed(context, '/game', arguments: 'hard'),
            ),
            SizedBox(height: 20),
            _buildDifficultyButton(
              context,
              localizations.back,
              () => Navigator.pop(context),
              isBackButton: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(BuildContext context, String text, VoidCallback onPressed, {bool isBackButton = false}) {
    return SizedBox(
      width: 200,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          backgroundColor: isBackButton ? Colors.grey : Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        child: Text(text, style: AppTextStyles.buttonText),
      ),
    );
  }
}