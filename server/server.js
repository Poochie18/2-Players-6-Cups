const WebSocket = require('ws');
const http = require('http');
const server = http.createServer();
const wss = new WebSocket.Server({ server });

const rooms = new Map();

wss.on('connection', (ws) => {
    console.log('New client connected');
    let roomId = null;
    let playerId = null;

    ws.on('message', (message) => {
        try {
            const data = JSON.parse(message);
            
            switch (data.type) {
                case 'create_room':
                    roomId = Math.random().toString(36).substring(2, 8);
                    playerId = '1';
                    rooms.set(roomId, {
                        players: new Map([[playerId, ws]]),
                        gameState: {
                            currentPlayer: '1',
                            cups: Array(6).fill(6),
                            scores: { '1': 0, '2': 0 }
                        }
                    });
                    ws.send(JSON.stringify({ type: 'room_created', roomId, playerId }));
                    break;

                case 'join_room':
                    if (rooms.has(data.roomId)) {
                        const room = rooms.get(data.roomId);
                        if (room.players.size < 2) {
                            roomId = data.roomId;
                            playerId = '2';
                            room.players.set(playerId, ws);
                            
                            // Notify both players that game can start
                            room.players.get('1').send(JSON.stringify({ 
                                type: 'player_joined',
                                gameState: room.gameState
                            }));
                            ws.send(JSON.stringify({ 
                                type: 'room_joined',
                                playerId,
                                gameState: room.gameState
                            }));
                        } else {
                            ws.send(JSON.stringify({ type: 'error', message: 'Room is full' }));
                        }
                    } else {
                        ws.send(JSON.stringify({ type: 'error', message: 'Room not found' }));
                    }
                    break;

                case 'make_move':
                    if (rooms.has(roomId)) {
                        const room = rooms.get(roomId);
                        const gameState = room.gameState;
                        
                        if (gameState.currentPlayer === playerId) {
                            // Update game state based on move
                            // TODO: Implement game logic here
                            
                            // Broadcast new state to both players
                            room.players.forEach((playerWs) => {
                                playerWs.send(JSON.stringify({
                                    type: 'game_update',
                                    gameState
                                }));
                            });
                        }
                    }
                    break;
            }
        } catch (e) {
            console.error('Error processing message:', e);
        }
    });

    ws.on('close', () => {
        console.log('Client disconnected');
        if (roomId && rooms.has(roomId)) {
            const room = rooms.get(roomId);
            room.players.delete(playerId);
            
            if (room.players.size === 0) {
                rooms.delete(roomId);
            } else {
                // Notify remaining player
                room.players.forEach((playerWs) => {
                    playerWs.send(JSON.stringify({ type: 'player_disconnected' }));
                });
            }
        }
    });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
}); 