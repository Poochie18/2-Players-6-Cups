import 'package:flutter/material.dart';
import 'package:two_players_six_cups/utils/ui_style.dart';

class DifficultyMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100]!,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Choose Difficulty',
              style: UIStyle.titleStyle,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/game', arguments: {'gameMode': 'single', 'botDifficulty': 'easy'}),
              child: Text('Easy', style: UIStyle.buttonTextStyle),
              style: UIStyle.buttonStyle(fixedWidth: 200), // Фиксированная ширина
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/game', arguments: {'gameMode': 'single', 'botDifficulty': 'medium'}),
              child: Text('Medium', style: UIStyle.buttonTextStyle),
              style: UIStyle.buttonStyle(fixedWidth: 200), // Фиксированная ширина
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/game', arguments: {'gameMode': 'single', 'botDifficulty': 'hard'}),
              child: Text('Hard', style: UIStyle.buttonTextStyle),
              style: UIStyle.buttonStyle(fixedWidth: 200), // Фиксированная ширина
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Back', style: UIStyle.buttonTextStyle),
              style: UIStyle.buttonStyle(fixedWidth: 200), // Фиксированная ширина
            ),
          ],
        ),
      ),
    );
  }
}