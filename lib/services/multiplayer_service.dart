import 'dart:math';
import 'dart:async';

class MultiplayerService {
  static final MultiplayerService _instance = MultiplayerService._internal();
  factory MultiplayerService() => _instance;
  MultiplayerService._internal();

  // Хранилище комнат: {room_code: {host: bool, gameState: Map}}
  final Map<String, Map<String, dynamic>> _rooms = {};
  
  // Потоки для обновлений состояния игры
  final Map<String, StreamController<Map<String, dynamic>>> _gameStateControllers = {};

  // Колбэки
  Function(String)? _onError;
  Function(Map<String, dynamic>)? _onGameStateUpdate;
  Function(Map<String, dynamic>)? _onMove;

  // Генерация 6-значного кода комнаты
  String generateRoomCode() {
    final random = Random();
    String code;
    do {
      code = (100000 + random.nextInt(900000)).toString();
    } while (_rooms.containsKey(code));
    return code;
  }

  // Создание комнаты
  String createRoom() {
    final roomCode = generateRoomCode();
    _rooms[roomCode] = {
      'host': true,
      'gameState': {
        'isGameStarted': false,
        'currentPlayer': 1,
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
      }
    };
    _gameStateControllers[roomCode] = StreamController<Map<String, dynamic>>.broadcast();
    return roomCode;
  }

  // Присоединение к комнате
  Future<bool> joinRoom(String roomCode) async {
    if (!_rooms.containsKey(roomCode)) {
      throw Exception('Room not found');
    }
    
    final room = _rooms[roomCode]!;
    if (room['isGameStarted'] == true) {
      throw Exception('Game already started');
    }

    room['isGameStarted'] = true;
    _gameStateControllers[roomCode]?.add({
      'type': 'player_joined',
      'gameState': room['gameState']
    });
    
    return true;
  }

  // Подписка на обновления состояния игры
  Stream<Map<String, dynamic>>? subscribeToGameState(String roomCode) {
    return _gameStateControllers[roomCode]?.stream;
  }

  // Обновление состояния игры
  void updateGameState(String roomCode, Map<String, dynamic> newState) {
    if (_rooms.containsKey(roomCode)) {
      _rooms[roomCode]!['gameState'] = newState;
      _gameStateControllers[roomCode]?.add({
        'type': 'game_update',
        'gameState': newState
      });
    }
  }

  // Сделать ход
  void makeMove(Map<String, dynamic> moveData) {
    final roomCode = moveData['roomCode'];
    if (_rooms.containsKey(roomCode)) {
      _gameStateControllers[roomCode]?.add({
        'type': 'move_made',
        'move': moveData
      });
    }
  }

  // Проверка существования комнаты
  bool roomExists(String roomCode) {
    return _rooms.containsKey(roomCode);
  }

  // Закрытие комнаты
  void closeRoom(String roomCode) {
    _gameStateControllers[roomCode]?.close();
    _gameStateControllers.remove(roomCode);
    _rooms.remove(roomCode);
  }

  // Установка колбэков
  void setErrorCallback(Function(String) callback) {
    _onError = callback;
  }

  void setGameStateUpdateCallback(Function(Map<String, dynamic>) callback) {
    _onGameStateUpdate = callback;
  }

  void setMoveCallback(Function(Map<String, dynamic>) callback) {
    _onMove = callback;
  }

  // Подключение к серверу (в нашем случае это заглушка)
  void connect(String serverUrl) {
    // В локальной версии ничего не делаем
  }

  // Отключение от сервера (в нашем случае это заглушка)
  void disconnect() {
    // В локальной версии ничего не делаем
  }
} 