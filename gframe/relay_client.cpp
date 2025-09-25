#include "relay_client.h"
#include "game.h"
#include "simple_http.h"
#include <random>
#include <sstream>
#include <iomanip>
#include <chrono>

namespace ygo {

// 静态成员初始化
std::atomic<WebSocketState> RelayClient::state_(WS_DISCONNECTED);
std::string RelayClient::server_url_;
std::string RelayClient::room_id_;
std::string RelayClient::socket_id_;
std::thread RelayClient::network_thread_;
std::atomic<bool> RelayClient::should_stop_(false);
std::mutex RelayClient::message_queue_mutex_;
std::queue<std::string> RelayClient::outgoing_messages_;

// 回调函数
std::function<void()> RelayClient::OnConnected;
std::function<void(const std::string&)> RelayClient::OnDisconnected;
std::function<void(const std::string&)> RelayClient::OnError;
std::function<void(const std::string&)> RelayClient::OnRoomCreated;
std::function<void(const std::string&)> RelayClient::OnJoinedRoom;
std::function<void(const std::string&)> RelayClient::OnPlayerJoined;
std::function<void(const std::string&)> RelayClient::OnPlayerLeft;
std::function<void(const unsigned char*, size_t, const std::string&)> RelayClient::OnGameDataReceived;

bool RelayClient::Initialize() {
    // 初始化网络库（Windows需要WSAStartup）
#ifdef _WIN32
    WSADATA wsaData;
    return WSAStartup(MAKEWORD(2, 2), &wsaData) == 0;
#else
    return true; // Linux/macOS 不需要特殊初始化
#endif
}

void RelayClient::Cleanup() {
    Disconnect();

#ifdef _WIN32
    WSACleanup();
#endif
}

bool RelayClient::Connect(const std::string& server_url) {
    if (state_ != WS_DISCONNECTED) {
        return false;
    }

    server_url_ = server_url;
    socket_id_ = GenerateSocketId();
    state_ = WS_CONNECTING;
    should_stop_ = false;

    // 启动网络线程
    network_thread_ = std::thread(NetworkThreadFunc);

    return true;
}

void RelayClient::Disconnect() {
    if (state_ == WS_DISCONNECTED) {
        return;
    }

    should_stop_ = true;
    state_ = WS_DISCONNECTING;

    if (network_thread_.joinable()) {
        network_thread_.join();
    }

    state_ = WS_DISCONNECTED;
    room_id_.clear();
}

bool RelayClient::IsConnected() {
    return state_ == WS_CONNECTED;
}

WebSocketState RelayClient::GetState() {
    return state_;
}

void RelayClient::CreateRoom(const std::string& room_name, int max_players, const std::string& game_mode) {
    if (!IsConnected()) return;

    SimpleJson message;
    message["event"] = SimpleJson("create-room");
    message["data"]["name"] = SimpleJson(room_name);
    message["data"]["maxPlayers"] = SimpleJson(max_players);
    message["data"]["version"] = SimpleJson(PRO_VERSION);
    message["data"]["gameMode"] = SimpleJson(game_mode);

    std::string json_str = message.Stringify();

    std::lock_guard<std::mutex> lock(message_queue_mutex_);
    outgoing_messages_.push(json_str);
}

void RelayClient::JoinRoom(const std::string& room_id) {
    if (!IsConnected()) return;

    SimpleJson message;
    message["event"] = SimpleJson("join-room");
    message["data"] = SimpleJson(room_id);

    std::string json_str = message.Stringify();

    std::lock_guard<std::mutex> lock(message_queue_mutex_);
    outgoing_messages_.push(json_str);
}

void RelayClient::LeaveRoom() {
    if (!IsConnected()) return;

    SimpleJson message;
    message["event"] = SimpleJson("leave-room");

    std::string json_str = message.Stringify();

    std::lock_guard<std::mutex> lock(message_queue_mutex_);
    outgoing_messages_.push(json_str);

    room_id_.clear();
}

void RelayClient::RefreshRooms() {
    if (!IsConnected()) return;

    // 通过HTTP API获取房间列表
    std::string api_url = server_url_ + "/api/rooms";
    std::string response = HttpGet(api_url);

    if (!response.empty()) {
        // 触发房间列表更新回调（暂时通过OnRoomCreated传递）
        if (OnRoomCreated) {
            OnRoomCreated(response);
        }
    }
}

bool RelayClient::SendGameData(const unsigned char* data, size_t len) {
    if (!IsConnected() || room_id_.empty()) return false;

    Json::Value message;
    message["event"] = "game-data";

    // 将二进制数据转换为Base64
    std::string encoded_data;
    encoded_data.reserve(len * 4 / 3 + 4);

    const char* base64_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    for (size_t i = 0; i < len; i += 3) {
        unsigned char b1 = data[i];
        unsigned char b2 = (i + 1 < len) ? data[i + 1] : 0;
        unsigned char b3 = (i + 2 < len) ? data[i + 2] : 0;

        encoded_data += base64_chars[b1 >> 2];
        encoded_data += base64_chars[((b1 & 0x03) << 4) | ((b2 & 0xf0) >> 4)];
        encoded_data += (i + 1 < len) ? base64_chars[((b2 & 0x0f) << 2) | ((b3 & 0xc0) >> 6)] : '=';
        encoded_data += (i + 2 < len) ? base64_chars[b3 & 0x3f] : '=';
    }

    message["data"] = encoded_data;

    Json::StreamWriterBuilder builder;
    std::string json_str = Json::writeString(builder, message);

    std::lock_guard<std::mutex> lock(message_queue_mutex_);
    outgoing_messages_.push(json_str);

    return true;
}

bool RelayClient::SendGameData(unsigned char proto, const void* buffer, size_t len) {
    // 创建包含协议头的数据包
    std::vector<unsigned char> packet(len + 1);
    packet[0] = proto;
    if (len > 0) {
        std::memcpy(packet.data() + 1, buffer, len);
    }

    return SendGameData(packet.data(), packet.size());
}

void RelayClient::SetPlayerReady(bool ready) {
    if (!IsConnected()) return;

    Json::Value message;
    message["event"] = "player-ready";
    message["data"] = ready;

    Json::StreamWriterBuilder builder;
    std::string json_str = Json::writeString(builder, message);

    std::lock_guard<std::mutex> lock(message_queue_mutex_);
    outgoing_messages_.push(json_str);
}

void RelayClient::StartGame() {
    if (!IsConnected()) return;

    Json::Value message;
    message["event"] = "start-game";

    Json::StreamWriterBuilder builder;
    std::string json_str = Json::writeString(builder, message);

    std::lock_guard<std::mutex> lock(message_queue_mutex_);
    outgoing_messages_.push(json_str);
}

void RelayClient::NetworkThreadFunc() {
    state_ = WS_CONNECTED;

    if (OnConnected) {
        OnConnected();
    }

    while (!should_stop_) {
        try {
            // 发送排队的消息
            SendQueuedMessages();

            // 模拟接收消息的轮询（在真实实现中，这里应该是WebSocket接收）
            // 这里我们简化处理，实际需要实现真正的WebSocket客户端

            std::this_thread::sleep_for(std::chrono::milliseconds(100));

        } catch (const std::exception& e) {
            state_ = WS_ERROR;
            if (OnError) {
                OnError(e.what());
            }
            break;
        }
    }

    if (OnDisconnected) {
        OnDisconnected("Connection closed");
    }
}

void RelayClient::SendQueuedMessages() {
    std::lock_guard<std::mutex> lock(message_queue_mutex_);

    while (!outgoing_messages_.empty()) {
        const std::string& message = outgoing_messages_.front();

        if (SendWebSocketMessage(message)) {
            outgoing_messages_.pop();
        } else {
            // 发送失败，停止处理队列
            break;
        }
    }
}

bool RelayClient::SendWebSocketMessage(const std::string& message) {
    // 简化实现：通过HTTP POST模拟WebSocket发送
    // 在真实实现中，这里应该使用真正的WebSocket连接

    std::string post_url = server_url_ + "/api/websocket/send";
    std::string response = HttpPost(post_url, message);

    return !response.empty();
}

void RelayClient::ProcessIncomingMessage(const std::string& message) {
    try {
        Json::Value json_message;
        Json::CharReaderBuilder builder;
        std::string errors;
        std::istringstream iss(message);

        if (!Json::parseFromStream(builder, iss, &json_message, &errors)) {
            return;
        }

        std::string event = json_message.get("event", "").asString();
        Json::Value data = json_message.get("data", Json::Value());

        if (event == "room-created") {
            room_id_ = data.get("roomId", "").asString();
            if (OnRoomCreated) {
                OnRoomCreated(room_id_);
            }
        } else if (event == "joined-room") {
            room_id_ = data.get("room", Json::Value()).get("id", "").asString();
            if (OnJoinedRoom) {
                OnJoinedRoom(room_id_);
            }
        } else if (event == "player-joined") {
            if (OnPlayerJoined) {
                OnPlayerJoined(data.get("playerId", "").asString());
            }
        } else if (event == "player-left") {
            if (OnPlayerLeft) {
                OnPlayerLeft(data.get("playerId", "").asString());
            }
        } else if (event == "game-data") {
            std::string encoded_data = data.get("data", "").asString();
            std::string from = data.get("from", "").asString();

            // Base64解码
            std::vector<unsigned char> decoded_data;
            // 简化的Base64解码实现（省略实际解码逻辑）

            if (OnGameDataReceived && !decoded_data.empty()) {
                OnGameDataReceived(decoded_data.data(), decoded_data.size(), from);
            }
        }
    } catch (const std::exception& e) {
        if (OnError) {
            OnError("Failed to process message: " + std::string(e.what()));
        }
    }
}

std::string RelayClient::HttpGet(const std::string& url) {
    auto response = SimpleHttpClient::Get(url);
    return response.success ? response.body : "";
}

std::string RelayClient::HttpPost(const std::string& url, const std::string& data) {
    std::map<std::string, std::string> headers;
    headers["Content-Type"] = "application/json";
    auto response = SimpleHttpClient::Post(url, data, headers);
    return response.success ? response.body : "";
}

std::string RelayClient::UrlEncode(const std::string& value) {
    std::ostringstream escaped;
    escaped.fill('0');
    escaped << std::hex;

    for (char c : value) {
        if (std::isalnum(c) || c == '-' || c == '_' || c == '.' || c == '~') {
            escaped << c;
        } else {
            escaped << std::uppercase;
            escaped << '%' << std::setw(2) << int(static_cast<unsigned char>(c));
            escaped << std::nouppercase;
        }
    }

    return escaped.str();
}

std::string RelayClient::GenerateSocketId() {
    const char* chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    const size_t chars_len = 62;

    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<> dis(0, chars_len - 1);

    std::string id;
    id.reserve(20);

    for (int i = 0; i < 20; ++i) {
        id += chars[dis(gen)];
    }

    return id;
}

} // namespace ygo