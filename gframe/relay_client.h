#ifndef RELAY_CLIENT_H
#define RELAY_CLIENT_H

#include "config.h"
#include <string>
#include <functional>
#include <thread>
#include <atomic>
#include <mutex>
#include <queue>
#include <vector>

namespace ygo {

// WebSocket状态
enum WebSocketState {
    WS_DISCONNECTED = 0,
    WS_CONNECTING = 1,
    WS_CONNECTED = 2,
    WS_DISCONNECTING = 3,
    WS_ERROR = 4
};

// 消息类型
enum MessageType {
    MSG_TEXT = 0,
    MSG_BINARY = 1
};

// WebSocket消息
struct WebSocketMessage {
    MessageType type;
    std::string data;
    std::vector<unsigned char> binaryData;
};

// 中继客户端类
class RelayClient {
public:
    // 回调函数类型定义
    static std::function<void()> OnConnected;
    static std::function<void(const std::string&)> OnDisconnected;
    static std::function<void(const std::string&)> OnError;
    static std::function<void(const std::string&)> OnRoomCreated;
    static std::function<void(const std::string&)> OnJoinedRoom;
    static std::function<void(const std::string&)> OnPlayerJoined;
    static std::function<void(const std::string&)> OnPlayerLeft;
    static std::function<void(const unsigned char*, size_t, const std::string&)> OnGameDataReceived;

    // 初始化和清理
    static bool Initialize();
    static void Cleanup();

    // 连接管理
    static bool Connect(const std::string& server_url);
    static void Disconnect();
    static bool IsConnected();
    static WebSocketState GetState();

    // 房间管理
    static void CreateRoom(const std::string& room_name, int max_players = 2, const std::string& game_mode = "standard");
    static void JoinRoom(const std::string& room_id);
    static void LeaveRoom();
    static void RefreshRooms();

    // 游戏数据传输
    static bool SendGameData(const unsigned char* data, size_t len);
    static bool SendGameData(unsigned char proto, const void* buffer, size_t len);

    // 玩家状态
    static void SetPlayerReady(bool ready);
    static void StartGame();

    // HTTP请求（用于获取房间列表等）
    static std::string HttpGet(const std::string& url);
    static std::string HttpPost(const std::string& url, const std::string& data);

private:
    static std::atomic<WebSocketState> state_;
    static std::string server_url_;
    static std::string room_id_;
    static std::string socket_id_;
    static std::thread network_thread_;
    static std::atomic<bool> should_stop_;
    static std::mutex message_queue_mutex_;
    static std::queue<std::string> outgoing_messages_;

    // WebSocket实现（简化版，使用HTTP长轮询模拟）
    static void NetworkThreadFunc();
    static void ProcessIncomingMessage(const std::string& message);
    static void SendQueuedMessages();
    static bool SendWebSocketMessage(const std::string& message);

    // HTTP工具函数
    static std::string UrlEncode(const std::string& value);
    static std::string GenerateSocketId();
};

} // namespace ygo

#endif // RELAY_CLIENT_H