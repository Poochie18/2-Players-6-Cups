import 'package:flutter/material.dart';
import '../main.dart';

class LanguageSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Locale>(
      icon: Icon(Icons.language),
      onSelected: (Locale locale) {
        MyApp.of(context).setLocale(locale);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
        PopupMenuItem<Locale>(
          value: Locale('en'),
          child: Text('English'),
        ),
        PopupMenuItem<Locale>(
          value: Locale('de'),
          child: Text('Deutsch'),
        ),
        PopupMenuItem<Locale>(
          value: Locale('uk'),
          child: Text('Українська'),
        ),
        PopupMenuItem<Locale>(
          value: Locale('zh'),
          child: Text('中文'),
        ),
        PopupMenuItem<Locale>(
          value: Locale('fr'),
          child: Text('Français'),
        ),
      ],
    );
  }
} 