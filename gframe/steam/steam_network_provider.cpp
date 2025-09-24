#include "steam_network_provider.h"
#include <algorithm>
#include <iostream>

namespace ygo {

SteamNetworkProvider::SteamNetworkProvider()
    : steam_api(SteamAPILoader::GetInstance()) {
}

SteamNetworkProvider::~SteamNetworkProvider() {
    Shutdown();
}

bool SteamNetworkProvider::Initialize() {
    if (initialized.load()) {
        return true;
    }

    if (!InitializeSteamAPI()) {
        return false;
    }

    StartNetworkThread();
    initialized.store(true);
    connection_state.store(NetworkConnectionState::DISCONNECTED);

    return true;
}

void SteamNetworkProvider::Shutdown() {
    if (!initialized.load()) {
        return;
    }

    StopNetworkThread();
    StopHosting();
    Disconnect();
    ShutdownSteamAPI();

    initialized.store(false);
}

bool SteamNetworkProvider::IsAvailable() const {
    return steam_api.IsSteamRunning() && steam_api.LoadSteamAPI();
}

NetworkProviderType SteamNetworkProvider::GetType() const {
    return NetworkProviderType::STEAM_NETWORK;
}

const char* SteamNetworkProvider::GetTypeName() const {
    return "Steam Network";
}

bool SteamNetworkProvider::StartHosting(const HostInfo& host_info, const std::wstring& host_name,
                                       const std::wstring& password, uint16_t port) {
    if (!initialized.load() || !steam_initialized.load()) {
        return false;
    }

    if (is_hosting.load()) {
        StopHosting();
    }

    // 创建监听套接字
    listen_socket = steam_api.CreateListenSocketIP(0, port ? port : 7911);
    if (listen_socket == 0) {
        return false;
    }

    // 保存主机信息
    current_host_info = host_info;
    current_host_name = host_name;
    current_password = password;

    is_hosting.store(true);
    return true;
}

void SteamNetworkProvider::StopHosting() {
    if (!is_hosting.load()) {
        return;
    }

    // 关闭所有客户端连接
    {
        std::lock_guard<std::mutex> lock(connections_mutex);
        for (auto& [handle, conn] : connections) {
            steam_api.CloseConnection(handle, 0, "Server shutdown", false);
        }
        connections.clear();
    }

    // 关闭监听套接字
    if (listen_socket != 0) {
        steam_api.CloseConnection(listen_socket, 0, "Server shutdown", false);
        listen_socket = 0;
    }

    is_hosting.store(false);
}

bool SteamNetworkProvider::IsHosting() const {
    return is_hosting.load();
}

bool SteamNetworkProvider::ConnectToHost(const std::string& host_address, uint16_t port,
                                        const std::wstring& password) {
    if (!initialized.load() || !steam_initialized.load()) {
        return false;
    }

    if (connection_state.load() != NetworkConnectionState::DISCONNECTED) {
        Disconnect();
    }

    UpdateConnectionState(NetworkConnectionState::CONNECTING);

    // 解析IP地址
    uint32_t ip = 0; // 需要实现IP字符串到uint32_t的转换

    // 建立连接
    server_connection = steam_api.ConnectByIPAddress(ip, port);
    if (server_connection == 0) {
        UpdateConnectionState(NetworkConnectionState::FAILED);
        return false;
    }

    // 连接建立会在NetworkThread中处理状态更新
    return true;
}

bool SteamNetworkProvider::ConnectToHost(uint32_t host_id, const std::wstring& password) {
    // 在Steam中，host_id可能是SteamID或其他标识符
    // 这里需要根据实际需求实现
    return false; // 简化实现
}

void SteamNetworkProvider::Disconnect() {
    if (connection_state.load() == NetworkConnectionState::DISCONNECTED) {
        return;
    }

    if (server_connection != 0) {
        steam_api.CloseConnection(server_connection, 0, "Client disconnect", false);
        server_connection = 0;
    }

    UpdateConnectionState(NetworkConnectionState::DISCONNECTED);
}

NetworkConnectionState SteamNetworkProvider::GetConnectionState() const {
    return connection_state.load();
}

void SteamNetworkProvider::RefreshHostList() {
    // Steam中的房间发现通过大厅系统实现
    // 这部分将在steam_lobby.cpp中实现
    if (on_host_list_updated) {
        on_host_list_updated();
    }
}

std::vector<NetworkHostInfo> SteamNetworkProvider::GetHostList() const {
    std::lock_guard<std::mutex> lock(host_list_mutex);
    return host_list;
}

void SteamNetworkProvider::ClearHostList() {
    std::lock_guard<std::mutex> lock(host_list_mutex);
    host_list.clear();

    if (on_host_list_updated) {
        on_host_list_updated();
    }
}

bool SteamNetworkProvider::SendToServer(const void* data, size_t len) {
    if (connection_state.load() != NetworkConnectionState::CONNECTED || server_connection == 0) {
        return false;
    }

    return SendDataToConnection(server_connection, data, len);
}

bool SteamNetworkProvider::SendToClient(DuelPlayer* player, const void* data, size_t len) {
    if (!is_hosting.load() || !player) {
        return false;
    }

    std::lock_guard<std::mutex> lock(connections_mutex);
    SteamNetworkConnection* conn = FindConnection(player);
    if (!conn || !conn->is_active) {
        return false;
    }

    return SendDataToConnection(conn->handle, data, len);
}

bool SteamNetworkProvider::SendToAllClients(const void* data, size_t len) {
    if (!is_hosting.load()) {
        return false;
    }

    std::lock_guard<std::mutex> lock(connections_mutex);
    bool success = true;
    for (auto& [handle, conn] : connections) {
        if (conn->is_active) {
            if (!SendDataToConnection(handle, data, len)) {
                success = false;
            }
        }
    }

    return success;
}

std::vector<DuelPlayer*> SteamNetworkProvider::GetConnectedPlayers() const {
    std::lock_guard<std::mutex> lock(connections_mutex);
    std::vector<DuelPlayer*> players;

    for (const auto& [handle, conn] : connections) {
        if (conn->is_active && conn->player) {
            players.push_back(conn->player);
        }
    }

    return players;
}

void SteamNetworkProvider::KickPlayer(DuelPlayer* player) {
    if (!is_hosting.load() || !player) {
        return;
    }

    std::lock_guard<std::mutex> lock(connections_mutex);
    SteamNetworkConnection* conn = FindConnection(player);
    if (conn && conn->is_active) {
        steam_api.CloseConnection(conn->handle, 0, "Kicked by host", false);
        CleanupConnection(conn->handle);
    }
}

void SteamNetworkProvider::SetOnClientConnected(std::function<void(DuelPlayer*)> callback) {
    on_client_connected = callback;
}

void SteamNetworkProvider::SetOnClientDisconnected(std::function<void(DuelPlayer*)> callback) {
    on_client_disconnected = callback;
}

void SteamNetworkProvider::SetOnDataReceived(std::function<void(DuelPlayer*, const void*, size_t)> callback) {
    on_data_received = callback;
}

void SteamNetworkProvider::SetOnHostListUpdated(std::function<void()> callback) {
    on_host_list_updated = callback;
}

void SteamNetworkProvider::SetOnConnectionStateChanged(std::function<void(NetworkConnectionState)> callback) {
    on_connection_state_changed = callback;
}

void SteamNetworkProvider::ProcessNetworkEvents() {
    if (!initialized.load() || !steam_initialized.load()) {
        return;
    }

    steam_api.SteamAPI_RunCallbacks();
    ProcessIncomingConnections();
    ProcessNetworkMessages();
    ProcessConnectionStateChanges();
}

bool SteamNetworkProvider::SupportsFriendInvite() const {
    return true;
}

bool SteamNetworkProvider::InviteFriend(uint64_t friend_id) {
    // 实现Steam好友邀请功能
    // 这里需要使用Steam API发送大厅邀请
    return false; // 简化实现
}

std::wstring SteamNetworkProvider::GetLocalPlayerName() const {
    if (steam_initialized.load()) {
        const char* name = steam_api.GetPersonaName();
        if (name) {
            // 简单的char*到wstring转换，实际应该使用正确的编码转换
            std::string str(name);
            return std::wstring(str.begin(), str.end());
        }
    }
    return L"SteamPlayer";
}

uint64_t SteamNetworkProvider::GetLocalPlayerId() const {
    if (steam_initialized.load()) {
        return steam_api.GetSteamID();
    }
    return 0;
}

int SteamNetworkProvider::GetPing() const {
    std::lock_guard<std::mutex> lock(stats_mutex);
    return current_ping;
}

float SteamNetworkProvider::GetPacketLoss() const {
    std::lock_guard<std::mutex> lock(stats_mutex);
    return packet_loss;
}

std::string SteamNetworkProvider::GetConnectionQualityString() const {
    if (connection_state.load() != NetworkConnectionState::CONNECTED) {
        return "Not Connected";
    }

    int ping = GetPing();
    float loss = GetPacketLoss();

    if (ping < 0) {
        return "Unknown";
    } else if (ping < 50 && loss < 0.01f) {
        return "Excellent";
    } else if (ping < 100 && loss < 0.05f) {
        return "Good";
    } else if (ping < 200 && loss < 0.10f) {
        return "Fair";
    } else {
        return "Poor";
    }
}

// 私有方法实现

bool SteamNetworkProvider::InitializeSteamAPI() {
    if (steam_initialized.load()) {
        return true;
    }

    if (!steam_api.LoadSteamAPI()) {
        return false;
    }

    if (!steam_api.SteamAPI_Init()) {
        return false;
    }

    // 检查是否需要重启以获取Steam支持
    if (steam_api.SteamAPI_RestartAppIfNecessary(STEAM_APP_ID)) {
        // 应用需要重启，这通常在开发阶段发生
        steam_api.SteamAPI_Shutdown();
        return false;
    }

    steam_initialized.store(true);
    return true;
}

void SteamNetworkProvider::ShutdownSteamAPI() {
    if (!steam_initialized.load()) {
        return;
    }

    steam_api.SteamAPI_Shutdown();
    steam_api.UnloadSteamAPI();
    steam_initialized.store(false);
}

void SteamNetworkProvider::ProcessIncomingConnections() {
    if (!is_hosting.load() || listen_socket == 0) {
        return;
    }

    // 处理新的连接请求
    // 这里需要实现Steam网络套接字的连接处理逻辑
    // 简化实现 - 实际需要使用Steam的回调系统
}

void SteamNetworkProvider::ProcessNetworkMessages() {
    // 处理所有连接的消息
    std::lock_guard<std::mutex> lock(connections_mutex);

    for (auto& [handle, conn] : connections) {
        if (!conn->is_active) continue;

        SteamNetworkingMessage_t* messages[MAX_MESSAGES_PER_FRAME];
        int msg_count = steam_api.ReceiveMessagesOnConnection(handle, messages, MAX_MESSAGES_PER_FRAME);

        for (int i = 0; i < msg_count; i++) {
            HandleIncomingMessage(messages[i]);
            // 释放消息内存 - 需要调用Steam API的释放函数
            // messages[i]->Release(); // 实际应该调用正确的释放函数
        }
    }
}

void SteamNetworkProvider::ProcessConnectionStateChanges() {
    // 检查连接状态变化
    // 这里需要实现状态变化的检测和处理
    // 实际中会通过Steam回调系统来处理
}

void SteamNetworkProvider::CleanupConnection(HSteamNetConnection handle) {
    auto it = connections.find(handle);
    if (it != connections.end()) {
        if (it->second->player && on_client_disconnected) {
            on_client_disconnected(it->second->player);
        }
        connections.erase(it);
    }
}

SteamNetworkConnection* SteamNetworkProvider::FindConnection(HSteamNetConnection handle) {
    auto it = connections.find(handle);
    return it != connections.end() ? it->second.get() : nullptr;
}

SteamNetworkConnection* SteamNetworkProvider::FindConnection(DuelPlayer* player) {
    for (auto& [handle, conn] : connections) {
        if (conn->player == player) {
            return conn.get();
        }
    }
    return nullptr;
}

void SteamNetworkProvider::HandleIncomingMessage(SteamNetworkingMessage_t* msg) {
    if (!msg || msg->cbSize <= 0) {
        return;
    }

    // 查找对应的连接
    SteamNetworkConnection* conn = FindConnection(msg->conn);
    if (!conn || !conn->is_active) {
        return;
    }

    // 触发数据接收回调
    if (on_data_received) {
        on_data_received(conn->player, msg->pData, msg->cbSize);
    }
}

bool SteamNetworkProvider::SendDataToConnection(HSteamNetConnection handle, const void* data, size_t len) {
    if (len > MAX_MESSAGE_SIZE) {
        return false;
    }

    return steam_api.SendMessageToConnection(handle, data, static_cast<uint32_t>(len), NETWORK_SEND_FLAGS);
}

void SteamNetworkProvider::UpdateConnectionState(NetworkConnectionState new_state) {
    NetworkConnectionState old_state = connection_state.exchange(new_state);
    if (old_state != new_state && on_connection_state_changed) {
        on_connection_state_changed(new_state);
    }
}

NetworkConnectionState SteamNetworkProvider::ConvertSteamConnectionState(ESteamNetworkingConnectionState steam_state) const {
    switch (steam_state) {
        case ESteamNetworkingConnectionState::None:
            return NetworkConnectionState::DISCONNECTED;
        case ESteamNetworkingConnectionState::Connecting:
        case ESteamNetworkingConnectionState::FindingRoute:
            return NetworkConnectionState::CONNECTING;
        case ESteamNetworkingConnectionState::Connected:
            return NetworkConnectionState::CONNECTED;
        case ESteamNetworkingConnectionState::ClosedByPeer:
        case ESteamNetworkingConnectionState::ProblemDetectedLocally:
            return NetworkConnectionState::FAILED;
        default:
            return NetworkConnectionState::DISCONNECTED;
    }
}

void SteamNetworkProvider::NetworkThread() {
    while (!should_stop_network_thread.load()) {
        if (initialized.load()) {
            ProcessNetworkEvents();
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }
}

void SteamNetworkProvider::StartNetworkThread() {
    if (network_thread.joinable()) {
        StopNetworkThread();
    }

    should_stop_network_thread.store(false);
    network_thread = std::thread(&SteamNetworkProvider::NetworkThread, this);
}

void SteamNetworkProvider::StopNetworkThread() {
    if (network_thread.joinable()) {
        should_stop_network_thread.store(true);
        network_thread.join();
    }
}

}