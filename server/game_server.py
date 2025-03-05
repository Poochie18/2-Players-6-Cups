import asyncio
import json
import random
import websockets
from typing import Dict, Set

class GameServer:
    def __init__(self):
        # Структура: {room_code: {'host': websocket, 'guest': websocket, 'game_state': dict}}
        self.rooms: Dict[str, dict] = {}
        # Структура: {websocket: room_code}
        self.player_rooms: Dict[websockets.WebSocketServerProtocol, str] = {}

    def generate_room_code(self) -> str:
        """Генерирует уникальный 6-значный код комнаты."""
        while True:
            code = str(random.randint(100000, 999999))
            if code not in self.rooms:
                return code

    async def register_room(self, websocket: websockets.WebSocketServerProtocol) -> str:
        """Создает новую комнату и регистрирует хоста."""
        room_code = self.generate_room_code()
        self.rooms[room_code] = {
            'host': websocket,
            'guest': None,
            'game_state': {
                'board': [[None] * 3 for _ in range(3)],
                'current_player': 1,
                'player1_cups': [
                    {'size': 'small', 'player': 1}, {'size': 'small', 'player': 1},
                    {'size': 'medium', 'player': 1}, {'size': 'medium', 'player': 1},
                    {'size': 'large', 'player': 1}, {'size': 'large', 'player': 1},
                ],
                'player2_cups': [
                    {'size': 'small', 'player': 2}, {'size': 'small', 'player': 2},
                    {'size': 'medium', 'player': 2}, {'size': 'medium', 'player': 2},
                    {'size': 'large', 'player': 2}, {'size': 'large', 'player': 2},
                ],
            }
        }
        self.player_rooms[websocket] = room_code
        return room_code

    async def join_room(self, websocket: websockets.WebSocketServerProtocol, room_code: str) -> bool:
        """Присоединяет гостя к существующей комнате."""
        if room_code not in self.rooms:
            return False
        
        room = self.rooms[room_code]
        if room['guest'] is not None:
            return False
        
        room['guest'] = websocket
        self.player_rooms[websocket] = room_code
        return True

    async def handle_disconnect(self, websocket: websockets.WebSocketServerProtocol):
        """Обрабатывает отключение игрока."""
        room_code = self.player_rooms.get(websocket)
        if room_code:
            room = self.rooms[room_code]
            other_player = None
            
            if room['host'] == websocket:
                other_player = room['guest']
                room['host'] = None
            elif room['guest'] == websocket:
                other_player = room['host']
                room['guest'] = None

            if other_player:
                try:
                    await other_player.send(json.dumps({
                        'type': 'player_disconnected'
                    }))
                except:
                    pass

            # Удаляем комнату, если оба игрока отключились
            if not room['host'] and not room['guest']:
                del self.rooms[room_code]

            del self.player_rooms[websocket]

    async def handle_message(self, websocket: websockets.WebSocketServerProtocol, message: str):
        """Обрабатывает входящие сообщения от клиентов."""
        try:
            data = json.loads(message)
            message_type = data.get('type')

            if message_type == 'create_room':
                room_code = await self.register_room(websocket)
                await websocket.send(json.dumps({
                    'type': 'room_created',
                    'roomId': room_code,
                    'playerId': 1
                }))

            elif message_type == 'join_room':
                room_code = data.get('roomId')
                if await self.join_room(websocket, room_code):
                    room = self.rooms[room_code]
                    # Отправляем сообщение гостю
                    await websocket.send(json.dumps({
                        'type': 'room_joined',
                        'roomId': room_code,
                        'playerId': 2,
                        'gameState': room['game_state']
                    }))
                    # Уведомляем хоста
                    await room['host'].send(json.dumps({
                        'type': 'player_joined',
                        'playerId': 2,
                        'gameState': room['game_state']
                    }))
                else:
                    await websocket.send(json.dumps({
                        'type': 'error',
                        'message': 'Invalid room code or room is full'
                    }))

            elif message_type == 'make_move':
                room_code = data.get('roomId')
                room = self.rooms.get(room_code)
                if room:
                    move_data = data.get('move')
                    room['game_state'] = move_data.get('gameState', room['game_state'])
                    
                    # Отправляем обновление обоим игрокам
                    message = json.dumps({
                        'type': 'game_update',
                        'gameState': room['game_state']
                    })
                    if room['host']:
                        await room['host'].send(message)
                    if room['guest']:
                        await room['guest'].send(message)

        except Exception as e:
            await websocket.send(json.dumps({
                'type': 'error',
                'message': str(e)
            }))

async def main():
    game_server = GameServer()

    async def handler(websocket):
        try:
            async for message in websocket:
                await game_server.handle_message(websocket, message)
        except websockets.ConnectionClosed:
            await game_server.handle_disconnect(websocket)

    async with websockets.serve(handler, "localhost", 8080):
        await asyncio.Future()  # run forever

if __name__ == "__main__":
    asyncio.run(main()) 