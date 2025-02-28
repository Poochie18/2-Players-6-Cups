import 'package:flutter/material.dart';

class UIStyle {
  static const Color primaryColor = const Color(0xFF4CAF50); // Убрали ненужный '!'
  static const Color secondaryColor = Colors.blueGrey;
  static const Color accentColor = Colors.white;
  static const Color errorColor = Colors.red;

  static const LinearGradient gradient = LinearGradient(
    colors: [const Color(0xFF90EE90)!, const Color(0xFF228B22)!], // Оставляем '!' здесь, так как Colors могут быть nullable
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const BorderRadius buttonBorderRadius = BorderRadius.all(Radius.circular(12));
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 30, vertical: 15);
  static const BoxShadow boxShadow = BoxShadow(
    color: Colors.black26,
    blurRadius: 6,
    offset: Offset(0, 2),
  );

  static ButtonStyle buttonStyle({Color? backgroundColor, Color? textColor, double? fixedWidth}) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? primaryColor,
      foregroundColor: textColor ?? accentColor,
      padding: buttonPadding,
      shape: RoundedRectangleBorder(borderRadius: buttonBorderRadius),
      minimumSize: Size(fixedWidth ?? 200, 0), // Фиксированная минимальная ширина
    );
  }

  static TextStyle titleStyle = TextStyle(
    fontSize: 48,
    color: secondaryColor,
    fontWeight: FontWeight.bold,
    shadows: [Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 2)],
  );

  static TextStyle subtitleStyle = TextStyle(
    fontSize: 20,
    color: secondaryColor,
    fontWeight: FontWeight.bold,
  );

  static TextStyle buttonTextStyle = TextStyle(
    fontSize: 20,
    color: accentColor,
  );

  static TextStyle menuTextStyle = TextStyle(
    fontSize: 24,
    color: secondaryColor,
    fontWeight: FontWeight.bold,
    shadows: [Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 2)],
  );

  static Widget alertDialogStyle({required String title, required Widget content}) {
    return AlertDialog(
      backgroundColor: Colors.grey[100]!,
      shape: RoundedRectangleBorder(borderRadius: buttonBorderRadius),
      content: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: buttonBorderRadius,
          boxShadow: [boxShadow],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: accentColor,
                shadows: [Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 2)],
              ),
              textAlign: TextAlign.center,
            ),
            content,
          ],
        ),
      ),
    );
  }
}