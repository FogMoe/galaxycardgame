# Galaxy Card Game Room List Server

一个极简的房间列表服务，用来展示通过房间目录广播出来的 GCG 房间。

## 快速启动

```bash
npm install
npm start
```

默认监听 `3080` 端口，可以通过环境变量调整：

```bash
PORT=8080 node server.js
```

## API 概览

- `GET /rooms/list`  
  返回 `text/plain`，每行 `name|host|port|note`。
- `POST /rooms/register`  
  `application/x-www-form-urlencoded`，字段 `name`、`host`、`port`、可选 `note`。返回 `OK <id>`。
- `POST /rooms/heartbeat`  
  字段 `id`，用于保活。
- `POST /rooms/unregister`  
  字段 `id`，用于下线。

房间 5 分钟无心跳会自动过期，可通过 `ROOM_TTL_MS` 调整。
