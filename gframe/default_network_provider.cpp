#include "default_network_provider.h"
#include "game.h"
#include <chrono>
#include <iostream>

namespace ygo {

DefaultNetworkProvider* DefaultNetworkProvider::current_instance = nullptr;

DefaultNetworkProvider::DefaultNetworkProvider() {
    current_instance = this;
}

DefaultNetworkProvider::~DefaultNetworkProvider() {
    Shutdown();
    if (current_instance == this) {
        current_instance = nullptr;
    }
}

bool DefaultNetworkProvider::Initialize() {
    if (initialized.load()) {
        return true;
    }

    // 初始化libevent（如果还没有初始化）
    // 注意：实际的初始化可能需要根据现有代码调整
    initialized.store(true);
    connection_state.store(NetworkConnectionState::DISCONNECTED);

    return true;
}

void DefaultNetworkProvider::Shutdown() {
    if (!initialized.load()) {
        return;
    }

    // 停止所有网络活动
    StopHosting();
    Disconnect();

    // 停止广播线程
    if (broadcast_thread) {
        should_stop_broadcast.store(true);
        if (broadcast_thread->joinable()) {
            broadcast_thread->join();
        }
        delete broadcast_thread;
        broadcast_thread = nullptr;
    }

    initialized.store(false);
}

bool DefaultNetworkProvider::IsAvailable() const {
    return true; // 默认网络总是可用的
}

NetworkProviderType DefaultNetworkProvider::GetType() const {
    return NetworkProviderType::DEFAULT_NETWORK;
}

const char* DefaultNetworkProvider::GetTypeName() const {
    return "Default Network (libevent)";
}

bool DefaultNetworkProvider::StartHosting(const HostInfo& host_info, const std::wstring& host_name,
                                        const std::wstring& password, uint16_t port) {
    if (!initialized.load()) {
        return false;
    }

    if (is_hosting.load()) {
        StopHosting();
    }

    // 保存主机信息
    current_host_info = host_info;
    current_host_name = host_name;
    current_password = password;
    hosting_port = port ? port : 7911; // 默认端口

    // 启动服务器
    bool success = NetServer::StartServer(hosting_port);
    if (success) {
        is_hosting.store(true);

        // 启动广播
        NetServer::StartBroadcast();

        return true;
    }

    return false;
}

void DefaultNetworkProvider::StopHosting() {
    if (!is_hosting.load()) {
        return;
    }

    NetServer::StopBroadcast();
    NetServer::StopServer();
    is_hosting.store(false);
}

bool DefaultNetworkProvider::IsHosting() const {
    return is_hosting.load();
}

bool DefaultNetworkProvider::ConnectToHost(const std::string& host_address, uint16_t port,
                                         const std::wstring& password) {
    if (!initialized.load()) {
        return false;
    }

    if (connection_state.load() != NetworkConnectionState::DISCONNECTED) {
        Disconnect();
    }

    UpdateConnectionState(NetworkConnectionState::CONNECTING);

    // 解析IP地址
    uint32_t ip = 0;
    // 这里需要实现IP地址解析逻辑，或者使用现有的函数
    // 简化实现，假设host_address是IP地址字符串

    bool success = DuelClient::StartClient(ip, port, false);
    if (success) {
        UpdateConnectionState(NetworkConnectionState::CONNECTED);
        return true;
    } else {
        UpdateConnectionState(NetworkConnectionState::FAILED);
        return false;
    }
}

bool DefaultNetworkProvider::ConnectToHost(uint32_t host_id, const std::wstring& password) {
    // 在主机列表中查找对应的主机
    std::lock_guard<std::mutex> lock(host_list_mutex);
    for (const auto& host : host_list) {
        if (host.host_id == host_id) {
            return ConnectToHost(host.ip_address, host.port, password);
        }
    }
    return false;
}

void DefaultNetworkProvider::Disconnect() {
    if (connection_state.load() == NetworkConnectionState::DISCONNECTED) {
        return;
    }

    DuelClient::StopClient();
    UpdateConnectionState(NetworkConnectionState::DISCONNECTED);
}

NetworkConnectionState DefaultNetworkProvider::GetConnectionState() const {
    return connection_state.load();
}

void DefaultNetworkProvider::RefreshHostList() {
    if (!initialized.load()) {
        return;
    }

    // 启动广播监听线程（如果还没有启动）
    if (!broadcast_thread) {
        should_stop_broadcast.store(false);
        broadcast_thread = new std::thread(&DefaultNetworkProvider::ProcessBroadcastPackets, this);
    }

    // 触发主机列表更新回调
    if (on_host_list_updated) {
        on_host_list_updated();
    }
}

std::vector<NetworkHostInfo> DefaultNetworkProvider::GetHostList() const {
    std::lock_guard<std::mutex> lock(host_list_mutex);
    return host_list;
}

void DefaultNetworkProvider::ClearHostList() {
    std::lock_guard<std::mutex> lock(host_list_mutex);
    host_list.clear();

    if (on_host_list_updated) {
        on_host_list_updated();
    }
}

bool DefaultNetworkProvider::SendToServer(const void* data, size_t len) {
    if (connection_state.load() != NetworkConnectionState::CONNECTED) {
        return false;
    }

    // 使用现有的DuelClient发送数据
    // 这里需要根据实际的DuelClient接口调整
    return true; // 简化实现
}

bool DefaultNetworkProvider::SendToClient(DuelPlayer* player, const void* data, size_t len) {
    if (!is_hosting.load() || !player) {
        return false;
    }

    // 使用现有的NetServer发送数据到特定客户端
    // 这里需要根据实际的NetServer接口调整
    return true; // 简化实现
}

bool DefaultNetworkProvider::SendToAllClients(const void* data, size_t len) {
    if (!is_hosting.load()) {
        return false;
    }

    // 使用现有的NetServer广播数据到所有客户端
    // 这里需要根据实际的NetServer接口调整
    return true; // 简化实现
}

std::vector<DuelPlayer*> DefaultNetworkProvider::GetConnectedPlayers() const {
    std::vector<DuelPlayer*> players;
    // 这里需要从NetServer获取连接的玩家列表
    return players; // 简化实现
}

void DefaultNetworkProvider::KickPlayer(DuelPlayer* player) {
    if (!is_hosting.load() || !player) {
        return;
    }

    NetServer::DisconnectPlayer(player);
}

void DefaultNetworkProvider::SetOnClientConnected(std::function<void(DuelPlayer*)> callback) {
    on_client_connected = callback;
}

void DefaultNetworkProvider::SetOnClientDisconnected(std::function<void(DuelPlayer*)> callback) {
    on_client_disconnected = callback;
}

void DefaultNetworkProvider::SetOnDataReceived(std::function<void(DuelPlayer*, const void*, size_t)> callback) {
    on_data_received = callback;
}

void DefaultNetworkProvider::SetOnHostListUpdated(std::function<void()> callback) {
    on_host_list_updated = callback;
}

void DefaultNetworkProvider::SetOnConnectionStateChanged(std::function<void(NetworkConnectionState)> callback) {
    on_connection_state_changed = callback;
}

void DefaultNetworkProvider::ProcessNetworkEvents() {
    if (!initialized.load()) {
        return;
    }

    // 处理网络事件
    // 这里可能需要调用现有的网络事件处理函数

    // 更新连接状态
    NetworkConnectionState current_client_state = DuelClientStateToNetworkState();
    if (current_client_state != connection_state.load()) {
        UpdateConnectionState(current_client_state);
    }
}

int DefaultNetworkProvider::GetPing() const {
    return current_ping;
}

std::string DefaultNetworkProvider::GetConnectionQualityString() const {
    if (connection_state.load() != NetworkConnectionState::CONNECTED) {
        return "Not Connected";
    }

    int ping = GetPing();
    if (ping < 0) {
        return "Unknown";
    } else if (ping < 50) {
        return "Excellent";
    } else if (ping < 100) {
        return "Good";
    } else if (ping < 200) {
        return "Fair";
    } else {
        return "Poor";
    }
}

void DefaultNetworkProvider::UpdateConnectionState(NetworkConnectionState new_state) {
    NetworkConnectionState old_state = connection_state.exchange(new_state);
    if (old_state != new_state && on_connection_state_changed) {
        on_connection_state_changed(new_state);
    }
}

void DefaultNetworkProvider::ProcessBroadcastPackets() {
    while (!should_stop_broadcast.load()) {
        // 这里需要实现监听广播包的逻辑
        // 简化实现：定期检查是否有新的主机

        std::this_thread::sleep_for(std::chrono::milliseconds(100));

        // TODO: 实际的广播包处理逻辑
        // 当收到新的HostPacket时，转换为NetworkHostInfo并添加到列表
    }
}

void DefaultNetworkProvider::ConvertHostPacketToInfo(const HostPacket& packet, NetworkHostInfo& info) {
    info.host_name = std::wstring(reinterpret_cast<const wchar_t*>(packet.name));
    info.info = packet.host;
    info.host_id = packet.ipaddr; // 使用IP作为主机ID

    // 转换IP地址
    uint32_t ip = packet.ipaddr;
    char ip_str[16];
    snprintf(ip_str, sizeof(ip_str), "%d.%d.%d.%d",
             (ip >> 24) & 0xFF, (ip >> 16) & 0xFF, (ip >> 8) & 0xFF, ip & 0xFF);
    info.ip_address = ip_str;

    info.port = packet.port;
    info.password_protected = false; // 广播包中通常不包含密码信息

    // 设置其他默认值
    info.player_count = 0;
    info.max_players = 4; // 默认值，可能需要根据游戏模式调整
}

NetworkConnectionState DefaultNetworkProvider::DuelClientStateToNetworkState() const {
    // 将DuelClient的连接状态转换为NetworkConnectionState
    // 这里需要根据实际的DuelClient状态枚举调整
    switch (DuelClient::connect_state) {
        case 0: return NetworkConnectionState::DISCONNECTED;
        case 1: return NetworkConnectionState::CONNECTING;
        case 2: return NetworkConnectionState::CONNECTED;
        default: return NetworkConnectionState::FAILED;
    }
}

// 静态回调适配器函数
void DefaultNetworkProvider::OnDuelClientDataReceived(const void* data, size_t len) {
    if (current_instance && current_instance->on_data_received) {
        current_instance->on_data_received(nullptr, data, len);
    }
}

void DefaultNetworkProvider::OnNetServerClientConnected(DuelPlayer* player) {
    if (current_instance && current_instance->on_client_connected) {
        current_instance->on_client_connected(player);
    }
}

void DefaultNetworkProvider::OnNetServerClientDisconnected(DuelPlayer* player) {
    if (current_instance && current_instance->on_client_disconnected) {
        current_instance->on_client_disconnected(player);
    }
}

}