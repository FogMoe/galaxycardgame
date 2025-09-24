#ifndef STEAM_NETWORK_PROVIDER_H
#define STEAM_NETWORK_PROVIDER_H

#include "../network_provider.h"
#include "steam_api_loader.h"
#include <unordered_map>
#include <thread>
#include <mutex>
#include <atomic>
#include <queue>
#include <chrono>

namespace ygo {

// Steam网络连接封装
struct SteamNetworkConnection {
    HSteamNetConnection handle = 0;
    DuelPlayer* player = nullptr;
    SteamNetworkingIdentity identity;
    std::chrono::steady_clock::time_point connect_time;
    std::string debug_name;
    bool is_active = false;
};

// Steam网络消息队列项
struct SteamNetworkMessage {
    HSteamNetConnection connection;
    std::vector<uint8_t> data;
    std::chrono::steady_clock::time_point timestamp;
};

// Steam网络提供者实现
class SteamNetworkProvider : public NetworkProvider {
public:
    SteamNetworkProvider();
    virtual ~SteamNetworkProvider();

    // NetworkProvider interface implementation
    bool Initialize() override;
    void Shutdown() override;
    bool IsAvailable() const override;
    NetworkProviderType GetType() const override;
    const char* GetTypeName() const override;

    // 服务器功能
    bool StartHosting(const HostInfo& host_info, const std::wstring& host_name,
                     const std::wstring& password, uint16_t port = 0) override;
    void StopHosting() override;
    bool IsHosting() const override;

    // 客户端功能
    bool ConnectToHost(const std::string& host_address, uint16_t port,
                      const std::wstring& password = L"") override;
    bool ConnectToHost(uint32_t host_id, const std::wstring& password = L"") override;
    void Disconnect() override;
    NetworkConnectionState GetConnectionState() const override;

    // 房间列表和发现（通过Steam大厅）
    void RefreshHostList() override;
    std::vector<NetworkHostInfo> GetHostList() const override;
    void ClearHostList() override;

    // 数据传输
    bool SendToServer(const void* data, size_t len) override;
    bool SendToClient(DuelPlayer* player, const void* data, size_t len) override;
    bool SendToAllClients(const void* data, size_t len) override;

    // 玩家管理
    std::vector<DuelPlayer*> GetConnectedPlayers() const override;
    void KickPlayer(DuelPlayer* player) override;

    // 事件回调设置
    void SetOnClientConnected(std::function<void(DuelPlayer*)> callback) override;
    void SetOnClientDisconnected(std::function<void(DuelPlayer*)> callback) override;
    void SetOnDataReceived(std::function<void(DuelPlayer*, const void*, size_t)> callback) override;
    void SetOnHostListUpdated(std::function<void()> callback) override;
    void SetOnConnectionStateChanged(std::function<void(NetworkConnectionState)> callback) override;

    // 处理网络事件
    void ProcessNetworkEvents() override;

    // Steam特有功能
    bool SupportsFriendInvite() const override;
    bool InviteFriend(uint64_t friend_id) override;
    std::wstring GetLocalPlayerName() const override;
    uint64_t GetLocalPlayerId() const override;

    // 网络质量信息
    int GetPing() const override;
    float GetPacketLoss() const override;
    std::string GetConnectionQualityString() const override;

private:
    // 初始化相关
    bool InitializeSteamAPI();
    void ShutdownSteamAPI();

    // 连接管理
    void ProcessIncomingConnections();
    void ProcessNetworkMessages();
    void ProcessConnectionStateChanges();
    void CleanupConnection(HSteamNetConnection handle);
    SteamNetworkConnection* FindConnection(HSteamNetConnection handle);
    SteamNetworkConnection* FindConnection(DuelPlayer* player);

    // 消息处理
    void HandleIncomingMessage(SteamNetworkingMessage_t* msg);
    bool SendDataToConnection(HSteamNetConnection handle, const void* data, size_t len);

    // 状态管理
    void UpdateConnectionState(NetworkConnectionState new_state);
    NetworkConnectionState ConvertSteamConnectionState(ESteamNetworkingConnectionState steam_state) const;

    // 网络线程
    void NetworkThread();
    void StartNetworkThread();
    void StopNetworkThread();

    // 成员变量
    SteamAPILoader& steam_api;
    std::atomic<bool> initialized{false};
    std::atomic<bool> steam_initialized{false};
    std::atomic<bool> is_hosting{false};
    std::atomic<NetworkConnectionState> connection_state{NetworkConnectionState::DISCONNECTED};

    // Steam网络句柄
    HSteamListenSocket listen_socket = 0;
    HSteamNetConnection server_connection = 0;
    HSteamNetPollGroup poll_group = 0;

    // 连接管理
    std::unordered_map<HSteamNetConnection, std::unique_ptr<SteamNetworkConnection>> connections;
    mutable std::mutex connections_mutex;

    // 主机信息
    HostInfo current_host_info{};
    std::wstring current_host_name;
    std::wstring current_password;

    // 房间列表（通过Steam大厅获取）
    std::vector<NetworkHostInfo> host_list;
    mutable std::mutex host_list_mutex;

    // 网络线程
    std::thread network_thread;
    std::atomic<bool> should_stop_network_thread{false};

    // 消息队列
    std::queue<SteamNetworkMessage> incoming_messages;
    std::mutex message_queue_mutex;

    // 统计信息
    mutable std::mutex stats_mutex;
    int current_ping = -1;
    float packet_loss = 0.0f;
    std::chrono::steady_clock::time_point last_stats_update;

    // Steam应用ID（需要在Steam上注册应用）
    static constexpr AppId_t STEAM_APP_ID = 0; // 替换为实际的Steam应用ID

    // 网络配置
    static constexpr int NETWORK_SEND_FLAGS = 1; // k_nSteamNetworkingSend_Reliable
    static constexpr int MAX_MESSAGE_SIZE = 65536;
    static constexpr int MAX_MESSAGES_PER_FRAME = 100;
};

}

#endif // STEAM_NETWORK_PROVIDER_H