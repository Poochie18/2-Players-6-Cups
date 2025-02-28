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
              style: UIStyle.buttonStyle(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/multiplayer'),
              child: Text('Multiplayer', style: UIStyle.buttonTextStyle),
              style: UIStyle.buttonStyle(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/settings'),
              child: Text('Settings', style: UIStyle.buttonTextStyle),
              style: UIStyle.buttonStyle(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.grey[100]!,
                    shape: RoundedRectangleBorder(borderRadius: UIStyle.buttonBorderRadius),
                    content: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: UIStyle.gradient,
                        borderRadius: UIStyle.buttonBorderRadius,
                        boxShadow: [UIStyle.boxShadow],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Exit Game',
                            style: UIStyle.menuTextStyle.copyWith(color: UIStyle.accentColor),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Are you sure you want to exit?',
                            style: UIStyle.subtitleStyle.copyWith(color: UIStyle.accentColor),
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('No', style: TextStyle(color: UIStyle.primaryColor, fontSize: 16)),
                                style: UIStyle.buttonStyle(backgroundColor: UIStyle.accentColor, textColor: UIStyle.primaryColor),
                              ),
                              SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                                child: Text('Yes', style: TextStyle(color: UIStyle.errorColor, fontSize: 16)),
                                style: UIStyle.buttonStyle(backgroundColor: UIStyle.accentColor, textColor: UIStyle.errorColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              child: Text('Exit', style: UIStyle.buttonTextStyle),
              style: UIStyle.buttonStyle(backgroundColor: UIStyle.errorColor),
            ),
          ],
        ),
      ),
    );
  }
}