// Galaxy Card Game中继服务器
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    },
    // 允许二进制数据传输（游戏数据包）
    allowEIO3: true,
    transports: ['websocket', 'polling']
});

// 房间管理
const rooms = new Map();
const playerRooms = new Map(); // 玩家ID -> 房间ID

app.use(cors());
app.use(express.json());

// 静态文件服务（用于调试）
app.use(express.static('public'));

// REST API：获取房间列表
app.get('/api/rooms', (req, res) => {
    try {
        const roomList = Array.from(rooms.values()).map(room => ({
            id: room.id,
            name: room.name,
            players: room.players.length,
            maxPlayers: room.maxPlayers,
            host: room.host,
            version: room.version,
            gameMode: room.gameMode || 'standard',
            created: room.created
        }));
        res.json({
            success: true,
            rooms: roomList,
            total: roomList.length
        });
    } catch (error) {
        console.error('获取房间列表错误:', error);
        res.status(500).json({
            success: false,
            error: 'Internal server error'
        });
    }
});

// 服务器状态API
app.get('/api/status', (req, res) => {
    res.json({
        success: true,
        status: 'running',
        rooms: rooms.size,
        connections: io.engine.clientsCount,
        uptime: process.uptime(),
        memory: process.memoryUsage()
    });
});

// Socket.IO 连接处理
io.on('connection', (socket) => {
    console.log(`[${new Date().toISOString()}] 玩家连接: ${socket.id}`);

    // 创建房间
    socket.on('create-room', (roomData) => {
        try {
            console.log(`[${socket.id}] 创建房间请求:`, roomData);

            const roomId = generateRoomId();
            const room = {
                id: roomId,
                name: roomData.name || `Room ${roomId}`,
                host: socket.id,
                players: [{
                    id: socket.id,
                    isHost: true,
                    ready: false
                }],
                maxPlayers: roomData.maxPlayers || 2,
                version: roomData.version || '1.0.0',
                gameMode: roomData.gameMode || 'standard',
                created: new Date().toISOString(),
                gameData: {},
                gameStarted: false
            };

            rooms.set(roomId, room);
            playerRooms.set(socket.id, roomId);
            socket.join(roomId);

            socket.emit('room-created', {
                success: true,
                roomId,
                room: room
            });

            console.log(`[${socket.id}] 房间创建成功: ${roomId}`);
        } catch (error) {
            console.error(`[${socket.id}] 创建房间错误:`, error);
            socket.emit('room-created', {
                success: false,
                error: error.message
            });
        }
    });

    // 加入房间
    socket.on('join-room', (roomId) => {
        try {
            console.log(`[${socket.id}] 尝试加入房间: ${roomId}`);

            const room = rooms.get(roomId);
            if (!room) {
                socket.emit('join-error', {
                    success: false,
                    error: '房间不存在'
                });
                return;
            }

            if (room.players.length >= room.maxPlayers) {
                socket.emit('join-error', {
                    success: false,
                    error: '房间已满'
                });
                return;
            }

            // 检查玩家是否已在房间中
            if (room.players.find(p => p.id === socket.id)) {
                socket.emit('join-error', {
                    success: false,
                    error: '你已经在这个房间中'
                });
                return;
            }

            // 添加玩家到房间
            room.players.push({
                id: socket.id,
                isHost: false,
                ready: false
            });

            playerRooms.set(socket.id, roomId);
            socket.join(roomId);

            // 通知房间内所有玩家
            io.to(roomId).emit('player-joined', {
                success: true,
                playerId: socket.id,
                players: room.players,
                room: room
            });

            // 向新加入的玩家发送房间信息
            socket.emit('joined-room', {
                success: true,
                room: room
            });

            console.log(`[${socket.id}] 成功加入房间 ${roomId}`);
        } catch (error) {
            console.error(`[${socket.id}] 加入房间错误:`, error);
            socket.emit('join-error', {
                success: false,
                error: error.message
            });
        }
    });

    // 转发游戏数据（核心功能）
    socket.on('game-data', (data) => {
        try {
            const roomId = playerRooms.get(socket.id);
            if (!roomId) {
                console.warn(`[${socket.id}] 尝试发送游戏数据但不在任何房间中`);
                return;
            }

            const room = rooms.get(roomId);
            if (!room) {
                console.warn(`[${socket.id}] 房间 ${roomId} 不存在`);
                return;
            }

            // 转发给房间内其他玩家
            socket.to(roomId).emit('game-data', {
                from: socket.id,
                data: data,
                timestamp: Date.now()
            });

            // 可选：记录游戏数据用于调试
            // console.log(`[${socket.id}] 转发游戏数据到房间 ${roomId}`);
        } catch (error) {
            console.error(`[${socket.id}] 转发游戏数据错误:`, error);
        }
    });

    // 玩家准备状态
    socket.on('player-ready', (ready) => {
        try {
            const roomId = playerRooms.get(socket.id);
            if (!roomId) return;

            const room = rooms.get(roomId);
            if (!room) return;

            const player = room.players.find(p => p.id === socket.id);
            if (player) {
                player.ready = ready;

                // 通知房间内所有玩家
                io.to(roomId).emit('player-ready-changed', {
                    playerId: socket.id,
                    ready: ready,
                    players: room.players
                });

                console.log(`[${socket.id}] 准备状态变更: ${ready}`);
            }
        } catch (error) {
            console.error(`[${socket.id}] 处理准备状态错误:`, error);
        }
    });

    // 开始游戏
    socket.on('start-game', () => {
        try {
            const roomId = playerRooms.get(socket.id);
            if (!roomId) return;

            const room = rooms.get(roomId);
            if (!room || room.host !== socket.id) {
                socket.emit('start-game-error', '只有房主可以开始游戏');
                return;
            }

            // 检查所有玩家是否准备
            const allReady = room.players.every(p => p.ready);
            if (!allReady) {
                socket.emit('start-game-error', '有玩家未准备');
                return;
            }

            room.gameStarted = true;

            // 通知房间内所有玩家游戏开始
            io.to(roomId).emit('game-started', {
                room: room
            });

            console.log(`[${socket.id}] 游戏开始，房间: ${roomId}`);
        } catch (error) {
            console.error(`[${socket.id}] 开始游戏错误:`, error);
        }
    });

    // 离开房间
    socket.on('leave-room', () => {
        handlePlayerDisconnect(socket);
    });

    // 断线处理
    socket.on('disconnect', (reason) => {
        console.log(`[${new Date().toISOString()}] 玩家断线: ${socket.id}, 原因: ${reason}`);
        handlePlayerDisconnect(socket);
    });

    // 心跳检测
    socket.on('ping', (callback) => {
        if (callback && typeof callback === 'function') {
            callback();
        }
    });
});

