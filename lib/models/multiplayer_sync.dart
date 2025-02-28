import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:async';

class MultiplayerSync {
  final String roomCode;
  String? gameFilePath;

  MultiplayerSync(this.roomCode);

  Future<void> initialize() async {
    final directory = await getApplicationDocumentsDirectory();
    gameFilePath = '${directory.path}/multiplayer_game_$roomCode.json';
    await _createGameFileIfNotExists();
  }

  Future<void> _createGameFileIfNotExists() async {
    if (gameFilePath != null) {
      final file = File(gameFilePath!);
      if (!await file.exists()) {
        await file.create(recursive: true);
        await file.writeAsString(jsonEncode({
          'board': List.generate(3, (_) => List.filled(3, null)),
          'player1Cups': [
            {'size': 'small', 'player': 1}, {'size': 'small', 'player': 1},
            {'size': 'medium', 'player': 1}, {'size': 'medium', 'player': 1},
            {'size': 'large', 'player': 1}, {'size': 'large', 'player': 1},
          ],
          'player2Cups': [
            {'size': 'small', 'player': 2}, {'size': 'small', 'player': 2},
            {'size': 'medium', 'player': 2}, {'size': 'medium', 'player': 2},
            {'size': 'large', 'player': 2}, {'size': 'large', 'player': 2},
          ],
          'currentPlayer': 1,
          'winner': null,
          'drawMessage': null,
          'isGameActive': false,
        }));
      }
    }
  }

  Future<Map<String, dynamic>> loadGameState() async {
    if (gameFilePath != null) {
      final file = File(gameFilePath!);
      if (await file.exists()) {
        final content = await file.readAsString();
        return jsonDecode(content) as Map<String, dynamic>;
      }
    }
    return {
      'board': List.generate(3, (_) => List.filled(3, null)),
      'player1Cups': [
        {'size': 'small', 'player': 1}, {'size': 'small', 'player': 1},
        {'size': 'medium', 'player': 1}, {'size': 'medium', 'player': 1},
        {'size': 'large', 'player': 1}, {'size': 'large', 'player': 1},
      ],
      'player2Cups': [
        {'size': 'small', 'player': 2}, {'size': 'small', 'player': 2},
        {'size': 'medium', 'player': 2}, {'size': 'medium', 'player': 2},
        {'size': 'large', 'player': 2}, {'size': 'large', 'player': 2},
      ],
      'currentPlayer': 1,
      'winner': null,
      'drawMessage': null,
      'isGameActive': false,
    };
  }

  Future<void> saveGameState({
    required List<List<Map<String, dynamic>?>> board,
    required List<Map<String, dynamic>> player1Cups,
    required List<Map<String, dynamic>> player2Cups,
    required int currentPlayer,
    String? winner,
    String? drawMessage,
    required bool isGameActive,
  }) async {
    if (gameFilePath != null) {
      final file = File(gameFilePath!);
      await file.writeAsString(jsonEncode({
        'board': board,
        'player1Cups': player1Cups,
        'player2Cups': player2Cups,
        'currentPlayer': currentPlayer,
        'winner': winner,
        'drawMessage': drawMessage,
        'isGameActive': isGameActive,
      }));
    }
  }

  void startPeriodicSync(void Function(Map<String, dynamic>) onStateChanged) {
    Timer.periodic(Duration(milliseconds: 500), (timer) async {
      final state = await loadGameState();
      onStateChanged(state);
    });
  }
}