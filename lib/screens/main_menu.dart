import 'package:flutter/material.dart';
import 'package:two_players_six_cups/utils/ui_style.dart';

class MainMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100]!,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Two Players,\nSix Cups',
              style: UIStyle.titleStyle,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/difficulty'),
              child: Text('Single Player', style: UIStyle.buttonTextStyle),
              style: UIStyle.buttonStyle(fixedWidth: 200),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/multiplayer'),
              child: Text('Multiplayer', style: UIStyle.buttonTextStyle),
              style: UIStyle.buttonStyle(fixedWidth: 200),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/settings'),
              child: Text('Settings', style: UIStyle.buttonTextStyle),
              style: UIStyle.buttonStyle(fixedWidth: 200),
            ),
          ],
        ),
      ),
    );
  }
}