// 处理玩家断线
function handlePlayerDisconnect(socket) {
    try {
        const roomId = playerRooms.get(socket.id);

        if (roomId) {
            const room = rooms.get(roomId);
            if (room) {
                // 移除玩家
                room.players = room.players.filter(p => p.id !== socket.id);

                if (room.players.length === 0) {
                    // 房间为空，删除房间
                    rooms.delete(roomId);
                    console.log(`[${socket.id}] 房间删除: ${roomId}`);
                } else {
                    // 如果是房主离开，转移房主权限
                    if (room.host === socket.id) {
                        room.host = room.players[0].id;
                        room.players[0].isHost = true;
                        console.log(`[${socket.id}] 房主权限转移到: ${room.host}`);
                    }

                    // 通知其他玩家
                    io.to(roomId).emit('player-left', {
                        playerId: socket.id,
                        players: room.players,
                        newHost: room.host
                    });

                    console.log(`[${socket.id}] 玩家离开房间 ${roomId}`);
                }
            }
            playerRooms.delete(socket.id);
        }
    } catch (error) {
        console.error(`[${socket.id}] 处理断线错误:`, error);
    }
}

// 生成房间ID
function generateRoomId() {
    return Math.random().toString(36).substr(2, 9).toUpperCase();
}

// 定期清理空房间和过期房间
setInterval(() => {
    try {
        const now = Date.now();
        const roomsToDelete = [];

        for (const [roomId, room] of rooms) {
            // 清理空房间
            if (room.players.length === 0) {
                roomsToDelete.push(roomId);
            }
            // 清理超过24小时的房间
            else if (now - new Date(room.created).getTime() > 24 * 60 * 60 * 1000) {
                roomsToDelete.push(roomId);
            }
        }

        for (const roomId of roomsToDelete) {
            rooms.delete(roomId);
            console.log(`清理房间: ${roomId}`);
        }
    } catch (error) {
        console.error('清理房间错误:', error);
    }
}, 5 * 60 * 1000); // 每5分钟清理一次

// 启动服务器
const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '0.0.0.0';

server.listen(PORT, HOST, () => {
    console.log('');
    console.log('='.repeat(50));
    console.log(' Galaxy Card Game 中继服务器');
    console.log('='.repeat(50));
    console.log(`🚀 服务器启动成功`);
    console.log(`📡 监听地址: http://${HOST}:${PORT}`);
    console.log(`🎮 WebSocket端点: ws://${HOST}:${PORT}/socket.io/`);
    console.log(`📊 状态API: http://${HOST}:${PORT}/api/status`);
    console.log(`📋 房间API: http://${HOST}:${PORT}/api/rooms`);
    console.log('='.repeat(50));
});

// 优雅关闭
process.on('SIGTERM', () => {
    console.log('\n收到SIGTERM信号，正在关闭服务器...');
    server.close(() => {
        console.log('服务器已关闭');
        process.exit(0);
    });
});

process.on('SIGINT', () => {
    console.log('\n收到SIGINT信号，正在关闭服务器...');
    server.close(() => {
        console.log('服务器已关闭');
        process.exit(0);
    });
});