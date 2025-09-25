# Galaxy Card Game 中继服务器

## 概述

这是Galaxy Card Game的中继服务器，用于实现公网联机功能。所有游戏数据都通过此服务器进行转发，解决了NAT穿透和防火墙等网络连接问题。

## 功能特性

- ✅ 房间创建和管理
- ✅ 玩家加入/离开房间
- ✅ 游戏数据透明转发
- ✅ 断线重连支持
- ✅ 房间列表API
- ✅ 服务器状态监控
- ✅ 自动清理空房间

## 快速开始

### 1. 安装依赖

```bash
cd online-server
npm install
```

### 2. 启动服务器

```bash
# 开发模式（自动重启）
npm run dev

# 生产模式
npm start
```

### 3. 验证服务器

访问 `http://localhost:3000/api/status` 查看服务器状态。

## API接口

### 获取房间列表
```
GET /api/rooms
```

返回格式：
```json
{
  "success": true,
  "rooms": [
    {
      "id": "ABC123",
      "name": "我的房间",
      "players": 1,
      "maxPlayers": 2,
      "host": "socket_id",
      "version": "1.0.0",
      "gameMode": "standard",
      "created": "2023-12-01T12:00:00.000Z"
    }
  ],
  "total": 1
}
```

### 获取服务器状态
```
GET /api/status
```

返回格式：
```json
{
  "success": true,
  "status": "running",
  "rooms": 5,
  "connections": 10,
  "uptime": 3600,
  "memory": {
    "rss": 50331648,
    "heapTotal": 20971520,
    "heapUsed": 15728640
  }
}
```

## WebSocket事件

### 客户端发送的事件

| 事件名 | 数据 | 描述 |
|--------|------|------|
| `create-room` | `{name, maxPlayers, version, gameMode}` | 创建房间 |
| `join-room` | `roomId` | 加入房间 |
| `leave-room` | - | 离开房间 |
| `game-data` | `gameData` | 发送游戏数据 |
| `player-ready` | `boolean` | 设置准备状态 |
| `start-game` | - | 开始游戏（仅房主） |
| `ping` | `callback` | 心跳检测 |

### 服务器发送的事件

| 事件名 | 数据 | 描述 |
|--------|------|------|
| `room-created` | `{success, roomId, room}` | 房间创建结果 |
| `joined-room` | `{success, room}` | 加入房间成功 |
| `join-error` | `{success, error}` | 加入房间失败 |
| `player-joined` | `{success, playerId, players, room}` | 有玩家加入 |
| `player-left` | `{playerId, players, newHost}` | 有玩家离开 |
| `game-data` | `{from, data, timestamp}` | 接收游戏数据 |
| `player-ready-changed` | `{playerId, ready, players}` | 玩家准备状态变更 |
| `game-started` | `{room}` | 游戏开始 |

## 部署

### Docker部署

1. 创建Dockerfile：
```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000

USER node

CMD ["npm", "start"]
```

2. 构建和运行：
```bash
docker build -t galaxy-relay-server .
docker run -p 3000:3000 galaxy-relay-server
```

### PM2部署

```bash
# 安装PM2
npm install -g pm2

# 启动服务
pm2 start server.js --name "galaxy-relay"

# 查看状态
pm2 status

# 查看日志
pm2 logs galaxy-relay
```

### 云服务器部署

推荐的云服务商：
- 阿里云ECS
- 腾讯云CVM
- AWS EC2
- 数字海洋Droplet

最低配置建议：
- CPU: 1核
- 内存: 1GB
- 带宽: 1Mbps

## 环境变量

| 变量名 | 默认值 | 描述 |
|--------|---------|------|
| `PORT` | `3000` | 服务器端口 |
| `HOST` | `0.0.0.0` | 绑定地址 |
| `NODE_ENV` | `development` | 运行环境 |

## 监控和日志

服务器会输出详细的日志信息，包括：
- 玩家连接/断线
- 房间创建/删除
- 数据转发
- 错误信息

日志格式：
```
[2023-12-01T12:00:00.000Z] 玩家连接: socket_abc123
[socket_abc123] 创建房间请求: {name: "我的房间"}
[socket_abc123] 房间创建成功: ABC123
```

## 性能优化

1. **连接数限制**：单个进程建议不超过5000个并发连接
2. **内存管理**：定期清理空房间和过期数据
3. **集群模式**：使用PM2 cluster模式提高性能
4. **负载均衡**：使用Nginx进行负载均衡

## 安全考虑

1. **防火墙**：只开放必要端口（3000）
2. **SSL/TLS**：生产环境建议使用HTTPS
3. **速率限制**：防止恶意请求
4. **输入验证**：验证客户端发送的数据

## 故障排除

### 常见问题

1. **端口被占用**
```bash
# 检查端口占用
netstat -tulpn | grep 3000
# 或
lsof -i :3000
```

2. **内存泄漏**
- 检查房间是否正确清理
- 监控内存使用情况

3. **连接超时**
- 检查防火墙设置
- 验证WebSocket支持

### 日志分析

重要日志关键词：
- `连接`: 新连接建立
- `房间创建成功`: 房间创建
- `断线`: 连接断开
- `错误`: 错误信息

## 开发

### 本地开发

```bash
# 启动开发服务器
npm run dev

# 运行测试
npm test
```

### 代码结构

```
online-server/
├── server.js          # 主服务器文件
├── package.json       # 依赖配置
├── README.md          # 文档
└── public/            # 静态文件（可选）
```

## 许可证

MIT License